class_name Army
extends RefCounted
## Dataclass mínima de ejército (GDD §5.5, §6, §8.1).
##
## Fase 0: solo estructura tipada y serialización (sin lógica de juego).
## Un ejército agrupa unidades dentro de una región; el líder aporta el bono
## de comandante de GDD §6.1.

var id: String = ""
var faction_id: String = ""
var region_id: String = ""
var leader_id: String = ""
## Unidades del ejército: Array[UnitInstance] desde Fase 1; en Fase 0 Array mixto.
var units: Array = []
## Moral 0.0-1.0 (GDD §6.1).
var morale: float = 1.0
var movement_left: int = 0
var is_sieging: bool = false


func total_units() -> int:
	return units.size()


## true si no le quedan unidades o la moral está rota (GDD §6.1).
func is_annihilated() -> bool:
	return units.is_empty() or morale <= 0.0


func to_dict() -> Dictionary:
	var serialized_units: Array = []
	for unit: Variant in units:
		if unit is Object and unit.has_method("to_dict"):
			serialized_units.append(unit.call("to_dict"))
		elif unit is Dictionary:
			serialized_units.append((unit as Dictionary).duplicate(true))
		else:
			serialized_units.append(unit)
	return {
		"id": id,
		"faction_id": faction_id,
		"region_id": region_id,
		"leader_id": leader_id,
		"units": serialized_units,
		"morale": morale,
		"movement_left": movement_left,
		"is_sieging": is_sieging,
	}


func apply_dict(data: Dictionary) -> void:
	id = str(data.get("id", id))
	faction_id = str(data.get("faction_id", faction_id))
	region_id = str(data.get("region_id", region_id))
	leader_id = str(data.get("leader_id", leader_id))
	var raw_units: Variant = data.get("units", null)
	if raw_units is Array:
		units = (raw_units as Array).duplicate(true)
	morale = float(data.get("morale", morale))
	movement_left = int(data.get("movement_left", movement_left))
	is_sieging = bool(data.get("is_sieging", is_sieging))
