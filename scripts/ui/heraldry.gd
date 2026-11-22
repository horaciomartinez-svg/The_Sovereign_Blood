extends RefCounted
## Heraldica generativa (GDD §10): escudos dibujados por codigo a partir del
## color de faccion y la casa. Sin assets raster ni material de terceros.
##
## Uso tipico (dentro de un Control._draw()):
##   Heraldry.draw_shield(self, Rect2(Vector2.ZERO, size), color, "plantagenet")

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")

const CHARGES: Array[String] = [
	"lion", "fleur", "cross", "eagle", "star", "tower", "sword", "crown", "lozenge", "bend",
]


## Carga heraldica estable por casa (misma casa -> mismo emblema).
static func charge_for(house: String) -> String:
	if house.is_empty():
		return "cross"
	return CHARGES[absi(hash(house)) % CHARGES.size()]


static func secondary_color(field: Color, house: String) -> Color:
	var metal := Palette.heraldic_metal(house)
	return field.lerp(metal, 0.55).darkened(0.05)


## Poligono del escudo (escudo "frances" medieval) dentro del rect dado.
static func shield_polygon(rect: Rect2) -> PackedVector2Array:
	var w := rect.size.x
	var h := rect.size.y
	var c := rect.position + rect.size * 0.5
	var pts := PackedVector2Array([
		c + Vector2(-w * 0.50, -h * 0.50),
		c + Vector2(w * 0.50, -h * 0.50),
		c + Vector2(w * 0.50, -h * 0.18),
		c + Vector2(w * 0.42, h * 0.12),
		c + Vector2(w * 0.22, h * 0.40),
		c + Vector2(0.0, h * 0.50),
		c + Vector2(-w * 0.22, h * 0.40),
		c + Vector2(-w * 0.42, h * 0.12),
		c + Vector2(-w * 0.50, -h * 0.18),
	])
	return pts


## Dibuja un escudo completo (campo, jefe, emblema y filetes) en `canvas`.
static func draw_shield(
		canvas: CanvasItem,
		rect: Rect2,
		field_color: Color,
		house: String,
		line_width: float = 3.0) -> void:
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return
	var points := shield_polygon(rect)
	var metal := Palette.heraldic_metal(house)
	var secondary := secondary_color(field_color, house)

	# Sombra y campo.
	canvas.draw_colored_polygon(_offset_polygon(points, Vector2(3, 4)), Color(0.0, 0.0, 0.0, 0.35))
	canvas.draw_colored_polygon(points, field_color.darkened(0.12))
	var inner := _scale_polygon(points, rect, 0.94)
	canvas.draw_colored_polygon(inner, field_color)

	# Jefe (banda superior) con el color secundario de la casa.
	var w := rect.size.x
	var h := rect.size.y
	var c := rect.position + rect.size * 0.5
	var chief := PackedVector2Array([
		c + Vector2(-w * 0.44, -h * 0.44),
		c + Vector2(w * 0.44, -h * 0.44),
		c + Vector2(w * 0.44, -h * 0.20),
		c + Vector2(0.0, -h * 0.15),
		c + Vector2(-w * 0.44, -h * 0.20),
	])
	canvas.draw_colored_polygon(chief, secondary)
	var chief_line := PackedVector2Array([
		c + Vector2(-w * 0.44, -h * 0.20),
		c + Vector2(0.0, -h * 0.15),
		c + Vector2(w * 0.44, -h * 0.20),
	])
	canvas.draw_polyline(chief_line, Palette.with_alpha(metal, 0.9), maxf(line_width * 0.7, 1.0), true)

	# Emblema.
	_draw_charge(canvas, charge_for(house), c + Vector2(0, h * 0.10), minf(w, h) * 0.30, metal, field_color)

	# Filetes del escudo (metal + linea interior).
	var outline := _closed(points)
	canvas.draw_polyline(outline, metal, line_width, true)
	canvas.draw_polyline(_closed(_scale_polygon(points, rect, 0.88)), Palette.with_alpha(metal, 0.45), 1.0, true)


## Borde/marco cuadrado para "retratos" (escudo sobre fondo tinta).
static func draw_frame(canvas: CanvasItem, rect: Rect2, color: Color, width: float = 2.0) -> void:
	canvas.draw_rect(rect, color, false, width)
	canvas.draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), Palette.with_alpha(color, 0.45), false, 1.0)
	var corner := minf(rect.size.x, rect.size.y) * 0.12
	for corner_center: Vector2 in [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(0, rect.size.y),
		rect.position + rect.size,
	]:
		canvas.draw_circle(corner_center, maxf(corner * 0.18, 2.0), color)


