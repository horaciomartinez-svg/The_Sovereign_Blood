extends Node
## GameState — estado global de la partida y guardado/carga (GDD §7.7, §8.4).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: mantendrá el snapshot serializable completo (turno, año, facciones,
## regiones, ejércitos, event_log) y la E/S de user://saves/*.json.

signal game_initialized(scenario_id: String, faction_id: String)
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal game_over(faction_id: String, victory: bool, reason: String)

## Versión del formato de guardado (GDD §8.4); migraciones al subirla.
const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves"

# Reloj y facción activa (espejo de TurnManager, legible por la UI).
var turn: int = 0
var year: int = 0
var quarter: int = 0
var current_faction_id: String = ""
var scenario_id: String = ""
var rng_seed: int = 1337
var is_running: bool = false

## Snapshot puro y serializable de toda la partida (GDD §8.3).
var state: Dictionary = {}


## Arranca una partida nueva para escenario/facción/semilla dados.
func new_game(_scenario_id: String, _faction_id: String, _seed_value: int = 1337) -> void:
	pass


## Devuelve el estado a "sin partida".
func reset() -> void:
	pass


## Snapshot serializable listo para JSON (GDD §8.3).
func to_dict() -> Dictionary:
	return {}


## Restaura el estado desde un snapshot (true si la estructura es válida).
func from_dict(data: Dictionary) -> bool:
	return false


## Guarda en user://saves/<slot>.json.
func save_game(slot: String = "autosave") -> bool:
	return false


## Carga user://saves/<slot>.json.
func load_game(slot: String = "autosave") -> bool:
	return false


func has_save(slot: String) -> bool:
	return false
