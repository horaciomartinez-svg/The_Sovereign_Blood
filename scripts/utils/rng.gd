class_name SeededRNG
extends RefCounted
## RNG sembrado, reproducible y serializable (GDD §8.3).
##
## Toda tirada de dados del juego (economía, familia, batalla, IA) debe salir de
## una instancia de esta clase para que "misma semilla + mismas acciones =
## mismo hash de save" (GDD §13, determinismo). Nunca usar randf()/randi() global.
##
## Uso:
##     var rng := SeededRNG.new(1337)
##     rng.next_int(1, 100)
##     var snap := rng.snapshot()   # guardar en la partida
##     rng.restore(snap)            # reproducir exactamente desde ahí

var initial_seed: int = 0
var _rng: RandomNumberGenerator


func _init(seed_value: int = 1337) -> void:
	initial_seed = seed_value
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value


## Semilla actual (64 bits).
func get_seed() -> int:
	return _rng.seed


func set_seed(seed_value: int) -> void:
	initial_seed = seed_value
	_rng.seed = seed_value


## Reestablece el generador a la semilla inicial.
func reset() -> void:
	_rng.seed = initial_seed


## [0.0, 1.0)
func next_float() -> float:
	return _rng.randf()


func next_float_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


## Entero en [from, to] inclusive.
func next_int(from: int, to: int) -> int:
	if to < from:
		return from
	return _rng.randi_range(from, to)


## true con probabilidad `probability` (0.0-1.0).
func next_bool(probability: float = 0.5) -> bool:
	return _rng.randf() < probability


## Tirada 1..100 (sistema porcentual del diseño; GDD §5.3).
func roll_d100() -> int:
	return _rng.randi_range(1, 100)


## Elemento aleatorio del array (null si está vacío).
func pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[_rng.randi_range(0, items.size() - 1)]


## Copia barajada del array (Fisher-Yates con este RNG; no muta el original).
func shuffled(items: Array) -> Array:
	var result: Array = items.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Variant = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result


## Valor gaussiano (Box-Muller). Por defecto μ=1, σ=0.15 como la tirada de
## batalla de GDD §6.1.
func gaussian(mean: float = 1.0, stddev: float = 0.15) -> float:
	var u1: float = maxf(_rng.randf(), 0.000001)
	var u2: float = _rng.randf()
	var z: float = sqrt(-2.0 * log(u1)) * cos(TAU * u2)
	return mean + stddev * z


## Modificador 0.75-1.25 según fórmula de comandante de GDD §6.1.
func commander_modifier(command_stat: int) -> float:
	return 1.0 + (float(command_stat) - 50.0) / 200.0


## Estado interno completo (semilla + flujo) para guardar en la partida.
func snapshot() -> Dictionary:
	return {
		"seed": _rng.seed,
		"state": _rng.state,
	}


## Restaura un snapshot creado con snapshot(). Acepta `state` como int o String:
## 64 bits no caben en un double, así que al guardar en JSON se serializa como
## texto para no perder precisión (ver GameState.to_dict).
func restore(snap: Dictionary) -> void:
	if snap.has("seed") and snap.has("state"):
		_rng.seed = _to_int64(snap["seed"])
		_rng.state = _to_int64(snap["state"])


func _to_int64(value: Variant) -> int:
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		return (value as String).to_int()
	return 0


## Copia independiente que continúa exactamente el mismo flujo.
func duplicate_rng() -> SeededRNG:
	var copy := SeededRNG.new(initial_seed)
	copy.restore(snapshot())
	return copy
