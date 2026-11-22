extends "res://scripts/ui/widgets/overlay_base.gd"
## Arbol familiar (GDD §9.5): retratos placeholder (escudos generados), lineas de
## parentesco, edad/heredero/fallecido. Permite concertar matrimonios via
## DynastySystem.marry (unica accion dinastica expuesta en el contrato §2).

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const ShieldScript = preload("res://scripts/ui/widgets/heraldry_shield.gd")

var _faction_id: String = ""
var _canvas: Control = null
var _detail_box: VBoxContainer = null
var _selected_id: String = ""
var _action_status: Label = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1580, 900)
	add_title("ÁRBOL FAMILIAR", "Linaje, herederos y matrimonios de la casa")
	var split := UIKit.hbox(content, 14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left := UIKit.panel(split, "InsetPanel")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left_margin := UIKit.margin(left, 8, 8, 8, 8)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(scroll)
	_canvas = FamilyTreeCanvas.new()
	scroll.add_child(_canvas)
	_canvas.connect("character_selected", _on_character_selected)

	var right := UIKit.panel(split, "ParchmentPanel")
	right.custom_minimum_size = Vector2(440, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right_margin := UIKit.margin(right, 12, 10, 12, 10)
	var right_scroll := ScrollContainer.new()
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(right_scroll)
	_detail_box = UIKit.vbox(right_scroll, 8)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_footer("CERRAR")
	_rebuild_all()


func setup(faction_id: Variant) -> void:
	if faction_id is String and not str(faction_id).is_empty():
		_faction_id = str(faction_id)
	_rebuild_all()


func _rebuild_all() -> void:
	if _canvas == null:
		return
	if _faction_id.is_empty():
		_faction_id = TSBGame.player_faction()
	var members := TSBGame.family_members(_faction_id)
	var ruler_id := str(TSBGame.ruler(_faction_id).get("id", ""))
	var heir_id := str(TSBGame.heir(_faction_id).get("id", ""))
	_canvas.call("set_model", members, ruler_id, heir_id, _faction_id)
	if _selected_id.is_empty():
		_selected_id = ruler_id
	_canvas.call("set_selected", _selected_id)
	_rebuild_detail()


func _on_character_selected(character_id: String) -> void:
	_selected_id = character_id
	_canvas.call("set_selected", character_id)
	_rebuild_detail()


func _member_by_id(character_id: String) -> Dictionary:
	for member: Variant in TSBGame.family_members(_faction_id):
		if member is Dictionary and str((member as Dictionary).get("id", "")) == character_id:
			return member
	return {}


func _rebuild_detail() -> void:
	if _detail_box == null:
		return
	UIKit.clear(_detail_box)
	var member := _member_by_id(_selected_id)
	if member.is_empty():
		var empty := UIKit.label(_detail_box, "Selecciona un miembro de la casa en el árbol.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var alive := bool(member.get("alive", true))
	var header := UIKit.hbox(_detail_box, 10)
	var shield: Control = ShieldScript.new()
	shield.custom_minimum_size = Vector2(96, 116)
	shield.set("house", str(member.get("house", _faction_id)))
	shield.set("field_color", TSBGame.faction_color(_faction_id))
	header.add_child(shield)
	var header_text := UIKit.vbox(header, 2)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(header_text, str(member.get("name", "—")), "InkLabel")
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var house_label := UIKit.label(header_text, "Casa %s" % str(member.get("house", "—")).capitalize(), "InkLabel")
	house_label.add_theme_font_size_override("font_size", 15)
	house_label.add_theme_color_override("font_color", Palette.CRIMSON)
	var role_label := UIKit.label(header_text, _role_text(member), "InkLabel")
	role_label.add_theme_font_size_override("font_size", 15)
	role_label.add_theme_color_override("font_color", Palette.INK_TEXT)

	var stats := UIKit.grid(_detail_box, 2, 10, 3)
	_stat(stats, "Edad", "%d años" % int(member.get("age", 0)))
	_stat(stats, "Nacimiento", str(int(member.get("born", 0))))
	_stat(stats, "Estado", "Vivo" if alive else "Fallecido %s" % str(int(member.get("died", 0))))
	_stat(stats, "Heredero", "Sí" if bool(member.get("is_heir", false)) else "No")

	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var attr_title := UIKit.label(_detail_box, "Atributos", "InkLabel")
	attr_title.add_theme_font_size_override("font_size", 18)
	attr_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var member_stats: Variant = member.get("stats", {})
	if member_stats is Dictionary and not (member_stats as Dictionary).is_empty():
		var stat_names := {
			"command": "Mando",
			"intrigue": "Astucia",
			"charisma": "Carisma",
			"loyalty": "Lealtad",
			"education": "Educación",
		}
		for key: Variant in stat_names.keys():
			var value := int((member_stats as Dictionary).get(key, 0))
			var row := UIKit.hbox(_detail_box, 8)
			var key_label := UIKit.label(row, str(stat_names[key]), "InkLabel")
			key_label.custom_minimum_size = Vector2(108, 0)
			key_label.add_theme_font_size_override("font_size", 14)
			key_label.add_theme_color_override("font_color", Palette.INK_TEXT)
			var bar := UIKit.bar(row, value, 100.0, Palette.GOLD_DIM, 12)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var value_label := UIKit.label(row, str(value), "InkLabel")
			value_label.add_theme_font_size_override("font_size", 14)
			value_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	else:
		var no_stats := UIKit.label(_detail_box, "Sin atributos registrados.", "InkLabel")
		no_stats.add_theme_font_size_override("font_size", 14)

	var traits_list: Variant = member.get("traits", [])
	if traits_list is Array and not (traits_list as Array).is_empty():
		var traits_title := UIKit.label(_detail_box, "Rasgos", "InkLabel")
		traits_title.add_theme_font_size_override("font_size", 18)
		traits_title.add_theme_color_override("font_color", Palette.CRIMSON)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 5)
		_detail_box.add_child(flow)
		for trait_value: Variant in (traits_list as Array):
			UIKit.chip(flow, str(trait_value).replace("_", " "), Palette.PARCHMENT_DARK, Palette.INK_TEXT)

	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	_build_marriage_section(member)
	UIKit.hsep(_detail_box, Palette.with_alpha(Palette.GOLD_DIM, 0.7))

	var future := UIKit.label(_detail_box, "Acciones de Fase 2", "InkLabel")
	future.add_theme_font_size_override("font_size", 18)
	future.add_theme_color_override("font_color", Palette.CRIMSON)
	var educate := UIKit.button(_detail_box, "Educar heredero (Fase 2)", "SmallButton", "La API de educación no forma parte del contrato de Fase 1")
	educate.disabled = true
	var regent := UIKit.button(_detail_box, "Nombrar regente (Fase 2)", "SmallButton", "La regencia automática llega con DynastySystem completo")
	regent.disabled = true
	_action_status = UIKit.label(_detail_box, "", "InkLabel")
	_action_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_status.add_theme_font_size_override("font_size", 13)
	_action_status.add_theme_color_override("font_color", Palette.CRIMSON)


func _role_text(member: Dictionary) -> String:
	if bool(member.get("is_ruler", false)):
		return "Gobernante"
	if bool(member.get("is_heir", false)):
		return "Heredero"
	if not bool(member.get("alive", true)):
		return "Antepasado"
	var role := str(member.get("role", ""))
	var labels := {
		"spouse": "Consorte",
		"general": "General",
		"advisor": "Consejero",
		"relative": "Casa real",
		"heir": "Heredero",
		"ruler": "Gobernante",
	}
	return str(labels.get(role, role.capitalize()))


func _build_marriage_section(member: Dictionary) -> void:
	var title := UIKit.label(_detail_box, "Concertar matrimonio", "InkLabel")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var alive := bool(member.get("alive", true))
	var spouse := TSBGame.character_spouse(member)
	if not alive:
		var dead_note := UIKit.label(_detail_box, "El personaje ha fallecido: no puede contraer matrimonio.", "InkLabel")
		dead_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dead_note.add_theme_font_size_override("font_size", 14)
		return
	if not spouse.is_empty():
		var spouse_name := str(TSBGame.character(spouse).get("name", spouse))
		var married := UIKit.label(_detail_box, "Casado/a con %s." % spouse_name, "InkLabel")
		married.add_theme_font_size_override("font_size", 14)
		return

	var candidates := _marriage_candidates(member)
	if candidates.is_empty():
		var no_candidates := UIKit.label(_detail_box, "No hay candidatos disponibles en las casas vecinas.", "InkLabel")
		no_candidates.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_candidates.add_theme_font_size_override("font_size", 14)
		return

	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 38)
	picker.add_theme_font_size_override("font_size", 14)
	for candidate: Variant in candidates:
		if candidate is Dictionary:
			var candidate_data := candidate as Dictionary
			picker.add_item("%s · %s (%d)" % [
				str(candidate_data.get("name", "—")),
				TSBGame.faction_name(str(candidate_data.get("faction", ""))),
				TSBGame.character_age(candidate_data),
			])
			picker.set_item_metadata(picker.item_count - 1, str(candidate_data.get("id", "")))
	_detail_box.add_child(picker)
	var propose_button := UIKit.button(_detail_box, "Proponer matrimonio", "PrimaryButton", "DynastySystem.marry() — puede crear alianza o pretensión")
	propose_button.disabled = not TSBGame.has_game()
	propose_button.pressed.connect(func() -> void: _propose_marriage(str(member.get("id", "")), picker))
	var note := UIKit.label(_detail_box, "La aceptación depende de la relación y la Astucia de las cortes (GDD §5.3).", "InkLabel")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Palette.MUTED)


