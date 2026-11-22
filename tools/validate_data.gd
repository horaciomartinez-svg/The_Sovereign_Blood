extends SceneTree
## Validador de datos de The Sovereign's Blood (GDD §7, §13; D-004, D-009).
##
## Uso:
##   godot --headless --path <repo> --script tools/validate_data.gd
##
## - Valida data/**/*.json contra data/schema/<x>.schema.json (documento completo).
## - Aplica las reglas cruzadas de GDD §13.
## - Imprime [OK]/[FAIL]/[WARN]/[SKIP] con archivo + campo.
## - Exit code 0 solo si no hay errores. Si data/ aún no tiene datasets, sale 0
##   con aviso "sin datasets aún" (AG-1 escribe en paralelo).

const ValidatorCore = preload("res://tools/validator_core.gd")


func _initialize() -> void:
	var core: RefCounted = ValidatorCore.new()
	var result: Dictionary = core.validate()
	_print_report(result)
	quit(0 if bool(result["ok"]) else 1)


func _print_report(result: Dictionary) -> void:
	var datasets: int = int(result["datasets"])
	var schemas: int = int(result["schemas"])
	var check_count: int = int(result["checks"])
	print("[INFO] validate_data — datasets=%d schemas=%d comprobaciones=%d" % [datasets, schemas, check_count])
	print("[INFO] raíz de datos: data/ (res://data)")
	for info_line in (result["infos"] as Array):
		print(str(info_line))
	for warning_line in (result["warnings"] as Array):
		print(str(warning_line))
	for skip_line in (result["skips"] as Array):
		print(str(skip_line))
	var error_list: Array = result["errors"]
	for error_line in error_list:
		print(str(error_line))
	if bool(result["ok"]):
		if datasets == 0:
			print("[OK] validate_data — sin datasets aún (data/ vacía o incompleta): nada que validar. El QA final (AG-4) lo ejecutará con data/ completa.")
		else:
			print("[OK] validate_data — %d dataset(s) validado(s) contra %d schema(s); reglas cruzadas §13 OK; 0 errores." % [datasets, schemas])
	else:
		print("[FAIL] validate_data — %d error(es) de validación; corregir antes de cerrar Fase 0." % error_list.size())
