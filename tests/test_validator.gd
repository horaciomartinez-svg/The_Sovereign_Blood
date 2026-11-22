extends RefCounted
## Tests del núcleo del validador (D-004): keywords de JSON Schema soportadas y
## comportamiento seguro cuando data/ aún no tiene datasets.

const TestRunnerScript = preload("res://tests/test_runner.gd")
const ValidatorCore = preload("res://tools/validator_core.gd")


func run(runner: TestRunnerScript, _tree: SceneTree) -> void:
	runner.begin_suite("validator")
	_check_types_and_required(runner)
	_check_enum_const_pattern(runner)
	_check_numbers(runner)
	_check_objects(runner)
	_check_arrays(runner)
	_check_composition(runner)
	_check_local_ref(runner)
	_check_dataset_envelope(runner)
	_check_cross_rules_negative(runner)
	_check_empty_data_behaviour(runner)


func _errors(instance: Variant, schema: Variant) -> Array:
	var core: ValidatorCore = ValidatorCore.new()
	return core.validate_instance(instance, schema)


func _contains(errors: Array, needle: String) -> bool:
	for error_line in errors:
		if str(error_line).contains(needle):
			return true
	return false


func _check_types_and_required(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"required": ["id", "count"],
		"properties": {
			"id": {"type": "string"},
			"count": {"type": "integer"},
			"active": {"type": "boolean"},
		},
	}
	var valid: Dictionary = {"id": "england", "count": 2, "active": true}
	runner.check("objeto válido → 0 errores", _errors(valid, schema).is_empty(), str(_errors(valid, schema)))

	var missing: Dictionary = {"id": "england"}
	var missing_errors := _errors(missing, schema)
	runner.check("campo requerido ausente → [FAIL]", _contains(missing_errors, "requerido 'count'"), str(missing_errors))
	runner.check("el error incluye archivo y campo ($.count)", _contains(missing_errors, "<memoria> :: $") and _contains(missing_errors, "count"))

	var wrong_type: Dictionary = {"id": 7, "count": 2}
	var type_errors := _errors(wrong_type, schema)
	runner.check("tipo incorrecto → [FAIL] tipo esperado", _contains(type_errors, "tipo esperado string"), str(type_errors))

	var float_that_is_integer := {"id": "x", "count": 2.0}
	runner.check("integer acepta 2.0 (semántica JSON Schema)", _errors(float_that_is_integer, schema).is_empty(), str(_errors(float_that_is_integer, schema)))

	var float_value := {"id": "x", "count": 2.5}
	runner.check("integer rechaza 2.5", not _errors(float_value, schema).is_empty())


func _check_enum_const_pattern(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"properties": {
			"terrain": {"type": "string", "enum": ["plains", "forest", "mountain"]},
			"version": {"const": 1},
			"region_id": {"type": "string", "pattern": "^region_[a-z0-9_]+$"},
		},
	}
	var valid: Dictionary = {"terrain": "forest", "version": 1, "region_id": "region_normandy"}
	runner.check("enum/const/pattern válidos → 0 errores", _errors(valid, schema).is_empty(), str(_errors(valid, schema)))

	var bad_enum := _errors({"terrain": "desert"}, schema)
	runner.check("enum fuera de lista → [FAIL]", _contains(bad_enum, "no está en enum"), str(bad_enum))

	var bad_const := _errors({"version": 2}, schema)
	runner.check("const distinto → [FAIL]", _contains(bad_const, "const"), str(bad_const))

	var bad_pattern := _errors({"region_id": "Normandy"}, schema)
	runner.check("pattern incumplido → [FAIL]", _contains(bad_pattern, "no cumple el patrón"), str(bad_pattern))


func _check_numbers(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"properties": {
			"strength": {"type": "integer", "minimum": 1, "maximum": 20},
			"wealth": {"type": "number", "minimum": 0},
		},
	}
	runner.check("minimum/maximum válidos → 0 errores", _errors({"strength": 9, "wealth": 60.5}, schema).is_empty())
	runner.check("minimum incumplido → [FAIL]", _contains(_errors({"strength": 0}, schema), "mínimo"))
	runner.check("maximum incumplido → [FAIL]", _contains(_errors({"strength": 21}, schema), "máximo"))


func _check_objects(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"properties": {
			"id": {"type": "string"},
			"stats": {
				"type": "object",
				"required": ["command"],
				"properties": {"command": {"type": "integer"}},
			},
		},
		"additionalProperties": false,
	}
	runner.check("objeto anidado válido → 0 errores", _errors({"id": "x", "stats": {"command": 85}}, schema).is_empty())
	runner.check("additionalProperties=false → [FAIL]", _contains(_errors({"id": "x", "extra": 1}, schema), "no permitido"))
	runner.check("propiedad anidada requerida → [FAIL]", _contains(_errors({"stats": {}}, schema), "requerido 'command'"))

	var additional_schema: Dictionary = {
		"type": "object",
		"properties": {"id": {"type": "string"}},
		"additionalProperties": {"type": "integer"},
	}
	runner.check("additionalProperties con schema válido → 0 errores", _errors({"id": "x", "a": 1, "b": 2}, additional_schema).is_empty())
	runner.check("additionalProperties con schema inválido → [FAIL]", not _errors({"id": "x", "a": "no"}, additional_schema).is_empty())


