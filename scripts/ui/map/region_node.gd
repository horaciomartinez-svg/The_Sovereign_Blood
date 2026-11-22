extends Control
## Nodo clickeable de region del mapa principal (GDD §9.3).
## Dibuja un hexagono coloreado por faccion, con nombre corto, apoyo, ciudad y
## banderas de ejercito. Emite hover/click; el world_map decide que mostrar.

signal hovered(region_id: String)
signal unhovered(region_id: String)
signal clicked(region_id: String)

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var region_id: String = ""
var region_data: Dictionary = {}
var radius: Vector2 = Vector2(34, 40)
var short_label: String = ""
var faction_color: Color = Palette.MUTED
var is_selected: bool = false
var support_value: int = 50
var armies: Array = []
var soldiers: int = 0

var _name_label: Label = null
var _army_label: Label = null
var _hovering: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 5

	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Palette.PARCHMENT_LIGHT)
	_name_label.add_theme_color_override("font_shadow_color", Palette.with_alpha(Palette.INK_DEEP, 0.95))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_name_label)

	_army_label = Label.new()
	_army_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_army_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_army_label.add_theme_font_size_override("font_size", 11)
	_army_label.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_army_label.add_theme_color_override("font_shadow_color", Palette.with_alpha(Palette.INK_DEEP, 0.95))
	_army_label.add_theme_constant_override("shadow_offset_x", 1)
	_army_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_army_label)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Configura el nodo: datos normalizados de la region, centro en el mapa y
## tamano del hexagono. Llamar tras add_child.
func configure(data: Dictionary, node_center: Vector2, hex_radius: Vector2, army_entries: Array) -> void:
	region_data = data
	region_id = str(data.get("id", ""))
	radius = hex_radius
	armies = army_entries
	size = Vector2(radius.x * 2.0 + 14.0, radius.y * 1.74 + 16.0)
	position = node_center - size * 0.5
	short_label = str(data.get("label", TSBGame.region_name(region_id)))
	var owner := str(data.get("owner", ""))
	faction_color = TSBGame.faction_color(owner) if not owner.is_empty() else Palette.MUTED.darkened(0.25)
	support_value = int(data.get("support", 50))
	soldiers = 0
	for army: Variant in armies:
		if army is Dictionary:
			soldiers += TSBGame.army_soldiers(army)
	_name_label.text = short_label
	_name_label.position = Vector2(2, size.y * 0.30)
	_name_label.size = Vector2(size.x - 4, 30)
	_army_label.text = _army_text()
	_army_label.position = Vector2(2, size.y * 0.60)
	_army_label.size = Vector2(size.x - 4, 18)
	_army_label.visible = soldiers > 0
	queue_redraw()


func _army_text() -> String:
	if armies.is_empty():
		return ""
	var count_text := TSBGame.short_number(soldiers)
	if armies.size() > 1:
		return "%s  ×%d" % [count_text, armies.size()]
	return count_text


func set_selected(value: bool) -> void:
	if is_selected == value:
		return
	is_selected = value
	z_index = 9 if value else 5
	queue_redraw()


func _hex_points() -> PackedVector2Array:
	var center := size * 0.5
	var points := PackedVector2Array()
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _draw() -> void:
	if region_id.is_empty():
		return
	var points := _hex_points()
	var center := size * 0.5

	# Sombra.
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(3, 4))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.35))

	# Relleno por faccion.
	var fill := faction_color.darkened(0.12)
	fill.a = 0.94
	draw_colored_polygon(points, fill)
	var inner := PackedVector2Array()
	for point in points:
		inner.append(center + (point - center) * 0.86)
	draw_colored_polygon(inner, faction_color.darkened(0.02) if not is_selected else faction_color.lightened(0.08))

	# Borde tinta + filete de seleccion/hover.
	var outline_color := Palette.INK_DEEP
	var outline_width := 2.0
	if is_selected:
		outline_color = Palette.GOLD_BRIGHT
		outline_width = 4.0
	elif _hovering:
		outline_color = Palette.GOLD
		outline_width = 3.0
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, outline_color, outline_width, true)
	draw_polyline(_closed_scaled(points, center, 0.80), Palette.with_alpha(Palette.PARCHMENT_LIGHT, 0.22), 1.0, true)

	# Icono de terreno/ciudad.
	_draw_terrain_glyph(center)

	# Indicador de apoyo (esquina superior izquierda).
	var support_pos := points[0] + (points[1] - points[0]) * 0.30 + Vector2(0, 8)
	draw_circle(support_pos, 4.0, Palette.support_color(support_value))
	draw_circle(support_pos, 4.0, Palette.INK_DEEP, false, 1.0)

	# Banderas de ejercito (hasta 3).
	var flag_origin := Vector2(size.x * 0.16, size.y * 0.78)
	for i in range(mini(armies.size(), 3)):
		var army: Variant = armies[i]
		var color := faction_color
		if army is Dictionary:
			color = TSBGame.faction_color(str((army as Dictionary).get("faction_id", "")))
		_draw_flag(flag_origin + Vector2(i * 13.0, 0), color)


