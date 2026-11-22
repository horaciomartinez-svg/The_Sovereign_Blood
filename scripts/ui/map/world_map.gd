extends Control
## Mapa principal (GDD §9.3): regiones coloreadas por faccion, ejercitos,
## barra lateral de resumen, menu de Consejo, tooltip y panel de region.
##
## Solo lee estado por la fachada TSBGame y se repinta con senales de EventBus /
## autoloads. Nunca escribe `GameState.state` ni diccionarios de sistemas.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const MapBackdrop = preload("res://scripts/ui/map/map_backdrop.gd")
const CouncilScene = preload("res://scenes/council/council_menu.tscn")
const RegionNodeScene = preload("res://scenes/map/region_node.tscn")
const RegionPanelScene = preload("res://scenes/map/region_panel.tscn")
const TooltipScene = preload("res://scenes/ui/tooltip.tscn")
const OptionsScene = preload("res://scenes/ui/options_menu.tscn")
const BattleReportScene = preload("res://scenes/battle/battle_report.tscn")
const YearEndScene = preload("res://scenes/ui/year_end_report.tscn")
const VictoryScene = preload("res://scenes/ui/victory_screen.tscn")
const FamilyScene = preload("res://scenes/family/family_tree.tscn")
const DiplomacyScene = preload("res://scenes/diplomacy/diplomacy_screen.tscn")
const MilitaryScene = preload("res://scenes/military/military_screen.tscn")
const EconomyScene = preload("res://scenes/economy/economy_screen.tscn")
const CourtScene = preload("res://scenes/ui/court_overview.tscn")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const QUARTER_NAMES: Array[String] = ["INVIERNO", "PRIMAVERA", "VERANO", "OTOÑO"]
const SIDEBAR_LEFT := 300.0
const SIDEBAR_RIGHT := 440.0

var _map_area: Control = null
var _map_backdrop: Control = null
var _region_layer: Control = null
var _council: Control = null
var _region_panel: Control = null
var _tooltip: Control = null
var _overlay_layer: CanvasLayer = null
var _notification_layer: CanvasLayer = null
var _notification_box: VBoxContainer = null
var _overlay: Node = null
var _overlay_kind: String = ""
var _turn_processing := false
var _pending_battle_reports: Array = []
var _deferred_battle_report: Dictionary = {}

var _region_nodes: Dictionary = {}
var _region_centers: Dictionary = {}
var _selected_region: String = ""

# Barra lateral de resumen.
var _info_panel: PanelContainer = null
var _info_shield: Control = null
var _info_faction: Label = null
var _info_date: Label = null
var _info_pg: Label = null
var _info_pg_bar: ProgressBar = null
var _info_treasury: Label = null
var _info_prestige: Label = null
var _info_regions: Label = null
var _info_armies: Label = null
var _info_ruler: Label = null
var _info_heir: Label = null
var _alerts_box: VBoxContainer = null
var _news_box: VBoxContainer = null
var _info_save: Label = null

var _map_hint: Label = null
var _preview_banner: PanelContainer = null
var _map_title: Label = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	TSBGame.ensure_data()
	_build_layers()
	_build_map()
	_build_council()
	_build_info_sidebar()
	_build_region_panel()
	_build_tooltip_and_overlays()
	_build_notifications()
	_connect_signals()
	_relayout()
	_refresh_all()
	set_process(true)


func _process(_delta: float) -> void:
	if _tooltip != null and _tooltip.visible:
		_tooltip.call("follow", get_global_mouse_position())


# ==========================================================================
# Construccion de capas
# ==========================================================================
func _build_layers() -> void:
	_map_area = Control.new()
	_map_area.anchor_left = 0.0
	_map_area.anchor_top = 0.0
	_map_area.anchor_right = 1.0
	_map_area.anchor_bottom = 1.0
	_map_area.offset_left = SIDEBAR_LEFT
	_map_area.offset_right = -SIDEBAR_RIGHT
	_map_area.clip_contents = true
	add_child(_map_area)


