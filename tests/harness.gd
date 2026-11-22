extends RefCounted
## Acceso de los tests a los autoloads.
##
## Godot compila el script de `--script` ANTES de registrar los autoloads como
## identificadores globales, así que los tests no pueden escribir `GameState.`.
## Este harness los obtiene del árbol (ya montados en `_initialize`) y expone
## atajos con llamadas dinámicas.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")

var gs: Node = null
var tm: Node = null
var dl: Node = null
var eco: Node = null
var dyn: Node = null
var dip: Node = null
var mil: Node = null
var battle: Node = null
var ai: Node = null
var bus: Node = null
var missing: Array[String] = []


func _init(root: Node) -> void:
	gs = _grab(root, "GameState")
	tm = _grab(root, "TurnManager")
	dl = _grab(root, "DataLoader")
	eco = _grab(root, "EconomySystem")
	dyn = _grab(root, "DynastySystem")
	dip = _grab(root, "DiplomacySystem")
	mil = _grab(root, "MilitarySystem")
	battle = _grab(root, "BattleManager")
	ai = _grab(root, "AIManager")
	bus = _grab(root, "EventBus")


func _grab(root: Node, autoload_name: String) -> Node:
	if root == null:
		missing.append(autoload_name)
		return null
	var found := root.get_node_or_null(NodePath(autoload_name))
	if found == null:
		missing.append(autoload_name)
	return found


func available() -> bool:
	return missing.is_empty()


# --- Partida -------------------------------------------------------------

func new_game(faction: String = "england", seed_value: int = 1337) -> void:
	gs.call("new_game", "scenario_1337", faction, seed_value)


func state() -> Dictionary:
	var value: Variant = gs.get("state")
	if value is Dictionary:
		return value
	return {}


func year() -> int:
	return SafeDict.as_int(gs.get("year"), 0)


func quarter() -> int:
	return SafeDict.as_int(gs.get("quarter"), 0)


func player() -> String:
	return SafeDict.as_string(gs.get("current_faction_id"), "")


func faction(faction_id: String) -> Dictionary:
	return gs.call("get_faction_state", faction_id)


func region(region_id: String) -> Dictionary:
	return gs.call("get_region_state", region_id)


func character(character_id: String) -> Dictionary:
	return gs.call("get_character_state", character_id)


func armies() -> Dictionary:
	return SafeDict.as_dict(state().get("armies", null))


func regions() -> Dictionary:
	return SafeDict.as_dict(state().get("regions", null))


func factions() -> Dictionary:
	return SafeDict.as_dict(state().get("factions", null))


func characters() -> Dictionary:
	return SafeDict.as_dict(state().get("characters", null))


func to_dict() -> Dictionary:
	var value: Variant = gs.call("to_dict")
	if value is Dictionary:
		return value
	return {}


## Hash estable del documento canónico de la partida (criterio A4).
func state_hash() -> int:
	return JSON.stringify(to_dict()).hash()


func state_json() -> String:
	return JSON.stringify(to_dict())


func save_game(slot: String = "test_slot") -> bool:
	return SafeDict.as_bool(gs.call("save_game", slot), false)


func load_game(slot: String = "test_slot") -> bool:
	return SafeDict.as_bool(gs.call("load_game", slot), false)


func has_save(slot: String) -> bool:
	return SafeDict.as_bool(gs.call("has_save", slot), false)


func rng() -> Variant:
	return gs.get("rng")


func snapshot_rng() -> Dictionary:
	var rng_object: Variant = gs.get("rng")
	if rng_object != null:
		return rng_object.call("snapshot")
	return {}


# --- Turno ---------------------------------------------------------------

func begin_turn(faction_id: String) -> void:
	tm.call("begin_turn", faction_id)


func end_turn() -> void:
	tm.call("end_turn")


func advance_quarter() -> void:
	tm.call("advance_quarter")


func advance_year() -> void:
	tm.call("advance_year")


func remaining_pg() -> int:
	return SafeDict.as_int(tm.get("remaining_pg"), 0)


func calculate_pg(faction_id: String) -> int:
	return SafeDict.as_int(tm.call("calculate_pg", faction_id), 0)


func spend_pg(amount: int) -> bool:
	return SafeDict.as_bool(tm.call("spend_pg", amount), false)


# --- Economía ------------------------------------------------------------

func recalculate(faction_id: String) -> void:
	eco.call("recalculate", faction_id)


func allocate(region_id: String, worker_class: String, amount: int) -> bool:
	return SafeDict.as_bool(eco.call("allocate", region_id, worker_class, amount), false)


func region_output(region_id: String) -> Dictionary:
	var value: Variant = eco.call("get_region_output", region_id)
	if value is Dictionary:
		return value
	return {}


func treasury(faction_id: String) -> int:
	return SafeDict.as_int(eco.call("get_treasury", faction_id), 0)


func support(region_id: String) -> int:
	return SafeDict.as_int(eco.call("get_support", region_id), 0)


