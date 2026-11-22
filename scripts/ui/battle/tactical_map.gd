extends Control
## Mapa táctico Nivel 2 (GDD §6.2, contrato fase2 §4) + selector de nivel 1/2/3.
##
## Consume la API de AG-2: BattleManager.launch_tactical() devuelve el nodo
## TacticalBattle ya configurado; esta escena lo anade al arbol, lo pinta y envia
## ordenes (select_unit/move_unit/attack_unit/end_round/auto_resolve/commit/
## apply_outcome). La UI nunca muta estado directamente.

signal closed
signal battle_report_ready(report: Dictionary)

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")
const GameConstants = preload("res://scripts/utils/game_constants.gd")

const HEX_DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

const CLOSE_COMBAT_SCENE := "res://scenes/battle/close_combat.tscn"

var _context: Dictionary = {}
var _content: VBoxContainer = null
var _status: Label = null
var _stage := "choose"
var _tb: Node = null
var _canvas: Control = null
var _side_box: VBoxContainer = null
var _round_label: Label = null
var _selected_unit := ""
var _reachable: Dictionary = {}


func _ready() -> void:
	UIKit.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 82
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.70)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.custom_minimum_size = Vector2(1560, 920)
	center.add_child(panel)
	var margin := UIKit.margin(panel, 22, 16, 22, 14)
	_content = UIKit.vbox(margin, 8)


func setup(context: Dictionary) -> void:
	_context = context.duplicate(true)
	_build_choice()


func _clear_content() -> void:
	UIKit.clear(_content)


func _header(title_text: String, subtitle_text: String = "") -> void:
	var title := UIKit.label(_content, title_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not subtitle_text.is_empty():
		var subtitle := UIKit.label(_content, subtitle_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		subtitle.add_theme_font_size_override("font_size", 15)
		subtitle.add_theme_color_override("font_color", Palette.CRIMSON)
	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))


func _build_choice() -> void:
	_stage = "choose"
	_clear_content()
	var region_id := str(_context.get("region_id", ""))
	_header("BATALLA EN %s" % TSBGame.region_name(region_id).to_upper(), "Elige cómo resolver el choque (GDD §6: tres niveles)")
	var attacker := str(_context.get("attacker_army_id", ""))
	var defender := str(_context.get("defender_army_id", ""))
	var attacker_army := TSBGame.army(attacker)
	var defender_army := TSBGame.army(defender)
	var attacker_faction := str(attacker_army.get("faction_id", ""))
	var defender_faction := str(defender_army.get("faction_id", ""))

	var matchup := UIKit.hbox(_content, 20)
	matchup.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_side(matchup, attacker_faction, "ATACANTE", TSBGame.army_soldiers(attacker_army))
	var vs := UIKit.label(matchup, "VS", "InkLabel")
	vs.add_theme_font_size_override("font_size", 30)
	vs.add_theme_color_override("font_color", Palette.CRIMSON)
	_choice_side(matchup, defender_faction, "DEFENSOR", TSBGame.army_soldiers(defender_army))

	UIKit.spacer(_content, 10)
	var options := HBoxContainer.new()
	options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 14)
	_content.add_child(options)
	_mode_card(options, "NIVEL 1", "Resolver automáticamente", "Combate delegado: poder, moral, terreno y hasta 5 asaltos. Informe definitivo, sin deshacer.", "RESOLVER", _begin_level1)
	_mode_card(options, "NIVEL 2", "Jugar táctico", "Mapa hexagonal local: mueve unidades por turnos de iniciativa, choque y objetivos (ciudad, puente, retaguardia).", "JUGAR TÁCTICO", _begin_level2)
	_mode_card(options, "NIVEL 3", "Combate cerrado", "Duelo unidad a unidad con cartas: carga, disparo, formación, finta y retirada. +1 carta si tu Mando es mayor.", "COMBATE CERRADO", _begin_level3)

	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var footer := UIKit.hbox(_content, 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	_status = UIKit.label(footer, "El resultado es definitivo (sin undo, §9.7).", "InkLabel")
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Palette.MUTED)
	var cancel := UIKit.button(footer, "CANCELAR", "PrimaryButton")
	cancel.custom_minimum_size = Vector2(200, 46)
	cancel.pressed.connect(_close)


