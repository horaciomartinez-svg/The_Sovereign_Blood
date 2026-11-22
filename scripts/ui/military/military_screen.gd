extends "res://scripts/ui/widgets/overlay_base.gd"
## Pantalla militar (GDD §9.4/§9.3): lista de ejércitos, movimiento por
## adyacencia y creacion de ejército. Reclutamiento se detalla en el panel de
## region (MilitarySystem.recruit). Toda accion llama a la API de sistemas.

signal army_management_requested

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1320, 800)
	add_title("EJÉRCITOS DEL REINO", "Movimiento por adyacencia, creación y disolución de huestes")
	_body = add_body_scroll()
	var footer := add_footer("CERRAR")
	var management := UIKit.button(footer, "GESTIÓN GLOBAL", "SmallButton", "Reclutar, entrenar y disolver por tipo de unidad")
	management.pressed.connect(_open_management)
	management.move_to_front()
	_rebuild()


func _open_management() -> void:
	army_management_requested.emit()
	close_overlay()


func refresh() -> void:
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var fid := TSBGame.player_faction()
	var own_armies: Array = []
	var soldiers := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			own_armies.append(army)
			soldiers += TSBGame.army_soldiers(army)

	var stats := UIKit.grid(_body, 4, 14, 4)
	_stat(stats, "Ejércitos", str(own_armies.size()))
	_stat(stats, "Soldados", TSBGame.short_number(soldiers))
	_stat(stats, "Oro", str(TSBGame.gold(fid)))
	_stat(stats, "PG", "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)])

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var title := UIKit.label(_body, "Huestes desplegadas", "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)

	if own_armies.is_empty():
		var empty := UIKit.label(_body, "No hay ejércitos. Crea uno en una región propia para iniciar una campaña.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 15)
	else:
		for army: Variant in own_armies:
			if not (army is Dictionary):
				continue
			var army_dict := army as Dictionary
			var region_id := str(army_dict.get("region_id", ""))
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.15), Palette.with_alpha(Palette.GOLD_DIM, 0.5), 1, 4, 10, 7))
			_body.add_child(box)
			var column := UIKit.vbox(box, 4)
			var info := UIKit.hbox(column, 8)
			var marker := ColorRect.new()
			marker.color = TSBGame.faction_color(fid)
			marker.custom_minimum_size = Vector2(6, 24)
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			info.add_child(marker)
			var leader := TSBGame.character(str(army_dict.get("leader_id", "")))
			var text := UIKit.label(
				info,
				"%s · %s · %d soldados · moral %d%%%s" % [
					_army_name(army_dict, region_id),
					TSBGame.region_name(region_id),
					TSBGame.army_soldiers(army_dict),
					int(float(army_dict.get("morale", 1.0)) * 100.0),
					" · " + str(leader.get("name", "")) if not leader.is_empty() else "",
				],
				"InkLabel")
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.add_theme_font_size_override("font_size", 15)
			text.add_theme_color_override("font_color", Palette.INK_TEXT)

			var controls := UIKit.hbox(column, 6)
			var adjacent := TSBGame.region_adjacency(region_id)
			var picker := OptionButton.new()
			picker.custom_minimum_size = Vector2(240, 36)
			picker.add_theme_font_size_override("font_size", 14)
			if adjacent.is_empty():
				picker.add_item("Sin adyacencias")
				picker.disabled = true
			else:
				for adjacent_id: Variant in adjacent:
					var target := str(adjacent_id)
					var cost := TSBGame.move_cost(str(army_dict.get("id", "")), target)
					var cost_text := " · %d PG" % cost if cost >= 0 else ""
					picker.add_item(TSBGame.region_name(target) + cost_text)
					picker.set_item_metadata(picker.item_count - 1, target)
			controls.add_child(picker)
			var move_button := UIKit.button(controls, "Mover", "SmallButton")
			move_button.disabled = not TSBGame.has_game() or adjacent.is_empty()
			move_button.pressed.connect(func() -> void: _move(str(army_dict.get("id", "")), picker))
			var disband := UIKit.button(controls, "Disolver", "SmallButton")
			disband.disabled = not TSBGame.has_game()
			disband.pressed.connect(func() -> void: _disband(str(army_dict.get("id", ""))))

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var create_title := UIKit.label(_body, "Levantar un nuevo ejército", "InkLabel")
	create_title.add_theme_font_size_override("font_size", 21)
	create_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var owned := TSBGame.regions_owned_by(fid)
	if owned.is_empty():
		var no_regions := UIKit.label(_body, "No controlas ninguna región.", "InkLabel")
		no_regions.add_theme_font_size_override("font_size", 15)
		return
	var create_row := UIKit.hbox(_body, 8)
	var region_picker := OptionButton.new()
	region_picker.custom_minimum_size = Vector2(320, 38)
	for region_id: Variant in owned:
		region_picker.add_item(TSBGame.region_name(str(region_id)))
		region_picker.set_item_metadata(region_picker.item_count - 1, str(region_id))
	create_row.add_child(region_picker)
	var create_button := UIKit.button(create_row, "Crear ejército", "SmallButton", "MilitarySystem.create_army()")
	create_button.disabled = not TSBGame.has_game()
	create_button.pressed.connect(func() -> void: _create(region_picker))
	var hint := UIKit.label(_body, "El reclutamiento de unidades se realiza desde el panel de cada región (click en el mapa).", "InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.MUTED)


func _army_name(army: Dictionary, region_id: String) -> String:
	var army_id := str(army.get("id", ""))
	if army_id.begins_with("preview_army_"):
		return "Hueste de %s" % TSBGame.region_name(region_id)
	return army_id.replace("army_", "Hueste ").replace("_", " ").capitalize()


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _move(army_id: String, picker: OptionButton) -> void:
	if picker.item_count == 0 or picker.selected < 0:
		return
	var target := str(picker.get_item_metadata(picker.selected))
	TSBGame.move_army(army_id, target)
	_rebuild()


func _disband(army_id: String) -> void:
	TSBGame.disband_army(army_id)
	_rebuild()


func _create(region_picker: OptionButton) -> void:
	if region_picker.item_count == 0 or region_picker.selected < 0:
		return
	var region_id := str(region_picker.get_item_metadata(region_picker.selected))
	TSBGame.create_army(TSBGame.player_faction(), region_id)
	_rebuild()
