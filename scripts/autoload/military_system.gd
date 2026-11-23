extends Node
## MilitarySystem — ejércitos, movimiento y reclutamiento (GDD §5.5, §8.1).
##
## - Ejércitos = grupos de unidades en una región; límite por región según
##   edificios (1 base + castillo + murallas).
## - Reclutamiento consume pool regional (hombres) y oro; el coste de units.json
##   es por bloque de 200 hombres.
## - Movimiento solo por adyacencia: 1 PG + penalización de terreno.
## - Mover a región enemiga con defensores → batalla delegada (BattleManager);
##   sin defensores → ocupación. En ambos casos se declaran hostilidades.
## Toda la aleatoriedad de la batalla sale de GameState.rng.

signal army_created(army_id: String, faction_id: String, region_id: String)
signal army_moved(army_id: String, from_region: String, to_region: String)
signal army_destroyed(army_id: String, faction_id: String)
signal armies_changed(region_id: String)
signal recruitment_completed(faction_id: String, region_id: String, unit_id: String)
signal region_captured(region_id: String, faction_id: String)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const TechScript = preload("res://scripts/utils/tech.gd")

const ARMY_SCRIPT = preload("res://scripts/model/army.gd")
const REGION_SCRIPT = preload("res://scripts/model/region_state.gd")

## Batallas pendientes de resolver al cierre del turno (normalmente vacío: la
## batalla se resuelve en el propio `move_army` para que la UI muestre el informe).
var _pending_battles: Array[Dictionary] = []
## D-070: motivo legible de la última operación (reclutar/entrenar/disolver).
var last_recruit_reason: String = ""
var last_train_reason: String = ""
var last_disband_reason: String = ""


func get_last_recruit_reason() -> String:
	return last_recruit_reason


func get_last_train_reason() -> String:
	return last_train_reason


func get_last_disband_reason() -> String:
	return last_disband_reason


## Crea un ejército vacío de la facción en la región indicada (si hay hueco).
func create_army(faction_id: String, region_id: String) -> Dictionary:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return {}
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var region: Dictionary = GameState.get_region_state(region_id)
	if faction.is_empty() or region.is_empty():
		return {}
	if SafeDict.as_bool(faction.get("eliminated"), false):
		return {}
	if SafeDict.as_string(region.get("owner"), "") != faction_id:
		return {}
	var slots: int = _army_slots(region)
	if _armies_of_faction_in(faction_id, region_id).size() >= slots:
		return {}
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var counter: int = 1
	var army_id := "army_%s_%d" % [faction_id, counter]
	while armies.has(army_id):
		counter += 1
		army_id = "army_%s_%d" % [faction_id, counter]
	var leader_id: String = ""
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	if ruler_id != "" and not _faction_has_leader(faction_id):
		var ruler: Dictionary = GameState.get_character_state(ruler_id)
		if SafeDict.as_bool(ruler.get("alive"), false):
			leader_id = ruler_id
	armies[army_id] = {
		"id": army_id,
		"faction_id": faction_id,
		"region_id": region_id,
		"leader_id": leader_id,
		"morale": 1.0,
		"movement_left": 2,
		"units": [],
	}
	emit_signal("army_created", army_id, faction_id, region_id)
	EventBus.emit_signal("army_created", army_id, faction_id, region_id)
	return (SafeDict.as_dict(armies.get(army_id, null))).duplicate(true)


## Recluta `amount` hombres de `unit_id` en la región (pool + oro).
func recruit(faction_id: String, region_id: String, unit_id: String, amount: int) -> bool:
	last_recruit_reason = ""
	var st: Dictionary = GameState.state
	if st.is_empty() or amount <= 0:
		last_recruit_reason = "cantidad inválida"
		return false
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var region: Dictionary = GameState.get_region_state(region_id)
	if faction.is_empty() or region.is_empty():
		last_recruit_reason = "facción o región inválida"
		return false
	if SafeDict.as_bool(faction.get("eliminated"), false):
		last_recruit_reason = "facción eliminada"
		return false
	if SafeDict.as_string(region.get("owner"), "") != faction_id:
		last_recruit_reason = "región no propia"
		return false
	var unit_definition: Dictionary = DataLoader.get_unit(unit_id)
	if unit_definition.is_empty():
		last_recruit_reason = "unidad inexistente"
		return false
	if not _unit_allowed_for(unit_definition, faction_id):
		last_recruit_reason = "unidad no disponible"
		return false
	var pool: int = SafeDict.as_int(region.get("recruit_pool"), 0)
	if pool < amount:
		last_recruit_reason = "pool insuficiente"
		return false
	var blocks: int = int(ceilf(float(amount) / float(Constants.UNIT_MEN_PER_BLOCK)))
	var cost: Dictionary = SafeDict.as_dict(unit_definition.get("cost", null))
	var gold_cost: int = blocks * SafeDict.as_int(cost.get("gold"), 0)
	var gold: int = SafeDict.as_int(faction.get("gold"), 0)
	if gold < gold_cost:
		last_recruit_reason = "oro insuficiente"
		return false
	# D-070: mercancías de reclutamiento (por bloque de 200 hombres).
	var requirements: Dictionary = _recruit_goods_requirements(unit_definition, amount)
	if not requirements.is_empty() and not TradeSystem.can_consume_goods(faction_id, requirements):
		last_recruit_reason = "faltan mercancías"
		return false
	# Localizar o crear el ejército receptor antes de comprometer recursos.
	var army_id: String = _army_id_of(faction_id, region_id)
	if army_id == "":
		var created: Dictionary = create_army(faction_id, region_id)
		if created.is_empty():
			return false
		army_id = SafeDict.as_string(created.get("id"), "")
	if army_id == "":
		return false
	# Comprometer recursos.
	faction["gold"] = gold - gold_cost
	region["recruit_pool"] = pool - amount
	region["support"] = clampi(SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT) - 1,
		Constants.SUPPORT_MIN, Constants.SUPPORT_MAX)
	var army: Dictionary = GameState.get_army_state(army_id)
	var units: Array = SafeDict.as_array(army.get("units", null))
	var merged: bool = false
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") != unit_id:
			continue
		unit["size"] = SafeDict.as_int(unit.get("size"), 0) + amount
		merged = true
		break
	if not merged:
		units.append({
			"id": "%s_u%d" % [army_id, units.size() + 1],
			"unit_id": unit_id,
			"size": amount,
			"strength": SafeDict.as_int(unit_definition.get("strength"), 1),
			"morale": 1.0,
			"experience": 0,
		})
	army["units"] = units
	if not requirements.is_empty():
		TradeSystem.consume_goods(faction_id, requirements)
	emit_signal("recruitment_completed", faction_id, region_id, unit_id)
	EventBus.emit_signal("recruitment_completed", faction_id, region_id, unit_id)
	emit_signal("armies_changed", region_id)
	EventBus.emit_signal("treasury_changed", faction_id, SafeDict.as_int(faction.get("gold"), 0))
	return true


