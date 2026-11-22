extends Control
## Panel de region (GDD §9.3): asignar mano de obra, edificios, reclutar y
## mover ejércitos. Toda accion llama a la API de los sistemas; el panel solo
## repinta con getters. En vista previa (sistemas stub) muestra datos y desactiva
## las ordenes que requieren partida activa.

signal closed
signal action_result(message: String, ok: bool)
signal battle_requested(attacker_army_id: String, defender_army_id: String, region_id: String)

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")

const WORKER_ORDER: Array[String] = ["farmers", "artisans", "merchants", "recruits"]
const WORKER_LABELS := {
	"farmers": "Campesinos",
	"artisans": "Artesanos",
	"merchants": "Comerciantes",
	"recruits": "Reclutas",
}
const WORKER_HINTS := {
	"farmers": "alimento",
	"artisans": "bienes",
	"merchants": "comercio",
	"recruits": "soldados",
}
const BUILDING_LABELS := {
	"castle": "Castillo",
	"market": "Mercado",
	"walls": "Murallas",
	"granary": "Granero",
	"shipyard": "Astillero",
	"workshops": "Talleres",
	"cathedral": "Catedral",
	"university": "Universidad",
	"mine": "Mina",
}
const STEP := 25

var region_id: String = ""
var _title_label: Label = null
var _subtitle_label: Label = null
var _content: VBoxContainer = null
var _scroll: ScrollContainer = null
var _footer: Label = null


