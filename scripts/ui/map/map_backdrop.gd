extends Control
## Fondo del mapa principal: mar, siluetas de presentacion, retícula nautica,
## lineas de adyacencia entre regiones, cartela y rosa de los vientos.
## Todo generado por codigo a partir de data/map_layout.json (D-017).

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var layout: Dictionary = {}
var centers: Dictionary = {}
var map_year: int = 1337
var map_era_label: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(layout_data: Dictionary, region_centers: Dictionary, year_value: int) -> void:
	layout = layout_data
	centers = region_centers
	map_year = year_value
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var canvas := size
	if canvas.x < 32.0 or canvas.y < 32.0:
		return
	_draw_sea(canvas)
	_draw_landmasses(canvas)
	_draw_adjacency()
	_draw_sea_routes(canvas)
	_draw_cartouche(canvas)
	_draw_compass(Vector2(canvas.x * 0.075, canvas.y * 0.86), minf(canvas.x, canvas.y) * 0.055)
	_draw_scale(canvas)
	draw_rect(Rect2(Vector2(2, 2), canvas - Vector2(4, 4)), Palette.with_alpha(Palette.GOLD_DIM, 0.55), false, 2.0)


func _draw_sea(canvas: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, canvas), Palette.SEA_DEEP)
	var bands := 14
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var color := Palette.SEA_DEEP.lerp(Palette.SEA, 0.35 * (1.0 - absf(t - 0.45) * 1.4))
		draw_rect(Rect2(0, canvas.y * float(i) / float(bands), canvas.x, canvas.y / float(bands) + 1.0), color)
	# Retícula nautica.
	for i in range(1, 16):
		var x := canvas.x * float(i) / 16.0
		draw_line(Vector2(x, 0), Vector2(x, canvas.y), Palette.with_alpha(Palette.GOLD, 0.05), 1.0)
	for i in range(1, 12):
		var y := canvas.y * float(i) / 12.0
		draw_line(Vector2(0, y), Vector2(canvas.x, y), Palette.with_alpha(Palette.GOLD, 0.05), 1.0)
	# Leyendas de mar.
	var font := ThemeBuilder.get_font()
	draw_string(font, Vector2(canvas.x * 0.06, canvas.y * 0.52), "OCEANUS  OCCIDENTALIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.with_alpha(Palette.PARCHMENT, 0.10))
	draw_string(font, Vector2(canvas.x * 0.42, canvas.y * 0.99), "MARE  NOSTRUM", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.with_alpha(Palette.PARCHMENT, 0.10))
	draw_string(font, Vector2(canvas.x * 0.60, canvas.y * 0.10), "MARE  SEPTENTRIONALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.with_alpha(Palette.PARCHMENT, 0.09))


func _draw_landmasses(canvas: Vector2) -> void:
	var landmasses: Variant = layout.get("landmasses", [])
	if not (landmasses is Array):
		return
	for mass: Variant in (landmasses as Array):
		if not (mass is Array) or (mass as Array).size() < 3:
			continue
		var points := PackedVector2Array()
		for pair: Variant in (mass as Array):
			if pair is Array and (pair as Array).size() >= 2:
				points.append(Vector2(float(pair[0]) * canvas.x, float(pair[1]) * canvas.y))
		if points.size() < 3:
			continue
		draw_colored_polygon(points, Palette.LAND.lerp(Palette.SEA, 0.10))
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Palette.LAND_DARK, 2.5, true)
		# Hachura interior tenue para dar textura de grabado.
		for i in range(0, points.size(), 2):
			var a := points[i]
			var b := points[(i + 2) % points.size()]
			draw_line(a.lerp(b, 0.15), a.lerp(b, 0.75), Palette.with_alpha(Palette.LAND_DARK, 0.12), 1.0)


func _draw_adjacency() -> void:
	var seen: Dictionary = {}
	for id: Variant in centers.keys():
		var from_pos: Variant = centers[id]
		if not (from_pos is Vector2):
			continue
		for other: Variant in TSBGame.region_adjacency(str(id)):
			var other_id := str(other)
			if not centers.has(other_id):
				continue
			var pair: Array[String] = [str(id), other_id]
			pair.sort()
			var key := "%s|%s" % [pair[0], pair[1]]
			if seen.has(key):
				continue
			seen[key] = true
			var to_pos: Variant = centers[other_id]
			if to_pos is Vector2:
				draw_line(from_pos as Vector2, to_pos as Vector2, Palette.with_alpha(Palette.GOLD_BRIGHT, 0.18), 1.3, true)


func _draw_sea_routes(canvas: Vector2) -> void:
	var routes: Array[Array] = [
		[Vector2(0.18, 0.36), Vector2(0.24, 0.52), Vector2(0.32, 0.62), Vector2(0.40, 0.68)],
		[Vector2(0.62, 0.55), Vector2(0.66, 0.68), Vector2(0.72, 0.78)],
		[Vector2(0.10, 0.29), Vector2(0.16, 0.42), Vector2(0.28, 0.50)],
	]
	for route: Array in routes:
		var points := PackedVector2Array()
		for raw: Variant in route:
			var p: Vector2 = raw
			points.append(Vector2(p.x * canvas.x, p.y * canvas.y))
		_dashed_polyline(points, Palette.with_alpha(Palette.PARCHMENT, 0.13), 1.2, 9.0)


func _dashed_polyline(points: PackedVector2Array, color: Color, width: float, dash: float) -> void:
	for i in range(points.size() - 1):
		_dashed_line(points[i], points[i + 1], color, width, dash)


func _dashed_line(from_pos: Vector2, to_pos: Vector2, color: Color, width: float, dash: float) -> void:
	var distance := from_pos.distance_to(to_pos)
	if distance <= 0.01:
		return
	var direction := (to_pos - from_pos) / distance
	var covered := 0.0
	while covered < distance:
		var segment := minf(dash, distance - covered)
		draw_line(from_pos + direction * covered, from_pos + direction * (covered + segment), color, width, true)
		covered += dash * 1.8


func _draw_cartouche(canvas: Vector2) -> void:
	# Cartela compacta en la esquina superior derecha (evita las regiones del norte).
	var rect := Rect2(Vector2(canvas.x - 330, 20), Vector2(310, 64))
	draw_rect(rect, Palette.with_alpha(Palette.INK_DEEP, 0.78), true)
	draw_rect(rect, Palette.with_alpha(Palette.GOLD, 0.55), false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size - Vector2(8, 8)), Palette.with_alpha(Palette.GOLD_DIM, 0.55), false, 1.0)
	var font := ThemeBuilder.get_font()
	draw_string(font, rect.position + Vector2(14, 27), "THE SOVEREIGN'S BLOOD", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Palette.GOLD_BRIGHT)
	draw_string(font, rect.position + Vector2(14, 51), "EVROPA · ANNO DOMINI %d" % map_year, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.PARCHMENT)


