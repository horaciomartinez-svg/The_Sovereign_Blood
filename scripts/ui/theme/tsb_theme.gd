extends RefCounted
## Tema global generado por codigo (GDD §10): tipografia serif del sistema,
## pergamino/azul tinta/dorado y variaciones de estilo reutilizables.
##
## No usa assets externos: SystemFont resuelve una serif del sistema operativo
## (Cinzel/EB Garamond/Georgia/Times/DejaVu Serif) y cae al font por defecto.
## Las escenas asignan `theme = TSBTheme.get_theme()` en su raiz.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")

const SERIF_NAMES: Array[String] = [
	"Cinzel", "EB Garamond", "Georgia", "Times New Roman",
	"Liberation Serif", "DejaVu Serif", "Noto Serif", "serif",
]

static var _font: SystemFont = null
static var _theme: Theme = null


static func get_font() -> Font:
	if _font == null:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(SERIF_NAMES)
		system_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		system_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_font = system_font
	return _font


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme := Theme.new()
	theme.default_font = get_font()
	theme.default_font_size = 21

	_setup_buttons(theme)
	_setup_labels(theme)
	_setup_panels(theme)
	_setup_inputs(theme)
	_setup_misc(theme)
	_theme = theme
	return theme


# --------------------------------------------------------------------------
# Botones
# --------------------------------------------------------------------------
static func _setup_buttons(theme: Theme) -> void:
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_type_variation("SmallButton", "Button")
	theme.set_type_variation("DangerButton", "Button")
	theme.set_type_variation("GhostButton", "Button")
	theme.set_type_variation("SidebarButton", "Button")
	theme.set_type_variation("CardButton", "Button")

	# Button base: tinta con filete dorado.
	theme.set_stylebox("normal", "Button", _button_box(Palette.INK_SOFT, Palette.GOLD_DIM, 1))
	theme.set_stylebox("hover", "Button", _button_box(Palette.INK, Palette.GOLD, 2))
	theme.set_stylebox("pressed", "Button", _button_box(Palette.GOLD_DIM.darkened(0.35), Palette.GOLD_BRIGHT, 2))
	theme.set_stylebox("disabled", "Button", _button_box(Palette.INK.darkened(0.2), Palette.with_alpha(Palette.GOLD_DIM, 0.4), 1))
	theme.set_stylebox("focus", "Button", _focus_box(Palette.GOLD_BRIGHT))
	theme.set_color("font_color", "Button", Palette.PARCHMENT)
	theme.set_color("font_hover_color", "Button", Palette.PARCHMENT_LIGHT)
	theme.set_color("font_pressed_color", "Button", Palette.GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", Palette.DISABLED_TEXT)
	theme.set_color("font_focus_color", "Button", Palette.PARCHMENT_LIGHT)
	theme.set_font_size("font_size", "Button", 21)
	theme.set_constant("outline_size", "Button", 0)
	theme.set_constant("h_separation", "Button", 8)

	# PrimaryButton: dorado con texto tinta.
	theme.set_stylebox("normal", "PrimaryButton", _button_box(Palette.GOLD.darkened(0.15), Palette.GOLD_BRIGHT, 2))
	theme.set_stylebox("hover", "PrimaryButton", _button_box(Palette.GOLD, Palette.PARCHMENT_LIGHT, 2))
	theme.set_stylebox("pressed", "PrimaryButton", _button_box(Palette.GOLD.darkened(0.35), Palette.GOLD_BRIGHT, 2))
	theme.set_stylebox("disabled", "PrimaryButton", _button_box(Palette.GOLD_DIM.darkened(0.3), Palette.with_alpha(Palette.GOLD, 0.4), 1))
	theme.set_color("font_color", "PrimaryButton", Palette.INK_TEXT)
	theme.set_color("font_hover_color", "PrimaryButton", Palette.INK_DEEP)
	theme.set_color("font_pressed_color", "PrimaryButton", Palette.INK_DEEP)
	theme.set_color("font_disabled_color", "PrimaryButton", Palette.DISABLED_TEXT)
	theme.set_font_size("font_size", "PrimaryButton", 23)

	# SmallButton
	theme.set_stylebox("normal", "SmallButton", _button_box(Palette.INK_SOFT, Palette.GOLD_DIM, 1, 3, 10, 5))
	theme.set_stylebox("hover", "SmallButton", _button_box(Palette.INK, Palette.GOLD, 1, 3, 10, 5))
	theme.set_stylebox("pressed", "SmallButton", _button_box(Palette.GOLD_DIM.darkened(0.35), Palette.GOLD_BRIGHT, 1, 3, 10, 5))
	theme.set_stylebox("disabled", "SmallButton", _button_box(Palette.INK.darkened(0.2), Palette.with_alpha(Palette.GOLD_DIM, 0.35), 1, 3, 10, 5))
	theme.set_font_size("font_size", "SmallButton", 17)

	# DangerButton
	theme.set_stylebox("normal", "DangerButton", _button_box(Palette.CRIMSON.darkened(0.1), Palette.CRIMSON_BRIGHT, 1))
	theme.set_stylebox("hover", "DangerButton", _button_box(Palette.CRIMSON, Palette.PARCHMENT, 2))
	theme.set_stylebox("pressed", "DangerButton", _button_box(Palette.CRIMSON.darkened(0.3), Palette.GOLD_BRIGHT, 2))
	theme.set_color("font_color", "DangerButton", Palette.PARCHMENT_LIGHT)
	theme.set_color("font_hover_color", "DangerButton", Palette.PARCHMENT_LIGHT)

	# GhostButton: solo texto con filete inferior.
	var ghost := Palette.stylebox(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 8, 4)
	var ghost_hover := Palette.stylebox(Palette.with_alpha(Palette.GOLD, 0.12), Color.TRANSPARENT, 0, 0, 8, 4)
	theme.set_stylebox("normal", "GhostButton", ghost)
	theme.set_stylebox("hover", "GhostButton", ghost_hover)
	theme.set_stylebox("pressed", "GhostButton", ghost_hover)
	theme.set_color("font_color", "GhostButton", Palette.MUTED)
	theme.set_color("font_hover_color", "GhostButton", Palette.PARCHMENT_LIGHT)
	theme.set_font_size("font_size", "GhostButton", 18)

	# SidebarButton: alineado a la izquierda, ancho completo.
	theme.set_stylebox("normal", "SidebarButton", _button_box(Palette.with_alpha(Palette.INK_SOFT, 0.55), Palette.with_alpha(Palette.GOLD_DIM, 0.5), 1, 3, 14, 8))
	theme.set_stylebox("hover", "SidebarButton", _button_box(Palette.INK_SOFT, Palette.GOLD, 1, 3, 14, 8))
	theme.set_stylebox("pressed", "SidebarButton", _button_box(Palette.GOLD_DIM.darkened(0.35), Palette.GOLD_BRIGHT, 1, 3, 14, 8))
	theme.set_stylebox("disabled", "SidebarButton", _button_box(Palette.with_alpha(Palette.INK, 0.5), Palette.with_alpha(Palette.GOLD_DIM, 0.25), 1, 3, 14, 8))
	theme.set_font_size("font_size", "SidebarButton", 19)

	# CardButton: tarjeta seleccionable (facciones).
	theme.set_stylebox("normal", "CardButton", _button_box(Palette.with_alpha(Palette.INK_SOFT, 0.8), Palette.with_alpha(Palette.GOLD_DIM, 0.8), 1, 5, 10, 8))
	theme.set_stylebox("hover", "CardButton", _button_box(Palette.INK_SOFT, Palette.GOLD, 2, 5, 10, 8))
	theme.set_stylebox("pressed", "CardButton", _button_box(Palette.GOLD.darkened(0.25), Palette.GOLD_BRIGHT, 2, 5, 10, 8))
	theme.set_color("font_color", "CardButton", Palette.PARCHMENT)
	theme.set_color("font_pressed_color", "CardButton", Palette.INK_TEXT)
	theme.set_font_size("font_size", "CardButton", 18)


static func _button_box(
		bg: Color, border: Color, width: int, radius: int = 4,
		margin_x: int = 20, margin_y: int = 9) -> StyleBoxFlat:
	var box := Palette.stylebox(bg, border, width, radius, margin_x, margin_y)
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	return box


static func _focus_box(color: Color) -> StyleBoxFlat:
	var box := Palette.stylebox(Color.TRANSPARENT, color, 2, 4, 20, 9)
	box.draw_center = false
	return box


# --------------------------------------------------------------------------
# Etiquetas
# --------------------------------------------------------------------------
static func _setup_labels(theme: Theme) -> void:
	var variations := {
		"TitleLabel": 56,
		"SubtitleLabel": 32,
		"SectionHeader": 25,
		"SmallLabel": 17,
		"TinyLabel": 14,
		"GoldLabel": 21,
		"CostLabel": 16,
		"ParchmentLabel": 21,
		"InkLabel": 21,
	}
	for name in variations.keys():
		theme.set_type_variation(name, "Label")
		theme.set_font_size("font_size", name, int(variations[name]))

	theme.set_color("font_color", "Label", Palette.PARCHMENT)
	theme.set_color("font_shadow_color", "Label", Palette.with_alpha(Palette.INK_DEEP, 0.6))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_constant("line_spacing", "Label", 2)

	theme.set_color("font_color", "TitleLabel", Palette.GOLD_BRIGHT)
	theme.set_constant("shadow_offset_x", "TitleLabel", 2)
	theme.set_constant("shadow_offset_y", "TitleLabel", 3)
	theme.set_color("font_color", "SubtitleLabel", Palette.PARCHMENT)
	theme.set_color("font_color", "SectionHeader", Palette.GOLD)
	theme.set_color("font_color", "SmallLabel", Palette.MUTED)
	theme.set_color("font_color", "TinyLabel", Palette.MUTED)
	theme.set_color("font_color", "GoldLabel", Palette.GOLD_BRIGHT)
	theme.set_color("font_color", "CostLabel", Palette.GOLD)
	theme.set_color("font_color", "ParchmentLabel", Palette.PARCHMENT_LIGHT)
	theme.set_color("font_color", "InkLabel", Palette.INK_TEXT)
	theme.set_color("font_shadow_color", "InkLabel", Color.TRANSPARENT)
	theme.set_color("font_shadow_color", "ParchmentLabel", Color.TRANSPARENT)


# --------------------------------------------------------------------------
# Paneles
# --------------------------------------------------------------------------
static func _setup_panels(theme: Theme) -> void:
	theme.set_type_variation("ParchmentPanel", "PanelContainer")
	theme.set_type_variation("InkPanel", "PanelContainer")
	theme.set_type_variation("InsetPanel", "PanelContainer")
	theme.set_type_variation("NoPanel", "PanelContainer")

	theme.set_stylebox("panel", "Panel", Palette.ink_style())
	theme.set_stylebox("panel", "PanelContainer", Palette.ink_style())
	theme.set_stylebox("panel", "ParchmentPanel", Palette.parchment_style(16))
	theme.set_stylebox("panel", "InkPanel", Palette.ink_style(16))
	theme.set_stylebox("panel", "InsetPanel", Palette.inset_style(10))
	theme.set_stylebox("panel", "NoPanel", Palette.stylebox(Color.TRANSPARENT))


# --------------------------------------------------------------------------
# Entradas, listas y barras
# --------------------------------------------------------------------------
static func _setup_inputs(theme: Theme) -> void:
	# LineEdit
	var normal := Palette.stylebox(Palette.INK_DEEP, Palette.GOLD_DIM, 1, 3, 8, 6)
	var focus := Palette.stylebox(Palette.INK_DEEP, Palette.GOLD, 2, 3, 8, 6)
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_stylebox("read_only", "LineEdit", Palette.stylebox(Palette.INK, Palette.with_alpha(Palette.GOLD_DIM, 0.5), 1, 3, 8, 6))
	theme.set_color("font_color", "LineEdit", Palette.PARCHMENT_LIGHT)
	theme.set_color("font_placeholder_color", "LineEdit", Palette.MUTED)
	theme.set_color("caret_color", "LineEdit", Palette.GOLD_BRIGHT)
	theme.set_color("selection_color", "LineEdit", Palette.with_alpha(Palette.GOLD, 0.35))
	theme.set_font_size("font_size", "LineEdit", 19)

	# PopupMenu (desplegables de OptionButton)
	theme.set_stylebox("panel", "PopupMenu", Palette.stylebox(Palette.INK, Palette.GOLD_DIM, 2, 4, 6, 6))
	theme.set_stylebox("hover", "PopupMenu", Palette.stylebox(Palette.GOLD_DIM.darkened(0.25), Palette.GOLD, 1, 3, 6, 4))
	theme.set_color("font_color", "PopupMenu", Palette.PARCHMENT)
	theme.set_color("font_hover_color", "PopupMenu", Palette.PARCHMENT_LIGHT)
	theme.set_color("font_disabled_color", "PopupMenu", Palette.DISABLED_TEXT)
	theme.set_font_size("font_size", "PopupMenu", 18)
	theme.set_constant("v_separation", "PopupMenu", 4)

	# ProgressBar (barras de apoyo/relacion)
	theme.set_stylebox("background", "ProgressBar", Palette.stylebox(Palette.INK_DEEP, Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 3, 0, 0))
	theme.set_stylebox("fill", "ProgressBar", Palette.stylebox(Palette.GOLD, Color.TRANSPARENT, 0, 3, 0, 0))
	theme.set_color("font_color", "ProgressBar", Palette.INK_TEXT)
	theme.set_font_size("font_size", "ProgressBar", 14)

	# Scroll
	theme.set_stylebox("panel", "ScrollContainer", Palette.stylebox(Color.TRANSPARENT))
	theme.set_stylebox("scroll", "VScrollBar", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.6), Color.TRANSPARENT, 0, 3, 3, 3))
	theme.set_stylebox("grabber", "VScrollBar", Palette.stylebox(Palette.with_alpha(Palette.GOLD_DIM, 0.8), Color.TRANSPARENT, 0, 3, 3, 3))
	theme.set_stylebox("grabber_highlight", "VScrollBar", Palette.stylebox(Palette.GOLD, Color.TRANSPARENT, 0, 3, 3, 3))
	theme.set_stylebox("grabber_pressed", "VScrollBar", Palette.stylebox(Palette.GOLD_BRIGHT, Color.TRANSPARENT, 0, 3, 3, 3))
	theme.set_stylebox("scroll", "HScrollBar", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.6), Color.TRANSPARENT, 0, 3, 3, 3))
	theme.set_stylebox("grabber", "HScrollBar", Palette.stylebox(Palette.with_alpha(Palette.GOLD_DIM, 0.8), Color.TRANSPARENT, 0, 3, 3, 3))


