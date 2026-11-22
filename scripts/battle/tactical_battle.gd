class_name TacticalBattle
extends Node
## Batalla Nivel 2 — mapa táctico hexagonal (GDD §6.2, contrato Fase 2 §4, D-029).
##
## Lógica pura, sin UI: el llamador (AG-3) lo añade al árbol y pinta `get_state()`.
## `BattleManager.launch_tactical()` devuelve el nodo ya configurado (no lo añade
## al árbol) y emite `EventBus.tactical_battle_started`.
##
## - Mapa axial de radio 4 (5 si la región es ciudad) derivado del terreno:
##   `plains / forest / hills / river / city`, con objetivos (ciudad, puente,
##   retaguardias) y valores de victoria.
## - Unidades derivadas del modelo `Army` (efectivos, moral, veteranía, comandante).
## - Iniciativa por rondas: el jugador actúa, `end_round()` resuelve la IA del
##   bando no jugador y avanza la ronda.
## - `commit()` es PURO; `apply_outcome()` aplica bajas/captura/botín vía
##   `MilitarySystem.apply_battle_outcome()` (una sola vez).
## - Toda tirada de combate sale de `GameState.rng` → determinismo por semilla.
##   El mapa se deriva del hash del region_id (también determinista y estable).

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")
const ARMY_SCRIPT = preload("res://scripts/model/army.gd")
const REGION_SCRIPT = preload("res://scripts/model/region_state.gd")
const CLOSE_COMBAT_SCRIPT = preload("res://scripts/battle/close_combat.gd")

const TERRAINS: Array[String] = ["plains", "forest", "hills", "river", "city"]

var battle_id: String = ""
var attacker_faction: String = ""
var defender_faction: String = ""
var region_id: String = ""
var round: int = 1
## Bando con la iniciativa: "attacker" | "defender".
var side: String = "attacker"
var winner: String = ""
var finished: bool = false
var player_side: String = "attacker"

var _attacker_army_id: String = ""
var _defender_army_id: String = ""
var _units: Array[Dictionary] = []
var _hexes: Dictionary = {}
var _objectives: Array[Dictionary] = []
var _selected_unit_id: String = ""
var _round_limit: int = Constants.TACTICAL_MAX_ROUNDS
var _start_men: Dictionary = {}
## Hombres iniciales por bando, incluidos los de unidades que mueran después
## (B-F2-01: las bajas del informe no deben depender de las unidades actuales).
var _start_men_by_side: Dictionary = {"attacker": 0, "defender": 0}
var _commander_stat: Dictionary = {}
var _commander_bonus: Dictionary = {}
var _region_wealth: int = 50
var _region_name: String = ""
var _log: Array[Dictionary] = []
var _applied: bool = false


## Configura la batalla a partir de los modelos del sistema militar.
func setup(attacker_army: ARMY_SCRIPT, defender_army: ARMY_SCRIPT, region: REGION_SCRIPT, p_player_side: String = "attacker") -> void:
	if attacker_army == null or defender_army == null:
		finished = true
		return
	attacker_faction = attacker_army.faction_id
	defender_faction = defender_army.faction_id
	_attacker_army_id = attacker_army.id
	_defender_army_id = defender_army.id
	region_id = region.id if region != null else attacker_army.region_id
	_region_name = region.name if region != null else region_id
	_region_wealth = region.base_wealth if region != null else 50
	player_side = p_player_side if (p_player_side == "attacker" or p_player_side == "defender") else "attacker"
	side = player_side
	_round_limit = Constants.TACTICAL_MAX_ROUNDS
	var seed_value: int = GameState.rng_seed
	if GameState.rng != null:
		seed_value = GameState.rng.get_seed()
	battle_id = "tac_%s_%s_%s_%d" % [region_id, attacker_faction, defender_faction, seed_value]
	_log.clear()
	_round_log_clear()
	# B-F2-01: reiniciar bajas/start-men por si se reutiliza el nodo.
	_units = []
	_start_men = {}
	_start_men_by_side = {"attacker": 0, "defender": 0}
	_commander_stat = {
		"attacker": _commander_stat_for(attacker_army.leader_id, attacker_faction),
		"defender": _commander_stat_for(defender_army.leader_id, defender_faction),
	}
	_commander_bonus = {
		"attacker": snappedf(1.0 + (float(_commander_stat["attacker"]) - 50.0) / Constants.BATTLE_COMMANDER_STAT_RANGE, 0.001),
		"defender": snappedf(1.0 + (float(_commander_stat["defender"]) - 50.0) / Constants.BATTLE_COMMANDER_STAT_RANGE, 0.001),
	}
	_build_map(region)
	_spawn_units(attacker_army, "attacker")
	_spawn_units(defender_army, "defender")
	round = 1
	finished = false
	winner = ""
	_applied = false
	_log_append("start", "Comienza la batalla táctica de %s" % _region_name)


# ---------------------------------------------------------------------------
# API pública (contrato §4)
# ---------------------------------------------------------------------------

func get_state() -> Dictionary:
	return {
		"battle_id": battle_id,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"region_id": region_id,
		"round": round,
		"side": side,
		"winner": winner,
		"finished": finished,
		"objectives": get_objectives(),
		"hexes": get_hexes(),
		"units": get_units(),
		"commander_bonus": _commander_bonus.duplicate(true),
	}


