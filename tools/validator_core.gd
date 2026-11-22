extends RefCounted
## Núcleo de validación de datos (GDD §7, §13; decisión D-004 y contrato D-009).
##
## Valida los datasets de res://data/ en dos capas:
##   1. JSON Schema draft 2020-12, subconjunto D-004:
##      type, required, properties, additionalProperties, items, enum, const,
##      minimum, maximum, oneOf, pattern, minItems, uniqueItems (+ $ref local
##      opcional, que AG-1 no usa).
##   2. Reglas cruzadas de GDD §13:
##      capital existe en regions · owner de cada año existe en factions ·
##      adyacencias simétricas · scenario.factions existe en factions ·
##      personajes referenciados existen · toda región tiene dueño en el año
##      del escenario · exactamente 8 facciones playable en 1337.
##
## Convenio de ficheros (D-009): data/<x>.json ↔ data/schema/<x>.schema.json;
## events_1337.json ↔ events.schema.json; scenarios/scenario_1337.json ↔
## scenario.schema.json. Los schemas validan el documento COMPLETO.
##
## Datos de PRESENTACIÓN (D-017/D-024/D-028): `data/map_layout.json` (tablero
## hexagonal deprecado por D-024) y `data/map_borders.json` (fronteras
## vectoriales del mapa §10.1) NO son datasets de simulación: solo alimentan la
## UI. Se excluyen explícitamente de la validación (no tienen schema ni reglas
## cruzadas de GDD §13).
##
## No depende de autoloads: lo usan tools/validate_data.gd (CLI) y
## tests/run_all.gd (CI) con el mismo resultado.

const DATA_DIR: String = "res://data"
const SCHEMA_DIR: String = "res://data/schema"

## Ficheros JSON de data/ que NO son datasets de simulación (solo presentación,
## D-017/D-024): el validador los ignora por completo (ni schema ni reglas
## cruzadas). `map_layout.json` está deprecado (D-024) y `map_borders.json` es
## geometría de presentación del mapa §10.1.
const NON_SIMULATION_DATASETS: Array[String] = ["map_layout.json", "map_borders.json"]

## Fase 3 §10.4 (D-053): claves y balance de `data/battle_tiles.json`. Es un
## dataset de JUEGO (no presentación): reglas tácticas N2/N3.
const BATTLE_TILES_KEYS: Array[String] = [
	"pastizal", "pastizal_arbustos", "pradera", "rio", "puente", "puente_villa",
	"colina", "bosque", "montana", "villa", "villa_calle", "camino",
]
const BATTLE_TILES_ROUTE_PREFIX: String = "res://assets/art/battle/tiles/tile_"
const BATTLE_TILES_EXPECTED: Dictionary = {
	"pastizal": {"move_cost": 1.0, "defense": 0, "passable": true},
	"pastizal_arbustos": {"move_cost": 1.0, "defense": 0, "passable": true},
	"pradera": {"move_cost": 1.0, "defense": 0, "passable": true},
	"rio": {"move_cost": null, "defense": 0, "passable": false},
	"puente": {"move_cost": 1.0, "defense": 0, "passable": true},
	"puente_villa": {"move_cost": 1.0, "defense": 1, "passable": true},
	"colina": {"move_cost": 2.0, "defense": 1, "passable": true},
	"bosque": {"move_cost": 2.0, "defense": 1, "passable": true, "cavalry_penalty": true},
	"montana": {"move_cost": null, "defense": 0, "passable": false},
	"villa": {"move_cost": 1.0, "defense": 1, "passable": true},
	"villa_calle": {"move_cost": 1.0, "defense": 0, "passable": true, "move_bonus": true},
	"camino": {"move_cost": 0.5, "defense": 0, "passable": true, "move_bonus": true},
}

## Raíces efectivas de la validación. Por defecto res://data; los tests pueden
## pasar un directorio temporal a validate(base_dir).
var _data_root: String = DATA_DIR
var _schema_root: String = SCHEMA_DIR

## Keywords de JSON Schema implementadas por este validador.
const SUPPORTED_KEYWORDS: Array = [
	"type", "required", "properties", "additionalProperties", "items",
	"enum", "const", "minimum", "maximum", "oneOf", "pattern", "minItems",
	"uniqueItems", "maxItems", "$ref", "allOf", "anyOf", "not",
]
## Keywords de metadatos/validación que se aceptan y se ignoran.
const IGNORED_KEYWORDS: Array = [
	"$schema", "$id", "$comment", "title", "description", "default",
	"examples", "deprecated", "readOnly", "writeOnly", "definitions",
	"$defs", "format",
]

var errors: Array[String] = []
var warnings: Array[String] = []
var skips: Array[String] = []
var infos: Array[String] = []
var checks: int = 0

var dataset_paths: Array[String] = []
var schema_paths: Array[String] = []

var _datasets: Dictionary = {}  # path -> {"data": Variant}
var _schemas: Dictionary = {}   # path -> Variant (raíz del schema)
var _entities: Dictionary = {}  # kind -> Array[{file, path, obj}]
var _ids: Dictionary = {}       # kind -> {id: {file, path, obj}}
var _scanned_schemas: Dictionary = {}


## Ejecuta la validación completa y devuelve un informe serializable.
## `base_dir` permite validar un directorio alternativo (tests); por defecto
## valida res://data.
func validate(base_dir: String = "") -> Dictionary:
	_reset()
	if base_dir != "":
		_data_root = base_dir.trim_suffix("/")
		_schema_root = _data_root.path_join("schema")
	if DirAccess.open(_data_root) == null:
		skips.append("[SKIP] no existe %s: sin datasets aún" % _rel(_data_root))
		return report()
	_scan_dir(_data_root)
	schema_paths.sort()
	dataset_paths.sort()
	if dataset_paths.is_empty():
		skips.append("[SKIP] sin datasets aún en %s (AG-1 en paralelo): validación de schemas y reglas cruzadas omitida" % _rel(_data_root))
		return report()

	_load_schemas()
	_load_datasets()
	_validate_datasets()
	_index_entities()
	_cross_rules()
	return report()