func _ready() -> void:
	UIKit.apply_theme(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	UIHelp.add_button(self, "region_panel")
	clip_contents = true
	_build()
	visible = false


func _build() -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := UIKit.margin(panel, 18, 16, 18, 14)
	var column := UIKit.vbox(margin, 8)

	var header := UIKit.hbox(column, 10)
	var header_text := UIKit.vbox(header, 1)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label = UIKit.label(header_text, "Región", "InkLabel")
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label = UIKit.label(header_text, "", "InkLabel")
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_color_override("font_color", Palette.CRIMSON)
	var close_button := UIKit.button(header, "X", "SmallButton", "Cerrar el panel de región")
	close_button.custom_minimum_size = Vector2(44, 40)
	close_button.pressed.connect(func() -> void: closed.emit())

	UIKit.hsep(column)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	var scroll_margin := UIKit.margin(_scroll, 2, 2, 10, 2)
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content = UIKit.vbox(scroll_margin, 10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	UIKit.hsep(column)
	_footer = UIKit.label(column, "", "TinyLabel")
	_footer.add_theme_font_size_override("font_size", 13)
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer.add_theme_color_override("font_color", Palette.MUTED)


func open(region: String) -> void:
	region_id = region
	visible = true
	refresh()


func refresh() -> void:
	if _content == null or region_id.is_empty():
		return
	UIKit.clear(_content)
	var data := TSBGame.region(region_id)
	var owner := str(data.get("owner", ""))
	var owner_name := TSBGame.faction_name(owner) if not owner.is_empty() else "Independiente"
	_title_label.text = str(data.get("name", region_id))
	_subtitle_label.text = owner_name
	var owner_color := TSBGame.faction_color(owner) if not owner.is_empty() else Palette.MUTED
	_subtitle_label.add_theme_color_override("font_color", owner_color.darkened(0.25))

	_build_overview(data, owner)
	_build_workers(data)
	_build_buildings(data)
	_build_armies(data)
	_build_recruitment(data)
	_footer.text = "Las órdenes consumen PG. En vista previa (sistemas en integración) permanecen desactivadas."


func _build_overview(data: Dictionary, owner: String) -> void:
	var section := _section("Señorío")
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 5)
	section.add_child(chips)
	UIKit.chip(chips, _terrain_name(str(data.get("terrain", ""))), Palette.INK_SOFT)
	if bool(data.get("has_city", false)):
		UIKit.chip(chips, "Ciudad", Palette.CRIMSON.darkened(0.2))
	var buildings_count: Variant = data.get("buildings", [])
	if buildings_count is Array:
		UIKit.chip(chips, "%d edificios" % (buildings_count as Array).size(), Palette.INK_SOFT)

	var stats := UIKit.grid(section, 2, 8, 4)
	_stat_row(stats, "Población", TSBGame.short_number(int(data.get("population", 0))))
	_stat_row(stats, "Riqueza base", str(int(data.get("base_wealth", 0))))
	var garrison := TSBGame.armies_in(region_id).size()
	_stat_row(stats, "Guarnición", "%d ejército%s" % [garrison, "" if garrison == 1 else "s"])
	_stat_row(stats, "Tesoro del reino", "%d oro" % TSBGame.gold(owner) if not owner.is_empty() else "—")

	var support_row := UIKit.hbox(section, 8)
	var support_title := UIKit.label(support_row, "Apoyo popular", "InkLabel")
	support_title.add_theme_font_size_override("font_size", 15)
	support_title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var support_value := TSBGame.support(region_id)
	var support_bar := UIKit.bar(support_row, support_value, 100.0, Palette.support_color(support_value), 14)
	support_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var support_label := UIKit.label(support_row, "%d/100" % support_value, "InkLabel")
	support_label.add_theme_font_size_override("font_size", 15)
	support_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _build_workers(data: Dictionary) -> void:
	var section := _section("Mano de obra")
	var workers: Variant = data.get("workers", {})
	var worker_dict: Dictionary = workers if workers is Dictionary else {}
	var total_assigned := 0
	for worker_class: String in WORKER_ORDER:
		var current := int(worker_dict.get(worker_class, 0))
		total_assigned += current
		var row := UIKit.hbox(section, 6)
		var class_label := UIKit.label(row, WORKER_LABELS[worker_class], "InkLabel")
		class_label.custom_minimum_size = Vector2(104, 0)
		class_label.add_theme_font_size_override("font_size", 15)
		class_label.add_theme_color_override("font_color", Palette.INK_TEXT)
		var hint := UIKit.label(row, WORKER_HINTS[worker_class], "TinyLabel")
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Palette.MUTED)
		hint.custom_minimum_size = Vector2(52, 0)
		var value_label := UIKit.label(row, str(current) if TSBGame.has_game() else "—", "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.add_theme_font_size_override("font_size", 17)
		value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
		var minus := UIKit.button(row, "-", "SmallButton", "Reasignar %d trabajadores (1 PG)" % STEP)
		minus.custom_minimum_size = Vector2(42, 34)
		minus.disabled = not TSBGame.has_game()
		minus.pressed.connect(func() -> void: _allocate(worker_class, -STEP))
		var plus := UIKit.button(row, "+", "SmallButton", "Reasignar %d trabajadores (1 PG)" % STEP)
		plus.custom_minimum_size = Vector2(42, 34)
		plus.disabled = not TSBGame.has_game()
		plus.pressed.connect(func() -> void: _allocate(worker_class, STEP))

	var total_label := UIKit.label(
		section,
		"Trabajadores asignados: %d%s" % [total_assigned, "" if TSBGame.has_game() else " (vista previa)"],
		"TinyLabel")
	total_label.add_theme_font_size_override("font_size", 13)
	total_label.add_theme_color_override("font_color", Palette.MUTED)
	total_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cost_note := UIKit.label(section, "Cada reasignación cuesta 1 PG (GDD §5.2).", "TinyLabel")
	cost_note.add_theme_font_size_override("font_size", 12)
	cost_note.add_theme_color_override("font_color", Palette.GOLD_DIM)


func _build_buildings(data: Dictionary) -> void:
	var section := _section("Edificios")
	var buildings: Variant = data.get("buildings", [])
	if not (buildings is Array) or (buildings as Array).is_empty():
		var empty := UIKit.label(section, "Sin edificios registrados.", "TinyLabel")
		empty.add_theme_font_size_override("font_size", 14)
		return
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 5)
	section.add_child(flow)
	for building: Variant in (buildings as Array):
		var key := str(building)
		UIKit.chip(flow, str(BUILDING_LABELS.get(key, key.capitalize())), Palette.PARCHMENT_DARK, Palette.INK_TEXT)


