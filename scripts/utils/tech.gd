extends RefCounted
## Tecnología por año (GDD v1.7 §4.3/§6.4, D-059).
##
## Tres eras: I (year < 1350), II (1350 ≤ year < 1400), III (year ≥ 1400).
## Una unidad está disponible si `unit.era` contiene el índice de la era actual
## (1..3) y, si existe, `available_from <= year`.
##
## Módulo PURO (sin autoloads): lo usan GameState/MilitarySystem/AIManager y los
## tests pueden precargarlo en `--script`.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const ERA_II_START: int = 1350
const ERA_III_START: int = 1400
const ERA_NAMES: Array[String] = ["I", "II", "III"]


static func era_index(year: int) -> int:
	if year < ERA_II_START:
		return 1
	if year < ERA_III_START:
		return 2
	return 3


## "I" | "II" | "III" (para UI y estado).
static func era_name(year: int) -> String:
	return ERA_NAMES[era_index(year) - 1]


static func era_for_year(year: int) -> String:
	return era_name(year)


## True si `unit_definition.era` (rango [min,max]) contiene la era del año.
static func is_unit_in_era(unit_definition: Dictionary, year: int) -> bool:
	var era_range: Array = SafeDict.as_array(unit_definition.get("era", null))
	if era_range.size() < 2:
		return true
	var era: int = era_index(year)
	var era_min: int = SafeDict.as_int(era_range[0], 1)
	var era_max: int = SafeDict.as_int(era_range[1], 3)
	return era >= era_min and era <= era_max


## Disponibilidad completa: era + `available_from` (año mínimo histórico).
static func is_unit_available(unit_definition: Dictionary, year: int) -> bool:
	if unit_definition.is_empty():
		return false
	if not is_unit_in_era(unit_definition, year):
		return false
	var available_from: int = SafeDict.as_int(unit_definition.get("available_from"), 0)
	return available_from <= 0 or year >= available_from
