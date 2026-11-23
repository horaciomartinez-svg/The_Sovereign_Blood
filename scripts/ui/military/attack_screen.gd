extends "res://scripts/ui/widgets/overlay_base.gd"
## D-084: Militar → Atacar. Elige una región adyacente no propia y una o varias
## huestes elegibles. La UI solo llama a TSBGame.attack_region; el motor valida
## adyacencia, PG, aliados y declara la guerra automáticamente si procede.

signal battle_report_requested(report: Dictionary)

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null
var _target_picker: OptionButton = null
var _target_info: Label = null
var _army_box: VBoxContainer = null
var _summary: Label = null
var _result_box: VBoxContainer = null
var _war_panel: PanelContainer = null
var _war_text: Label = null
var _attack_button: Button = null
var _candidate_ids: Array[String] = []
var _checks: Array[CheckBox] = []
var _selected_target := ""


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1120, 820)
	add_title("ATACAR", "Objetivo, huestes y guerra: prepara tu ofensiva")
	_body = add_body_scroll()
	_build_target_section()
	_build_army_section()
	_result_box = UIKit.vbox(_body, 6)
	_summary = UIKit.label(_body, "", "InkLabel")
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.add_theme_font_size_override("font_size", 15)
	_summary.add_theme_color_override("font_color", Palette.INK_TEXT)
	var footer := add_footer("CERRAR")
	_attack_button = UIKit.button(footer, "ATACAR...", "PrimaryButton", "Revisar la guerra y confirmar")
	_attack_button.name = "attack_button"
	_attack_button.custom_minimum_size = Vector2(220, 46)
	_attack_button.disabled = true
	_attack_button.pressed.connect(_on_attack_pressed)
	_build_war_panel()
	_rebuild_targets()