func _build_armies(data: Dictionary) -> void:
	var section := _section("Ejércitos en la región")
	var army_entries := TSBGame.armies_in(region_id)
	if army_entries.is_empty():
		var empty := UIKit.label(section, "No hay ejércitos acantonados.", "TinyLabel")
		empty.add_theme_font_size_override("font_size", 14)
	else:
		for army_entry: Variant in army_entries:
			if not (army_entry is Dictionary):
				continue
			var army: Dictionary = army_entry
			var army_box := UIKit.vbox(section, 3)
			var row := UIKit.hbox(army_box, 8)
			var color := TSBGame.faction_color(str(army.get("faction_id", "")))
			var marker := ColorRect.new()
			marker.color = color
			marker.custom_minimum_size = Vector2(6, 22)
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(marker)
			var text := UIKit.label(
				row,
				"%s · %d soldados · moral %d%%" % [
					TSBGame.faction_name(str(army.get("faction_id", ""))),
					TSBGame.army_soldiers(army),
					int(float(army.get("morale", 1.0)) * 100.0),
				],
				"InkLabel")
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.add_theme_font_size_override("font_size", 14)
			text.add_theme_color_override("font_color", Palette.INK_TEXT)

			var controls := UIKit.hbox(army_box, 6)
			var adjacent: Array = TSBGame.region_adjacency(region_id)
			var target_picker := OptionButton.new()
			target_picker.fit_to_longest_item = false
			target_picker.custom_minimum_size = Vector2(164, 34)
			target_picker.add_theme_font_size_override("font_size", 14)
			if adjacent.is_empty():
				target_picker.add_item("Sin regiones adyacentes")
				target_picker.disabled = true
			else:
				for adjacent_id: Variant in adjacent:
					target_picker.add_item(TSBGame.region_name(str(adjacent_id)))
					target_picker.set_item_metadata(target_picker.item_count - 1, str(adjacent_id))
			controls.add_child(target_picker)
			var move_button := UIKit.button(controls, "Avanzar", "SmallButton", "Mover 1 PG; si hay defensores enemigos se ofrece elegir Nivel 1/2/3 (GDD §6)")
			move_button.disabled = not TSBGame.has_game() or adjacent.is_empty()
			move_button.pressed.connect(func() -> void: _move_army(army, target_picker))
			var disband := UIKit.button(controls, "Disolver", "SmallButton")
			disband.disabled = not TSBGame.has_game()
			disband.pressed.connect(func() -> void: _disband_army(army))

	if owner_is_player():
		var create := UIKit.button(section, "Crear ejército en esta región", "SmallButton", "MilitarySystem.create_army()")
		create.disabled = not TSBGame.has_game()
		create.pressed.connect(_create_army)


func _build_recruitment(data: Dictionary) -> void:
	var section := _section("Reclutamiento")
	var fid := TSBGame.player_faction()
	var pool := TSBGame.recruitment_pool(region_id)
	var pool_text := "Pool de reclutas: %d" % pool if pool >= 0 else "Pool de reclutas: — (sistemas en integración)"
	var pool_label := UIKit.label(section, pool_text, "TinyLabel")
	pool_label.add_theme_font_size_override("font_size", 14)
	pool_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var units := TSBGame.units_for_faction(fid)
	var picker_row := UIKit.hbox(section, 6)
	var unit_picker := OptionButton.new()
	unit_picker.fit_to_longest_item = false
	unit_picker.custom_minimum_size = Vector2(132, 36)
	unit_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_picker.add_theme_font_size_override("font_size", 13)
	var selected_cost := ""
	for unit_entry: Variant in units:
		if not (unit_entry is Dictionary):
			continue
		var unit_data: Dictionary = unit_entry
		unit_picker.add_item(str(unit_data.get("name", unit_data.get("id", ""))))
		unit_picker.set_item_metadata(unit_picker.item_count - 1, str(unit_data.get("id", "")))
		if selected_cost.is_empty():
			var cost: Variant = unit_data.get("cost", {})
			if cost is Dictionary:
				selected_cost = "%d oro, %d reclutas" % [int((cost as Dictionary).get("gold", 0)), int((cost as Dictionary).get("recruits", 0))]
	picker_row.add_child(unit_picker)

	var amount_spin := SpinBox.new()
	amount_spin.min_value = 100
	amount_spin.max_value = 4000
	amount_spin.step = 100
	amount_spin.value = 200
	amount_spin.custom_minimum_size = Vector2(86, 36)
	amount_spin.add_theme_font_size_override("font_size", 13)
	picker_row.add_child(amount_spin)

	var action_row := UIKit.hbox(section, 6)
	var recruit_button := UIKit.button(action_row, "Reclutar", "SmallButton", "MilitarySystem.recruit()")
	recruit_button.custom_minimum_size = Vector2(120, 36)
	recruit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recruit_button.disabled = not TSBGame.has_game() or units.is_empty()
	recruit_button.pressed.connect(func() -> void: _recruit(unit_picker, int(amount_spin.value)))

	var cost_label := UIKit.label(section, "Coste por unidad: %s (se valida al reclutar)." % (selected_cost if not selected_cost.is_empty() else "—"), "TinyLabel")
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Palette.MUTED)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if units.is_empty():
		var empty := UIKit.label(section, "No hay unidades disponibles para tu facción en este año.", "TinyLabel")
		empty.add_theme_font_size_override("font_size", 13)


