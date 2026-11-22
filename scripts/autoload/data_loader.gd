extends Node
## DataLoader — carga `res://data/*.json` y expone índices id → diccionario.
##
## Contrato de datos D-009: `{schema_version, factions|characters|regions|units|events}`;
## `data/scenarios/*.json` son objetos únicos. Los datos son DEFINICIONES estáticas:
## ningún sistema las muta (el estado vivo vive en `GameState.state`).

signal data_loaded(kind: String, count: int)
signal data_load_failed(path: String, message: String)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const DATA_DIR: String = "res://data"
const SCHEMA_DIR: String = "res://data/schema"
const SCENARIO_DIR: String = "res://data/scenarios"
const FACTION_FILE: String = "res://data/factions.json"
const REGION_FILE: String = "res://data/regions.json"
const CHARACTER_FILE: String = "res://data/characters.json"
const UNIT_FILE: String = "res://data/units.json"

# Índices id → diccionario crudo (serializable, GDD §8.3).
var factions: Dictionary = {}
var regions: Dictionary = {}
var characters: Dictionary = {}
var units: Dictionary = {}
var scenarios: Dictionary = {}
var events: Dictionary = {}
var is_loaded: bool = false
var last_errors: Array[String] = []


## Carga todos los datasets del Escenario 1. Devuelve true si no hubo errores.
func load_all() -> bool:
	reset()
	var ok := true
	if not _load_entities(FACTION_FILE, "factions", factions):
		ok = false
	if not _load_entities(REGION_FILE, "regions", regions):
		ok = false
	if not _load_entities(CHARACTER_FILE, "characters", characters):
		ok = false
	if not _load_entities(UNIT_FILE, "units", units):
		ok = false
	if not _load_scenarios():
		ok = false
	if not _load_events():
		ok = false
	is_loaded = ok and not factions.is_empty() and not regions.is_empty()
	return is_loaded


## Lee un JSON y devuelve su raíz; {} si no existe o no parsea.
func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_errors.append("%s: no se puede abrir (error %d)" % [path, FileAccess.get_open_error()])
		emit_signal("data_load_failed", path, "no se puede abrir")
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		var message := "JSON inválido (línea %d): %s" % [json.get_error_line(), json.get_error_message()]
		last_errors.append("%s: %s" % [path, message])
		emit_signal("data_load_failed", path, message)
		return {}
	var root: Variant = json.data
	if not (root is Dictionary):
		last_errors.append("%s: la raíz debe ser un objeto JSON" % path)
		emit_signal("data_load_failed", path, "raíz no es objeto")
		return {}
	return root


## Carga un dataset concreto e índice sus entidades por id.
## `kind`: factions | regions | characters | units | events | scenarios.
func load_dataset(path: String, kind: String) -> bool:
	match kind:
		"factions":
			return _load_entities(path, "factions", factions)
		"regions":
			return _load_entities(path, "regions", regions)
		"characters":
			return _load_entities(path, "characters", characters)
		"units":
			return _load_entities(path, "units", units)
		"events":
			return _load_events_file(path)
		"scenarios", "scenario":
			return _load_scenario_file(path)
		_:
			last_errors.append("%s: tipo de dataset desconocido '%s'" % [path, kind])
			return false


func get_faction(id: String) -> Dictionary:
	var entry: Dictionary = factions.get(id, {})
	return entry


func get_region(id: String) -> Dictionary:
	var entry: Dictionary = regions.get(id, {})
	return entry


func get_character(id: String) -> Dictionary:
	var entry: Dictionary = characters.get(id, {})
	return entry


func get_unit(id: String) -> Dictionary:
	var entry: Dictionary = units.get(id, {})
	return entry


func get_scenario(id: String) -> Dictionary:
	var entry: Dictionary = scenarios.get(id, {})
	return entry


func get_event(id: String) -> Dictionary:
	var entry: Dictionary = events.get(id, {})
	return entry


func has_faction(id: String) -> bool:
	return factions.has(id)


func has_region(id: String) -> bool:
	return regions.has(id)


func has_unit(id: String) -> bool:
	return units.has(id)


func has_scenario(id: String) -> bool:
	return scenarios.has(id)


