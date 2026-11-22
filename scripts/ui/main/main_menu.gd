extends Control
## Menu principal (GDD §9.1): Nuevo juego / Cargar / Opciones / Salir.
## Fondo de mapa antiguo generado por codigo; sin assets externos.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")
const UIManual = preload("res://scripts/ui/ui_manual.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")
const ParchmentBackdrop = preload("res://scripts/ui/widgets/parchment_backdrop.gd")
const OptionsScene = preload("res://scenes/ui/options_menu.tscn")

const SCENARIO_SELECT_SCENE := "res://scenes/main/scenario_select.tscn"
const WORLD_MAP_SCENE := "res://scenes/map/world_map.tscn"

var _load_button: Button = null
var _status_label: Label = null
var _version_label: Label = null
var _overlay: Node = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	TSBGame.ensure_data()
	UIAudio.play_music("menu")
	_build()
	UIHelp.add_button(self, "main_menu")
	_refresh()


func _build() -> void:
	var backdrop := ParchmentBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := UIKit.vbox(center, 14)
	column.custom_minimum_size = Vector2(720, 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := UIKit.label(column, "THE SOVEREIGN'S BLOOD", "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 66)

	var subtitle := UIKit.label(column, "Sangre de Reyes · Gran estrategia dinástica · 1337–1453", "SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.add_theme_font_size_override("font_size", 25)

	_ornament(column)
	UIKit.spacer(column, 30)

	var menu := UIKit.vbox(column, 16)
	menu.custom_minimum_size = Vector2(500, 0)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var new_game := UIKit.button(menu, "NUEVO JUEGO", "PrimaryButton")
	new_game.custom_minimum_size = Vector2(500, 62)
	new_game.pressed.connect(_on_new_game)

	_load_button = UIKit.button(menu, "CARGAR PARTIDA", "", "Carga el autoguardado de user://saves/autosave.json")
	_load_button.custom_minimum_size = Vector2(500, 58)
	_load_button.pressed.connect(_on_load_game)

	var options := UIKit.button(menu, "OPCIONES", "")
	options.custom_minimum_size = Vector2(500, 58)
	options.pressed.connect(_on_options)

	var manual := UIKit.button(menu, "MANUAL DEL JUGADOR", "", "Abre docs/MANUAL_DEL_JUGADOR.md en el visor del sistema")
	manual.custom_minimum_size = Vector2(500, 58)
	manual.pressed.connect(_on_manual)

	var quit := UIKit.button(menu, "SALIR", "GhostButton")
	quit.custom_minimum_size = Vector2(500, 48)
	quit.pressed.connect(_on_quit)

	UIKit.spacer(column, 22)
	_status_label = UIKit.label(column, "", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.custom_minimum_size = Vector2(600, 28)

	# Pie de pagina.
	var footer := UIKit.hbox(self, 10)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 40
	footer.offset_right = -40
	footer.offset_top = -58
	footer.offset_bottom = -22
	var footer_left := UIKit.label(footer, "MVP Fase 1 · Escenario «Dos Coronas» 1337", "TinyLabel")
	footer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_version_label = UIKit.label(footer, "v0.1.0 · Godot 4.7.2 · 1920×1080", "TinyLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_version_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var data_note := ""
	if TSBGame.using_data_fallback():
		data_note = "Datos 1337 cargados en vista previa (DataLoader en integración con AG-2)"
	var bottom_left := UIKit.label(self, data_note, "TinyLabel")
	bottom_left.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.offset_left = 40
	bottom_left.offset_top = -30
	bottom_left.offset_bottom = -10


func _ornament(parent: Node) -> void:
	var row := UIKit.hbox(parent, 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var left := UIKit.hsep(row)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(80, 1)
	var diamond := ColorRect.new()
	diamond.color = Palette.GOLD
	diamond.custom_minimum_size = Vector2(9, 9)
	diamond.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	diamond.rotation = PI * 0.25
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(diamond)
	var right := UIKit.hsep(row)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(80, 1)


func _refresh() -> void:
	if _load_button == null:
		return
	var has_save := TSBGame.has_save("autosave")
	_load_button.disabled = not has_save
	if not has_save:
		_load_button.tooltip_text = "No hay autoguardado disponible"
	if _status_label != null and TSBGame.has_game():
		var fid := TSBGame.player_faction()
		_status_label.text = "Partida en curso: %s · %d" % [TSBGame.faction_name(fid), TSBGame.current_year()]


func _on_new_game() -> void:
	get_tree().change_scene_to_file(SCENARIO_SELECT_SCENE)


func _on_load_game() -> void:
	if not TSBGame.has_save("autosave"):
		_notify("No hay autoguardado disponible.")
		return
	if TSBGame.load_game("autosave"):
		get_tree().change_scene_to_file(WORLD_MAP_SCENE)
	else:
		_notify("No se pudo cargar el autoguardado (los sistemas aún están en integración).")


func _on_options() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	_overlay = OptionsScene.instantiate()
	add_child(_overlay)
	if _overlay.has_method("open"):
		_overlay.call("open", false)
	if _overlay.has_signal("closed"):
		_overlay.connect("closed", _on_overlay_closed)


func _on_manual() -> void:
	if not UIManual.open_manual():
		_notify(UIManual.fallback_message())
	else:
		_notify("Manual abierto: %s" % UIManual.manual_path())


func _on_overlay_closed() -> void:
	_overlay = null


func _on_quit() -> void:
	get_tree().quit()


func _notify(message: String) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	var timer := get_tree().create_timer(4.0)
	var label_ref: WeakRef = weakref(_status_label)
	var self_ref: WeakRef = weakref(self)
	timer.timeout.connect(func() -> void:
		var alive_label: Variant = label_ref.get_ref()
		var alive_self: Variant = self_ref.get_ref()
		if alive_label != null and is_instance_valid(alive_label) and alive_self != null and is_instance_valid(alive_self):
			(alive_label as Label).text = ""
			(alive_self as Node).call("_refresh"))
