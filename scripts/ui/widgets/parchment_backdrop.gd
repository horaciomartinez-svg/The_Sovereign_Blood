extends Control
## Fondo "mapa antiguo" generado por codigo para menus y pantallas oscuras.
## Sin texturas: lineas, manchas, rosa de los vientos y doble filete dorado.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var canvas_size := size
	if canvas_size.x < 8.0 or canvas_size.y < 8.0:
		return
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Palette.INK_DEEP)

	# Degradado sutil de tinta.
	var bands := 18
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var color := Palette.INK_DEEP.lerp(Palette.INK, 0.55 * (1.0 - t))
		draw_rect(Rect2(0, canvas_size.y * float(i) / float(bands), canvas_size.x, canvas_size.y / float(bands) + 1.0), color)

	# Reticula de carta nautica.
	for i in range(1, 12):
		var y := canvas_size.y * float(i) / 12.0
		draw_line(Vector2(0, y), Vector2(canvas_size.x, y), Palette.SEA_GRID, 1.0)
	for i in range(1, 18):
		var x := canvas_size.x * float(i) / 18.0
		draw_line(Vector2(x, 0), Vector2(x, canvas_size.y), Palette.SEA_GRID, 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	# Costas decorativas onduladas.
	for line_index in range(4):
		var base_y := canvas_size.y * (0.16 + 0.21 * float(line_index))
		var points := PackedVector2Array()
		var step := maxf(canvas_size.x / 60.0, 12.0)
		var x := 0.0
		while x <= canvas_size.x:
			var phase := float(line_index) * 1.7
			var y := base_y + sin(x / 210.0 + phase) * 26.0 + sin(x / 83.0 + phase * 2.0) * 9.0
			points.append(Vector2(x, y))
			x += step
		draw_polyline(points, Palette.with_alpha(Palette.GOLD, 0.07), 1.4, true)

	# Manchas de tinta/pergamino.
	for i in range(14):
		var pos := Vector2(rng.randf_range(0.03, 0.97) * canvas_size.x, rng.randf_range(0.05, 0.95) * canvas_size.y)
		var radius := rng.randf_range(14.0, 70.0)
		draw_circle(pos, radius, Color(0.35, 0.24, 0.10, rng.randf_range(0.015, 0.045)))

	# Rosa de los vientos.
	_draw_compass(Vector2(canvas_size.x * 0.86, canvas_size.y * 0.30), minf(canvas_size.x, canvas_size.y) * 0.075)
	_draw_compass(Vector2(canvas_size.x * 0.12, canvas_size.y * 0.78), minf(canvas_size.x, canvas_size.y) * 0.045)

	# Leyendas tenues de carta.
	var font := ThemeBuilder.get_font()
	var muted := Palette.with_alpha(Palette.GOLD, 0.22)
	draw_string(font, Vector2(canvas_size.x * 0.57, canvas_size.y * 0.13), "MARE  OCCIDENTALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, muted)
	draw_string(font, Vector2(canvas_size.x * 0.20, canvas_size.y * 0.92), "HIC  SVNT  DRACONES", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.with_alpha(Palette.GOLD, 0.14))

	# Doble filete.
	draw_rect(Rect2(Vector2(14, 14), canvas_size - Vector2(28, 28)), Palette.with_alpha(Palette.GOLD, 0.55), false, 2.0)
	draw_rect(Rect2(Vector2(22, 22), canvas_size - Vector2(44, 44)), Palette.with_alpha(Palette.GOLD_DIM, 0.7), false, 1.0)

	# Esquinas ornamentadas.
	_draw_corner(Vector2(22, 22), 1.0, 1.0)
	_draw_corner(Vector2(canvas_size.x - 22, 22), -1.0, 1.0)
	_draw_corner(Vector2(22, canvas_size.y - 22), 1.0, -1.0)
	_draw_corner(Vector2(canvas_size.x - 22, canvas_size.y - 22), -1.0, -1.0)


func _draw_compass(center: Vector2, radius: float) -> void:
	var gold := Palette.with_alpha(Palette.GOLD, 0.35)
	draw_arc(center, radius, 0.0, TAU, 48, gold, 1.2, true)
	draw_arc(center, radius * 0.72, 0.0, TAU, 40, Palette.with_alpha(Palette.GOLD, 0.18), 1.0, true)
	for i in range(8):
		var angle := TAU * float(i) / 8.0 - PI * 0.5
		var length := radius if i % 2 == 0 else radius * 0.62
		var tip := center + Vector2(cos(angle), sin(angle)) * length
		draw_line(center, tip, gold, 1.3)
		if i % 2 == 0:
			var left := center + Vector2(cos(angle - 0.10), sin(angle - 0.10)) * radius * 0.55
			var right := center + Vector2(cos(angle + 0.10), sin(angle + 0.10)) * radius * 0.55
			draw_colored_polygon(PackedVector2Array([center, left, tip]), Palette.with_alpha(Palette.GOLD, 0.10))
			draw_colored_polygon(PackedVector2Array([center, tip, right]), Palette.with_alpha(Palette.GOLD, 0.05))
	draw_circle(center, maxf(radius * 0.06, 2.0), gold)


func _draw_corner(origin: Vector2, dir_x: float, dir_y: float) -> void:
	var gold := Palette.with_alpha(Palette.GOLD, 0.5)
	var arm := 42.0
	draw_line(origin, origin + Vector2(arm * dir_x, 0), gold, 1.5)
	draw_line(origin, origin + Vector2(0, arm * dir_y), gold, 1.5)
	draw_line(origin + Vector2(8 * dir_x, 8 * dir_y), origin + Vector2(30 * dir_x, 8 * dir_y), gold, 1.0)
	draw_line(origin + Vector2(8 * dir_x, 8 * dir_y), origin + Vector2(8 * dir_x, 30 * dir_y), gold, 1.0)
	draw_circle(origin + Vector2(14 * dir_x, 14 * dir_y), 3.0, gold)
