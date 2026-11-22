class_name RegionState
extends RefCounted
## Dataclass mínima de región (estado de una provincia en la partida; GDD §7.2, §8.1).
##
## Fase 0: solo estructura tipada y serialización (sin lógica de juego).
## Los datos históricos por año (year_data) viven en data/regions*.json; aquí
## solo el estado mutable de la partida (dueño, asignación, edificios).

var id: String = ""
var name: String = ""
var terrain: String = ""  # plains | forest | mountain | coast | city
var has_city: bool = false
var adjacency: Array[String] = []
## Dueño actual en la partida ("" = independiente/sin dueño).
var owner_faction: String = ""
var population: int = 0
var base_wealth: int = 0
var buildings: Array[String] = []
## Apoyo popular 0-100 (GDD §5.2; 50 = neutro).
var support: int = 50
## Asignación de mano de obra: clase → cantidad (GDD §5.2).
var assigned_workers: Dictionary = {}
## Datos históricos por año, tal cual vienen del dataset: {"1337": {...}}.
var year_data: Dictionary = {}


func set_owner(faction_id: String) -> void:
	owner_faction = faction_id


## Entrada histórica de un año concreto ({} si no existe).
func get_year_entry(year: int) -> Dictionary:
	var entry: Dictionary = year_data.get(str(year), {})
	return entry


## Dueño histórico según el dataset para un año ("" si no consta).
func get_owner_for_year(year: int) -> String:
	var entry: Dictionary = get_year_entry(year)
	return str(entry.get("owner", ""))


func is_adjacent_to(region_id: String) -> bool:
	return adjacency.has(region_id)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"terrain": terrain,
		"has_city": has_city,
		"adjacency": adjacency.duplicate(),
		"owner": owner_faction,
		"population": population,
		"base_wealth": base_wealth,
		"buildings": buildings.duplicate(),
		"support": support,
		"assigned_workers": assigned_workers.duplicate(true),
		"year_data": year_data.duplicate(true),
	}


func apply_dict(data: Dictionary) -> void:
	id = str(data.get("id", id))
	name = str(data.get("name", name))
	terrain = str(data.get("terrain", terrain))
	has_city = bool(data.get("has_city", has_city))
	var raw_adjacency: Variant = data.get("adjacency", null)
	if raw_adjacency is Array:
		adjacency.clear()
		for item: Variant in (raw_adjacency as Array):
			adjacency.append(str(item))
	owner_faction = str(data.get("owner", owner_faction))
	population = int(data.get("population", population))
	base_wealth = int(data.get("base_wealth", base_wealth))
	var raw_buildings: Variant = data.get("buildings", null)
	if raw_buildings is Array:
		buildings.clear()
		for item: Variant in (raw_buildings as Array):
			buildings.append(str(item))
	support = int(data.get("support", support))
	var raw_workers: Variant = data.get("assigned_workers", null)
	if raw_workers is Dictionary:
		assigned_workers = (raw_workers as Dictionary).duplicate(true)
	var raw_years: Variant = data.get("year_data", null)
	if raw_years is Dictionary:
		year_data = (raw_years as Dictionary).duplicate(true)