func _marriage_candidates(member: Dictionary) -> Array:
	var fid := str(member.get("faction", _faction_id))
	var out: Array = []
	for candidate: Variant in TSBGame.all_characters():
		if not (candidate is Dictionary):
			continue
		var data := candidate as Dictionary
		var candidate_id := str(data.get("id", ""))
		if candidate_id.is_empty() or candidate_id == str(member.get("id", "")):
			continue
		if str(data.get("faction", "")) == fid:
			continue
		if not TSBGame.character_is_alive(data):
			continue
		if not TSBGame.character_spouse(data).is_empty():
			continue
		if TSBGame.character_age(data) < 14:
			continue
		out.append(data)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", "")))
	if out.size() > 40:
		out = out.slice(0, 40)
	return out


func _propose_marriage(character_id: String, picker: OptionButton) -> void:
	if picker.item_count == 0 or picker.selected < 0:
		return
	var target_id := str(picker.get_item_metadata(picker.selected))
	if target_id.is_empty():
		return
	var result := TSBGame.marry(character_id, target_id)
	var message := "Los sistemas de dinastía aún no procesan matrimonios (integración pendiente con AG-2)."
	if not result.is_empty():
		if bool(result.get("ok", false)):
			message = "Matrimonio concertado con %s." % str(TSBGame.character(target_id).get("name", target_id))
			if result.has("alliance"):
				message += " Alianza: %s." % str(result.get("alliance", "—"))
			if result.has("claim"):
				message += " Se ha obtenido una pretensión."
		else:
			message = "Propuesta rechazada: %s" % str(result.get("reason", "sin motivo indicado"))
	if _action_status != null:
		_action_status.text = message
	_rebuild_all()


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


