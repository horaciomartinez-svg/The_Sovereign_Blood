extends Node
## TurnManager — orquestador del turno; la UI solo habla con él (GDD §8.2, §5.1).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: secuencia gobernanza → economía → familia → diplomacia → militar →
## IA rivales → avance de año; gestiona los Puntos de Gobernanza (PG).

# Contrato literal GDD §8.2.
signal turn_started(quarter: int, year: int)
signal pg_changed(remaining: int)
signal turn_ended(quarter: int, year: int)
signal phase_changed(phase: String)
signal year_advanced(year: int)

## 4 trimestres por año; 1 turno = 1 trimestre (GDD §5.1).
const QUARTERS_PER_YEAR: int = 4
## PG base por trimestre (GDD §5.1: 30 + prestigio/10 + bonus − penalización).
const PG_BASE: int = 30

var current_quarter: int = 1
var current_year: int = 1337
var current_faction_id: String = ""
var remaining_pg: int = 0
## Fase del turno: "idle" | "governance" | "economy" | "family" | "diplomacy" | "military" | "ai" | "year_end".
var phase: String = "idle"


## Inicia el turno de la facción indicada (emite turn_started + pg_changed).
func begin_turn(_faction_id: String) -> void:
	pass


## Cierra el turno: IA de rivales y, si toca, fin de año (GDD §8.2).
func end_turn() -> void:
	pass


## Gasta PG si hay suficientes; false si no alcanza (valida PG, GDD §5.1).
func spend_pg(_amount: int) -> bool:
	return false


func can_spend_pg(_amount: int) -> bool:
	return false


## PG del trimestre según fórmula de GDD §5.1 (0 en Fase 0).
func calculate_pg(_faction_id: String) -> int:
	return 0


## Avanza un trimestre y, si procede, dispara year_advanced.
func advance_quarter() -> void:
	pass


func advance_year() -> void:
	pass
