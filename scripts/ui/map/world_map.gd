extends Node2D
## Mapa principal (GDD v1.4 §9.3 + §10.1): atlas por capas con Camera2D.
##
## Capas (contrato Fase 2 §2):
##   1. Terreno   assets/art/map/terrain_base.png (4096x3072, generado por tools/generate_map_terrain.py)
##   2. Fronteras data/map_borders.json por ano (1337/1402/1453) + relleno de faccion
##   3. Interactiva hit-test punto-en-poligono, hover dorado 18 %, tooltip y click
##   4. Entidades banderas, ciudades, ejercitos, nombres con elision y etiquetas de mar
## HUD del consejo/panel en CanvasLayer independiente de la camara.
##
## Regla de oro: solo lee por la fachada TSBGame y se repinta con senales; nunca
## muta GameState.state ni diccionarios de sistemas. La vista de ano NO altera
## la partida (solo la capa politica).

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")
const MapBordersLayer = preload("res://scripts/ui/map/map_borders_layer.gd")
const MapInteractiveLayer = preload("res://scripts/ui/map/map_interactive_layer.gd")
const MapEntitiesLayer = preload("res://scripts/ui/map/map_entities_layer.gd")
const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")
const AdvisorPanel = preload("res://scripts/ui/widgets/advisor_panel.gd")
const TutorialHighlight = preload("res://scripts/ui/widgets/tutorial_highlight.gd")
const UIPreferences = preload("res://scripts/ui/ui_preferences.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")
const UILegibility = preload("res://scripts/ui/ui_legibility.gd")
const FontScaler = preload("res://scripts/ui/widgets/font_scaler.gd")
const CouncilScene = preload("res://scenes/council/council_menu.tscn")
const RegionPanelScene = preload("res://scenes/map/region_panel.tscn")
const TooltipScene = preload("res://scenes/ui/tooltip.tscn")
const OptionsScene = preload("res://scenes/ui/options_menu.tscn")
const BattleReportScene = preload("res://scenes/battle/battle_report.tscn")
const YearEndScene = preload("res://scenes/ui/year_end_report.tscn")
const VictoryScene = preload("res://scenes/ui/victory_screen.tscn")
const OrderConfirmationScene = preload("res://scenes/ui/order_confirmation.tscn")
const SaveLoadScene = preload("res://scenes/ui/save_load_screen.tscn")
const AttackScene = preload("res://scenes/military/attack_screen.tscn")
const FamilyScene = preload("res://scenes/family/family_tree.tscn")
const DiplomacyScene = preload("res://scenes/diplomacy/diplomacy_screen.tscn")
const MilitaryScene = preload("res://scenes/military/military_screen.tscn")
const EconomyScene = preload("res://scenes/economy/economy_screen.tscn")
const CourtScene = preload("res://scenes/ui/court_overview.tscn")

const TACTICAL_SCENE := "res://scenes/battle/tactical_map.tscn"
const CLOSE_COMBAT_SCENE := "res://scenes/battle/close_combat.tscn"
const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const TERRAIN_TEXTURE := "res://assets/art/map/terrain_base.png"

const QUARTER_NAMES: Array[String] = ["INVIERNO", "PRIMAVERA", "VERANO", "OTOÑO"]
const SEASON_TINT_COLORS: Array[Color] = [
	Color(0.35, 0.62, 0.40, 0.06),
	Color(0.82, 0.58, 0.24, 0.065),
	Color(0.72, 0.40, 0.18, 0.065),
	Color(0.32, 0.46, 0.62, 0.07),
]
const MAP_W := 2048.0
const MAP_H := 1536.0
const SIDEBAR_LEFT := 340.0
const SIDEBAR_RIGHT := 560.0
const ZOOM_MIN := 0.5
const ZOOM_MAX := 3.0
const DEFAULT_ZOOM := 0.7

# Mundo y camara.
var _world: Node2D = null
var _terrain: Sprite2D = null
var _borders: Node2D = null
var _interactive: Node2D = null
var _entities: Node2D = null
var _camera: Camera2D = null
var _view_year := 1337
var _selected_region := ""
var _hover_region := ""
var _dragging := false
var _drag_moved := false
var _drag_button := 0
var _drag_start_mouse := Vector2.ZERO
var _drag_start_camera := Vector2.ZERO

# HUD.
var _hud_layer: CanvasLayer = null
var _hud: Control = null
var _council: Control = null
var _info_panel: PanelContainer = null
var _info_portrait: Control = null
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

var _sovereign_panel: PanelContainer = null
var _sovereign_portrait: Control = null
var _sovereign_name: Label = null
var _sovereign_sub: Label = null
var _sovereign_heir: Label = null
var _year_buttons: Dictionary = {}
var _year_label: Label = null
var _borders_notice: PanelContainer = null
var _zoom_label: Label = null
var _zoom_controls: Control = null
var _advisor: Control = null
var _tutorial_highlight: Control = null
var _tutorial_layer: CanvasLayer = null
var _season_hud: Label = null
var _season_tint: ColorRect = null
var _deferred_year_end: int = 0
var _end_turn_in_progress := false
var _closed_season := ""
var _closed_year := 0
var _closed_actions: Array = []
var _bulletin_pending := false
var _map_hint: Label = null
var _preview_banner: PanelContainer = null
var _view_banner: PanelContainer = null

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
var _tactical_pending_report: Dictionary = {}


func _ready() -> void:
	TSBGame.ensure_data()
	UIAudio.play_music("map")
	_build_world()
	_build_hud()
	_build_council()
	_build_info_sidebar()
	_build_sovereign_panel()
	_build_year_selector()
	_build_zoom_controls()
	_build_map_labels()
	_build_region_panel()
	_build_tooltip_and_overlays()
	_build_notifications()
	_build_tutorial_ui()
	_connect_signals()
	_view_year = _default_view_year()
	_set_view_year(_view_year)
	_refresh_all()
	set_process(true)
	FontScaler.attach(self)


func _process(_delta: float) -> void:
	# Coste minimo: solo clamp de camara y seguimiento de tooltip.
	_clamp_camera()
	if _advisor != null:
		_update_tutorial_highlight()
	if _tooltip != null and _tooltip.visible:
		_tooltip.call("follow", get_viewport().get_mouse_position())
		var mouse := get_viewport().get_mouse_position()
		if _is_hud_position(mouse):
			_tooltip.call("hide_tip")


