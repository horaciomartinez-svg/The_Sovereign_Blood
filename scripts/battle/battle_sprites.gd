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

## Fase 3.1 / D-064: estados de animación de combate y sus mapas en `anim`.
const ANIM_STATES: Array[String] = ["idle", "march", "attack", "hit", "dead"]
const STATE_ANIM_KEY: Dictionary = {
	"idle": "idle",
	"march": "march",
	"attack": "attack",
	"hit": "hit",
	"dead": "death",
}
const STATE_FPS_KEY: Dictionary = {
	"idle": "fps",
	"march": "fps",
	"attack": "fps_attack",
	"hit": "fps_hit",
	"dead": "fps_death",
}
const STATE_DEFAULT_FPS: Dictionary = {
	"idle": 2.0,
	"march": 6.0,
	"attack": 9.0,
	"hit": 8.0,
	"dead": 6.0,
}
## `attack_2` es el cuadro de impacto (segundo del estado attack, D-064).
const ATTACK_IMPACT_FRAME_OFFSET: int = 1

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


# --- Fase 3.1 (D-064): estados idle/march/attack/hit/dead ------------------

static func anim_data(sprite_sheet: Dictionary) -> Dictionary:
	return SafeDict.as_dict(sprite_sheet.get("anim", null))


## Índices de `frames` para un estado ([] si no hay mapa o fallback).
static func state_frame_indices(sprite_sheet: Dictionary, state: String) -> Array[int]:
	var result: Array[int] = []
	var anim: Dictionary = anim_data(sprite_sheet)
	var key: String = str(STATE_ANIM_KEY.get(state, "idle"))
	for value in SafeDict.as_array(anim.get(key, null)):
		result.append(SafeDict.as_int(value, 0))
	return result


static func state_fps(sprite_sheet: Dictionary, state: String) -> float:
	var anim: Dictionary = anim_data(sprite_sheet)
	var key: String = str(STATE_FPS_KEY.get(state, "fps"))
	var fallback: float = SafeDict.as_float(STATE_DEFAULT_FPS.get(state, MARCH_FPS_DEFAULT), MARCH_FPS_DEFAULT)
	return SafeDict.as_float(anim.get(key), fallback)


static func state_is_loop(state: String) -> bool:
	return state == "idle" or state == "march"


static func state_is_oneshot(state: String) -> bool:
	return state == "attack" or state == "hit"


## Índice *dentro del estado* (0..n-1) para `elapsed_ms` desde su inicio.
static func state_frame_index(sprite_sheet: Dictionary, state: String, elapsed_ms: float) -> int:
	var indices: Array[int] = state_frame_indices(sprite_sheet, state)
	if indices.is_empty():
		return 0
	var fps: float = state_fps(sprite_sheet, state)
	var raw_index: int = int(floorf(maxf(0.0, elapsed_ms) * fps / 1000.0))
	if state_is_loop(state):
		return posmod(raw_index, indices.size())
	return mini(raw_index, indices.size() - 1)


## Ruta del cuadro actual de un estado ("" si fallback).
static func state_frame_path(sprite_sheet: Dictionary, state: String, elapsed_ms: float) -> String:
	var indices: Array[int] = state_frame_indices(sprite_sheet, state)
	if indices.is_empty():
		return ""
	var index_in_state: int = state_frame_index(sprite_sheet, state, elapsed_ms)
	return frame_path(sprite_sheet, indices[index_in_state])


## Índice absoluto en `frames` del cuadro `attack_2` (impacto).
static func attack_impact_index(sprite_sheet: Dictionary) -> int:
	var indices: Array[int] = state_frame_indices(sprite_sheet, "attack")
	if indices.is_empty():
		return -1
	return indices[mini(ATTACK_IMPACT_FRAME_OFFSET, indices.size() - 1)]


## ms desde el inicio del ataque hasta `attack_2` (impacto), con fps_attack.
static func attack_impact_ms(sprite_sheet: Dictionary) -> float:
	var fps: float = maxf(1.0, state_fps(sprite_sheet, "attack"))
	return roundf(float(ATTACK_IMPACT_FRAME_OFFSET) / fps * 1000.0 * 10.0) / 10.0


## Duración de un cuadro de ataque (1000/fps_attack): ventana mínima de attack_2.
static func attack_frame_ms(sprite_sheet: Dictionary) -> float:
	var fps: float = maxf(1.0, state_fps(sprite_sheet, "attack"))
	return roundf(1000.0 / fps * 10.0) / 10.0


## Retraso visual de la reacción (hit/dead) para que `attack_2` tenga ventana:
## impacto + un cuadro de ataque (≈222,2 ms con fps_attack=9). El daño lógico NO
## se retrasa; sólo el cambio de estado visual en el render.
static func reaction_delay_ms(sprite_sheet: Dictionary) -> float:
	return roundf((attack_impact_ms(sprite_sheet) + attack_frame_ms(sprite_sheet)) * 10.0) / 10.0


## Duración de un estado una vez (o del ciclo completo si es loop).
static func state_duration_ms(sprite_sheet: Dictionary, state: String) -> float:
	var indices: Array[int] = state_frame_indices(sprite_sheet, state)
	if indices.is_empty():
		return 0.0
	var fps: float = maxf(1.0, state_fps(sprite_sheet, state))
	return roundf(float(indices.size()) / fps * 1000.0 * 10.0) / 10.0


## Estado al que se pasa al agotar un one-shot (ataque/hit → idle).
static func state_after_elapsed(sprite_sheet: Dictionary, state: String, elapsed_ms: float) -> String:
	if state == "dead":
		return "dead"
	if state_is_oneshot(state):
		var duration: float = state_duration_ms(sprite_sheet, state)
		if duration > 0.0 and elapsed_ms >= duration:
			return "idle"
	return state


## Fila de animación para el estado y `elapsed_ms` (frame_path ya resuelto).
static func animation_frame_info(sprite_sheet: Dictionary, state: String, elapsed_ms: float) -> Dictionary:
	var indices: Array[int] = state_frame_indices(sprite_sheet, state)
	var index_in_state: int = state_frame_index(sprite_sheet, state, elapsed_ms)
	var absolute_index: int = -1
	if not indices.is_empty():
		absolute_index = indices[index_in_state]
	return {
		"state": state,
		"frame_index": index_in_state,
		"absolute_frame": absolute_index,
		"frame_path": frame_path(sprite_sheet, absolute_index) if absolute_index >= 0 else "",
		"fps": state_fps(sprite_sheet, state),
		"loop": state_is_loop(state),
		"duration_ms": state_duration_ms(sprite_sheet, state),
	}


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