func get_hexes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in SafeDict.sorted_keys(_hexes):
		result.append(SafeDict.as_dict(_hexes.get(key, null)).duplicate(true))
	return result


func get_units() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		result.append(unit.duplicate(true))
	return result


func get_unit(unit_id: String) -> Dictionary:
	var unit: Dictionary = _find_unit(unit_id)
	return unit.duplicate(true)


func get_objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for objective_value in _objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		result.append(objective.duplicate(true))
	return result


func get_round_log() -> Array[Dictionary]:
	return _round_log.duplicate(true)


func select_unit(unit_id: String) -> void:
	_selected_unit_id = ""
	if not _find_unit(unit_id).is_empty():
		_selected_unit_id = unit_id


func get_selected_unit_id() -> String:
	return _selected_unit_id


func can_move_unit(unit_id: String, q: int, r: int) -> bool:
	return _can_move_unit(unit_id, q, r)


## Hexes alcanzables con los puntos de movimiento y coste de terreno actuales.
func get_reachable_hexes(unit_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty() or finished:
		return result
	var origin_q: int = SafeDict.as_int(unit.get("q"), 0)
	var origin_r: int = SafeDict.as_int(unit.get("r"), 0)
	var moves: int = SafeDict.as_int(unit.get("moves_left"), 0)
	if moves <= 0:
		return result
	var visited: Dictionary = {}
	var frontier: Array[Dictionary] = [{"q": origin_q, "r": origin_r, "cost": 0}]
	while not frontier.is_empty():
		var current: Dictionary = SafeDict.as_dict(frontier.pop_front())
		var current_q: int = SafeDict.as_int(current.get("q"), 0)
		var current_r: int = SafeDict.as_int(current.get("r"), 0)
		var current_cost: int = SafeDict.as_int(current.get("cost"), 0)
		for neighbour in _neighbours(current_q, current_r):
			var next_q: int = SafeDict.as_int(neighbour.get("q"), 0)
			var next_r: int = SafeDict.as_int(neighbour.get("r"), 0)
			var key := _hex_key(next_q, next_r)
			if not _hexes.has(key):
				continue
			if not _is_hex_free(next_q, next_r, unit_id):
				continue
			var hex: Dictionary = SafeDict.as_dict(_hexes.get(key, null))
			var terrain: String = SafeDict.as_string(hex.get("terrain"), "plains")
			var step_cost: int = SafeDict.as_int(Constants.TACTICAL_MOVE_COST.get(terrain), 1)
			var total_cost: int = current_cost + step_cost
			if total_cost > moves:
				continue
			var previous_cost: int = SafeDict.as_int(visited.get(key), 999)
			if total_cost >= previous_cost:
				continue
			visited[key] = total_cost
			frontier.append({"q": next_q, "r": next_r, "cost": total_cost})
	for key in SafeDict.sorted_keys(visited):
		var cost: int = SafeDict.as_int(visited.get(key, 0), 0)
		var parts: PackedStringArray = str(key).split(",")
		if parts.size() != 2:
			continue
		var q: int = parts[0].to_int()
		var r: int = parts[1].to_int()
		var hex: Dictionary = SafeDict.as_dict(_hexes.get(key, null))
		result.append({
			"q": q,
			"r": r,
			"terrain": SafeDict.as_string(hex.get("terrain"), "plains"),
			"cost": cost,
			"objective": SafeDict.as_string(hex.get("objective"), ""),
			"occupied": false,
		})
	result.sort_custom(_compare_hexes)
	return result


func move_unit(unit_id: String, q: int, r: int) -> bool:
	if finished:
		return false
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty():
		return false
	if _side_of_unit(unit) != side:
		return false
	if not _can_move_unit(unit_id, q, r):
		return false
	var origin_q: int = SafeDict.as_int(unit.get("q"), 0)
	var origin_r: int = SafeDict.as_int(unit.get("r"), 0)
	var destination: Dictionary = SafeDict.as_dict(_hexes.get(_hex_key(q, r), null))
	var terrain: String = SafeDict.as_string(destination.get("terrain"), "plains")
	var cost: int = SafeDict.as_int(Constants.TACTICAL_MOVE_COST.get(terrain), 1)
	unit["q"] = q
	unit["r"] = r
	unit["moves_left"] = maxi(0, SafeDict.as_int(unit.get("moves_left"), 0) - cost)
	_capture_objective_at(q, r, SafeDict.as_string(unit.get("faction"), ""))
	_log_append("move", "%s se mueve de (%d,%d) a (%d,%d)" % [unit_id, origin_q, origin_r, q, r])
	_check_finish()
	return true


func attack_unit(attacker_id: String, defender_id: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "attacker_id": attacker_id, "defender_id": defender_id}
	if finished:
		return result
	var attacker: Dictionary = _find_unit(attacker_id)
	var defender: Dictionary = _find_unit(defender_id)
	if attacker.is_empty() or defender.is_empty():
		result["reason"] = "unknown_unit"
		return result
	if _side_of_unit(attacker) == _side_of_unit(defender):
		result["reason"] = "same_side"
		return result
	if _side_of_unit(attacker) != side:
		result["reason"] = "not_side_turn"
		return result
	if SafeDict.as_int(attacker.get("orders_left"), 0) <= 0:
		result["reason"] = "no_orders"
		return result
	var distance: int = _hex_distance(
		SafeDict.as_int(attacker.get("q"), 0), SafeDict.as_int(attacker.get("r"), 0),
		SafeDict.as_int(defender.get("q"), 0), SafeDict.as_int(defender.get("r"), 0))
	var unit_type: String = SafeDict.as_string(attacker.get("type"), "infantry")
	var is_ranged: bool = unit_type == "ranged" or unit_type == "artillery"
	if distance > 1:
		if not is_ranged or distance > Constants.TACTICAL_RANGED_RANGE:
			result["reason"] = "out_of_range"
			return result
	var rng: SeededRNGScript = _rng()
	var attack_power: float = _unit_power(attacker) * _commander_bonus_for(_side_of_unit(attacker))
	if distance > 1:
		attack_power *= Constants.TACTICAL_RANGED_PENALTY
	var defense_hex: Dictionary = SafeDict.as_dict(_hexes.get(_hex_key(
		SafeDict.as_int(defender.get("q"), 0), SafeDict.as_int(defender.get("r"), 0)), null))
	var defense_terrain: String = SafeDict.as_string(defense_hex.get("terrain"), "plains")
	var defense_power: float = _unit_power(defender) * _commander_bonus_for(_side_of_unit(defender)) \
		* SafeDict.as_float(Constants.TACTICAL_DEFENSE_TERRAIN.get(defense_terrain), 1.0)
	var roll: float = rng.gaussian(1.0, 0.15)
	var ratio: float = attack_power / maxf(attack_power + defense_power, 1.0)
	var defender_loss_fraction: float = clampf(ratio * 0.5 * roll, 0.0, 0.5)
	var attacker_loss_fraction: float = clampf((1.0 - ratio) * 0.5 / maxf(roll, 0.3), 0.0, 0.4)
	var defender_losses: int = _apply_unit_damage(defender, defender_loss_fraction)
	var attacker_losses: int = _apply_unit_damage(attacker, attacker_loss_fraction)
	attacker["orders_left"] = maxi(0, SafeDict.as_int(attacker.get("orders_left"), 0) - 1)
	result["ok"] = true
	result["distance"] = distance
	result["attack_power"] = snappedf(attack_power, 0.01)
	result["defense_power"] = snappedf(defense_power, 0.01)
	result["defender_losses"] = defender_losses
	result["attacker_losses"] = attacker_losses
	result["defender_destroyed"] = _is_unit_destroyed(defender)
	result["attacker_destroyed"] = _is_unit_destroyed(attacker)
	result["winner"] = _side_of_unit(attacker) if result["defender_destroyed"] else ""
	_log_append("attack", "%s ataca a %s: -%d / -%d" % [attacker_id, defender_id, defender_losses, attacker_losses])
	if result["defender_destroyed"]:
		_remove_destroyed_unit(defender_id)
	if result["attacker_destroyed"]:
		_remove_destroyed_unit(attacker_id)
	_check_finish()
	return result


## Choque de una unidad resuelto con la mecánica del Nivel 3 (cartas).
func resolve_duel(attacker_unit_id: String, defender_unit_id: String, order_id: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "order": order_id}
	if finished:
		return result
	var attacker: Dictionary = _find_unit(attacker_unit_id)
	var defender: Dictionary = _find_unit(defender_unit_id)
	if attacker.is_empty() or defender.is_empty():
		result["reason"] = "unknown_unit"
		return result
	if _side_of_unit(attacker) == _side_of_unit(defender):
		result["reason"] = "same_side"
		return result
	if SafeDict.as_int(attacker.get("orders_left"), 0) <= 0:
		result["reason"] = "no_orders"
		return result
	var duel: CLOSE_COMBAT_SCRIPT = CLOSE_COMBAT_SCRIPT.new()
	var attacker_input: Dictionary = attacker.duplicate(true)
	var defender_input: Dictionary = defender.duplicate(true)
	attacker_input["commander_stat"] = _commander_stat_for(
		SafeDict.as_string(attacker.get("source_leader"), ""), SafeDict.as_string(attacker.get("faction"), ""))
	defender_input["commander_stat"] = _commander_stat_for(
		SafeDict.as_string(defender.get("source_leader"), ""), SafeDict.as_string(defender.get("faction"), ""))
	attacker_input["terrain"] = _terrain_at(SafeDict.as_int(attacker.get("q"), 0), SafeDict.as_int(attacker.get("r"), 0))
	defender_input["terrain"] = _terrain_at(SafeDict.as_int(defender.get("q"), 0), SafeDict.as_int(defender.get("r"), 0))
	duel.setup(attacker_input, defender_input)
	var played: bool = duel.play_order(order_id)
	if not played:
		result["reason"] = "invalid_order"
		duel.free()
		return result
	var round_result: Dictionary = duel.enemy_respond()
	var outcome: Dictionary = duel.get_outcome()
	var attacker_losses: int = SafeDict.as_int(outcome.get("attacker_losses"), 0)
	var defender_losses: int = SafeDict.as_int(outcome.get("defender_losses"), 0)
	_apply_losses_absolute(attacker, attacker_losses)
	_apply_losses_absolute(defender, defender_losses)
	attacker["orders_left"] = maxi(0, SafeDict.as_int(attacker.get("orders_left"), 0) - 1)
	result["ok"] = true
	result["round"] = round_result
	result["outcome"] = outcome
	result["attacker_losses"] = attacker_losses
	result["defender_losses"] = defender_losses
	result["defender_destroyed"] = _is_unit_destroyed(defender)
	result["attacker_destroyed"] = _is_unit_destroyed(attacker)
	result["winner"] = _side_of_unit(attacker) if result["defender_destroyed"] else ""
	if result["defender_destroyed"]:
		_remove_destroyed_unit(defender_unit_id)
	if result["attacker_destroyed"]:
		_remove_destroyed_unit(attacker_unit_id)
	_log_append("duel", "Duelo %s vs %s con carta %s" % [attacker_unit_id, defender_unit_id, order_id])
	duel.free()
	_check_finish()
	return result


## Ejecuta la IA del bando no jugador, comprueba fin y avanza la ronda.
func end_round() -> void:
	if finished:
		return
	var enemy_side: String = _enemy_side()
	_run_ai_side(enemy_side)
	_check_finish()
	if finished:
		_finish()
		return
	_advance_round()


## Juega la batalla completa con IA en ambos bandos (headless/QA).
func auto_resolve() -> Dictionary:
	var guard: int = 0
	while not finished and guard < Constants.TACTICAL_MAX_ROUNDS * 3:
		guard += 1
		_run_ai_side(player_side)
		_check_finish()
		if finished:
			_finish()
			break
		_run_ai_side(_enemy_side())
		_check_finish()
		if finished:
			_finish()
			break
		_advance_round()
	if not finished:
		_finish_by_score()
	return commit()


func is_finished() -> bool:
	return finished


func get_winner() -> String:
	return winner


## Informe BattleReport-compatible (PURO: no muta estado ni emite señales).
func commit() -> Dictionary:
	var attacker_losses: int = _side_start_men("attacker") - _side_current_men("attacker")
	var defender_losses: int = _side_start_men("defender") - _side_current_men("defender")
	var attacker_won: bool = finished and winner == attacker_faction
	return {
		"level": 2,
		"battle_id": battle_id,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"region_id": region_id,
		"attacker_army_id": _attacker_army_id,
		"defender_army_id": _defender_army_id,
		"winner_faction": winner,
		"attacker_losses": maxi(0, attacker_losses),
		"defender_losses": maxi(0, defender_losses),
		"rounds": _round_log.duplicate(true),
		"rounds_played": round,
		"region_captured": attacker_won,
		"loot_gold": int(roundf(float(_region_wealth) * Constants.LOOT_GOLD_PER_WEALTH)) if attacker_won else 0,
		"leader_killed": false,
		"leader_captured": false,
		"objectives": get_objectives(),
		"army_snapshot": {
			"attacker": _snapshot_side("attacker"),
			"defender": _snapshot_side("defender"),
		},
		"notes": "Nivel 2 táctico en %s: vence %s tras %d ronda(s); bajas %d/%d" % [
			_region_name, winner if winner != "" else "nadie", round,
			maxi(0, attacker_losses), maxi(0, defender_losses),
		],
	}


## Aplica el resultado al estado de la partida (una sola vez). Emite
## `EventBus.battle_resolved` (dentro de MilitarySystem) y tactical_battle_finished.
func apply_outcome() -> void:
	if _applied or not finished:
		return
	var report: Dictionary = commit()
	if not MilitarySystem.apply_battle_outcome(report):
		return
	_applied = true
	EventBus.emit_signal("tactical_battle_finished", winner, region_id)


# ---------------------------------------------------------------------------
# Mapa y unidades
# ---------------------------------------------------------------------------

func _build_map(region: REGION_SCRIPT) -> void:
	_hexes.clear()
	_objectives.clear()
	var terrain: String = "plains"
	var has_city: bool = false
	if region != null:
		terrain = region.terrain
		has_city = region.has_city
	var radius: int = Constants.TACTICAL_RADIUS
	if has_city or terrain == "city":
		radius = Constants.TACTICAL_RADIUS_CITY
	var river_offset: int = (absi(region_id.hash()) % 3) - 1
	if river_offset == 0:
		river_offset = 1
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if _hex_distance(0, 0, q, r) > radius:
				continue
			var hex_terrain: String = "plains"
			if r == river_offset:
				hex_terrain = "river"
			elif _hex_distance(0, 0, q, r) >= 2 and q < 0 and r > 0:
				hex_terrain = "hills"
			elif terrain == "forest" and ((absi(q) * 7 + absi(r) * 13 + absi(region_id.hash())) % 5 == 0):
				hex_terrain = "forest"
			if has_city and _hex_distance(0, 0, q, r) <= 1:
				hex_terrain = "city"
			_hexes[_hex_key(q, r)] = {"q": q, "r": r, "terrain": hex_terrain, "objective": ""}
	_add_objective("obj_city", "Ciudad" if has_city else "Campamento", 0, 0, "city",
		Constants.TACTICAL_OBJECTIVE_CITY_VALUE, "")
	var bridge_q: int = 0
	while not _hexes.has(_hex_key(bridge_q, river_offset)):
		bridge_q += 1
	_add_objective("obj_bridge", "Puente", bridge_q, river_offset, "bridge",
		Constants.TACTICAL_OBJECTIVE_BRIDGE_VALUE, "")
	_add_objective("obj_rear_attacker", "Retaguardia atacante", -radius, 0, "rearguard",
		Constants.TACTICAL_OBJECTIVE_REAR_VALUE, "attacker")
	_add_objective("obj_rear_defender", "Retaguardia defensora", radius, 0, "rearguard",
		Constants.TACTICAL_OBJECTIVE_REAR_VALUE, "defender")


func _add_objective(objective_id: String, objective_name: String, q: int, r: int, kind: String, value: int, objective_side: String) -> void:
	var key := _hex_key(q, r)
	if not _hexes.has(key):
		return
	var hex: Dictionary = SafeDict.as_dict(_hexes.get(key, null))
	hex["objective"] = objective_id
	_hexes[key] = hex
	_objectives.append({
		"id": objective_id,
		"name": objective_name,
		"q": q,
		"r": r,
		"kind": kind,
		"side": objective_side,
		"value": value,
		"captured_by": "",
	})


func _spawn_units(army: ARMY_SCRIPT, unit_side: String) -> void:
	var faction_id: String = army.faction_id
	var spawn_hexes: Array[Dictionary] = _spawn_hexes(unit_side)
	var spawn_index: int = 0
	var unit_index: int = 0
	var source_leader: String = army.leader_id
	for unit_value in army.units:
		var source: Dictionary = SafeDict.as_dict(unit_value)
		var size: int = SafeDict.as_int(source.get("size"), 0)
		if size <= 0:
			continue
		var unit_id: String = "%s_%s_%d" % [unit_side, SafeDict.as_string(source.get("id"), "u"), unit_index]
		var unit_definition: Dictionary = DataLoader.get_unit(SafeDict.as_string(source.get("unit_id"), ""))
		var unit_type: String = SafeDict.as_string(unit_definition.get("type"), "infantry")
		var moves: int = clampi(SafeDict.as_int(unit_definition.get("move"), Constants.TACTICAL_DEFAULT_MOVES), 1, Constants.TACTICAL_MAX_MOVES)
		var spawn: Dictionary = SafeDict.as_dict(spawn_hexes[mini(spawn_index, spawn_hexes.size() - 1)])
		spawn_index += 1
		var unit: Dictionary = {
			"id": unit_id,
			"source_unit_id": SafeDict.as_string(source.get("id"), unit_id),
			"source_leader": source_leader,
			"faction": faction_id,
			"side": unit_side,
			"unit_id": SafeDict.as_string(source.get("unit_id"), ""),
			"type": unit_type,
			"size": size,
			"strength": SafeDict.as_int(source.get("strength"), SafeDict.as_int(unit_definition.get("strength"), 1)),
			"morale": clampf(SafeDict.as_float(source.get("morale"), 1.0), 0.0, 1.0),
			"experience": SafeDict.as_int(source.get("experience"), 0),
			"commander": unit_index == 0 and source_leader != "",
			"q": SafeDict.as_int(spawn.get("q"), 0),
			"r": SafeDict.as_int(spawn.get("r"), 0),
			"moves_left": moves,
			"max_moves": moves,
			"orders_left": 1,
		}
		_units.append(unit)
		_start_men[unit_id] = size
		_start_men_by_side[unit_side] = SafeDict.as_int(_start_men_by_side.get(unit_side), 0) + size
		unit_index += 1


func _spawn_hexes(unit_side: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in SafeDict.sorted_keys(_hexes):
		var hex: Dictionary = SafeDict.as_dict(_hexes.get(key, null))
		var q: int = SafeDict.as_int(hex.get("q"), 0)
		var r: int = SafeDict.as_int(hex.get("r"), 0)
		var distance: int = _hex_distance(0, 0, q, r)
		if unit_side == "attacker":
			if q > -2:
				continue
		else:
			if q < 2:
				continue
		# Los hexes de objetivo se dejan libres para poder capturarlos.
		if SafeDict.as_string(hex.get("objective"), "") != "":
			continue
		if not _is_hex_free(q, r, ""):
			continue
		result.append({"q": q, "r": r, "distance": distance})
	result.sort_custom(_compare_spawn_hexes)
	return result


func _compare_spawn_hexes(left: Dictionary, right: Dictionary) -> bool:
	var left_distance: int = SafeDict.as_int(left.get("distance"), 99)
	var right_distance: int = SafeDict.as_int(right.get("distance"), 99)
	if left_distance != right_distance:
		return left_distance < right_distance
	return _hex_key(SafeDict.as_int(left.get("q"), 0), SafeDict.as_int(left.get("r"), 0)) \
		< _hex_key(SafeDict.as_int(right.get("q"), 0), SafeDict.as_int(right.get("r"), 0))


func _compare_hexes(left: Dictionary, right: Dictionary) -> bool:
	var left_cost: int = SafeDict.as_int(left.get("cost"), 0)
	var right_cost: int = SafeDict.as_int(right.get("cost"), 0)
	if left_cost != right_cost:
		return left_cost < right_cost
	return _hex_key(SafeDict.as_int(left.get("q"), 0), SafeDict.as_int(left.get("r"), 0)) \
		< _hex_key(SafeDict.as_int(right.get("q"), 0), SafeDict.as_int(right.get("r"), 0))


# ---------------------------------------------------------------------------
# Rondas, IA y fin de batalla
# ---------------------------------------------------------------------------

func _advance_round() -> void:
	round += 1
	if round > _round_limit:
		_finish_by_score()
		return
	_reset_units_for_round()
	side = player_side
	_log_append("round", "Comienza la ronda %d" % round)


func _reset_units_for_round() -> void:
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		unit["moves_left"] = SafeDict.as_int(unit.get("max_moves"), Constants.TACTICAL_DEFAULT_MOVES)
		unit["orders_left"] = 1


func _run_ai_side(ai_side: String) -> void:
	var unit_ids: Array[String] = []
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == ai_side:
			unit_ids.append(SafeDict.as_string(unit.get("id"), ""))
	unit_ids.sort()
	for unit_id in unit_ids:
		if finished:
			return
		var unit: Dictionary = _find_unit(unit_id)
		if unit.is_empty():
			continue
		_ai_act_unit(unit_id, ai_side)


func _ai_act_unit(unit_id: String, ai_side: String) -> void:
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty():
		return
	var enemy_side: String = "defender" if ai_side == "attacker" else "attacker"
	# 1) Choque: atacar al enemigo adyacente más débil (o a tiro si es a distancia).
	var target_id: String = _weakest_enemy_in_range(unit_id, enemy_side)
	if target_id != "":
		attack_unit(unit_id, target_id)
		return
	# 2) Objetivos: avanzar hacia la retaguardia enemiga / objetivo más valioso.
	var target_hex: Dictionary = _ai_target_hex(unit_id, ai_side)
	if target_hex.is_empty():
		return
	var steps: int = 0
	while steps < 4 and not finished:
		steps += 1
		var current: Dictionary = _find_unit(unit_id)
		if current.is_empty():
			return
		var move_step: Dictionary = _best_step_towards(unit_id, target_hex)
		if move_step.is_empty():
			break
		if not move_unit(unit_id, SafeDict.as_int(move_step.get("q"), 0), SafeDict.as_int(move_step.get("r"), 0)):
			break
		var adjacent_target: String = _weakest_enemy_in_range(unit_id, enemy_side)
		if adjacent_target != "" and SafeDict.as_int(_find_unit(unit_id).get("orders_left"), 0) > 0:
			attack_unit(unit_id, adjacent_target)
			break


func _weakest_enemy_in_range(unit_id: String, enemy_side: String) -> String:
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty():
		return ""
	var unit_type: String = SafeDict.as_string(unit.get("type"), "infantry")
	var max_range: int = 1
	if unit_type == "ranged" or unit_type == "artillery":
		max_range = Constants.TACTICAL_RANGED_RANGE
	var best_id: String = ""
	var best_size: int = 999999999
	for other_value in _units:
		var other: Dictionary = SafeDict.as_dict(other_value)
		if SafeDict.as_string(other.get("side"), "") != enemy_side:
			continue
		var distance: int = _hex_distance(
			SafeDict.as_int(unit.get("q"), 0), SafeDict.as_int(unit.get("r"), 0),
			SafeDict.as_int(other.get("q"), 0), SafeDict.as_int(other.get("r"), 0))
		if distance > max_range:
			continue
		var size: int = SafeDict.as_int(other.get("size"), 0)
		if size < best_size:
			best_size = size
			best_id = SafeDict.as_string(other.get("id"), "")
	return best_id


func _ai_target_hex(unit_id: String, ai_side: String) -> Dictionary:
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty():
		return {}
	var enemy_side: String = "defender" if ai_side == "attacker" else "attacker"
	var best_objective: Dictionary = {}
	var best_score: int = -999999
	for objective_value in _objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		var objective_side: String = SafeDict.as_string(objective.get("side"), "")
		var captured_by: String = SafeDict.as_string(objective.get("captured_by"), "")
		if captured_by == SafeDict.as_string(unit.get("faction"), ""):
			continue
		var score: int = SafeDict.as_int(objective.get("value"), 1) * 10
		if objective_side != "" and objective_side != ai_side:
			score += 15
		var distance: int = _hex_distance(
			SafeDict.as_int(unit.get("q"), 0), SafeDict.as_int(unit.get("r"), 0),
			SafeDict.as_int(objective.get("q"), 0), SafeDict.as_int(objective.get("r"), 0))
		score -= distance
		if score > best_score:
			best_score = score
			best_objective = objective
	if not best_objective.is_empty():
		return best_objective
	# Sin objetivos: ir hacia el enemigo más cercano.
	var best_enemy: Dictionary = {}
	var best_distance: int = 999999
	for other_value in _units:
		var other: Dictionary = SafeDict.as_dict(other_value)
		if SafeDict.as_string(other.get("side"), "") != enemy_side:
			continue
		var distance: int = _hex_distance(
			SafeDict.as_int(unit.get("q"), 0), SafeDict.as_int(unit.get("r"), 0),
			SafeDict.as_int(other.get("q"), 0), SafeDict.as_int(other.get("r"), 0))
		if distance < best_distance:
			best_distance = distance
			best_enemy = other
	return best_enemy


func _best_step_towards(unit_id: String, target: Dictionary) -> Dictionary:
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty() or target.is_empty():
		return {}
	var target_q: int = SafeDict.as_int(target.get("q"), 0)
	var target_r: int = SafeDict.as_int(target.get("r"), 0)
	var best: Dictionary = {}
	var best_distance: int = _hex_distance(
		SafeDict.as_int(unit.get("q"), 0), SafeDict.as_int(unit.get("r"), 0), target_q, target_r)
	var moves: int = SafeDict.as_int(unit.get("moves_left"), 0)
	for neighbour in _neighbours(SafeDict.as_int(unit.get("q"), 0), SafeDict.as_int(unit.get("r"), 0)):
		var q: int = SafeDict.as_int(neighbour.get("q"), 0)
		var r: int = SafeDict.as_int(neighbour.get("r"), 0)
		if not _can_move_unit(unit_id, q, r):
			continue
		var terrain: String = _terrain_at(q, r)
		var cost: int = SafeDict.as_int(Constants.TACTICAL_MOVE_COST.get(terrain), 1)
		if cost > moves:
			continue
		var distance: int = _hex_distance(q, r, target_q, target_r)
		if distance < best_distance:
			best_distance = distance
			best = {"q": q, "r": r}
	return best


func _check_finish() -> void:
	if finished:
		return
	var attacker_units: int = _side_units_count("attacker")
	var defender_units: int = _side_units_count("defender")
	if attacker_units == 0 and defender_units == 0:
		_finish_with(attacker_faction)
		return
	if attacker_units == 0:
		_finish_with(defender_faction)
		return
	if defender_units == 0:
		_finish_with(attacker_faction)
		return
	for objective_value in _objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		var captured_by: String = SafeDict.as_string(objective.get("captured_by"), "")
		if captured_by == "":
			continue
		var objective_side: String = SafeDict.as_string(objective.get("side"), "")
		if objective_side == "defender" and captured_by == attacker_faction:
			_finish_with(attacker_faction)
			return
		if objective_side == "attacker" and captured_by == defender_faction:
			_finish_with(defender_faction)
			return


func _finish() -> void:
	if not finished:
		_finish_with(winner)


func _finish_with(winning_faction: String) -> void:
	if finished:
		return
	finished = true
	winner = winning_faction
	side = ""
	_log_append("finish", "Fin de la batalla: vence %s en la ronda %d" % [winner, round])
	EventBus.emit_signal("tactical_battle_finished", winner, region_id)


func _finish_by_score() -> void:
	var attacker_score: int = 0
	var defender_score: int = 0
	for objective_value in _objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		var captured_by: String = SafeDict.as_string(objective.get("captured_by"), "")
		var value: int = SafeDict.as_int(objective.get("value"), 1)
		if captured_by == attacker_faction:
			attacker_score += value
		elif captured_by == defender_faction:
			defender_score += value
	var attacker_men: int = _side_current_men("attacker")
	var defender_men: int = _side_current_men("defender")
	if attacker_men > defender_men:
		attacker_score += 1
	elif defender_men > attacker_men:
		defender_score += 1
	if attacker_score >= defender_score:
		_finish_with(attacker_faction)
	else:
		_finish_with(defender_faction)


func _capture_objective_at(q: int, r: int, faction_id: String) -> void:
	var key := _hex_key(q, r)
	if not _hexes.has(key):
		return
	var hex: Dictionary = SafeDict.as_dict(_hexes.get(key, null))
	var objective_id: String = SafeDict.as_string(hex.get("objective"), "")
	if objective_id == "":
		return
	for objective_value in _objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		if SafeDict.as_string(objective.get("id"), "") != objective_id:
			continue
		objective["captured_by"] = faction_id
		_log_append("objective", "%s captura %s" % [faction_id, objective_id])
		return


# ---------------------------------------------------------------------------
# Utilidades de estado
# ---------------------------------------------------------------------------

func _find_unit(unit_id: String) -> Dictionary:
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("id"), "") == unit_id:
			return unit
	return {}


func _side_of_unit(unit: Dictionary) -> String:
	return SafeDict.as_string(unit.get("side"), "")


func _enemy_side() -> String:
	return "defender" if player_side == "attacker" else "attacker"


func _can_move_unit(unit_id: String, q: int, r: int) -> bool:
	if finished:
		return false
	var unit: Dictionary = _find_unit(unit_id)
	if unit.is_empty():
		return false
	if _side_of_unit(unit) != side:
		return false
	var unit_q: int = SafeDict.as_int(unit.get("q"), 0)
	var unit_r: int = SafeDict.as_int(unit.get("r"), 0)
	var key := _hex_key(q, r)
	if not _hexes.has(key):
		return false
	if _hex_distance(unit_q, unit_r, q, r) != 1:
		return false
	if not _is_hex_free(q, r, unit_id):
		return false
	var terrain: String = _terrain_at(q, r)
	var cost: int = SafeDict.as_int(Constants.TACTICAL_MOVE_COST.get(terrain), 1)
	return SafeDict.as_int(unit.get("moves_left"), 0) >= cost


func _is_hex_free(q: int, r: int, ignore_unit_id: String) -> bool:
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("id"), "") == ignore_unit_id:
			continue
		if SafeDict.as_int(unit.get("q"), 0) == q and SafeDict.as_int(unit.get("r"), 0) == r:
			return false
	return true


