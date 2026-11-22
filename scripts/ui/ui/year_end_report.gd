extends "res://scripts/ui/widgets/overlay_base.gd"
## Fin de año (GDD §9.8): informe anual con cosecha, sucesos, tesoro y frontera.
## Se abre al recibir EventBus.year_advanced / TurnManager.year_advanced.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _year: int = 0
var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1180, 760)
	_body = add_body_scroll()
	add_footer("COMENZAR EL AÑO SIGUIENTE")
	_rebuild()


func setup(year_value: Variant) -> void:
	_year = int(year_value) if year_value != null else TSBGame.current_year()
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var year_shown := _year if _year > 0 else TSBGame.current_year()
	var fid := TSBGame.player_faction()

	var heading := UIKit.label(_body, "EL AÑO %d HA CONCLUIDO" % year_shown, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Palette.INK_TEXT)
	var subheading := UIKit.label(_body, "Crónica anual de la casa de %s" % TSBGame.faction_name(fid), "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	subheading.add_theme_font_size_override("font_size", 17)
	subheading.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var stats := UIKit.grid(_body, 3, 12, 6)
	_stat(stats, "Año", str(year_shown))
	_stat(stats, "Tesoro", "%d oro" % TSBGame.gold(fid))
	_stat(stats, "Prestigio", str(TSBGame.prestige(fid)))
	_stat(stats, "Regiones", "%d de %d" % [TSBGame.regions_owned_by(fid).size(), TSBGame.region_ids().size()])
	var army_count := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			army_count += 1
	_stat(stats, "Ejércitos", str(army_count))
	var living := 0
	for member: Variant in TSBGame.family_members(fid):
		if member is Dictionary and bool((member as Dictionary).get("alive", false)):
			living += 1
	_stat(stats, "Casa real", "%d vivos" % living)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var econ_title := UIKit.label(_body, "Cosecha y economía", "InkLabel")
	econ_title.add_theme_font_size_override("font_size", 21)
	econ_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var econ_note := UIKit.label(
		_body,
		"El cierre de año ejecuta EconomySystem.resolve_harvest y DynastySystem.advance_year (contrato §3.4). "
		+ "Los valores vivos se leen del estado canónico; en vista previa se muestran los datos iniciales de 1337.",
		"InkLabel")
	econ_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	econ_note.add_theme_font_size_override("font_size", 14)
	econ_note.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))

	var owned := TSBGame.regions_owned_by(fid)
	if not owned.is_empty():
		var top := owned.slice(0, mini(owned.size(), 4))
		var output_grid := UIKit.grid(_body, 2, 12, 4)
		for region_id: Variant in top:
			var rid := str(region_id)
			var output := TSBGame.region_output(rid)
			var output_text := ""
			if output.is_empty():
				output_text = "apoyo %d/100" % TSBGame.support(rid)
			else:
				var parts: Array[String] = []
				for key: Variant in output.keys():
					parts.append("%s: %s" % [str(key).replace("_", " "), str(output[key])])
					if parts.size() >= 3:
						break
				output_text = " · ".join(parts)
			_stat(output_grid, TSBGame.region_name(rid), output_text)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var news_title := UIKit.label(_body, "Sucesos del año", "InkLabel")
	news_title.add_theme_font_size_override("font_size", 21)
	news_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var news_added := 0
	for entry: Variant in TSBGame.events_in_log_for_year(year_shown):
		if entry is Dictionary:
			var text := str((entry as Dictionary).get("text", (entry as Dictionary).get("event_id", "")))
			if not text.is_empty():
				_news_item(text)
				news_added += 1
	if news_added == 0:
		for event: Variant in TSBGame.events_for_year(year_shown):
			if event is Dictionary:
				var news := str((event as Dictionary).get("news", ""))
				if not news.is_empty():
					_news_item(news)
					news_added += 1
	if news_added == 0:
		var quiet := UIKit.label(_body, "Un año sin grandes sucesos registrados por los cronistas.", "InkLabel")
		quiet.add_theme_font_size_override("font_size", 15)

	var next_year := year_shown + 1
	var next_label := UIKit.label(_body, "Se abre el año %d. El reloj del reino avanza al trimestre de invierno." % next_year, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	next_label.add_theme_font_size_override("font_size", 15)
	next_label.add_theme_color_override("font_color", Palette.CRIMSON)


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _news_item(text: String) -> void:
	var row := UIKit.hbox(_body, 8)
	var bullet := UIKit.label(row, "·", "InkLabel")
	bullet.add_theme_font_size_override("font_size", 18)
	bullet.add_theme_color_override("font_color", Palette.CRIMSON)
	var label := UIKit.label(row, text, "InkLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Palette.INK_TEXT)
