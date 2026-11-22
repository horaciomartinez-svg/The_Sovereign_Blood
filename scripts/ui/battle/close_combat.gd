extends Control
## Combate cerrado Nivel 3 (GDD §6.3, contrato fase2 §4). Consume la API
## `CloseCombat` de AG-2: cartas carga/disparo/formacion/finta/retirada, una por
## ronda, la IA responde con `enemy_respond()`. La UI solo pinta y envia ordenes.

signal closed
signal battle_report_ready(report: Dictionary)

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")

const CARD_LABELS := {
	"carga": "Carga",
	"disparo": "Disparo",
	"formacion": "Formación",
	"finta": "Finta",
	"retirada": "Retirada ordenada",
}
const CARD_HINTS := {
	"carga": "×1.4 vs infantería en llano; ×0.6 vs piqueros/formación",
	"disparo": "daña antes del choque",
	"formacion": "reduce daño de carga",
	"finta": "reposiciona y evita el choque",
	"retirada": "reduce bajas al retirarse",
}

var _cc: Node = null
var _attacker_unit: Dictionary = {}
var _defender_unit: Dictionary = {}
var _content: VBoxContainer = null
var _log_box: VBoxContainer = null
var _status: Label = null
## D-033: si el duelo viene de una batalla de campaña, el resultado se aplica
## una sola vez al terminar. El acceso directo (sin contexto) es vista previa.
var _campaign_context: Dictionary = {}
var _campaign_applied := false
var _campaign_apply_result: Dictionary = {}


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 85
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.custom_minimum_size = Vector2(1280, 820)
	center.add_child(panel)
	var margin := UIKit.margin(panel, 24, 18, 24, 16)
	_content = UIKit.vbox(margin, 8)
	_build_shell()


func setup(attacker_unit: Dictionary, defender_unit: Dictionary, campaign_context: Dictionary = {}) -> void:
	_attacker_unit = attacker_unit.duplicate(true)
	_defender_unit = defender_unit.duplicate(true)
	_campaign_context = campaign_context.duplicate(true)
	_cc = TSBGame.launch_close_combat(_attacker_unit, _defender_unit)
	if _cc == null:
		_show_pending()
		return
	add_child(_cc)
	_rebuild()


