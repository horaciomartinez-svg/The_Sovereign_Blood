extends Node
## EconomySystem — economía por regiones (GDD §5.2, §8.2).
##
## Fórmulas (contrato Fase 1 §4), todas deterministas:
##   trabajadores = población / 200 (unidades de mano de obra)
##   alimento     = farmers × factor_terreno × clima_cosecha
##   bienes       = artisans × 0.6 × talleres(1.2 si workshops)
##   comercio     = merchants × 0.4 × rutas(1.0 con ciudad/mercado, 0.6 sin) × (1 + riqueza/100)
##   impuestos    = riqueza × tasa × población / 100 000
##   tesoro      += impuestos + bienes + comercio − mantenimiento
## Apoyo popular 0-100; <20 puede provocar revuelta (GDD §5.2). Cosecha anual
## con clima del RNG central en el primer trimestre.

signal treasury_changed(faction_id: String, gold: int)
signal region_output_changed(region_id: String, output: Dictionary)
signal assignment_changed(region_id: String, worker_class: String, amount: int)
signal unrest_triggered(region_id: String, support: int)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")

## Clases de mano de obra asignables (GDD §5.2).
const WORKER_CLASSES: Array[String] = ["farmers", "artisans", "merchants", "recruits"]


## Recalcula producción, apoyo y tesoro de una facción (una vez por trimestre).
func recalculate(faction_id: String) -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or faction_id == "":
		return
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		return
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var gross_income: float = 0.0
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var output: Dictionary = _region_output(region_id, region, faction)
		gross_income += SafeDict.as_float(output.get("gold_income"), 0.0)
		_update_support(region_id, region, faction, output)
		emit_signal("region_output_changed", region_id, output)
		EventBus.emit_signal("region_output_changed", region_id, output)
		if SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT) < Constants.REVOLT_SUPPORT_THRESHOLD:
			_maybe_revolt(region_id, region, faction)
	var upkeep: int = _army_upkeep(faction_id)
	var gold_before: int = SafeDict.as_int(faction.get("gold"), 0)
	var overhead: int = 0
	if gold_before > Constants.TREASURY_SOFT_CAP:
		overhead = int(ceilf(float(gold_before - Constants.TREASURY_SOFT_CAP) * Constants.TREASURY_OVERHEAD_RATE))
	var net: int = int(roundf(gross_income)) - upkeep - overhead
	var gold_after: int = gold_before + net
	if gold_after < 0:
		gold_after = 0
		_apply_unpaid_penalty(faction_id)
	faction["gold"] = gold_after
	emit_signal("treasury_changed", faction_id, gold_after)
	EventBus.emit_signal("treasury_changed", faction_id, gold_after)


## Asigna mano de obra de una región: `amount` es el valor objetivo de la clase.
## Cuesta 1 PG por orden y redistribuye contra farmers (o artisans si la clase
## es farmers), manteniendo constante el total de trabajadores.
func allocate(region_id: String, worker_class: String, amount: int) -> bool:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return false
	var region: Dictionary = GameState.get_region_state(region_id)
	if region.is_empty() or not WORKER_CLASSES.has(worker_class) or amount < 0:
		return false
	var owner: String = SafeDict.as_string(region.get("owner"), "")
	if owner == "":
		return false
	var faction: Dictionary = GameState.get_faction_state(owner)
	if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		return false
	var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
	var total: int = _workers_total(workers)
	if amount > total:
		return false
	var current: int = SafeDict.as_int(workers.get(worker_class), 0)
	var delta: int = amount - current
	var buffer_class: String = "farmers" if worker_class != "farmers" else "artisans"
	var buffer_value: int = SafeDict.as_int(workers.get(buffer_class), 0)
	if delta > 0 and buffer_value < delta:
		return false
	if delta == 0:
		return true
	if not TurnManager.spend_pg_for(owner, Constants.ALLOCATE_PG_COST):
		return false
	workers[worker_class] = amount
	workers[buffer_class] = buffer_value - delta
	if workers[buffer_class] < 0:
		# No debería ocurrir por la validación previa; restaura ante cualquier caso.
		workers[buffer_class] = 0
	region["workers"] = workers
	if worker_class == "recruits":
		var pool: int = SafeDict.as_int(region.get("recruit_pool"), 0)
		region["recruit_pool"] = maxi(0, pool + delta * Constants.WORKER_POPULATION_PER_UNIT)
	if buffer_class == "recruits":
		var pool_buffer: int = SafeDict.as_int(region.get("recruit_pool"), 0)
		region["recruit_pool"] = maxi(0, pool_buffer - delta * Constants.WORKER_POPULATION_PER_UNIT)
	emit_signal("assignment_changed", region_id, worker_class, amount)
	GameState.record_turn_action("workers", region_id, 0)
	EventBus.emit_signal("region_assignment_changed", region_id, worker_class, amount)
	return true