static func _draw_charge(
		canvas: CanvasItem,
		kind: String,
		center: Vector2,
		s: float,
		color: Color,
		field: Color) -> void:
	var dark := field.darkened(0.35)
	match kind:
		"lion":
			canvas.draw_colored_polygon(_ellipse(center + Vector2(0, s * 0.05), s * 0.34, s * 0.48, 14), color)
			canvas.draw_circle(center + Vector2(s * 0.22, -s * 0.42), s * 0.22, color)
			canvas.draw_circle(center + Vector2(s * 0.30, -s * 0.48), s * 0.05, dark)
			canvas.draw_line(center + Vector2(-s * 0.28, s * 0.40), center + Vector2(-s * 0.52, s * 0.62), color, maxf(s * 0.12, 2.0))
			canvas.draw_line(center + Vector2(-s * 0.18, s * 0.42), center + Vector2(-s * 0.05, s * 0.66), color, maxf(s * 0.10, 2.0))
			canvas.draw_line(center + Vector2(-s * 0.34, -s * 0.30), center + Vector2(-s * 0.62, -s * 0.50), color, maxf(s * 0.08, 2.0))
		"fleur":
			canvas.draw_circle(center + Vector2(0, -s * 0.34), s * 0.17, color)
			canvas.draw_circle(center + Vector2(-s * 0.30, -s * 0.10), s * 0.20, color)
			canvas.draw_circle(center + Vector2(s * 0.30, -s * 0.10), s * 0.20, color)
			canvas.draw_circle(center + Vector2(0, s * 0.02), s * 0.24, color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.40, s * 0.14), Vector2(s * 0.80, s * 0.12)), color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.07, s * 0.22), Vector2(s * 0.14, s * 0.36)), color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.30, s * 0.18), Vector2(s * 0.60, s * 0.07)), dark)
		"cross":
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.16, -s * 0.56), Vector2(s * 0.32, s * 1.12)), color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.52, -s * 0.18), Vector2(s * 1.04, s * 0.34)), color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.08, -s * 0.46), Vector2(s * 0.16, s * 0.92)), dark)
		"eagle":
			canvas.draw_colored_polygon(PackedVector2Array([
				center, center + Vector2(-s * 0.72, -s * 0.28), center + Vector2(-s * 0.58, s * 0.08),
				center + Vector2(-s * 0.18, s * 0.02),
			]), color)
			canvas.draw_colored_polygon(PackedVector2Array([
				center, center + Vector2(s * 0.72, -s * 0.28), center + Vector2(s * 0.58, s * 0.08),
				center + Vector2(s * 0.18, s * 0.02),
			]), color)
			canvas.draw_colored_polygon(_ellipse(center + Vector2(0, s * 0.12), s * 0.20, s * 0.42, 12), color)
			canvas.draw_circle(center + Vector2(0, -s * 0.40), s * 0.16, color)
			canvas.draw_line(center + Vector2(0, s * 0.50), center + Vector2(0, s * 0.70), color, maxf(s * 0.10, 2.0))
		"star":
			canvas.draw_colored_polygon(_star(center, s * 0.62, s * 0.26, 5), color)
			canvas.draw_circle(center, s * 0.10, dark)
		"tower":
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.36, -s * 0.20), Vector2(s * 0.72, s * 0.76)), color)
			for i in range(3):
				canvas.draw_rect(Rect2(center + Vector2(-s * 0.40 + i * s * 0.28, -s * 0.44), Vector2(s * 0.20, s * 0.26)), color)
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.10, s * 0.18), Vector2(s * 0.20, s * 0.38)), dark)
		"sword":
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.07, -s * 0.60), Vector2(s * 0.14, s * 1.00)), color)
			canvas.draw_polygon(PackedVector2Array([
				center + Vector2(-s * 0.07, -s * 0.60),
				center + Vector2(s * 0.07, -s * 0.60),
				center + Vector2(0, -s * 0.78),
			]), PackedColorArray([color, color, color]))
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.34, s * 0.28), Vector2(s * 0.68, s * 0.10)), color)
			canvas.draw_circle(center + Vector2(0, s * 0.48), s * 0.10, color)
		"crown":
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.46, s * 0.08), Vector2(s * 0.92, s * 0.22)), color)
			for i in range(3):
				var x := -s * 0.42 + i * s * 0.42
				canvas.draw_colored_polygon(PackedVector2Array([
					center + Vector2(x, s * 0.08),
					center + Vector2(x + s * 0.20, -s * 0.38),
					center + Vector2(x + s * 0.40, s * 0.08),
				]), color)
			canvas.draw_circle(center + Vector2(0, s * 0.42), s * 0.07, dark)
		"lozenge":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -s * 0.62),
				center + Vector2(s * 0.44, 0),
				center + Vector2(0, s * 0.62),
				center + Vector2(-s * 0.44, 0),
			]), color)
			canvas.draw_circle(center, s * 0.13, dark)
		"bend":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-s * 0.52, -s * 0.52),
				center + Vector2(-s * 0.20, -s * 0.62),
				center + Vector2(s * 0.52, s * 0.40),
				center + Vector2(s * 0.20, s * 0.54),
			]), color)
			canvas.draw_line(center + Vector2(-s * 0.20, -s * 0.62), center + Vector2(s * 0.52, s * 0.40), dark, maxf(s * 0.08, 2.0))
		_:
			canvas.draw_circle(center, s * 0.34, color)


# --------------------------------------------------------------------------
# Helpers geometricos
# --------------------------------------------------------------------------
static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out


static func _offset_polygon(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + offset)
	return out


static func _scale_polygon(points: PackedVector2Array, rect: Rect2, factor: float) -> PackedVector2Array:
	var c := rect.position + rect.size * 0.5
	var out := PackedVector2Array()
	for p in points:
		out.append(c + (p - c) * factor)
	return out


static func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		out.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return out


static func _star(center: Vector2, outer: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var count := points * 2
	for i in range(count):
		var radius := outer if i % 2 == 0 else inner
		var angle := -PI * 0.5 + TAU * float(i) / float(count)
		out.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return out
