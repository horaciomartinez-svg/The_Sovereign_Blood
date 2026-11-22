class_name BattleTiles
extends RefCounted
## Tabla de tiles del campo de batalla N3 (GDD v1.7 §10.4, contrato tiles §B,
## D-053). API pura y consultable que usan `TacticalBattle` (N2) y `CloseCombat`
## (N3); no instancia nodos de UI ni consume RNG.
##
## La instancia se construye con la tabla de `data/battle_tiles.json` (vía
## `DataLoader.get_battle_tiles()`); si la tabla está vacía o falta una clave,
## los helpers devuelven valores de "sin tiles" para que la batalla use su
## comportamiento legado (determinismo intacto cuando no hay tiles).

const SafeDict = preload("res://scripts/utils/safe_dict.gd")

## Terreno táctico de N2 → clave de tile de §10.4.
const TERRAIN_TO_TILE: Dictionary = {
	"plains": "pastizal",
	"forest": "bosque",
	"hills": "colina",
	"river": "rio",
	"city": "villa",
	"mountain": "montana",
}

## Tipos de unidad considerados caballería para `cavalry_penalty` (§6.4).
const CAVALRY_TYPES: Array[String] = ["cavalry", "light_cavalry"]

var tiles: Dictionary = {}


func _init(tiles_data: Dictionary = {}) -> void:
	tiles = tiles_data.duplicate(true)


## Devuelve la clave de tile de un terreno táctico ("plains" → "pastizal").
static func tile_key_for_terrain(terrain: String) -> String:
	var key: Variant = TERRAIN_TO_TILE.get(terrain, null)
	if key is String:
		return key
	return ""


static func is_cavalry(unit_type: String) -> bool:
	return CAVALRY_TYPES.has(unit_type)


func is_empty() -> bool:
	return tiles.is_empty()


func keys() -> Array[String]:
	var result: Array[String] = []
	for key in tiles.keys():
		result.append(str(key))
	result.sort()
	return result


func has_tile(key: String) -> bool:
	return tiles.has(key)


## Entrada completa de un tile ({} si no existe).
func get_tile(key: String) -> Dictionary:
	var entry: Variant = tiles.get(key, null)
	if entry is Dictionary:
		return (entry as Dictionary).duplicate(true)
	return {}


func is_passable(key: String) -> bool:
	if not tiles.has(key):
		return true  # sin dato → comportamiento legado (transitable)
	var entry: Dictionary = get_tile(key)
	return bool(entry.get("passable", true))


func get_defense(key: String) -> int:
	if not tiles.has(key):
		return 0
	var entry: Dictionary = get_tile(key)
	return SafeDict.as_int(entry.get("defense"), 0)


## Multiplicador de defensa para N3: 1.0 + 0.2·defense (colina/bosque/villa).
func get_defense_multiplier(key: String) -> float:
	return 1.0 + 0.2 * float(get_defense(key))


func has_cavalry_penalty(key: String) -> bool:
	if not tiles.has(key):
		return false
	return SafeDict.as_bool(get_tile(key).get("cavalry_penalty"), false)


func has_move_bonus(key: String) -> bool:
	if not tiles.has(key):
		return false
	return SafeDict.as_bool(get_tile(key).get("move_bonus"), false)


## Coste de movimiento del tile para un tipo de unidad.
## -1.0 si es intransitable o no hay datos (la batalla decide el fallback).
func get_move_cost(key: String, unit_type: String = "infantry") -> float:
	if not tiles.has(key):
		return -1.0
	var entry: Dictionary = get_tile(key)
	if not bool(entry.get("passable", true)):
		return -1.0
	var base_cost: float = SafeDict.as_float(entry.get("move_cost"), -1.0)
	if base_cost < 0.0:
		return -1.0
	# Bonus de camino/villa_calle: reduce el coste (mitad, mínimo 0.5).
	if SafeDict.as_bool(entry.get("move_bonus"), false):
		base_cost = maxf(0.5, base_cost * 0.5)
	# Penalización de caballería en bosque (§6.4): movimiento ×1.5.
	if SafeDict.as_bool(entry.get("cavalry_penalty"), false) and is_cavalry(unit_type):
		base_cost *= 1.5
	return base_cost
