extends "res://scripts/ui/widgets/overlay_base.gd"
## Informe de batalla delegada (Nivel 1, GDD §9.7). Se abre al recibir
## BattleManager.battle_resolved (EventBus.battle_resolved). Sin deshacer.

const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _report: Dictionary = {}
var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1180, 760)
	add_title("INFORME DE BATALLA", "El resultado es definitivo: no hay deshacer (§9.7)")
	_body = add_body_scroll()
	add_footer("CERRAR")
	_rebuild()


func setup(report_data: Variant) -> void:
	if report_data is Dictionary:
		_report = report_data
	else:
		_report = {}
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	if _report.is_empty():
		var empty := UIKit.label(_body, "Sin informe de batalla disponible. Se mostrará aquí en cuanto BattleManager resuelva un combate delegado (AG-2).", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return

	var attacker := str(_report.get("attacker_faction", ""))
	var defender := str(_report.get("defender_faction", ""))
	var region_id := str(_report.get("region_id", ""))
	var winner := str(_report.get("winner_faction", ""))
	var result := "Victoria de %s" % TSBGame.faction_name(winner) if not winner.is_empty() else "Batalla indecisa"
	var result_color := Palette.GREEN if winner == TSBGame.player_faction() else Palette.CRIMSON
	if winner.is_empty():
		result_color = Palette.GOLD_DIM

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(result_color, 0.20), result_color, 2, 5, 14, 8))
	_body.add_child(banner)
	var banner_label := UIKit.label(banner, result, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.add_theme_font_size_override("font_size", 26)
	banner_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var where := UIKit.label(_body, "En %s · año %d, trimestre %d" % [TSBGame.region_name(region_id), TSBGame.current_year(), TSBGame.current_quarter()], "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	where.add_theme_font_size_override("font_size", 16)
	where.add_theme_color_override("font_color", Palette.CRIMSON)

	var sides := UIKit.hbox(_body, 16)
	_side_panel(sides, attacker, "ATACANTE", int(_report.get("attacker_losses", 0)), "attacker_army_id")
	var middle := UIKit.vbox(sides, 2)
	middle.custom_minimum_size = Vector2(180, 0)
	var vs := UIKit.label(middle, "FRENTE", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	vs.add_theme_font_size_override("font_size", 18)
	vs.add_theme_color_override("font_color", Palette.CRIMSON)
	var region_label := UIKit.label(middle, TSBGame.region_name(region_id), "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	region_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	region_label.add_theme_font_size_override("font_size", 15)
	_side_panel(sides, defender, "DEFENSOR", int(_report.get("defender_losses", 0)), "defender_army_id")

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var rounds_title := UIKit.label(_body, "Asaltos", "InkLabel")
	rounds_title.add_theme_font_size_override("font_size", 21)
	rounds_title.add_theme_color_override("font_color", Palette.CRIMSON)

	var rounds: Variant = _report.get("rounds", [])
	if rounds is Array and not (rounds as Array).is_empty():
		var grid := UIKit.grid(_body, 3, 10, 4)
		_header_cell(grid, "Asalto")
		_header_cell(grid, "Bajas atacante")
		_header_cell(grid, "Bajas defensor")
		for i in range((rounds as Array).size()):
			var round_entry: Variant = (rounds as Array)[i]
			if not (round_entry is Dictionary):
				continue
			var round_dict := round_entry as Dictionary
			var number := int(round_dict.get("round", round_dict.get("assault", i + 1)))
			_cell(grid, "Asalto %d" % number)
			_cell(grid, str(_first_value(round_dict, ["attacker_damage", "attacker_losses", "attacker_casualties", "attacker"], "—")))
			_cell(grid, str(_first_value(round_dict, ["defender_damage", "defender_losses", "defender_casualties", "defender"], "—")))
	else:
		var no_rounds := UIKit.label(_body, "El informe no detalla asaltos (resolución directa).", "InkLabel")
		no_rounds.add_theme_font_size_override("font_size", 15)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var spoils_title := UIKit.label(_body, "Capturas y botín", "InkLabel")
	spoils_title.add_theme_font_size_override("font_size", 21)
	spoils_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var spoils := UIKit.grid(_body, 2, 12, 4)
	_spoils_row(spoils, "Botín", _loot_text())
	_spoils_row(spoils, "Prisioneros", _prisoners_text())
	_spoils_row(spoils, "Líder enemigo", _leader_text())
	_spoils_row(spoils, "Región capturada", "Sí" if bool(_report.get("region_captured", false)) else "No")

	if bool(_report.get("region_captured", false)) and not winner.is_empty():
		var capture := UIKit.label(_body, "%s ocupa %s." % [TSBGame.faction_name(winner), TSBGame.region_name(region_id)], "InkLabel")
		capture.add_theme_font_size_override("font_size", 17)
		capture.add_theme_color_override("font_color", Palette.CRIMSON)

	var notes := str(_report.get("notes", ""))
	if not notes.is_empty():
		var notes_box := PanelContainer.new()
		notes_box.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.25), Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 4, 10, 6))
		_body.add_child(notes_box)
		var notes_label := UIKit.label(notes_box, notes, "InkLabel")
		notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notes_label.add_theme_font_size_override("font_size", 15)

	var power_text := _power_text()
	if not power_text.is_empty():
		var power_label := UIKit.label(_body, power_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		power_label.add_theme_font_size_override("font_size", 14)
		power_label.add_theme_color_override("font_color", Palette.CRIMSON)

	var extra := _unknown_keys_text()
	if not extra.is_empty():
		var extra_label := UIKit.label(_body, "Detalles: " + extra, "InkLabel")
		extra_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		extra_label.add_theme_font_size_override("font_size", 13)
		extra_label.add_theme_color_override("font_color", Palette.MUTED)


func _power_text() -> String:
	var attacker: Variant = _first_value(_report, ["attacker_start_power", "attacker_power"], null)
	var defender: Variant = _first_value(_report, ["defender_start_power", "defender_power"], null)
	if attacker == null and defender == null:
		return ""
	return "Poder inicial estimado — atacante: %s · defensor: %s" % [_format_power(attacker), _format_power(defender)]


func _format_power(value: Variant) -> String:
	if value == null:
		return "—"
	if value is float or value is int:
		return "%.1f" % float(value)
	return str(value)


func _side_panel(parent: Node, faction_id: String, role_text: String, losses: int, army_key: String = "") -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.16), Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 4, 12, 8))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var row := UIKit.hbox(panel, 12)
	# Slot §10.2 (4): retrato del lider de cada bando.
	var leader: Dictionary = {}
	var army_id := str(_report.get(army_key, "")) if not army_key.is_empty() else ""
	if not army_id.is_empty():
		var army := TSBGame.army(army_id)
		var leader_id := str(army.get("leader_id", ""))
		if not leader_id.is_empty():
			leader = TSBGame.character(leader_id)
	if leader.is_empty():
		leader = TSBGame.ruler(faction_id)
	var portrait: Control = PortraitFrame.make(str(leader.get("id", "")), Vector2(84, 98))
	if portrait != null:
		row.add_child(portrait)
	var text := UIKit.vbox(row, 3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role_label := UIKit.label(text, role_text, "InkLabel")
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Palette.CRIMSON)
	var name_label := UIKit.label(text, TSBGame.faction_name(faction_id), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not leader.is_empty():
		var leader_label := UIKit.label(text, "Líder: %s" % str(leader.get("name", "—")), "InkLabel")
		leader_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		leader_label.add_theme_font_size_override("font_size", 14)
		leader_label.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.2))
	var losses_label := UIKit.label(text, "Bajas: %s" % TSBGame.short_number(losses), "InkLabel")
	losses_label.add_theme_font_size_override("font_size", 17)
	losses_label.add_theme_color_override("font_color", Palette.CRIMSON)