## Valida una instancia en memoria contra un schema (API usada por los tests).
func validate_instance(instance: Variant, schema: Variant) -> Array[String]:
	var root: Dictionary = {}
	if schema is Dictionary:
		root = schema
	var local_errors := _check(instance, schema, root, "$", "<memoria>")
	return local_errors


## Informe serializable de la última validación.
func report() -> Dictionary:
	return {
		"ok": errors.is_empty(),
		"errors": errors.duplicate(),
		"warnings": warnings.duplicate(),
		"skips": skips.duplicate(),
		"infos": infos.duplicate(),
		"datasets": dataset_paths.size(),
		"schemas": schema_paths.size(),
		"checks": checks,
	}


func _reset() -> void:
	errors.clear()
	warnings.clear()
	skips.clear()
	infos.clear()
	checks = 0
	dataset_paths.clear()
	schema_paths.clear()
	_datasets.clear()
	_schemas.clear()
	_entities.clear()
	_ids.clear()
	_scanned_schemas.clear()
	_data_root = DATA_DIR
	_schema_root = SCHEMA_DIR


# ---------------------------------------------------------------------------
# Descubrimiento y carga de ficheros
# ---------------------------------------------------------------------------

func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		errors.append("[FAIL] %s :: no se puede abrir el directorio" % _rel(dir_path))
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue
		var full_path := dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_scan_dir(full_path)
		elif entry_name.get_extension().to_lower() == "json":
			if NON_SIMULATION_DATASETS.has(entry_name.to_lower()):
				infos.append("[INFO] excluido de la validación (solo presentación, D-017/D-024): %s" % _rel(full_path))
			elif full_path.begins_with(_schema_root + "/"):
				schema_paths.append(full_path)
			else:
				dataset_paths.append(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _load_schemas() -> void:
	for path in schema_paths:
		var loaded := _load_json(path)
		if not bool(loaded["ok"]):
			errors.append("[FAIL] %s :: $ :: schema ilegible: %s" % [_rel(path), str(loaded["error"])])
			continue
		var root: Variant = loaded["data"]
		if not (root is Dictionary):
			errors.append("[FAIL] %s :: $ :: el schema raíz debe ser un objeto JSON" % _rel(path))
			continue
		_schemas[path] = root


func _load_datasets() -> void:
	for path in dataset_paths:
		var loaded := _load_json(path)
		if not bool(loaded["ok"]):
			errors.append("[FAIL] %s :: $ :: %s" % [_rel(path), str(loaded["error"])])
			continue
		_datasets[path] = {"data": loaded["data"]}


func _load_json(path: String) -> Dictionary:
	var result: Dictionary = {"ok": false, "data": null, "error": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["error"] = "no se puede abrir (error %d)" % FileAccess.get_open_error()
		return result
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		result["error"] = "JSON inválido (línea %d): %s" % [json.get_error_line(), json.get_error_message()]
		return result
	result["ok"] = true
	result["data"] = json.data
	return result


## Empareja un dataset con su schema aplicando el convenio D-009 + heurística.
func _schema_for(dataset_path: String) -> String:
	if not _datasets.has(dataset_path):
		return ""
	var root: Variant = _datasets[dataset_path]["data"]

	# 1) "$schema" declarado dentro del propio documento (override).
	if root is Dictionary and (root as Dictionary).has("$schema"):
		var resolved := _resolve_schema_reference(str((root as Dictionary)["$schema"]))
		if resolved != "":
			return resolved

	# 2) Nombre exacto: data/<x>.json → data/schema/<x>.schema.json.
	var stem := dataset_path.get_file().get_basename().to_lower()
	for candidate in _schema_name_candidates(stem):
		var direct := _schema_root.path_join(candidate + ".schema.json")
		if FileAccess.file_exists(direct):
			return direct
		var plain := _schema_root.path_join(candidate + ".json")
		if FileAccess.file_exists(plain):
			return plain

	# 3) Heurística por prefijo: events_1337.json → events.schema.json.
	var best := ""
	var best_length := -1
	for schema_path in schema_paths:
		var schema_stem := _schema_stem(schema_path)
		if schema_stem == "":
			continue
		if stem == schema_stem:
			return schema_path
		if stem.begins_with(schema_stem) and schema_stem.length() > best_length:
			var next_char := stem.substr(schema_stem.length(), 1)
			if next_char == "_" or next_char == "-" or next_char == "":
				best = schema_path
				best_length = schema_stem.length()
	return best


func _schema_name_candidates(stem: String) -> Array[String]:
	var names: Array[String] = []
	names.append(stem)
	var singular := _singular(stem)
	if singular != stem:
		names.append(singular)
	var known_kinds: Array = ["scenario", "events", "event", "characters", "character", "factions", "faction", "regions", "region", "units", "unit"]
	for kind in known_kinds:
		if stem.begins_with(kind):
			if not names.has(kind):
				names.append(kind)
			var kind_singular := _singular(kind)
			if not names.has(kind_singular):
				names.append(kind_singular)
	return names


func _singular(word: String) -> String:
	if word.length() > 3 and word.ends_with("s") and not word.ends_with("ss"):
		return word.substr(0, word.length() - 1)
	return word


func _schema_stem(schema_path: String) -> String:
	var file_name := schema_path.get_file()
	var stem := file_name.get_basename().to_lower()  # "characters.schema.json" → "characters.schema"
	if stem.ends_with(".schema"):
		stem = stem.substr(0, stem.length() - ".schema".length())
	return stem


func _resolve_schema_reference(reference: String) -> String:
	if reference.begins_with("http://") or reference.begins_with("https://"):
		return ""  # meta-schema remoto (p. ej. draft 2020-12): se ignora
	if reference.begins_with("res://"):
		return reference if FileAccess.file_exists(reference) else ""
	var cleaned := reference.trim_prefix("./").trim_prefix("/")
	var candidates: Array[String] = [
		_schema_root.path_join(cleaned),
		_data_root.path_join(cleaned),
	]
	for candidate in candidates:
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


# ---------------------------------------------------------------------------
# Capa 1: JSON Schema (subconjunto D-004)
# ---------------------------------------------------------------------------

func _validate_datasets() -> void:
	for dataset_path in dataset_paths:
		if not _datasets.has(dataset_path):
			continue
		var schema_path := _schema_for(dataset_path)
		if schema_path == "":
			warnings.append("[WARN] %s :: $ :: sin schema en data/schema/ (se omite la validación de esquema; las reglas cruzadas sí se aplican)" % _rel(dataset_path))
			continue
		if not _schemas.has(schema_path):
			continue
		infos.append("[INFO] schema aplicado: %s ↔ %s" % [_rel(dataset_path), _rel(schema_path)])
		var schema_root: Variant = _schemas[schema_path]
		if not (schema_root is Dictionary):
			continue
		_scan_schema_keywords(schema_root, _rel(schema_path), "$", _scanned_schemas)
		var dataset_root: Variant = _datasets[dataset_path]["data"]
		checks += 1
		var schema_errors := _check(dataset_root, schema_root, schema_root, "$", _rel(dataset_path))
		for schema_error in schema_errors:
			errors.append(schema_error)


## Avisa de keywords no soportadas para que el schema no dé una falsa sensación
## de validación (solo aviso: no bloquea la CI).
func _scan_schema_keywords(node: Variant, schema_file: String, path: String, seen: Dictionary) -> void:
	if not (node is Dictionary):
		return
	var schema: Dictionary = node
	for key in schema.keys():
		var key_name := str(key)
		match key_name:
			"properties":
				if schema[key] is Dictionary:
					var properties: Dictionary = schema[key]
					for property_name in properties.keys():
						_scan_schema_keywords(properties[property_name], schema_file, "%s.properties.%s" % [path, str(property_name)], seen)
			"items":
				_scan_schema_keywords(schema[key], schema_file, path + ".items", seen)
			"additionalProperties":
				if schema[key] is Dictionary:
					_scan_schema_keywords(schema[key], schema_file, path + ".additionalProperties", seen)
			"oneOf", "allOf", "anyOf":
				if schema[key] is Array:
					var index := 0
					for branch in (schema[key] as Array):
						_scan_schema_keywords(branch, schema_file, "%s.%s[%d]" % [path, key_name, index], seen)
						index += 1
			"not":
				_scan_schema_keywords(schema[key], schema_file, path + ".not", seen)
			"definitions", "$defs":
				if schema[key] is Dictionary:
					var definitions: Dictionary = schema[key]
					for definition_name in definitions.keys():
						_scan_schema_keywords(definitions[definition_name], schema_file, "%s.%s.%s" % [path, key_name, str(definition_name)], seen)
			_:
				if SUPPORTED_KEYWORDS.has(key_name):
					continue
				if IGNORED_KEYWORDS.has(key_name):
					continue
				var warning_key := "%s|%s|%s" % [schema_file, path, key_name]
				if not seen.has(warning_key):
					seen[warning_key] = true
					warnings.append("[WARN] %s :: %s :: keyword no soportada '%s' (se ignora)" % [schema_file, path, key_name])


func _check(instance: Variant, schema: Variant, root: Dictionary, path: String, file: String) -> Array[String]:
	var local_errors: Array[String] = []
	checks += 1
	if schema == null:
		return local_errors
	if not (schema is Dictionary):
		local_errors.append(_format_error(file, path, "schema inválido: se esperaba un objeto"))
		return local_errors
	var schema_dict: Dictionary = schema

	if schema_dict.has("$ref"):
		var reference := str(schema_dict["$ref"])
		var target: Variant = _resolve_local_ref(root, reference)
		if target == null:
			warnings.append("[WARN] %s :: %s :: $ref no resuelto '%s' (se omite)" % [file, path, reference])
		else:
			local_errors.append_array(_check(instance, target, root, path, file))

	if schema_dict.has("type"):
		if not _type_matches(instance, schema_dict["type"]):
			local_errors.append(_format_error(file, path, "tipo esperado %s, recibido %s" % [_describe_type(schema_dict["type"]), _json_type_of(instance)]))
			return local_errors

	if schema_dict.has("const"):
		if not _json_equal(instance, schema_dict["const"]):
			local_errors.append(_format_error(file, path, "se esperaba el valor const %s, recibido %s" % [str(schema_dict["const"]), str(instance)]))

	if schema_dict.has("enum") and schema_dict["enum"] is Array:
		var allowed: Array = schema_dict["enum"]
		var matched := false
		for candidate in allowed:
			if _json_equal(instance, candidate):
				matched = true
				break
		if not matched:
			local_errors.append(_format_error(file, path, "el valor %s no está en enum %s" % [str(instance), str(allowed)]))

	if (schema_dict.has("minimum") or schema_dict.has("maximum")) and (instance is int or instance is float):
		var numeric := float(instance)
		if schema_dict.has("minimum") and numeric < float(schema_dict["minimum"]):
			local_errors.append(_format_error(file, path, "valor %s menor que el mínimo %s" % [str(instance), str(schema_dict["minimum"])]))
		if schema_dict.has("maximum") and numeric > float(schema_dict["maximum"]):
			local_errors.append(_format_error(file, path, "valor %s mayor que el máximo %s" % [str(instance), str(schema_dict["maximum"])]))

	if schema_dict.has("pattern") and instance is String:
		var regex := RegEx.new()
		var regex_error := regex.compile(str(schema_dict["pattern"]))
		if regex_error == OK:
			if regex.search(instance) == null:
				local_errors.append(_format_error(file, path, "'%s' no cumple el patrón %s" % [str(instance), str(schema_dict["pattern"])]))
		else:
			warnings.append("[WARN] %s :: %s :: patrón inválido '%s' en el schema (se omite)" % [file, path, str(schema_dict["pattern"])])

	if instance is Dictionary:
		local_errors.append_array(_check_object(instance as Dictionary, schema_dict, root, path, file))

	if instance is Array:
		local_errors.append_array(_check_array(instance as Array, schema_dict, root, path, file))

	if schema_dict.has("oneOf") and schema_dict["oneOf"] is Array:
		var valid_branches := 0
		for branch in (schema_dict["oneOf"] as Array):
			if _check(instance, branch, root, path, file).is_empty():
				valid_branches += 1
		if valid_branches != 1:
			local_errors.append(_format_error(file, path, "oneOf: %d ramas válidas (se esperaba exactamente 1)" % valid_branches))

	if schema_dict.has("allOf") and schema_dict["allOf"] is Array:
		for branch in (schema_dict["allOf"] as Array):
			local_errors.append_array(_check(instance, branch, root, path, file))

	if schema_dict.has("anyOf") and schema_dict["anyOf"] is Array:
		var any_valid := false
		for branch in (schema_dict["anyOf"] as Array):
			if _check(instance, branch, root, path, file).is_empty():
				any_valid = true
				break
		if not any_valid:
			local_errors.append(_format_error(file, path, "anyOf: ninguna rama es válida"))

	if schema_dict.has("not"):
		if _check(instance, schema_dict["not"], root, path, file).is_empty():
			local_errors.append(_format_error(file, path, "la instancia coincide con un schema 'not'"))

	return local_errors


func _check_object(instance: Dictionary, schema: Dictionary, root: Dictionary, path: String, file: String) -> Array[String]:
	var local_errors: Array[String] = []
	if schema.has("required") and schema["required"] is Array:
		for required_key in (schema["required"] as Array):
			var key_name := str(required_key)
			if not instance.has(key_name):
				local_errors.append(_format_error(file, path, "falta el campo requerido '%s'" % key_name))

	var properties: Dictionary = {}
	if schema.has("properties") and schema["properties"] is Dictionary:
		properties = schema["properties"]
		for property_name in properties.keys():
			if instance.has(property_name):
				local_errors.append_array(_check(instance[property_name], properties[property_name], root, "%s.%s" % [path, str(property_name)], file))

	if schema.has("additionalProperties"):
		var additional: Variant = schema["additionalProperties"]
		for key in instance.keys():
			var key_name := str(key)
			if properties.has(key_name):
				continue
			if additional is bool and not bool(additional):
				local_errors.append(_format_error(file, path, "campo no permitido '%s' (additionalProperties=false)" % key_name))
			elif additional is Dictionary:
				local_errors.append_array(_check(instance[key], additional, root, "%s.%s" % [path, key_name], file))
	return local_errors


func _check_array(instance: Array, schema: Dictionary, root: Dictionary, path: String, file: String) -> Array[String]:
	var local_errors: Array[String] = []
	if schema.has("minItems") and instance.size() < int(schema["minItems"]):
		local_errors.append(_format_error(file, path, "se esperaban al menos %d elementos, hay %d" % [int(schema["minItems"]), instance.size()]))
	if schema.has("maxItems") and instance.size() > int(schema["maxItems"]):
		local_errors.append(_format_error(file, path, "se esperaban como máximo %d elementos, hay %d" % [int(schema["maxItems"]), instance.size()]))
	if schema.has("uniqueItems") and bool(schema["uniqueItems"]):
		var seen_items: Array = []
		for item in instance:
			for previous in seen_items:
				if _json_equal(previous, item):
					local_errors.append(_format_error(file, path, "elemento duplicado '%s' (uniqueItems=true)" % str(item)))
					break
			seen_items.append(item)
	if schema.has("items"):
		var items_schema: Variant = schema["items"]
		if items_schema is Dictionary:
			var index := 0
			for item in instance:
				local_errors.append_array(_check(item, items_schema, root, "%s[%d]" % [path, index], file))
				index += 1
		elif items_schema is Array:
			var tuple_schemas: Array = items_schema
			var limit := mini(tuple_schemas.size(), instance.size())
			for index in limit:
				local_errors.append_array(_check(instance[index], tuple_schemas[index], root, "%s[%d]" % [path, index], file))
	return local_errors


func _type_matches(instance: Variant, type_spec: Variant) -> bool:
	if type_spec is Array:
		for candidate in (type_spec as Array):
			if _type_matches(instance, candidate):
				return true
		return false
	if not (type_spec is String):
		return false
	match str(type_spec):
		"object":
			return instance is Dictionary
		"array":
			return instance is Array
		"string":
			return instance is String
		"boolean":
			return instance is bool
		"number":
			return (instance is int or instance is float) and not (instance is bool)
		"integer":
			if instance is int:
				return true
			if instance is float:
				return float(instance) == floorf(float(instance))
			return false
		"null":
			return instance == null
		_:
			return false


func _json_type_of(instance: Variant) -> String:
	if instance == null:
		return "null"
	if instance is bool:
		return "boolean"
	if instance is int:
		return "integer"
	if instance is float:
		return "number"
	if instance is String:
		return "string"
	if instance is Array:
		return "array"
	if instance is Dictionary:
		return "object"
	return type_string(typeof(instance))


func _describe_type(type_spec: Variant) -> String:
	if type_spec is Array:
		var parts: Array[String] = []
		for candidate in (type_spec as Array):
			parts.append(str(candidate))
		return " | ".join(parts)
	return str(type_spec)


func _json_equal(left: Variant, right: Variant) -> bool:
	var left_numeric: bool = (left is int or left is float) and not (left is bool)
	var right_numeric: bool = (right is int or right is float) and not (right is bool)
	if left_numeric and right_numeric:
		return float(left) == float(right)
	if left is Array and right is Array:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in left_array.size():
			if not _json_equal(left_array[index], right_array[index]):
				return false
		return true
	if left is Dictionary and right is Dictionary:
		var left_dict: Dictionary = left
		var right_dict: Dictionary = right
		if left_dict.size() != right_dict.size():
			return false
		for key in left_dict.keys():
			if not right_dict.has(key):
				return false
			if not _json_equal(left_dict[key], right_dict[key]):
				return false
		return true
	return left == right


## Resuelve "$ref" locales del estilo "#/definitions/X" o "#/$defs/X".
func _resolve_local_ref(root: Dictionary, reference: String) -> Variant:
	if not reference.begins_with("#"):
		return null  # referencias externas no soportadas
	var pointer := reference.substr(1)
	if pointer == "" or pointer == "/":
		return root
	var parts := pointer.split("/")
	var current: Variant = root
	for index in range(1, parts.size()):
		var part := str(parts[index]).replace("~1", "/").replace("~0", "~")
		if current is Dictionary and (current as Dictionary).has(part):
			current = (current as Dictionary)[part]
		elif current is Array and part.is_valid_int():
			var array: Array = current
			var array_index := int(part)
			if array_index >= 0 and array_index < array.size():
				current = array[array_index]
			else:
				return null
		else:
			return null
	return current


# ---------------------------------------------------------------------------
# Capa 2: reglas cruzadas de GDD §13
# ---------------------------------------------------------------------------

func _index_entities() -> void:
	for kind in ["faction", "region", "character", "unit", "scenario", "event"]:
		_entities[kind] = []
		_ids[kind] = {}
	for dataset_path in dataset_paths:
		if not _datasets.has(dataset_path):
			continue
		var kind := _kind_of(dataset_path)
		if kind == "":
			warnings.append("[WARN] %s :: $ :: tipo de dataset no reconocido (se valida contra schema pero sin reglas cruzadas)" % _rel(dataset_path))
			continue
		# battle_tiles no es una lista de entidades: lo valida su regla cruzada.
		if kind == "battle_tiles":
			continue
		var root: Variant = _datasets[dataset_path]["data"]
		var list := _entities_of(root, kind)
		if list.is_empty():
			warnings.append("[WARN] %s :: $ :: no se encontraron entidades de tipo '%s' (formato no reconocido; sin reglas cruzadas para este fichero)" % [_rel(dataset_path), kind])
			continue
		var index := 0
		for item in list:
			if not (item is Dictionary):
				errors.append(_format_error(_rel(dataset_path), "$.%s[%d]" % [kind + "s", index], "la entidad no es un objeto"))
				index += 1
				continue
			var record: Dictionary = {
				"file": _rel(dataset_path),
				"path": "$.%s[%d]" % [kind + "s", index],
				"obj": item,
			}
			_entities[kind].append(record)
			var entity_id := _as_id((item as Dictionary).get("id", null))
			if entity_id == "":
				errors.append(_format_error(_rel(dataset_path), str(record["path"]), "entidad sin 'id'"))
			elif _ids[kind].has(entity_id):
				var previous: Dictionary = _ids[kind][entity_id]
				errors.append(_format_error(_rel(dataset_path), str(record["path"]) + ".id", "id '%s' duplicado (ya definido en %s)" % [entity_id, str(previous["path"])]))
			else:
				_ids[kind][entity_id] = record
			index += 1


func _kind_of(dataset_path: String) -> String:
	var stem := dataset_path.get_file().get_basename().to_lower()
	if stem.begins_with("battle_tiles") or stem.begins_with("battle_tile"):
		return "battle_tiles"
	if stem.begins_with("scenario"):
		return "scenario"
	if stem.begins_with("event"):
		return "event"
	if stem.begins_with("character") or stem.begins_with("person"):
		return "character"
	if stem.begins_with("faction"):
		return "faction"
	if stem.begins_with("region"):
		return "region"
	if stem.begins_with("unit"):
		return "unit"
	return ""


func _entities_of(root: Variant, kind: String) -> Array:
	if root is Array:
		return root
	if root is Dictionary:
		var root_dict: Dictionary = root
		var keys: Array = [kind + "s", "items", "data", kind]
		for key in keys:
			if root_dict.has(key) and root_dict[key] is Array:
				return root_dict[key]
		if kind == "scenario" and (root_dict.has("id") or root_dict.has("start_year")):
			return [root_dict]
		for key in root_dict.keys():
			var value: Variant = root_dict[key]
			if value is Array and not (value as Array).is_empty() and (value as Array)[0] is Dictionary:
				return value
	return []


func _cross_rules() -> void:
	_check_capital_exists()
	_check_region_owners()
	_check_adjacency_symmetry()
	_check_scenario_factions()
	_check_character_references()
	_check_regions_owned_per_scenario()
	_check_playable_1337()
	_check_battle_tiles()


func _has_kind(kind: String) -> bool:
	return not (_ids.get(kind, {}) as Dictionary).is_empty()


func _id_map(kind: String) -> Dictionary:
	var mapping: Dictionary = _ids.get(kind, {})
	return mapping


func _check_capital_exists() -> void:
	if not _has_kind("faction") or not _has_kind("region"):
		skips.append("[SKIP] regla capital↔regions: requiere factions.json y regions.json (faltan o están vacíos)")
		return
	var regions := _id_map("region")
	var factions := _id_map("faction")
	for faction_id in factions.keys():
		var record: Dictionary = factions[faction_id]
		var faction: Dictionary = record["obj"]
		if not faction.has("capital"):
			continue
		var capital := _as_id(faction.get("capital", null))
		if capital == "":
			continue
		checks += 1
		if not regions.has(capital):
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".capital", "la capital '%s' no existe como región en regions.json" % capital))
	# D-010: NO se exige que la facción posea su capital ni que sea única
	# (Sacro Imperio y Bohemia comparten region_praga; owner 1337 = bohemia).


