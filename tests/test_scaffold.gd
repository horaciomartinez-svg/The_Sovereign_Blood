extends RefCounted
## Smoke test de Fase 0 (A3/A5): project.godot, autoloads montados, contratos de
## GDD §8.2 declarados, modelos dataclass y carpeta data/ accesible.
##
## No depende de GUT: lo ejecuta tests/run_all.gd con asserts nativos.

const TestRunnerScript = preload("res://tests/test_runner.gd")

const AUTOLOADS: Array = [
	"EventBus",
	"DataLoader",
	"GameState",
	"TurnManager",
	"EconomySystem",
	"DynastySystem",
	"DiplomacySystem",
	"MilitarySystem",
	"BattleManager",
	"AIManager",
]

const AUTOLOAD_SCRIPTS: Dictionary = {
	"EventBus": "res://scripts/autoload/event_bus.gd",
	"DataLoader": "res://scripts/autoload/data_loader.gd",
	"GameState": "res://scripts/autoload/game_state.gd",
	"TurnManager": "res://scripts/autoload/turn_manager.gd",
	"EconomySystem": "res://scripts/autoload/economy_system.gd",
	"DynastySystem": "res://scripts/autoload/dynasty_system.gd",
	"DiplomacySystem": "res://scripts/autoload/diplomacy_system.gd",
	"MilitarySystem": "res://scripts/autoload/military_system.gd",
	"BattleManager": "res://scripts/autoload/battle_manager.gd",
	"AIManager": "res://scripts/autoload/ai_manager.gd",
}

## Métodos de contrato GDD §8.2 (+ helpers declarados en Fase 0).
const CONTRACT_METHODS: Dictionary = {
	"EventBus": [],
	"DataLoader": ["load_all", "load_json", "load_dataset", "get_faction", "get_region", "get_character", "get_unit", "get_scenario", "get_events_for_year", "has_faction", "has_region", "reset"],
	"GameState": ["new_game", "reset", "to_dict", "from_dict", "save_game", "load_game", "has_save"],
	"TurnManager": ["begin_turn", "end_turn", "spend_pg", "can_spend_pg", "calculate_pg", "advance_quarter", "advance_year"],
	"EconomySystem": ["recalculate", "allocate", "get_treasury", "get_region_output", "resolve_harvest", "get_support"],
	"DynastySystem": ["marry", "advance_year", "get_ruler", "get_heir", "resolve_succession", "get_family_tree"],
	"DiplomacySystem": ["propose", "get_relation", "set_relation", "are_at_war", "are_allied", "get_action_cost"],
	"MilitarySystem": ["create_army", "recruit", "move_army", "disband_army", "get_army", "get_armies_in", "get_recruitment_pool", "get_move_cost"],
	"BattleManager": ["resolve_delegated", "launch_tactical", "estimate_power"],
	"AIManager": ["take_turn", "run_ai_turns", "run_all_ai", "get_profile", "set_profile"],
}

## Señales de contrato que la UI/sistemas esperan encontrar.
const CONTRACT_SIGNALS: Dictionary = {
	"EventBus": ["turn_started", "turn_ended", "year_advanced", "pg_changed", "character_born", "character_died", "war_declared", "peace_made", "battle_resolved", "game_over"],
	"GameState": ["game_initialized", "game_saved", "game_loaded"],
	"TurnManager": ["turn_started", "pg_changed", "turn_ended"],
	"EconomySystem": ["treasury_changed", "region_output_changed"],
	"DynastySystem": ["character_born", "character_died", "marriage_formed", "succession_resolved"],
	"DiplomacySystem": ["proposal_sent", "war_declared", "peace_made", "relation_changed"],
	"MilitarySystem": ["army_created", "army_moved", "army_destroyed"],
	"BattleManager": ["battle_resolved"],
	"AIManager": ["ai_turn_started", "ai_turn_finished"],
}

const MODEL_SCRIPTS: Dictionary = {
	"Character": "res://scripts/model/character.gd",
	"RegionState": "res://scripts/model/region_state.gd",
	"Army": "res://scripts/model/army.gd",
	"UnitInstance": "res://scripts/model/unit_instance.gd",
	"BattleReport": "res://scripts/model/battle_report.gd",
}


func run(runner: TestRunnerScript, tree: SceneTree) -> void:
	runner.begin_suite("scaffold")
	_check_project_settings(runner)
	_check_autoloads(runner, tree)
	_check_contracts(runner, tree)
	_check_scripts(runner)
	_check_data_dir(runner)