func _is_hud_position(screen_pos: Vector2) -> bool:
	var view_size := get_viewport_rect().size
	if screen_pos.x < SIDEBAR_LEFT or screen_pos.x > view_size.x - SIDEBAR_RIGHT:
		return true
	if screen_pos.y < 12.0:
		return true
	return false


# ==========================================================================
# Capa 1: mundo + camara
# ==========================================================================
func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "WorldLayers"
	add_child(_world)

	var table := Polygon2D.new()
	table.polygon = PackedVector2Array([
		Vector2(-6000, -6000), Vector2(MAP_W + 6000, -6000),
		Vector2(MAP_W + 6000, MAP_H + 6000), Vector2(-6000, MAP_H + 6000),
	])
	table.color = Palette.INK_DEEP
	table.z_index = -20
	_world.add_child(table)

	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-10, 16), Vector2(MAP_W + 18, 16),
		Vector2(MAP_W + 18, MAP_H + 24), Vector2(-10, MAP_H + 24),
	])
	shadow.color = Color(0.0, 0.0, 0.0, 0.45)
	shadow.z_index = -10
	_world.add_child(shadow)

	_terrain = Sprite2D.new()
	_terrain.name = "TerrainLayer"
	if ResourceLoader.exists(TERRAIN_TEXTURE):
		_terrain.texture = load(TERRAIN_TEXTURE)
	else:
		push_warning("Mapa: falta %s; se generara con tools/generate_map_terrain.py" % TERRAIN_TEXTURE)
	_terrain.centered = false
	_terrain.position = Vector2.ZERO
	_terrain.scale = Vector2(0.5, 0.5)  # 4096x3072 -> 2048x1536 unidades de mundo
	_terrain.z_index = 0
	_world.add_child(_terrain)

	_borders = MapBordersLayer.new()
	_borders.name = "BordersLayer"
	_borders.call("set_map_size", Vector2(MAP_W, MAP_H))
	_world.add_child(_borders)

	_interactive = MapInteractiveLayer.new()
	_interactive.name = "InteractiveLayer"
	_interactive.z_index = 2
	_interactive.call("setup", _borders)
	_world.add_child(_interactive)

	_entities = MapEntitiesLayer.new()
	_entities.name = "EntitiesLayer"
	_entities.z_index = 3
	_world.add_child(_entities)

	_camera = Camera2D.new()
	_camera.name = "MapCamera"
	_camera.position = Vector2(MAP_W * 0.5, MAP_H * 0.5)
	_camera.zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	_camera.enabled = true
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(_camera)


func _clamp_camera() -> void:
	if _camera == null:
		return
	var view_size := get_viewport_rect().size
	var half := view_size * 0.5 / _camera.zoom
	var target := _camera.position
	if half.x >= MAP_W * 0.5:
		target.x = MAP_W * 0.5
	else:
		target.x = clampf(target.x, half.x, MAP_W - half.x)
	if half.y >= MAP_H * 0.5:
		target.y = MAP_H * 0.5
	else:
		target.y = clampf(target.y, half.y, MAP_H - half.y)
	_camera.position = target


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform := get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos


func _set_zoom(new_zoom: float, focus_screen: Vector2 = Vector2.INF) -> void:
	if _camera == null:
		return
	var clamped := clampf(new_zoom, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(clamped, _camera.zoom.x):
		return
	var focus := focus_screen
	if focus == Vector2.INF:
		focus = get_viewport_rect().size * 0.5
	var world_before := _screen_to_world(focus)
	_camera.zoom = Vector2(clamped, clamped)
	var world_after := _screen_to_world(focus)
	_camera.position += world_before - world_after
	_clamp_camera()
	_update_zoom_dependent()


func _update_zoom_dependent() -> void:
	if _camera == null:
		return
	var z := _camera.zoom.x
	_borders.call("set_zoom", z)
	_interactive.call("set_zoom", z)
	_entities.call("set_zoom", z)
	if _zoom_label != null:
		_zoom_label.text = "%.2f×" % z
	_refresh_view_banner()


# ==========================================================================
# HUD
# ==========================================================================
func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUDLayer"
	_hud_layer.layer = 10
	add_child(_hud_layer)
	_hud = Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.theme = ThemeBuilder.get_theme()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_hud)
	_build_season_hud()