func _choice_side(parent: Node, faction_id: String, role_text: String, soldiers: int) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.16), Palette.with_alpha(Palette.GOLD_DIM, 0.7), 1, 5, 14, 8))
	panel.custom_minimum_size = Vector2(390, 0)
	parent.add_child(panel)
	var row := UIKit.hbox(panel, 12)
	var ruler := TSBGame.ruler(faction_id)
	var portrait: Control = PortraitFrame.make(str(ruler.get("id", "")), Vector2(96, 114))
	if portrait != null:
		row.add_child(portrait)
	var text := UIKit.vbox(row, 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role := UIKit.label(text, role_text, "InkLabel")
	role.add_theme_font_size_override("font_size", 13)
	role.add_theme_color_override("font_color", Palette.CRIMSON)
	var name_label := UIKit.label(text, TSBGame.faction_name(faction_id), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var detail := UIKit.label(text, "Líder: %s · %d soldados" % [str(ruler.get("name", "—")), soldiers], "InkLabel")
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))


func _mode_card(parent: Node, level_text: String, title_text: String, description: String, button_text: String, handler: Callable) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.12), Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 5, 14, 10))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := UIKit.vbox(panel, 5)
	var level := UIKit.label(column, level_text, "InkLabel")
	level.add_theme_font_size_override("font_size", 15)
	level.add_theme_color_override("font_color", Palette.CRIMSON)
	var title := UIKit.label(column, title_text, "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var desc := UIKit.label(column, description, "InkLabel")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var button := UIKit.button(column, button_text, "PrimaryButton")
	button.custom_minimum_size = Vector2(0, 48)
	button.pressed.connect(handler)


# ==========================================================================
# Nivel 1
# ==========================================================================
func _begin_level1() -> void:
	var attacker := str(_context.get("attacker_army_id", ""))
	var region_id := str(_context.get("region_id", ""))
	var report: Dictionary = TSBGame.delegate_attack(attacker, region_id)
	if report.is_empty():
		_status.text = "El movimiento/batalla no pudo resolverse (PG, adyacencia o ejército no disponible)."
		return
	battle_report_ready.emit(report.duplicate(true))
	close_overlay()


# ==========================================================================
# Nivel 2
# ==========================================================================
func _begin_level2() -> void:
	var attacker := str(_context.get("attacker_army_id", ""))
	var defender := str(_context.get("defender_army_id", ""))
	var region_id := str(_context.get("region_id", ""))
	_tb = TSBGame.launch_tactical(attacker, defender, region_id)
	if _tb == null:
		_status.text = "API táctica aún no disponible (BattleManager.launch_tactical devolvió null)."
		return
	add_child(_tb)
	_stage = "n2"
	_selected_unit = ""
	_reachable = {}
	_build_n2_ui()
	_sync_n2()


func _build_n2_ui() -> void:
	_clear_content()
	var top := UIKit.hbox(_content, 10)
	_round_label = UIKit.label(top, "", "InkLabel")
	_round_label.add_theme_font_size_override("font_size", 18)
	_round_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	_round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var end_round := UIKit.button(top, "TERMINAR RONDA", "PrimaryButton", "TacticalBattle.end_round(): la IA mueve/ataca y avanza ronda")
	end_round.custom_minimum_size = Vector2(200, 44)
	end_round.pressed.connect(_end_round)
	var auto := UIKit.button(top, "AUTO-RESOLVER", "SmallButton", "TacticalBattle.auto_resolve()")
	auto.custom_minimum_size = Vector2(160, 44)
	auto.pressed.connect(_auto_resolve)
	var abandon := UIKit.button(top, "ABANDONAR", "SmallButton", "Cerrar sin aplicar el resultado (no hay efectos colaterales)")
	abandon.custom_minimum_size = Vector2(130, 44)
	abandon.pressed.connect(_abandon)
	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))

	var body := UIKit.hbox(_content, 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas = TacticalCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(980, 650)
	_canvas.call("set_tb", _tb)
	_canvas.connect("cell_clicked", _on_cell_clicked)
	body.add_child(_canvas)

	var side_panel := PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.10), Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 5, 10, 8))
	side_panel.custom_minimum_size = Vector2(380, 0)
	body.add_child(side_panel)
	var side_scroll := ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(side_scroll)
	var side_margin := UIKit.margin(side_scroll, 4, 2, 8, 2)
	_side_box = UIKit.vbox(side_margin, 6)
	_side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	UIKit.hsep(_content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	_status = UIKit.label(_content, "Click en una unidad propia para seleccionarla; click en hex dorado para mover; click en enemigo adyacente para atacar.", "InkLabel")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Palette.MUTED)


