extends Control
## Opciones / pausa. Se usa desde el menu principal (in_game=false) y desde el
## mapa (in_game=true): guardar, cargar autoguardado, salir al menu.
## Solo llama a la API de GameState; nunca escribe estado directamente.

signal closed

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")
const UIPreferences = preload("res://scripts/ui/ui_preferences.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")
const FontScaler = preload("res://scripts/ui/widgets/font_scaler.gd")

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"

var _dialog: PanelContainer = null
var _content: VBoxContainer = null
var _in_game := false
var _status: Label = null
var _fullscreen_check: CheckButton = null


func _ready() -> void:
	UIKit.apply_theme(self)
	FontScaler.attach(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	_build()
	UIHelp.add_button(self, "options")
	open(false)


func open(in_game: bool) -> void:
	_in_game = in_game
	# Pausa la música mientras el juego está en pausa (opciones in-game).
	if _in_game:
		UIAudio.set_music_paused(true)
	_rebuild_content()
	visible = true


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.theme_type_variation = "ParchmentPanel"
	_dialog.custom_minimum_size = Vector2(640, 0)
	center.add_child(_dialog)

	var margin := UIKit.margin(_dialog, 26, 22, 26, 22)
	_content = UIKit.vbox(margin, 14)


func _rebuild_content() -> void:
	if _content == null:
		return
	UIKit.clear(_content)
	var title := UIKit.label(_content, "Opciones", "SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	UIKit.hsep(_content)

	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Pantalla completa"
	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_content.add_child(_fullscreen_check)

	var mute_check := CheckButton.new()
	mute_check.text = "Silenciar audio"
	mute_check.tooltip_text = "Activa/desactiva música y efectos de sonido."
	mute_check.button_pressed = UIAudio.is_muted()
	mute_check.toggled.connect(_on_mute_toggled)
	_content.add_child(mute_check)

	var tint_check := CheckButton.new()
	tint_check.text = "Tinte estacional del mapa"
	tint_check.tooltip_text = "D-079: cambia suavemente el tono del mapa según la estación. No afecta a la simulación."
	tint_check.button_pressed = UIPreferences.season_tint_enabled()
	tint_check.toggled.connect(func(value: bool) -> void: UIPreferences.set_season_tint_enabled(value))
	_content.add_child(tint_check)

	var audio_title := UIKit.label(_content, "AUDIO", "InkLabel")
	audio_title.add_theme_font_size_override("font_size", 18)
	audio_title.add_theme_color_override("font_color", Palette.CRIMSON)

	var music_row := UIKit.hbox(_content, 10)
	var music_label := UIKit.label(music_row, "Música", "InkLabel")
	music_label.custom_minimum_size = Vector2(110, 0)
	music_label.tooltip_text = "Volumen de la banda sonora (por defecto −6 dB)."
	var music_slider := HSlider.new()
	music_slider.min_value = -40.0
	music_slider.max_value = 6.0
	music_slider.step = 1.0
	music_slider.value = UIAudio.music_volume_db()
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.custom_minimum_size = Vector2(240, 28)
	music_slider.tooltip_text = "Música: %d dB" % int(UIAudio.music_volume_db())
	music_row.add_child(music_slider)
	var music_value := UIKit.label(music_row, "%d dB" % int(UIAudio.music_volume_db()), "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	music_value.custom_minimum_size = Vector2(70, 0)
	music_value.add_theme_font_size_override("font_size", 14)
	music_slider.value_changed.connect(func(value: float) -> void:
		music_value.text = "%d dB" % int(value)
		music_slider.tooltip_text = "Música: %d dB" % int(value)
		UIAudio.set_music_volume_db(value)
	)

	var sfx_row := UIKit.hbox(_content, 10)
	var sfx_label := UIKit.label(sfx_row, "Efectos", "InkLabel")
	sfx_label.custom_minimum_size = Vector2(110, 0)
	sfx_label.tooltip_text = "Volumen de clicks, campana de fin de año y espada N3."
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = -40.0
	sfx_slider.max_value = 6.0
	sfx_slider.step = 1.0
	sfx_slider.value = UIAudio.sfx_volume_db()
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.custom_minimum_size = Vector2(240, 28)
	sfx_slider.tooltip_text = "Efectos: %d dB" % int(UIAudio.sfx_volume_db())
	sfx_row.add_child(sfx_slider)
	var sfx_value := UIKit.label(sfx_row, "%d dB" % int(UIAudio.sfx_volume_db()), "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	sfx_value.custom_minimum_size = Vector2(70, 0)
	sfx_value.add_theme_font_size_override("font_size", 14)
	sfx_slider.value_changed.connect(func(value: float) -> void:
		sfx_value.text = "%d dB" % int(value)
		sfx_slider.tooltip_text = "Efectos: %d dB" % int(value)
		UIAudio.set_sfx_volume_db(value)
	)
	sfx_slider.drag_ended.connect(func(_changed: bool) -> void: UIAudio.play_click())

	var info := UIKit.label(_content, "Resolución de diseño 1920×1080 · escalado por canvas_items\nMúsica y SFX se guardan en user://; la música de fondo no se corta al guardar/cargar.", "InkLabel")
	info.add_theme_font_size_override("font_size", 15)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if _in_game:
		UIKit.hsep(_content)
		var save := UIKit.button(_content, "Guardar partida (autoguardado)", "", "Escribe user://saves/autosave.json vía GameState.save_game()")
		save.pressed.connect(_on_save)
		var load_button := UIKit.button(_content, "Cargar autoguardado", "", "Restaura user://saves/autosave.json vía GameState.load_game()")
		load_button.disabled = not TSBGame.has_save("autosave")
		if load_button.disabled:
			load_button.tooltip_text = "No hay autoguardado disponible todavía."
		load_button.pressed.connect(_on_load)
		var menu := UIKit.button(_content, "Salir al menú principal", "DangerButton")
		menu.pressed.connect(_on_main_menu)

	_status = UIKit.label(_content, "", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_status.add_theme_font_size_override("font_size", 16)

	var close := UIKit.button(_content, "REANUDAR" if _in_game else "CERRAR", "PrimaryButton")
	close.custom_minimum_size = Vector2(0, 52)
	close.pressed.connect(close_overlay)


func _on_fullscreen_toggled(enabled: bool) -> void:
	UIAudio.play_click()
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _is_audio_muted() -> bool:
	return UIAudio.is_muted()


func _on_mute_toggled(enabled: bool) -> void:
	UIAudio.play_click()
	UIAudio.set_muted(enabled)


func _on_save() -> void:
	if TSBGame.save_game("autosave"):
		_set_status("Partida guardada en user://saves/autosave.json")
	else:
		_set_status("No se pudo guardar: los sistemas aún están en integración.")


func _on_load() -> void:
	if TSBGame.has_save("autosave") and TSBGame.load_game("autosave"):
		_set_status("Autoguardado cargado.")
	else:
		_set_status("No hay autoguardado válido o los sistemas aún están en integración.")


func _on_main_menu() -> void:
	close_overlay()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text


func close_overlay() -> void:
	if _in_game:
		UIAudio.set_music_paused(false)
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()
