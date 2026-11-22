extends Node
## DataLoader — puente JSON (res://data) → estructuras tipadas (GDD §7, §8.1).
##
## Fase 0: contrato declarado, sin carga real (autoload vacío, GDD §12).
## Fase 1: parseará data/*.json, validará contra data/schema/*.json y expondrá
## diccionarios indexados por id (nunca datos hardcodeados en GDScript, §7).

## Emitida cuando un bloque de datos termina de cargarse.
signal data_loaded(kind: String, count: int)
## Emitida si un archivo no se puede leer o no parsea como JSON.
signal data_load_failed(path: String, message: String)

const DATA_DIR: String = "res://data"
const SCHEMA_DIR: String = "res://data/schema"

# Índices id → diccionario crudo (serializable, GDD §8.3).
var factions: Dictionary = {}
var regions: Dictionary = {}
var characters: Dictionary = {}
var units: Dictionary = {}
var scenarios: Dictionary = {}
var events: Dictionary = {}
var is_loaded: bool = false


## Carga todos los datasets de res://data/. Devuelve true si no hubo errores.
func load_all() -> bool:
	return false


## Carga un JSON y devuelve su raíz ({} si falla). No muta los índices.
func load_json(path: String) -> Dictionary:
	return {}


## Carga un JSON y lo indexa por id en el índice de la clase indicada.
func load_dataset(path: String, kind: String) -> bool:
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


## Eventos cuyo campo "year" coincide con el año dado (vacío en Fase 0).
func get_events_for_year(year: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return result


func has_faction(id: String) -> bool:
	return factions.has(id)


func has_region(id: String) -> bool:
	return regions.has(id)


## Vacía todos los índices (para tests y nueva partida).
func reset() -> void:
	pass
