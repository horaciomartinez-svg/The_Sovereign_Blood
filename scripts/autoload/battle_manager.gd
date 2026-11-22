extends Node
## BattleManager — fachada única para los 3 niveles de batalla (GDD §6, §8.2).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: resolución delegada (Nivel 1) y su informe. Niveles 2 y 3 son Fase 2.

signal battle_started(attacker_faction: String, defender_faction: String, region_id: String)
signal battle_resolved(report: Dictionary)

const STANCE_DEFENSIVE: int = 0
const STANCE_BALANCED: int = 1
const STANCE_OFFENSIVE: int = 2

## Hasta 5 asaltos por batalla (GDD §6.1).
const MAX_ASSAULTS: int = 5
## Un ejército con <25% de efectivos o moral rota se retira (GDD §6.1).
const RETREAT_THRESHOLD: float = 0.25

const ARMY_SCRIPT = preload("res://scripts/model/army.gd")
const REGION_SCRIPT = preload("res://scripts/model/region_state.gd")
const REPORT_SCRIPT = preload("res://scripts/model/battle_report.gd")


## Nivel 1 — combate delegado. Devuelve un BattleReport (diccionario serializable)
## con bajas, rondas y región conquistada si cae la capital regional (GDD §6.1).
func resolve_delegated(
		_attacker_army: ARMY_SCRIPT,
		_defender_army: ARMY_SCRIPT,
		_region: REGION_SCRIPT,
		_stance: int) -> REPORT_SCRIPT:
	return null


## Nivel 2 — mapa táctico de ejércitos (Fase 2; devuelve null en Fase 0).
func launch_tactical(
		_attacker_army: ARMY_SCRIPT,
		_defender_army: ARMY_SCRIPT,
		_region: REGION_SCRIPT) -> Node:
	return null


## Poder de un ejército según GDD §6.1 (0.0 en Fase 0).
func estimate_power(_army: ARMY_SCRIPT, _region: REGION_SCRIPT, _is_attacker: bool) -> float:
	return 0.0
