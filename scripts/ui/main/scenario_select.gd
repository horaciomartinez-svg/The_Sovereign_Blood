extends Control
## Selección de escenario y casa (GDD v1.7 §4.3-§4.5, contrato escenarios §3).
## 3 escenarios jugables (1337/1402/1453) con título, descripción, año y era;
## al elegir escenario se listan sus 8 playable_factions. Los datos son la
## fuente de verdad; si un escenario aún no está cargado, su tarjeta queda
## deshabilitada con "datos en preparación", sin promesa de disponibilidad futura.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ParchmentBackdrop = preload("res://scripts/ui/widgets/parchment_backdrop.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const WORLD_MAP_SCENE := "res://scenes/map/world_map.tscn"

const SCENARIO_DEFAULTS := [
	{
		"id": "scenario_1337",
		"year": 1337,
		"title": "Dos Coronas",
		"description": "Eduardo III de Inglaterra reivindica la corona francesa: comienza la Guerra de los Cien Años.",
	},
	{
		"id": "scenario_1402",
		"year": 1402,
		"end_year": 1460,
		"title": "El Choque de Imperios",
		"description": "Timur desafía a los otomanos y Francia y Borgoña se desangran en la Guerra de los Cien Años.",
	},
	{
		"id": "scenario_1453",
		"year": 1453,
		"end_year": 1480,
		"title": "El Ocaso y el Alba",
		"description": "Constantinopla cae, estalla la Guerra de las Dos Rosas y la pólvora cambia la faz de Europa.",
	},
]

const FACTION_LABELS := {
	"england": "Inglaterra",
	"france": "Francia",
	"hre": "Sacro Imperio",
	"bohemia": "Bohemia",
	"hungary": "Hungría",
	"castile": "Castilla",
	"aragon": "Aragón",
	"poland": "Polonia",
	"scotland": "Escocia",
	"papacy": "Papado",
	"granada": "Granada",
	"mamluks": "Mamelucos",
	"byzantium": "Bizancio",
	"golden_horde": "Horda de Oro",
	"brittany": "Bretaña",
	"burgundy": "Borgoña",
	"florence": "Florencia",
	"genoa": "Génova",
	"milan": "Milán",
	"naples": "Nápoles",
	"ottoman": "Otomanos",
	"tamerlane": "Timúridas",
	"venice": "Venecia",
}

const GOVERNMENT_LABELS := {
	"monarchy": "Monarquía",
	"elective_monarchy": "Monarquía electiva",
	"theocracy": "Teocracia",
	"sultanate": "Sultanato",
	"khanate": "Kanato",
	"empire": "Imperio",
	"republic": "República",
}

const PROFILE_LABELS := {
	"aggressor": "Agressor",
	"merchant": "Comerciante",
	"dynastic": "Dinástico",
	"survivor": "Superviviente",
	"balanced": "Equilibrado",
}

var _selected_scenario_id: String = ""
var _selected_faction: String = ""
var _scenario_buttons: Dictionary = {}
var _faction_buttons: Dictionary = {}
var _scenario_subtitle: Label = null
var _faction_title: Label = null
var _faction_box: VBoxContainer = null
var _detail_box: VBoxContainer = null
var _start_button: Button = null
var _status_label: Label = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	TSBGame.ensure_data()
	_build()
	var initial := "scenario_1337"
	if not _scenario_available(initial):
		for meta: Dictionary in SCENARIO_DEFAULTS:
			if _scenario_available(str(meta.get("id", ""))):
				initial = str(meta.get("id", ""))
				break
	_select_scenario(initial)