func _draw_compass(center: Vector2, radius: float) -> void:
	var gold := Palette.with_alpha(Palette.GOLD, 0.55)
	draw_arc(center, radius, 0.0, TAU, 56, gold, 1.5, true)
	draw_arc(center, radius * 0.74, 0.0, TAU, 48, Palette.with_alpha(Palette.GOLD, 0.30), 1.0, true)
	var font := ThemeBuilder.get_font()
	for i in range(8):
		var angle := TAU * float(i) / 8.0 - PI * 0.5
		var length := radius if i % 2 == 0 else radius * 0.58
		var tip := center + Vector2(cos(angle), sin(angle)) * length
		draw_line(center, tip, gold, 1.4, true)
		if i % 2 == 0:
			var left := center + Vector2(cos(angle - 0.10), sin(angle - 0.10)) * radius * 0.54
			var right := center + Vector2(cos(angle + 0.10), sin(angle + 0.10)) * radius * 0.54
			draw_colored_polygon(PackedVector2Array([center, left, tip]), Palette.with_alpha(Palette.GOLD, 0.22))
			draw_colored_polygon(PackedVector2Array([center, tip, right]), Palette.with_alpha(Palette.GOLD, 0.08))
	var letters := ["N", "E", "S", "O"]
	for i in range(4):
		var angle := TAU * float(i) / 4.0 - PI * 0.5
		var pos := center + Vector2(cos(angle), sin(angle)) * (radius + 16.0)
		draw_string(font, pos + Vector2(-7, 7), letters[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.with_alpha(Palette.GOLD, 0.7))
	draw_circle(center, maxf(radius * 0.05, 2.0), gold)


func _draw_scale(canvas: Vector2) -> void:
	var origin := Vector2(canvas.x - 300, canvas.y - 40)
	var color := Palette.with_alpha(Palette.PARCHMENT, 0.45)
	for i in range(6):
		var start := origin + Vector2(i * 36, 0)
		var fill := Palette.with_alpha(Palette.PARCHMENT, 0.30) if i % 2 == 0 else Color.TRANSPARENT
		draw_rect(Rect2(start, Vector2(36, 7)), fill, true)
		draw_rect(Rect2(start, Vector2(36, 7)), color, false, 1.0)
	var font := ThemeBuilder.get_font()
	draw_string(font, origin + Vector2(0, 26), "LEGUAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.with_alpha(Palette.PARCHMENT, 0.45))