func get_treasury(faction_id: String) -> int:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	return SafeDict.as_int(faction.get("gold"), 0)


## Producción del trimestre para una región (no muta estado salvo RNG no usado).
func get_region_output(region_id: String) -> Dictionary:
	var region: Dictionary = GameState.get_region_state(region_id)
	if region.is_empty():
		return {}
	var owner: String = SafeDict.as_string(region.get("owner"), "")
	var faction: Dictionary = GameState.get_faction_state(owner)
	return _region_output(region_id, region, faction)


## Cosecha anual (trimestre 1): clima RNG por región y crecimiento/famine de población.
func resolve_harvest(faction_id: String) -> Dictionary:
	var result: Dictionary = {"faction_id": faction_id, "regions": 0, "food": 0.0}
	var st: Dictionary = GameState.state
	if st.is_empty():
		return result
	if GameState.rng == null:
		GameState.rng = preload("res://scripts/utils/rng.gd").new(GameState.rng_seed)
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var total_food: float = 0.0
	var region_count: int = 0
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var climate: float = GameState.rng.next_float_range(Constants.HARVEST_MIN, Constants.HARVEST_MAX)
		region["harvest_modifier"] = snappedf(climate, 0.001)
		var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
		var farmers: int = SafeDict.as_int(workers.get("farmers"), 0)
		var terrain: String = SafeDict.as_string(region.get("terrain"), "plains")
		var terrain_factor: float = SafeDict.as_float(Constants.TERRAIN_FOOD.get(terrain), 1.0)
		total_food += float(farmers) * terrain_factor * climate
		region_count += 1
		var support: int = SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT)
		var population: int = SafeDict.as_int(region.get("population"), 1000)
		if support > Constants.HARVEST_GROWTH_SUPPORT:
			region["population"] = population + int(roundf(float(population) * Constants.HARVEST_GROWTH_RATE))
		elif support < Constants.HARVEST_FAMINE_SUPPORT:
			region["population"] = maxi(1000, population - int(roundf(float(population) * Constants.HARVEST_FAMINE_RATE)))
		emit_signal("region_output_changed", region_id, get_region_output(region_id))
	result["regions"] = region_count
	result["food"] = snappedf(total_food, 0.01)
	return result


## Apoyo popular 0-100 de una región (50 = neutro si no hay partida).
func get_support(region_id: String) -> int:
	var region: Dictionary = GameState.get_region_state(region_id)
	return SafeDict.as_int(region.get("support"), 50)


# ---------------------------------------------------------------------------
# Fórmulas
# ---------------------------------------------------------------------------