func _recruit_goods_requirements(unit_definition: Dictionary, amount: int) -> Dictionary:
	var requirements: Dictionary = {}
	var goods: Dictionary = SafeDict.as_dict(unit_definition.get("recruit_goods", null))
	if goods.is_empty():
		return requirements
	var blocks: int = int(ceilf(float(amount) / float(maxi(1, Constants.UNIT_MEN_PER_BLOCK))))
	for good_id in SafeDict.sorted_keys(goods):
		var per_block: float = SafeDict.as_float(goods.get(good_id), 0.0)
		if per_block > 0.0:
			requirements[good_id] = ceilf(per_block * float(blocks))
	return requirements


## task-71/D-075: coste de reclutar `amount` hombres (oro + mercancías).
func get_unit_recruit_cost(unit_id: String, amount: int) -> Dictionary:
	var definition: Dictionary = DataLoader.get_unit(unit_id)
	if definition.is_empty() or amount <= 0:
		return {}
	var blocks: int = int(ceilf(float(amount) / float(maxi(1, Constants.UNIT_MEN_PER_BLOCK))))
	var cost: Dictionary = SafeDict.as_dict(definition.get("cost", null))
	return {
		"unit_id": unit_id,
		"amount": amount,
		"blocks": blocks,
		"gold": blocks * SafeDict.as_int(cost.get("gold"), 0),
		"gold_per_block": SafeDict.as_int(cost.get("gold"), 0),
		"goods": _recruit_goods_requirements(definition, amount),
		"goods_per_block": SafeDict.as_dict(definition.get("recruit_goods", null)).duplicate(true),
	}