func _terrain_at(q: int, r: int) -> String:
	var hex: Dictionary = SafeDict.as_dict(_hexes.get(_hex_key(q, r), null))
	return SafeDict.as_string(hex.get("terrain"), "plains")


func _hex_key(q: int, r: int) -> String:
	return "%d,%d" % [q, r]


func _hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	var dq: int = q1 - q2
	var dr: int = r1 - r2
	return maxi(absi(dq), maxi(absi(dr), absi(dq + dr)))


func _neighbours(q: int, r: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"q": q + 1, "r": r},
		{"q": q - 1, "r": r},
		{"q": q, "r": r + 1},
		{"q": q, "r": r - 1},
		{"q": q + 1, "r": r - 1},
		{"q": q - 1, "r": r + 1},
	]
	return result


func _unit_power(unit: Dictionary) -> float:
	var size: int = SafeDict.as_int(unit.get("size"), 0)
	var strength: int = SafeDict.as_int(unit.get("strength"), 1)
	var morale: float = clampf(SafeDict.as_float(unit.get("morale"), 1.0), 0.0, 1.0)
	var experience: int = SafeDict.as_int(unit.get("experience"), 0)
	var veterancy: float = 1.0 + (float(experience) - 50.0) / 200.0
	return maxf(0.0, float(strength) * (float(size) / 100.0) * morale * veterancy)