func _check_project_settings(runner: TestRunnerScript) -> void:
	runner.check_eq("application/config/name", "The Sovereign's Blood", ProjectSettings.get_setting("application/config/name", ""))
	runner.check_eq("display/window/size/viewport_width", 1920, ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	runner.check_eq("display/window/size/viewport_height", 1080, ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene == "":
		runner.check("main_scene vacío (Fase 0) o escena existente (Fase 1)", true)
	else:
		runner.check("main_scene apunta a una escena existente", FileAccess.file_exists(main_scene), "main_scene='%s'" % main_scene)
	var features: Variant = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	var has_feature := false
	if features is PackedStringArray:
		has_feature = (features as PackedStringArray).has("4.7")
	runner.check("config/features incluye Godot 4.7", has_feature, str(features))
	for autoload_name in AUTOLOADS:
		runner.check("ProjectSettings registra autoload/%s" % autoload_name, ProjectSettings.has_setting("autoload/%s" % autoload_name))


func _check_autoloads(runner: TestRunnerScript, tree: SceneTree) -> void:
	if tree.root == null:
		runner.check("SceneTree.root disponible", false)
		return
	var mounted := 0
	for autoload_name in AUTOLOADS:
		var node := tree.root.get_node_or_null(NodePath(str(autoload_name)))
		if node != null:
			mounted += 1
			runner.check("autoload montado y es Node: %s" % autoload_name, node is Node)
			# Los autoloads deben ser nodos (extends Node), no RefCounted.
			var autoload_script: Variant = node.get_script()
			var base_type := ""
			if autoload_script is Script:
				base_type = str((autoload_script as Script).get_instance_base_type())
			runner.check("autoload %s extends Node" % autoload_name, base_type == "Node", "base_type='%s'" % base_type)
		else:
			runner.check("autoload montado: %s" % autoload_name, false, "no existe bajo root")
	runner.check_eq("10/10 autoloads montados en el árbol", AUTOLOADS.size(), mounted)


func _check_contracts(runner: TestRunnerScript, tree: SceneTree) -> void:
	for autoload_name in CONTRACT_METHODS.keys():
		var node := tree.root.get_node_or_null(NodePath(str(autoload_name)))
		var methods: Array = CONTRACT_METHODS[autoload_name]
		if node == null:
			runner.check("contrato %s disponible" % autoload_name, false, "autoload no montado")
			continue
		for method_name in methods:
			runner.check("%s.%s()" % [autoload_name, str(method_name)], node.has_method(str(method_name)))
	for autoload_name in CONTRACT_SIGNALS.keys():
		var node := tree.root.get_node_or_null(NodePath(str(autoload_name)))
		var signal_names: Array = CONTRACT_SIGNALS[autoload_name]
		if node == null:
			continue
		for signal_name in signal_names:
			runner.check("%s signal %s" % [autoload_name, str(signal_name)], node.has_signal(str(signal_name)))


func _check_scripts(runner: TestRunnerScript) -> void:
	for autoload_name in AUTOLOAD_SCRIPTS.keys():
		var script_path := str(AUTOLOAD_SCRIPTS[autoload_name])
		var script: Variant = load(script_path)
		runner.check("autoload compila: %s" % script_path.get_file(), script != null)
		if script is GDScript:
			var instance: Node = (script as GDScript).new()
			runner.check("autoload instanciable: %s" % autoload_name, instance != null)
			if instance != null:
				instance.free()
	for model_name in MODEL_SCRIPTS.keys():
		var script_path := str(MODEL_SCRIPTS[model_name])
		var script: Variant = load(script_path)
		if runner.check("modelo compila: %s" % script_path.get_file(), script is GDScript):
			var instance: RefCounted = (script as GDScript).new()
			runner.check("modelo instanciable: %s" % model_name, instance != null)
			if instance != null:
				runner.check("modelo %s expone to_dict()" % model_name, instance.has_method("to_dict"))
	var rng_script: Variant = load("res://scripts/utils/rng.gd")
	if runner.check("utilidad compila: rng.gd", rng_script is GDScript):
		var rng_instance: RefCounted = (rng_script as GDScript).new(1)
		runner.check("rng expone snapshot()/restore()", rng_instance.has_method("snapshot") and rng_instance.has_method("restore"))


func _check_data_dir(runner: TestRunnerScript) -> void:
	var data_dir := DirAccess.open("res://data")
	runner.check_not_null("data/ existe y es accesible", data_dir)
	if data_dir != null:
		runner.check("data/schema/ accesible", DirAccess.open("res://data/schema") != null)