## Resumen global por tipo de unidad (D-070) para la pantalla de ejércitos.
func get_faction_army_summary(faction_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var aggregated: Dictionary = {}
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			var unit_id: String = SafeDict.as_string(unit.get("unit_id"), "")
			if unit_id == "":
				continue
			var definition: Dictionary = DataLoader.get_unit(unit_id)
			var entry: Dictionary = SafeDict.as_dict(aggregated.get(unit_id, null))
			if entry.is_empty():
				entry = {
					"unit_id": unit_id,
					"type": SafeDict.as_string(definition.get("type"), "infantry"),
					"count": 0,
					"men": 0,
					"strength": SafeDict.as_int(definition.get("strength"), 1),
					"avg_morale": 0.0,
					"avg_experience": 0.0,
					"sprite_path": _unit_march_sprite(unit_id),
					"recruit_gold_per_block": SafeDict.as_int(
						SafeDict.as_dict(definition.get("cost", null)).get("gold"), 0),
					"recruit_goods_per_block": SafeDict.as_dict(definition.get("recruit_goods", null)).duplicate(true),
					"_morale_sum": 0.0,
					"_exp_sum": 0.0,
				}
			var size: int = maxi(0, SafeDict.as_int(unit.get("size"), 0))
			entry["count"] = SafeDict.as_int(entry.get("count"), 0) + 1
			entry["men"] = SafeDict.as_int(entry.get("men"), 0) + size
			entry["_morale_sum"] = SafeDict.as_float(entry.get("_morale_sum"), 0.0) \
				+ SafeDict.as_float(unit.get("morale"), 1.0) * float(size)
			entry["_exp_sum"] = SafeDict.as_float(entry.get("_exp_sum"), 0.0) \
				+ SafeDict.as_float(unit.get("experience"), 0.0) * float(size)
			aggregated[unit_id] = entry
	for unit_id in SafeDict.sorted_keys(aggregated):
		var entry: Dictionary = SafeDict.as_dict(aggregated.get(unit_id, null))
		var men: int = maxi(0, SafeDict.as_int(entry.get("men"), 0))
		if men > 0:
			entry["avg_morale"] = snappedf(SafeDict.as_float(entry.get("_morale_sum"), 0.0) / float(men), 0.001)
			entry["avg_experience"] = snappedf(SafeDict.as_float(entry.get("_exp_sum"), 0.0) / float(men), 0.01)
		entry.erase("_morale_sum")
		entry.erase("_exp_sum")
		result.append(entry)
	return result


func _unit_march_sprite(unit_id: String) -> String:
	var sprite: Dictionary = DataLoader.get_unit_sprite(unit_id)
	var frames: Array = SafeDict.as_array(sprite.get("frames", null))
	if not frames.is_empty():
		return str(frames[0])
	return "res://assets/art/sprites/units/%s_march_1.png" % unit_id


## Entrena unidades de un tipo (D-070): coste oro + 1 PG; tope de experiencia.
func train_unit(faction_id: String, unit_id: String, amount: int = Constants.TRAIN_EXP_PER_ACTION) -> bool:
	last_train_reason = ""
	var st: Dictionary = GameState.state
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if st.is_empty() or faction.is_empty() or amount <= 0:
		last_train_reason = "parámetros inválidos"
		return false
	var matching: Array[Dictionary] = []
	var men: int = 0
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			if SafeDict.as_string(unit.get("unit_id"), "") == unit_id and SafeDict.as_int(unit.get("size"), 0) > 0:
				matching.append(unit)
				men += SafeDict.as_int(unit.get("size"), 0)
	if matching.is_empty():
		last_train_reason = "no hay unidades de ese tipo"
		return false
	var cost: int = int(ceilf(float(men) / float(maxi(1, Constants.UNIT_MEN_PER_BLOCK)))) * Constants.TRAIN_GOLD_PER_BLOCK
	if SafeDict.as_int(faction.get("gold"), 0) < cost:
		last_train_reason = "oro insuficiente"
		return false
	if not TurnManager.spend_pg_for(faction_id, 1):
		last_train_reason = "PG insuficiente"
		return false
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) - cost
	for unit in matching:
		unit["experience"] = mini(Constants.TRAIN_EXP_MAX,
			SafeDict.as_int(unit.get("experience"), 0) + amount)
	EventBus.emit_signal("army_trained", faction_id, unit_id, amount)
	EventBus.emit_signal("armies_changed", "")
	return true


## Entrena todas las unidades de un ejército concreto (oro + 1 PG).
func train_army(army_id: String) -> bool:
	last_train_reason = ""
	var st: Dictionary = GameState.state
	var army: Dictionary = GameState.get_army_state(army_id)
	if st.is_empty() or army.is_empty():
		last_train_reason = "ejército inexistente"
		return false
	var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if SafeDict.as_int(faction.get("gold"), 0) < Constants.TRAIN_ARMY_GOLD:
		last_train_reason = "oro insuficiente"
		return false
	if not TurnManager.spend_pg_for(faction_id, 1):
		last_train_reason = "PG insuficiente"
		return false
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) - Constants.TRAIN_ARMY_GOLD
	for unit_value in SafeDict.as_array(army.get("units", null)):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		unit["experience"] = mini(Constants.TRAIN_EXP_MAX,
			SafeDict.as_int(unit.get("experience"), 0) + Constants.TRAIN_EXP_PER_ACTION)
	EventBus.emit_signal("army_trained", faction_id, "", Constants.TRAIN_EXP_PER_ACTION)
	EventBus.emit_signal("armies_changed", SafeDict.as_string(army.get("region_id"), ""))
	return true


## Disuelve `amount` hombres de una unidad global (libera pool, devuelve 50 %).
func disband_unit(faction_id: String, unit_id: String, amount: int) -> bool:
	last_disband_reason = ""
	var st: Dictionary = GameState.state
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var definition: Dictionary = DataLoader.get_unit(unit_id)
	if st.is_empty() or faction.is_empty() or definition.is_empty() or amount <= 0:
		last_disband_reason = "parámetros inválidos"
		return false
	var available: int = 0
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			if SafeDict.as_string(unit.get("unit_id"), "") == unit_id:
				available += SafeDict.as_int(unit.get("size"), 0)
	if available < amount:
		last_disband_reason = "unidades insuficientes"
		return false
	var remaining: int = amount
	var refund: int = 0
	var pool_region: String = ""
	for army_id in SafeDict.sorted_keys(armies):
		if remaining <= 0:
			break
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		var units: Array = SafeDict.as_array(army.get("units", null))
		var kept: Array = []
		for unit_value in units:
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			if SafeDict.as_string(unit.get("unit_id"), "") != unit_id or remaining <= 0:
				kept.append(unit)
				continue
			var size: int = SafeDict.as_int(unit.get("size"), 0)
			var removed: int = mini(size, remaining)
			remaining -= removed
			var refund_blocks: int = int(ceilf(float(removed) / float(maxi(1, Constants.UNIT_MEN_PER_BLOCK))))
			var unit_cost: Dictionary = SafeDict.as_dict(definition.get("cost", null))
			refund += int(roundf(float(refund_blocks * SafeDict.as_int(unit_cost.get("gold"), 0)) * Constants.DISBAND_REFUND_RATIO))
			unit["size"] = size - removed
			if pool_region == "":
				pool_region = SafeDict.as_string(army.get("region_id"), "")
			if SafeDict.as_int(unit.get("size"), 0) > 0:
				kept.append(unit)
		army["units"] = kept
		if kept.is_empty():
			var region_id: String = SafeDict.as_string(army.get("region_id"), "")
			armies.erase(army_id)
			emit_signal("army_destroyed", army_id, faction_id)
			emit_signal("armies_changed", region_id)
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) + refund
	if pool_region != "":
		var region: Dictionary = GameState.get_region_state(pool_region)
		region["recruit_pool"] = SafeDict.as_int(region.get("recruit_pool"), 0) + amount
	EventBus.emit_signal("army_disbanded", faction_id, unit_id, amount)
	EventBus.emit_signal("armies_changed", pool_region)
	return true