func _apply_unit_damage(unit: Dictionary, fraction: float) -> int:
	var size: int = SafeDict.as_int(unit.get("size"), 0)
	var losses: int = int(roundf(float(size) * clampf(fraction, 0.0, 0.6)))
	unit["size"] = maxi(0, size - losses)
	unit["morale"] = maxf(0.05, SafeDict.as_float(unit.get("morale"), 1.0) - fraction * 0.5)
	unit["experience"] = clampi(SafeDict.as_int(unit.get("experience"), 0) + 1, 0, 100)
	return losses


func _apply_losses_absolute(unit: Dictionary, losses: int) -> void:
	var size: int = SafeDict.as_int(unit.get("size"), 0)
	unit["size"] = maxi(0, size - maxi(0, losses))
	unit["morale"] = maxf(0.05, SafeDict.as_float(unit.get("morale"), 1.0) - float(losses) / maxf(1.0, float(size)) * 0.5)


func _is_unit_destroyed(unit: Dictionary) -> bool:
	return SafeDict.as_int(unit.get("size"), 0) <= 0 \
		or SafeDict.as_float(unit.get("morale"), 1.0) < Constants.CLOSE_COMBAT_MORALE_BREAK


func _remove_destroyed_unit(unit_id: String) -> void:
	var remaining: Array[Dictionary] = []
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("id"), "") == unit_id:
			continue
		remaining.append(unit)
	_units = remaining