func _header_cell(parent: Node, text: String) -> void:
	var label := UIKit.label(parent, text, "InkLabel")
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Palette.CRIMSON)


func _cell(parent: Node, text: String) -> void:
	var label := UIKit.label(parent, text, "InkLabel")
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _spoils_row(parent: Node, label_text: String, value: Variant) -> void:
	_header_cell(parent, label_text)
	var value_text := "—"
	if value != null and not (value is String and str(value).is_empty()):
		value_text = str(value)
	_cell(parent, value_text)


func _first_value(dictionary: Dictionary, keys: Array, fallback: Variant) -> Variant:
	for key: Variant in keys:
		if dictionary.has(key):
			return dictionary[key]
	return fallback


func _loot_text() -> String:
	if _report.has("loot_gold"):
		return "%s oro" % TSBGame.short_number(int(_report.get("loot_gold", 0)))
	var loot: Variant = _report.get("loot", null)
	if loot is Dictionary:
		var parts: Array[String] = []
		for key: Variant in (loot as Dictionary).keys():
			parts.append("%s: %s" % [str(key), str((loot as Dictionary)[key])])
		return ", ".join(parts) if not parts.is_empty() else "—"
	if loot is String and not str(loot).is_empty():
		return str(loot)
	return "—"


func _prisoners_text() -> String:
	for key: String in ["prisoners", "captured", "captures"]:
		if _report.has(key):
			var value: Variant = _report[key]
			if value is bool:
				return "Sí" if bool(value) else "No"
			return str(value)
	return "—"


func _leader_text() -> String:
	if bool(_report.get("leader_killed", false)):
		return "Caído"
	if _report.has("captured_leader"):
		return "Sí" if _report.get("captured_leader") is String and not str(_report.get("captured_leader")).is_empty() else ("Sí" if bool(_report.get("captured_leader")) else "No")
	if bool(_report.get("leader_captured", false)):
		return "Capturado"
	return "—"


func _unknown_keys_text() -> String:
	var known := [
		"attacker_faction", "defender_faction", "region_id", "winner_faction",
		"attacker_losses", "defender_losses", "rounds", "region_captured", "notes",
		"loot", "loot_gold", "spoils", "booty", "prisoners", "captured", "captures",
		"captured_leader", "leader_captured", "leader_killed", "captive",
		"attacker_power", "defender_power", "attacker_start_power", "defender_start_power",
		"attacker_army", "defender_army", "attacker_army_id", "defender_army_id",
	]
	var extras: Array[String] = []
	for key: Variant in _report.keys():
		var key_text := str(key)
		if known.has(key_text):
			continue
		var value: Variant = _report[key]
		if value is Dictionary or value is Array:
			continue
		extras.append("%s: %s" % [key_text.replace("_", " "), str(value)])
	if extras.size() > 5:
		extras = extras.slice(0, 5)
	return " · ".join(extras)