func _check_region_owners() -> void:
	if not _has_kind("region") or not _has_kind("faction"):
		skips.append("[SKIP] regla year_data.owner↔factions: requiere regions.json y factions.json")
		return
	var regions := _id_map("region")
	var factions := _id_map("faction")
	for region_id in regions.keys():
		var record: Dictionary = regions[region_id]
		var region: Dictionary = record["obj"]
		var year_data: Variant = region.get("year_data", null)
		if not (year_data is Dictionary):
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".year_data", "year_data debe ser un objeto (año → datos)"))
			continue
		for year_key in (year_data as Dictionary).keys():
			var year_entry: Variant = (year_data as Dictionary)[year_key]
			var entry_path := "%s.year_data.%s" % [str(record["path"]), str(year_key)]
			if not (year_entry is Dictionary):
				errors.append(_format_error(str(record["file"]), entry_path, "la entrada del año debe ser un objeto"))
				continue
			checks += 1
			var owner := _as_id((year_entry as Dictionary).get("owner", null))
			if owner == "":
				continue
			if not factions.has(owner):
				errors.append(_format_error(str(record["file"]), entry_path + ".owner", "owner '%s' no existe en factions.json" % owner))


func _check_adjacency_symmetry() -> void:
	if not _has_kind("region"):
		skips.append("[SKIP] regla adyacencias simétricas: requiere regions.json")
		return
	var regions := _id_map("region")
	for region_id in regions.keys():
		var record: Dictionary = regions[region_id]
		var region: Dictionary = record["obj"]
		var adjacency: Variant = region.get("adjacency", null)
		if not (adjacency is Array):
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".adjacency", "adjacency debe ser un array de ids de región"))
			continue
		for neighbour in (adjacency as Array):
			var neighbour_id := _as_id(neighbour)
			if neighbour_id == "":
				continue
			checks += 1
			var adjacency_path := str(record["path"]) + ".adjacency"
			if neighbour_id == region_id:
				errors.append(_format_error(str(record["file"]), adjacency_path, "una región no puede ser adyacente a sí misma"))
				continue
			if not regions.has(neighbour_id):
				errors.append(_format_error(str(record["file"]), adjacency_path, "adyacencia a región inexistente '%s'" % neighbour_id))
				continue
			var neighbour_obj: Dictionary = regions[neighbour_id]["obj"]
			var neighbour_adjacency: Variant = neighbour_obj.get("adjacency", null)
			if not (neighbour_adjacency is Array) or not (neighbour_adjacency as Array).has(region_id):
				errors.append(_format_error(str(record["file"]), adjacency_path, "adyacencia asimétrica: '%s' no declara '%s' en su adjacency" % [neighbour_id, region_id]))