func _build_shell() -> void:
	var title := UIKit.label(_content, "COMBATE CERRADO · NIVEL 3", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var subtitle := UIKit.label(_content, "Órdenes de la mano y respuesta de la IA; el comandante con mayor Mando roba +1 carta", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var inner := UIKit.margin(scroll, 2, 2, 10, 2)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_box = UIKit.vbox(inner, 8)
	_log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	_status = UIKit.label(_content, "", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_status.add_theme_font_size_override("font_size", 14)
	var footer := UIKit.hbox(_content, 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	var auto_button := UIKit.button(footer, "AUTO-RESOLVER", "SmallButton", "CloseCombat.auto_resolve()")
	auto_button.pressed.connect(_on_auto_resolve)
	var close_button := UIKit.button(footer, "CERRAR", "PrimaryButton")
	close_button.custom_minimum_size = Vector2(200, 46)
	close_button.pressed.connect(_close)


func _show_pending() -> void:
	UIKit.clear(_log_box)
	var label := UIKit.label(_log_box, "Combate cerrado aún no disponible: BattleManager.launch_close_combat() devolvió null. La escena consume la API del contrato y se integrará en cuanto AG-2 esté verde.", "InkLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)


func _rebuild() -> void:
	if _cc == null or _log_box == null:
		return
	UIKit.clear(_log_box)
	var state: Dictionary = _cc.call("get_state")
	var round_value := int(state.get("round", 1))
	var attacker: Dictionary = state.get("attacker", {})
	var defender: Dictionary = state.get("defender", {})
	var hands: Dictionary = state.get("hands", {})
	var attacker_hand: Array = hands.get("attacker", [])
	var finished := bool(state.get("finished", false))

	var header := UIKit.hbox(_log_box, 12)
	_unit_card(header, attacker, "TU UNIDAD (atacante)", true)
	var vs := UIKit.vbox(header, 2)
	vs.custom_minimum_size = Vector2(140, 0)
	var round_label := UIKit.label(vs, "RONDA %d" % round_value, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	round_label.add_theme_font_size_override("font_size", 20)
	round_label.add_theme_color_override("font_color", Palette.CRIMSON)
	_unit_card(header, defender, "ENEMIGO (defensor)", false)

	UIKit.hsep(_log_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var hand_title := UIKit.label(_log_box, "Tu mano · elige una carta (una por ronda)", "InkLabel")
	hand_title.add_theme_font_size_override("font_size", 18)
	hand_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var hand_row := HFlowContainer.new()
	hand_row.add_theme_constant_override("h_separation", 8)
	hand_row.add_theme_constant_override("v_separation", 6)
	_log_box.add_child(hand_row)
	for card: Variant in attacker_hand:
		var card_id := str(card)
		var button := UIKit.button(hand_row, "%s — %s" % [str(CARD_LABELS.get(card_id, card_id)), str(CARD_HINTS.get(card_id, ""))], "SmallButton")
		button.custom_minimum_size = Vector2(360, 42)
		button.disabled = finished
		button.pressed.connect(func() -> void: _play_card(card_id))
	if attacker_hand.is_empty() and not finished:
		var empty := UIKit.label(_log_box, "Sin cartas: pulsa AUTO-RESOLVER o cierra el combate.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 14)

	var last_round: Dictionary = state.get("last_round", {})
	if not last_round.is_empty():
		var last_title := UIKit.label(_log_box, "Última ronda", "InkLabel")
		last_title.add_theme_font_size_override("font_size", 17)
		last_title.add_theme_color_override("font_color", Palette.CRIMSON)
		var round_text := "Atacante: %s · Defensor: %s · Bajas: %d / %d" % [
			str(CARD_LABELS.get(str(last_round.get("attacker_card", "")), str(last_round.get("attacker_card", "—")))),
			str(CARD_LABELS.get(str(last_round.get("defender_card", "")), str(last_round.get("defender_card", "—")))),
			int(last_round.get("attacker_losses", 0)),
			int(last_round.get("defender_losses", 0)),
		]
		var round_label2 := UIKit.label(_log_box, round_text, "InkLabel")
		round_label2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		round_label2.add_theme_font_size_override("font_size", 14)

	if finished:
		_show_outcome()


func _unit_card(parent: Node, unit: Dictionary, title_text: String, is_attacker: bool) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.16), Palette.with_alpha(Palette.GOLD_DIM, 0.7), 1, 5, 12, 8))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var row := UIKit.hbox(panel, 10)
	var faction_id := str(unit.get("faction", ""))
	var ruler := TSBGame.ruler(faction_id)
	var portrait: Control = PortraitFrame.make(str(ruler.get("id", "")), Vector2(76, 90))
	if portrait != null:
		row.add_child(portrait)
	var text := UIKit.vbox(row, 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(text, title_text, "InkLabel")
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var name_label := UIKit.label(text, TSBGame.faction_name(faction_id), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var unit_name := str(TSBGame.unit(str(unit.get("unit_id", ""))).get("name", unit.get("unit_id", "—")))
	var detail := "%s · %d efectivos · moral %d%%" % [unit_name, int(unit.get("size", 0)), int(float(unit.get("morale", 1.0)) * 100.0)]
	var detail_label := UIKit.label(text, detail, "InkLabel")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))


func _play_card(card_id: String) -> void:
	if _cc == null:
		return
	var played: Variant = _cc.call("play_order", card_id)
	if not bool(played):
		_set_status("No puedes jugar esa carta en este momento.")
		return
	var result: Variant = _cc.call("enemy_respond")
	if result is Dictionary:
		var response := result as Dictionary
		_set_status("Ronda %d: %s vs %s · bajas %d/%d" % [
			int(response.get("round", 0)),
			str(CARD_LABELS.get(str(response.get("attacker_card", "")), "—")),
			str(CARD_LABELS.get(str(response.get("defender_card", "")), "—")),
			int(response.get("attacker_losses", 0)),
			int(response.get("defender_losses", 0)),
		])
	_rebuild()


func _on_auto_resolve() -> void:
	if _cc == null:
		return
	var outcome: Variant = _cc.call("auto_resolve")
	if outcome is Dictionary:
		_set_status("Combate resuelto automáticamente.")
	_rebuild()


func _show_outcome() -> void:
	if _cc == null:
		return
	var outcome: Variant = _cc.call("get_outcome")
	if not (outcome is Dictionary):
		return
	var data := outcome as Dictionary
	_apply_campaign_outcome_once()
	var winner_side := str(data.get("winner_side", ""))
	var winner_faction := str(data.get("winner_faction", ""))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.GOLD_DIM, 0.25), Palette.GOLD, 1, 5, 12, 8))
	_log_box.add_child(panel)
	var text := UIKit.vbox(panel, 2)
	var title := UIKit.label(text, "RESULTADO: vence %s" % (TSBGame.faction_name(winner_faction) if not winner_faction.is_empty() else winner_side), "InkLabel")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var losses := UIKit.label(text, "Bajas — atacante: %d · defensor: %d · rondas: %d" % [
		int(data.get("attacker_losses", 0)), int(data.get("defender_losses", 0)), int(data.get("rounds", 0))], "InkLabel")
	losses.add_theme_font_size_override("font_size", 15)
	losses.add_theme_color_override("font_color", Palette.INK_TEXT)
	var note := UIKit.label(text, _campaign_note(), "InkLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Palette.MUTED)


## Aplica una unica vez el duelo a la campana cuando hay contexto de batalla
## (D-033). Sin contexto (selector directo) no toca el estado.
func _apply_campaign_outcome_once() -> void:
	if _campaign_applied or _campaign_context.is_empty() or _cc == null:
		return
	var attacker_army_id := str(_campaign_context.get("attacker_army_id", ""))
	var defender_army_id := str(_campaign_context.get("defender_army_id", ""))
	var region_id := str(_campaign_context.get("region_id", ""))
	if attacker_army_id.is_empty() or defender_army_id.is_empty() or region_id.is_empty():
		return
	if not TSBGame.has_close_combat_apply():
		_set_status("API de aplicación N3 pendiente (AG-2 task-17): resultado en vista previa.")
		return
	var outcome_value: Variant = _cc.call("get_outcome")
	if not (outcome_value is Dictionary):
		return
	var result := TSBGame.apply_close_combat_outcome(attacker_army_id, defender_army_id, region_id, outcome_value as Dictionary)
	_campaign_apply_result = result.duplicate(true)
	_campaign_applied = not result.is_empty() and bool(result.get("ok", true))
	if _campaign_applied:
		_set_status("Resultado de Nivel 3 aplicado a la campaña.")
	else:
		_set_status("No se pudo aplicar el resultado de Nivel 3 a la campaña.")


func _campaign_note() -> String:
	if _campaign_context.is_empty():
		return "Vista previa del selector directo: no se aplica a la campaña (D-033)."
	if _campaign_applied:
		return "Resultado aplicado a la campaña: dueño, bajas e informe actualizados."
	if not TSBGame.has_close_combat_apply():
		return "API apply_close_combat_outcome aún no disponible (AG-2 task-17); duelo mostrado sin efectos."
	return "No se pudo aplicar el resultado a la campaña; revisa el estado del ejército/región."


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text


func _close() -> void:
	if _cc != null and is_instance_valid(_cc):
		_cc.queue_free()
		_cc = null
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
