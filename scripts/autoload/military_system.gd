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

const ARMY_SCRIPT = preload("res://scripts/model/army.gd")
const REGION_SCRIPT = preload("res://scripts/model/region_state.gd")

## Batallas pendientes de resolver al cierre del turno (normalmente vacío: la
## batalla se resuelve en el propio `move_army` para que la UI muestre el informe).
var _pending_battles: Array[Dictionary] = []


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
	var st: Dictionary = GameState.state
	if st.is_empty() or amount <= 0:
		return false
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var region: Dictionary = GameState.get_region_state(region_id)
	if faction.is_empty() or region.is_empty():
		return false
	if SafeDict.as_bool(faction.get("eliminated"), false):
		return false
	if SafeDict.as_string(region.get("owner"), "") != faction_id:
		return false
	var unit_definition: Dictionary = DataLoader.get_unit(unit_id)
	if unit_definition.is_empty():
		return false
	if not _unit_allowed_for(unit_definition, faction_id):
		return false
	var pool: int = SafeDict.as_int(region.get("recruit_pool"), 0)
	if pool < amount:
		return false
	var blocks: int = int(ceilf(float(amount) / float(Constants.UNIT_MEN_PER_BLOCK)))
	var cost: Dictionary = SafeDict.as_dict(unit_definition.get("cost", null))
	var gold_cost: int = blocks * SafeDict.as_int(cost.get("gold"), 0)
	var gold: int = SafeDict.as_int(faction.get("gold"), 0)
	if gold < gold_cost:
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
	emit_signal("recruitment_completed", faction_id, region_id, unit_id)
	EventBus.emit_signal("recruitment_completed", faction_id, region_id, unit_id)
	emit_signal("armies_changed", region_id)
	EventBus.emit_signal("treasury_changed", faction_id, SafeDict.as_int(faction.get("gold"), 0))
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


func disband_army(army_id: String) -> bool:
	var st: Dictionary = GameState.state
	var army: Dictionary = GameState.get_army_state(army_id)
	if st.is_empty() or army.is_empty():
		return false
	var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
	var region_id: String = SafeDict.as_string(army.get("region_id"), "")
	var region: Dictionary = GameState.get_region_state(region_id)
	var men: int = _army_men(army)
	if not region.is_empty():
		var returned: int = int(roundf(float(men) * 0.5))
		region["recruit_pool"] = SafeDict.as_int(region.get("recruit_pool"), 0) + returned
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	armies.erase(army_id)
	emit_signal("army_destroyed", army_id, faction_id)
	EventBus.emit_signal("army_destroyed", army_id, faction_id)
	emit_signal("armies_changed", region_id)
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
	if not tags.is_empty() and not tags.has(faction_id):
		return false
	var available_from: int = SafeDict.as_int(unit_definition.get("available_from"), 0)
	if available_from > 0 and SafeDict.as_int(GameState.state.get("year"), 1337) < available_from:
		return false
	var era_range: Array = SafeDict.as_array(unit_definition.get("era", null))
	if era_range.size() >= 2:
		var era: int = _current_era()
		var era_min: int = SafeDict.as_int(era_range[0], 1)
		var era_max: int = SafeDict.as_int(era_range[1], 3)
		if era < era_min or era > era_max:
			return false
	return true


func _current_era() -> int:
	var year: int = SafeDict.as_int(GameState.state.get("year"), 1337)
	return clampi(1 + int(float(year - 1337) / 21.0), 1, 3)
