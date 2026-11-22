class_name UnitInstance
extends RefCounted
## Dataclass mínima de unidad concreta (instancia de un tipo de GDD §7.4).
##
## Fase 0: solo estructura tipada y serialización (sin lógica de juego).
## `unit_id` referencia data/units*.json; la instancia guarda el estado mutable.

var id: String = ""
var unit_id: String = ""
var faction_id: String = ""
## Efectivos actuales (hombres).
var size: int = 0
var strength: int = 0
## Moral 0.0-1.0 (GDD §6.1).
var morale: float = 1.0
## Veterania (0-100): multiplica el poder en GDD §6.1.
var experience: int = 0


func is_destroyed() -> bool:
	return size <= 0


## Factor de veterania 0.75-1.25 derivado de experience (GDD §6.1).
func veterancy_factor() -> float:
	return 1.0 + (float(experience) - 50.0) / 200.0


func to_dict() -> Dictionary:
	return {
		"id": id,
		"unit_id": unit_id,
		"faction_id": faction_id,
		"size": size,
		"strength": strength,
		"morale": morale,
		"experience": experience,
	}


func apply_dict(data: Dictionary) -> void:
	id = str(data.get("id", id))
	unit_id = str(data.get("unit_id", unit_id))
	faction_id = str(data.get("faction_id", faction_id))
	size = int(data.get("size", size))
	strength = int(data.get("strength", strength))
	morale = float(data.get("morale", morale))
	experience = int(data.get("experience", experience))