func _check_scenario_factions() -> void:
	if not _has_kind("scenario"):
		skips.append("[SKIP] regla scenario.factions↔factions: requiere data/scenarios/*.json")
		return
	if not _has_kind("faction"):
		skips.append("[SKIP] regla scenario.factions↔factions: requiere factions.json")
		return
	var scenarios := _id_map("scenario")
	var factions := _id_map("faction")
	for scenario_id in scenarios.keys():
		var record: Dictionary = scenarios[scenario_id]
		var scenario: Dictionary = record["obj"]
		var scenario_factions: Variant = scenario.get("factions", null)
		if not (scenario_factions is Array):
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".factions", "factions debe ser un array de ids de facción"))
			continue
		for faction_ref in (scenario_factions as Array):
			var faction_id := _as_id(faction_ref)
			if faction_id == "":
				continue
			checks += 1
			if not factions.has(faction_id):
				errors.append(_format_error(str(record["file"]), str(record["path"]) + ".factions", "la facción '%s' no existe en factions.json" % faction_id))


func _check_character_references() -> void:
	if _has_kind("character"):
		var characters := _id_map("character")
		for character_id in characters.keys():
			var record: Dictionary = characters[character_id]
			var character: Dictionary = record["obj"]
			var family: Variant = character.get("family", null)
			if family is Dictionary:
				for relation in ["father", "mother", "spouse"]:
					var reference := _as_id((family as Dictionary).get(relation, null))
					if reference == "":
						continue
					checks += 1
					if not characters.has(reference):
						errors.append(_format_error(str(record["file"]), "%s.family.%s" % [str(record["path"]), relation], "personaje referenciado '%s' no existe en characters.json" % reference))
				var children: Variant = (family as Dictionary).get("children", null)
				if children is Array:
					for child in (children as Array):
						var child_id := _as_id(child)
						if child_id == "":
							continue
						checks += 1
						if not characters.has(child_id):
							errors.append(_format_error(str(record["file"]), str(record["path"]) + ".family.children", "hijo referenciado '%s' no existe en characters.json" % child_id))
			var claims: Variant = character.get("claims", null)
			if claims is Array and _has_kind("faction"):
				var factions := _id_map("faction")
				for claim in (claims as Array):
					if not (claim is Dictionary):
						continue
					var target := _as_id((claim as Dictionary).get("target", null))
					if target == "":
						continue
					checks += 1
					if not factions.has(target):
						errors.append(_format_error(str(record["file"]), str(record["path"]) + ".claims", "claims.target '%s' no existe en factions.json" % target))
	else:
		skips.append("[SKIP] reglas de personajes referenciados: requiere characters.json")

	# Referencias de archivo/personajes declaradas por los escenarios.
	if _has_kind("scenario"):
		var characters_map := _id_map("character")
		var scenarios := _id_map("scenario")
		for scenario_id in scenarios.keys():
			var record: Dictionary = scenarios[scenario_id]
			var scenario: Dictionary = record["obj"]
			var initial_state: Variant = scenario.get("initial_state", null)
			if initial_state is Dictionary:
				var characters_ref: Variant = (initial_state as Dictionary).get("characters", null)
				var ref_path := str(record["path"]) + ".initial_state.characters"
				if characters_ref is Array:
					for character_ref in (characters_ref as Array):
						var character_id := _as_id(character_ref)
						if character_id == "":
							continue
						checks += 1
						if not characters_map.has(character_id):
							errors.append(_format_error(str(record["file"]), ref_path, "personaje referenciado '%s' no existe en characters.json" % character_id))
				elif characters_ref is String and str(characters_ref) != "":
					_check_data_file_reference(str(record["file"]), ref_path, str(characters_ref))
			var events_script := _as_id(scenario.get("events_script", null))
			if events_script != "":
				_check_data_file_reference(str(record["file"]), str(record["path"]) + ".events_script", events_script)