func _side_units_count(unit_side: String) -> int:
	var count: int = 0
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == unit_side:
			count += 1
	return count


func _side_current_men(unit_side: String) -> int:
	var total: int = 0
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") != unit_side:
			continue
		total += SafeDict.as_int(unit.get("size"), 0)
	return total


func _side_start_men(unit_side: String) -> int:
	# B-F2-01: usar el total inicial por bando (no las unidades actuales, porque
	# las destruidas se eliminan de `_units` y el informe perdería sus bajas).
	return SafeDict.as_int(_start_men_by_side.get(unit_side), 0)


func _snapshot_side(unit_side: String) -> Array:
	var snapshot: Array = []
	for unit_value in _units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") != unit_side:
			continue
		snapshot.append({
			"source_unit_id": SafeDict.as_string(unit.get("source_unit_id"), ""),
			"id": SafeDict.as_string(unit.get("id"), ""),
			"unit_id": SafeDict.as_string(unit.get("unit_id"), ""),
			"size": SafeDict.as_int(unit.get("size"), 0),
			"morale": snappedf(SafeDict.as_float(unit.get("morale"), 1.0), 0.001),
			"experience": SafeDict.as_int(unit.get("experience"), 0),
		})
	return snapshot


func _commander_bonus_for(unit_side: String) -> float:
	return SafeDict.as_float(_commander_bonus.get(unit_side), 1.0)