func _sync_n2() -> void:
	if _tb == null:
		return
	var state: Dictionary = _tb.call("get_state")
	var round_value := int(state.get("round", 1))
	var side := str(state.get("side", "attacker"))
	_round_label.text = "RONDA %d · iniciativa: %s · %s" % [
		round_value,
		"tu bando" if side == "attacker" else "enemigo",
		TSBGame.region_name(str(state.get("region_id", ""))),
	]
	_canvas.call("set_selection", _selected_unit, _reachable)
	_canvas.queue_redraw()
	_rebuild_side(state)
	if bool(_tb.call("is_finished")):
		_finish_n2()


func _rebuild_side(state: Dictionary) -> void:
	if _side_box == null:
		return
	UIKit.clear(_side_box)
	var units: Array = state.get("units", [])
	var title := UIKit.label(_side_box, "Unidades", "InkLabel")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var player_faction := TSBGame.player_faction()
	for unit: Variant in units:
		if not (unit is Dictionary):
			continue
		var data := unit as Dictionary
		var row := UIKit.hbox(_side_box, 6)
		var marker := ColorRect.new()
		marker.color = TSBGame.faction_color(str(data.get("faction", "")))
		marker.custom_minimum_size = Vector2(5, 22)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(marker)
		var unit_name := str(TSBGame.unit(str(data.get("unit_id", ""))).get("name", data.get("unit_id", "—")))
		var label := UIKit.label(row, "%s · %d · q%d,r%d%s" % [
			unit_name,
			int(data.get("size", 0)),
			int(data.get("q", 0)),
			int(data.get("r", 0)),
			" · ★" if bool(data.get("commander", false)) else "",
		], "InkLabel")
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Palette.INK_TEXT if str(data.get("faction", "")) == player_faction else Palette.CRIMSON.darkened(0.2))
		if str(data.get("id", "")) == _selected_unit:
			label.add_theme_color_override("font_color", Palette.CRIMSON)
	var obj_title := UIKit.label(_side_box, "Objetivos", "InkLabel")
	obj_title.add_theme_font_size_override("font_size", 18)
	obj_title.add_theme_color_override("font_color", Palette.CRIMSON)
	for objective: Variant in (state.get("objectives", []) as Array):
		if objective is Dictionary:
			var obj := objective as Dictionary
			var captured := str(obj.get("captured_by", ""))
			var status_text := "libre" if captured.is_empty() else TSBGame.faction_name(captured)
			var obj_label := UIKit.label(_side_box, "%s (%s) · %s" % [str(obj.get("name", "—")), str(obj.get("kind", "")), status_text], "InkLabel")
			obj_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			obj_label.add_theme_font_size_override("font_size", 12)
			obj_label.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.1))
	var log_title := UIKit.label(_side_box, "Registro", "InkLabel")
	log_title.add_theme_font_size_override("font_size", 18)
	log_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var log_entries: Array = _tb.call("get_round_log") if _tb.has_method("get_round_log") else []
	var shown := 0
	for i in range(log_entries.size() - 1, -1, -1):
		var entry: Variant = log_entries[i]
		if entry is Dictionary:
			var text := str((entry as Dictionary).get("text", (entry as Dictionary).get("kind", "")))
			if text.is_empty():
				continue
			var log_label := UIKit.label(_side_box, "· " + text, "InkLabel")
			log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			log_label.add_theme_font_size_override("font_size", 12)
			log_label.add_theme_color_override("font_color", Palette.MUTED)
			shown += 1
			if shown >= 6:
				break


