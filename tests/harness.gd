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
var audio: Node = null
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
	audio = _grab(root, "AudioManager")


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


## Arranca una partida en un escenario concreto (Fase 3: 1402/1453/fixtures).
func new_game_in(scenario_id: String, faction: String = "england", seed_value: int = 1337) -> void:
	gs.call("new_game", scenario_id, faction, seed_value)


func scenario_definition(scenario_id: String) -> Dictionary:
	return SafeDict.as_dict(dl.call("get_scenario", scenario_id))


## Era tecnológica actual ("I"/"II"/"III", D-059).
func era() -> String:
	return str(gs.call("get_era"))


func era_index() -> int:
	return SafeDict.as_int(gs.call("get_era_index"), 0)


func available_units(faction_id: String) -> Array[String]:
	var value: Variant = mil.call("get_available_units", faction_id)
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func is_unit_available(unit_id: String, faction_id: String = "") -> bool:
	return SafeDict.as_bool(mil.call("is_unit_available", unit_id, faction_id), false)


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


# --- Batallas Nivel 2/3 (Fase 2) -----------------------------------------

## Modelos Army/RegionState que consume BattleManager.launch_tactical().
func get_army_model(army_id: String) -> Variant:
	return mil.call("get_army_model", army_id)


func get_region_model(region_id: String) -> Variant:
	return mil.call("get_region_model", region_id)


func launch_tactical(attacker_model: Variant, defender_model: Variant, region_model: Variant) -> Node:
	var value: Variant = battle.call("launch_tactical", attacker_model, defender_model, region_model)
	if value is Node:
		return value
	return null


func launch_close_combat(attacker_unit: Dictionary, defender_unit: Dictionary) -> Node:
	var value: Variant = battle.call("launch_close_combat", attacker_unit, defender_unit)
	if value is Node:
		return value
	return null


func apply_battle_outcome(report: Dictionary) -> bool:
	return SafeDict.as_bool(mil.call("apply_battle_outcome", report), false)


func battle_reports() -> Array:
	return SafeDict.as_array(state().get("battle_reports", null))


## Aplica un duelo Nivel 3 (CloseCombat.get_outcome) a la campaña (D-033).
func apply_close_combat_outcome(attacker_army_id: String, defender_army_id: String,
		region_id: String, outcome: Dictionary) -> Dictionary:
	var value: Variant = battle.call("apply_close_combat_outcome", attacker_army_id,
		defender_army_id, region_id, outcome)
	if value is Dictionary:
		return value
	return {}


# --- Fase 2: espionaje / reloj / fin de partida --------------------------

func intel(faction_id: String, target_id: String) -> Dictionary:
	var faction_state: Dictionary = faction(faction_id)
	var intel_map: Dictionary = SafeDict.as_dict(faction_state.get("intel", null))
	return SafeDict.as_dict(intel_map.get(target_id, null))


func set_year(year_value: int) -> void:
	var st: Dictionary = state()
	if st.is_empty():
		return
	st["year"] = year_value
	gs.call("sync_clock_from_state")
	tm.call("sync_clock_from_state")


func is_game_over() -> bool:
	return SafeDict.as_bool(state().get("game_over"), false)


func game_over_reason() -> String:
	return SafeDict.as_string(state().get("game_over_reason"), "")


## Resumen de fin de partida (D-066) para pantalla de fin/tests.
func game_over_info() -> Dictionary:
	return SafeDict.as_dict(gs.call("get_game_over_info"))


## Evalúa las condiciones §4.5 y devuelve el resumen (API pública TurnManager).
func check_game_over() -> Dictionary:
	return SafeDict.as_dict(tm.call("check_game_over"))


func playable_factions(scenario_id: String = "") -> Array[String]:
	var result: Array[String] = []
	var value: Variant = gs.call("get_playable_factions", scenario_id)
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


# --- Batalla pendiente / audio (D-066) -----------------------------------

func has_pending_battle() -> bool:
	return SafeDict.as_bool(gs.call("has_pending_battle"), false)


func pending_battle() -> Dictionary:
	return SafeDict.as_dict(gs.call("get_pending_battle"))


func clear_pending_battle() -> void:
	gs.call("clear_pending_battle")


func audio_count(tone_name: String) -> int:
	return SafeDict.as_int(audio.call("get_play_count", tone_name), 0)


func reset_audio_counts() -> void:
	audio.call("reset_counts")


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


# --- Fase 3: datos de sprites (D-040/D-042) ------------------------------

func unit_definition(unit_id: String) -> Dictionary:
	return SafeDict.as_dict(dl.call("get_unit", unit_id))


func unit_sprite(unit_id: String) -> Dictionary:
	return SafeDict.as_dict(dl.call("get_unit_sprite", unit_id))


func unit_ids() -> Array[String]:
	var value: Variant = dl.call("get_unit_ids")
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


# --- Fase 3 §10.4: tiles de batalla (D-053) ------------------------------

func battle_tiles() -> Dictionary:
	var value: Variant = dl.call("get_battle_tiles")
	if value is Dictionary:
		return value
	return {}


func battle_tile(key: String) -> Dictionary:
	var value: Variant = dl.call("get_battle_tile", key)
	if value is Dictionary:
		return value
	return {}


func battle_tile_keys() -> Array[String]:
	var value: Variant = dl.call("get_battle_tile_keys")
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func rng_snapshot() -> Dictionary:
	var dict: Dictionary = to_dict()
	return SafeDict.as_dict(dict.get("rng", null))
