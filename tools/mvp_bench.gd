extends RefCounted
## MvpBench — métricas CPU del MVP-1337 (D-066, prompt §2.2).
##
## Dos medidas representativas, sin depender de GPU/ventana:
##   · `measure_ai_ms(ai_node)`  — 13 rivales en un turno (`AIManager.run_all_ai`).
##   · `measure_map_frame_ms()`  — reconstrucción CPU por frame de la capa de
##     fronteras del mapa (polígonos normalizados de `map_borders.json` 1337):
##     puntos, centroides y bounds, igual que `map_borders_layer` en su repintado.
## No mutan la partida salvo `AIManager.run_all_ai` (que el llamador controla).

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const MAP_BORDERS_PATH: String = "res://data/map_borders.json"
const DEFAULT_YEAR: int = 1337


## Entradas de fronteras del año (lista de {region_id, owner, ring}).
static func load_map_borders(year: int = DEFAULT_YEAR) -> Array:
	if not FileAccess.file_exists(MAP_BORDERS_PATH):
		return []
	var file := FileAccess.open(MAP_BORDERS_PATH, FileAccess.READ)
	if file == null:
		return []
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return []
	var data: Dictionary = SafeDict.as_dict(json.data)
	var years: Dictionary = SafeDict.as_dict(data.get("years", null))
	var entries: Array = SafeDict.as_array(years.get(str(year), null))
	return entries


## ms de CPU por frame de la capa de fronteras (promedio de `iterations`).
static func measure_map_frame_ms(iterations: int = 120, year: int = DEFAULT_YEAR) -> float:
	var entries: Array = load_map_borders(year)
	if entries.is_empty():
		return -1.0
	var loops: int = maxi(1, iterations)
	var start_usec: int = Time.get_ticks_usec()
	for _iteration in loops:
		for entry_value in entries:
			var entry: Dictionary = SafeDict.as_dict(entry_value)
			var ring: Array = SafeDict.as_array(entry.get("ring", null))
			var points := PackedVector2Array()
			for pair_value in ring:
				var pair: Array = SafeDict.as_array(pair_value)
				if pair.size() < 2:
					continue
				points.append(Vector2(float(pair[0]) * 4096.0, float(pair[1]) * 3072.0))
			if points.size() < 3:
				continue
			# Centroide + bounds (lo que la capa calcula al reconstruirse).
			var center := Vector2.ZERO
			var min_point := points[0]
			var max_point := points[0]
			for point in points:
				center += point
				min_point = Vector2(minf(min_point.x, point.x), minf(min_point.y, point.y))
				max_point = Vector2(maxf(max_point.x, point.x), maxf(max_point.y, point.y))
			center /= float(points.size())
			var _bounds := Rect2(min_point, max_point - min_point)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	return roundf(elapsed_ms / float(loops) * 1000.0) / 1000.0


## ms del turno IA completo. El nodo debe ser el autoload AIManager.
static func measure_ai_ms(ai_node: Node) -> int:
	if ai_node == null:
		return -1
	var start_ms: int = Time.get_ticks_msec()
	ai_node.call("run_all_ai")
	return Time.get_ticks_msec() - start_ms