func _on_cell_clicked(q: int, r: int) -> void:
	if _tb == null:
		return
	var state: Dictionary = _tb.call("get_state")
	if bool(state.get("finished", false)):
		return
	var player_faction := TSBGame.player_faction()
	var clicked_unit := _unit_at(state, q, r)
	if not clicked_unit.is_empty():
		var clicked_faction := str(clicked_unit.get("faction", ""))
		if clicked_faction == player_faction:
			_selected_unit = str(clicked_unit.get("id", ""))
			_tb.call("select_unit", _selected_unit)
			_reachable = _reachable_map(_selected_unit)
			_status.text = "Unidad seleccionada: %s. Los hex dorados son alcanzables." % str(TSBGame.unit(str(clicked_unit.get("unit_id", ""))).get("name", "unidad"))
			_sync_n2()
			return
		if _selected_unit.is_empty():
			_status.text = "Selecciona primero una unidad propia."
			return
		var attacker_unit: Dictionary = _tb.call("get_unit", _selected_unit)
		var distance := _hex_distance(int(attacker_unit.get("q", 0)), int(attacker_unit.get("r", 0)), q, r)
		if distance != 1:
			_status.text = "El enemigo está fuera de alcance (solo hex adyacentes)."
			return
		var result: Dictionary = _tb.call("attack_unit", _selected_unit, str(clicked_unit.get("id", "")))
		if bool(result.get("ok", false)):
			_status.text = "Ataque: bajas enemigas %d, propias %d%s." % [
				int(result.get("defender_losses", 0)),
				int(result.get("attacker_losses", 0)),
				" · unidad enemiga destruida" if bool(result.get("defender_destroyed", false)) else "",
			]
		else:
			_status.text = "Ataque no válido en esta posición."
		_sync_n2()
		return
	# Hex vacio: mover si es alcanzable.
	if _selected_unit.is_empty():
		return
	var key := "%d,%d" % [q, r]
	if not _reachable.has(key):
		_status.text = "Hex no alcanzable con los movimientos restantes."
		return
	var moved: bool = _move_selected_to(q, r)
	if moved:
		_status.text = "Unidad movida a q%d, r%d." % [q, r]
		_reachable = _reachable_map(_selected_unit)
		_sync_n2()
	else:
		_status.text = "Movimiento rechazado."


## Mueve paso a paso hacia la celda alcanzable elegida (la API TacticalBattle
## resuelve un hex adyacente por llamada; aqui se reconstruye la ruta con el
## coste de terreno de las constantes del juego).
func _move_selected_to(q: int, r: int) -> bool:
	if _selected_unit.is_empty():
		return false
	var unit: Dictionary = _tb.call("get_unit", _selected_unit)
	if unit.is_empty():
		return false
	var steps: Array[Vector2i] = _find_move_path(unit, q, r)
	if steps.is_empty():
		return false
	for step: Vector2i in steps:
		var ok_move: bool = _tb.call("move_unit", _selected_unit, step.x, step.y)
		if not ok_move:
			return false
	return true


func _find_move_path(unit: Dictionary, target_q: int, target_r: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start_q := int(unit.get("q", 0))
	var start_r := int(unit.get("r", 0))
	if start_q == target_q and start_r == target_r:
		return result
	var hex_map: Dictionary = {}
	for hex_value: Variant in _tb.call("get_hexes"):
		if hex_value is Dictionary:
			var hex := hex_value as Dictionary
			hex_map["%d,%d" % [int(hex.get("q", 0)), int(hex.get("r", 0))]] = hex
	var blocked: Dictionary = {}
	for other_value: Variant in _tb.call("get_units"):
		if other_value is Dictionary:
			var other := other_value as Dictionary
			if str(other.get("id", "")) != _selected_unit:
				blocked["%d,%d" % [int(other.get("q", 0)), int(other.get("r", 0))]] = true
	var moves_left := int(unit.get("moves_left", 0))
	var start_key := "%d,%d" % [start_q, start_r]
	var target_key := "%d,%d" % [target_q, target_r]
	var best: Dictionary = {start_key: 0}
	var previous: Dictionary = {}
	var frontier: Array[Dictionary] = [{"key": start_key, "q": start_q, "r": start_r, "cost": 0}]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("cost", 0)) < int(b.get("cost", 0)))
		var current: Dictionary = frontier.pop_front()
		var current_key := str(current.get("key", ""))
		if current_key == target_key:
			break
		var cost := int(current.get("cost", 0))
		if cost > int(best.get(current_key, 999)):
			continue
		for direction: Vector2i in HEX_DIRS:
			var next_q := int(current.get("q", 0)) + direction.x
			var next_r := int(current.get("r", 0)) + direction.y
			var next_key := "%d,%d" % [next_q, next_r]
			if not hex_map.has(next_key) or blocked.has(next_key):
				continue
			var terrain := str((hex_map[next_key] as Dictionary).get("terrain", "plains"))
			var step_cost := int(GameConstants.TACTICAL_MOVE_COST.get(terrain, 1))
			var next_cost := cost + step_cost
			if next_cost > moves_left:
				continue
			var known := int(best.get(next_key, 999999))
			if next_cost >= known:
				continue
			best[next_key] = next_cost
			previous[next_key] = current_key
			frontier.append({"key": next_key, "q": next_q, "r": next_r, "cost": next_cost})
	if not best.has(target_key):
		return result
	var reversed_keys: Array[String] = []
	var cursor := target_key
	while cursor != start_key and previous.has(cursor):
		reversed_keys.append(cursor)
		cursor = str(previous[cursor])
	reversed_keys.reverse()
	for key: String in reversed_keys:
		var parts := key.split(",")
		result.append(Vector2i(int(parts[0]), int(parts[1])))
	return result


