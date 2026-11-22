extends Control
## Seleccion de escenario y faccion (GDD §9.2).
## Tres tarjetas: la de 1337 es jugable (datos completos); 1402/1453 llegan en Fase 3.
## Arranca con GameState.new_game("scenario_1337", fid) + TurnManager.begin_turn(fid).

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ParchmentBackdrop = preload("res://scripts/ui/widgets/parchment_backdrop.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const WORLD_MAP_SCENE := "res://scenes/map/world_map.tscn"

const FACTION_LABELS := {
	"england": "Inglaterra",
	"france": "Francia",
	"hre": "Sacro Imperio",
	"bohemia": "Bohemia",
	"hungary": "Hungría",
	"castile": "Castilla",
	"aragon": "Aragón",
	"poland": "Polonia",
}

const GOVERNMENT_LABELS := {
	"monarchy": "Monarquía",
	"elective_monarchy": "Monarquía electiva",
	"theocracy": "Teocracia",
	"sultanate": "Sultanato",
	"khanate": "Kanato",
	"empire": "Imperio",
}

const PROFILE_LABELS := {
	"aggressor": "Agressor",
	"merchant": "Comerciante",
	"dynastic": "Dinástico",
	"survivor": "Superviviente",
	"balanced": "Equilibrado",
}

var _selected_faction: String = ""
var _faction_buttons: Dictionary = {}
var _detail_box: VBoxContainer = null
var _start_button: Button = null
var _status_label: Label = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	TSBGame.ensure_data()
	_build()
	_select_faction("england")


func _build() -> void:
	var backdrop := ParchmentBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := UIKit.margin(self, 40, 26, 40, 24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page := UIKit.vbox(margin, 16)

	# Cabecera.
	var header := UIKit.hbox(page, 18)
	var back := UIKit.button(header, "<  VOLVER", "SmallButton", "Volver al menú principal")
	back.custom_minimum_size = Vector2(150, 46)
	back.pressed.connect(_on_back)

	var titles := UIKit.vbox(header, 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(titles, "ELIGE TU CORONA", "TitleLabel")
	title.add_theme_font_size_override("font_size", 46)
	var subtitle := UIKit.label(titles, "Escenario «Dos Coronas» · 1337 — selecciona la casa que gobernarás", "SmallLabel")
	subtitle.add_theme_font_size_override("font_size", 19)

	var data_summary := UIKit.label(
		header,
		"%d facciones · %d jugables · %d regiones · %d personajes" % [
			TSBGame.faction_ids().size(),
			TSBGame.playable_factions().size(),
			TSBGame.region_ids().size(),
			TSBGame.all_characters().size(),
		],
		"TinyLabel",
		HORIZONTAL_ALIGNMENT_RIGHT)
	data_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.hsep(page)

	# Contenido: tarjetas + detalle de faccion.
	var content := UIKit.hbox(page, 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var cards := UIKit.hbox(content, 18)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_current_scenario_card(cards)
	_build_future_card(cards, "1402", "El Choque de Imperios", "Timur desafía a los otomanos;\nFrancia y Borgoña se desangran en la\nGuerra de los Cien Años.")
	_build_future_card(cards, "1453", "El Ocaso y el Alba", "Constantinopla cae, la Guerra de las\nDos Rosas estalla y la pólvora cambia\nla faz de Europa.")

	var detail_panel := UIKit.panel(content, "ParchmentPanel")
	detail_panel.custom_minimum_size = Vector2(470, 0)
	var detail_margin := UIKit.margin(detail_panel, 18, 16, 18, 16)
	_detail_box = UIKit.vbox(detail_margin, 8)
	_detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Pie.
	UIKit.hsep(page)
	var footer := UIKit.hbox(page, 16)
	_status_label = UIKit.label(footer, "", "SmallLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button = UIKit.button(footer, "COMENZAR REINADO", "PrimaryButton")
	_start_button.custom_minimum_size = Vector2(380, 62)
	_start_button.pressed.connect(_on_start)


func _build_current_scenario_card(parent: Node) -> void:
	var card := UIKit.panel(parent, "ParchmentPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := UIKit.margin(card, 20, 16, 20, 16)
	var column := UIKit.vbox(margin, 8)

	var year := UIKit.label(column, "1337", "InkLabel")
	year.add_theme_font_size_override("font_size", 44)
	year.add_theme_color_override("font_color", Palette.CRIMSON)

	var title := UIKit.label(column, TSBGame.scenario_title(), "InkLabel")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)

	var description := UIKit.label(
		column,
		str(TSBGame.scenario().get("description", "Eduardo III de Inglaterra reivindica la corona francesa.")),
		"InkLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.1))
	description.custom_minimum_size = Vector2(0, 64)

	var minimap := ScenarioMinimap.new()
	minimap.custom_minimum_size = Vector2(0, 250)
	minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(minimap)

	var notice := UIKit.label(column, "Facciones jugables", "InkLabel")
	notice.add_theme_font_size_override("font_size", 20)
	notice.add_theme_color_override("font_color", Palette.CRIMSON)

	var grid := UIKit.grid(column, 2, 8, 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var group := ButtonGroup.new()
	var playable := TSBGame.playable_factions()
	for faction_id: Variant in playable:
		var fid := str(faction_id)
		var button := UIKit.button(grid, str(FACTION_LABELS.get(fid, TSBGame.faction_name(fid))), "CardButton")
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = TSBGame.faction_name(fid)
		button.pressed.connect(func() -> void: _select_faction(fid))
		_faction_buttons[fid] = button

	UIKit.spacer(column, 4)
	var chips := UIKit.hbox(column, 6)
	UIKit.chip(chips, "47 regiones", Palette.PARCHMENT_DARK, Palette.INK_TEXT)
	UIKit.chip(chips, "14 potencias", Palette.PARCHMENT_DARK, Palette.INK_TEXT)
	UIKit.chip(chips, "1337–1399", Palette.PARCHMENT_DARK, Palette.INK_TEXT)


func _build_future_card(parent: Node, year_text: String, title_text: String, description_text: String) -> void:
	var card := UIKit.panel(parent, "InkPanel")
	card.custom_minimum_size = Vector2(250, 0)
	var margin := UIKit.margin(card, 16, 16, 16, 16)
	var column := UIKit.vbox(margin, 10)

	var year := UIKit.label(column, year_text, "TitleLabel")
	year.add_theme_font_size_override("font_size", 40)
	var title := UIKit.label(column, title_text, "SectionHeader")
	title.add_theme_font_size_override("font_size", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var description := UIKit.label(column, description_text, "SmallLabel")
	description.add_theme_font_size_override("font_size", 15)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.spacer(column, 8)
	var lock_label := UIKit.label(column, "PRÓXIMAMENTE", "GoldLabel")
	lock_label.add_theme_font_size_override("font_size", 18)
	var phase := UIKit.label(column, "Fase 3 · datos y eventos históricos\n1402 y 1453 (AG-1 + AG-2)", "TinyLabel")
	phase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	card.modulate = Color(1, 1, 1, 0.78)


func _select_faction(faction_id: String) -> void:
	if faction_id.is_empty():
		return
	_selected_faction = faction_id
	for key: Variant in _faction_buttons.keys():
		var button: Button = _faction_buttons[key]
		button.button_pressed = str(key) == faction_id
	_rebuild_detail()
	if _start_button != null:
		_start_button.text = "COMENZAR REINADO CON %s" % str(FACTION_LABELS.get(faction_id, TSBGame.faction_name(faction_id))).to_upper()
		_start_button.disabled = false
	if _status_label != null:
		_status_label.text = "Al comenzar se creará la partida y se abrirá el mapa de Europa."


func _rebuild_detail() -> void:
	if _detail_box == null:
		return
	UIKit.clear(_detail_box)
	var fid := _selected_faction
	var faction_data := TSBGame.faction(fid)
	var color := TSBGame.faction_color(fid)
	var header := UIKit.hbox(_detail_box, 14)

	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(118, 140)
	shield.set("house", _house_of_faction(fid))
	shield.set("field_color", color)
	header.add_child(shield)

	var header_text := UIKit.vbox(header, 2)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(header_text, TSBGame.faction_name(fid), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var gov := UIKit.label(header_text, str(GOVERNMENT_LABELS.get(str(faction_data.get("government", "")), "Monarquía")), "InkLabel")
	gov.add_theme_font_size_override("font_size", 17)
	gov.add_theme_color_override("font_color", Palette.CRIMSON)
	var profile := UIKit.label(header_text, "Perfil: %s" % str(PROFILE_LABELS.get(TSBGame.faction_profile(fid), "Equilibrado")), "InkLabel")
	profile.add_theme_font_size_override("font_size", 16)
	profile.add_theme_color_override("font_color", Palette.INK_TEXT)

	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.8))

	var ruler := TSBGame.ruler(fid)
	var heir := TSBGame.heir(fid)
	var capital := str(faction_data.get("capital", ""))
	var regions_count := TSBGame.regions_owned_by(fid).size()
	var armies := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			armies += 1

	_detail_row("Gobernante", str(ruler.get("name", "—")), _age_text(ruler))
	_detail_row("Heredero", str(heir.get("name", "—")), "")
	_detail_row("Capital", TSBGame.region_name(capital), "")
	_detail_row("Tesoro inicial", "%d oro" % TSBGame.gold(fid), "")
	_detail_row("Prestigio", str(TSBGame.prestige(fid)), "")
	_detail_row("Regiones", str(regions_count), "")
	_detail_row("Ejércitos", str(armies), "")

	UIKit.spacer(_detail_box, 6)
	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.8))

	var traits := UIKit.vbox(_detail_box, 3)
	var ruler_traits: Variant = ruler.get("traits", [])
	if ruler_traits is Array and not (ruler_traits as Array).is_empty():
		var traits_title := UIKit.label(traits, "Rasgos del gobernante", "InkLabel")
		traits_title.add_theme_font_size_override("font_size", 18)
		traits_title.add_theme_color_override("font_color", Palette.CRIMSON)
		for trait_value: Variant in (ruler_traits as Array):
			var trait_label := UIKit.label(traits, "· " + str(trait_value).replace("_", " "), "InkLabel")
			trait_label.add_theme_font_size_override("font_size", 15)
			trait_label.add_theme_color_override("font_color", Palette.INK_TEXT)

	var hint := UIKit.label(
		_detail_box,
		"La partida se juega por trimestres: 4 turnos = 1 año. El objetivo es sostener dos coronas durante una década y alcanzar 500 de prestigio (§4.5).",
		"InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))

	UIKit.spacer(_detail_box, 4)
	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var goals_title := UIKit.label(_detail_box, "OBJETIVOS DE VICTORIA", "InkLabel")
	goals_title.add_theme_font_size_override("font_size", 17)
	goals_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var victory: Variant = TSBGame.scenario().get("victory", {})
	var victory_dict: Dictionary = victory if victory is Dictionary else {}
	var goals := [
		"Sostener %d coronas bajo tu casa" % int(victory_dict.get("crowns", 2)),
		"Alcanzar %d puntos de prestigio" % int(victory_dict.get("prestige", 500)),
		"Mantener el trono durante %d años" % int(victory_dict.get("years_held", 10)),
	]
	for goal_text: String in goals:
		var goal_label := UIKit.label(_detail_box, "· " + goal_text, "InkLabel")
		goal_label.add_theme_font_size_override("font_size", 14)
		goal_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var end_label := UIKit.label(
		_detail_box,
		"Escenario %d–%d · guardado automático al final de cada año." % [TSBGame.start_year(), TSBGame.scenario_end_year()],
		"InkLabel")
	end_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_label.add_theme_font_size_override("font_size", 12)
	end_label.add_theme_color_override("font_color", Palette.MUTED)


func _detail_row(label_text: String, value_text: String, suffix: String) -> void:
	var row := UIKit.hbox(_detail_box, 8)
	var key_label := UIKit.label(row, label_text, "InkLabel")
	key_label.custom_minimum_size = Vector2(150, 0)
	key_label.add_theme_font_size_override("font_size", 16)
	key_label.add_theme_color_override("font_color", Palette.CRIMSON.darkened(0.1))
	var value_label := UIKit.label(row, value_text, "InkLabel")
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_font_size_override("font_size", 17)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not suffix.is_empty():
		var suffix_label := UIKit.label(row, suffix, "InkLabel")
		suffix_label.add_theme_font_size_override("font_size", 16)
		suffix_label.add_theme_color_override("font_color", Palette.GOLD_DIM)


func _house_of_faction(faction_id: String) -> String:
	var ruler := TSBGame.ruler(faction_id)
	var house := str(ruler.get("house", ""))
	return house if not house.is_empty() else faction_id


func _age_text(character_entry: Dictionary) -> String:
	if character_entry.is_empty():
		return ""
	var age := TSBGame.character_age(character_entry)
	return "%d años" % age if age > 0 else ""


func _on_start() -> void:
	if _selected_faction.is_empty():
		return
	var started := TSBGame.start_new_game(_selected_faction)
	if not started:
		_status_label.text = "Sistemas en integración (AG-2): se abre el mapa en vista previa de datos."
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


# ==========================================================================
# Miniatura de mapa generada por codigo (thumbnail del escenario)
# ==========================================================================
class ScenarioMinimap extends Control:
	const PaletteLocal = preload("res://scripts/ui/theme/tsb_palette.gd")
	const TSBGameLocal = preload("res://scripts/ui/tsb_game.gd")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var canvas := size
		if canvas.x < 8.0 or canvas.y < 8.0:
			return
		draw_rect(Rect2(Vector2.ZERO, canvas), PaletteLocal.SEA_DEEP)
		var entries: Array = TSBGameLocal.map_borders_for_year(1337)
		for entry: Variant in entries:
			if not (entry is Dictionary):
				continue
			var data := entry as Dictionary
			var raw_ring: Variant = data.get("ring", [])
			if not (raw_ring is Array) or (raw_ring as Array).size() < 3:
				continue
			var points := PackedVector2Array()
			for pair: Variant in (raw_ring as Array):
				if pair is Array and (pair as Array).size() >= 2:
					points.append(Vector2(float((pair as Array)[0]) * canvas.x, float((pair as Array)[1]) * canvas.y))
			if points.size() < 3:
				continue
			var owner := str(data.get("owner", ""))
			var color := TSBGameLocal.faction_color(owner) if not owner.is_empty() else PaletteLocal.MUTED
			color.a = 0.72
			draw_colored_polygon(points, color)
			var closed := points.duplicate()
			closed.append(points[0])
			draw_polyline(closed, PaletteLocal.with_alpha(PaletteLocal.INK_DEEP, 0.55), 0.7, true)
		if entries.is_empty():
			# Sin fronteras (AG-1 pendiente): puntos de centro como miniatura.
			for region_id: Variant in TSBGameLocal.region_ids():
				var data := TSBGameLocal.region(str(region_id))
				var owner := str(data.get("owner", ""))
				var color := TSBGameLocal.faction_color(owner) if not owner.is_empty() else PaletteLocal.MUTED
				var center: Vector2 = TSBGameLocal.map_center(str(region_id), 1337)
				draw_circle(center * canvas, 5.0, color)
		draw_rect(Rect2(Vector2.ZERO, canvas), PaletteLocal.with_alpha(PaletteLocal.GOLD_DIM, 0.8), false, 1.0)