func _commander_stat_for(leader_id: String, faction_id: String) -> int:
	var character_id: String = leader_id
	if character_id == "":
		var faction: Dictionary = GameState.get_faction_state(faction_id)
		character_id = SafeDict.as_string(faction.get("ruler_id"), "")
	if character_id == "":
		return Constants.BATTLE_COMMANDER_STAT_BASE
	var character: Dictionary = GameState.get_character_state(character_id)
	var stats: Dictionary = SafeDict.as_dict(character.get("stats", null))
	return SafeDict.as_int(stats.get("command"), Constants.BATTLE_COMMANDER_STAT_BASE)


func _rng() -> SeededRNGScript:
	var rng: SeededRNGScript = GameState.rng
	if rng == null:
		rng = SeededRNGScript.new(GameState.rng_seed)
		GameState.rng = rng
	return rng


func _round_log_clear() -> void:
	# Separamos el registro de rondas (informe) del log narrativo.
	if _round_log.is_empty():
		return
	_round_log.clear()


func _log_append(kind: String, text: String) -> void:
	_log.append({"kind": kind, "round": round, "text": text})
	if kind == "attack" or kind == "duel" or kind == "finish" or kind == "round":
		_round_log.append({"round": round, "kind": kind, "text": text})


var _round_log: Array[Dictionary] = []
