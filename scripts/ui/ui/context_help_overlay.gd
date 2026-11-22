extends "res://scripts/ui/widgets/overlay_base.gd"
## D-082: ayuda contextual de 3-5 líneas desde data/context_help.json.
## Se abre sin salir de la pantalla actual.

var _screen: String = ""
var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1120, 560)
	_body = add_body_scroll()
	add_footer("ENTENDIDO")
	_rebuild()


func setup(screen_key: Variant) -> void:
	_screen = str(screen_key) if screen_key != null else ""
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var context := UIHelp.context_for(_screen)
	var title_text := str(context.get("title", "Ayuda"))
	var title := UIKit.label(_body, "?  " + title_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var sub := UIKit.label(_body, "Ayuda contextual · puedes cerrar y seguir jugando", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var lines: Variant = context.get("lines", context.get("help", []))
	if not (lines is Array) or (lines as Array).is_empty():
		var empty := UIKit.label(_body, "No hay ayuda disponible para esta pantalla.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		return
	for index in range((lines as Array).size()):
		var line_text := str((lines as Array)[index])
		var row := UIKit.hbox(_body, 8)
		var bullet := UIKit.label(row, "%d." % (index + 1), "InkLabel")
		bullet.custom_minimum_size = Vector2(34, 0)
		bullet.add_theme_font_size_override("font_size", 16)
		bullet.add_theme_color_override("font_color", Palette.CRIMSON)
		var label := UIKit.label(row, line_text, "InkLabel")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Palette.INK_TEXT)
