extends "res://scripts/ui/widgets/overlay_base.gd"
## D-081: revisión de órdenes antes de cerrar el trimestre. No ejecuta el turno:
## emite confirmed/corrected y el world_map decide. Solo lee `turn_actions`.

signal confirmed
signal corrected

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _actions: Array = []
var _from_setup := false
var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1080, 640)
	add_title("TUS ÓRDENES ESTE TRIMESTRE", "Revisa lo que has ordenado antes de que la corte resuelva el trimestre")
	_body = add_body_scroll()
	var footer := add_footer("CORREGIR")
	for child: Node in footer.get_children():
		if child is Button:
			(child as Button).pressed.connect(func() -> void: corrected.emit())
			break
	var confirm := UIKit.button(footer, "CONFIRMAR TURNO", "PrimaryButton", "Ejecuta la IA y cierra el trimestre")
	confirm.custom_minimum_size = Vector2(260, 50)
	confirm.pressed.connect(_on_confirm)
	_refresh_body()


func setup(actions_value: Variant = null) -> void:
	if actions_value is Array:
		_actions = (actions_value as Array).duplicate(true)
		_from_setup = true
	_refresh_body()


func _refresh_body() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	if not _from_setup:
		_actions = TSBGame.turn_actions()
	var title := UIKit.label(_body, "Órdenes registradas: %d" % _actions.size(), "InkLabel")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var list := UIKit.vbox(_body, 4)
	if _actions.is_empty():
		var empty := UIKit.label(list, "No has dado órdenes este trimestre.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 17)
		empty.add_theme_color_override("font_color", Palette.MUTED)
	else:
		for entry_value: Variant in _actions:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			var action := str(entry.get("action", "orden"))
			var target := str(entry.get("target", ""))
			var pg := int(entry.get("pg", 0))
			var line := "· %s" % action.capitalize().replace("_", " ")
			if not target.is_empty():
				line += " → %s" % target
			if pg > 0:
				line += " (%d PG)" % pg
			var label := UIKit.label(list, line, "InkLabel")
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Palette.INK_TEXT)
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var note := UIKit.label(_body, "Órdenes libres (pueden repetirse): reclutar, entrenar, disolver, asignar trabajadores y comprar/vender mercancías.", "InkLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Palette.MUTED)


func _on_confirm() -> void:
	confirmed.emit()
	close_overlay()