func _check_data_file_reference(origin_file: String, field_path: String, reference: String) -> void:
	checks += 1
	var candidates: Array[String] = [
		_data_root.path_join(reference),
		_data_root.path_join("scenarios").path_join(reference),
	]
	for candidate in candidates:
		if FileAccess.file_exists(candidate):
			return
	errors.append(_format_error(origin_file, field_path, "el fichero referenciado '%s' no existe en data/" % reference))


func _check_regions_owned_per_scenario() -> void:
	if not _has_kind("scenario") or not _has_kind("region"):
		skips.append("[SKIP] regla 'toda región con dueño en el año del escenario': requiere scenarios/*.json y regions.json")
		return
	var scenarios := _id_map("scenario")
	var regions := _id_map("region")
	for scenario_id in scenarios.keys():
		var record: Dictionary = scenarios[scenario_id]
		var scenario: Dictionary = record["obj"]
		var start_year := int(scenario.get("start_year", 0))
		if start_year <= 0:
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".start_year", "start_year ausente o inválido"))
			continue
		var scenario_factions: Dictionary = {}
		var scenario_factions_ref: Variant = scenario.get("factions", null)
		if scenario_factions_ref is Array:
			for faction_ref in (scenario_factions_ref as Array):
				scenario_factions[_as_id(faction_ref)] = true
		var year_key := str(start_year)
		for region_id in regions.keys():
			var region_record: Dictionary = regions[region_id]
			var region: Dictionary = region_record["obj"]
			var year_data: Variant = region.get("year_data", null)
			if not (year_data is Dictionary):
				continue
			checks += 1
			var regions_data: Dictionary = year_data
			if not regions_data.has(year_key):
				errors.append(_format_error(str(region_record["file"]), str(region_record["path"]) + ".year_data", "falta el año %s (start_year del escenario '%s')" % [year_key, scenario_id]))
				continue
			var year_entry: Variant = regions_data[year_key]
			if not (year_entry is Dictionary):
				continue
			var owner := _as_id((year_entry as Dictionary).get("owner", null))
			if owner == "":
				errors.append(_format_error(str(region_record["file"]), "%s.year_data.%s.owner" % [str(region_record["path"]), year_key], "la región no tiene dueño en el año %s" % year_key))
			elif not scenario_factions.is_empty() and not scenario_factions.has(owner):
				warnings.append("[WARN] %s :: %s.year_data.%s.owner :: owner '%s' no está en scenario.factions (¿facción menor intencional?)" % [str(region_record["file"]), str(region_record["path"]), year_key, owner])


