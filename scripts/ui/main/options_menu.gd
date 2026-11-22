extends Control
## Opciones / pausa. Se usa desde el menu principal (in_game=false) y desde el
## mapa (in_game=true): guardar, cargar autoguardado, salir al menu.
## Solo llama a la API de GameState; nunca escribe estado directamente.

signal closed

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"

var _dialog: PanelContainer = null
var _content: VBoxContainer = null
var _in_game := false
var _status: Label = null
var _fullscreen_check: CheckButton = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	_build()
	open(false)


func open(in_game: bool) -> void:
	_in_game = in_game
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
	mute_check.tooltip_text = "Activa/desactiva los tonos de UI (click, campana de fin de año, espada N3)."
	mute_check.button_pressed = _is_audio_muted()
	mute_check.toggled.connect(_on_mute_toggled)
	_content.add_child(mute_check)

	var info := UIKit.label(_content, "Resolución de diseño 1920×1080 · escalado por canvas_items\nAudio: tonos generados por AudioManager (click, campana de fin de año, espada N3); sin assets externos.", "InkLabel")
	info.add_theme_font_size_override("font_size", 16)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if _in_game:
		UIKit.hsep(_content)
		var save := UIKit.button(_content, "Guardar partida (autoguardado)", "", "Escribe user://saves/autosave.json vía GameState.save_game()")
		save.pressed.connect(_on_save)
		var load_button := UIKit.button(_content, "Cargar autoguardado", "", "Restaura user://saves/autosave.json vía GameState.load_game()")
		load_button.disabled = not TSBGame.has_save("autosave")
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


func _audio() -> Node:
	return get_node_or_null("/root/AudioManager")


func _is_audio_muted() -> bool:
	var audio := _audio()
	return bool(audio.call("is_muted")) if audio != null and audio.has_method("is_muted") else false


func _on_mute_toggled(enabled: bool) -> void:
	UIAudio.play_click()
	var audio := _audio()
	if audio != null and audio.has_method("set_muted"):
		audio.call("set_muted", enabled)


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
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()