# --------------------------------------------------------------------------
# Varios
# --------------------------------------------------------------------------
static func _setup_misc(theme: Theme) -> void:
	theme.set_stylebox("separator", "HSeparator", Palette.stylebox(Palette.with_alpha(Palette.GOLD_DIM, 0.7), Color.TRANSPARENT, 0, 0, 0, 1))
	theme.set_stylebox("separator", "VSeparator", Palette.stylebox(Palette.with_alpha(Palette.GOLD_DIM, 0.7), Color.TRANSPARENT, 0, 0, 1, 0))
	theme.set_constant("separation", "HSeparator", 8)
	theme.set_constant("separation", "VSeparator", 8)

	# RichTextLabel
	theme.set_type_variation("ParchmentRich", "RichTextLabel")
	theme.set_color("default_color", "RichTextLabel", Palette.PARCHMENT)
	theme.set_color("default_color", "ParchmentRich", Palette.INK_TEXT)
	theme.set_font("normal_font", "RichTextLabel", get_font())
	theme.set_font("normal_font", "ParchmentRich", get_font())
	theme.set_font("bold_font", "RichTextLabel", get_font())
	theme.set_font_size("normal_font_size", "RichTextLabel", 19)
	theme.set_font_size("bold_font_size", "RichTextLabel", 19)
	theme.set_font_size("italics_font_size", "RichTextLabel", 19)
	theme.set_font_size("mono_font_size", "RichTextLabel", 18)
	theme.set_constant("line_separation", "RichTextLabel", 4)

	# Tooltips: fondo pergamino con texto tinta.
	theme.set_stylebox("panel", "TooltipPanel", Palette.parchment_style(10))
	theme.set_color("font_color", "TooltipLabel", Palette.INK_TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 18)

	# CheckBox / CheckButton heredan de Button; solo retocamos colores.
	theme.set_color("font_color", "CheckBox", Palette.PARCHMENT)
	theme.set_color("font_hover_color", "CheckBox", Palette.PARCHMENT_LIGHT)
	theme.set_font_size("font_size", "CheckBox", 20)
	theme.set_color("font_color", "CheckButton", Palette.PARCHMENT)
	theme.set_font_size("font_size", "CheckButton", 20)

	# OptionButton hereda Button; asegura el tamano de fuente.
	theme.set_font_size("font_size", "OptionButton", 19)

	# ItemList (por si se usa en listas de facciones)
	theme.set_stylebox("panel", "ItemList", Palette.inset_style(8, Palette.INK_DEEP))
	theme.set_stylebox("focus", "ItemList", _focus_box(Palette.GOLD))
	theme.set_stylebox("selected", "ItemList", Palette.stylebox(Palette.GOLD_DIM.darkened(0.25), Palette.GOLD, 1, 3, 6, 4))
	theme.set_stylebox("selected_focus", "ItemList", Palette.stylebox(Palette.GOLD_DIM, Palette.GOLD_BRIGHT, 1, 3, 6, 4))
	theme.set_stylebox("cursor", "ItemList", Palette.stylebox(Palette.with_alpha(Palette.GOLD, 0.2), Color.TRANSPARENT, 0, 0, 0, 0))
	theme.set_stylebox("cursor_unfocused", "ItemList", Palette.stylebox(Palette.with_alpha(Palette.GOLD, 0.1), Color.TRANSPARENT, 0, 0, 0, 0))
	theme.set_color("font_color", "ItemList", Palette.PARCHMENT)
	theme.set_color("font_selected_color", "ItemList", Palette.PARCHMENT_LIGHT)
	theme.set_font_size("font_size", "ItemList", 18)