func owner_is_player() -> bool:
	var owner := TSBGame.region_owner(region_id)
	return not owner.is_empty() and owner == TSBGame.player_faction()


func _section(title_text: String) -> VBoxContainer:
	var box := UIKit.vbox(_content, 5)
	var title := UIKit.label(box, title_text, "InkLabel")
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(box, Palette.with_alpha(Palette.GOLD_DIM, 0.5))
	return box


func _stat_row(parent: Node, key_text: String, value_text: String) -> void:
	var row := UIKit.hbox(parent, 4)
	var key_label := UIKit.label(row, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	key_label.custom_minimum_size = Vector2(96, 0)
	var value_label := UIKit.label(row, value_text, "InkLabel")
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _terrain_name(terrain: String) -> String:
	var names := {
		"plains": "Llanura",
		"forest": "Bosque",
		"mountain": "Montaña",
		"coast": "Costa",
		"city": "Ciudad",
	}
	return str(names.get(terrain, terrain.capitalize()))


# --------------------------------------------------------------------------
# Acciones (solo API de sistemas a traves de TSBGame)
# --------------------------------------------------------------------------
func _allocate(worker_class: String, delta: int) -> void:
	var data := TSBGame.region(region_id)
	var workers: Variant = data.get("workers", {})
	var current := int((workers as Dictionary).get(worker_class, 0)) if workers is Dictionary else 0
	var target := maxi(current + delta, 0)
	if target == current:
		action_result.emit("La asignación no cambia.", false)
		return
	var ok := TSBGame.allocate(region_id, worker_class, target)
	if ok:
		action_result.emit("%s: %s asignados a %d." % [str(data.get("name", region_id)), WORKER_LABELS[worker_class], target], true)
		TSBGame.tutorial_advance("assign_workers")
	else:
		action_result.emit("No se pudo reasignar (¿PG insuficiente o población ocupada?).", false)
	refresh()


func _move_army(army: Dictionary, picker: OptionButton) -> void:
	if picker.item_count == 0 or picker.get_selected_id() < 0:
		return
	var target := str(picker.get_item_metadata(picker.selected))
	if target.is_empty():
		return
	var army_id := str(army.get("id", ""))
	var fid := str(army.get("faction_id", TSBGame.player_faction()))
	var target_owner := TSBGame.region_owner(target)
	var target_data := TSBGame.region(target)
	var defender := TSBGame.defender_army_in(target, fid)
	if not target_owner.is_empty() and target_owner != fid and not defender.is_empty():
		# Choque: el jugador elige Nivel 1/2/3 en la pantalla de batalla.
		battle_requested.emit(army_id, str(defender.get("id", "")), target)
		action_result.emit("Choque en %s: elige cómo resolver la batalla." % TSBGame.region_name(target), true)
		return
	var ok := TSBGame.move_army(army_id, target)
	if ok:
		var notice := "Ejército en marcha hacia %s." % TSBGame.region_name(target)
		if not target_owner.is_empty() and target_owner != fid:
			notice = "La región %s no tenía defensores: ocupada." % TSBGame.region_name(target)
		action_result.emit(notice, true)
	else:
		action_result.emit("Movimiento rechazado (PG, adyacencia o ejército no disponible).", false)
	refresh()


func _disband_army(army: Dictionary) -> void:
	var army_id := str(army.get("id", ""))
	if TSBGame.disband_army(army_id):
		action_result.emit("Ejército disuelto.", true)
	else:
		action_result.emit("No se pudo disolver el ejército.", false)
	refresh()


func _create_army() -> void:
	var fid := TSBGame.player_faction()
	var result := TSBGame.create_army(fid, region_id)
	if result.is_empty():
		action_result.emit("No se pudo crear el ejército (sin PG, oro o hueco).", false)
	else:
		action_result.emit("Nuevo ejército creado en %s." % TSBGame.region_name(region_id), true)
	refresh()


func _recruit(picker: OptionButton, amount: int) -> void:
	if picker.item_count == 0 or picker.selected < 0:
		return
	var unit_id := str(picker.get_item_metadata(picker.selected))
	if unit_id.is_empty():
		return
	var fid := TSBGame.player_faction()
	if TSBGame.recruit(fid, region_id, unit_id, amount):
		action_result.emit("Se han reclutado %d unidades de %s." % [amount, str(TSBGame.unit(unit_id).get("name", unit_id))], true)
	else:
		action_result.emit("Reclutamiento rechazado (oro, pool o límite de ejércitos).", false)
	refresh()