# ==========================================================================
# Lienzo del arbol (dibujo por codigo)
# ==========================================================================
class FamilyTreeCanvas extends Control:
	signal character_selected(character_id: String)

	const PaletteLocal = preload("res://scripts/ui/theme/tsb_palette.gd")
	const HeraldryLocal = preload("res://scripts/ui/heraldry.gd")
	const ThemeBuilderLocal = preload("res://scripts/ui/theme/tsb_theme.gd")
	const TSBGameLocal = preload("res://scripts/ui/tsb_game.gd")

	const CARD_SIZE := Vector2(238, 124)
	const GAP_X := 22.0
	const ROW_GAP := 74.0

	var _cards: Array = []
	var _rects: Dictionary = {}
	var _links: Array = []
	var _marriages: Array = []
	var _selected: String = ""
	var _tree_size: Vector2 = Vector2(800, 400)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_model(members: Array, ruler_id: String, heir_id: String, _faction_id: String) -> void:
		_cards.clear()
		_rects.clear()
		_links.clear()
		_marriages.clear()
		var by_id: Dictionary = {}
		for member: Variant in members:
			if member is Dictionary:
				by_id[str((member as Dictionary).get("id", ""))] = member
		if by_id.is_empty():
			custom_minimum_size = Vector2(640, 320)
			queue_redraw()
			return
		var ruler: Dictionary = by_id.get(ruler_id, {})
		if ruler.is_empty():
			for member: Variant in members:
				if member is Dictionary and bool((member as Dictionary).get("is_ruler", false)):
					ruler = member
					break
		if ruler.is_empty() and not members.is_empty():
			ruler = members[0]
		var ruler_key := str(ruler.get("id", ""))

		# Niveles generacionales.
		var levels: Dictionary = {}
		levels[ruler_key] = 0
		var ruler_family: Variant = ruler.get("family", {})
		var spouse_id := ""
		var children_ids: Array = []
		var parent_ids: Array = []
		if ruler_family is Dictionary:
			spouse_id = TSBGameLocal.character_spouse(ruler)
			var children: Variant = (ruler_family as Dictionary).get("children", [])
			if children is Array:
				for child: Variant in (children as Array):
					children_ids.append(str(child))
			var father := str((ruler_family as Dictionary).get("father", ""))
			var mother := str((ruler_family as Dictionary).get("mother", ""))
			if not father.is_empty():
				parent_ids.append(father)
			if not mother.is_empty():
				parent_ids.append(mother)
		# Consortes: spouse declarado + miembros con rol spouse/unidos al gobernante.
		if not spouse_id.is_empty() and by_id.has(spouse_id):
			levels[spouse_id] = 0
		else:
			for member: Variant in members:
				if not (member is Dictionary):
					continue
				var data := member as Dictionary
				if TSBGameLocal.character_spouse(data) == ruler_key:
					spouse_id = str(data.get("id", ""))
					levels[spouse_id] = 0
					break
		for member: Variant in members:
			if not (member is Dictionary):
				continue
			var data := member as Dictionary
			var member_id := str(data.get("id", ""))
			if member_id == ruler_key or member_id == spouse_id:
				continue
			if children_ids.has(member_id) or bool(data.get("is_heir", false)):
				levels[member_id] = 1
			var family: Variant = data.get("family", {})
			if family is Dictionary:
				if str((family as Dictionary).get("father", "")) == ruler_key or str((family as Dictionary).get("mother", "")) == ruler_key:
					levels[member_id] = 1
		for parent_id: Variant in parent_ids:
			if by_id.has(str(parent_id)):
				levels[str(parent_id)] = -1
		# Nietos.
		var child_keys: Array = []
		for member_id: Variant in levels.keys():
			if int(levels[member_id]) == 1:
				child_keys.append(member_id)
		for child_key: Variant in child_keys:
			var child_data: Dictionary = by_id.get(str(child_key), {})
			var child_family: Variant = child_data.get("family", {})
			if child_family is Dictionary:
				var grandchildren: Variant = (child_family as Dictionary).get("children", [])
				if grandchildren is Array:
					for grandchild: Variant in (grandchildren as Array):
						if by_id.has(str(grandchild)) and not levels.has(str(grandchild)):
							levels[str(grandchild)] = 2
		# Resto: casa y corte en una fila inferior.
		for member: Variant in members:
			if member is Dictionary:
				var member_id := str((member as Dictionary).get("id", ""))
				if not levels.has(member_id):
					levels[member_id] = 3

		# Filas.
		var row_levels: Array = []
		for level: Variant in levels.values():
			if not row_levels.has(int(level)):
				row_levels.append(int(level))
		row_levels.sort()
		var row_index_by_level: Dictionary = {}
		for i in range(row_levels.size()):
			row_index_by_level[int(row_levels[i])] = i

		var rows: Dictionary = {}
		for member_id: Variant in levels.keys():
			var row := int(row_index_by_level[int(levels[member_id])])
			if not rows.has(row):
				rows[row] = []
			rows[row].append(str(member_id))
		var max_row_width := 760.0
		for row: Variant in rows.keys():
			var ids: Array = rows[row]
			var width := ids.size() * CARD_SIZE.x + maxf(ids.size() - 1, 0) * GAP_X
			max_row_width = maxf(max_row_width, width)
		var tree_width := max_row_width + 40.0
		var tree_height := rows.size() * (CARD_SIZE.y + ROW_GAP) + 30.0
		_tree_size = Vector2(maxf(tree_width, 760.0), maxf(tree_height, 300.0))
		custom_minimum_size = _tree_size

		for row: Variant in rows.keys():
			var ids: Array = rows[row]
			var row_width := ids.size() * CARD_SIZE.x + maxf(ids.size() - 1, 0) * GAP_X
			var start_x := (_tree_size.x - row_width) * 0.5
			var y := 18.0 + int(row) * (CARD_SIZE.y + ROW_GAP)
			ids.sort_custom(func(a: String, b: String) -> bool:
				var da: Dictionary = by_id.get(a, {})
				var db: Dictionary = by_id.get(b, {})
				return str(da.get("born", 0)) < str(db.get("born", 0)))
			for i in range(ids.size()):
				var member_id := str(ids[i])
				var rect := Rect2(Vector2(start_x + i * (CARD_SIZE.x + GAP_X), y), CARD_SIZE)
				_cards.append({
					"id": member_id,
					"rect": rect,
					"member": by_id[member_id],
				})
				_rects[member_id] = rect

		# Enlaces de matrimonio y parentesco.
		if not spouse_id.is_empty() and _rects.has(spouse_id) and _rects.has(ruler_key):
			_marriages.append([ruler_key, spouse_id])
		for card: Variant in _cards:
			if not (card is Dictionary):
				continue
			var card_dict := card as Dictionary
			var child_id := str(card_dict.get("id", ""))
			var child_data: Dictionary = card_dict.get("member", {})
			var child_family: Variant = child_data.get("family", {})
			if not (child_family is Dictionary):
				continue
			var linked := false
			for parent_key: String in ["father", "mother"]:
				var parent_id := str((child_family as Dictionary).get(parent_key, ""))
				if _rects.has(parent_id) and parent_id != child_id and not linked:
					_links.append([parent_id, child_id])
					linked = true
			if not linked and children_ids.has(child_id) and _rects.has(ruler_key):
				_links.append([ruler_key, child_id])
		queue_redraw()

	func set_selected(character_id: String) -> void:
		_selected = character_id
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if _cards.is_empty():
			return
		var font := ThemeBuilderLocal.get_font()
		var gold := PaletteLocal.with_alpha(PaletteLocal.GOLD, 0.55)
		for marriage: Variant in _marriages:
			var pair: Array = marriage
			var rect_a: Rect2 = _rects.get(str(pair[0]), Rect2())
			var rect_b: Rect2 = _rects.get(str(pair[1]), Rect2())
			if rect_a.size.x <= 0.0 or rect_b.size.x <= 0.0:
				continue
			var y := rect_a.position.y + rect_a.size.y * 0.5
			var from_x := minf(rect_a.end.x, rect_b.end.x)
			var to_x := maxf(rect_a.position.x, rect_b.position.x)
			if from_x > to_x:
				var tmp := from_x
				from_x = to_x
				to_x = tmp
			draw_line(Vector2(from_x, y - 2), Vector2(to_x, y - 2), gold, 2.0, true)
			draw_line(Vector2(from_x, y + 2), Vector2(to_x, y + 2), gold, 2.0, true)
			draw_circle(Vector2((from_x + to_x) * 0.5, y), 4.0, gold)
		for link: Variant in _links:
			var pair: Array = link
			var rect_parent: Rect2 = _rects.get(str(pair[0]), Rect2())
			var rect_child: Rect2 = _rects.get(str(pair[1]), Rect2())
			if rect_parent.size.x <= 0.0 or rect_child.size.x <= 0.0:
				continue
			var start := rect_parent.position + Vector2(rect_parent.size.x * 0.5, rect_parent.size.y)
			var end := rect_child.position + Vector2(rect_child.size.x * 0.5, 0)
			var mid_y := (start.y + end.y) * 0.5
			draw_line(start, Vector2(start.x, mid_y), gold, 1.6, true)
			draw_line(Vector2(start.x, mid_y), Vector2(end.x, mid_y), gold, 1.6, true)
			draw_line(Vector2(end.x, mid_y), end, gold, 1.6, true)
			draw_circle(Vector2(end.x, mid_y), 2.5, gold)
		for card: Variant in _cards:
			if card is Dictionary:
				_draw_card(card as Dictionary, font)

	func _draw_card(card: Dictionary, font: Font) -> void:
		var rect: Rect2 = card.get("rect", Rect2())
		var member: Dictionary = card.get("member", {})
		var character_id := str(card.get("id", ""))
		var selected := character_id == _selected
		var is_ruler := bool(member.get("is_ruler", false))
		var is_heir := bool(member.get("is_heir", false))
		var alive := bool(member.get("alive", true))

		var fill := PaletteLocal.with_alpha(PaletteLocal.INK_SOFT, 0.92)
		if selected:
			fill = PaletteLocal.with_alpha(PaletteLocal.GOLD_DIM, 0.40)
		draw_rect(rect, fill, true)
		var border := PaletteLocal.with_alpha(PaletteLocal.GOLD_DIM, 0.7)
		var border_width := 1.5
		if is_ruler:
			border = PaletteLocal.GOLD_BRIGHT
			border_width = 3.0
		elif is_heir:
			border = PaletteLocal.GOLD
			border_width = 2.0
		if selected:
			border = PaletteLocal.PARCHMENT_LIGHT
			border_width = 3.0
		if not alive:
			border = PaletteLocal.with_alpha(PaletteLocal.MUTED, 0.55)
		draw_rect(rect, border, false, border_width)
		draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size - Vector2(8, 8)), PaletteLocal.with_alpha(border, 0.25), false, 1.0)

		var shield_rect := Rect2(rect.position + Vector2(10, 12), Vector2(56, 70))
		HeraldryLocal.draw_shield(self, shield_rect, TSBGameLocal.faction_color(str(member.get("faction", ""))), str(member.get("house", "")))

		var name_color := PaletteLocal.PARCHMENT_LIGHT if alive else PaletteLocal.MUTED
		draw_string(font, rect.position + Vector2(76, 30), _fit(str(member.get("name", "")), 22), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, name_color)
		var house_text := "%s · %d años" % [str(member.get("house", "")).capitalize(), int(member.get("age", 0))]
		draw_string(font, rect.position + Vector2(76, 50), _fit(house_text, 26), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PaletteLocal.MUTED)
		var status_text := "Gobernante" if is_ruler else ("Heredero" if is_heir else _role_short(member, alive))
		draw_string(font, rect.position + Vector2(76, 72), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PaletteLocal.GOLD_BRIGHT if (is_ruler or is_heir) else PaletteLocal.MUTED)
		if not alive:
			draw_line(rect.position + Vector2(10, 92), rect.position + Vector2(70, 108), PaletteLocal.with_alpha(PaletteLocal.MUTED, 0.5), 1.0)
			draw_string(font, rect.position + Vector2(76, 94), "† %d" % int(member.get("died", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PaletteLocal.MUTED)

		if is_ruler:
			_draw_crown(rect.position + Vector2(rect.size.x - 26, 18))
		elif is_heir:
			_draw_star(rect.position + Vector2(rect.size.x - 26, 20), 9.0)

	func _role_short(member: Dictionary, alive: bool) -> String:
		if not alive:
			return "Fallecido"
		var role := str(member.get("role", ""))
		var labels := {
			"spouse": "Consorte",
			"general": "General",
			"advisor": "Consejero",
			"relative": "Casa real",
			"heir": "Heredero",
			"ruler": "Gobernante",
		}
		return str(labels.get(role, role.capitalize()))

	func _fit(text: String, max_chars: int) -> String:
		if text.length() <= max_chars:
			return text
		return text.substr(0, maxi(max_chars - 1, 1)) + "…"

	func _draw_crown(center: Vector2) -> void:
		var color := PaletteLocal.GOLD_BRIGHT
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-11, 6), center + Vector2(-11, -3), center + Vector2(-5, 1),
			center + Vector2(0, -7), center + Vector2(5, 1), center + Vector2(11, -3),
			center + Vector2(11, 6),
		]), color)
		draw_rect(Rect2(center + Vector2(-11, 6), Vector2(22, 3)), color.darkened(0.25))

	func _draw_star(center: Vector2, radius: float) -> void:
		var points := PackedVector2Array()
		for i in range(10):
			var r := radius if i % 2 == 0 else radius * 0.42
			var angle := -PI * 0.5 + TAU * float(i) / 10.0
			points.append(center + Vector2(cos(angle), sin(angle)) * r)
		draw_colored_polygon(points, PaletteLocal.GOLD_BRIGHT)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, PaletteLocal.INK_DEEP, 1.0, true)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
				for character_id: Variant in _rects.keys():
					var rect: Rect2 = _rects[character_id]
					if rect.has_point(mouse.position):
						character_selected.emit(str(character_id))
						accept_event()
						return