func _build_map() -> void:
	_map_backdrop = MapBackdrop.new()
	_map_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_area.add_child(_map_backdrop)

	_region_layer = Control.new()
	_region_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_region_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area.add_child(_region_layer)

	_map_hint = UIKit.label(
		_map_area,
		"Click en una región para gobernar · Enter = terminar turno · Esc = opciones",
		"TinyLabel",
		HORIZONTAL_ALIGNMENT_CENTER)
	_map_hint.add_theme_font_size_override("font_size", 14)
	_map_hint.add_theme_color_override("font_color", Palette.with_alpha(Palette.PARCHMENT, 0.72))
	_map_hint.anchor_left = 0.0
	_map_hint.anchor_right = 1.0
	_map_hint.anchor_top = 1.0
	_map_hint.anchor_bottom = 1.0
	_map_hint.offset_top = -30
	_map_hint.offset_bottom = -8
	_map_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_preview_banner = PanelContainer.new()
	_preview_banner.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.88), Palette.GOLD, 1, 4, 14, 6))
	_preview_banner.anchor_left = 0.5
	_preview_banner.anchor_right = 0.5
	_preview_banner.anchor_top = 0.0
	_preview_banner.anchor_bottom = 0.0
	_preview_banner.offset_left = -330
	_preview_banner.offset_right = 330
	_preview_banner.offset_top = 118
	_preview_banner.offset_bottom = 158
	_preview_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_area.add_child(_preview_banner)
	var banner_label := UIKit.label(_preview_banner, "VISTA PREVIA · datos 1337 · sistemas de turno en integración (AG-2)", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.add_theme_font_size_override("font_size", 15)
	banner_label.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_preview_banner.visible = false

	_create_region_nodes()


func _create_region_nodes() -> void:
	var region_ids := TSBGame.region_ids()
	for id: Variant in region_ids:
		var region_id := str(id)
		var node: Control = RegionNodeScene.instantiate()
		_region_layer.add_child(node)
		node.hovered.connect(_on_region_hovered)
		node.unhovered.connect(_on_region_unhovered)
		node.clicked.connect(_on_region_clicked)
		_region_nodes[region_id] = node


func _build_council() -> void:
	_council = CouncilScene.instantiate()
	add_child(_council)
	if _council.has_signal("corte_requested"):
		_council.connect("corte_requested", func() -> void: _open_overlay(CourtScene.resource_path, "court"))
	if _council.has_signal("family_requested"):
		_council.connect("family_requested", func() -> void: _open_overlay(FamilyScene.resource_path, "family"))
	if _council.has_signal("diplomacy_requested"):
		_council.connect("diplomacy_requested", func() -> void: _open_overlay(DiplomacyScene.resource_path, "diplomacy"))
	if _council.has_signal("military_requested"):
		_council.connect("military_requested", func() -> void: _open_overlay(MilitaryScene.resource_path, "military"))
	if _council.has_signal("economy_requested"):
		_council.connect("economy_requested", func() -> void: _open_overlay(EconomyScene.resource_path, "economy"))
	if _council.has_signal("end_turn_requested"):
		_council.connect("end_turn_requested", _on_end_turn_requested)
	if _council.has_signal("menu_requested"):
		_council.connect("menu_requested", _on_return_to_menu)


func _build_info_sidebar() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.theme_type_variation = "ParchmentPanel"
	_info_panel.anchor_left = 1.0
	_info_panel.anchor_right = 1.0
	_info_panel.anchor_top = 0.0
	_info_panel.anchor_bottom = 1.0
	_info_panel.offset_left = -SIDEBAR_RIGHT
	_info_panel.offset_right = 0.0
	add_child(_info_panel)

	var margin := UIKit.margin(_info_panel, 6, 6, 6, 6)
	var column := UIKit.vbox(margin, 7)

	var header := UIKit.hbox(column, 10)
	_info_shield = ShieldScript.new()
	_info_shield.custom_minimum_size = Vector2(84, 100)
	header.add_child(_info_shield)
	var header_text := UIKit.vbox(header, 1)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_faction = UIKit.label(header_text, "—", "InkLabel")
	_info_faction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_faction.add_theme_font_size_override("font_size", 23)
	_info_faction.add_theme_color_override("font_color", Palette.INK_TEXT)
	_info_date = UIKit.label(header_text, "—", "InkLabel")
	_info_date.add_theme_font_size_override("font_size", 16)
	_info_date.add_theme_color_override("font_color", Palette.CRIMSON)

	UIKit.hsep(column, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var pg_row := UIKit.hbox(column, 8)
	var pg_title := UIKit.label(pg_row, "PG", "InkLabel")
	pg_title.add_theme_font_size_override("font_size", 18)
	pg_title.add_theme_color_override("font_color", Palette.CRIMSON)
	_info_pg = UIKit.label(pg_row, "—", "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_info_pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_pg.add_theme_font_size_override("font_size", 20)
	_info_pg.add_theme_color_override("font_color", Palette.INK_TEXT)
	_info_pg_bar = UIKit.bar(column, 0, 30, Palette.GOLD, 12)

	var stats := UIKit.grid(column, 2, 8, 3)
	_info_treasury = _stat_pair(stats, "Tesoro")
	_info_prestige = _stat_pair(stats, "Prestigio")
	_info_regions = _stat_pair(stats, "Regiones")
	_info_armies = _stat_pair(stats, "Ejércitos")

	UIKit.hsep(column, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var court := UIKit.vbox(column, 2)
	_info_ruler = UIKit.label(court, "Gobernante: —", "InkLabel")
	_info_ruler.add_theme_font_size_override("font_size", 15)
	_info_ruler.add_theme_color_override("font_color", Palette.INK_TEXT)
	_info_heir = UIKit.label(court, "Heredero: —", "InkLabel")
	_info_heir.add_theme_font_size_override("font_size", 15)
	_info_heir.add_theme_color_override("font_color", Palette.INK_TEXT)

	UIKit.hsep(column, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var alerts_title := UIKit.label(column, "ALERTAS DEL REINO", "InkLabel")
	alerts_title.add_theme_font_size_override("font_size", 15)
	alerts_title.add_theme_color_override("font_color", Palette.CRIMSON)
	_alerts_box = UIKit.vbox(column, 3)

	var news_title := UIKit.label(column, "CRÓNICA RECIENTE", "InkLabel")
	news_title.add_theme_font_size_override("font_size", 15)
	news_title.add_theme_color_override("font_color", Palette.CRIMSON)
	_news_box = UIKit.vbox(column, 3)

	var expand := Control.new()
	expand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	expand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(expand)

	UIKit.hsep(column, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var buttons := UIKit.hbox(column, 6)
	var save_button := UIKit.button(buttons, "Guardar", "SmallButton", "GameState.save_game('autosave')")
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_pressed)
	var options_button := UIKit.button(buttons, "Opciones", "SmallButton", "Opciones y pausa")
	options_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_button.pressed.connect(_on_options_pressed)
	var menu_button := UIKit.button(buttons, "Menú", "SmallButton", "Volver al menú principal")
	menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_button.pressed.connect(_on_return_to_menu)
	_info_save = UIKit.label(column, "", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_info_save.add_theme_font_size_override("font_size", 12)


func _stat_pair(parent: Node, title_text: String) -> Label:
	var box := UIKit.vbox(parent, 0)
	var key_label := UIKit.label(box, title_text, "TinyLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	var value_label := UIKit.label(box, "—", "InkLabel")
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	return value_label


func _build_region_panel() -> void:
	_region_panel = RegionPanelScene.instantiate()
	add_child(_region_panel)
	if _region_panel.has_signal("closed"):
		_region_panel.connect("closed", _on_region_panel_closed)
	if _region_panel.has_signal("action_result"):
		_region_panel.connect("action_result", _on_action_result)
	_region_panel.visible = false


func _build_tooltip_and_overlays() -> void:
	_tooltip = TooltipScene.instantiate()
	add_child(_tooltip)
	_tooltip.visible = false

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 20
	add_child(_overlay_layer)


func _build_notifications() -> void:
	_notification_layer = CanvasLayer.new()
	_notification_layer.layer = 30
	add_child(_notification_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_layer.add_child(root)
	_notification_box = VBoxContainer.new()
	_notification_box.anchor_left = 1.0
	_notification_box.anchor_right = 1.0
	_notification_box.anchor_top = 1.0
	_notification_box.anchor_bottom = 1.0
	_notification_box.offset_left = -460
	_notification_box.offset_right = -20
	_notification_box.offset_top = -320
	_notification_box.offset_bottom = -70
	_notification_box.alignment = BoxContainer.ALIGNMENT_END
	_notification_box.add_theme_constant_override("separation", 6)
	_notification_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_notification_box)


# ==========================================================================
# Layout y refresco
# ==========================================================================
func _relayout() -> void:
	if _map_area == null:
		return
	var map_size := _map_area.size
	if map_size.x < 100.0 or map_size.y < 100.0:
		return
	var layout := TSBGame.map_layout()
	var regions: Variant = layout.get("regions", {})
	var centers: Dictionary = {}
	if regions is Dictionary:
		for region_id: Variant in (regions as Dictionary).keys():
			var entry: Variant = (regions as Dictionary)[region_id]
			if not (entry is Dictionary):
				continue
			var pos := Vector2(
				float((entry as Dictionary).get("x", 0.5)) * map_size.x,
				float((entry as Dictionary).get("y", 0.5)) * map_size.y)
			centers[str(region_id)] = pos
	_region_centers = centers
	_map_backdrop.call("configure", layout, centers, TSBGame.current_year())
	_refresh_regions()


func _refresh_regions() -> void:
	if _region_centers.is_empty():
		return
	var map_size := _map_area.size
	for region_id: Variant in _region_nodes.keys():
		var id := str(region_id)
		var node: Control = _region_nodes[region_id]
		var center: Variant = _region_centers.get(id)
		if not (center is Vector2):
			continue
		var layout_entry := TSBGame.layout_for(id)
		var radius_pair: Variant = layout_entry.get("r", [0.0295, 0.0335])
		var radius := Vector2(0.0295 * map_size.x, 0.0335 * map_size.y)
		if radius_pair is Array and (radius_pair as Array).size() >= 2:
			radius = Vector2(float((radius_pair as Array)[0]) * map_size.x, float((radius_pair as Array)[1]) * map_size.y)
		var data := TSBGame.region(id)
		data["label"] = str(layout_entry.get("label", TSBGame.region_name(id)))
		var armies := TSBGame.armies_in(id)
		node.call("configure", data, center, radius, armies)
		node.call("set_selected", id == _selected_region)


func _refresh_all() -> void:
	_refresh_regions()
	_council.call("refresh")
	_refresh_info_sidebar()
	if _preview_banner != null:
		_preview_banner.visible = not TSBGame.has_game()


func _refresh_info_sidebar() -> void:
	if _info_panel == null:
		return
	var fid := TSBGame.player_faction()
	var has_game := TSBGame.has_game()
	var faction_name := TSBGame.faction_name(fid) if not fid.is_empty() else "Sin partida"
	_info_faction.text = faction_name
	_info_date.text = "%s · %d" % [QUARTER_NAMES[TSBGame.current_quarter() - 1], TSBGame.current_year()]
	var color := TSBGame.faction_color(fid) if not fid.is_empty() else Palette.MUTED
	_info_shield.call("setup", _house_of(fid), color, true)

	_info_pg.text = "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)] if has_game else "—"
	_info_pg_bar.max_value = float(maxi(TSBGame.pg_max(), 1))
	_info_pg_bar.value = float(TSBGame.pg_remaining()) if has_game else 0.0
	_info_pg_bar.add_theme_stylebox_override("fill", Palette.stylebox(Palette.GOLD if TSBGame.pg_remaining() > 0 else Palette.CRIMSON, Color.TRANSPARENT, 0, 3))

	_info_treasury.text = "%s oro" % TSBGame.short_number(TSBGame.gold(fid)) if has_game else "%s oro" % TSBGame.short_number(TSBGame.gold(fid))
	_info_prestige.text = str(TSBGame.prestige(fid)) if has_game else "%d" % TSBGame.prestige(fid)
	_info_regions.text = "%d de %d" % [TSBGame.regions_owned_by(fid).size(), TSBGame.region_ids().size()]
	var army_count := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			army_count += 1
	_info_armies.text = "%d ejércitos" % army_count

	var ruler := TSBGame.ruler(fid)
	var heir := TSBGame.heir(fid)
	_info_ruler.text = "Gobernante: %s%s" % [str(ruler.get("name", "—")), _age_suffix(ruler)]
	_info_heir.text = "Heredero: %s%s" % [str(heir.get("name", "Sin heredero")), _age_suffix(heir)]

	_rebuild_alerts(fid, has_game)
	_rebuild_news(fid)
	_info_save.text = "Autoguardado: %s" % ("disponible" if TSBGame.has_save("autosave") else "—") if has_game else "Sin partida activa"


func _rebuild_alerts(fid: String, has_game: bool) -> void:
	UIKit.clear(_alerts_box)
	if not has_game:
		_alert_line("Sin partida activa: vista previa de datos 1337.", Palette.GOLD_DIM)
		_alert_line("Sistemas de turno en integración (AG-2).", Palette.MUTED)
		return
	var alerts := 0
	if TSBGame.pg_remaining() <= 0:
		_alert_line("Sin PG: termina el turno para gobernar de nuevo.", Palette.CRIMSON_BRIGHT)
		alerts += 1
	for region_id: Variant in TSBGame.regions_owned_by(fid):
		var support := TSBGame.support(str(region_id))
		if support < 25:
			_alert_line("Revuelta latente en %s (apoyo %d)." % [TSBGame.region_name(str(region_id)), support], Palette.CRIMSON_BRIGHT)
			alerts += 1
			if alerts >= 3:
				break
	if alerts < 3 and TSBGame.heir(fid).is_empty():
		_alert_line("Sin heredero: riesgo de extinción dinástica.", Palette.CRIMSON_BRIGHT)
		alerts += 1
	if alerts < 3 and TSBGame.gold(fid) < 300:
		_alert_line("Tesorería baja: %d oro." % TSBGame.gold(fid), Palette.GOLD)
		alerts += 1
	for faction_id: Variant in TSBGame.faction_ids():
		var other := str(faction_id)
		if other == fid:
			continue
		if TSBGame.are_at_war(fid, other):
			_alert_line("En guerra con %s." % TSBGame.faction_name(other), Palette.CRIMSON_BRIGHT)
			alerts += 1
			if alerts >= 4:
				break
	if alerts == 0:
		_alert_line("El reino goza de paz y orden.", Palette.GREEN)


func _alert_line(text: String, color: Color) -> void:
	var label := UIKit.label(_alerts_box, "· " + text, "TinyLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)


func _rebuild_news(_fid: String) -> void:
	UIKit.clear(_news_box)
	var entries: Array = TSBGame.event_log()
	var news_added := 0
	if not entries.is_empty():
		var start := maxi(entries.size() - 3, 0)
		for i in range(entries.size() - 1, start - 1, -1):
			var entry: Variant = entries[i]
			if entry is Dictionary:
				var text := str((entry as Dictionary).get("text", (entry as Dictionary).get("event_id", "")))
				if not text.is_empty():
					_news_line(text)
					news_added += 1
	if news_added == 0:
		var year_events := TSBGame.events_for_year(TSBGame.current_year())
		for event: Variant in year_events:
			if event is Dictionary:
				var news := str((event as Dictionary).get("news", ""))
				if not news.is_empty():
					_news_line(news)
					news_added += 1
				if news_added >= 2:
					break
	if news_added == 0:
		_news_line("Los cronistas aguardan los primeros sucesos del reinado.")


func _news_line(text: String) -> void:
	var label := UIKit.label(_news_box, "· " + text, "InkLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.1))


func _house_of(fid: String) -> String:
	if fid.is_empty():
		return "sovereign"
	var ruler := TSBGame.ruler(fid)
	var house := str(ruler.get("house", ""))
	return house if not house.is_empty() else fid


func _age_suffix(character_entry: Dictionary) -> String:
	if character_entry.is_empty():
		return ""
	var age := TSBGame.character_age(character_entry)
	return " (%d años)" % age if age > 0 else ""


# ==========================================================================
# Senales de gameplay
# ==========================================================================
func _connect_signals() -> void:
	# EventBus (contrato GDD §8.2; la UI nunca se acopla a los sistemas).
	_bus("turn_started", _on_turn_started)
	_bus("turn_ended", _on_turn_ended)
	_bus("year_advanced", _on_year_advanced_event)
	_bus("pg_changed", _on_pg_changed_bus)
	_bus("treasury_changed", _on_treasury_changed)
	_bus("region_assignment_changed", _on_region_assignment_changed)
	_bus("region_output_changed", _on_region_output_changed)
	_bus("unrest_triggered", _on_unrest_triggered)
	_bus("revolt_triggered", _on_revolt_triggered)
	_bus("army_created", _on_army_created)
	_bus("army_moved", _on_army_moved)
	_bus("army_destroyed", _on_army_destroyed)
	_bus("region_captured", _on_region_captured)
	_bus("battle_resolved", _on_battle_resolved_bus)
	_bus("relation_changed", _on_relation_changed)
	_bus("war_declared", _on_war_declared)
	_bus("peace_made", _on_peace_made)
	_bus("alliance_changed", _on_alliance_changed)
	_bus("character_born", _on_character_born)
	_bus("character_died", _on_character_died)
	_bus("marriage_formed", _on_marriage_formed)
	_bus("succession_resolved", _on_succession_resolved)
	_bus("regency_started", _on_regency_started)
	_bus("dynasty_extinct", _on_dynasty_extinct)
	_bus("game_event_triggered", _on_game_event_triggered)
	_bus("game_over", _on_game_over_bus)
	_bus("ui_notification", _on_ui_notification)
	_bus("turn_phase_changed", _on_phase_changed)

	# Senales propias de los autoloads (por si AG-2 emite ahi).
	_system("TurnManager", "turn_started", _on_turn_started)
	_system("TurnManager", "turn_ended", _on_turn_ended)
	_system("TurnManager", "year_advanced", _on_year_advanced_one_arg)
	_system("TurnManager", "pg_changed", _on_pg_changed_one_arg)
	_system("TurnManager", "phase_changed", _on_phase_changed)
	_system("EconomySystem", "treasury_changed", _on_treasury_changed)
	_system("EconomySystem", "assignment_changed", _on_region_assignment_changed)
	_system("EconomySystem", "region_output_changed", _on_region_output_changed)
	_system("EconomySystem", "unrest_triggered", _on_unrest_triggered)
	_system("MilitarySystem", "army_created", _on_army_created)
	_system("MilitarySystem", "army_moved", _on_army_moved)
	_system("MilitarySystem", "army_destroyed", _on_army_destroyed)
	_system("MilitarySystem", "armies_changed", _on_armies_changed)
	_system("BattleManager", "battle_resolved", _on_battle_resolved_bus)
	_system("DynastySystem", "character_born", _on_character_born)
	_system("DynastySystem", "character_died", _on_character_died)
	_system("DynastySystem", "marriage_formed", _on_marriage_formed)
	_system("DynastySystem", "succession_resolved", _on_succession_resolved)
	_system("DynastySystem", "regency_started", _on_regency_started)
	_system("DynastySystem", "dynasty_extinct", _on_dynasty_extinct)
	_system("DiplomacySystem", "war_declared", _on_war_declared)
	_system("DiplomacySystem", "peace_made", _on_peace_made)
	_system("DiplomacySystem", "alliance_changed", _on_alliance_changed)
	_system("DiplomacySystem", "relation_changed", _on_relation_changed)
	_system("DiplomacySystem", "proposal_resolved", _on_proposal_resolved)
	_system("GameState", "game_saved", _on_game_saved)
	_system("GameState", "game_loaded", _on_game_loaded)
	_system("GameState", "game_over", _on_game_over_bus)


func _bus(signal_name: String, handler: Callable) -> void:
	var node := get_node_or_null("/root/EventBus")
	if node != null and node.has_signal(signal_name):
		node.connect(signal_name, handler)


func _system(node_name: String, signal_name: String, handler: Callable) -> void:
	var node := get_node_or_null("/root/%s" % node_name)
	if node != null and node.has_signal(signal_name):
		node.connect(signal_name, handler)


# Handlers: firma exacta de cada senal.
func _on_turn_started(_quarter: int, _year: int) -> void:
	_refresh_all()
	_notify("Turno iniciado: %s de %d" % [QUARTER_NAMES[TSBGame.current_quarter() - 1], TSBGame.current_year()])


func _on_turn_ended(_quarter: int, _year: int) -> void:
	_refresh_all()


func _on_year_advanced_event(year: int) -> void:
	_refresh_all()
	_open_year_end(year)


func _on_year_advanced_one_arg(year: int) -> void:
	_refresh_all()
	_open_year_end(year)


func _on_pg_changed_bus(_faction_id: String, _remaining: int) -> void:
	_refresh_all()


func _on_pg_changed_one_arg(_remaining: int) -> void:
	_refresh_all()


func _on_phase_changed(_phase: String) -> void:
	if _council != null:
		_council.call("refresh")


func _on_treasury_changed(_faction_id: String, _gold: int) -> void:
	_refresh_all()


func _on_region_assignment_changed(_region_id: String, _worker_class: String, _amount: int) -> void:
	_refresh_all()
	if _region_panel != null and _region_panel.visible:
		_region_panel.call("refresh")


func _on_region_output_changed(_region_id: String, _output: Dictionary) -> void:
	if _region_panel != null and _region_panel.visible:
		_region_panel.call("refresh")


func _on_unrest_triggered(region_id: String, support: int) -> void:
	_notify("Descontento en %s (apoyo %d)." % [TSBGame.region_name(region_id), support], 2)


func _on_revolt_triggered(region_id: String, _faction_id: String) -> void:
	_notify("¡Revuelta en %s!" % TSBGame.region_name(region_id), 2)
	_refresh_all()


func _on_army_created(_army_id: String, _faction_id: String, region_id: String) -> void:
	_notify("Nuevo ejército en %s." % TSBGame.region_name(region_id))
	_refresh_all()


func _on_army_moved(_army_id: String, from_region: String, to_region: String) -> void:
	_notify("Ejército en marcha: %s → %s." % [TSBGame.region_name(from_region), TSBGame.region_name(to_region)])
	_refresh_all()


func _on_army_destroyed(_army_id: String, _faction_id: String) -> void:
	_notify("Un ejército ha sido destruido.", 2)
	_refresh_all()


func _on_armies_changed(_region_id: String) -> void:
	_refresh_all()


func _on_region_captured(region_id: String, faction_id: String) -> void:
	_notify("¡%s ha tomado %s!" % [TSBGame.faction_name(faction_id), TSBGame.region_name(region_id)], 1)
	_refresh_all()


func _on_battle_resolved_bus(report: Variant) -> void:
	var report_dict: Dictionary = {}
	if report is Dictionary:
		report_dict = report
	elif report is Object and (report as Object).has_method("to_dict"):
		var converted: Variant = (report as Object).call("to_dict")
		if converted is Dictionary:
			report_dict = converted
	_refresh_all()
	if report_dict.is_empty():
		_notify("Se ha librado una batalla (informe no disponible).", 2)
		return
	if not _battle_is_relevant(report_dict):
		_notify("Batalla en %s: victoria de %s (sin intervención de tu reino)." % [
			TSBGame.region_name(str(report_dict.get("region_id", ""))),
			TSBGame.faction_name(str(report_dict.get("winner_faction", ""))) if not str(report_dict.get("winner_faction", "")).is_empty() else "nadie",
		])
		return
	if _turn_processing:
		# Durante el turno de la IA se encola y se muestra el ultimo al final.
		_pending_battle_reports.append(report_dict)
		_notify("Batalla en %s: victoria de %s." % [
			TSBGame.region_name(str(report_dict.get("region_id", ""))),
			TSBGame.faction_name(str(report_dict.get("winner_faction", ""))) if not str(report_dict.get("winner_faction", "")).is_empty() else "nadie",
		], 1)
		return
	_open_overlay(BattleReportScene.resource_path, "battle", report_dict)


## Relevante para el jugador: su faccion lucha o su region esta en juego.
func _battle_is_relevant(report: Dictionary) -> bool:
	var fid := TSBGame.player_faction()
	if str(report.get("attacker_faction", "")) == fid or str(report.get("defender_faction", "")) == fid:
		return true
	var region_id := str(report.get("region_id", ""))
	if not region_id.is_empty() and TSBGame.region_owner(region_id) == fid:
		return true
	return false


func _flush_pending_battles() -> void:
	if _pending_battle_reports.is_empty():
		return
	var last: Dictionary = _pending_battle_reports[_pending_battle_reports.size() - 1]
	var count := _pending_battle_reports.size()
	_pending_battle_reports.clear()
	if _overlay_kind == "year_end" or _overlay_kind == "victory":
		_deferred_battle_report = last
		_notify("%d batalla(s) resueltas este turno; el informe se mostrará al cerrar esta pantalla." % count, 1)
		return
	_open_overlay(BattleReportScene.resource_path, "battle", last)


func _on_relation_changed(_faction_a: String, _faction_b: String, _value: int) -> void:
	if _overlay_kind == "diplomacy" and _overlay != null:
		_overlay.call("refresh")


func _on_war_declared(attacker: String, defender: String) -> void:
	_notify("¡Guerra! %s declara la guerra a %s." % [TSBGame.faction_name(attacker), TSBGame.faction_name(defender)], 2)
	_refresh_all()


func _on_peace_made(faction_a: String, faction_b: String) -> void:
	_notify("Paz entre %s y %s." % [TSBGame.faction_name(faction_a), TSBGame.faction_name(faction_b)], 1)
	_refresh_all()


func _on_alliance_changed(faction_a: String, faction_b: String, allied: bool) -> void:
	_notify("%s con %s." % ["Alianza" if allied else "Fin de la alianza", TSBGame.faction_name(faction_b)], 1)
	_refresh_all()


func _on_character_born(character_id: String, faction_id: String) -> void:
	if faction_id == TSBGame.player_faction():
		_notify("Nace %s en la casa real." % str(TSBGame.character(character_id).get("name", "un heredero")), 1)
	_refresh_all()


func _on_character_died(character_id: String, _cause: String) -> void:
	_notify("Ha fallecido %s." % str(TSBGame.character(character_id).get("name", "un personaje")), 2)
	_refresh_all()


func _on_marriage_formed(ruler_id: String, spouse_id: String) -> void:
	_notify("Matrimonio: %s y %s." % [str(TSBGame.character(ruler_id).get("name", "—")), str(TSBGame.character(spouse_id).get("name", "—"))], 1)
	_refresh_all()


func _on_succession_resolved(faction_id: String, heir_id: String) -> void:
	if faction_id == TSBGame.player_faction():
		_notify("Sucesión resuelta: %s." % str(TSBGame.character(heir_id).get("name", "nuevo soberano")), 2)
	_refresh_all()


func _on_regency_started(faction_id: String, regent_id: String) -> void:
	if faction_id == TSBGame.player_faction():
		_notify("Regencia: %s gobierna por el heredero menor." % str(TSBGame.character(regent_id).get("name", "—")), 2)
	_refresh_all()


func _on_dynasty_extinct(faction_id: String) -> void:
	_notify("La dinastía de %s se ha extinguido." % TSBGame.faction_name(faction_id), 2)
	_refresh_all()


func _on_game_event_triggered(event_id: String, _payload: Dictionary) -> void:
	_notify("Suceso histórico: %s" % event_id.replace("_", " "), 1)
	_refresh_all()


func _on_game_over_bus(faction_id: String, victory: bool, reason: String) -> void:
	_open_victory(faction_id, victory, reason)


func _on_ui_notification(message: String, level: int) -> void:
	_notify(message, level)


func _on_proposal_resolved(_actor: String, _target: String, _action: String, _accepted: bool) -> void:
	if _overlay_kind == "diplomacy" and _overlay != null:
		_overlay.call("refresh")


func _on_game_saved(_slot: String) -> void:
	_info_save.text = "Partida guardada."
	_notify("Partida guardada.", 1)


func _on_game_loaded(_slot: String) -> void:
	_refresh_all()
	_notify("Partida cargada.", 1)


# ==========================================================================
# Interaccion del mapa
# ==========================================================================
func _on_region_hovered(region_id: String) -> void:
	if _tooltip == null:
		return
	_tooltip.call("show_text", _region_tooltip_bbcode(region_id))
	_tooltip.call("follow", get_global_mouse_position())


func _on_region_unhovered(_region_id: String) -> void:
	if _tooltip != null:
		_tooltip.call("hide_tip")


func _on_region_clicked(region_id: String) -> void:
	_selected_region = region_id
	for id: Variant in _region_nodes.keys():
		var node: Control = _region_nodes[id]
		node.call("set_selected", str(id) == region_id)
	if _region_panel != null:
		_region_panel.call("open", region_id)
	if _tooltip != null:
		_tooltip.call("hide_tip")


func _region_tooltip_bbcode(region_id: String) -> String:
	var data := TSBGame.region(region_id)
	var owner := str(data.get("owner", ""))
	var owner_name := TSBGame.faction_name(owner) if not owner.is_empty() else "Independiente"
	var owner_color := TSBGame.faction_color(owner) if not owner.is_empty() else Palette.MUTED
	var lines: Array[String] = []
	lines.append("[b][color=#%s]%s[/color][/b]" % [owner_color.to_html(false), str(data.get("name", region_id))])
	lines.append("[color=#6b5a3e]%s · %s[/color]" % [owner_name, _terrain_label(str(data.get("terrain", "")))])
	lines.append("Población: %s   ·   Riqueza: %d" % [TSBGame.short_number(int(data.get("population", 0))), int(data.get("base_wealth", 0))])
	var support := TSBGame.support(region_id)
	lines.append("Apoyo: %d/100   ·   Edificios: %d" % [support, (data.get("buildings", []) as Array).size() if data.get("buildings") is Array else 0])
	var armies := TSBGame.armies_in(region_id)
	var soldiers := 0
	for army: Variant in armies:
		if army is Dictionary:
			soldiers += TSBGame.army_soldiers(army)
	lines.append("Ejércitos: %d (%s soldados)" % [armies.size(), TSBGame.short_number(soldiers)])
	lines.append("[i][color=#7f1f26]Click para abrir el panel de la región[/color][/i]")
	return "\n".join(lines)


func _terrain_label(terrain: String) -> String:
	var labels := {
		"plains": "Llanura",
		"forest": "Bosque",
		"mountain": "Montaña",
		"coast": "Costa",
		"city": "Ciudad",
	}
	return str(labels.get(terrain, terrain.capitalize()))


# ==========================================================================
# Acciones de UI
# ==========================================================================
func _on_region_panel_closed() -> void:
	_selected_region = ""
	if _region_panel != null:
		_region_panel.visible = false
	for id: Variant in _region_nodes.keys():
		var node: Control = _region_nodes[id]
		node.call("set_selected", false)


func _on_action_result(message: String, ok: bool) -> void:
	_notify(message, 1 if ok else 2)
	_refresh_all()


func _on_end_turn_requested() -> void:
	if not TSBGame.has_game():
		_notify("Inicia una partida (Nuevo juego) para terminar turnos.", 2)
		return
	if _turn_processing:
		return
	_turn_processing = true
	_notify("La IA rival delibera…")
	_council.call("refresh")
	await get_tree().process_frame
	TSBGame.end_turn()
	_turn_processing = false
	_refresh_all()
	_notify("Trimestre completado: %s de %d" % [QUARTER_NAMES[TSBGame.current_quarter() - 1], TSBGame.current_year()], 1)
	_flush_pending_battles()


func _on_save_pressed() -> void:
	if not TSBGame.has_game():
		_notify("Inicia una partida antes de guardar.", 2)
		return
	if TSBGame.save_game("autosave"):
		_notify("Partida guardada en user://saves/autosave.json", 1)
	else:
		_notify("No se pudo guardar la partida.", 2)
	_refresh_all()


func _on_options_pressed() -> void:
	_open_options()


func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _open_options() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	_overlay = OptionsScene.instantiate()
	_overlay_kind = "options"
	_overlay_layer.add_child(_overlay)
	if _overlay.has_method("open"):
		_overlay.call("open", true)
	if _overlay.has_signal("closed"):
		_overlay.connect("closed", _on_overlay_closed)


func _open_overlay(scene_path: String, kind: String, setup_arg: Variant = null) -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
		_overlay = null
	var resource: Variant = load(scene_path)
	if not (resource is PackedScene):
		_notify("Pantalla no disponible todavía (%s)." % kind, 2)
		return
	_overlay = (resource as PackedScene).instantiate()
	_overlay_kind = kind
	_overlay_layer.add_child(_overlay)
	if setup_arg != null and _overlay.has_method("setup"):
		_overlay.call("setup", setup_arg)
	if _overlay.has_signal("closed"):
		_overlay.connect("closed", _on_overlay_closed)
	if _overlay.has_signal("region_requested"):
		_overlay.connect("region_requested", _on_overlay_region_requested)
	if _tooltip != null:
		_tooltip.call("hide_tip")


func _on_overlay_region_requested(region_id: String) -> void:
	_on_region_clicked(region_id)


func _open_year_end(year: int) -> void:
	if _overlay_kind == "year_end":
		return
	_open_overlay(YearEndScene.resource_path, "year_end", year)


func _open_victory(faction_id: String, victory: bool, reason: String) -> void:
	var payload := {"faction_id": faction_id, "victory": victory, "reason": reason}
	_open_overlay(VictoryScene.resource_path, "victory", payload)


func _on_overlay_closed() -> void:
	var closed_kind := _overlay_kind
	_overlay = null
	_overlay_kind = ""
	_refresh_all()
	if not _deferred_battle_report.is_empty() and (closed_kind == "year_end" or closed_kind == "victory"):
		var report := _deferred_battle_report
		_deferred_battle_report = {}
		_open_overlay(BattleReportScene.resource_path, "battle", report)


# ==========================================================================
# Notificaciones y teclado
# ==========================================================================
func _notify(message: String, level: int = 0) -> void:
	if _notification_box == null or message.is_empty():
		return
	# Evita avalanchas de avisos: maximo 4 simultaneos y sin duplicar el ultimo.
	if _notification_box.get_child_count() > 0:
		var last_child := _notification_box.get_child(_notification_box.get_child_count() - 1)
		var last_text := str(last_child.get_meta("message", ""))
		if last_text == message:
			return
	while _notification_box.get_child_count() >= 4:
		var oldest := _notification_box.get_child(0)
		_notification_box.remove_child(oldest)
		oldest.queue_free()
	var color := Palette.INK
	var border := Palette.GOLD_DIM
	if level == 1:
		color = Color("1d3327")
		border = Palette.GREEN_BRIGHT
	elif level == 2:
		color = Color("3a1a1d")
		border = Palette.CRIMSON_BRIGHT
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(color, 0.95), border, 1, 4, 12, 7))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("message", message)
	_notification_box.add_child(panel)
	var label := UIKit.label(panel, message, "SmallLabel")
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(380, 0)
	var timer := get_tree().create_timer(4.0)
	var panel_ref: WeakRef = weakref(panel)
	timer.timeout.connect(func() -> void:
		var alive_panel: Variant = panel_ref.get_ref()
		if alive_panel != null and is_instance_valid(alive_panel):
			(alive_panel as Node).queue_free())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _overlay != null and is_instance_valid(_overlay):
			return
		if _region_panel != null and _region_panel.visible:
			_on_region_panel_closed()
			get_viewport().set_input_as_handled()
			return
		_open_options()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
			if _overlay == null:
				_on_end_turn_requested()
				get_viewport().set_input_as_handled()