func _build() -> void:
	var backdrop := ParchmentBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := UIKit.margin(self, 34, 22, 34, 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page := UIKit.vbox(margin, 12)

	var header := UIKit.hbox(page, 18)
	var back := UIKit.button(header, "<  VOLVER", "SmallButton", "Volver al menú principal")
	back.custom_minimum_size = Vector2(150, 46)
	back.pressed.connect(_on_back)
	var titles := UIKit.vbox(header, 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(titles, "ELIGE TU ESCENARIO", "TitleLabel")
	title.add_theme_font_size_override("font_size", 42)
	_scenario_subtitle = UIKit.label(titles, "Tres escenarios jugables · selecciona una casa para comenzar", "SmallLabel")
	_scenario_subtitle.add_theme_font_size_override("font_size", 18)
	var data_summary := UIKit.label(
		header,
		"%d facciones · %d regiones · %d personajes" % [
			TSBGame.faction_ids().size(),
			TSBGame.region_ids().size(),
			TSBGame.all_characters().size(),
		],
		"TinyLabel",
		HORIZONTAL_ALIGNMENT_RIGHT)
	data_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.hsep(page)

	var cards_row := UIKit.hbox(page, 14)
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for meta: Dictionary in SCENARIO_DEFAULTS:
		_build_scenario_card(cards_row, meta)
	UIKit.hsep(page)

	var content := UIKit.hbox(page, 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var faction_panel := UIKit.panel(content, "ParchmentPanel")
	faction_panel.custom_minimum_size = Vector2(480, 0)
	var faction_margin := UIKit.margin(faction_panel, 16, 14, 16, 14)
	var faction_column := UIKit.vbox(faction_margin, 6)
	_faction_title = UIKit.label(faction_column, "CASAS JUGABLES", "InkLabel")
	_faction_title.add_theme_font_size_override("font_size", 20)
	_faction_title.add_theme_color_override("font_color", Palette.CRIMSON)
	_faction_box = UIKit.vbox(faction_column, 6)
	_faction_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var faction_hint := UIKit.label(
		faction_column,
		"Cada escenario declara sus 8 facciones jugables en los datos (playable_factions).",
		"InkLabel")
	faction_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	faction_hint.add_theme_font_size_override("font_size", 12)
	faction_hint.add_theme_color_override("font_color", Palette.MUTED)

	var detail_panel := UIKit.panel(content, "ParchmentPanel")
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_panel.add_child(scroll)
	var detail_margin := UIKit.margin(scroll, 16, 14, 16, 14)
	detail_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box = UIKit.vbox(detail_margin, 7)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	UIKit.hsep(page)
	var footer := UIKit.hbox(page, 16)
	_status_label = UIKit.label(footer, "", "SmallLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button = UIKit.button(footer, "COMENZAR REINADO", "PrimaryButton")
	_start_button.custom_minimum_size = Vector2(380, 62)
	_start_button.pressed.connect(_on_start)


func _build_scenario_card(parent: Node, meta: Dictionary) -> void:
	var scenario_id := str(meta.get("id", ""))
	var available := _scenario_available(scenario_id)
	var card := UIKit.panel(parent, "ParchmentPanel" if available else "InkPanel")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not available:
		card.modulate = Color(1, 1, 1, 0.72)
	var margin := UIKit.margin(card, 16, 12, 16, 12)
	var column := UIKit.vbox(margin, 5)
	var year_value := TSBGame.scenario_start_year(scenario_id) if available else int(meta.get("year", 1337))
	var year_label := UIKit.label(column, str(year_value), "InkLabel")
	year_label.add_theme_font_size_override("font_size", 36)
	year_label.add_theme_color_override("font_color", Palette.CRIMSON if available else Palette.MUTED)
	var title_text := str(TSBGame.scenario(scenario_id).get("title", meta.get("title", ""))) if available else str(meta.get("title", ""))
	var title_label := UIKit.label(column, title_text, "InkLabel")
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Palette.INK_TEXT if available else Palette.MUTED)
	var era_text := "ERA %s" % TSBGame.era_for_year(year_value)
	var end_year := TSBGame.scenario_end_year_for(scenario_id) if available else int(meta.get("end_year", year_value + 62))
	var era_label := UIKit.label(column, "%s · %d–%d" % [era_text, year_value, end_year], "InkLabel")
	era_label.add_theme_font_size_override("font_size", 13)
	era_label.add_theme_color_override("font_color", Palette.GOLD_DIM if available else Palette.MUTED)
	var description_text := str(TSBGame.scenario(scenario_id).get("description", meta.get("description", ""))) if available else str(meta.get("description", ""))
	var description := UIKit.label(column, description_text, "InkLabel")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.1) if available else Palette.MUTED)
	description.custom_minimum_size = Vector2(0, 52)
	UIKit.spacer(column, 2)
	var button_text := "ELEGIR ESCENARIO" if available else "DATOS EN PREPARACIÓN"
	var button := UIKit.button(column, button_text, "SmallButton" if available else "CardButton")
	button.disabled = not available
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(func() -> void: _select_scenario(scenario_id))
	_scenario_buttons[scenario_id] = button


func _scenario_available(scenario_id: String) -> bool:
	return TSBGame.scenario_available(scenario_id) and not TSBGame.playable_factions(scenario_id).is_empty()


func _select_scenario(scenario_id: String) -> void:
	if not _scenario_available(scenario_id):
		if _status_label != null:
			_status_label.text = "Escenario aún no disponible en los datos; se habilitará al cargarse."
		return
	_selected_scenario_id = scenario_id
	for key: Variant in _scenario_buttons.keys():
		var button: Button = _scenario_buttons[key]
		button.button_pressed = str(key) == scenario_id
	if _scenario_subtitle != null:
		_scenario_subtitle.text = "%s · %d–%d · ERA %s" % [
			str(TSBGame.scenario(scenario_id).get("title", "")),
			TSBGame.scenario_start_year(scenario_id),
			TSBGame.scenario_end_year_for(scenario_id),
			TSBGame.era_for_year(TSBGame.scenario_start_year(scenario_id)),
		]
	_rebuild_factions()


func _rebuild_factions() -> void:
	if _faction_box == null:
		return
	UIKit.clear(_faction_box)
	_faction_buttons.clear()
	var playable := TSBGame.playable_factions(_selected_scenario_id)
	if _faction_title != null:
		_faction_title.text = "CASAS JUGABLES · %s" % _scenario_short_title(_selected_scenario_id)
	if playable.is_empty():
		var empty := UIKit.label(_faction_box, "Datos del escenario en preparación: no hay facciones jugables cargadas.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		if _start_button != null:
			_start_button.disabled = true
		return
	var grid := UIKit.grid(_faction_box, 2, 8, 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var group := ButtonGroup.new()
	for faction_id: Variant in playable:
		var fid := str(faction_id)
		var button := UIKit.button(grid, str(FACTION_LABELS.get(fid, TSBGame.faction_name(fid))), "CardButton")
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = TSBGame.faction_name(fid)
		button.pressed.connect(func() -> void: _select_faction(fid))
		_faction_buttons[fid] = button
	_select_faction(str(playable[0]))


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
		_status_label.text = "Al comenzar se creará la partida y se abrirá el mapa en el año del escenario."


func _rebuild_detail() -> void:
	if _detail_box == null or _selected_faction.is_empty():
		return
	UIKit.clear(_detail_box)
	var fid := _selected_faction
	var faction_data := TSBGame.faction(fid)
	var color := TSBGame.faction_color(fid)
	var header := UIKit.hbox(_detail_box, 14)
	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(96, 116)
	shield.set("house", _house_of_faction(fid))
	shield.set("field_color", color)
	header.add_child(shield)
	var header_text := UIKit.vbox(header, 2)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(header_text, TSBGame.faction_name(fid), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var gov := UIKit.label(header_text, str(GOVERNMENT_LABELS.get(str(faction_data.get("government", "")), "Monarquía")), "InkLabel")
	gov.add_theme_font_size_override("font_size", 16)
	gov.add_theme_color_override("font_color", Palette.CRIMSON)
	var profile := UIKit.label(header_text, "Perfil: %s" % str(PROFILE_LABELS.get(TSBGame.faction_profile(fid), "Equilibrado")), "InkLabel")
	profile.add_theme_font_size_override("font_size", 15)
	profile.add_theme_color_override("font_color", Palette.INK_TEXT)
	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.8))

	var ruler := _current_or_preview_ruler(fid, "ruler")
	var heir := _current_or_preview_ruler(fid, "heir")
	var capital := str(faction_data.get("capital", ""))
	_detail_row("Gobernante", str(ruler.get("name", "—")), _age_text(ruler))
	_detail_row("Heredero", str(heir.get("name", "—")), "")
	_detail_row("Capital", TSBGame.region_name(capital), "")
	_detail_row("Tesoro inicial", "%d oro" % _preview_treasury(fid), "")
	_detail_row("Prestigio", str(TSBGame.prestige(fid)), "")
	_detail_row("Regiones", str(_preview_regions(fid)), "")
	_detail_row("Ejércitos", str(_preview_armies(fid)), "")

	UIKit.spacer(_detail_box, 4)
	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var scenario_data := TSBGame.scenario(_selected_scenario_id)
	var victory_value: Variant = scenario_data.get("victory", {})
	var victory: Dictionary = victory_value if victory_value is Dictionary else {}
	var goals_title := UIKit.label(_detail_box, "OBJETIVOS DE VICTORIA · %s" % _scenario_short_title(_selected_scenario_id), "InkLabel")
	goals_title.add_theme_font_size_override("font_size", 17)
	goals_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var goals := [
		"Alcanzar %d puntos de prestigio" % int(victory.get("prestige", 500)),
		"Controlar el %d%% de las regiones" % int(victory.get("control_pct", 70)),
		"Sobrevivir hasta %d" % TSBGame.scenario_end_year_for(_selected_scenario_id),
	]
	for goal_text: String in goals:
		var goal_label := UIKit.label(_detail_box, "· " + goal_text, "InkLabel")
		goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		goal_label.add_theme_font_size_override("font_size", 13)
		goal_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var hint := UIKit.label(_detail_box, "La partida se juega por trimestres: 4 turnos = 1 año. El mapa arranca en la vista política del año del escenario.", "InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Palette.MUTED)


func _scenario_short_title(scenario_id: String) -> String:
	var sc := TSBGame.scenario(scenario_id)
	var title := str(sc.get("title", ""))
	if not title.is_empty():
		return title
	for meta: Dictionary in SCENARIO_DEFAULTS:
		if str(meta.get("id", "")) == scenario_id:
			return str(meta.get("title", ""))
	return scenario_id


func _current_or_preview_ruler(faction_id: String, role: String) -> Dictionary:
	if TSBGame.has_game() and TSBGame.scenario_id() == _selected_scenario_id:
		var current := TSBGame.ruler(faction_id) if role == "ruler" else TSBGame.heir(faction_id)
		if not current.is_empty():
			return current
	var year := TSBGame.scenario_start_year(_selected_scenario_id)
	var best: Dictionary = {}
	var best_reign := -1
	for entry: Variant in TSBGame.characters_of(faction_id):
		if not (entry is Dictionary):
			continue
		var character := entry as Dictionary
		if str(character.get("role", "")) != role:
			continue
		var born := int(character.get("born", 0))
		var died_value: Variant = character.get("died", null)
		if born > year or (died_value != null and int(died_value) < year):
			continue
		var reign_start := int(character.get("reign_start", 0))
		if reign_start > 0 and reign_start > year:
			continue
		var reign_end := int(character.get("reign_end", 0))
		if reign_end > 0 and reign_end < year:
			continue
		if reign_start >= best_reign:
			best = character.duplicate(true)
			best_reign = reign_start
	if not best.is_empty():
		best["age"] = maxi(year - int(best.get("born", year)), 0)
	return best


func _preview_treasury(faction_id: String) -> int:
	if TSBGame.has_game() and TSBGame.scenario_id() == _selected_scenario_id:
		return TSBGame.gold(faction_id)
	var initial: Variant = TSBGame.scenario(_selected_scenario_id).get("initial_state", {})
	if initial is Dictionary:
		var treasuries: Variant = (initial as Dictionary).get("treasuries", {})
		if treasuries is Dictionary and (treasuries as Dictionary).has(faction_id):
			return int((treasuries as Dictionary).get(faction_id, 0))
	return TSBGame.gold(faction_id)


func _preview_regions(faction_id: String) -> int:
	if TSBGame.has_game() and TSBGame.scenario_id() == _selected_scenario_id:
		return TSBGame.regions_owned_by(faction_id).size()
	var year := TSBGame.scenario_start_year(_selected_scenario_id)
	var count := 0
	for region_id: Variant in TSBGame.region_ids():
		if TSBGame.map_owner_for(str(region_id), year) == faction_id:
			count += 1
	return count


func _preview_armies(faction_id: String) -> int:
	if TSBGame.has_game() and TSBGame.scenario_id() == _selected_scenario_id:
		var count := 0
		for army: Variant in TSBGame.armies().values():
			if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == faction_id:
				count += 1
		return count
	var initial: Variant = TSBGame.scenario(_selected_scenario_id).get("initial_state", {})
	if initial is Dictionary:
		var armies: Variant = (initial as Dictionary).get("armies", {})
		if armies is Dictionary:
			var list: Variant = (armies as Dictionary).get(faction_id, [])
			if list is Array:
				return (list as Array).size()
	return 0


func _detail_row(label_text: String, value_text: String, suffix: String) -> void:
	var row := UIKit.hbox(_detail_box, 8)
	var key_label := UIKit.label(row, label_text, "InkLabel")
	key_label.custom_minimum_size = Vector2(130, 0)
	key_label.add_theme_font_size_override("font_size", 15)
	key_label.add_theme_color_override("font_color", Palette.CRIMSON.darkened(0.1))
	var value_label := UIKit.label(row, value_text, "InkLabel")
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not suffix.is_empty():
		var suffix_label := UIKit.label(row, suffix, "InkLabel")
		suffix_label.add_theme_font_size_override("font_size", 14)
		suffix_label.add_theme_color_override("font_color", Palette.GOLD_DIM)


func _house_of_faction(faction_id: String) -> String:
	var ruler := TSBGame.ruler(faction_id)
	var house := str(ruler.get("house", ""))
	return house if not house.is_empty() else faction_id


func _age_text(character_entry: Dictionary) -> String:
	if character_entry.is_empty():
		return ""
	var age := int(character_entry.get("age", 0))
	if age <= 0:
		age = TSBGame.character_age(character_entry)
	return "%d años" % age if age > 0 else ""


func _on_start() -> void:
	if _selected_faction.is_empty() or _selected_scenario_id.is_empty():
		return
	var started: bool = TSBGame.start_new_game_in_scenario(_selected_scenario_id, _selected_faction)
	if not started:
		if _status_label != null:
			_status_label.text = "No se pudo iniciar el escenario: datos del escenario todavía no cargados."
		return
	get_tree().change_scene_to_file(WORLD_MAP_SCENE)


func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()