func _check_arrays(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"properties": {
			"adjacency": {
				"type": "array",
				"minItems": 1,
				"uniqueItems": true,
				"items": {"type": "string", "pattern": "^region_"},
			},
		},
	}
	runner.check("array válido → 0 errores", _errors({"adjacency": ["region_a", "region_b"]}, schema).is_empty(), str(_errors({"adjacency": ["region_a", "region_b"]}, schema)))
	runner.check("minItems → [FAIL]", _contains(_errors({"adjacency": []}, schema), "al menos 1"))
	runner.check("uniqueItems → [FAIL]", _contains(_errors({"adjacency": ["region_a", "region_a"]}, schema), "uniqueItems"))
	runner.check("items con tipo incorrecto → [FAIL]", not _errors({"adjacency": [7]}, schema).is_empty())
	runner.check("el error de items incluye el índice ($.adjacency[0])", _contains(_errors({"adjacency": [7]}, schema), "adjacency[0]"))


func _check_composition(runner: TestRunnerScript) -> void:
	var one_of: Dictionary = {
		"type": "object",
		"properties": {
			"died": {"oneOf": [{"type": "string"}, {"type": "integer"}]},
		},
	}
	runner.check("oneOf válido (string) → 0 errores", _errors({"died": "1348"}, one_of).is_empty())
	runner.check("oneOf válido (integer) → 0 errores", _errors({"died": 1348}, one_of).is_empty())
	runner.check("oneOf inválido → [FAIL]", _contains(_errors({"died": 1.5}, one_of), "oneOf"))

	var nullable_type: Dictionary = {"type": ["string", "null"]}
	runner.check("type como lista acepta null", _errors(null, nullable_type).is_empty())
	runner.check("type como lista acepta string", _errors("x", nullable_type).is_empty())
	runner.check("type como lista rechaza integer", not _errors(3, nullable_type).is_empty())


func _check_local_ref(runner: TestRunnerScript) -> void:
	var schema: Dictionary = {
		"type": "object",
		"properties": {
			"playable": {"$ref": "#/definitions/booleanFlag"},
		},
		"definitions": {
			"booleanFlag": {"type": "boolean"},
		},
	}
	runner.check("$ref local válido → 0 errores", _errors({"playable": true}, schema).is_empty(), str(_errors({"playable": true}, schema)))
	runner.check("$ref local detecta tipo incorrecto", not _errors({"playable": "yes"}, schema).is_empty())


func _check_dataset_envelope(runner: TestRunnerScript) -> void:
	# Réplica del contrato D-009: el schema valida el documento COMPLETO.
	var schema: Dictionary = {
		"type": "object",
		"required": ["schema_version", "factions"],
		"properties": {
			"schema_version": {"type": "integer", "const": 1},
			"factions": {
				"type": "array",
				"minItems": 1,
				"items": {
					"type": "object",
					"required": ["id", "name", "capital", "playable"],
					"properties": {
						"id": {"type": "string", "pattern": "^[a-z][a-z0-9_]*$"},
						"name": {"type": "string"},
						"capital": {"type": "string"},
						"playable": {"type": "boolean"},
					},
					"additionalProperties": false,
				},
			},
		},
		"additionalProperties": false,
	}
	var valid: Dictionary = {
		"schema_version": 1,
		"factions": [{"id": "england", "name": "Inglaterra", "capital": "region_londres", "playable": true}],
	}
	runner.check("envelope D-009 válido → 0 errores", _errors(valid, schema).is_empty(), str(_errors(valid, schema)))

	var invalid: Dictionary = {
		"schema_version": 1,
		"factions": [{"id": "England", "name": "Inglaterra", "capital": "region_londres", "playable": "yes"}],
	}
	var invalid_errors := _errors(invalid, schema)
	runner.check("envelope D-009 detecta id con pattern", _contains(invalid_errors, ".id"), str(invalid_errors))
	runner.check("envelope D-009 detecta playable no booleano", _contains(invalid_errors, ".playable"), str(invalid_errors))


const TEST_DATA_ROOT := "user://_tsb_validation_selftest"


