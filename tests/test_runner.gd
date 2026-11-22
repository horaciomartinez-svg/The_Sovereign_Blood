extends RefCounted
## Micro-runner de tests para CI headless (sin plugin GUT en Fase 0; GUT llega
## en Fase 1, GDD §13). Solo asserts nativos y salida legible.

var passed: int = 0
var failed: int = 0
var skipped: int = 0
var failures: Array[String] = []
var suite: String = ""
var verbose: bool = true


func begin_suite(suite_name: String) -> void:
	suite = suite_name
	print("[SUITE] %s" % suite)


## Registra un assert. Devuelve el resultado booleano para encadenar.
func check(test_name: String, condition: bool, detail: String = "") -> bool:
	if condition:
		passed += 1
		if verbose:
			print("  [PASS] %s" % test_name)
		return true
	failed += 1
	var message := "%s/%s" % [suite, test_name]
	if detail != "":
		message += ": " + detail
	failures.append(message)
	print("  [FAIL] %s" % message)
	return false


func check_eq(test_name: String, expected: Variant, actual: Variant) -> bool:
	var equal := _values_equal(expected, actual)
	var detail := ""
	if not equal:
		detail = "esperado %s, recibido %s" % [str(expected), str(actual)]
	return check(test_name, equal, detail)


func check_not_null(test_name: String, value: Variant) -> bool:
	return check(test_name, value != null, "valor null")


func skip(test_name: String, reason: String) -> void:
	skipped += 1
	print("  [SKIP] %s: %s" % [test_name, reason])


func summary() -> Dictionary:
	return {
		"passed": passed,
		"failed": failed,
		"skipped": skipped,
		"failures": failures.duplicate(),
	}


func _values_equal(expected: Variant, actual: Variant) -> bool:
	if (expected is int or expected is float) and (actual is int or actual is float):
		return float(expected) == float(actual)
	return expected == actual
