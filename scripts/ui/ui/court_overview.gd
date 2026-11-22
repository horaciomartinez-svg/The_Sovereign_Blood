extends "res://scripts/ui/widgets/overlay_base.gd"
## Corte / resumen de la casa (menu de Consejo): gobernante, heredero, consejeros,
## atributos, pretensiones y estado general del reino. Solo lecturas.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1240, 820)
	add_title("LA CORTE", "El soberano, su casa y los hombres que sostienen el trono")
	_body = add_body_scroll()
	add_footer("CERRAR")
	_rebuild()


func refresh() -> void:
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var fid := TSBGame.player_faction()
	var color := TSBGame.faction_color(fid)
	var faction_data := TSBGame.faction(fid)

	var header := UIKit.hbox(_body, 16)
	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(140, 168)
	shield.set("house", str(TSBGame.ruler(fid).get("house", fid)))
	shield.set("field_color", color)
	header.add_child(shield)
	var header_text := UIKit.vbox(header, 3)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(header_text, TSBGame.faction_name(fid), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var government := str(faction_data.get("government", "monarchy"))
	var government_label := UIKit.label(header_text, "Gobierno: %s" % government.replace("_", " ").capitalize(), "InkLabel")
	government_label.add_theme_font_size_override("font_size", 16)
	government_label.add_theme_color_override("font_color", Palette.CRIMSON)
	var date_label := UIKit.label(header_text, "Año %d · Trimestre %d · %d regiones" % [
		TSBGame.current_year(), TSBGame.current_quarter(), TSBGame.regions_owned_by(fid).size()], "InkLabel")
	date_label.add_theme_font_size_override("font_size", 15)
	date_label.add_theme_color_override("font_color", Palette.INK_TEXT)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_section("El soberano")
	var ruler := TSBGame.ruler(fid)
	if ruler.is_empty():
		var no_ruler := UIKit.label(_body, "No hay gobernante vivo: la sucesión debe resolverse.", "InkLabel")
		no_ruler.add_theme_font_size_override("font_size", 16)
	else:
		_character_block(ruler, color, true)
		_traits_of(ruler)
		_stats_of(ruler)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_section("El heredero")
	var heir := TSBGame.heir(fid)
	if heir.is_empty():
		var no_heir := UIKit.label(_body, "Sin heredero designado: riesgo de crisis sucesoria (GDD §5.3).", "InkLabel")
		no_heir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_heir.add_theme_font_size_override("font_size", 16)
		no_heir.add_theme_color_override("font_color", Palette.CRIMSON)
	else:
		_character_block(heir, color, false)
		_traits_of(heir)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_section("Casa y corte")
	var ruler_id := str(ruler.get("id", ""))
	var heir_id := str(heir.get("id", ""))
	var court_count := 0
	for member: Variant in TSBGame.family_members(fid):
		if not (member is Dictionary):
			continue
		var data := member as Dictionary
		var member_id := str(data.get("id", ""))
		if member_id == ruler_id or member_id == heir_id:
			continue
		if not bool(data.get("alive", false)):
			continue
		if str(data.get("role", "")) == "spouse":
			continue
		_character_block(data, color, false)
		court_count += 1
		if court_count >= 8:
			break
	if court_count == 0:
		var none := UIKit.label(_body, "La corte no registra otros miembros vivos.", "InkLabel")
		none.add_theme_font_size_override("font_size", 15)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_section("Estado del reino")
	var stats := UIKit.grid(_body, 4, 14, 5)
	_stat(stats, "Tesoro", "%d oro" % TSBGame.gold(fid))
	_stat(stats, "Prestigio", str(TSBGame.prestige(fid)))
	_stat(stats, "PG", "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)])
	_stat(stats, "Regiones", str(TSBGame.regions_owned_by(fid).size()))
	var army_count := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			army_count += 1
	_stat(stats, "Ejércitos", str(army_count))
	_stat(stats, "Heredero", str(heir.get("name", "—")))
	_stat(stats, "Casa real", "%d miembros" % TSBGame.family_members(fid).size())

	var claims: Variant = ruler.get("claims", [])
	if claims is Array and not (claims as Array).is_empty():
		UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
		_section("Pretensiones dinásticas")
		for claim: Variant in (claims as Array):
			if claim is Dictionary:
				var claim_data := claim as Dictionary
				var claim_label := UIKit.label(
					_body,
					"Pretensión sobre %s (fuerza %.2f)" % [TSBGame.faction_name(str(claim_data.get("target", ""))), float(claim_data.get("strength", 0.0))],
					"InkLabel")
				claim_label.add_theme_font_size_override("font_size", 15)
				claim_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _section(text: String) -> void:
	var title := UIKit.label(_body, text, "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)


func _character_block(member: Dictionary, color: Color, big: bool) -> void:
	var row := UIKit.hbox(_body, 12)
	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(86, 104) if big else Vector2(64, 78)
	shield.set("house", str(member.get("house", "")))
	shield.set("field_color", color)
	row.add_child(shield)
	var text := UIKit.vbox(row, 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(text, str(member.get("name", "—")), "InkLabel")
	name_label.add_theme_font_size_override("font_size", 22 if big else 18)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var detail := "Casa %s · %d años · %s" % [
		str(member.get("house", "—")).capitalize(),
		int(member.get("age", 0)),
		str(member.get("role", "")).capitalize(),
	]
	var detail_label := UIKit.label(text, detail, "InkLabel")
	detail_label.add_theme_font_size_override("font_size", 14)
	detail_label.add_theme_color_override("font_color", Palette.CRIMSON)


func _traits_of(member: Dictionary) -> void:
	var traits: Variant = member.get("traits", [])
	if not (traits is Array) or (traits as Array).is_empty():
		return
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	_body.add_child(flow)
	for trait_value: Variant in (traits as Array):
		UIKit.chip(flow, str(trait_value).replace("_", " "), Palette.PARCHMENT_DARK, Palette.INK_TEXT)


func _stats_of(member: Dictionary) -> void:
	var member_stats: Variant = member.get("stats", {})
	if not (member_stats is Dictionary) or (member_stats as Dictionary).is_empty():
		return
	var labels := {
		"command": "Mando",
		"intrigue": "Astucia",
		"charisma": "Carisma",
		"loyalty": "Lealtad",
		"education": "Educación",
	}
	var grid := UIKit.grid(_body, 5, 10, 3)
	for key: Variant in labels.keys():
		var box := UIKit.vbox(grid, 1)
		var key_label := UIKit.label(box, str(labels[key]), "InkLabel")
		key_label.add_theme_font_size_override("font_size", 13)
		key_label.add_theme_color_override("font_color", Palette.MUTED)
		var value := int((member_stats as Dictionary).get(key, 0))
		var value_label := UIKit.label(box, str(value), "InkLabel")
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