func _check_playable_1337() -> void:
	if not _has_kind("scenario") or not _has_kind("faction"):
		skips.append("[SKIP] regla 'exactamente 8 playable en 1337': requiere scenarios/*.json y factions.json")
		return
	var scenarios := _id_map("scenario")
	var factions := _id_map("faction")
	for scenario_id in scenarios.keys():
		var record: Dictionary = scenarios[scenario_id]
		var scenario: Dictionary = record["obj"]
		var start_year := int(scenario.get("start_year", 0))
		if start_year != 1337 and not str(scenario_id).contains("1337"):
			continue
		var scenario_factions_ref: Variant = scenario.get("factions", null)
		var pool: Array = []
		if scenario_factions_ref is Array and not (scenario_factions_ref as Array).is_empty():
			pool = scenario_factions_ref
		else:
			pool = factions.keys()
		var playable_count := 0
		for faction_ref in pool:
			var faction_id := _as_id(faction_ref)
			if not factions.has(faction_id):
				continue
			var faction_obj: Dictionary = factions[faction_id]["obj"]
			if bool(faction_obj.get("playable", false)):
				playable_count += 1
		checks += 1
		if playable_count != 8:
			errors.append(_format_error(str(record["file"]), str(record["path"]) + ".factions", "hay %d facciones playable=true en 1337 (se esperaban exactamente 8)" % playable_count))


