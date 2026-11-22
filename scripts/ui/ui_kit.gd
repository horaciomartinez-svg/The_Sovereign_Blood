extends RefCounted
## UIKit — fabricas de controles con el estilo de The Sovereign's Blood.
## Toda la UI se construye por codigo (placeholders GDD §10) para no depender
## de assets ni del editor. Estas funciones solo crean/nodes presentacion.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")


static func apply_theme(root: Control) -> void:
	root.theme = ThemeBuilder.get_theme()


static func label(
		parent: Node,
		text: String,
		variation: String = "",
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	if not variation.is_empty():
		node.theme_type_variation = variation
	node.horizontal_alignment = align
	parent.add_child(node)
	return node


static func rich(parent: Node, text: String = "", variation: String = "") -> RichTextLabel:
	var node := RichTextLabel.new()
	node.bbcode_enabled = true
	node.fit_content = true
	node.scroll_active = false
	node.text = text
	if not variation.is_empty():
		node.theme_type_variation = variation
	parent.add_child(node)
	return node


static func title(parent: Node, text: String, variation: String = "TitleLabel") -> Label:
	return label(parent, text, variation)


static func button(
		parent: Node,
		text: String,
		variation: String = "",
		tooltip: String = "") -> Button:
	var node := Button.new()
	node.text = text
	if not variation.is_empty():
		node.theme_type_variation = variation
	if not tooltip.is_empty():
		node.tooltip_text = tooltip
	parent.add_child(node)
	# D-066: click de UI (no-op si AudioManager aún no está registrado).
	node.pressed.connect(UIAudio.play_click)
	return node


static func panel(parent: Node, variation: String = "ParchmentPanel") -> PanelContainer:
	var node := PanelContainer.new()
	if not variation.is_empty():
		node.theme_type_variation = variation
	parent.add_child(node)
	return node


static func vbox(parent: Node, separation: int = 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func hbox(parent: Node, separation: int = 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node


static func grid(parent: Node, columns: int = 2, h_separation: int = 10, v_separation: int = 8) -> GridContainer:
	var node := GridContainer.new()
	node.columns = columns
	node.add_theme_constant_override("h_separation", h_separation)
	node.add_theme_constant_override("v_separation", v_separation)
	parent.add_child(node)
	return node


static func margin(parent: Node, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var node := MarginContainer.new()
	node.add_theme_constant_override("margin_left", left)
	node.add_theme_constant_override("margin_top", top)
	node.add_theme_constant_override("margin_right", right)
	node.add_theme_constant_override("margin_bottom", bottom)
	parent.add_child(node)
	return node


static func spacer(parent: Node, height: float = 8.0) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func expander(parent: Node) -> Control:
	var node := Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func hsep(parent: Node, color: Color = Palette.with_alpha(Palette.GOLD_DIM, 0.6)) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.custom_minimum_size = Vector2(0, 1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func vsep(parent: Node, color: Color = Palette.with_alpha(Palette.GOLD_DIM, 0.6)) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.custom_minimum_size = Vector2(1, 0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func bar(
		parent: Node,
		value: float,
		max_value: float,
		fill_color: Color,
		height: float = 16.0,
		show_text: bool = false) -> ProgressBar:
	var node := ProgressBar.new()
	node.max_value = maxf(max_value, 0.001)
	node.value = value
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_stylebox_override("background", Palette.stylebox(Palette.INK_DEEP, Palette.with_alpha(Palette.GOLD_DIM, 0.5), 1, 3))
	node.add_theme_stylebox_override("fill", Palette.stylebox(fill_color, Color.TRANSPARENT, 0, 3))
	if show_text:
		node.add_theme_color_override("font_color", Palette.INK_TEXT)
	parent.add_child(node)
	return node


## Etiqueta pequeña con fondo (chips de edificios, costes, estados).
static func chip(parent: Node, text: String, color: Color = Palette.INK_SOFT, text_color: Color = Palette.PARCHMENT) -> PanelContainer:
	var panel_node := PanelContainer.new()
	panel_node.add_theme_stylebox_override("panel", Palette.stylebox(color, Palette.with_alpha(Palette.GOLD_DIM, 0.7), 1, 3, 7, 3))
	panel_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	parent.add_child(panel_node)
	var text_node := label(panel_node, text, "TinyLabel")
	text_node.add_theme_color_override("font_color", text_color)
	return panel_node


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func use_font(node: Control, font_size: int) -> void:
	node.add_theme_font_override("font", ThemeBuilder.get_font())
	node.add_theme_font_size_override("font_size", font_size)


## Pone el nodo en una celda concreta de un GridContainer (helper de lectura).
static func grid_cell(parent: Node, control: Control) -> void:
	parent.add_child(control)


## Panel de dialogo centrado (para overlays). Devuelve el contenedor interior.
static func centered_dialog(
		parent: Control,
		min_size: Vector2,
		variation: String = "ParchmentPanel") -> PanelContainer:
	var center := CenterContainer.new()
	full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(center)
	var dialog := panel(center, variation)
	dialog.custom_minimum_size = min_size
	return dialog