## Disuelve un ejército completo (libera pool y devuelve 50 % del coste).
func disband_army(army_id: String) -> bool:
	last_disband_reason = ""
	var st: Dictionary = GameState.state
	var army: Dictionary = GameState.get_army_state(army_id)
	if st.is_empty() or army.is_empty():
		last_disband_reason = "ejército inexistente"
		return false
	var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
	var region_id: String = SafeDict.as_string(army.get("region_id"), "")
	var men: int = 0
	var refund: int = 0
	for unit_value in SafeDict.as_array(army.get("units", null)):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		var unit_id: String = SafeDict.as_string(unit.get("unit_id"), "")
		var size: int = SafeDict.as_int(unit.get("size"), 0)
		men += size
		var definition: Dictionary = DataLoader.get_unit(unit_id)
		var unit_cost: Dictionary = SafeDict.as_dict(definition.get("cost", null))
		var blocks: int = int(ceilf(float(size) / float(maxi(1, Constants.UNIT_MEN_PER_BLOCK))))
		refund += int(roundf(float(blocks * SafeDict.as_int(unit_cost.get("gold"), 0)) * Constants.DISBAND_REFUND_RATIO))
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) + refund
	var region: Dictionary = GameState.get_region_state(region_id)
	region["recruit_pool"] = SafeDict.as_int(region.get("recruit_pool"), 0) + men
	SafeDict.as_dict(st.get("armies", null)).erase(army_id)
	emit_signal("army_destroyed", army_id, faction_id)
	EventBus.emit_signal("army_disbanded", faction_id, "", men)
	emit_signal("armies_changed", region_id)
	return true


## Mueve un ejército a una región adyacente; resuelve ocupación o batalla.
func move_army(army_id: String, to_region: String) -> bool:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return false
	var army: Dictionary = GameState.get_army_state(army_id)
	if army.is_empty():
		return false
	var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
	var from_region: String = SafeDict.as_string(army.get("region_id"), "")
	if from_region == "" or to_region == "" or from_region == to_region:
		return false
	if not _is_adjacent(from_region, to_region):
		return false
	if SafeDict.as_int(army.get("movement_left"), 0) <= 0:
		return false
	var cost: int = get_move_cost(army_id, to_region)
	if cost < 0:
		return false
	if not TurnManager.spend_pg_for(faction_id, cost):
		return false
	army["movement_left"] = SafeDict.as_int(army.get("movement_left"), 0) - 1
	var destination: Dictionary = GameState.get_region_state(to_region)
	var owner: String = SafeDict.as_string(destination.get("owner"), "")
	var attacker_faction: String = faction_id
	if owner == "" or owner == attacker_faction:
		army["region_id"] = to_region
		_after_move(army_id, from_region, to_region)
		return true
	# Región enemiga: declarar hostilidades y resolver.
	DiplomacySystem.begin_hostilities(attacker_faction, owner)
	var defenders: Array[String] = _armies_of_faction_in(owner, to_region)
	if defenders.is_empty():
		_occupy_region(to_region, attacker_faction)
		army["region_id"] = to_region
		_after_move(army_id, from_region, to_region)
		return true
	var defender_id: String = _strongest_army_id(defenders)
	_resolve_battle(army_id, defender_id, to_region, from_region)
	return true


## Ejército por id (copia; la UI no debe mutar el estado).
func get_army(army_id: String) -> Dictionary:
	var army: Dictionary = GameState.get_army_state(army_id)
	return army.duplicate(true)


func get_armies_in(region_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("region_id"), "") == region_id:
			result.append(army.duplicate(true))
	return result


## Pool de reclutas disponible en la región (hombres).
func get_recruitment_pool(region_id: String) -> int:
	var region: Dictionary = GameState.get_region_state(region_id)
	return SafeDict.as_int(region.get("recruit_pool"), 0)


## Coste en PG de mover el ejército a la región destino (-1 si es ilegal).
func get_move_cost(army_id: String, to_region: String) -> int:
	var army: Dictionary = GameState.get_army_state(army_id)
	if army.is_empty():
		return -1
	var from_region: String = SafeDict.as_string(army.get("region_id"), "")
	if not _is_adjacent(from_region, to_region):
		return -1
	if SafeDict.as_int(army.get("movement_left"), 0) <= 0:
		return -1
	var destination: Dictionary = GameState.get_region_state(to_region)
	if destination.is_empty():
		return -1
	var terrain: String = SafeDict.as_string(destination.get("terrain"), "plains")
	var penalty: int = SafeDict.as_int(Constants.TERRAIN_MOVE_PENALTY.get(terrain), 0)
	return Constants.MOVE_PG_COST + penalty