func _build_war_panel() -> void:
	_war_panel = PanelContainer.new()
	_war_panel.anchor_left = 0.5
	_war_panel.anchor_right = 0.5
	_war_panel.anchor_top = 0.5
	_war_panel.anchor_bottom = 0.5
	_war_panel.offset_left = -360
	_war_panel.offset_right = 360
	_war_panel.offset_top = -170
	_war_panel.offset_bottom = 170
	_war_panel.z_index = 140
	_war_panel.visible = false
	_war_panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.PARCHMENT_LIGHT, Palette.GOLD_DIM, 2, 6, 22, 18))
	add_child(_war_panel)
	var column := UIKit.vbox(_war_panel, 10)
	var title := UIKit.label(column, "CONFIRMAR ATAQUE", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	_war_text = UIKit.label(column, "", "InkLabel")
	_war_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_war_text.add_theme_font_size_override("font_size", 16)
	_war_text.add_theme_color_override("font_color", Palette.INK_TEXT)
	var row := UIKit.hbox(column, 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	var cancel := UIKit.button(row, "CORREGIR", "SmallButton")
	cancel.pressed.connect(func() -> void: _war_panel.visible = false)
	var confirm := UIKit.button(row, "CONFIRMAR ATAQUE", "PrimaryButton")
	confirm.name = "attack_confirm_button"
	confirm.pressed.connect(func() -> void:
		_war_panel.visible = false
		_perform_attack()
	)


func _build_target_section() -> void:
	var title := UIKit.label(_body, "Objetivo", "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var row := UIKit.hbox(_body, 10)
	var label := UIKit.label(row, "Región adyacente", "InkLabel")
	label.custom_minimum_size = Vector2(180, 0)
	_target_picker = OptionButton.new()
	_target_picker.custom_minimum_size = Vector2(420, 38)
	_target_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_picker.item_selected.connect(_on_target_changed)
	row.add_child(_target_picker)
	_target_info = UIKit.label(_body, "", "InkLabel")
	_target_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_target_info.add_theme_font_size_override("font_size", 14)
	_target_info.add_theme_color_override("font_color", Palette.MUTED)


func _build_army_section() -> void:
	var title := UIKit.label(_body, "Huestes elegibles", "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var hint := UIKit.label(_body, "Selecciona una o varias huestes propias en una región adyacente al objetivo. Las acciones militares son repetibles.", "InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.MUTED)
	_army_box = UIKit.vbox(_body, 5)


func _rebuild_targets() -> void:
	_candidate_ids.clear()
	_target_picker.clear()
	var fid := TSBGame.player_faction()
	var seen: Dictionary = {}
	for owned: Variant in TSBGame.regions_owned_by(fid):
		for adjacent: Variant in TSBGame.region_adjacency(str(owned)):
			var target := str(adjacent)
			if seen.has(target):
				continue
			var owner := TSBGame.region_owner(target)
			if owner == fid:
				continue
			seen[target] = true
			_candidate_ids.append(target)
			var suffix := ""
			if not owner.is_empty() and TSBGame.are_allied(fid, owner):
				suffix = " · ALIADA"
			elif not owner.is_empty() and TSBGame.are_at_war(fid, owner):
				suffix = " · EN GUERRA"
			_target_picker.add_item(TSBGame.region_name(target) + suffix)
			_target_picker.set_item_metadata(_target_picker.item_count - 1, target)
	if _candidate_ids.is_empty():
		_target_picker.add_item("Sin regiones enemigas adyacentes")
		_target_picker.disabled = true
		_target_info.text = "Mueve una hueste a una frontera con otro reino para poder atacar."
		_attack_button.disabled = true
		return
	_target_picker.disabled = false
	_target_picker.select(0)
	_selected_target = _candidate_ids[0]
	_refresh_target()


func _on_target_changed(index: int) -> void:
	if index < 0 or index >= _target_picker.item_count:
		return
	_selected_target = str(_target_picker.get_item_metadata(index))
	_refresh_target()


func _refresh_target() -> void:
	UIKit.clear(_army_box)
	for child: Node in _result_box.get_children():
		child.queue_free()
	_checks.clear()
	if _selected_target.is_empty():
		return
	var fid := TSBGame.player_faction()
	var owner := TSBGame.region_owner(_selected_target)
	var owner_name := TSBGame.faction_name(owner) if not owner.is_empty() else "independiente"
	var war_text := "En guerra con %s." % owner_name if not owner.is_empty() and TSBGame.are_at_war(fid, owner) else "Sin guerra con %s: se declarará automáticamente al confirmar." % owner_name
	if not owner.is_empty() and TSBGame.are_allied(fid, owner):
		war_text = "%s es aliada: no puedes atacarla sin romper la alianza." % owner_name
	_target_info.text = "Objetivo: %s · propietario: %s. %s" % [TSBGame.region_name(_selected_target), owner_name, war_text]
	_build_eligible_armies(_selected_target)


func _build_eligible_armies(target: String) -> void:
	var fid := TSBGame.player_faction()
	var eligible: Array = []
	var count := 0
	for army_value: Variant in TSBGame.armies().values():
		if not (army_value is Dictionary):
			continue
		var army: Dictionary = army_value
		if str(army.get("faction_id", "")) != fid:
			continue
		var region := str(army.get("region_id", ""))
		if not TSBGame.region_adjacency(region).has(target):
			continue
		var movement := int(army.get("movement_left", 2))
		var cost := TSBGame.move_cost(str(army.get("id", "")), target)
		if movement <= 0 or cost < 0:
			continue
		eligible.append(army)
		var check := CheckBox.new()
		check.text = "%s · %s · %d soldados · %d PG" % [
			_army_label(army), TSBGame.region_name(region), TSBGame.army_soldiers(army), cost]
		check.set_meta("army_id", str(army.get("id", "")))
		check.add_theme_font_size_override("font_size", 15)
		check.button_pressed = true
		check.toggled.connect(func(_pressed: bool) -> void: _update_summary())
		_army_box.add_child(check)
		_checks.append(check)
		count += 1
	if count == 0:
		var none := UIKit.label(_army_box, "No hay huestes propias adyacentes con movimiento disponible.", "InkLabel")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.add_theme_font_size_override("font_size", 14)
		none.add_theme_color_override("font_color", Palette.MUTED)
	_update_summary()


func _update_summary() -> void:
	var ids := _selected_armies()
	var pg := 0
	for army_id in ids:
		pg += maxi(0, TSBGame.move_cost(army_id, _selected_target))
	var owner := TSBGame.region_owner(_selected_target)
	var fid := TSBGame.player_faction()
	var allied := not owner.is_empty() and TSBGame.are_allied(fid, owner)
	var at_war := not owner.is_empty() and TSBGame.are_at_war(fid, owner)
	var text := "Huestes seleccionadas: %d · PG total: %d/%d." % [ids.size(), pg, TSBGame.pg_remaining()]
	if not owner.is_empty() and not at_war and not allied:
		var prestige_cost := TSBGame.war_prestige_cost(fid, owner)
		text += "\nSi no hay guerra con %s, se declarará automáticamente al confirmar" % TSBGame.faction_name(owner)
		if prestige_cost > 0:
			text += "; coste previsto de prestigio: %d." % prestige_cost
		else:
			text += "; hay casus belli, sin coste de prestigio."
	if allied:
		text += "\nObjetivo aliado bloqueado: no se puede atacar sin romper la alianza."
	if not ids.is_empty() and pg > TSBGame.pg_remaining():
		text += "\nPG insuficientes."
	_summary.text = text
	_attack_button.disabled = ids.is_empty() or allied or pg <= 0 or pg > TSBGame.pg_remaining()


func _selected_armies() -> Array:
	var ids: Array = []
	for check in _checks:
		if check.button_pressed:
			ids.append(str(check.get_meta("army_id", "")))
	return ids


func _army_label(army: Dictionary) -> String:
	var id := str(army.get("id", ""))
	return "Hueste " + id.replace("army_", "").replace("_", " ").capitalize()


func _on_attack_pressed() -> void:
	if _selected_target.is_empty() or _selected_armies().is_empty():
		return
	var owner := TSBGame.region_owner(_selected_target)
	var preview := TSBGame.attack_preview(TSBGame.player_faction(), _selected_target, _selected_armies())
	var war_note := "Si no hay guerra, se declarará automáticamente."
	var prestige := TSBGame.war_prestige_cost(TSBGame.player_faction(), owner)
	if prestige > 0:
		war_note += " Coste de prestigio: %d (sin casus belli)." % prestige
	elif not owner.is_empty() and not TSBGame.are_at_war(TSBGame.player_faction(), owner):
		war_note += " Hay casus belli, sin coste de prestigio."
	if not owner.is_empty() and TSBGame.are_at_war(TSBGame.player_faction(), owner):
		war_note = "Ya estás en guerra con %s; se resolverán los choques." % TSBGame.faction_name(owner)
	_war_text.text = "Atacar %s con %d hueste(s).\n%s\nPG total: %d." % [
		TSBGame.region_name(_selected_target), _selected_armies().size(), war_note,
		_summary_pg()]
	_war_panel.visible = true


func _summary_pg() -> int:
	var pg := 0
	for army_id in _selected_armies():
		pg += maxi(0, TSBGame.move_cost(army_id, _selected_target))
	return pg


func _perform_attack() -> void:
	if _war_panel != null:
		_war_panel.visible = false
	var result := TSBGame.attack_region(TSBGame.player_faction(), _selected_target, _selected_armies())
	UIKit.clear(_result_box)
	var title := UIKit.label(_result_box, "Resultado del ataque", "InkLabel")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	if not bool(result.get("ok", false)):
		var error := UIKit.label(_result_box, "No se pudo atacar: %s." % str(result.get("reason", "motivo desconocido")), "InkLabel")
		error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error.add_theme_font_size_override("font_size", 15)
		error.add_theme_color_override("font_color", Palette.CRIMSON)
		return
	TSBGame.tutorial_advance("attack_launched")
	var declared := bool(result.get("declared_war", false))
	var header := "Ataque resuelto%s · PG gastados: %d." % [
		" · guerra declarada automáticamente" if declared else "", int(result.get("pg_spent", 0))]
	var header_label := UIKit.label(_result_box, header, "InkLabel")
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_label.add_theme_font_size_override("font_size", 15)
	header_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var results: Variant = result.get("results", [])
	if results is Array:
		for entry_value: Variant in (results as Array):
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			var moved := bool(entry.get("moved", false))
			var battle: Variant = entry.get("battle", null)
			var line := "%s: %s%s" % [
				_army_label({"id": str(entry.get("army_id", ""))}),
				"movida" if moved else "no movida",
				" · batalla resuelta" if battle != null and battle is Dictionary else "",
			]
			var label := UIKit.label(_result_box, line, "InkLabel")
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 14)
			if battle is Dictionary and not (battle as Dictionary).is_empty():
				var report := UIKit.button(_result_box, "VER INFORME DE BATALLA", "SmallButton")
				report.pressed.connect(func() -> void: battle_report_requested.emit(battle))


func _set_status(text: String) -> void:
	if _summary != null:
		_summary.text = text
