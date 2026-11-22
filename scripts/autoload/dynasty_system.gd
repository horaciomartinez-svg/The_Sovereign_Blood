extends Node
## DynastySystem — nacimientos, muertes, matrimonios y sucesión (GDD §5.3, §8.2).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: eventos vitales trimestrales, árbol familiar, regencia, crisis
## sucesoria y extinción dinástica. Todo con RNG sembrado (GDD §8.3).

signal character_born(character_id: String, faction_id: String)
signal character_died(character_id: String, cause: String)
signal marriage_formed(character_id: String, spouse_id: String)
signal succession_resolved(faction_id: String, heir_id: String)
signal regency_started(faction_id: String, regent_id: String)
signal dynasty_extinct(faction_id: String)


## Matrimonio dinámico: {ok: bool, alliance?: String, claim?: Dictionary, reason?: String} (GDD §8.2).
func marry(_character_id: String, _target_character_id: String) -> Dictionary:
	return {}


## Eventos vitales generados al avanzar el año (GDD §8.2).
func advance_year() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	return events


## Gobernante actual de una facción ({} en Fase 0).
func get_ruler(_faction_id: String) -> Dictionary:
	return {}


## Heredero legal de una facción ({} si no hay todavía).
func get_heir(_faction_id: String) -> Dictionary:
	return {}


## Resuelve la sucesión al morir el gobernante (GDD §5.3).
func resolve_succession(_faction_id: String) -> Dictionary:
	return {}


## Árbol familiar serializable de una facción.
func get_family_tree(_faction_id: String) -> Array[Dictionary]:
	var tree: Array[Dictionary] = []
	return tree