## D-084: previsualiza un ataque multi-ejército sin mutar estado ni gastar PG.
func preview_attack(faction_id: String, target_region: String, army_ids: Array = []) -> Dictionary:
	var result: Dictionary = {
		"ok": false,
		"reason": "",
		"target_region": target_region,
		"owner": "",
		"at_war": false,
		"allied": false,
		"eligible_armies": [],
		"selected_ids": [],
		"pg_total": 0,
		"can_attack": false,
	}
	var st: Dictionary = GameState.state
	if st.is_empty():
		result["reason"] = "no_game"
		return result
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var target: Dictionary = GameState.get_region_state(target_region)
	if faction.is_empty() or target.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		result["reason"] = "invalid_target"
		return result
	var owner: String = SafeDict.as_string(target.get("owner"), "")
	result["owner"] = owner
	if owner == faction_id:
		result["reason"] = "own_region"
		return result
	if owner != "" and DiplomacySystem.are_allied(faction_id, owner):
		result["allied"] = true
		result["reason"] = "ally"
		return result
	var at_war: bool = owner != "" and DiplomacySystem.are_at_war(faction_id, owner)
	result["at_war"] = at_war
	var eligible: Array[Dictionary] = []
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		if SafeDict.as_int(army.get("movement_left"), 0) <= 0:
			continue
		var from_region: String = SafeDict.as_string(army.get("region_id"), "")
		if not _is_adjacent(from_region, target_region):
			continue
		var cost: int = get_move_cost(str(army_id), target_region)
		if cost < 0:
			continue
		eligible.append({
			"army_id": str(army_id),
			"region_id": from_region,
			"men": SafeDict.as_int(army.get("men"), 0),
			"move_cost": cost,
		})
	result["eligible_armies"] = eligible
	var selected: Array[String] = []
	if army_ids.is_empty():
		for entry in eligible:
			selected.append(SafeDict.as_string(entry.get("army_id"), ""))
	else:
		for value in army_ids:
			var army_id: String = str(value)
			if selected.has(army_id):
				result["reason"] = "duplicate_army"
				return result
			var found: bool = false
			for entry in eligible:
				if SafeDict.as_string(entry.get("army_id"), "") == army_id:
					found = true
					break
			if not found:
				result["reason"] = "ineligible_army"
				return result
			selected.append(army_id)
	if selected.is_empty():
		result["reason"] = "no_armies"
		return result
	var total: int = 0
	for entry in eligible:
		if selected.has(SafeDict.as_string(entry.get("army_id"), "")):
			total += SafeDict.as_int(entry.get("move_cost"), 0)
	result["selected_ids"] = selected
	result["pg_total"] = total
	result["can_attack"] = true
	# Compatibilidad con UI/QA: también expone `pg_spent` como coste previsto.
	result["pg_spent"] = total
	if SafeDict.as_int(faction.get("pg"), 0) < total:
		result["reason"] = "pg"
		result["can_attack"] = false
		return result
	result["ok"] = true
	result["reason"] = "ok"
	return result


## D-084: ataca una región con uno o varios ejércitos; declara guerra automática
## una sola vez si no hay guerra con el propietario. No cambia fórmulas de combate.
func attack_region(faction_id: String, target_region: String, army_ids: Array = []) -> Dictionary:
	var preview: Dictionary = preview_attack(faction_id, target_region, army_ids)
	var result: Dictionary = {
		"ok": false,
		"reason": SafeDict.as_string(preview.get("reason"), ""),
		"declared_war": false,
		"pg_spent": 0,
		"results": [],
	}
	if not SafeDict.as_bool(preview.get("ok"), false):
		return result
	var target: Dictionary = GameState.get_region_state(target_region)
	var owner: String = SafeDict.as_string(target.get("owner"), "")
	var declared: bool = false
	if owner != "" and not SafeDict.as_bool(preview.get("at_war"), false):
		declared = DiplomacySystem.begin_hostilities(faction_id, owner)
	result["declared_war"] = declared
	var st: Dictionary = GameState.state
	var battles_before: int = SafeDict.as_array(st.get("battle_reports", null)).size()
	var moved_count: int = 0
	var spent: int = 0
	for value in SafeDict.as_array(preview.get("selected_ids", null)):
		var army_id: String = str(value)
		var cost: int = get_move_cost(army_id, target_region)
		if cost < 0:
			result["results"].append({"army_id": army_id, "moved": false, "battle": null})
			continue
		var moved: bool = move_army(army_id, target_region)
		var battle: Variant = null
		var reports: Array = SafeDict.as_array(GameState.state.get("battle_reports", null))
		if moved and reports.size() > battles_before:
			battle = reports[reports.size() - 1]
			battles_before = reports.size()
		if moved:
			moved_count += 1
			spent += cost
		result["results"].append({"army_id": army_id, "moved": moved, "battle": battle})
	result["pg_spent"] = spent
	result["ok"] = moved_count > 0
	result["reason"] = "ok" if moved_count > 0 else "no_armies_moved"
	if result["ok"]:
		GameState.record_turn_action("attack", target_region, spent)
		TutorialSystem.advance_tutorial("attack_launched")
	return result


## Resuelve batallas pendientes (contrato §3.3). Devuelve cuántas resolvió.
func resolve_pending_battles() -> int:
	var count: int = _pending_battles.size()
	_pending_battles.clear()
	return count


