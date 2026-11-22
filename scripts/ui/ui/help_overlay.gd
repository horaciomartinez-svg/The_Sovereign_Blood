extends "res://scripts/ui/widgets/overlay_base.gd"
## Ayuda / resumen del Manual del Jugador (D-072). No duplica el manual:
## muestra un resumen y abre el documento del proyecto con OS.shell_open.

const UIManual = preload("res://scripts/ui/ui_manual.gd")

var _status: Label = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1280, 780)
	add_title("AYUDA · MANUAL DEL JUGADOR", "Resumen rápido; el manual completo está en docs/MANUAL_DEL_JUGADOR.md")
	var body := add_body_scroll()
	for line: String in UIManual.SUMMARY:
		var label := UIKit.label(body, line, "InkLabel")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Palette.INK_TEXT)
	UIKit.hsep(body, Palette.with_alpha(Palette.GOLD_DIM, 0.6))
	var hint := UIKit.label(body, "El manual detalla victoria/derrota, economía y mercancías, familia/consorte, diplomacia, los tres niveles de batalla, IA/eventos y consejos por facción.", "InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Palette.MUTED)

	var footer := add_footer("CERRAR")
	var open := UIKit.button(footer, "ABRIR MANUAL", "SmallButton", "Abre docs/MANUAL_DEL_JUGADOR.md en el visor del sistema")
	open.pressed.connect(_on_open_manual)
	_status = UIKit.label(content, "", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Palette.CRIMSON)


func _on_open_manual() -> void:
	if not UIManual.open_manual():
		if _status != null:
			_status.text = UIManual.fallback_message()
	else:
		if _status != null:
			_status.text = "Manual abierto: %s" % UIManual.manual_path()
