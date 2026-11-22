extends Control
## Menu de Consejo (GDD §9.4): barra lateral clasica con las ordenes principales
## y coste en PG visible. Solo emite peticiones: el world_map abre cada pantalla.

signal corte_requested
signal family_requested
signal diplomacy_requested
signal military_requested
signal economy_requested
signal end_turn_requested
signal menu_requested

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

const QUARTER_NAMES: Array[String] = ["INVIERNO", "PRIMAVERA", "VERANO", "OTOÑO"]

var _faction_label: Label = null
var _date_label: Label = null
var _pg_label: Label = null
var _pg_bar: ProgressBar = null
var _phase_label: Label = null
var _end_turn_button: Button = null


func _ready() -> void:
	UIKit.apply_theme(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_build()
	refresh()


func _build() -> void:
	var background := ColorRect.new()
	background.color = Palette.INK_DEEP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var right_border := ColorRect.new()
	right_border.color = Palette.with_alpha(Palette.GOLD_DIM, 0.8)
	right_border.anchor_left = 1.0
	right_border.anchor_right = 1.0
	right_border.anchor_bottom = 1.0
	right_border.offset_left = -2
	right_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_border)

	var margin := UIKit.margin(self, 18, 22, 16, 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := UIKit.vbox(margin, 9)

	var crown := UIKit.hbox(column, 8)
	crown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var crest := ColorRect.new()
	crest.color = Palette.GOLD
	crest.custom_minimum_size = Vector2(10, 10)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crest.rotation = PI * 0.25
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crown.add_child(crest)
	var title := UIKit.label(crown, "CONSEJO", "TitleLabel")
	title.add_theme_font_size_override("font_size", 34)

	_faction_label = UIKit.label(column, "—", "SmallLabel")
	_faction_label.add_theme_font_size_override("font_size", 16)
	_faction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_date_label = UIKit.label(column, "—", "GoldLabel")
	_date_label.add_theme_font_size_override("font_size", 18)

	UIKit.hsep(column)

	# PG visible siempre (recurso de accion del turno, GDD §5.1).
	var pg_row := UIKit.hbox(column, 8)
	var pg_title := UIKit.label(pg_row, "PG", "SectionHeader")
	pg_title.add_theme_font_size_override("font_size", 20)
	_pg_label = UIKit.label(pg_row, "—", "GoldLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	_pg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pg_label.add_theme_font_size_override("font_size", 20)
	_pg_bar = UIKit.bar(column, 0, 30, Palette.GOLD, 12)

	UIKit.hsep(column)

	var orders := UIKit.vbox(column, 7)
	_order_row(orders, "Corte", "resumen de la casa", "—", corte_requested)
	_order_row(orders, "Familia", "árbol y matrimonios", "0 PG", family_requested)
	_order_row(orders, "Diplomacia", "propuestas y tratados", "0–10 PG", diplomacy_requested)
	_order_row(orders, "Militar", "ejércitos y movimiento", "1 PG / ej.", military_requested)
	_order_row(orders, "Economía", "mano de obra y tesoro", "1 PG / orden", economy_requested)

	UIKit.spacer(column, 4)
	UIKit.hsep(column)

	_phase_label = UIKit.label(column, "", "TinyLabel")
	_phase_label.add_theme_font_size_override("font_size", 14)
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var expand := Control.new()
	expand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	expand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(expand)

	_end_turn_button = UIKit.button(column, "TERMINAR TURNO", "PrimaryButton", "Cierra tus órdenes, ejecuta la IA rival y avanza el trimestre (Enter)")
	_end_turn_button.custom_minimum_size = Vector2(0, 64)
	_end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())

	var menu_button := UIKit.button(column, "Menú principal", "GhostButton")
	menu_button.pressed.connect(func() -> void: menu_requested.emit())

	var footnote := UIKit.label(column, "Fase 1 · sin deshacer (§9.7)", "TinyLabel", HORIZONTAL_ALIGNMENT_CENTER)
	footnote.add_theme_font_size_override("font_size", 12)


func _order_row(
		parent: Node,
		title: String,
		subtitle: String,
		cost: String,
		signal_ref: Signal) -> void:
	var row := UIKit.hbox(parent, 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := UIKit.button(row, title, "SidebarButton")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = subtitle
	button.pressed.connect(func() -> void: signal_ref.emit())

	var cost_label := UIKit.label(row, cost, "TinyLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	cost_label.custom_minimum_size = Vector2(78, 0)
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Palette.GOLD)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Actualiza los valores mostrados (solo lecturas de la fachada TSBGame).
func refresh() -> void:
	if _pg_label == null:
		return
	var fid := TSBGame.player_faction()
	var has_game := TSBGame.has_game()
	if has_game:
		_faction_label.text = TSBGame.faction_name(fid)
		_faction_label.add_theme_color_override("font_color", Palette.PARCHMENT)
		_date_label.text = "%s · %d" % [QUARTER_NAMES[TSBGame.current_quarter() - 1], TSBGame.current_year()]
		var pg := TSBGame.pg_remaining()
		var pg_max := maxi(TSBGame.pg_max(), 1)
		_pg_label.text = "%d / %d" % [pg, pg_max]
		_pg_bar.max_value = float(pg_max)
		_pg_bar.value = float(pg)
		_pg_bar.add_theme_stylebox_override("fill", Palette.stylebox(Palette.GOLD if pg > 0 else Palette.CRIMSON, Color.TRANSPARENT, 0, 3))
		_phase_label.text = "Turno %d de la partida" % TSBGame.current_turn()
		_end_turn_button.disabled = false
	else:
		_faction_label.text = "Vista previa de datos"
		_date_label.text = "1337 · sin partida iniciada"
		_pg_label.text = "—"
		_pg_bar.max_value = 1.0
		_pg_bar.value = 0.0
		_phase_label.text = "Los sistemas de turno (AG-2) aún están en integración; puedes explorar el mapa."
		_end_turn_button.disabled = true
		_end_turn_button.tooltip_text = "Inicia una partida cuando los sistemas estén integrados"