## Hombres totales del ejército.
func get_army_men(army_id: String) -> int:
	return _army_men(GameState.get_army_state(army_id))


## Huecos de ejército de una región según edificios.
func get_army_slots(region_id: String) -> int:
	var region: Dictionary = GameState.get_region_state(region_id)
	return _army_slots(region)


## Modelo Army de un ejército del estado (para BattleManager Nivel 2/3, D-029).
func get_army_model(army_id: String) -> ARMY_SCRIPT:
	return _to_army_model(GameState.get_army_state(army_id))


## Modelo RegionState de una región del estado (para BattleManager Nivel 2/3).
func get_region_model(region_id: String) -> REGION_SCRIPT:
	return _to_region_model(region_id, GameState.get_region_state(region_id))


## Aplica el informe de una batalla Nivel 2/3 (D-029): bajas por unidades,
## captura de región, botín y líder caído. Emite battle_resolved una vez.
func apply_battle_outcome(report: Dictionary) -> bool:
	var st: Dictionary = GameState.state
	if st.is_empty() or report.is_empty():
		return false
	var attacker_id: String = SafeDict.as_string(report.get("attacker_army_id"), "")
	var defender_id: String = SafeDict.as_string(report.get("defender_army_id"), "")
	var snapshot: Dictionary = SafeDict.as_dict(report.get("army_snapshot", null))
	if not snapshot.is_empty():
		_apply_army_snapshot(attacker_id, SafeDict.as_array(snapshot.get("attacker", null)))
		_apply_army_snapshot(defender_id, SafeDict.as_array(snapshot.get("defender", null)))
	var region_id: String = SafeDict.as_string(report.get("region_id"), "")
	var attacker_faction: String = SafeDict.as_string(report.get("attacker_faction"), "")
	var defender_faction: String = SafeDict.as_string(report.get("defender_faction"), "")
	if SafeDict.as_bool(report.get("region_captured"), false) and region_id != "" and attacker_faction != "":
		var loot: int = SafeDict.as_int(report.get("loot_gold"), 0)
		if loot > 0:
			var defender_state: Dictionary = GameState.get_faction_state(defender_faction)
			var attacker_state: Dictionary = GameState.get_faction_state(attacker_faction)
			var transferred: int = mini(SafeDict.as_int(defender_state.get("gold"), 0), loot)
			if transferred > 0:
				defender_state["gold"] = SafeDict.as_int(defender_state.get("gold"), 0) - transferred
				attacker_state["gold"] = SafeDict.as_int(attacker_state.get("gold"), 0) + transferred
			report["loot_gold"] = transferred
		_occupy_region(region_id, attacker_faction)
	# Líder caído/cautivo (solo si el informe lo trae; Nivel 1 lo aplica aparte).
	var leader_id: String = SafeDict.as_string(report.get("leader_id"), "")
	var leader_lost: bool = SafeDict.as_bool(report.get("leader_killed"), false) \
		or SafeDict.as_bool(report.get("leader_captured"), false)
	if leader_lost and leader_id != "":
		var character: Dictionary = GameState.get_character_state(leader_id)
		if not character.is_empty() and SafeDict.as_bool(character.get("alive"), false):
			character["alive"] = false
			character["died"] = SafeDict.as_int(st.get("year"), 1337)
			EventBus.emit_signal("character_died", leader_id, "batalla")
			var leader_faction: String = SafeDict.as_string(character.get("faction"), "")
			if leader_faction != "":
				DynastySystem.check_ruling_line(leader_faction)
	var reports: Array = SafeDict.as_array(st.get("battle_reports", null))
	reports.append(report.duplicate(true))
	while reports.size() > Constants.MAX_BATTLE_REPORTS:
		reports.pop_front()
	st["battle_reports"] = reports
	GameState.clear_pending_battle()
	if not SafeDict.as_bool(st.get("game_over"), false):
		AudioManager.play_music("map")
	emit_signal("armies_changed", region_id)
	EventBus.emit_signal("battle_resolved", report.duplicate(true))
	return true


## Aplica un snapshot de unidades (id de origen → efectivos/moral/veteranía).
func _apply_army_snapshot(army_id: String, units_snapshot: Array) -> void:
	var st: Dictionary = GameState.state
	var army: Dictionary = GameState.get_army_state(army_id)
	if army.is_empty():
		return
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var current_units: Array = SafeDict.as_array(army.get("units", null))
	var updated: Array = []
	for unit_value in current_units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		var source_id: String = SafeDict.as_string(unit.get("id"), "")
		var found: bool = false
		var destroyed: bool = false
		for snapshot_value in units_snapshot:
			var snapshot_unit: Dictionary = SafeDict.as_dict(snapshot_value)
			var snapshot_source: String = SafeDict.as_string(snapshot_unit.get("source_unit_id"),
				SafeDict.as_string(snapshot_unit.get("id"), ""))
			if snapshot_source != source_id:
				continue
			found = true
			var new_size: int = SafeDict.as_int(snapshot_unit.get("size"), SafeDict.as_int(unit.get("size"), 0))
			if new_size <= 0:
				destroyed = true
				break
			unit["size"] = new_size
			unit["morale"] = snappedf(SafeDict.as_float(snapshot_unit.get("morale"),
				SafeDict.as_float(unit.get("morale"), 1.0)), 0.001)
			unit["experience"] = SafeDict.as_int(snapshot_unit.get("experience"),
				SafeDict.as_int(unit.get("experience"), 0))
			break
		if destroyed:
			continue
		updated.append(unit)
	if updated.is_empty():
		var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
		armies.erase(army_id)
		emit_signal("army_destroyed", army_id, faction_id)
		EventBus.emit_signal("army_destroyed", army_id, faction_id)
	else:
		army["units"] = updated


