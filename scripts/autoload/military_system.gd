extends Node
## MilitarySystem — ejércitos, movimiento y reclutamiento (GDD §5.5, §8.1).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: un ejército por grupo de unidades en una región, movimiento por
## adyacencia (1 PG + coste de terreno), reclutamiento que consume pool y oro.

signal army_created(army_id: String, faction_id: String, region_id: String)
signal army_moved(army_id: String, from_region: String, to_region: String)
signal army_destroyed(army_id: String, faction_id: String)
signal armies_changed(region_id: String)
signal recruitment_completed(faction_id: String, region_id: String, unit_id: String)

## Límite de ejércitos por región (se amplía con edificios; GDD §5.5).
const DEFAULT_ARMY_SLOTS: int = 1
## PG por mover un ejército (GDD §5.5).
const MOVE_PG_COST: int = 1


## Crea un ejército vacío de la facción en la región indicada.
func create_army(_faction_id: String, _region_id: String) -> Dictionary:
	return {}


## Recluta unidades (consume pool regional y oro). true si la orden es válida.
func recruit(_faction_id: String, _region_id: String, _unit_id: String, _amount: int) -> bool:
	return false


## Mueve un ejército a una región adyacente validando PG y adyacencia.
func move_army(_army_id: String, _to_region: String) -> bool:
	return false


func disband_army(_army_id: String) -> bool:
	return false


## Ejército por id ({} si no existe; diccionario serializable).
func get_army(_army_id: String) -> Dictionary:
	return {}


func get_armies_in(_region_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return result


## Pool de reclutas disponible en la región (0 en Fase 0).
func get_recruitment_pool(_region_id: String) -> int:
	return 0


## Coste en PG de mover el ejército a la región destino (-1 si es ilegal).
func get_move_cost(_army_id: String, _to_region: String) -> int:
	return -1