func _region_output(region_id: String, region: Dictionary, faction: Dictionary) -> Dictionary:
	var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
	var farmers: int = SafeDict.as_int(workers.get("farmers"), 0)
	var artisans: int = SafeDict.as_int(workers.get("artisans"), 0)
	var merchants: int = SafeDict.as_int(workers.get("merchants"), 0)
	var workers_total: int = _workers_total(workers)
	var terrain: String = SafeDict.as_string(region.get("terrain"), "plains")
	var terrain_factor: float = SafeDict.as_float(Constants.TERRAIN_FOOD.get(terrain), 1.0)
	var harvest: float = SafeDict.as_float(region.get("harvest_modifier"), 1.0)
	var food: float = float(farmers) * terrain_factor * harvest
	var food_need: float = float(workers_total) * Constants.FOOD_NEED_PER_WORKER
	var buildings: Array = SafeDict.as_array(region.get("buildings", null))
	var workshops_factor: float = 1.2 if buildings.has("workshops") else 1.0
	var goods: float = float(artisans) * Constants.GOODS_PER_ARTISAN * workshops_factor
	var has_city: bool = SafeDict.as_bool(region.get("has_city"), false)
	var has_market: bool = buildings.has("market") or has_city
	var routes_factor: float = 1.0 if has_market else 0.6
	var prosperity: float = float(SafeDict.as_int(region.get("base_wealth"), 50))
	var commerce: float = float(merchants) * Constants.COMMERCE_PER_MERCHANT * routes_factor * (1.0 + prosperity / 100.0)
	var trade_pacts: Array = SafeDict.as_array(faction.get("trade_pacts", null))
	if not trade_pacts.is_empty():
		commerce *= 1.0 + Constants.TRADE_PACT_COMMERCE_BONUS
	var tax_rate: float = SafeDict.as_float(faction.get("tax_rate"), Constants.TAX_RATE_DEFAULT)
	var population: int = SafeDict.as_int(region.get("population"), 1000)
	var taxes: float = float(SafeDict.as_int(region.get("base_wealth"), 50)) * tax_rate \
		* float(population) / Constants.TAX_POPULATION_DIVISOR
	return {
		"region_id": region_id,
		"workers_total": workers_total,
		"food": snappedf(food, 0.01),
		"food_need": snappedf(food_need, 0.01),
		"surplus": snappedf(food - food_need, 0.01),
		"goods": snappedf(goods, 0.01),
		"commerce": snappedf(commerce, 0.01),
		"taxes": snappedf(taxes, 0.01),
		"gold_income": snappedf(taxes + goods + commerce, 0.01),
		"tax_rate": tax_rate,
		"harvest_modifier": harvest,
	}


func _update_support(region_id: String, region: Dictionary, faction: Dictionary, output: Dictionary) -> void:
	var food_need: float = maxf(1.0, SafeDict.as_float(output.get("food_need"), 1.0))
	var surplus_ratio: float = (SafeDict.as_float(output.get("food"), 0.0) - food_need) / food_need
	var delta: int = clampi(int(roundf(surplus_ratio * 6.0)), -3, 3)
	var wealth: int = SafeDict.as_int(region.get("base_wealth"), 50)
	delta += clampi(int(roundf((float(wealth) - 50.0) / 25.0)), -1, 2)
	var tax_rate: float = SafeDict.as_float(output.get("tax_rate"), Constants.TAX_RATE_DEFAULT)
	if tax_rate > Constants.TAX_RATE_DEFAULT:
		delta -= int(roundf((tax_rate - Constants.TAX_RATE_DEFAULT) * 20.0))
	var at_war: Array = SafeDict.as_array(faction.get("at_war", null))
	if not at_war.is_empty():
		delta -= 1
	if SafeDict.as_string(region.get("terrain"), "") == "mountain":
		# D-067: las economías de montaña no deben entrar en espiral de revueltas.
		delta += Constants.SUPPORT_MOUNTAIN_BONUS
	var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
	var workers_total: int = _workers_total(workers)
	var recruits: int = SafeDict.as_int(workers.get("recruits"), 0)
	if workers_total > 0 and float(recruits) / float(workers_total) > 0.2:
		delta -= 1
	var support: int = SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT)
	var new_support: int = clampi(support + delta, Constants.SUPPORT_MIN, Constants.SUPPORT_MAX)
	region["support"] = new_support
	if new_support < Constants.REVOLT_SUPPORT_THRESHOLD and support >= Constants.REVOLT_SUPPORT_THRESHOLD:
		emit_signal("unrest_triggered", region_id, new_support)
		EventBus.emit_signal("unrest_triggered", region_id, new_support)