# ---------------------------------------------------------------------------
# Batalla delegada
# ---------------------------------------------------------------------------

func _resolve_battle(attacker_id: String, defender_id: String, region_id: String, from_region: String) -> void:
	var st: Dictionary = GameState.state
	var attacker: Dictionary = GameState.get_army_state(attacker_id)
	var defender: Dictionary = GameState.get_army_state(defender_id)
	var region: Dictionary = GameState.get_region_state(region_id)
	if attacker.is_empty() or defender.is_empty() or region.is_empty():
		return
	var attacker_faction: String = SafeDict.as_string(attacker.get("faction_id"), "")
	var defender_faction: String = SafeDict.as_string(defender.get("faction_id"), "")
	EventBus.emit_signal("battle_started", attacker_faction, defender_faction, region_id)
	var attacker_model: ARMY_SCRIPT = _to_army_model(attacker)
	var defender_model: ARMY_SCRIPT = _to_army_model(defender)
	var region_model: REGION_SCRIPT = _to_region_model(region_id, region)
	var report = BattleManager.resolve_delegated(attacker_model, defender_model, region_model,
		BattleManager.STANCE_BALANCED)
	if report == null:
		return
	_write_back_army(attacker_id, attacker_model)
	_write_back_army(defender_id, defender_model)
	var report_dict: Dictionary = report.to_dict()
	report_dict["attacker_army_id"] = attacker_id
	report_dict["defender_army_id"] = defender_id
	var attacker_won: bool = SafeDict.as_bool(report_dict.get("region_captured"), false) \
		or SafeDict.as_string(report_dict.get("winner_faction"), "") == attacker_faction
	if attacker_won:
		var loot: int = SafeDict.as_int(report_dict.get("loot_gold"), 0)
		var defender_state: Dictionary = GameState.get_faction_state(defender_faction)
		var attacker_state: Dictionary = GameState.get_faction_state(attacker_faction)
		var transferred: int = mini(SafeDict.as_int(defender_state.get("gold"), 0), loot)
		if transferred > 0:
			defender_state["gold"] = SafeDict.as_int(defender_state.get("gold"), 0) - transferred
			attacker_state["gold"] = SafeDict.as_int(attacker_state.get("gold"), 0) + transferred
		report_dict["loot_gold"] = transferred
		_occupy_region(region_id, attacker_faction)
		var attacker_after: Dictionary = GameState.get_army_state(attacker_id)
		if not attacker_after.is_empty():
			attacker_after["region_id"] = region_id
	else:
		var attacker_back: Dictionary = GameState.get_army_state(attacker_id)
		if not attacker_back.is_empty():
			attacker_back["region_id"] = from_region
		var defender_after: Dictionary = GameState.get_army_state(defender_id)
		if not defender_after.is_empty():
			defender_after["region_id"] = region_id
	# Muerte/cautiverio del líder derrotado (15%, GDD §6.1).
	var losing_leader: String = ""
	if attacker_won:
		losing_leader = SafeDict.as_string(defender.get("leader_id"), "")
	else:
		losing_leader = SafeDict.as_string(attacker.get("leader_id"), "")
	var leader_lost: bool = SafeDict.as_bool(report_dict.get("leader_killed"), false) \
		or SafeDict.as_bool(report_dict.get("leader_captured"), false)
	if losing_leader != "" and leader_lost:
		var character: Dictionary = GameState.get_character_state(losing_leader)
		if not character.is_empty() and SafeDict.as_bool(character.get("alive"), false):
			character["alive"] = false
			character["died"] = SafeDict.as_int(st.get("year"), 1337)
			EventBus.emit_signal("character_died", losing_leader,
				"capturado" if SafeDict.as_bool(report_dict.get("leader_captured"), false) else "batalla")
			report_dict["leader_id"] = losing_leader
			# Fase 2 (D-031): muerte del gobernante → sucesión o extinción.
			var loser_faction: String = defender_faction if attacker_won else attacker_faction
			DynastySystem.check_ruling_line(loser_faction)
	var reports: Array = SafeDict.as_array(st.get("battle_reports", null))
	reports.append(report_dict)
	while reports.size() > Constants.MAX_BATTLE_REPORTS:
		reports.pop_front()
	st["battle_reports"] = reports
	GameState.clear_pending_battle()
	if not SafeDict.as_bool(st.get("game_over"), false):
		AudioManager.play_music("map")
	emit_signal("armies_changed", region_id)
	EventBus.emit_signal("battle_resolved", report_dict)


func _write_back_army(army_id: String, model: ARMY_SCRIPT) -> void:
	var st: Dictionary = GameState.state
	var army: Dictionary = GameState.get_army_state(army_id)
	if army.is_empty():
		return
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	army["morale"] = snappedf(model.morale, 0.001)
	var new_units: Array = []
	for unit_value in model.units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		var size: int = SafeDict.as_int(unit.get("size"), 0)
		if size <= 0:
			continue
		unit["size"] = size
		unit["morale"] = snappedf(SafeDict.as_float(unit.get("morale"), 1.0), 0.001)
		new_units.append(unit)
	army["units"] = new_units
	if new_units.is_empty():
		var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
		armies.erase(army_id)
		emit_signal("army_destroyed", army_id, faction_id)
		EventBus.emit_signal("army_destroyed", army_id, faction_id)


