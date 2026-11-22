extends "res://scripts/ui/widgets/overlay_base.gd"
## Gestión global de ejércitos (D-070): resumen por tipo con sprite march_1,
## conteos/fuerza/moral, Reclutar (oro+pool+mercancías), Entrenar y Disolver
## con confirmación. Usa la API de MilitarySystem/TradeSystem vía TSBGame.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null
var _status: Label = null
var _region_picker: OptionButton = null
var _confirm: ConfirmationDialog = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1500, 920)
	add_title("EJÉRCITOS DEL REINO", "Administración global por tipo de unidad: reclutar, entrenar y disolver")
	_body = add_body_scroll()
	UIKit.hsep(content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var footer := UIKit.hbox(content, 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	_status = UIKit.label(footer, "", "SmallLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_footer("CERRAR")
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Confirmar disolución"
	_confirm.confirmed.connect(_on_disband_confirmed)
	add_child(_confirm)
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var fid := TSBGame.player_faction()
	var summary := TSBGame.faction_army_summary(fid)
	var total_men := 0
	var total_units := 0
	for entry_value: Variant in summary:
		if entry_value is Dictionary:
			total_men += int((entry_value as Dictionary).get("men", 0))
			total_units += int((entry_value as Dictionary).get("count", 0))
	var stats := UIKit.grid(_body, 4, 12, 4)
	_stat(stats, "Unidades", str(total_units))
	_stat(stats, "Soldados", "%d" % total_men)
	_stat(stats, "Oro", "%d" % TSBGame.gold(fid))
	_stat(stats, "PG", "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)])

	var region_row := UIKit.hbox(_body, 8)
	var region_label := UIKit.label(region_row, "Región de reclutamiento", "InkLabel")
	region_label.custom_minimum_size = Vector2(220, 0)
	_region_picker = OptionButton.new()
	_region_picker.custom_minimum_size = Vector2(340, 36)
	for region_id: Variant in TSBGame.regions_owned_by(fid):
		_region_picker.add_item(TSBGame.region_name(str(region_id)))
		_region_picker.set_item_metadata(_region_picker.item_count - 1, str(region_id))
	region_row.add_child(_region_picker)
	var pool := TSBGame.recruitment_pool(_selected_region())
	var pool_label := UIKit.label(region_row, "Pool: %s" % (str(pool) if pool >= 0 else "—"), "InkLabel")
	pool_label.add_theme_font_size_override("font_size", 13)
	pool_label.add_theme_color_override("font_color", Palette.MUTED)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.6))
	if summary.is_empty():
		var empty := UIKit.label(_body, "No hay unidades en tus ejércitos. Recluta desde una región propia para empezar.", "InkLabel")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Palette.MUTED)
		return
	var grid := UIKit.grid(_body, 1, 10, 7)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry_value: Variant in summary:
		if entry_value is Dictionary:
			_build_unit_card(grid, fid, entry_value as Dictionary)
	_build_cost_reference()


func _build_cost_reference() -> void:
	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.6))
	var title := UIKit.label(_body, "Costes de referencia por bloque (200 hombres)", "InkLabel")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var hint := UIKit.label(_body, "Caballería > arqueros/infantería ligera; artillería > caballería. El coste real se descuenta al reclutar y se muestra en cada tarjeta.", "InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Palette.MUTED)
	var list := UIKit.vbox(_body, 2)
	var gold_parts: Array[String] = []
	var goods_parts: Array[String] = []
	for unit_id: String in ["militia_spearman", "longbowman", "men_at_arms", "bombarda"]:
		var cost := TSBGame.unit_recruit_cost(unit_id, 100)
		gold_parts.append("%s %d" % [TSBGame.unit_name(unit_id), int(cost.get("per_block_gold", 0))])
		var goods := _goods_text(cost.get("per_block_goods", {}))
		if not goods.is_empty():
			goods_parts.append("%s: %s" % [TSBGame.unit_name(unit_id), goods])
	var summary := UIKit.label(list, "Oro/bloque (200 hombres): " + " · ".join(gold_parts), "InkLabel")
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not goods_parts.is_empty():
		var goods_summary := UIKit.label(list, "Mercancías/bloque: " + " · ".join(goods_parts), "InkLabel")
		goods_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		goods_summary.add_theme_font_size_override("font_size", 13)
		goods_summary.add_theme_color_override("font_color", Palette.GOLD_DIM)


func _build_unit_card(parent: Node, faction_id: String, entry: Dictionary) -> void:
	var unit_id := str(entry.get("unit_id", ""))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.10), Palette.with_alpha(Palette.GOLD_DIM, 0.55), 1, 4, 8, 6))
	parent.add_child(card)
	var row := UIKit.hbox(card, 8)
	var sprite_box := CenterContainer.new()
	sprite_box.custom_minimum_size = Vector2(90, 90)
	row.add_child(sprite_box)
	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(64, 80)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := str(entry.get("sprite_path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			sprite.texture = loaded as Texture2D
	sprite_box.add_child(sprite)
	var column := UIKit.vbox(row, 3)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := UIKit.label(column, TSBGame.unit_name(unit_id), "InkLabel")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var info := UIKit.label(column, "%d unidad(es) · %d hombres · fuerza %d" % [
		int(entry.get("count", 0)), int(entry.get("men", 0)), int(roundf(float(entry.get("strength", 0.0))))], "InkLabel")
	info.add_theme_font_size_override("font_size", 13)
	info.add_theme_color_override("font_color", Palette.INK_TEXT)
	var morale := UIKit.label(column, "Moral media %d%% · experiencia media %d" % [
		int(roundf(float(entry.get("avg_morale", 1.0)) * 100.0)), int(roundf(float(entry.get("avg_experience", 0.0))))], "InkLabel")
	morale.add_theme_font_size_override("font_size", 12)
	morale.add_theme_color_override("font_color", Palette.MUTED)
	var cost_label := UIKit.label(column, "", "InkLabel")
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Palette.GOLD_DIM)
	var controls := UIKit.hbox(column, 5)
	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = 500
	qty.step = 1
	qty.value = 100
	qty.custom_minimum_size = Vector2(80, 32)
	controls.add_child(qty)
	cost_label.text = _cost_text(unit_id, int(qty.value))
	qty.value_changed.connect(func(value: float) -> void:
		cost_label.text = _cost_text(unit_id, int(value))
	)
	var recruit := UIKit.button(controls, "Reclutar", "SmallButton", "Recluta en la región seleccionada; consume oro, pool y mercancías.")
	recruit.custom_minimum_size = Vector2(96, 32)
	recruit.pressed.connect(func() -> void: _on_recruit(faction_id, unit_id, qty))
	var train := UIKit.button(controls, "Entrenar", "SmallButton", "Entrena el tipo: oro + 1 PG; sube la experiencia media.")
	train.custom_minimum_size = Vector2(96, 32)
	train.pressed.connect(func() -> void: _on_train(faction_id, unit_id))
	var disband := UIKit.button(controls, "Disolver", "SmallButton", "Disuelve hombres del tipo; devuelve parte del oro y libera pool.")
	disband.custom_minimum_size = Vector2(96, 32)
	disband.pressed.connect(func() -> void: _ask_disband(faction_id, unit_id, qty))


func _cost_text(unit_id: String, amount: int) -> String:
	var cost := TSBGame.unit_recruit_cost(unit_id, amount)
	var block := int(cost.get("block_size", 200))
	var per_goods := _goods_text(cost.get("per_block_goods", {}))
	var total_goods := _goods_text(cost.get("goods", {}))
	var per_text := "Por bloque (%d hombres): %d oro · %d reclutas" % [
		block, int(cost.get("per_block_gold", 0)), int(cost.get("per_block_recruits", 0))]
	if not per_goods.is_empty():
		per_text += " · " + per_goods
	var total_text := "Total para %d: %d oro · %d reclutas" % [
		amount, int(cost.get("gold", 0)), int(cost.get("recruits", 0))]
	if not total_goods.is_empty():
		total_text += " · " + total_goods
	return per_text + "\n" + total_text


func _goods_text(goods_value: Variant) -> String:
	if not (goods_value is Dictionary):
		return ""
	var parts: Array[String] = []
	for good_id: Variant in (goods_value as Dictionary).keys():
		parts.append("%s %d" % [str(good_id), int(ceilf(float((goods_value as Dictionary)[good_id])))])
	return ", ".join(parts)


func _selected_region() -> String:
	if _region_picker == null or _region_picker.item_count == 0 or _region_picker.selected < 0:
		return ""
	return str(_region_picker.get_item_metadata(_region_picker.selected))


func _on_recruit(faction_id: String, unit_id: String, qty: SpinBox) -> void:
	var region_id := _selected_region()
	if region_id.is_empty():
		_set_status("No hay región propia seleccionada para reclutar.")
		return
	var amount := int(qty.value)
	var cost := TSBGame.unit_recruit_cost(unit_id, amount)
	var gold_before := TSBGame.gold(faction_id)
	if TSBGame.recruit(faction_id, region_id, unit_id, amount):
		var spent := maxi(0, gold_before - TSBGame.gold(faction_id))
		var goods_text := _goods_text(cost.get("goods", {}))
		var message := "Reclutados %d de %s: -%d oro, -%d reclutas" % [
			amount, TSBGame.unit_name(unit_id), spent, int(cost.get("recruits", 0))]
		if not goods_text.is_empty():
			message += ", mercancías: " + goods_text
		_set_status(message + ".")
	else:
		_set_status("No se pudo reclutar (%s)." % _reason(TSBGame.recruit_last_error()))
	_rebuild()


func _on_train(faction_id: String, unit_id: String) -> void:
	if TSBGame.train_unit(faction_id, unit_id, 100):
		_set_status("Entrenamiento confirmado: +100 experiencia en %s." % TSBGame.unit_name(unit_id))
	else:
		_set_status("No se pudo entrenar (%s)." % _reason(TSBGame.train_last_error()))
	_rebuild()


func _ask_disband(faction_id: String, unit_id: String, qty: SpinBox) -> void:
	_confirm.dialog_text = "¿Disolver %d hombres de %s? Se devolverá el 50 %% del oro y se liberará pool." % [int(qty.value), TSBGame.unit_name(unit_id)]
	_confirm.set_meta("faction_id", faction_id)
	_confirm.set_meta("unit_id", unit_id)
	_confirm.set_meta("qty", int(qty.value))
	_confirm.popup_centered(Vector2i(620, 180))


func _on_disband_confirmed() -> void:
	var faction_id := str(_confirm.get_meta("faction_id", ""))
	var unit_id := str(_confirm.get_meta("unit_id", ""))
	var qty := int(_confirm.get_meta("qty", 0))
	if TSBGame.disband_unit(faction_id, unit_id, qty):
		_set_status("Disolución confirmada: %d hombres de %s." % [qty, TSBGame.unit_name(unit_id)])
	else:
		_set_status("No se pudo disolver (%s)." % _reason(TSBGame.disband_last_error()))
	_rebuild()


func _reason(value: String) -> String:
	return value if not value.is_empty() else "recurso insuficiente"


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text
