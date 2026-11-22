extends "res://scripts/ui/widgets/overlay_base.gd"
## D-080: pestaña Crónica consultable en cualquier momento. Histórico persistido
## por AG-2 (`state.chronicle`); la UI solo lo presenta.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UILegibility = preload("res://scripts/ui/ui_legibility.gd")

var _body: VBoxContainer = null
var _year_filter: int = -1


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1240, 800)
	add_title("CRÓNICA DEL REINO", "Memoria de tus años de gobierno · se conserva en la partida")
	_body = add_body_scroll()
	add_footer("CERRAR")
	_refresh()


func setup(year_value: Variant = null) -> void:
	if year_value != null and int(year_value) > 0:
		_year_filter = int(year_value)
	_refresh()


func _refresh() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var entries := TSBGame.chronicle()
	if _year_filter > 0:
		var filtered: Array = []
		for entry: Variant in entries:
			if entry is Dictionary and int((entry as Dictionary).get("year", -1)) == _year_filter:
				filtered.append(entry)
		entries = filtered
	if entries.is_empty():
		var empty := UIKit.label(_body, "No hay entradas en la Crónica todavía. Cierra un trimestre o un año para empezar a escribir la historia de tu casa.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 17)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		return
	var last_year := -1
	for entry_value: Variant in entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var year := int(entry.get("year", 0))
		if year != last_year:
			UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.6))
			var year_title := UIKit.label(_body, "Año %d" % year, "InkLabel")
			year_title.add_theme_font_size_override("font_size", 23)
			year_title.add_theme_color_override("font_color", Palette.CRIMSON)
			last_year = year
		var row := UIKit.hbox(_body, 10)
		var stamp := UIKit.label(row, str(entry.get("season_or_year", "")), "InkLabel")
		stamp.custom_minimum_size = Vector2(190, 0)
		stamp.add_theme_font_size_override("font_size", 14)
		stamp.add_theme_color_override("font_color", Palette.MUTED)
		var text := UIKit.label(row, str(entry.get("text", "")), "InkLabel")
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 16)
		text.add_theme_color_override("font_color", Palette.INK_TEXT)
