extends "res://scripts/ui/widgets/overlay_base.gd"
## Fin de año (GDD §9.8): informe anual con cosecha, sucesos, tesoro y frontera.
## Se abre al recibir EventBus.year_advanced / TurnManager.year_advanced.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")

var _year: int = 0
var _body: VBoxContainer = null


func _build_content() -> void:
	UIAudio.play_music("year_end")
	dialog.custom_minimum_size = Vector2(1180, 900)
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
	_build_goods_section(fid)
	_build_wars_section(fid)
	_build_prestige_ranking(fid)

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
				var labels := {"food": "alimentos", "goods": "bienes", "commerce": "comercio", "taxes": "impuestos"}
				for key: String in ["food", "goods", "commerce", "taxes"]:
					if output.has(key):
						parts.append("%s: %s" % [str(labels.get(key, key)), str(output[key])])
				output_text = " · ".join(parts) if not parts.is_empty() else "apoyo %d/100" % TSBGame.support(rid)
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


func _section_title(text: String) -> void:
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var title := UIKit.label(_body, text, "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)


func _build_goods_section(fid: String) -> void:
	_section_title("Bienes producidos")
	var totals: Dictionary = {}
	for region_id: Variant in TSBGame.regions_owned_by(fid):
		var output := TSBGame.region_output(str(region_id))
		if output is Dictionary:
			for key: Variant in ["food", "goods", "commerce", "taxes"]:
				if (output as Dictionary).has(str(key)):
					totals[str(key)] = float(totals.get(str(key), 0.0)) + float((output as Dictionary)[str(key)])
	if totals.is_empty():
		var empty := UIKit.label(_body, "Sin producción registrada este año.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		return
	var labels := {"food": "Alimentos", "goods": "Bienes", "commerce": "Comercio", "taxes": "Impuestos"}
	var parts: Array[String] = []
	for key: Variant in totals.keys():
		parts.append("%s: %s" % [str(labels.get(str(key), str(key))), str(snappedf(float(totals[key]), 0.1))])
	var label := UIKit.label(_body, " · ".join(parts), "InkLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _build_wars_section(fid: String) -> void:
	_section_title("Guerras")
	var wars: Array[String] = []
	for other: Variant in TSBGame.faction_ids():
		var other_id := str(other)
		if other_id == fid:
			continue
		if TSBGame.are_at_war(fid, other_id):
			wars.append(TSBGame.faction_name(other_id))
	if wars.is_empty():
		var peace := UIKit.label(_body, "El reino no sostiene guerras activas al cerrar el año.", "InkLabel")
		peace.add_theme_font_size_override("font_size", 15)
		peace.add_theme_color_override("font_color", Palette.INK_TEXT)
	else:
		var label := UIKit.label(_body, "En guerra con: " + ", ".join(wars) + ".", "InkLabel")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Palette.CRIMSON)


func _build_prestige_ranking(fid: String) -> void:
	_section_title("Ranking de prestigio · 8 casas jugables")
	var rows: Array = []
	for other: Variant in TSBGame.playable_factions():
		var other_id := str(other)
		rows.append({"id": other_id, "name": TSBGame.faction_name(other_id), "prestige": TSBGame.prestige(other_id)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("prestige", 0)) > int(b.get("prestige", 0))
	)
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var line := "%d. %s — %d prestigio%s" % [
			index + 1, str(row.get("name", "")), int(row.get("prestige", 0)),
			"  (tu casa)" if str(row.get("id", "")) == fid else "",
		]
		var label := UIKit.label(_body, line, "InkLabel")
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Palette.GOLD_DIM if str(row.get("id", "")) == fid else Palette.INK_TEXT)


func _build_chronicle_year(year_shown: int) -> void:
	_section_title("Crónica del año %d" % year_shown)
	var entries := TSBGame.chronicle(year_shown)
	if entries.is_empty():
		var empty := UIKit.label(_body, "La Crónica de este año aún no tiene entradas persistidas.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		return
	for entry_value: Variant in entries:
		if entry_value is Dictionary:
			var entry: Dictionary = entry_value
			var text := str(entry.get("text", ""))
			if text.is_empty():
				continue
			var label := UIKit.label(_body, "%s: %s" % [str(entry.get("season_or_year", "")), text], "InkLabel")
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 14)
			label.add_theme_color_override("font_color", Palette.INK_TEXT)