## Ids ordenados (determinismo en la simulación y los tests).
func get_faction_ids() -> Array[String]:
	return SafeDict.sorted_keys(factions)


func get_region_ids() -> Array[String]:
	return SafeDict.sorted_keys(regions)


func get_character_ids() -> Array[String]:
	return SafeDict.sorted_keys(characters)


func get_unit_ids() -> Array[String]:
	return SafeDict.sorted_keys(units)


func get_scenario_ids() -> Array[String]:
	return SafeDict.sorted_keys(scenarios)


## Eventos cuyo campo `year` coincide con el año dado (ordenados por id).
func get_events_for_year(year: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array[String] = SafeDict.sorted_keys(events)
	for event_id in ids:
		var event: Dictionary = SafeDict.as_dict(events[event_id])
		if SafeDict.as_int(event.get("year"), -1) == year:
			result.append(event)
	return result


## Todos los eventos indexados, ordenados por id (para UI/debug).
func get_all_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array[String] = SafeDict.sorted_keys(events)
	for event_id in ids:
		result.append(SafeDict.as_dict(events[event_id]))
	return result


## Vacía todos los índices (nueva partida / tests).
func reset() -> void:
	factions = {}
	regions = {}
	characters = {}
	units = {}
	scenarios = {}
	events = {}
	is_loaded = false
	last_errors = []


# ---------------------------------------------------------------------------
# Carga interna
# ---------------------------------------------------------------------------

func _load_entities(path: String, envelope_key: String, target: Dictionary) -> bool:
	var root: Dictionary = load_json(path)
	if root.is_empty():
		return false
	var items: Array = SafeDict.as_array(root.get(envelope_key, null))
	var indexed: int = 0
	for item_value in items:
		var item: Dictionary = SafeDict.as_dict(item_value)
		var entity_id: String = SafeDict.as_string(item.get("id"), "")
		if entity_id == "":
			continue
		target[entity_id] = item
		indexed += 1
	if indexed == 0:
		var message := "sin entidades '%s'" % envelope_key
		last_errors.append("%s: %s" % [path, message])
		emit_signal("data_load_failed", path, message)
		return false
	emit_signal("data_loaded", envelope_key, indexed)
	return true


func _load_scenarios() -> bool:
	var dir := DirAccess.open(SCENARIO_DIR)
	if dir == null:
		last_errors.append("%s: no se puede abrir" % SCENARIO_DIR)
		emit_signal("data_load_failed", SCENARIO_DIR, "directorio inaccesible")
		return false
	var loaded: int = 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
			if _load_scenario_file(SCENARIO_DIR.path_join(file_name)):
				loaded += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return loaded > 0


func _load_scenario_file(path: String) -> bool:
	var root: Dictionary = load_json(path)
	if root.is_empty():
		return false
	var scenario_id: String = SafeDict.as_string(root.get("id"), "")
	if scenario_id == "":
		last_errors.append("%s: escenario sin 'id'" % path)
		emit_signal("data_load_failed", path, "escenario sin id")
		return false
	scenarios[scenario_id] = root
	emit_signal("data_loaded", "scenarios", scenarios.size())
	return true


func _load_events() -> bool:
	var dir := DirAccess.open(DATA_DIR)
	if dir == null:
		return false
	var loaded: int = 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() \
				and file_name.begins_with("events_") \
				and file_name.get_extension().to_lower() == "json":
			if _load_events_file(DATA_DIR.path_join(file_name)):
				loaded += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	return loaded > 0


func _load_events_file(path: String) -> bool:
	var root: Dictionary = load_json(path)
	if root.is_empty():
		return false
	var items: Array = SafeDict.as_array(root.get("events", null))
	var indexed: int = 0
	for item_value in items:
		var event: Dictionary = SafeDict.as_dict(item_value)
		var event_id: String = SafeDict.as_string(event.get("id"), "")
		if event_id == "":
			continue
		events[event_id] = event
		indexed += 1
	if indexed == 0:
		last_errors.append("%s: sin eventos" % path)
		emit_signal("data_load_failed", path, "sin eventos")
		return false
	emit_signal("data_loaded", "events", indexed)
	return true
