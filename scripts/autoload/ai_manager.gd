extends Node
## AIManager — orquesta las facciones IA (GDD §5.6, §8.1).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: un AIBrain por facción con perfil (agresor/comerciante/dinástico/
## superviviente/equilibrado), decisión trimestral por utilidad esperada.

signal ai_turn_started(faction_id: String)
signal ai_turn_finished(faction_id: String, elapsed_ms: int)
signal all_ai_finished()

## Presupuesto de rendimiento: 14 facciones en <2 s (GDD §5.6, §13).
const TIME_BUDGET_MS: int = 2000
const PROFILES: Array[String] = ["aggressive", "merchant", "dynastic", "survivor", "balanced"]


## Ejecuta el turno de una facción IA (2-4 órdenes; GDD §5.6).
func take_turn(_faction_id: String) -> void:
	pass


## Ejecuta los turnos de todas las facciones IA indicadas (tras el jugador).
func run_ai_turns(_faction_ids: Array[String]) -> void:
	pass


## Ejecuta todos los rivales de la partida (Fase 1).
func run_all_ai() -> void:
	pass


func get_profile(_faction_id: String) -> String:
	return "balanced"


func set_profile(_faction_id: String, _profile: String) -> void:
	pass
