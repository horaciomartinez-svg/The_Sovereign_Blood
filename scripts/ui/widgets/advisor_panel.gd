extends PanelContainer
## Panel del Consejero (D-073): avatar heráldico por código, paso actual,
## progreso y Saltar. Consume TutorialSystem; no hardcodea los textos.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")
const UIAudio = preload("res://scripts/ui/ui_audio.gd")

var _avatar: Control = null
var _name_label: Label = null
var _title_label: Label = null
var _text_label: Label = null
var _objective_label: Label = null
var _progress_label: Label = null
var _skip_button: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.94), Palette.GOLD_DIM, 2, 6, 12, 10))
	_build()
	_connect_tutorial_signals()
	refresh()


func _build() -> void:
	var column := UIKit.vbox(self, 6)
	var header := UIKit.hbox(column, 10)
	var avatar_box := CenterContainer.new()
	avatar_box.custom_minimum_size = Vector2(54, 64)
	header.add_child(avatar_box)
	_avatar = ShieldScript.new()
	_avatar.custom_minimum_size = Vector2(46, 56)
	_avatar.set("field_color", Palette.GOLD_DIM)
	avatar_box.add_child(_avatar)
	var titles := UIKit.vbox(header, 1)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label = UIKit.label(titles, "EL CONSEJERO", "InkLabel")
	_name_label.add_theme_font_size_override("font_size", 17)
	_name_label.add_theme_color_override("font_color", Palette.GOLD)
	_progress_label = UIKit.label(titles, "", "InkLabel")
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Palette.MUTED)
	_title_label = UIKit.label(column, "", "InkLabel")
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 17)
	_title_label.add_theme_color_override("font_color", Palette.PARCHMENT_LIGHT)
	_text_label = UIKit.label(column, "", "InkLabel")
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_label.add_theme_color_override("font_color", Palette.PARCHMENT)
	_objective_label = UIKit.label(column, "", "InkLabel")
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 12)
	_objective_label.add_theme_color_override("font_color", Palette.GOLD)
	var footer := UIKit.hbox(column, 6)
	footer.alignment = BoxContainer.ALIGNMENT_END
	_skip_button = UIKit.button(footer, "Saltar", "SmallButton", "Cerrar el tutorial del Consejero")
	_skip_button.pressed.connect(_on_skip)


func _connect_tutorial_signals() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.has_signal("tutorial_started"):
		bus.connect("tutorial_started", func(_step: Dictionary) -> void: refresh())
	if bus.has_signal("tutorial_step_changed"):
		bus.connect("tutorial_step_changed", func(_step: Dictionary) -> void: refresh())
	if bus.has_signal("tutorial_skipped"):
		bus.connect("tutorial_skipped", func() -> void: refresh())
	if bus.has_signal("tutorial_completed"):
		bus.connect("tutorial_completed", func() -> void: refresh())


func refresh() -> void:
	var active := TSBGame.tutorial_active()
	visible = active
	if not active:
		return
	var faction_id := TSBGame.player_faction()
	var house := str(TSBGame.ruler(faction_id).get("house", "tsb"))
	if _avatar != null:
		_avatar.set("house", house)
		_avatar.set("field_color", TSBGame.faction_color(faction_id))
	var step := TSBGame.tutorial_step()
	if step.is_empty():
		visible = false
		return
	var tutorial := TSBGame.tutorial_state()
	var index := int(tutorial.get("step_index", 0)) + 1
	var total := maxi(TSBGame.tutorial_steps_count(), index)
	_progress_label.text = "Paso %d de %d" % [index, total]
	_title_label.text = str(step.get("title", "Consejo"))
	_text_label.text = str(step.get("text", ""))
	_objective_label.text = "Objetivo: " + str(step.get("objective", ""))
	if _skip_button != null:
		_skip_button.visible = true


func _on_skip() -> void:
	UIAudio.play_click()
	TSBGame.tutorial_skip()
	refresh()
