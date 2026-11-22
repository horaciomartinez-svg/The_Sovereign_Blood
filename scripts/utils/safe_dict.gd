extends RefCounted
## Helpers estáticos para tratar datos JSON sin romper el tipado de GDScript.
##
## Todo el estado de partida es Dictionary/Array/primitivos (contrato Fase 1 §1),
## así que los sistemas necesitan conversiones seguras: nunca usar `:=` con un
## valor Variant (Godot 4.7 lo trata como error de compilación).


static func as_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func as_array(value: Variant) -> Array:
	if value is Array:
		return value
	return []


static func as_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	if value is String:
		return value
	if value is StringName:
		return str(value)
	return fallback


static func as_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value
	if value is float:
		return int(roundf(value))
	return fallback


static func as_float(value: Variant, fallback: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	return fallback


static func as_bool(value: Variant, fallback: bool = false) -> bool:
	if value is bool:
		return value
	return fallback


static func clamp_int(value: int, minimum: int, maximum: int) -> int:
	return clampi(value, minimum, maximum)


static func clamp_float(value: float, minimum: float, maximum: float) -> float:
	return clampf(value, minimum, maximum)


## Copia profunda de un valor JSON (Dictionary/Array) o el propio valor.
static func deep_copy(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


## Claves de un diccionario ordenadas (determinismo en logs/tests).
static func sorted_keys(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in source.keys():
		result.append(str(key))
	result.sort()
	return result