func _build_season_hud() -> void:
	# D-079: tinte sutil por estación, generado por código y desactivable en Opciones.
	_season_tint = ColorRect.new()
	_season_tint.anchor_left = 0.0
	_season_tint.anchor_right = 1.0
	_season_tint.anchor_top = 0.0
	_season_tint.anchor_bottom = 1.0
	_season_tint.offset_left = SIDEBAR_LEFT
	_season_tint.offset_right = -SIDEBAR_RIGHT
	_season_tint.offset_bottom = -26
	_season_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_season_tint.color = Color(0.35, 0.55, 0.40, 0.06)
	_hud.add_child(_season_tint)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -390
	panel.offset_right = 390
	panel.offset_top = 102
	panel.offset_bottom = 132
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.82), Palette.with_alpha(Palette.GOLD_DIM, 0.8), 1, 3, 10, 3))
	_hud.add_child(panel)
	_season_hud = UIKit.label(panel, "", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_season_hud.add_theme_font_size_override("font_size", 15)
	_season_hud.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_season_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var help := UIHelp.add_button(_hud, "world_map")
	help.offset_right = -SIDEBAR_RIGHT - 16
	help.offset_left = -SIDEBAR_RIGHT - 58
	help.offset_top = 100
	help.offset_bottom = 142


func _build_map_labels() -> void:
	_map_hint = UIKit.label(_hud, "Rueda = zoom · arrastrar (botón derecho/central) = mover · click = región · Enter = terminar turno", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_map_hint.add_theme_font_size_override("font_size", 13)
	_map_hint.add_theme_color_override("font_color", Palette.with_alpha(Palette.PARCHMENT, 0.75))
	_map_hint.anchor_left = 0.0
	_map_hint.anchor_right = 1.0
	_map_hint.anchor_top = 1.0
	_map_hint.anchor_bottom = 1.0
	_map_hint.offset_top = -30
	_map_hint.offset_bottom = -8
	_map_hint.offset_left = SIDEBAR_LEFT
	_map_hint.offset_right = -SIDEBAR_RIGHT
	_map_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_preview_banner = PanelContainer.new()
	_preview_banner.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.88), Palette.GOLD, 1, 4, 14, 6))
	_preview_banner.anchor_left = 0.5
	_preview_banner.anchor_right = 0.5
	_preview_banner.offset_left = -320
	_preview_banner.offset_right = 320
	_preview_banner.offset_top = 128
	_preview_banner.offset_bottom = 166
	_preview_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_preview_banner)
	var banner := UIKit.label(_preview_banner, "VISTA PREVIA · datos del escenario · sistemas en integración", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	banner.add_theme_font_size_override("font_size", 14)
	banner.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_preview_banner.visible = false

	_view_banner = PanelContainer.new()
	_view_banner.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.82), Palette.GOLD_DIM, 1, 4, 12, 4))
	_view_banner.anchor_left = 0.5
	_view_banner.anchor_right = 0.5
	_view_banner.offset_left = -170
	_view_banner.offset_right = 170
	_view_banner.offset_top = 92
	_view_banner.offset_bottom = 122
	_view_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_view_banner)
	var view_label := UIKit.label(_view_banner, "", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	view_label.name = "ViewText"
	view_label.add_theme_font_size_override("font_size", 13)
	view_label.add_theme_color_override("font_color", Palette.PARCHMENT)
	_view_banner.visible = false

	_borders_notice = PanelContainer.new()
	_borders_notice.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.86), Palette.CRIMSON_BRIGHT, 1, 4, 12, 5))
	_borders_notice.anchor_left = 0.5
	_borders_notice.anchor_right = 0.5
	_borders_notice.offset_left = -350
	_borders_notice.offset_right = 350
	_borders_notice.offset_top = 128
	_borders_notice.offset_bottom = 164
	_borders_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_borders_notice)
	var notice := UIKit.label(_borders_notice, "Fronteras históricas pendientes (AG-1) · se muestra el terreno base", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	notice.add_theme_font_size_override("font_size", 13)
	notice.add_theme_color_override("font_color", Palette.PARCHMENT_LIGHT)
	_borders_notice.visible = false


func _build_sovereign_panel() -> void:
	_sovereign_panel = PanelContainer.new()
	_sovereign_panel.add_theme_stylebox_override("panel", Palette.ink_style(10, Palette.GOLD_DIM, 2))
	_sovereign_panel.position = Vector2(SIDEBAR_LEFT + 16.0, 16.0)
	_sovereign_panel.custom_minimum_size = Vector2(360, 132)
	_sovereign_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(_sovereign_panel)
	var row := UIKit.hbox(_sovereign_panel, 10)
	_sovereign_portrait = PortraitFrame.make("", Vector2(88, 108))
	if _sovereign_portrait != null:
		row.add_child(_sovereign_portrait)
	var text := UIKit.vbox(row, 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(text, "SOBERANO", "TinyLabel")
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Palette.GOLD)
	_sovereign_name = UIKit.label(text, "—", "ParchmentLabel")
	_sovereign_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sovereign_name.add_theme_font_size_override("font_size", 22)
	_sovereign_sub = UIKit.label(text, "—", "TinyLabel")
	_sovereign_sub.add_theme_font_size_override("font_size", 13)
	_sovereign_heir = UIKit.label(text, "—", "TinyLabel")
	_sovereign_heir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sovereign_heir.add_theme_font_size_override("font_size", 12)


func _build_year_selector() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.ink_style(8, Palette.GOLD_DIM, 1))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = 16
	panel.offset_bottom = 84
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(panel)
	var column := UIKit.vbox(panel, 3)
	var header := UIKit.hbox(column, 6)
	var caption := UIKit.label(header, "VISTA POLÍTICA", "TinyLabel")
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Palette.GOLD)
	_year_label = UIKit.label(header, "", "TinyLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_year_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_year_label.add_theme_font_size_override("font_size", 12)
	var buttons := UIKit.hbox(column, 6)
	var group := ButtonGroup.new()
	var years: Array = TSBGame.map_border_years()
	if years.is_empty():
		years = [1337, 1402, 1453]
	for year_value: Variant in years:
		var year_int := int(year_value)
		var button := UIKit.button(buttons, str(year_int), "SmallButton", "Vista política del año %d (no altera la partida)" % year_int)
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 32)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _set_view_year(year_int))
		_year_buttons[year_int] = button


