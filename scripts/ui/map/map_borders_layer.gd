extends Node2D
## Capa 2 del mapa §10.1: fronteras vectoriales por ano + relleno de faccion.
##
## Datos: data/map_borders.json (AG-1). Cada region tiene un anillo normalizado
## [0..1]; se dibuja en coordenadas de mundo del mapa (map_size).
## Hover = tinta dorada ~18 %; click lo gestiona world_map. Todo por codigo.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var year: int = 0
var map_size: Vector2 = Vector2(2048, 1536)
var zoom: float = 0.7

var _polygons: Array[Dictionary] = []
var _index: Dictionary = {}


func _ready() -> void:
	z_index = 1
	visible = true


func set_map_size(new_size: Vector2) -> void:
	map_size = new_size
	if year > 0:
		load_year(year)


func set_year(new_year: int) -> void:
	year = new_year
	load_year(year)


func load_year(target_year: int) -> void:
	_polygons.clear()
	_index.clear()
	year = target_year
	for entry: Variant in TSBGame.map_borders_for_year(target_year):
		if not (entry is Dictionary):
			continue
		var entry_dict := entry as Dictionary
		var region_id := str(entry_dict.get("region_id", ""))
		var raw_ring: Variant = entry_dict.get("ring", [])
		if region_id.is_empty() or not (raw_ring is Array) or (raw_ring as Array).size() < 3:
			continue
		var points := PackedVector2Array()
		for pair: Variant in (raw_ring as Array):
			if pair is Array and (pair as Array).size() >= 2:
				points.append(Vector2(float((pair as Array)[0]) * map_size.x, float((pair as Array)[1]) * map_size.y))
		if points.size() < 3:
			continue
		var center := Vector2.ZERO
		var raw_center: Variant = entry_dict.get("center", null)
		if raw_center is Array and (raw_center as Array).size() >= 2:
			center = Vector2(float((raw_center as Array)[0]) * map_size.x, float((raw_center as Array)[1]) * map_size.y)
		else:
			for point in points:
				center += point
			center /= float(points.size())
		var entry_data := {
			"region_id": region_id,
			"points": points,
			"center": center,
			"owner": str(entry_dict.get("owner", "")),
		}
		_polygons.append(entry_data)
		_index[region_id] = _polygons.size() - 1
	queue_redraw()


func region_count() -> int:
	return _polygons.size()


func has_region(region_id: String) -> bool:
	return _index.has(region_id)


func set_zoom(new_zoom: float) -> void:
	if is_equal_approx(zoom, new_zoom):
		return
	zoom = new_zoom
	queue_redraw()


## Hit-test punto-en-poligono en coordenadas de mundo (47 anillos por movimiento).
func hit_test(world_point: Vector2) -> String:
	for entry: Dictionary in _polygons:
		if Geometry2D.is_point_in_polygon(world_point, entry.get("points", PackedVector2Array())):
			return str(entry.get("region_id", ""))
	return ""


func region_at(world_point: Vector2) -> String:
	return hit_test(world_point)


func get_entry(region_id: String) -> Dictionary:
	if not _index.has(region_id):
		return {}
	return _polygons[int(_index[region_id])]


func get_center(region_id: String) -> Vector2:
	var entry := get_entry(region_id)
	return entry.get("center", Vector2.ZERO)


func get_polygon(region_id: String) -> PackedVector2Array:
	var entry := get_entry(region_id)
	return entry.get("points", PackedVector2Array())


func _draw() -> void:
	if _polygons.is_empty():
		return
	var border_width := clampf(1.7 / maxf(zoom, 0.01), 0.5, 4.0)
	# Relleno politico (18-25 % de opacidad).
	for entry: Dictionary in _polygons:
		var owner := str(entry.get("owner", ""))
		var color := TSBGame.faction_color(owner) if not owner.is_empty() else Palette.MUTED.darkened(0.25)
		color.a = 0.22
		draw_colored_polygon(entry.get("points", PackedVector2Array()), color)
	# Fronteras de tinta.
	for entry: Dictionary in _polygons:
		var points: PackedVector2Array = entry.get("points", PackedVector2Array())
		if points.size() < 3:
			continue
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Palette.with_alpha(Palette.INK, 0.92), border_width, true)