func _reachable_map(unit_id: String) -> Dictionary:
	var out: Dictionary = {}
	if _tb == null:
		return out
	for cell: Variant in _tb.call("get_reachable_hexes", unit_id):
		if cell is Dictionary:
			var data := cell as Dictionary
			if bool(data.get("occupied", false)):
				continue
			out["%d,%d" % [int(data.get("q", 0)), int(data.get("r", 0))]] = true
	return out


func _unit_at(state: Dictionary, q: int, r: int) -> Dictionary:
	for unit: Variant in (state.get("units", []) as Array):
		if unit is Dictionary:
			var data := unit as Dictionary
			if int(data.get("q", -999)) == q and int(data.get("r", -999)) == r:
				return data
	return {}


func _hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	return int((absi(q1 - q2) + absi(q1 + r1 - q2 - r2) + absi(r1 - r2)) / 2)


func _end_round() -> void:
	if _tb == null:
		return
	_tb.call("end_round")
	_selected_unit = ""
	_reachable = {}
	_status.text = "Ronda terminada: la IA ha actuado."
	_sync_n2()


func _auto_resolve() -> void:
	if _tb == null:
		return
	var report: Variant = _tb.call("auto_resolve")
	if report is Dictionary:
		battle_report_ready.emit((report as Dictionary).duplicate(true))
	_finish_n2()


func _finish_n2() -> void:
	if _tb == null or _stage != "n2":
		return
	var report: Variant = _tb.call("commit")
	var report_dict: Dictionary = (report as Dictionary).duplicate(true) if report is Dictionary else {}
	_tb.call("apply_outcome")
	if not report_dict.is_empty() and bool(report_dict.get("region_captured", false)):
		TSBGame.relocate_after_capture(str(_context.get("attacker_army_id", "")), str(_context.get("region_id", "")))
	if not report_dict.is_empty():
		battle_report_ready.emit(report_dict)
	close_overlay()


func _abandon() -> void:
	if _tb != null and is_instance_valid(_tb):
		_tb.queue_free()
		_tb = null
	close_overlay()


# ==========================================================================
# Nivel 3
# ==========================================================================
func _begin_level3() -> void:
	var attacker_unit: Dictionary = TSBGame.first_unit_of_army(str(_context.get("attacker_army_id", "")))
	var defender_unit: Dictionary = TSBGame.first_unit_of_army(str(_context.get("defender_army_id", "")))
	if attacker_unit.is_empty() or defender_unit.is_empty():
		_status.text = "No hay unidades disponibles para el combate cerrado."
		return
	var resource: Variant = load(CLOSE_COMBAT_SCENE)
	if not (resource is PackedScene):
		_status.text = "Escena de combate cerrado no disponible."
		return
	var close_scene: Node = (resource as PackedScene).instantiate()
	_stage = "n3"
	add_child(close_scene)
	if close_scene.has_method("setup"):
		close_scene.call("setup", attacker_unit, defender_unit)
	if close_scene.has_signal("closed"):
		close_scene.connect("closed", _close)


# ==========================================================================
# Cierre
# ==========================================================================
func close_overlay() -> void:
	if _tb != null and is_instance_valid(_tb):
		_tb.queue_free()
		_tb = null
	closed.emit()
	queue_free()


func _close() -> void:
	close_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _stage == "n2":
			_abandon()
		else:
			close_overlay()
		get_viewport().set_input_as_handled()