func _to_army_model(army_state: Dictionary) -> ARMY_SCRIPT:
	var model: ARMY_SCRIPT = ARMY_SCRIPT.new()
	model.apply_dict(army_state)
	return model


func _to_region_model(region_id: String, region_state: Dictionary) -> REGION_SCRIPT:
	var model: REGION_SCRIPT = REGION_SCRIPT.new()
	model.apply_dict({
		"id": region_id,
		"name": SafeDict.as_string(region_state.get("name"), region_id),
		"terrain": SafeDict.as_string(region_state.get("terrain"), "plains"),
		"has_city": SafeDict.as_bool(region_state.get("has_city"), false),
		"owner": SafeDict.as_string(region_state.get("owner"), ""),
		"population": SafeDict.as_int(region_state.get("population"), 1000),
		"base_wealth": SafeDict.as_int(region_state.get("base_wealth"), 50),
		"buildings": SafeDict.as_array(region_state.get("buildings", null)).duplicate(),
		"support": SafeDict.as_int(region_state.get("support"), Constants.SUPPORT_DEFAULT),
	})
	return model


# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

func _after_move(army_id: String, from_region: String, to_region: String) -> void:
	emit_signal("army_moved", army_id, from_region, to_region)
	emit_signal("armies_changed", to_region)
	emit_signal("armies_changed", from_region)
	EventBus.emit_signal("army_moved", army_id, from_region, to_region)


func _occupy_region(region_id: String, faction_id: String) -> void:
	var region: Dictionary = GameState.get_region_state(region_id)
	if region.is_empty():
		return
	var previous_owner: String = SafeDict.as_string(region.get("owner"), "")
	region["owner"] = faction_id
	region["support"] = Constants.REVOLT_SUPPORT_RESET
	EventBus.emit_signal("region_captured", region_id, faction_id)
	emit_signal("region_captured", region_id, faction_id)
	if previous_owner != "":
		EventBus.emit_signal("ui_notification", "%s ha sido conquistada." % region_id, 2)


func _is_adjacent(from_region: String, to_region: String) -> bool:
	if from_region == "" or to_region == "" or from_region == to_region:
		return false
	var definition: Dictionary = DataLoader.get_region(from_region)
	var adjacency: Array = SafeDict.as_array(definition.get("adjacency", null))
	return adjacency.has(to_region)


func _army_slots(region: Dictionary) -> int:
	var slots: int = Constants.ARMY_BASE_SLOTS_PER_REGION
	var buildings: Array = SafeDict.as_array(region.get("buildings", null))
	if buildings.has("castle"):
		slots += Constants.ARMY_SLOT_CASTLE
	if buildings.has("walls"):
		slots += Constants.ARMY_SLOT_WALLS
	return slots


func _army_id_of(faction_id: String, region_id: String) -> String:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return army_id
	return ""


func _armies_of_faction_in(faction_id: String, region_id: String) -> Array[String]:
	var result: Array[String] = []
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			result.append(army_id)
	return result


func _strongest_army_id(army_ids: Array[String]) -> String:
	var best_id: String = ""
	var best_men: int = -1
	for army_id in army_ids:
		var men: int = _army_men(GameState.get_army_state(army_id))
		if men > best_men:
			best_men = men
			best_id = army_id
	return best_id


func _army_men(army: Dictionary) -> int:
	var total: int = 0
	var units: Array = SafeDict.as_array(army.get("units", null))
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		total += SafeDict.as_int(unit.get("size"), 0)
	return total


func _faction_has_leader(faction_id: String) -> bool:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		if SafeDict.as_string(army.get("leader_id"), "") != "":
			return true
	return false


func _unit_allowed_for(unit_definition: Dictionary, faction_id: String) -> bool:
	var tags: Array = SafeDict.as_array(unit_definition.get("faction_tags", null))
	if faction_id != "" and not tags.is_empty() and not tags.has(faction_id):
		return false
	# D-059: era tecnológica actual + año histórico mínimo (`available_from`).
	var year: int = SafeDict.as_int(GameState.state.get("year"), 1337)
	return TechScript.is_unit_available(unit_definition, year)


func _current_era() -> int:
	return TechScript.era_index(SafeDict.as_int(GameState.state.get("year"), 1337))


## Ids de unidades reclutables por la facción con la era/año actuales (D-059).
func get_available_units(faction_id: String = "") -> Array[String]:
	var result: Array[String] = []
	for unit_id in DataLoader.get_unit_ids():
		var definition: Dictionary = DataLoader.get_unit(unit_id)
		if definition.is_empty():
			continue
		if not _unit_allowed_for(definition, faction_id):
			continue
		result.append(unit_id)
	return result


## True si la unidad está disponible ahora para la facción (era/tags/año).
func is_unit_available(unit_id: String, faction_id: String = "") -> bool:
	var definition: Dictionary = DataLoader.get_unit(unit_id)
	return not definition.is_empty() and _unit_allowed_for(definition, faction_id)