## Prueba de integración de las reglas cruzadas §13 con un dataset roto a
## propósito en user:// (nunca toca data/). Debe detectar cada error.
func _check_cross_rules_negative(runner: TestRunnerScript) -> void:
	_remove_dir(TEST_DATA_ROOT)
	_write_json(TEST_DATA_ROOT.path_join("factions.json"), {
		"schema_version": 1,
		"factions": [
			{"id": "england", "name": "Inglaterra", "capital": "region_londres", "playable": true},
			{"id": "france", "name": "Francia", "capital": "region_paris", "playable": true},
		],
	})
	_write_json(TEST_DATA_ROOT.path_join("regions.json"), {
		"schema_version": 1,
		"regions": [
			{"id": "region_londres", "name": "Londres", "adjacency": ["region_york"], "year_data": {"1337": {"owner": "england"}}},
			{"id": "region_york", "name": "York", "adjacency": [], "year_data": {"1337": {"owner": "atlantis"}}},
			{"id": "region_ruan", "name": "Ruan", "adjacency": ["region_londres", "region_inexistente"], "year_data": {"1337": {"owner": "france"}}},
		],
	})
	_write_json(TEST_DATA_ROOT.path_join("characters.json"), {
		"schema_version": 1,
		"characters": [{"id": "edward", "name": "Eduardo", "family": {"father": "desconocido_externo"}}],
	})
	_write_json(TEST_DATA_ROOT.path_join("scenarios").path_join("scenario_1337.json"), {
		"id": "scenario_1337",
		"start_year": 1337,
		"factions": ["england", "france", "ghostland"],
		"initial_state": {"characters": "characters_1337.json"},
		"events_script": "events_1337.json",
	})
	# Solo factions tiene schema: el resto debe avisar de schema ausente.
	_write_json(TEST_DATA_ROOT.path_join("schema").path_join("factions.schema.json"), {
		"type": "object",
		"required": ["schema_version", "factions"],
		"properties": {
			"schema_version": {"type": "integer", "const": 1},
			"factions": {"type": "array", "items": {"type": "object", "required": ["id", "name", "capital", "playable"]}},
		},
	})

	var core: ValidatorCore = ValidatorCore.new()
	var result: Dictionary = core.validate(TEST_DATA_ROOT)
	var error_lines: Array = result["errors"]
	runner.check("integración: dataset roto NO pasa la validación", not bool(result["ok"]))
	runner.check("integración: capital inexistente detectada", _contains(error_lines, "no existe como región"), str(error_lines))
	runner.check("integración: adyacencia asimétrica detectada", _contains(error_lines, "adyacencia asimétrica"), str(error_lines))
	runner.check("integración: adyacencia a región inexistente detectada", _contains(error_lines, "región inexistente"), str(error_lines))
	runner.check("integración: owner inexistente detectado", _contains(error_lines, "owner 'atlantis'"), str(error_lines))
	runner.check("integración: personaje referenciado inexistente detectado", _contains(error_lines, "desconocido_externo"), str(error_lines))
	runner.check("integración: facción de escenario inexistente detectada", _contains(error_lines, "la facción 'ghostland'"), str(error_lines))
	runner.check("integración: fichero de personajes referenciado inexistente detectado", _contains(error_lines, "characters_1337.json"), str(error_lines))
	runner.check("integración: events_script inexistente detectado", _contains(error_lines, "events_1337.json"), str(error_lines))
	runner.check("integración: playable ≠ 8 detectado", _contains(error_lines, "exactamente 8"), str(error_lines))
	var has_missing_schema_warning := false
	for warning_line in (result["warnings"] as Array):
		if str(warning_line).contains("sin schema"):
			has_missing_schema_warning = true
	runner.check("integración: aviso por dataset sin schema", has_missing_schema_warning)
	runner.check("integración: errores con formato [FAIL] archivo :: campo", _contains(error_lines, "[FAIL] user://_tsb_validation_selftest/"), str(error_lines))
	_remove_dir(TEST_DATA_ROOT)


func _write_json(path: String, data: Variant) -> void:
	var directory := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("[WARN] test_validator: no se pudo escribir %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _remove_dir(path: String) -> void:
	_remove_dir_absolute(ProjectSettings.globalize_path(path))


func _remove_dir_absolute(absolute_path: String) -> void:
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var child_path := absolute_path.path_join(entry_name)
			if dir.current_is_dir():
				_remove_dir_absolute(child_path)
			else:
				DirAccess.remove_absolute(child_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _check_empty_data_behaviour(runner: TestRunnerScript) -> void:
	var core: ValidatorCore = ValidatorCore.new()
	var result: Dictionary = core.validate()
	var datasets := int(result["datasets"])
	if datasets == 0:
		var skipped_cleanly: bool = bool(result["ok"]) and not (result["skips"] as Array).is_empty()
		runner.check("data/ sin datasets → OK con aviso (no rompe CI)", skipped_cleanly, str(result["skips"]))
	else:
		runner.skip("data/ sin datasets", "%d dataset(s) presentes: lo cubre la suite data_validation" % datasets)
