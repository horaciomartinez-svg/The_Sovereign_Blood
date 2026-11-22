extends "res://scripts/ui/widgets/overlay_base.gd"
## D-080: boletín trimestral de 6 categorías. Solo lee estado/API y textos AG-1;
## no modifica nada. «Continuar» cierra el modal.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UILegibility = preload("res://scripts/ui/ui_legibility.gd")

var _payload: Dictionary = {}
var _body: VBoxContainer = null
var _built := false


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1120, 650)
	_body = add_body_scroll()
	add_footer("CONTINUAR")
	_built = true
	_refresh()


func setup(payload: Variant) -> void:
	if payload is Dictionary:
		_payload = (payload as Dictionary).duplicate(true)
	_refresh()


func _refresh() -> void:
	if not _built or _body == null:
		return
	UIKit.clear(_body)
	var season := str(_payload.get("season", TSBGame.season_name()))
	var year := int(_payload.get("year", TSBGame.current_year()))
	var header_template := UILegibility.text("quarterly_bulletin.header", "Ha terminado el {estación} de {año}")
	var header_text := UILegibility.format(header_template, {"estación": season, "año": year})
	var title := UIKit.label(_body, header_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var sub := UIKit.label(_body, "Boletín de la corte · resumen del trimestre", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.75))

	var values := _values()
	var categories: Array[String] = ["economy", "support", "actions", "demography", "trade", "events"]
	for category in categories:
		var label_template := UILegibility.text("quarterly_bulletin.categories.%s.label" % category, category.capitalize())
		var template := UILegibility.text("quarterly_bulletin.categories.%s.template" % category, "")
		var row := UIKit.hbox(_body, 12)
		var heading := UIKit.label(row, label_template, "InkLabel")
		heading.custom_minimum_size = Vector2(220, 0)
		heading.add_theme_font_size_override("font_size", 16)
		heading.add_theme_color_override("font_color", Palette.CRIMSON)
		var text := UILegibility.format(template, values) if not template.is_empty() else str(values.get(category, ""))
		if text.is_empty():
			text = str(values.get(category, "Sin datos."))
		var detail := UIKit.label(row, text, "InkLabel")
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_theme_font_size_override("font_size", 16)
		detail.add_theme_color_override("font_color", Palette.INK_TEXT)


func _values() -> Dictionary:
	var fid := TSBGame.player_faction()
	var owned := TSBGame.regions_owned_by(fid)
	var income := 0.0
	var support_sum := 0
	var at_risk := 0
	for region_id: Variant in owned:
		var rid := str(region_id)
		support_sum += TSBGame.support(rid)
		if TSBGame.support(rid) < 30:
			at_risk += 1
		var output := TSBGame.region_output(rid)
		income += float(output.get("gold_income", 0.0)) if output is Dictionary else 0.0
	var army_men := 0
	for entry: Variant in TSBGame.faction_army_summary(fid):
		if entry is Dictionary:
			army_men += int((entry as Dictionary).get("men", 0))
	var expense := float(army_men) * 0.1
	var net := income - expense
	var actions: Array = _payload.get("actions", [])
	var events: Array[String] = []
	for entry: Variant in TSBGame.events_in_log_for_year(int(_payload.get("year", TSBGame.current_year()))):
		if entry is Dictionary:
			var text := str((entry as Dictionary).get("text", ""))
			if not text.is_empty():
				events.append(text)
	var event_text := "Sin eventos este trimestre."
	if not events.is_empty():
		event_text = "; ".join(events.slice(maxi(0, events.size() - 2), events.size()))
	var living := 0
	for member: Variant in TSBGame.family_members(fid):
		if member is Dictionary and bool((member as Dictionary).get("alive", true)):
			living += 1
	return {
		"ingresos": int(roundf(income)),
		"gastos": int(roundf(expense)),
		"neto": int(roundf(net)),
		"oro": TSBGame.gold(fid),
		"apoyo_medio": int(roundf(float(support_sum) / maxf(1.0, float(owned.size())))),
		"regiones_riesgo": at_risk,
		"acciones": actions.size(),
		"pg_restantes": TSBGame.pg_remaining(),
		"nacimientos": 0,
		"muertes": 0,
		"casa_viva": living,
		"mercaderes": TSBGame.trade_merchants(fid),
		"expediciones": TSBGame.trade_expeditions().size(),
		"eventos": event_text,
		"economy": "Tesoro: %d oro; ingresos estimados: %d; gastos: %d; neto: %d." % [TSBGame.gold(fid), int(roundf(income)), int(roundf(expense)), int(roundf(net))],
		"support": "Apoyo medio: %d/100; regiones en riesgo: %d." % [int(roundf(float(support_sum) / maxf(1.0, float(owned.size())))), at_risk],
		"actions": "Órdenes registradas: %d; PG restantes: %d." % [actions.size(), TSBGame.pg_remaining()],
		"demography": "Casa real: %d vivos; nacimientos/muertes registrados en la Crónica." % living,
		"trade": "Mercaderes asignados: %d; expediciones activas: %d." % [TSBGame.trade_merchants(fid), TSBGame.trade_expeditions().size()],
	}