func harvest(faction_id: String) -> Dictionary:
	var value: Variant = eco.call("resolve_harvest", faction_id)
	if value is Dictionary:
		return value
	return {}


# --- Dinastía ------------------------------------------------------------

func marry(character_id: String, target_character_id: String) -> Dictionary:
	var value: Variant = dyn.call("marry", character_id, target_character_id)
	if value is Dictionary:
		return value
	return {}


func dynasty_advance_year() -> Array[Dictionary]:
	var value: Variant = dyn.call("advance_year")
	if value is Array:
		var result: Array[Dictionary] = []
		for item in (value as Array):
			if item is Dictionary:
				result.append(item)
		return result
	return []


func ruler(faction_id: String) -> Dictionary:
	var value: Variant = dyn.call("get_ruler", faction_id)
	if value is Dictionary:
		return value
	return {}


func heir(faction_id: String) -> Dictionary:
	var value: Variant = dyn.call("get_heir", faction_id)
	if value is Dictionary:
		return value
	return {}


func resolve_succession(faction_id: String) -> Dictionary:
	var value: Variant = dyn.call("resolve_succession", faction_id)
	if value is Dictionary:
		return value
	return {}


func family_tree(faction_id: String) -> Array[Dictionary]:
	var value: Variant = dyn.call("get_family_tree", faction_id)
	if value is Array:
		var result: Array[Dictionary] = []
		for item in (value as Array):
			if item is Dictionary:
				result.append(item)
		return result
	return []


# --- Diplomacia ----------------------------------------------------------

func propose(actor: String, target: String, action: Dictionary) -> Dictionary:
	var value: Variant = dip.call("propose", actor, target, action)
	if value is Dictionary:
		return value
	return {}


func relation(faction_a: String, faction_b: String) -> int:
	return SafeDict.as_int(dip.call("get_relation", faction_a, faction_b), 0)


func set_relation(faction_a: String, faction_b: String, value: int) -> void:
	dip.call("set_relation", faction_a, faction_b, value)


func at_war(faction_a: String, faction_b: String) -> bool:
	return SafeDict.as_bool(dip.call("are_at_war", faction_a, faction_b), false)


func allied(faction_a: String, faction_b: String) -> bool:
	return SafeDict.as_bool(dip.call("are_allied", faction_a, faction_b), false)


func action_cost(action_id: String) -> int:
	return SafeDict.as_int(dip.call("get_action_cost", action_id), -1)


func declare_war(attacker: String, defender: String) -> bool:
	return SafeDict.as_bool(dip.call("declare_war", attacker, defender), false)


# --- Militar -------------------------------------------------------------

func create_army(faction_id: String, region_id: String) -> Dictionary:
	var value: Variant = mil.call("create_army", faction_id, region_id)
	if value is Dictionary:
		return value
	return {}


func recruit(faction_id: String, region_id: String, unit_id: String, amount: int) -> bool:
	return SafeDict.as_bool(mil.call("recruit", faction_id, region_id, unit_id, amount), false)


func move_army(army_id: String, to_region: String) -> bool:
	return SafeDict.as_bool(mil.call("move_army", army_id, to_region), false)


func disband_army(army_id: String) -> bool:
	return SafeDict.as_bool(mil.call("disband_army", army_id), false)


func army(army_id: String) -> Dictionary:
	var value: Variant = mil.call("get_army", army_id)
	if value is Dictionary:
		return value
	return {}


func armies_in(region_id: String) -> Array[Dictionary]:
	var value: Variant = mil.call("get_armies_in", region_id)
	if value is Array:
		var result: Array[Dictionary] = []
		for item in (value as Array):
			if item is Dictionary:
				result.append(item)
		return result
	return []


func recruitment_pool(region_id: String) -> int:
	return SafeDict.as_int(mil.call("get_recruitment_pool", region_id), 0)


func move_cost(army_id: String, to_region: String) -> int:
	return SafeDict.as_int(mil.call("get_move_cost", army_id, to_region), -1)


func army_men(army_id: String) -> int:
	return SafeDict.as_int(mil.call("get_army_men", army_id), 0)


func army_slots(region_id: String) -> int:
	return SafeDict.as_int(mil.call("get_army_slots", region_id), 0)


# --- IA ------------------------------------------------------------------

func run_all_ai() -> void:
	ai.call("run_all_ai")


func run_ai_turns(faction_ids: Array[String]) -> void:
	ai.call("run_ai_turns", faction_ids)


func ai_last_run_ms() -> int:
	return SafeDict.as_int(ai.get("last_run_ms"), 0)


func ai_last_orders() -> Dictionary:
	var value: Variant = ai.get("last_orders")
	if value is Dictionary:
		return value
	return {}


func ai_profile(faction_id: String) -> String:
	return SafeDict.as_string(ai.call("get_profile", faction_id), "")


func ai_set_profile(faction_id: String, profile: String) -> void:
	ai.call("set_profile", faction_id, profile)
