extends "res://scripts/ui/widgets/overlay_base.gd"
## Pantalla de diplomacia (GDD §9.6): relaciones, estado de tratados y propuestas
## con exito estimado. La aceptacion real la resuelve DiplomacySystem.propose();
## la UI solo llama a la API y muestra el resultado.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

const ACTIONS: Array[String] = [
	"alliance", "marriage", "trade_pact", "demand_tribute",
	"offer_tribute", "declare_war", "propose_peace",
]
const ACTION_LABELS := {
	"alliance": "Proponer alianza",
	"marriage": "Matrimonio dinástico",
	"trade_pact": "Pacto comercial",
	"demand_tribute": "Exigir tributo",
	"offer_tribute": "Ofrecer tributo",
	"declare_war": "Declarar la guerra",
	"propose_peace": "Proponer la paz",
}

var _target_id: String = ""
var _list_box: VBoxContainer = null
var _detail_box: VBoxContainer = null
var _status_label: Label = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1500, 860)
	add_title("DIPLOMACIA", "Relaciones entre coronas, tratados y propuestas de la corte")
	var split := UIKit.hbox(content, 14)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var left := UIKit.panel(split, "InsetPanel")
	left.custom_minimum_size = Vector2(430, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_margin := UIKit.margin(left, 10, 8, 10, 8)
	var left_scroll := ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(left_scroll)
	_list_box = UIKit.vbox(left_scroll, 6)
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var right := UIKit.panel(split, "ParchmentPanel")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_margin := UIKit.margin(right, 12, 10, 12, 10)
	var right_scroll := ScrollContainer.new()
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(right_scroll)
	_detail_box = UIKit.vbox(right_scroll, 8)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_footer("CERRAR")
	_select_default_target()
	refresh()


func refresh() -> void:
	_refresh_list()
	_rebuild_detail()


func _select_default_target() -> void:
	if not _target_id.is_empty():
		return
	var fid := TSBGame.player_faction()
	for faction_id: Variant in TSBGame.faction_ids():
		var other := str(faction_id)
		if other == fid:
			continue
		_target_id = other
		return


func _refresh_list() -> void:
	if _list_box == null:
		return
	UIKit.clear(_list_box)
	var fid := TSBGame.player_faction()
	for faction_id: Variant in TSBGame.faction_ids():
		var other := str(faction_id)
		if other == fid:
			continue
		var relation := TSBGame.relation(fid, other)
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", Palette.stylebox(
			Palette.with_alpha(Palette.GOLD_DIM, 0.22) if other == _target_id else Color.TRANSPARENT,
			Palette.with_alpha(Palette.GOLD, 0.9) if other == _target_id else Color.TRANSPARENT,
			1, 4, 8, 5))
		_list_box.add_child(row)
		var column := UIKit.vbox(row, 3)
		var name_row := UIKit.hbox(column, 8)
		var marker := ColorRect.new()
		marker.color = TSBGame.faction_color(other)
		marker.custom_minimum_size = Vector2(7, 24)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_child(marker)
		var name_button := UIKit.button(name_row, TSBGame.faction_name(other), "GhostButton")
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_button.add_theme_font_size_override("font_size", 17)
		name_button.pressed.connect(func() -> void: _select_target(other))
		var relation_label := UIKit.label(name_row, "%+d" % relation, "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
		relation_label.add_theme_font_size_override("font_size", 16)
		relation_label.add_theme_color_override("font_color", Palette.relation_color(relation))
		var bar := UIKit.bar(column, relation + 100, 200, Palette.relation_color(relation), 8)
		var status := ""
		if TSBGame.are_at_war(fid, other):
			status = "EN GUERRA"
		elif TSBGame.are_allied(fid, other):
			status = "ALIADOS"
		if not status.is_empty():
			var status_label := UIKit.label(column, status, "TinyLabel")
			status_label.add_theme_font_size_override("font_size", 12)
			status_label.add_theme_color_override("font_color", Palette.CRIMSON_BRIGHT if status == "EN GUERRA" else Palette.GREEN_BRIGHT)


func _select_target(target_id: String) -> void:
	_target_id = target_id
	refresh()


func _rebuild_detail() -> void:
	if _detail_box == null:
		return
	UIKit.clear(_detail_box)
	if _target_id.is_empty():
		var empty := UIKit.label(_detail_box, "Selecciona una corona en la lista.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var fid := TSBGame.player_faction()
	var relation := TSBGame.relation(fid, _target_id)
	var at_war := TSBGame.are_at_war(fid, _target_id)
	var allied := TSBGame.are_allied(fid, _target_id)

	var header := UIKit.hbox(_detail_box, 14)
	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(104, 124)
	shield.set("house", str(TSBGame.ruler(_target_id).get("house", _target_id)))
	shield.set("field_color", TSBGame.faction_color(_target_id))
	header.add_child(shield)
	var header_text := UIKit.vbox(header, 2)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(header_text, TSBGame.faction_name(_target_id), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 27)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var ruler := TSBGame.ruler(_target_id)
	var ruler_label := UIKit.label(header_text, "Gobernante: %s" % str(ruler.get("name", "—")), "InkLabel")
	ruler_label.add_theme_font_size_override("font_size", 16)
	var status_text := "En guerra" if at_war else ("Aliados" if allied else "Neutral")
	var status_label := UIKit.label(header_text, "Relación: %+d · %s" % [relation, status_text], "InkLabel")
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Palette.relation_color(relation))

	var relation_bar := UIKit.bar(_detail_box, relation + 100, 200, Palette.relation_color(relation), 16)
	relation_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var actions_title := UIKit.label(_detail_box, "Propuestas", "InkLabel")
	actions_title.add_theme_font_size_override("font_size", 21)
	actions_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var hint := UIKit.label(
		_detail_box,
		"Éxito estimado por la corte (la aceptación real la decide DiplomacySystem.propose). El coste en PG lo cobra el sistema, nunca la UI.",
		"InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.MUTED)

	var grid := UIKit.grid(_detail_box, 2, 10, 6)
	for action_id: String in ACTIONS:
		_action_button(grid, action_id, at_war, allied)

	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_marriage_section(at_war)

	_status_label = UIKit.label(_detail_box, "", "InkLabel")
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Palette.CRIMSON)


func _action_button(parent: Node, action_id: String, at_war: bool, allied: bool) -> void:
	var box := UIKit.vbox(parent, 2)
	var cost := TSBGame.action_cost(action_id)
	var estimate := _estimate(action_id)
	var label := "%s  ·  %s" % [str(ACTION_LABELS[action_id]), "%d PG" % cost if cost >= 0 else "PG?"]
	var button := UIKit.button(box, label, "SmallButton", "Estima un %d%% de aceptación" % estimate)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 40)
	var disabled := not TSBGame.has_game()
	if action_id == "declare_war" and (at_war or allied):
		disabled = true
	if action_id == "propose_peace" and not at_war:
		disabled = true
	if action_id == "alliance" and (at_war or allied):
		disabled = true
	if action_id in ["trade_pact", "demand_tribute"] and at_war:
		disabled = true
	if action_id == "marriage" and at_war:
		disabled = true
	button.disabled = disabled
	if action_id != "marriage":
		button.pressed.connect(func() -> void: _propose(action_id, {}))
	var estimate_label := UIKit.label(box, "Éxito estimado: %d%%" % estimate, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	estimate_label.add_theme_font_size_override("font_size", 12)
	estimate_label.add_theme_color_override("font_color", Palette.MUTED)


func _estimate(action_id: String) -> int:
	var fid := TSBGame.player_faction()
	var relation := TSBGame.relation(fid, _target_id)
	var value := 50.0 + float(relation) * 0.5
	match action_id:
		"alliance":
			value -= 15.0
		"marriage":
			value += 5.0
		"trade_pact":
			value += 10.0
		"demand_tribute":
			value -= 25.0
		"offer_tribute":
			value += 25.0
		"declare_war":
			value += 40.0
		"propose_peace":
			value += 10.0
	var ruler := TSBGame.ruler(fid)
	var ruler_stats: Variant = ruler.get("stats", {})
	if ruler_stats is Dictionary:
		value += (float(int((ruler_stats as Dictionary).get("charisma", 50))) - 50.0) / 5.0
	return clampi(int(round(value)), 5, 95)


func _marriage_section(at_war: bool) -> void:
	var title := UIKit.label(_detail_box, "Matrimonio entre casas", "InkLabel")
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var fid := TSBGame.player_faction()
	var our_candidates := _unmarried_members(fid)
	var their_candidates := _unmarried_members(_target_id)
	if at_war:
		var war_note := UIKit.label(_detail_box, "No se puede concertar matrimonio durante una guerra.", "InkLabel")
		war_note.add_theme_font_size_override("font_size", 14)
		return
	if our_candidates.is_empty() or their_candidates.is_empty():
		var empty := UIKit.label(_detail_box, "Sin candidatos casaderos en una u otra casa.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 14)
		return
	var row := UIKit.hbox(_detail_box, 8)
	var our_picker := OptionButton.new()
	our_picker.custom_minimum_size = Vector2(0, 38)
	our_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	our_picker.add_theme_font_size_override("font_size", 13)
	for candidate: Variant in our_candidates:
		var data := candidate as Dictionary
		our_picker.add_item("%s (%d)" % [str(data.get("name", "—")), TSBGame.character_age(data)])
		our_picker.set_item_metadata(our_picker.item_count - 1, str(data.get("id", "")))
	row.add_child(our_picker)
	var their_picker := OptionButton.new()
	their_picker.custom_minimum_size = Vector2(0, 38)
	their_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	their_picker.add_theme_font_size_override("font_size", 13)
	for candidate: Variant in their_candidates:
		var data := candidate as Dictionary
		their_picker.add_item("%s (%d)" % [str(data.get("name", "—")), TSBGame.character_age(data)])
		their_picker.set_item_metadata(their_picker.item_count - 1, str(data.get("id", "")))
	row.add_child(their_picker)
	var propose := UIKit.button(row, "Proponer", "SmallButton")
	propose.disabled = not TSBGame.has_game()
	propose.tooltip_text = "Inicia una partida para concertar matrimonios"
	propose.pressed.connect(func() -> void: _propose_marriage(our_picker, their_picker))


func _unmarried_members(faction_id: String) -> Array:
	var out: Array = []
	for member: Variant in TSBGame.family_members(faction_id):
		if not (member is Dictionary):
			continue
		var data := member as Dictionary
		if not bool(data.get("alive", false)):
			continue
		if not TSBGame.character_spouse(data).is_empty():
			continue
		if TSBGame.character_age(data) < 14:
			continue
		out.append(data)
	return out


func _propose_marriage(our_picker: OptionButton, their_picker: OptionButton) -> void:
	if our_picker.item_count == 0 or their_picker.item_count == 0:
		return
	var actor_character := str(our_picker.get_item_metadata(our_picker.selected))
	var target_character := str(their_picker.get_item_metadata(their_picker.selected))
	_propose("marriage", {
		"actor_character": actor_character,
		"target_character": target_character,
	})


func _propose(action_id: String, extra: Dictionary) -> void:
	var fid := TSBGame.player_faction()
	var action := {"type": action_id}
	for key: Variant in extra.keys():
		action[key] = extra[key]
	var result := TSBGame.propose(fid, _target_id, action)
	if _status_label != null:
		_status_label.text = _result_text(action_id, result)
	refresh()


func _result_text(action_id: String, result: Dictionary) -> String:
	if result.is_empty():
		return "Los sistemas de diplomacia aún no procesan propuestas (integración pendiente con AG-2)."
	if not bool(result.get("ok", true)):
		return "Propuesta no válida: %s" % str(result.get("reason", "revisa los requisitos"))
	var accepted := bool(result.get("accepted", false))
	var cost := int(result.get("cost_pg", 0))
	if accepted:
		return "Propuesta aceptada (%s). Coste: %d PG." % [str(ACTION_LABELS[action_id]), cost]
	return "Propuesta rechazada (%s). %s" % [str(ACTION_LABELS[action_id]), str(result.get("reason", ""))]