func _build_zoom_controls() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.ink_style(6, Palette.GOLD_DIM, 1))
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -SIDEBAR_RIGHT - 186
	panel.offset_right = -SIDEBAR_RIGHT - 16
	panel.offset_top = -64
	panel.offset_bottom = -24
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(panel)
	_zoom_controls = panel
	var row := UIKit.hbox(panel, 6)
	var zoom_out := UIKit.button(row, "-", "SmallButton")
	zoom_out.custom_minimum_size = Vector2(38, 30)
	zoom_out.pressed.connect(func() -> void: _set_zoom(_camera.zoom.x / 1.2))
	_zoom_label = UIKit.label(row, "%.2f×" % _camera.zoom.x, "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_zoom_label.custom_minimum_size = Vector2(54, 0)
	_zoom_label.add_theme_font_size_override("font_size", 13)
	var zoom_in := UIKit.button(row, "+", "SmallButton")
	zoom_in.custom_minimum_size = Vector2(38, 30)
	zoom_in.pressed.connect(func() -> void: _set_zoom(_camera.zoom.x * 1.2))
	var reset := UIKit.button(row, "AJUSTAR", "SmallButton")
	reset.custom_minimum_size = Vector2(78, 30)
	reset.pressed.connect(func() -> void: _set_zoom(DEFAULT_ZOOM))


func _build_council() -> void:
	_council = CouncilScene.instantiate()
	_hud.add_child(_council)
	_council.anchor_left = 0.0
	_council.anchor_right = 0.0
	_council.anchor_top = 0.0
	_council.anchor_bottom = 1.0
	_council.offset_left = 0.0
	_council.offset_right = SIDEBAR_LEFT
	_council.offset_top = 0.0
	_council.offset_bottom = 0.0
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
	if _council.has_signal("help_requested"):
		_council.connect("help_requested", func() -> void: _open_overlay("res://scenes/ui/help_overlay.tscn", "help"))
	if _council.has_signal("chronicle_requested"):
		_council.connect("chronicle_requested", func() -> void: _open_overlay("res://scenes/ui/chronicle_screen.tscn", "chronicle"))
	if _council.has_signal("advisor_toggled"):
		_council.connect("advisor_toggled", func(_enabled: bool) -> void: _refresh_tutorial_ui())
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
	_info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_info_panel.clip_contents = true
	_hud.add_child(_info_panel)

	var margin := UIKit.margin(_info_panel, 6, 6, 6, 6)
	var info_scroll := ScrollContainer.new()
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(info_scroll)
	var column := UIKit.vbox(info_scroll, 7)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var header := UIKit.hbox(column, 10)
	_info_portrait = PortraitFrame.make("", Vector2(84, 100))
	if _info_portrait != null:
		header.add_child(_info_portrait)
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
	_info_pg.tooltip_text = "Puntos de Gobierno (PG): se gastan en acciones de corte, diplomacia, militar y economía. Se recuperan al empezar el siguiente turno."
	_info_pg_bar = UIKit.bar(column, 0, 30, Palette.GOLD, 12)
	_info_pg_bar.tooltip_text = "PG restantes / PG máximos del turno"

	var stats := UIKit.grid(column, 2, 8, 3)
	_info_treasury = _stat_pair(stats, "Tesoro")
	_info_prestige = _stat_pair(stats, "Prestigio")
	_info_regions = _stat_pair(stats, "Regiones")
	_info_armies = _stat_pair(stats, "Ejércitos")

	UIKit.hsep(column, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var court := UIKit.vbox(column, 2)
	_info_ruler = UIKit.label(court, "Gobernante: —", "InkLabel")
	_info_ruler.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_ruler.add_theme_font_size_override("font_size", 15)
	_info_ruler.add_theme_color_override("font_color", Palette.INK_TEXT)
	_info_heir = UIKit.label(court, "Heredero: —", "InkLabel")
	_info_heir.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var save_button := UIKit.button(buttons, "Guardar/Cargar", "SmallButton", "Abrir ranuras de guardado (D-085)")
	save_button.name = "save_button"
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
	_info_save.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


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
	_hud.add_child(_region_panel)
	_region_panel.anchor_left = 1.0
	_region_panel.anchor_right = 1.0
	_region_panel.anchor_top = 0.0
	_region_panel.anchor_bottom = 1.0
	_region_panel.offset_left = -SIDEBAR_RIGHT
	_region_panel.offset_right = 0.0
	if _region_panel.has_signal("closed"):
		_region_panel.connect("closed", _on_region_panel_closed)
	if _region_panel.has_signal("action_result"):
		_region_panel.connect("action_result", _on_action_result)
	if _region_panel.has_signal("battle_requested"):
		_region_panel.connect("battle_requested", _on_battle_requested)
	_region_panel.visible = false


func _build_tooltip_and_overlays() -> void:
	_tooltip = TooltipScene.instantiate()
	_hud.add_child(_tooltip)
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
# Tutorial / Consejero (D-073)
# ==========================================================================
func _build_tutorial_ui() -> void:
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 25
	add_child(_tutorial_layer)
	_tutorial_highlight = TutorialHighlight.new()
	_tutorial_layer.add_child(_tutorial_highlight)
	_advisor = AdvisorPanel.new()
	_advisor.anchor_left = 1.0
	_advisor.anchor_right = 1.0
	_advisor.anchor_top = 1.0
	_advisor.anchor_bottom = 1.0
	_advisor.offset_left = -SIDEBAR_RIGHT - 470
	_advisor.offset_right = -SIDEBAR_RIGHT - 20
	_advisor.offset_top = -330
	_advisor.offset_bottom = -90
	_tutorial_layer.add_child(_advisor)


func _advance_tutorial(condition_id: String) -> void:
	if TSBGame.tutorial_active():
		TSBGame.tutorial_advance(condition_id)
		_update_tutorial_highlight()


func _refresh_tutorial_ui() -> void:
	if _advisor != null:
		_advisor.call("refresh")
	_update_tutorial_highlight()


func _update_tutorial_highlight() -> void:
	if _tutorial_highlight == null:
		return
	if not TSBGame.tutorial_active():
		_tutorial_highlight.call("clear_highlight")
		return
	var step := TSBGame.tutorial_step()
	if step.is_empty():
		_tutorial_highlight.call("clear_highlight")
		return
	var highlight := str(step.get("highlight", ""))
	if _overlay != null and is_instance_valid(_overlay) and highlight not in ["attack_button", "expedition_button", "save_button"]:
		_tutorial_highlight.call("clear_highlight")
		return
	var target := _tutorial_target_rect(highlight)
	var hint := "Consejo: %s" % str(step.get("title", ""))
	_tutorial_highlight.call("set_highlight", target, hint)


func _tutorial_target_rect(highlight: String) -> Rect2:
	var view_size := get_viewport_rect().size
	match highlight:
		"map_region":
			return Rect2(Vector2(SIDEBAR_LEFT + 12, 140), Vector2(view_size.x - SIDEBAR_LEFT - SIDEBAR_RIGHT - 24, view_size.y - 210))
		"workers_panel":
			if _region_panel != null and _region_panel.visible:
				return _region_panel.get_global_rect()
			return Rect2(Vector2(view_size.x - SIDEBAR_RIGHT - 460, 100), Vector2(440, view_size.y - 180))
		"family_button":
			return _control_rect_by_text("Familia", Rect2(Vector2(20, 280), Vector2(SIDEBAR_LEFT - 30, 52)))
		"diplomacy_button":
			return _control_rect_by_text("Diplomacia", Rect2(Vector2(20, 340), Vector2(SIDEBAR_LEFT - 30, 52)))
		"military_button":
			return _control_rect_by_text("Militar", Rect2(Vector2(20, 400), Vector2(SIDEBAR_LEFT - 30, 52)))
		"market_button":
			if _overlay != null and _overlay_kind == "market":
				return _overlay.get_global_rect()
			var market := _control_rect_by_text("MERCADO", Rect2())
			if market.size.x > 0.0:
				return market
			return _control_rect_by_text("Economía", Rect2(Vector2(20, 460), Vector2(SIDEBAR_LEFT - 30, 52)))
		"end_turn_button":
			return _control_rect_by_text("TERMINAR TURNO", Rect2(Vector2(20, view_size.y - 120), Vector2(SIDEBAR_LEFT - 40, 56)))
		"save_button":
			return _control_rect_by_name("save_button", _control_rect_by_text("Guardar/Cargar", Rect2(Vector2(view_size.x - SIDEBAR_RIGHT + 20, 680), Vector2(400, 42))))
		"attack_button":
			return _control_rect_by_name("attack_button", _control_rect_by_text("ATACAR", Rect2(Vector2(24, view_size.y - 120), Vector2(240, 52))))
		"expedition_button":
			return _control_rect_by_name("expedition_button", _control_rect_by_text("Enviar expedición", Rect2(Vector2(view_size.x * 0.3, view_size.y * 0.6), Vector2(340, 44))))
		"battle_report":
			if _overlay != null and is_instance_valid(_overlay):
				return _overlay.get_global_rect()
			return Rect2(Vector2(view_size.x * 0.25, view_size.y * 0.25), Vector2(view_size.x * 0.5, view_size.y * 0.5))
	return Rect2()


func _control_rect_by_text(text: String, fallback: Rect2) -> Rect2:
	if _overlay != null and is_instance_valid(_overlay):
		var found_overlay := _find_control_with_text(_overlay, text)
		if found_overlay != null:
			return found_overlay.get_global_rect()
	var found := _find_control_with_text(self, text)
	if found != null:
		return found.get_global_rect()
	return fallback


func _control_rect_by_name(name: String, fallback: Rect2) -> Rect2:
	if _overlay != null and is_instance_valid(_overlay):
		var found_overlay := _find_control_with_name(_overlay, name)
		if found_overlay != null:
			return found_overlay.get_global_rect()
	var found := _find_control_with_name(self, name)
	if found != null:
		return found.get_global_rect()
	return fallback


func _find_control_with_name(root_node: Node, node_name: String) -> Control:
	for child: Node in root_node.get_children():
		if child.name == node_name and child is Control:
			return child as Control
		var nested := _find_control_with_name(child, node_name)
		if nested != null:
			return nested
	return null


func _find_control_with_text(root_node: Node, text: String) -> Control:
	for child: Node in root_node.get_children():
		if child is Button and (child as Button).text == text:
			return child as Control
		var nested := _find_control_with_text(child, text)
		if nested != null:
			return nested
	return null


# ==========================================================================
# Vista de ano (solo capa politica; nunca altera la partida)
# ==========================================================================
func _default_view_year() -> int:
	var years := TSBGame.map_border_years()
	var scenario_year := TSBGame.start_year()
	if years.has(scenario_year):
		return scenario_year
	if not years.is_empty():
		return int(years[0])
	return scenario_year


## API publica para QA/benchmark: cambia la vista politica sin alterar la partida.
func set_view_year(year_value: int) -> void:
	_set_view_year(year_value)


func _set_view_year(year_value: int) -> void:
	_view_year = year_value
	for key: Variant in _year_buttons.keys():
		var button: Button = _year_buttons[key]
		button.button_pressed = int(key) == year_value
	if _year_label != null:
		var suffix := ""
		if TSBGame.has_game() and year_value != TSBGame.start_year():
			suffix = " · histórica"
		var era_text := TSBGame.current_era() if TSBGame.has_game() else TSBGame.era_for_year(year_value)
		_year_label.text = "AÑO %d · ERA %s%s" % [year_value, era_text, suffix]
	_refresh_map_layers()
	_refresh_view_banner()


func _refresh_view_banner() -> void:
	if _view_banner == null:
		return
	_view_banner.visible = TSBGame.has_game() and _view_year != TSBGame.start_year()
	if _view_banner.visible:
		var text_node: Variant = _view_banner.find_child("ViewText", true, false)
		if text_node is Label:
			(text_node as Label).text = "VISTA HISTÓRICA %d · no altera la partida" % _view_year


func _refresh_map_layers() -> void:
	if _borders == null or _entities == null or _camera == null:
		return
	var zoom := _camera.zoom.x
	_borders.call("set_zoom", zoom)
	_borders.call("set_year", _view_year)
	_interactive.call("set_zoom", zoom)
	_interactive.call("set_selected", _selected_region)
	_interactive.call("set_hover", _hover_region)
	_entities.call("configure", _view_year, Vector2(MAP_W, MAP_H), zoom, TSBGame.has_game())
	if _borders_notice != null:
		_borders_notice.visible = not TSBGame.has_map_borders() and TSBGame.has_game()
	for key: Variant in _year_buttons.keys():
		var button: Button = _year_buttons[key]
		var available := TSBGame.map_border_years().has(int(key))
		button.disabled = not available
		if not available:
			button.tooltip_text = "Fronteras del año %d pendientes (AG-1)" % int(key)


# ==========================================================================
# Refresco de datos de juego
# ==========================================================================
func _refresh_season_ui() -> void:
	if _season_hud == null:
		return
	var fid := TSBGame.player_faction()
	var has_game := TSBGame.has_game()
	_season_hud.text = UILegibility.format(
		UILegibility.text("hud.hud", "{estación} {año} — Tesoro: {oro} · PG: {pg}"),
		{
			"estación": TSBGame.season_name() if has_game else "Sin partida",
			"año": TSBGame.current_year() if has_game else "",
			"oro": TSBGame.short_number(TSBGame.gold(fid)) if has_game else "—",
			"pg": ("%d/%d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 0)]) if has_game else "—",
		}
	)
	if _season_tint != null:
		_season_tint.visible = has_game and UIPreferences.season_tint_enabled()
		var index := clampi(TSBGame.current_quarter() - 1, 0, 3)
		_season_tint.color = SEASON_TINT_COLORS[index]


func _refresh_all() -> void:
	if _world == null or _entities == null or _borders == null or _council == null:
		# La escena se instancio pero aun no ha entrado en el arbol (QA/probes):
		# el retrato y los datos se resuelven por API; no hay widgets que refrescar.
		return
	_entities.call("refresh")
	_council.call("refresh")
	_refresh_info_sidebar()
	_refresh_sovereign_panel()
	if _preview_banner != null:
		_preview_banner.visible = not TSBGame.has_game()
	if _borders_notice != null:
		_borders_notice.visible = not TSBGame.has_map_borders() and TSBGame.has_game()
	_refresh_view_banner()
	_refresh_season_ui()
	_update_zoom_dependent()


func _refresh_info_sidebar() -> void:
	if _info_panel == null:
		return
	var fid := TSBGame.player_faction()
	var has_game := TSBGame.has_game()
	_info_faction.text = TSBGame.faction_name(fid) if not fid.is_empty() else "Sin partida"
	_info_date.text = "%s · %d · Era %s" % [
		TSBGame.season_name(),
		TSBGame.current_year(),
		TSBGame.current_era(),
	]
	var info_ruler := _display_ruler(fid)
	if _info_portrait != null:
		_info_portrait.call("setup", str(info_ruler.get("id", "")))

	_info_pg.text = "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)] if has_game else "—"
	_info_pg_bar.max_value = float(maxi(TSBGame.pg_max(), 1))
	_info_pg_bar.value = float(TSBGame.pg_remaining()) if has_game else 0.0
	_info_pg_bar.add_theme_stylebox_override("fill", Palette.stylebox(Palette.GOLD if TSBGame.pg_remaining() > 0 else Palette.CRIMSON, Color.TRANSPARENT, 0, 3))

	_info_treasury.text = "%s oro" % TSBGame.short_number(TSBGame.gold(fid))
	_info_prestige.text = str(TSBGame.prestige(fid))
	_info_regions.text = "%d de %d" % [TSBGame.regions_owned_by(fid).size(), TSBGame.region_ids().size()]
	var army_count := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == fid:
			army_count += 1
	_info_armies.text = "%d ejércitos" % army_count

	var ruler := _display_ruler(fid)
	var heir := TSBGame.heir(fid)
	_info_ruler.text = "Gobernante: %s%s" % [str(ruler.get("name", "—")), _age_suffix(ruler)]
	_info_heir.text = "Heredero: %s%s" % [str(heir.get("name", "Sin heredero")), _age_suffix(heir)]

	_rebuild_alerts(fid, has_game)
	_rebuild_news(fid)
	_info_save.text = "Autoguardado: %s" % ("disponible" if TSBGame.has_save("autosave") else "—") if has_game else "Sin partida activa"


## Slot §10.2 (1): retrato del soberano en la esquina del mapa; se refresca al
## cambiar de gobernante (sucesion/muerte) sin recargar la partida.
func _refresh_sovereign_panel() -> void:
	if _sovereign_panel == null:
		return
	var fid := TSBGame.player_faction()
	var ruler := _display_ruler(fid)
	var heir := TSBGame.heir(fid)
	if _sovereign_portrait != null:
		_sovereign_portrait.call("setup", str(ruler.get("id", "")))
	_sovereign_name.text = str(ruler.get("name", "Sin gobernante"))
	_sovereign_sub.text = "%s · %s · %d años" % [
		TSBGame.faction_name(fid) if not fid.is_empty() else "Vista previa",
		TSBGame.season_name().capitalize(),
		TSBGame.character_age(ruler) if not ruler.is_empty() else 0,
	]
	_sovereign_heir.text = "Heredero: %s" % str(heir.get("name", "sin heredero"))


## Gobernante mostrado: el ruler vivo; si la sucesión aún no ha fijado uno,
## cae al heredero para que el slot nunca quede vacío (§10.2).
func _display_ruler(fid: String) -> Dictionary:
	var ruler := TSBGame.ruler(fid)
	if ruler.is_empty():
		ruler = TSBGame.heir(fid)
	return ruler


## API §10.2 del slot del mapa. Si la UI aun no se ha construido (p. ej. una
## sonda que instancia la escena fuera del arbol), devuelve el gobernante actual
## de la partida para que el slot nunca quede vacio.
func get_portrait_character_id() -> String:
	if _sovereign_portrait != null and is_instance_valid(_sovereign_portrait):
		return str(_sovereign_portrait.call("get_portrait_character_id"))
	var ruler := _display_ruler(TSBGame.player_faction())
	return str(ruler.get("id", ""))


func is_fallback() -> bool:
	if _sovereign_portrait != null and is_instance_valid(_sovereign_portrait):
		return bool(_sovereign_portrait.call("is_fallback"))
	return true


## Refresco completo para QA/automatizacion (sucesion, fin de turno, etc.).
func refresh() -> void:
	_refresh_all()


func _rebuild_alerts(fid: String, has_game: bool) -> void:
	UIKit.clear(_alerts_box)
	if not has_game:
		_alert_line("Sin partida activa: vista previa de datos.", Palette.GOLD_DIM)
		_alert_line("Sistemas de turno en integración.", Palette.MUTED)
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


func _age_suffix(character_entry: Dictionary) -> String:
	if character_entry.is_empty():
		return ""
	var age := TSBGame.character_age(character_entry)
	return " (%d años)" % age if age > 0 else ""


# ==========================================================================
# Interaccion con el mapa (capa 3)
# ==========================================================================
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
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_camera.zoom.x * 1.12, mouse.position)
			get_viewport().set_input_as_handled()
			return
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_camera.zoom.x / 1.12, mouse.position)
			get_viewport().set_input_as_handled()
			return
		if mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if mouse.pressed:
				_dragging = true
				_drag_moved = false
				_drag_button = mouse.button_index
				_drag_start_mouse = mouse.position
				_drag_start_camera = _camera.position
			else:
				if _dragging and not _drag_moved and mouse.button_index == MOUSE_BUTTON_LEFT:
					_on_map_click(mouse.position)
				_dragging = false
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _dragging:
			if motion.position.distance_to(_drag_start_mouse) > 5.0:
				_drag_moved = true
			var delta := (_drag_start_mouse - motion.position) / _camera.zoom.x
			_camera.position = _drag_start_camera + delta
			_clamp_camera()
			if _tooltip != null:
				_tooltip.call("hide_tip")
			get_viewport().set_input_as_handled()
			return
		_on_map_motion(motion.position)
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
			if _overlay == null:
				_on_end_turn_requested()
				get_viewport().set_input_as_handled()


func _on_map_motion(screen_pos: Vector2) -> void:
	if _is_hud_position(screen_pos):
		_set_hover_region("")
		return
	var world_pos := _screen_to_world(screen_pos)
	var region_id := str(_interactive.call("hit_test", world_pos))
	_set_hover_region(region_id)
	if region_id.is_empty():
		if _tooltip != null:
			_tooltip.call("hide_tip")
		return
	if _tooltip != null:
		_tooltip.call("show_text", _region_tooltip_bbcode(region_id))
		_tooltip.call("follow", screen_pos)


func _set_hover_region(region_id: String) -> void:
	if _hover_region == region_id:
		return
	_hover_region = region_id
	_interactive.call("set_hover", region_id)
	if region_id.is_empty() and _tooltip != null:
		_tooltip.call("hide_tip")


func _on_map_click(screen_pos: Vector2) -> void:
	var world_pos := _screen_to_world(screen_pos)
	var region_id := str(_interactive.call("hit_test", world_pos))
	if region_id.is_empty():
		return
	_on_region_clicked(region_id)


func _on_region_clicked(region_id: String) -> void:
	_selected_region = region_id
	_interactive.call("set_selected", region_id)
	if _region_panel != null:
		_region_panel.call("open", region_id)
	# El panel tapa los controles de zoom en la esquina inferior derecha.
	if _zoom_controls != null:
		_zoom_controls.visible = false
	if _tooltip != null:
		_tooltip.call("hide_tip")
	_advance_tutorial("open_region")


func _region_tooltip_bbcode(region_id: String) -> String:
	var data := TSBGame.region(region_id)
	var view_owner := TSBGame.map_owner_for(region_id, _view_year)
	if view_owner.is_empty():
		view_owner = str(data.get("owner", ""))
	var owner_name := TSBGame.faction_name(view_owner) if not view_owner.is_empty() else "Independiente"
	var owner_color := TSBGame.faction_color(view_owner) if not view_owner.is_empty() else Palette.MUTED
	var lines: Array[String] = []
	lines.append("[b][color=#%s]%s[/color][/b]" % [owner_color.to_html(false), str(data.get("name", region_id))])
	lines.append("[color=#6b5a3e]%s · %s · vista %d[/color]" % [owner_name, _terrain_label(str(data.get("terrain", ""))), _view_year])
	if TSBGame.has_game() and _view_year == TSBGame.start_year():
		var support := TSBGame.support(region_id)
		lines.append("Población: %s   ·   Riqueza: %d" % [TSBGame.short_number(int(data.get("population", 0))), int(data.get("base_wealth", 0))])
		lines.append("Apoyo: %d/100   ·   Edificios: %d" % [support, (data.get("buildings", []) as Array).size() if data.get("buildings") is Array else 0])
		var armies := TSBGame.armies_in(region_id)
		var soldiers := 0
		for army: Variant in armies:
			if army is Dictionary:
				soldiers += TSBGame.army_soldiers(army)
		lines.append("Ejércitos: %d (%s soldados)" % [armies.size(), TSBGame.short_number(soldiers)])
	else:
		lines.append("Vista política histórica: solo fronteras y dueño del año %d." % _view_year)
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
# Senales de gameplay
# ==========================================================================
func _connect_signals() -> void:
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
	_bus("tactical_battle_started", _on_tactical_started)
	_bus("tactical_battle_finished", _on_tactical_finished)
	_bus("close_combat_started", _on_close_combat_started)
	_bus("close_combat_finished", _on_close_combat_finished)

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


func _on_turn_started(_quarter: int, _year: int) -> void:
	_refresh_all()
	if _overlay != null and is_instance_valid(_overlay) and _overlay.has_method("refresh"):
		_overlay.call("refresh")
	_notify("Turno iniciado: %s de %d" % [TSBGame.season_name(), TSBGame.current_year()])


func _on_turn_ended(_quarter: int, _year: int) -> void:
	_refresh_all()


func _on_year_advanced_event(year: int) -> void:
	_refresh_all()
	if _end_turn_in_progress:
		_deferred_year_end = year
		return
	_open_year_end(year)


func _on_year_advanced_one_arg(year: int) -> void:
	_refresh_all()
	if _end_turn_in_progress:
		_deferred_year_end = year
		return
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
	if _overlay_kind == "tactical" or _overlay_kind == "close_combat":
		# La escena táctica mostrará el informe al cerrarse.
		_tactical_pending_report = report_dict.duplicate(true)
		return
	if _turn_processing:
		_pending_battle_reports.append(report_dict)
		_notify("Batalla en %s: victoria de %s." % [
			TSBGame.region_name(str(report_dict.get("region_id", ""))),
			TSBGame.faction_name(str(report_dict.get("winner_faction", ""))) if not str(report_dict.get("winner_faction", "")).is_empty() else "nadie",
		], 1)
		return
	_open_overlay(BattleReportScene.resource_path, "battle", report_dict)


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


func _on_tactical_started(attacker: String, defender: String, region_id: String) -> void:
	_notify("Batalla táctica: %s vs %s en %s." % [TSBGame.faction_name(attacker), TSBGame.faction_name(defender), TSBGame.region_name(region_id)], 1)


func _on_tactical_finished(winner: String, region_id: String) -> void:
	_notify("Batalla táctica concluida en %s: victoria de %s." % [TSBGame.region_name(region_id), TSBGame.faction_name(winner)], 1)
	_refresh_all()


func _on_close_combat_started(_attacker: String, _defender: String) -> void:
	_notify("Combate cerrado iniciado.", 1)


func _on_close_combat_finished(winner: String) -> void:
	_notify("Combate cerrado concluido: victoria de %s." % TSBGame.faction_name(winner), 1)
	_refresh_all()


# ==========================================================================
# Acciones de UI
# ==========================================================================
func _on_region_panel_closed() -> void:
	_selected_region = ""
	_interactive.call("set_selected", "")
	if _region_panel != null:
		_region_panel.visible = false
	if _zoom_controls != null:
		_zoom_controls.visible = true


func _on_action_result(message: String, ok: bool) -> void:
	_notify(message, 1 if ok else 2)
	_refresh_all()


func _on_battle_requested(attacker_army_id: String, defender_army_id: String, region_id: String) -> void:
	_open_tactical_battle(attacker_army_id, defender_army_id, region_id)


func _on_end_turn_requested() -> void:
	if not TSBGame.has_game():
		_notify("Inicia una partida (Nuevo juego) para terminar turnos.", 2)
		return
	if _turn_processing or (_overlay != null and is_instance_valid(_overlay)):
		return
	_turn_processing = true
	_open_overlay(OrderConfirmationScene.resource_path, "orders", null)
	if _overlay == null:
		_turn_processing = false
		return
	if _overlay.has_signal("confirmed"):
		_overlay.connect("confirmed", _on_orders_confirmed)
	if _overlay.has_signal("corrected"):
		_overlay.connect("corrected", _on_orders_corrected)


func _on_orders_confirmed() -> void:
	await get_tree().process_frame
	await _perform_end_turn()


func _on_orders_corrected() -> void:
	_turn_processing = false


func _perform_end_turn() -> void:
	if not TSBGame.has_game():
		_turn_processing = false
		return
	_notify("La IA rival delibera…")
	_council.call("refresh")
	_closed_season = TSBGame.season_name()
	_closed_year = TSBGame.current_year()
	_closed_actions = TSBGame.turn_actions()
	_end_turn_in_progress = true
	await get_tree().process_frame
	TSBGame.end_turn()
	# D-085: autoguardado solo después del cierre resuelto, nunca antes de confirmar.
	TSBGame.autosave()
	_end_turn_in_progress = false
	_turn_processing = false
	_refresh_all()
	_notify("Trimestre completado: %s de %d" % [TSBGame.season_name(), TSBGame.current_year()], 1)
	_flush_pending_battles()
	if _overlay == null:
		_open_quarterly_bulletin({
			"season": _closed_season,
			"year": _closed_year,
			"actions": _closed_actions,
		})
	else:
		_bulletin_pending = true


func _open_quarterly_bulletin(payload: Dictionary = {}) -> void:
	_open_overlay("res://scenes/ui/quarterly_bulletin.tscn", "bulletin", payload)


func _on_save_pressed() -> void:
	if not TSBGame.has_game():
		_notify("Inicia una partida antes de guardar.", 2)
		return
	_open_overlay(SaveLoadScene.resource_path, "save_load", null)


func _on_options_pressed() -> void:
	_open_options()


func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# ==========================================================================
# Overlays
# ==========================================================================
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
	if _overlay.has_signal("market_requested"):
		_overlay.connect("market_requested", _on_overlay_market_requested)
	if _overlay.has_signal("army_management_requested"):
		_overlay.connect("army_management_requested", _on_overlay_army_management_requested)
	if _overlay.has_signal("attack_requested"):
		_overlay.connect("attack_requested", _on_attack_requested)
	if _overlay.has_signal("battle_report_requested"):
		_overlay.connect("battle_report_requested", _on_attack_battle_report_requested)
	if _overlay.has_signal("battle_report_ready"):
		_overlay.connect("battle_report_ready", _on_overlay_battle_report_ready)
	if _tooltip != null:
		_tooltip.call("hide_tip")
	match kind:
		"family":
			_advance_tutorial("open_family")
		"diplomacy":
			_advance_tutorial("open_diplomacy")
		"military":
			_advance_tutorial("open_military")
		"market":
			_advance_tutorial("open_market")
	if _advisor != null:
		_advisor.visible = false
	if _tutorial_highlight != null:
		_tutorial_highlight.call("clear_highlight")


func _on_overlay_region_requested(region_id: String) -> void:
	_on_region_clicked(region_id)


func _on_overlay_market_requested() -> void:
	call_deferred("_open_overlay", "res://scenes/economy/market_screen.tscn", "market", null)


func _on_overlay_army_management_requested() -> void:
	call_deferred("_open_overlay", "res://scenes/military/army_management.tscn", "army", null)


func _on_attack_requested() -> void:
	if _overlay != null and is_instance_valid(_overlay) and _overlay.has_method("close_overlay"):
		_overlay.call("close_overlay")
	call_deferred("_open_overlay", AttackScene.resource_path, "attack", null)


func _on_attack_battle_report_requested(report: Dictionary) -> void:
	if _overlay != null and is_instance_valid(_overlay) and _overlay.has_method("close_overlay"):
		_overlay.call("close_overlay")
	call_deferred("_open_overlay", BattleReportScene.resource_path, "battle", report)


func _on_overlay_battle_report_ready(report: Dictionary) -> void:
	_tactical_pending_report = report.duplicate(true)


func _open_tactical_battle(attacker_army_id: String, defender_army_id: String, region_id: String) -> void:
	var context := {
		"attacker_army_id": attacker_army_id,
		"defender_army_id": defender_army_id,
		"region_id": region_id,
	}
	_tactical_pending_report = {}
	_open_overlay(TACTICAL_SCENE, "tactical", context)


func _open_year_end(year: int) -> void:
	if _overlay_kind == "year_end":
		return
	# D-066: AudioManager.play_year_bell() lo emite TurnManager al avanzar año.
	_open_overlay(YearEndScene.resource_path, "year_end", year)


func _open_victory(faction_id: String, victory: bool, reason: String) -> void:
	var payload := {"faction_id": faction_id, "victory": victory, "reason": reason}
	_open_overlay(VictoryScene.resource_path, "victory", payload)


func _on_overlay_closed() -> void:
	var closed_kind := _overlay_kind
	_overlay = null
	_overlay_kind = ""
	_refresh_all()
	_refresh_tutorial_ui()
	if closed_kind in ["tactical", "battle", "victory", "year_end", "close"]:
		UIAudio.play_music("map")
	if closed_kind == "orders":
		_turn_processing = false
	if closed_kind == "bulletin" and _deferred_year_end > 0:
		var pending_year := _deferred_year_end
		_deferred_year_end = 0
		_open_year_end(pending_year)
		return
	if _bulletin_pending and _overlay == null:
		_bulletin_pending = false
		_open_quarterly_bulletin({
			"season": _closed_season,
			"year": _closed_year,
			"actions": _closed_actions,
		})
		return
	if not _tactical_pending_report.is_empty():
		var report := _tactical_pending_report
		_tactical_pending_report = {}
		_open_overlay(BattleReportScene.resource_path, "battle", report)
		return
	if not _deferred_battle_report.is_empty() and (closed_kind == "year_end" or closed_kind == "victory"):
		var report := _deferred_battle_report
		_deferred_battle_report = {}
		_open_overlay(BattleReportScene.resource_path, "battle", report)
		return
	if _bulletin_pending and _overlay == null:
		_bulletin_pending = false
		_open_quarterly_bulletin({
			"season": _closed_season,
			"year": _closed_year,
			"actions": _closed_actions,
		})


# ==========================================================================
# Notificaciones
# ==========================================================================
func _notify(message: String, level: int = 0) -> void:
	if _notification_box == null or message.is_empty():
		return
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


# ==========================================================================
# Benchmark de rendimiento del controlador del mapa (< 8 ms/frame)
# ==========================================================================
## Devuelve el coste medio en ms de `iterations` frames logicos con hit-test y
## clamp de camara (lo usa AG-4/QA; headless mide CPU, no GPU).
func benchmark_map_frame(iterations: int = 120) -> float:
	var start := Time.get_ticks_usec()
	for i in range(maxi(iterations, 1)):
		var zone := float(i % 47) / 47.0
		var world_point := Vector2(MAP_W * (0.08 + 0.84 * zone), MAP_H * (0.12 + 0.72 * fmod(float(i) / 47.0 * 13.0, 1.0)))
		_interactive.call("hit_test", world_point)
		_clamp_camera()
	var elapsed := Time.get_ticks_usec() - start
	return float(elapsed) / float(maxi(iterations, 1)) / 1000.0