# ==========================================================================
# Lienzo hexagonal (Nivel 2)
# ==========================================================================
class TacticalCanvas extends Control:
	signal cell_clicked(q: int, r: int)

	const PaletteLocal = preload("res://scripts/ui/theme/tsb_palette.gd")
	const TSBGameLocal = preload("res://scripts/ui/tsb_game.gd")
	const ThemeBuilderLocal = preload("res://scripts/ui/theme/tsb_theme.gd")

	var tb: Node = null
	var selected_unit := ""
	var reachable: Dictionary = {}
	var _radius := 26.0
	var _origin := Vector2.ZERO
	var _cells: Dictionary = {}   # "q,r" -> Vector2 centro
	var _hover_key := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_tb(node: Node) -> void:
		tb = node
		_rebuild_layout()
		queue_redraw()

	func set_selection(unit_id: String, reachable_map: Dictionary) -> void:
		selected_unit = unit_id
		reachable = reachable_map
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_rebuild_layout()
			queue_redraw()

	func _rebuild_layout() -> void:
		_cells.clear()
		if tb == null:
			return
		var hexes: Array = tb.call("get_hexes")
		if hexes.is_empty():
			return
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for hex: Variant in hexes:
			if hex is Dictionary:
				var q := int((hex as Dictionary).get("q", 0))
				var r := int((hex as Dictionary).get("r", 0))
				var x := sqrt(3.0) * (float(q) + float(r) * 0.5)
				var y := 1.5 * float(r)
				min_x = minf(min_x, x)
				max_x = maxf(max_x, x)
				min_y = minf(min_y, y)
				max_y = maxf(max_y, y)
		var span_x := maxf(max_x - min_x, 0.001) + 2.0
		var span_y := maxf(max_y - min_y, 0.001) + 2.0
		var canvas_size := size
		_radius = minf(canvas_size.x * 0.86 / (sqrt(3.0) * span_x), canvas_size.y * 0.86 / (1.5 * span_y))
		_radius = clampf(_radius, 12.0, 34.0)
		var total_w := sqrt(3.0) * _radius * span_x
		var total_h := 1.5 * _radius * span_y
		_origin = Vector2((canvas_size.x - total_w) * 0.5 - min_x * sqrt(3.0) * _radius + sqrt(3.0) * _radius, (canvas_size.y - total_h) * 0.5 - min_y * 1.5 * _radius + _radius)
		for hex: Variant in hexes:
			if hex is Dictionary:
				var q := int((hex as Dictionary).get("q", 0))
				var r := int((hex as Dictionary).get("r", 0))
				_cells["%d,%d" % [q, r]] = _hex_center(q, r)

	func _hex_center(q: int, r: int) -> Vector2:
		return _origin + Vector2(sqrt(3.0) * _radius * (float(q) + float(r) * 0.5), 1.5 * _radius * float(r))

	func _hex_points(center: Vector2) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in range(6):
			var angle := deg_to_rad(60.0 * float(i) - 30.0)
			points.append(center + Vector2(cos(angle), sin(angle)) * _radius)
		return points

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PaletteLocal.with_alpha(PaletteLocal.INK_SOFT, 0.55), true)
		if tb == null:
			return
		var state: Dictionary = tb.call("get_state")
		var hexes: Array = state.get("hexes", [])
		var objectives: Array = state.get("objectives", [])
		var objective_cells: Dictionary = {}
		for objective: Variant in objectives:
			if objective is Dictionary:
				objective_cells["%d,%d" % [int((objective as Dictionary).get("q", 0)), int((objective as Dictionary).get("r", 0))]] = objective
		var reachable_map: Dictionary = reachable
		for hex: Variant in hexes:
			if not (hex is Dictionary):
				continue
			var data := hex as Dictionary
			var q := int(data.get("q", 0))
			var r := int(data.get("r", 0))
			var key := "%d,%d" % [q, r]
			var center: Vector2 = _cells.get(key, Vector2.ZERO)
			if center == Vector2.ZERO and not _cells.has(key):
				center = _hex_center(q, r)
			var base := _terrain_color(str(data.get("terrain", "plains")))
			draw_colored_polygon(_hex_points(center), base)
			if reachable_map.has(key):
				draw_colored_polygon(_hex_points(center), PaletteLocal.with_alpha(PaletteLocal.GOLD, 0.20))
			if key == _hover_key:
				draw_colored_polygon(_hex_points(center), PaletteLocal.with_alpha(PaletteLocal.PARCHMENT_LIGHT, 0.10))
			var outline := PaletteLocal.with_alpha(PaletteLocal.INK, 0.65)
			draw_polyline(_closed(_hex_points(center)), outline, maxf(1.2 / maxf(size.x / 980.0, 0.5), 1.0), true)
			if objective_cells.has(key):
				_draw_objective(center, objective_cells[key])
		_draw_units(state)
		_draw_selected_ring()

	func _draw_units(state: Dictionary) -> void:
		for unit: Variant in (state.get("units", []) as Array):
			if not (unit is Dictionary):
				continue
			var data := unit as Dictionary
			var q := int(data.get("q", 0))
			var r := int(data.get("r", 0))
			var center: Vector2 = _cells.get("%d,%d" % [q, r], _hex_center(q, r))
			var color := TSBGameLocal.faction_color(str(data.get("faction", "")))
			var is_selected := str(data.get("id", "")) == selected_unit
			var unit_radius := _radius * (0.62 if bool(data.get("commander", false)) else 0.52)
			draw_circle(center, unit_radius + 2.0, PaletteLocal.with_alpha(PaletteLocal.INK_DEEP, 0.55))
			draw_circle(center, unit_radius, color)
			draw_circle(center, unit_radius, PaletteLocal.INK, false, maxf(_radius * 0.06, 1.0))
			if bool(data.get("commander", false)):
				draw_circle(center + Vector2(0, -unit_radius * 0.42), unit_radius * 0.16, PaletteLocal.GOLD_BRIGHT)
			var font := ThemeBuilderLocal.get_font()
			var count_text := TSBGameLocal.short_number(int(data.get("size", 0)))
			var font_size := int(clampf(_radius * 0.42, 9.0, 15.0))
			var text_size := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			draw_string(font, center + Vector2(-text_size.x * 0.5, font_size * 0.35), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, PaletteLocal.PARCHMENT_LIGHT)
			if is_selected:
				draw_arc(center, _radius * 0.86, 0.0, TAU, 36, PaletteLocal.GOLD_BRIGHT, maxf(_radius * 0.09, 2.0), true)

	func _draw_selected_ring() -> void:
		if selected_unit.is_empty():
			return
		for cell: Variant in reachable.keys():
			var key := str(cell)
			if _cells.has(key):
				draw_arc(_cells[key], _radius * 0.55, 0.0, TAU, 24, PaletteLocal.with_alpha(PaletteLocal.GOLD_BRIGHT, 0.75), 2.0, true)

	func _draw_objective(center: Vector2, objective: Dictionary) -> void:
		var kind := str(objective.get("kind", "city"))
		var color := PaletteLocal.GOLD_BRIGHT
		if kind == "bridge":
			color = PaletteLocal.with_alpha(PaletteLocal.PARCHMENT_LIGHT, 0.9)
		elif kind == "rearguard":
			color = PaletteLocal.CRIMSON_BRIGHT
		var marker := _radius * 0.22
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -marker), center + Vector2(marker, 0),
			center + Vector2(0, marker), center + Vector2(-marker, 0),
		]), color)
		draw_circle(center, marker, PaletteLocal.INK, false, 1.2)

	func _closed(points: PackedVector2Array) -> PackedVector2Array:
		var out := points.duplicate()
		if out.size() > 0:
			out.append(out[0])
		return out

	func _terrain_color(terrain: String) -> Color:
		match terrain:
			"forest":
				return Color("8a9a6a")
			"hills":
				return Color("b9a274")
			"river":
				return Color("7fa0b5")
			"city":
				return Color("c9ae6a")
			_:
				return Color("cbb98f")

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var motion := event as InputEventMouseMotion
			var key := _nearest_hex(motion.position)
			if key != _hover_key:
				_hover_key = key
				queue_redraw()
			return
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
				var closest := _nearest_key(mouse.position)
				if not closest.is_empty():
					var parts := closest.split(",")
					cell_clicked.emit(int(parts[0]), int(parts[1]))
					accept_event()

	func _nearest_hex(screen_point: Vector2) -> String:
		return _nearest_key(screen_point)

	func _nearest_key(screen_point: Vector2) -> String:
		var best := ""
		var best_distance := _radius * 1.05
		for key: Variant in _cells.keys():
			var center: Vector2 = _cells[key]
			var distance := center.distance_to(screen_point)
			if distance < best_distance:
				best_distance = distance
				best = str(key)
		return best
