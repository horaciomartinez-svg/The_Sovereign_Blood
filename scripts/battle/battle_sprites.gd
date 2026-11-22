extends RefCounted
## Constantes y helpers de sprites, animación y proyectiles (Fase 3 §10.3,
## contrato `architecture_contracts_fase3.md` §2-§3, D-040/D-042).
##
## Módulo PURO (sin autoloads): lo usan `TacticalBattle` y `CloseCombat` y los
## tests pueden preloardearlo en `--script` sin problemas. Determinista: no
## consume RNG ni usa reloj de pared (el tiempo lo aporta el render con
## `tick_animation`).

const SafeDict = preload("res://scripts/utils/safe_dict.gd")

## Base sin espejo (el asset base mira a E) y direcciones que se espejan (D-042).
const BASE_FACINGS: Array[String] = ["E", "SE", "S"]
const MIRROR_FACINGS: Array[String] = ["W", "SW", "NW", "N"]

## Delta axial (signo) → orientación. Sólo 6 vecinos hexagonales.
const FACING_BY_SIGN: Dictionary = {
	Vector2i(1, 0): "E",
	Vector2i(1, -1): "SE",
	Vector2i(0, 1): "S",
	Vector2i(-1, 1): "SW",
	Vector2i(-1, 0): "W",
	Vector2i(0, -1): "N",
}

const MARCH_FPS_DEFAULT: float = 6.0
const MARCH_FRAME_COUNT: int = 3

## Proyectiles D-042/D-048: por `unit_id`; virote/flecha/piedra con su sprite,
## duración y altura de arco. La trayectoria es paramétrica (sin RNG de combate).
const PROJECTILE_BY_UNIT: Dictionary = {
	"crossbowmen": {
		"type": "virote",
		"sprite": "res://assets/art/sprites/projectiles/proyectil_virote.png",
		"duration_ms": 350,
		"arc_height": 24.0,
		"ballistic": true,
	},
	"longbowman": {
		"type": "flecha",
		"sprite": "res://assets/art/sprites/projectiles/proyectil_flecha.png",
		"duration_ms": 500,
		"arc_height": 40.0,
		"ballistic": true,
	},
	# D-048: arco compuesto (jenízaro) y caballería de estepa disparan flecha.
	"janissary": {
		"type": "flecha",
		"sprite": "res://assets/art/sprites/projectiles/proyectil_flecha.png",
		"duration_ms": 500,
		"arc_height": 40.0,
		"ballistic": true,
	},
	"steppe_cavalry": {
		"type": "flecha",
		"sprite": "res://assets/art/sprites/projectiles/proyectil_flecha.png",
		"duration_ms": 500,
		"arc_height": 40.0,
		"ballistic": true,
	},
	"bombarda": {
		"type": "piedra",
		"sprite": "res://assets/art/sprites/projectiles/proyectil_piedra.png",
		"duration_ms": 700,
		"arc_height": 56.0,
		"ballistic": true,
	},
}


## Orientación (E/SE/S/SW/W/NW/N) a partir de un delta de hexes.
static func facing_from_delta(dq: int, dr: int) -> String:
	if dq == 0 and dr == 0:
		return "E"
	var sign_delta := Vector2i(signi(dq), signi(dr))
	var facing: String = str(FACING_BY_SIGN.get(sign_delta, ""))
	if facing != "":
		return facing
	# Fallback angular (por si el delta no es de un vecino axial).
	var degrees: float = rad_to_deg(atan2(float(dr), float(dq)))
	if degrees < 0.0:
		degrees += 360.0
	if degrees < 22.5 or degrees >= 337.5:
		return "E"
	if degrees < 67.5:
		return "SE"
	if degrees < 112.5:
		return "S"
	if degrees < 157.5:
		return "SW"
	if degrees < 202.5:
		return "W"
	if degrees < 247.5:
		return "NW"
	return "N"


## True si el sprite debe espejarse horizontalmente (W/SW/NW/N).
static func mirror_for(facing: String) -> bool:
	return MIRROR_FACINGS.has(facing)


static func is_valid_facing(facing: String) -> bool:
	return BASE_FACINGS.has(facing) or MIRROR_FACINGS.has(facing)


## Rutas res:// de los cuadros de una hoja (vacío si no hay sprite).
static func frames_of(sprite_sheet: Dictionary) -> Array[String]:
	var frames: Array[String] = []
	for frame_value in SafeDict.as_array(sprite_sheet.get("frames", null)):
		frames.append(str(frame_value))
	return frames


## Ruta del cuadro `frame_index` (con wrap; "" si fallback).
static func frame_path(sprite_sheet: Dictionary, frame_index: int) -> String:
	var frames: Array[String] = frames_of(sprite_sheet)
	if frames.is_empty():
		return ""
	return frames[posmod(frame_index, frames.size())]


static func march_fps(sprite_sheet: Dictionary) -> float:
	var anim: Dictionary = SafeDict.as_dict(sprite_sheet.get("anim", null))
	return SafeDict.as_float(anim.get("fps"), MARCH_FPS_DEFAULT)


## Cuadro de marcha (0..2) a 6 fps con loop; en reposo siempre 0.
static func march_frame(sprite_sheet: Dictionary, elapsed_ms: float, moving: bool) -> int:
	if not moving or sprite_sheet.is_empty():
		return 0
	var frames: Array[String] = frames_of(sprite_sheet)
	if frames.is_empty():
		return 0
	var cycle: int = mini(MARCH_FRAME_COUNT, frames.size())
	var fps: float = march_fps(sprite_sheet)
	var index: int = int(floorf(maxf(0.0, elapsed_ms) * fps / 1000.0))
	return posmod(index, cycle)


## Especificación del proyectil de una unidad ({} si no dispara).
static func projectile_for_unit(unit_id: String) -> Dictionary:
	var spec: Dictionary = SafeDict.as_dict(PROJECTILE_BY_UNIT.get(unit_id, null))
	if spec.is_empty():
		return {}
	var result: Dictionary = spec.duplicate(true)
	result["unit_id"] = unit_id
	return result


## Posición paramétrica de la trayectoria (x lineal, arco senoidal, D-042).
static func projectile_position(from_point: Dictionary, to_point: Dictionary,
		arc_height: float, t: float) -> Dictionary:
	var clamped: float = clampf(t, 0.0, 1.0)
	var from_x: float = SafeDict.as_float(from_point.get("x"), 0.0)
	var from_y: float = SafeDict.as_float(from_point.get("y"), 0.0)
	var to_x: float = SafeDict.as_float(to_point.get("x"), 0.0)
	var to_y: float = SafeDict.as_float(to_point.get("y"), 0.0)
	var x: float = lerpf(from_x, to_x, clamped)
	var y: float = lerpf(from_y, to_y, clamped) - arc_height * sin(PI * clamped)
	return {"x": snappedf(x, 0.01), "y": snappedf(y, 0.01)}
