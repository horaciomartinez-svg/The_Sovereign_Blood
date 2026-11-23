extends Control
## Base comun de overlays de pantalla completa: velo, panel centrado pergamino,
## cabecera, cuerpo con scroll y pie con boton de cierre.
## Las pantallas heredan con `extends "res://scripts/ui/widgets/overlay_base.gd"`
## y sobrescriben `_build_content()`; opcionalmente exponen `setup(...)`.

signal closed

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")
const FontScaler = preload("res://scripts/ui/widgets/font_scaler.gd")

const CONTEXT_KEYS := {
	"family_tree": "family",
	"diplomacy_screen": "diplomacy",
	"military_screen": "military",
	"economy_screen": "economy",
	"market_screen": "market",
	"army_management": "army_management",
	"year_end_report": "year_end",
	"victory_screen": "victory",
	"court_overview": "council",
	"battle_report": "battle_n1",
	"chronicle_screen": "chronicle",
}

var dialog: PanelContainer = null
var content: VBoxContainer = null


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	_build_shell()
	_build_content()
	_build_help_button()
	FontScaler.attach(self)


func _context_help_key() -> String:
	var script_path := ""
	if get_script() != null:
		script_path = str(get_script().resource_path)
	var file_key := script_path.get_file().get_basename()
	return str(CONTEXT_KEYS.get(file_key, ""))


func _build_help_button() -> void:
	var screen_key := _context_help_key()
	if screen_key.is_empty():
		return
	var help_button := UIKit.button(self, "?", "SmallButton", "Ayuda contextual (D-082)")
	help_button.custom_minimum_size = Vector2(42, 42)
	help_button.anchor_left = 1.0
	help_button.anchor_right = 1.0
	help_button.anchor_top = 0.0
	help_button.anchor_bottom = 0.0
	help_button.offset_left = -60
	help_button.offset_right = -18
	help_button.offset_top = 18
	help_button.offset_bottom = 60
	help_button.z_index = 120
	help_button.add_theme_font_size_override("font_size", 22)
	help_button.pressed.connect(func() -> void: UIHelp.open_help(self, screen_key))


func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.66)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	dialog = PanelContainer.new()
	dialog.theme_type_variation = "ParchmentPanel"
	dialog.custom_minimum_size = Vector2(1100, 0)
	center.add_child(dialog)

	var margin := UIKit.margin(dialog, 26, 20, 26, 18)
	content = UIKit.vbox(margin, 10)


## Virtual: cada overlay construye su contenido aqui.
func _build_content() -> void:
	pass


func add_title(title_text: String, subtitle_text: String = "") -> void:
	var title := UIKit.label(content, title_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not subtitle_text.is_empty():
		var subtitle := UIKit.label(content, subtitle_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		subtitle.add_theme_font_size_override("font_size", 17)
		subtitle.add_theme_color_override("font_color", Palette.CRIMSON)
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.hsep(content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))


## Crea el area central con scroll y devuelve el VBox donde anadir el cuerpo.
func add_body_scroll() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var margin := UIKit.margin(scroll, 2, 2, 10, 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UIKit.vbox(margin, 9)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box


## Anade el pie con boton de cierre y devuelve la fila para botones extra.
func add_footer(close_text: String = "CERRAR") -> HBoxContainer:
	UIKit.hsep(content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var row := UIKit.hbox(content, 10)
	row.alignment = BoxContainer.ALIGNMENT_END
	var close_button := UIKit.button(row, close_text, "PrimaryButton")
	close_button.custom_minimum_size = Vector2(240, 50)
	close_button.pressed.connect(close_overlay)
	return row


func close_overlay() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_overlay()
		get_viewport().set_input_as_handled()
