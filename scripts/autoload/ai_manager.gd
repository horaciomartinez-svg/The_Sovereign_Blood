extends Node
## AIManager — orquesta las facciones IA (GDD §5.6, §8.1).
##
## Cada rival juega 2-4 órdenes por trimestre con utilidad esperada (§5.6) y su
## perfil (agresor/comerciante/dinástico/superviviente/equilibrado). Presupuesto:
## 13 rivales en <2000 ms (medido en `ai_turn_finished` y en `last_run_ms`).
##
## La planificación es determinista (sin RNG): misma semilla + mismas acciones →
## mismo estado (GDD §13).

signal ai_turn_started(faction_id: String)
signal ai_turn_finished(faction_id: String, elapsed_ms: int)
signal all_ai_finished()

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const AIBrainScript = preload("res://scripts/ai/ai_brain.gd")
const AIProfiles = preload("res://scripts/ai/ai_profiles.gd")

## Presupuesto de rendimiento (GDD §5.6, §13).
const TIME_BUDGET_MS: int = 2000

var last_run_ms: int = 0
var last_turn_count: int = 0
## Órdenes ejecutadas por facción en la última ejecución (para tests/QA).
var last_orders: Dictionary = {}
var _brain: RefCounted = null


func _ready() -> void:
	_brain = AIBrainScript.new()


## Ejecuta el turno de una facción IA (2-4 órdenes; GDD §5.6).
func take_turn(faction_id: String) -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or SafeDict.as_bool(st.get("game_over"), false):
		return
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		return
	if _brain == null:
		_brain = AIBrainScript.new()
	var started_ms: int = Time.get_ticks_msec()
	emit_signal("ai_turn_started", faction_id)
	faction["pg"] = TurnManager.calculate_pg(faction_id)
	var profile: String = get_profile(faction_id)
	var actions: Array[Dictionary] = _brain.plan(faction_id, profile, Constants.AI_ORDER_MAX)
	var orders_done: int = 0
	for action in actions:
		if orders_done >= Constants.AI_ORDER_MAX:
			break
		if SafeDict.as_bool(st.get("game_over"), false):
			break
		if _execute_order(faction_id, action):
			orders_done += 1
	last_orders[faction_id] = orders_done
	last_turn_count = int(last_orders.size())
	var elapsed_ms: int = Time.get_ticks_msec() - started_ms
	emit_signal("ai_turn_finished", faction_id, elapsed_ms)


## Ejecuta los turnos de todas las facciones IA indicadas (tras el jugador).
func run_ai_turns(faction_ids: Array[String]) -> void:
	var started_ms: int = Time.get_ticks_msec()
	last_orders = {}
	for faction_id in faction_ids:
		take_turn(faction_id)
	last_run_ms = Time.get_ticks_msec() - started_ms
	last_turn_count = last_orders.size()
	emit_signal("all_ai_finished")
	EventBus.emit_signal("ui_notification",
		"Turno de la IA completado: %d facción(es) en %d ms" % [last_turn_count, last_run_ms], 0)


## Ejecuta todos los rivales de la partida (todas las facciones no jugador).
func run_all_ai() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return
	var player: String = GameState.current_faction_id
	if player == "":
		player = SafeDict.as_string(st.get("player_faction"), "")
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	var ids: Array[String] = []
	for faction_id in SafeDict.sorted_keys(factions):
		if faction_id == player:
			continue
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		ids.append(faction_id)
	run_ai_turns(ids)


func get_profile(faction_id: String) -> String:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var profile: String = SafeDict.as_string(faction.get("profile"), "")
	if profile == "":
		var definition: Dictionary = DataLoader.get_faction(faction_id)
		profile = SafeDict.as_string(definition.get("profile"), "balanced")
	return profile


## D-073: multiplicador de agresividad IA según dificultad (informativo/tests).
func get_aggression_multiplier() -> float:
	if GameState.get_difficulty() == "beginner":
		return Constants.AI_AGGRESSION_BEGINNER
	return Constants.AI_AGGRESSION_NORMAL


func set_profile(faction_id: String, profile: String) -> void:
	if not AIProfiles.is_valid(profile):
		return
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if not faction.is_empty():
		faction["profile"] = profile


# ---------------------------------------------------------------------------
# Ejecución de órdenes
# ---------------------------------------------------------------------------

func _execute_order(faction_id: String, action: Dictionary) -> bool:
	var action_type: String = SafeDict.as_string(action.get("type"), "")
	match action_type:
		"move":
			return MilitarySystem.move_army(
				SafeDict.as_string(action.get("army_id"), ""),
				SafeDict.as_string(action.get("to_region"), ""))
		"recruit":
			return MilitarySystem.recruit(
				faction_id,
				SafeDict.as_string(action.get("region_id"), ""),
				SafeDict.as_string(action.get("unit_id"), ""),
				SafeDict.as_int(action.get("amount"), Constants.AI_RECRUIT_MEN))
		"diplomacy":
			var proposal: Dictionary = {
				"type": SafeDict.as_string(action.get("action"), ""),
			}
			var result: Dictionary = DiplomacySystem.propose(
				faction_id,
				SafeDict.as_string(action.get("target"), ""),
				proposal)
			return SafeDict.as_bool(result.get("ok"), false)
		_:
			return false
