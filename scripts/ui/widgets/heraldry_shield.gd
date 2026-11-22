extends Control
## Retrato placeholder: escudo heraldico generado por codigo (GDD §10).
## Se usa como "retrato" en el arbol familiar y en tarjetas de faccion.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const Heraldry = preload("res://scripts/ui/heraldry.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")

var house: String = ""
var field_color: Color = Palette.CRIMSON
var framed: bool = true
var line_width: float = 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 116)


func setup(house_name: String, color: Color, frame: bool = true) -> void:
	house = house_name
	field_color = color
	framed = frame
	queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var pad := 6.0
	var rect := Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	if framed:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.with_alpha(Palette.INK_DEEP, 0.85))
		Heraldry.draw_frame(self, Rect2(Vector2(1, 1), size - Vector2(2, 2)), Palette.with_alpha(Palette.GOLD_DIM, 0.8), 1.5)
	Heraldry.draw_shield(self, rect, field_color, house, line_width)
