extends RefCounted
## Tests Fase 4 D-071/D-073: consorte, dificultad, tutorial y save/load.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const PLAYER: String = "england"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_consort(runner, h)
	_check_difficulty(runner, h)
	_check_tutorial(runner, h)
	_check_save_load(runner, h)
	_check_old_save_defaults(runner, h)


func _check_consort(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("consort")
	h.new_game(PLAYER)
	var info: Dictionary = h.consort_info(PLAYER)
	runner.check("Inglaterra tiene consorte válida", bool(info.get("valid")), str(info))
	var turn_before: int = SafeDict.as_int(h.state().get("turn"), 0)
	var prestige_before: int = SafeDict.as_int(h.faction(PLAYER).get("prestige"), 0)
	var pg_before: int = h.remaining_pg()
	var action: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("pasar tiempo con la consorte", bool(action.get("ok")), str(action))
	runner.check_eq("cuesta 3 PG", pg_before - 3, h.remaining_pg())
	var faction: Dictionary = h.faction(PLAYER)
	runner.check("activa bonus de fertilidad 2-4 trimestres",
		SafeDict.as_int(faction.get("fertility_bonus_until_turn"), 0) >= turn_before + 2
		and SafeDict.as_int(faction.get("fertility_bonus_until_turn"), 0) <= turn_before + 4)
	runner.check_eq("cooldown registrado en el turno", turn_before,
		SafeDict.as_int(faction.get("last_consort_turn"), -1))
	runner.check("pequeño prestigio", SafeDict.as_int(faction.get("prestige"), 0) > prestige_before)
	var again: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("no se repite en el mismo trimestre", not bool(again.get("ok")))
	runner.check("motivo action_used al repetir",
		SafeDict.as_string(again.get("reason"), "") == "action_used",
		SafeDict.as_string(again.get("reason"), ""))
	# Siguiente trimestre: cooldown liberado.
	h.advance_quarter()
	var next: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("se puede repetir tras avanzar trimestre", bool(next.get("ok")), str(next))
	# Sin consorte válida, falla con motivo y no rompe estado.
	h.new_game(PLAYER)
	var ruler: Dictionary = h.character(SafeDict.as_string(h.faction(PLAYER).get("ruler_id"), ""))
	var family: Dictionary = SafeDict.as_dict(ruler.get("family", null))
	family["spouse"] = ""
	var no_spouse: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("sin consorte falla con motivo", not bool(no_spouse.get("ok"))
		and SafeDict.as_string(no_spouse.get("reason"), "") != "", str(no_spouse))
	# Sin PG, falla.
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 0
	var no_pg: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("sin PG falla con motivo", not bool(no_pg.get("ok")), str(no_pg))


func _check_difficulty(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("difficulty")
	h.new_game(PLAYER)
	runner.check_eq("normal por defecto", "normal", h.difficulty())
	runner.check("normal sin tutorial", not h.tutorial_active())
	runner.check_eq("agresividad IA normal 1.0", 1.0, h.ai_aggression_multiplier())
	h.new_game_with_difficulty(PLAYER, "beginner")
	runner.check_eq("dificultad beginner guardada", "beginner", h.difficulty())
	runner.check("beginner activa el tutorial", h.tutorial_active())
	runner.check_eq("beginner reduce agresividad IA a 0.75", 0.75, h.ai_aggression_multiplier())
	runner.check("dificultad inválida rechazada", not h.set_difficulty("imposible"))


func _check_tutorial(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("tutorial")
	runner.check_eq("tutorial_script tiene 9 pasos", 9,
		SafeDict.as_array(h.tutorial.call("get_steps")).size())
	var conditions: Array = h.tutorial.call("get_conditions")
	for condition in ["open_region", "assign_workers", "open_family", "open_diplomacy",
			"open_market", "open_military", "end_turn", "battle_played", "saved"]:
		runner.check("condición de tutorial %s" % condition, conditions.has(condition))
	h.new_game_with_difficulty(PLAYER, "beginner")
	var step: Dictionary = h.tutorial_step()
	runner.check_eq("primer paso del tutorial", "open_region", SafeDict.as_string(step.get("condition"), ""))
	runner.check("primer paso tiene highlight/objective",
		SafeDict.as_string(step.get("highlight"), "") != ""
		and SafeDict.as_string(step.get("objective"), "") != "")
	var wrong: Dictionary = h.advance_tutorial("end_turn")
	runner.check("condición incorrecta no avanza", not bool(wrong.get("ok")))
	runner.check_eq("paso sigue siendo 0", 0, SafeDict.as_int(h.tutorial_state().get("step_index"), -1))
	var advanced: Dictionary = h.advance_tutorial("open_region")
	runner.check("condición correcta avanza", bool(advanced.get("ok")) and bool(advanced.get("advanced")))
	runner.check_eq("paso 1", 1, SafeDict.as_int(h.tutorial_state().get("step_index"), -1))
	var completed: Array = SafeDict.as_array(h.tutorial_state().get("completed_steps", null))
	runner.check("paso completado registrado", completed.has("mapa_y_region"))
	runner.check("el tutorial sigue activo", h.tutorial_active())
	# Saltar: desactiva y queda serializable.
	runner.check("skip desactiva tutorial", h.skip_tutorial())
	runner.check("tutorial inactivo tras skip", not h.tutorial_active())
	runner.check("estado skipped persistido", SafeDict.as_bool(h.tutorial_state().get("skipped"), false))


func _check_save_load(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("phase4_save_load")
	h.new_game_with_difficulty(PLAYER, "beginner")
	h.set_merchants(PLAYER, 6)
	h.produce_trade(PLAYER)
	h.advance_tutorial("open_region")
	# Consorte con PG disponible.
	var consort: Dictionary = h.spend_time_with_consort(PLAYER)
	runner.check("acción de consorte antes de guardar", bool(consort.get("ok")), str(consort))
	var tutorial_step: int = SafeDict.as_int(h.tutorial_state().get("step_index"), -1)
	var fertility_until: int = SafeDict.as_int(h.faction(PLAYER).get("fertility_bonus_until_turn"), -1)
	var inventory: Dictionary = h.trade_inventory(PLAYER)
	var hash_before: int = h.state_hash()
	runner.check("guardar partida con trade/tutorial/difficulty/consorte", h.save_game("phase4_save"))
	h.faction(PLAYER)["gold"] = 1
	h.advance_tutorial("assign_workers")
	h.new_game("france")
	runner.check("cargar partida Fase 4", h.load_game("phase4_save"))
	runner.check_eq("hash exacto Fase 4", hash_before, h.state_hash())
	runner.check_eq("dificultad tras cargar", "beginner", h.difficulty())
	runner.check("tutorial activo tras cargar", h.tutorial_active())
	runner.check_eq("paso de tutorial tras cargar", tutorial_step,
		SafeDict.as_int(h.tutorial_state().get("step_index"), -1))
	runner.check_eq("bonus de consorte tras cargar", fertility_until,
		SafeDict.as_int(h.faction(PLAYER).get("fertility_bonus_until_turn"), -1))
	var restored_inventory: Dictionary = h.trade_inventory(PLAYER)
	var inventory_ok: bool = true
	for good_id in inventory.keys():
		if not is_equal_approx(SafeDict.as_float(inventory.get(good_id), 0.0),
				SafeDict.as_float(restored_inventory.get(good_id), -1.0)):
			inventory_ok = false
	runner.check("inventario de mercancías tras cargar", inventory_ok)
	runner.check("estado serializable tras cargar", JSON.stringify(h.state()).length() > 1000)


func _check_old_save_defaults(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("save_migration")
	h.new_game(PLAYER)
	var save: Dictionary = SafeDict.as_dict(h.gs.call("to_dict"))
	save.erase("trade")
	save.erase("tutorial")
	save.erase("difficulty")
	save["save_version"] = 1
	var factions: Dictionary = SafeDict.as_dict(save.get("factions", null))
	for faction_id in factions.keys():
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		faction.erase("last_consort_turn")
		faction.erase("fertility_bonus_until_turn")
	runner.check("from_dict acepta save v1 sin campos Fase 4", bool(h.gs.call("from_dict", save)))
	runner.check("default difficulty normal", h.difficulty() == "normal")
	runner.check("default tutorial inactivo", not h.tutorial_active())
	runner.check("default trade inicializado", not h.trade_inventory(PLAYER).is_empty())
	var faction: Dictionary = h.faction(PLAYER)
	runner.check("defaults de consorte en la facción",
		faction.has("last_consort_turn") and faction.has("fertility_bonus_until_turn"))
	runner.check("hash estable tras migración",
		not SafeDict.as_string(h.gs.call("to_dict").get("difficulty"), "") == "")
