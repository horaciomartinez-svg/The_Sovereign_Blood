extends Control
## Resaltado del elemento UI del paso actual del Consejero (D-073).
## Dibuja un marco dorado sobre el control objetivo y una etiqueta breve.
## No captura input ni altera la pantalla subyacente.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")

var _target_rect: Rect2 = Rect2()
var _hint: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func set_highlight(target_rect: Rect2, hint: String = "") -> void:
	_target_rect = target_rect
	_hint = hint
	visible = target_rect.size.x > 1.0 and target_rect.size.y > 1.0
	queue_redraw()


func clear_highlight() -> void:
	_target_rect = Rect2()
	_hint = ""
	visible = false
	queue_redraw()


func _draw() -> void:
	if _target_rect.size.x < 1.0:
		return
	var rect := _target_rect.grow(4.0)
	var color := Palette.GOLD
	draw_rect(rect, Palette.with_alpha(Palette.GOLD, 0.10), true)
	draw_rect(rect, color, false, 3.0)
	var corner := 12.0
	for point: Vector2 in [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]:
		draw_circle(point, 4.0, Palette.GOLD)
	if not _hint.is_empty():
		var font := ThemeDB.fallback_font
		var text_size := font.get_string_size(_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var label_pos := Vector2(rect.position.x + 8.0, rect.position.y + 8.0)
		# En la barra lateral el objetivo es estrecho: la etiqueta va a su derecha
		# para no tapar los controles vecinos.
		if rect.position.x < 240.0:
			label_pos = Vector2(rect.end.x + 8.0, rect.position.y + 4.0)
		var label_rect := Rect2(label_pos, text_size + Vector2(16, 10))
		draw_rect(label_rect, Palette.with_alpha(Palette.INK_DEEP, 0.92), true)
		draw_rect(label_rect, Palette.GOLD, false, 1.0)
		draw_string(font, label_rect.position + Vector2(8, text_size.y + 1), _hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Palette.PARCHMENT_LIGHT)
