extends SceneTree
## Runner headless de CI (GDD §13; D-006). Sin plugin GUT en Fase 0 (GUT llega
## en Fase 1): asserts nativos + validación de datos §13.
##
## Uso:
##   godot --headless --path <repo> --script tests/run_all.gd
##
## Exit code 0 si todos los tests pasan y la validación de datos no reporta
## errores. Si data/ aún no tiene datasets, la validación sale con aviso y no
## rompe la CI (AG-1 trabaja en paralelo).

const TestRunnerScript = preload("res://tests/test_runner.gd")
const TestScaffoldScript = preload("res://tests/test_scaffold.gd")
const TestRngScript = preload("res://tests/test_rng.gd")
const TestValidatorScript = preload("res://tests/test_validator.gd")
const ValidatorCore = preload("res://tools/validator_core.gd")


func _initialize() -> void:
	var version_info: Dictionary = Engine.get_version_info()
	print("==============================================================")
	print(" The Sovereign's Blood — CI headless Fase 0 (criterios A3/A5)")
	print(" Godot %s" % str(version_info.get("string", "")))
	print("==============================================================")
	var runner: TestRunnerScript = TestRunnerScript.new()
	TestScaffoldScript.new().run(runner, self)
	TestRngScript.new().run(runner, self)
	TestValidatorScript.new().run(runner, self)
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