func _draw_terrain_glyph(center: Vector2) -> void:
	var has_city := bool(region_data.get("has_city", false))
	var terrain := str(region_data.get("terrain", "plains"))
	if has_city:
		# Torre/castillo.
		var base := center + Vector2(radius.x * 0.38, -radius.y * 0.30)
		draw_rect(Rect2(base, Vector2(12, 13)), Palette.INK_DEEP)
		draw_rect(Rect2(base + Vector2(-2, -6), Vector2(4, 6)), Palette.INK_DEEP)
		draw_rect(Rect2(base + Vector2(5, -8), Vector2(4, 8)), Palette.INK_DEEP)
		draw_rect(Rect2(base + Vector2(10, -6), Vector2(4, 6)), Palette.INK_DEEP)
	elif terrain == "forest":
		var base := center + Vector2(radius.x * 0.42, -radius.y * 0.18)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -10), base + Vector2(6, 4), base + Vector2(-6, 4)]), Palette.with_alpha(Palette.INK_DEEP, 0.65))
		draw_colored_polygon(PackedVector2Array([base + Vector2(9, -6), base + Vector2(14, 6), base + Vector2(4, 6)]), Palette.with_alpha(Palette.INK_DEEP, 0.5))
	elif terrain == "mountain":
		var base := center + Vector2(radius.x * 0.40, -radius.y * 0.12)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -12), base + Vector2(9, 6), base + Vector2(-9, 6)]), Palette.with_alpha(Palette.INK_DEEP, 0.65))
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -12), base + Vector2(3, -4), base + Vector2(-3, -4)]), Palette.PARCHMENT_LIGHT)
	elif terrain == "coast":
		var base := center + Vector2(radius.x * 0.30, -radius.y * 0.22)
		for i in range(2):
			var y := base.y + i * 5.0
			draw_line(Vector2(base.x - 8, y), Vector2(base.x + 8, y), Palette.with_alpha(Palette.INK_DEEP, 0.55), 1.5, true)
	else:
		var base := center + Vector2(radius.x * 0.40, -radius.y * 0.22)
		draw_circle(base, 2.0, Palette.with_alpha(Palette.INK_DEEP, 0.5))
		draw_circle(base + Vector2(7, 3), 2.0, Palette.with_alpha(Palette.INK_DEEP, 0.5))


func _draw_flag(origin: Vector2, color: Color) -> void:
	draw_line(origin, origin + Vector2(0, -13), Palette.INK_DEEP, 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(1, -13),
		origin + Vector2(10, -10),
		origin + Vector2(1, -6),
	]), color.lightened(0.15))
	draw_polyline(PackedVector2Array([
		origin + Vector2(1, -13),
		origin + Vector2(10, -10),
		origin + Vector2(1, -6),
		origin + Vector2(1, -13),
	]), Palette.INK_DEEP, 1.0, true)


func _closed_scaled(points: PackedVector2Array, center: Vector2, factor: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(center + (point - center) * factor)
	out.append(out[0])
	return out


func _inside_hex(local_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(local_point, _hex_points())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed and _inside_hex(mouse.position):
			clicked.emit(region_id)
			accept_event()
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_set_hover(_inside_hex(motion.position))


func _on_mouse_entered() -> void:
	_set_hover(_inside_hex(get_local_mouse_position()))


func _on_mouse_exited() -> void:
	_set_hover(false)


func _set_hover(value: bool) -> void:
	if _hovering == value:
		return
	_hovering = value
	if _hovering:
		hovered.emit(region_id)
	else:
		unhovered.emit(region_id)
	queue_redraw()
