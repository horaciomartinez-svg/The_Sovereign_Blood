extends Node
## EconomySystem — economía por regiones (GDD §5.2, §8.2).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: producción por asignación de mano de obra, tesoro, apoyo popular,
## edificios y cosecha anual (todo con RNG sembrado, GDD §8.3).

signal treasury_changed(faction_id: String, gold: int)
signal region_output_changed(region_id: String, output: Dictionary)
signal assignment_changed(region_id: String, worker_class: String, amount: int)
signal unrest_triggered(region_id: String, support: int)

## Clases de mano de obra asignables (GDD §5.2).
const WORKER_CLASSES: Array[String] = ["farmers", "artisans", "merchants", "recruits"]


## Recalcula producción, ingresos y gastos de una facción (GDD §8.2).
func recalculate(_faction_id: String) -> void:
	pass


## Asigna mano de obra de una región validando PG (GDD §8.2).
func allocate(_region_id: String, _worker_class: String, _amount: int) -> bool:
	return false


func get_treasury(_faction_id: String) -> int:
	return 0


## Producción del trimestre para una región ({} en Fase 0).
func get_region_output(_region_id: String) -> Dictionary:
	return {}


## Cosecha anual de la facción (turno 1; GDD §5.2).
func resolve_harvest(_faction_id: String) -> Dictionary:
	return {}


## Apoyo popular 0-100 de una región (50 = neutro en Fase 0).
func get_support(_region_id: String) -> int:
	return 50