func _maybe_revolt(region_id: String, region: Dictionary, faction: Dictionary) -> void:
	if GameState.rng == null:
		return
	if GameState.rng.next_float() >= Constants.REVOLT_CHANCE:
		return
	var faction_id: String = SafeDict.as_string(region.get("owner"), "")
	region["support"] = Constants.REVOLT_SUPPORT_RESET
	var gold: int = SafeDict.as_int(faction.get("gold"), 0)
	faction["gold"] = maxi(0, gold - Constants.REVOLT_GOLD_LOSS)
	faction["prestige"] = maxi(0, SafeDict.as_int(faction.get("prestige"), 0) - Constants.REVOLT_PRESTIGE_LOSS)
	var st: Dictionary = GameState.state
	var entry: Dictionary = {
		"year": SafeDict.as_int(st.get("year"), 0),
		"quarter": SafeDict.as_int(st.get("quarter"), 0),
		"event_id": "revuelta_%s" % region_id,
		"text": "Revuelta popular en %s: el descontento estalla." % SafeDict.as_string(region.get("name"), region_id),
	}
	var event_log: Array = SafeDict.as_array(st.get("event_log", null))
	event_log.append(entry)
	st["event_log"] = event_log
	EventBus.emit_signal("revolt_triggered", region_id, faction_id)
	EventBus.emit_signal("ui_notification", str(entry.get("text", "")), 2)


func _army_upkeep(faction_id: String) -> int:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var total_men: int = 0
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		var units: Array = SafeDict.as_array(army.get("units", null))
		for unit_value in units:
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			total_men += SafeDict.as_int(unit.get("size"), 0)
	return int(ceilf(float(total_men) / float(Constants.UNIT_MEN_PER_BLOCK) * Constants.ARMY_UPKEEP_PER_200_MEN))


func _apply_unpaid_penalty(faction_id: String) -> void:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		army["morale"] = maxf(Constants.BATTLE_MIN_MORALE, SafeDict.as_float(army.get("morale"), 1.0) - 0.05)


func _workers_total(workers: Dictionary) -> int:
	var total: int = 0
	for worker_class in WORKER_CLASSES:
		total += SafeDict.as_int(workers.get(worker_class), 0)
	return total


## task-71: construcción gateada (una por región+edificio/turno). Devuelve
## {ok, reason, cost_gold, cost_pg, building}. No gasta nada si falla.
func build_building(faction_id: String, region_id: String, building_id: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "", "cost_gold": 0, "cost_pg": 0}
	var st: Dictionary = GameState.state
	if st.is_empty() or faction_id == "" or region_id == "" or building_id == "":
		result["reason"] = "parámetros inválidos"
		return result
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var region: Dictionary = GameState.get_region_state(region_id)
	if faction.is_empty() or region.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		result["reason"] = "facción/región inválida"
		return result
	if SafeDict.as_string(region.get("owner"), "") != faction_id:
		result["reason"] = "región no propia"
		return result
	var buildings: Array = SafeDict.as_array(region.get("buildings", null))
	var gate_key: String = "build:%s:%s" % [region_id, building_id]
	if buildings.has(building_id):
		if GameState.is_action_used(faction_id, gate_key):
			result["reason"] = "action_used"
		else:
			result["reason"] = "ya construido"
		return result
	var cost_value: Variant = Constants.BUILDING_COSTS.get(building_id, null)
	var cost: Dictionary = SafeDict.as_dict(cost_value)
	if cost.is_empty():
		result["reason"] = "edificio desconocido"
		return result
	var cost_gold: int = SafeDict.as_int(cost.get("gold"), 0)
	var cost_pg: int = SafeDict.as_int(cost.get("pg"), 0)
	result["cost_gold"] = cost_gold
	result["cost_pg"] = cost_pg
	if SafeDict.as_int(faction.get("gold"), 0) < cost_gold:
		result["reason"] = "oro insuficiente"
		return result
	if SafeDict.as_int(faction.get("pg"), 0) < cost_pg:
		result["reason"] = "PG insuficiente"
		return result
	if not GameState.can_use_action(faction_id, gate_key):
		result["reason"] = "action_used"
		return result
	GameState.mark_action_used(faction_id, gate_key)
	if not TurnManager.spend_pg_for(faction_id, cost_pg):
		result["reason"] = "PG insuficiente"
		return result
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) - cost_gold
	buildings.append(building_id)
	region["buildings"] = buildings
	GameState.record_turn_action("build", "%s:%s" % [region_id, building_id], cost_pg)
	result["ok"] = true
	result["reason"] = "ok"
	EventBus.emit_signal("building_completed", region_id, building_id)
	return result


func get_building_cost(building_id: String) -> Dictionary:
	return SafeDict.as_dict(Constants.BUILDING_COSTS.get(building_id, null)).duplicate(true)
