class_name Character
extends RefCounted
## Dataclass mínima de personaje (GDD §7.1, §8.1).
##
## Fase 0: solo estructura tipada y serialización (sin lógica de juego).
## Fase 1: la rellena DynastySystem/DataLoader desde data/characters*.json.

var id: String = ""
var name: String = ""
var house: String = ""
var faction: String = ""
var born: int = 0
## Año de muerte; null si sigue vivo. JSON: `"died": null`.
var died: Variant = null
var role: String = ""  # ruler | heir | general | advisor | ...
var stats: Dictionary = {}  # command, intrigue, charisma, loyalty, education
var traits: Array[String] = []
var family: Dictionary = {}  # father, mother, spouse, children
var claims: Array[Dictionary] = []  # {target: faction_id, strength: float}


## true si está vivo en el año indicado (sin año → true si died == null).
func is_alive_at(year: int = 0) -> bool:
	if died == null:
		return true
	var death_year: int = int(died)
	if year <= 0:
		return false
	return year < death_year


func get_stat(stat_name: String, default_value: int = 0) -> int:
	var value: int = stats.get(stat_name, default_value)
	return value


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"house": house,
		"faction": faction,
		"born": born,
		"died": died,
		"role": role,
		"stats": stats.duplicate(true),
		"traits": traits.duplicate(),
		"family": family.duplicate(true),
		"claims": claims.duplicate(true),
	}


func apply_dict(data: Dictionary) -> void:
	id = str(data.get("id", id))
	name = str(data.get("name", name))
	house = str(data.get("house", house))
	faction = str(data.get("faction", faction))
	born = int(data.get("born", born))
	died = data.get("died", died)
	role = str(data.get("role", role))
	var raw_stats: Variant = data.get("stats", null)
	if raw_stats is Dictionary:
		stats = (raw_stats as Dictionary).duplicate(true)
	var raw_traits: Variant = data.get("traits", null)
	if raw_traits is Array:
		traits.clear()
		for item: Variant in (raw_traits as Array):
			traits.append(str(item))
	var raw_family: Variant = data.get("family", null)
	if raw_family is Dictionary:
		family = (raw_family as Dictionary).duplicate(true)
	var raw_claims: Variant = data.get("claims", null)
	if raw_claims is Array:
		claims.clear()
		for item: Variant in (raw_claims as Array):
			if item is Dictionary:
				claims.append((item as Dictionary).duplicate(true))
