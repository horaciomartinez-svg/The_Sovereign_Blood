extends SceneTree
## Runner headless de CI (GDD §13; D-006). Sin plugin GUT en Fase 0; en Fase 1
## se amplía con asserts nativos por sistema (TurnManager, economía, dinastía,
## diplomacia, militar, batalla, IA, eventos, GameState e integración).
##
## Uso:
##   godot --headless --path <repo> --script tests/run_all.gd
##
## Exit code 0 si todos los tests pasan y la validación de datos no reporta
## errores. Los tests acceden a los autoloads de forma dinámica (ver
## tests/harness.gd) porque Godot compila el script de --script antes de
## registrar los autoloads como identificadores globales.

const TestRunnerScript = preload("res://tests/test_runner.gd")
const TestScaffoldScript = preload("res://tests/test_scaffold.gd")
const TestRngScript = preload("res://tests/test_rng.gd")
const TestValidatorScript = preload("res://tests/test_validator.gd")
const TestGameStateScript = preload("res://tests/test_game_state.gd")
const TestTurnManagerScript = preload("res://tests/test_turn_manager.gd")
const TestEconomyScript = preload("res://tests/test_economy.gd")
const TestDynastyScript = preload("res://tests/test_dynasty.gd")
const TestDiplomacyScript = preload("res://tests/test_diplomacy.gd")
const TestMilitaryScript = preload("res://tests/test_military.gd")
const TestBattleScript = preload("res://tests/test_battle.gd")
const TestAiScript = preload("res://tests/test_ai.gd")
const TestEventsScript = preload("res://tests/test_events.gd")
const TestIntegrationScript = preload("res://tests/test_integration.gd")
const TestTacticalBattleScript = preload("res://tests/test_tactical_battle.gd")
const TestCloseCombatScript = preload("res://tests/test_close_combat.gd")
const TestEspionageScript = preload("res://tests/test_espionage.gd")
const TestCrecyScript = preload("res://tests/test_crecy.gd")
const TestSpritesScript = preload("res://tests/test_sprites.gd")
const TestBattleTilesScript = preload("res://tests/test_battle_tiles.gd")
const TestScenariosScript = preload("res://tests/test_scenarios.gd")
const TestMvp1337Script = preload("res://tests/test_mvp_1337.gd")
const TestMusicScript = preload("res://tests/test_music.gd")
const HarnessScript = preload("res://tests/harness.gd")
const ValidatorCore = preload("res://tools/validator_core.gd")


func _initialize() -> void:
	var version_info: Dictionary = Engine.get_version_info()
	print("==============================================================")
	print(" The Sovereign's Blood — CI headless (Fase 0 + Fase 1 + Fase 2 + Fase 3)")
	print(" Godot %s" % str(version_info.get("string", "")))
	print("==============================================================")
	var runner: TestRunnerScript = TestRunnerScript.new()
	TestScaffoldScript.new().run(runner, self)
	TestRngScript.new().run(runner, self)
	TestValidatorScript.new().run(runner, self)
	var harness: HarnessScript = HarnessScript.new(root)
	if not harness.available():
		print("[FAIL] autoloads no disponibles: ", harness.missing)
		quit(1)
		return
	# Sistemas Fase 1.
	TestGameStateScript.new().run(runner, harness)
	TestTurnManagerScript.new().run(runner, harness)
	TestEconomyScript.new().run(runner, harness)
	TestDynastyScript.new().run(runner, harness)
	TestDiplomacyScript.new().run(runner, harness)
	TestMilitaryScript.new().run(runner, harness)
	TestBattleScript.new().run(runner, harness)
	TestAiScript.new().run(runner, harness)
	TestEventsScript.new().run(runner, harness)
	TestIntegrationScript.new().run(runner, harness)
	# Profundidad militar Fase 2 (Niveles 2/3, espionaje, Crécy).
	TestTacticalBattleScript.new().run(runner, harness)
	TestCloseCombatScript.new().run(runner, harness)
	TestEspionageScript.new().run(runner, harness)
	TestCrecyScript.new().run(runner, harness)
	# Fase 3 (D-040/D-042): sprites de unidades, animación y proyectiles.
	TestSpritesScript.new().run(runner, harness)
	# Fase 3 §10.4 (D-053): tiles de batalla y reglas tácticas N2/N3.
	TestBattleTilesScript.new().run(runner, harness)
	# Fase 3 (D-058/D-059/D-060/D-061): escenarios, tecnología y victoria.
	TestScenariosScript.new().run(runner, harness)
	# Fase 3.3 MVP-1337 (D-066): audio, loop, §4.5, save/load, rendimiento y balance.
	TestMvp1337Script.new().run(runner, harness)
	# Fase 3.3 D-067 §2.5: música OGG, buses, crossfade y persistencia.
	TestMusicScript.new().run(runner, harness)
	_run_data_validation(runner)

	var summary: Dictionary = runner.summary()
	print("--------------------------------------------------------------")
	print("RESULTADO: %d pasados, %d fallidos, %d omitidos" % [int(summary["passed"]), int(summary["failed"]), int(summary["skipped"])])
	if int(summary["failed"]) > 0:
		print("Fallos:")
		for failure in (summary["failures"] as Array):
			print("  - " + str(failure))
		print("CI: FAIL (exit 1)")
		quit(1)
		return
	print("CI: OK (exit 0)")
	quit(0)


func _run_data_validation(runner: TestRunnerScript) -> void:
	runner.begin_suite("data_validation")
	var core: ValidatorCore = ValidatorCore.new()
	var result: Dictionary = core.validate()
	for info_line in (result["infos"] as Array):
		print(str(info_line))
	for warning_line in (result["warnings"] as Array):
		print(str(warning_line))
	for skip_line in (result["skips"] as Array):
		print(str(skip_line))
	for error_line in (result["errors"] as Array):
		print(str(error_line))
	var datasets := int(result["datasets"])
	var schemas := int(result["schemas"])
	var check_count := int(result["checks"])
	var test_name := "data/: validación §13 (%d dataset(s), %d schema(s), %d comprobaciones)" % [datasets, schemas, check_count]
	if bool(result["ok"]):
		if datasets == 0:
			print("  [INFO] sin datasets aún en data/: validación de esquemas y reglas cruzadas diferida al QA final (AG-4)")
		runner.check(test_name, true)
	else:
		runner.check(test_name, false, "%d error(es) de datos" % (result["errors"] as Array).size())