# ---------------------------------------------------------------------------
# Regla cruzada: tiles de batalla N3 (Fase 3 §10.4 / D-053)
# ---------------------------------------------------------------------------

## Valida `data/battle_tiles.json`: 12 claves exactas, balance D-053,
## pasabilidad/flags coherentes y rutas `res://assets/art/battle/tiles/tile_<clave>.png`.
func _check_battle_tiles() -> void:
	var dataset_path: String = ""
	for path in dataset_paths:
		if _kind_of(path) == "battle_tiles":
			dataset_path = path
			break
	if dataset_path == "":
		skips.append("[SKIP] regla battle_tiles §10.4: requiere data/battle_tiles.json")
		return
	var root: Variant = _datasets[dataset_path]["data"]
	var file := _rel(dataset_path)
	if not (root is Dictionary):
		errors.append(_format_error(file, "$", "el dataset debe ser un objeto envelope D-009"))
		return
	var envelope: Dictionary = root
	checks += 1
	var schema_version: Variant = envelope.get("schema_version", null)
	if not (schema_version is int or schema_version is float) or int(schema_version) != 1:
		errors.append(_format_error(file, "$.schema_version", "schema_version debe ser 1"))
	var tiles_value: Variant = envelope.get("battle_tiles", null)
	if not (tiles_value is Dictionary):
		errors.append(_format_error(file, "$.battle_tiles", "battle_tiles debe ser un objeto (clave → tile)"))
		return
	var tiles: Dictionary = tiles_value
	for key in BATTLE_TILES_KEYS:
		checks += 1
		if not tiles.has(key):
			errors.append(_format_error(file, "$.battle_tiles", "falta la clave '%s' (deben ser 12 exactas)" % key))
	for key in tiles.keys():
		if not BATTLE_TILES_KEYS.has(str(key)):
			errors.append(_format_error(file, "$.battle_tiles", "clave no permitida '%s' (las 12 del contrato §B)" % str(key)))
	var routes_seen: Dictionary = {}
	for key in BATTLE_TILES_KEYS:
		if not tiles.has(key):
			continue
		var base := "$.battle_tiles.%s" % key
		var entry_value: Variant = tiles.get(key)
		if not (entry_value is Dictionary):
			errors.append(_format_error(file, base, "el tile debe ser un objeto"))
			continue
		var entry: Dictionary = entry_value
		var expected: Dictionary = BATTLE_TILES_EXPECTED[key]
		var missing_field: bool = false
		for field in ["tile", "move_cost", "defense", "passable"]:
			if not entry.has(field):
				errors.append(_format_error(file, base, "falta el campo '%s'" % field))
				missing_field = true
		if missing_field:
			continue
		# Ruta del tile.
		checks += 1
		var route := _as_id(entry.get("tile", null))
		var expected_route := "%s%s.png" % [BATTLE_TILES_ROUTE_PREFIX, key]
		if route != expected_route:
			errors.append(_format_error(file, base + ".tile", "ruta '%s' (esperada '%s')" % [route, expected_route]))
		if routes_seen.has(route):
			errors.append(_format_error(file, base + ".tile", "ruta duplicada (ya usada por '%s')" % str(routes_seen[route])))
		routes_seen[route] = key
		# move_cost: null si es intransitable, número > 0 si es transitable.
		checks += 1
		var move_cost: Variant = entry.get("move_cost", null)
		var expected_cost: Variant = expected.get("move_cost", null)
		if expected_cost == null:
			if move_cost != null:
				errors.append(_format_error(file, base + ".move_cost", "debe ser null (tile intransitable)"))
		elif not (move_cost is int or move_cost is float) or not is_equal_approx(float(move_cost), float(expected_cost)):
			errors.append(_format_error(file, base + ".move_cost", "valor %s (esperado %s según D-053)" % [str(move_cost), str(expected_cost)]))
		# defense entero.
		checks += 1
		var defense_value: Variant = entry.get("defense", null)
		if not (defense_value is int or (defense_value is float and float(defense_value) == floorf(float(defense_value)))):
			errors.append(_format_error(file, base + ".defense", "debe ser un entero"))
		elif int(defense_value) != int(expected.get("defense", 0)):
			errors.append(_format_error(file, base + ".defense", "valor %d (esperado %d)" % [int(defense_value), int(expected.get("defense", 0))]))
		# passable bool.
		checks += 1
		var passable_value: Variant = entry.get("passable", null)
		var passable_ok: bool = passable_value is bool
		if not passable_ok:
			errors.append(_format_error(file, base + ".passable", "debe ser booleano"))
		elif bool(passable_value) != bool(expected.get("passable", false)):
			errors.append(_format_error(file, base + ".passable", "valor %s (esperado %s)" % [str(passable_value), str(expected.get("passable", false))]))
		# Flags coherentes (sólo en transitable y con el valor del contrato).
		for flag in ["cavalry_penalty", "move_bonus"]:
			checks += 1
			var expected_flag: bool = bool(expected.get(flag, false))
			var actual_flag: bool = false
			if entry.has(flag):
				var flag_value: Variant = entry.get(flag)
				if not (flag_value is bool):
					errors.append(_format_error(file, "%s.%s" % [base, flag], "debe ser booleano"))
				else:
					actual_flag = bool(flag_value)
			if actual_flag != expected_flag:
				errors.append(_format_error(file, "%s.%s" % [base, flag], "flag %s (esperado %s según D-053)" % [str(actual_flag), str(expected_flag)]))
			if actual_flag and passable_ok and not bool(passable_value):
				errors.append(_format_error(file, "%s.%s" % [base, flag], "flag incoherente en tile intransitable"))
	infos.append("[INFO] battle_tiles: 12 tiles validados (claves, balance D-053, pasabilidad, flags y rutas §10.4)")


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _format_error(file: String, path: String, message: String) -> String:
	return "[FAIL] %s :: %s :: %s" % [file, path, message]


## Devuelve el id como String tratando null como "". Ojo: str(null) == "<null>",
## por eso no se puede usar str() directamente en campos opcionales.
func _as_id(value: Variant) -> String:
	if value == null:
		return ""
	if value is String:
		return value
	return str(value)


func _rel(path: String) -> String:
	if path.begins_with("res://"):
		return path.substr("res://".length())
	return path
