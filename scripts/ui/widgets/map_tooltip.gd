extends PanelContainer
## Tooltip de region del mapa: panel pergamino que sigue al raton (GDD §9.3).

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")

var _label: RichTextLabel


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	add_theme_stylebox_override("panel", Palette.parchment_style(12))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.theme_type_variation = "ParchmentRich"
	_label.custom_minimum_size = Vector2(380, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false


func show_text(bbcode: String) -> void:
	if _label == null:
		return
	_label.text = bbcode
	visible = true
	reset_size()


func follow(mouse_position: Vector2) -> void:
	var view := get_viewport_rect().size
	var target := mouse_position + Vector2(22, 20)
	if target.x + size.x > view.x - 10.0:
		target.x = mouse_position.x - size.x - 18.0
	if target.y + size.y > view.y - 10.0:
		target.y = mouse_position.y - size.y - 18.0
	target.x = clampf(target.x, 10.0, maxf(view.x - size.x - 10.0, 10.0))
	target.y = clampf(target.y, 10.0, maxf(view.y - size.y - 10.0, 10.0))
	global_position = target


func hide_tip() -> void:
	visible = false
