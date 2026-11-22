extends Node2D
## Capa 3 del mapa §10.1: interaccion visual (hover dorado + seleccion).
##
## Se separa de BordersLayer para que las fronteras y el relleno politico sean
## puramente datos, y esta capa sea la unica que responde al puntero. El hit-test
## delega en los poligonos de BordersLayer y el click lo gestiona world_map.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")

var borders: Node2D = null
var hover_region: String = ""
var selected_region: String = ""
var zoom: float = 0.7


func setup(borders_layer: Node2D) -> void:
	borders = borders_layer


func set_zoom(new_zoom: float) -> void:
	if is_equal_approx(zoom, new_zoom):
		return
	zoom = new_zoom
	queue_redraw()


func set_hover(region_id: String) -> void:
	if hover_region == region_id:
		return
	hover_region = region_id
	queue_redraw()


func set_selected(region_id: String) -> void:
	if selected_region == region_id:
		return
	selected_region = region_id
	queue_redraw()


func hit_test(world_point: Vector2) -> String:
	if borders == null:
		return ""
	return str(borders.call("hit_test", world_point))


func _draw() -> void:
	if borders == null:
		return
	if not hover_region.is_empty():
		var hover_points: PackedVector2Array = borders.call("get_polygon", hover_region)
		if hover_points.size() >= 3:
			draw_colored_polygon(hover_points, Palette.with_alpha(Palette.GOLD, 0.18))
			_draw_outline(hover_points, Palette.GOLD, 2.2 / maxf(zoom, 0.01))
	if not selected_region.is_empty():
		var selected_points: PackedVector2Array = borders.call("get_polygon", selected_region)
		if selected_points.size() >= 3:
			_draw_outline(selected_points, Palette.PARCHMENT_LIGHT, 3.0 / maxf(zoom, 0.01))


func _draw_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)
