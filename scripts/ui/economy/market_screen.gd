extends "res://scripts/ui/widgets/overlay_base.gd"
## Mercado del reino (D-069): inventario por mercancía, precio/factor,
## comerciantes, compra/venta con cantidad y expedición. La UI solo llama a
## TradeSystem vía TSBGame; no muta GameState directamente.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null
var _status: Label = null
var _region_picker: OptionButton = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1480, 920)
	add_title("MERCADO DEL REINO", "Inventario, precios, comerciantes y expediciones de mercaderes")
	_body = add_body_scroll()
	UIKit.hsep(content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var footer := UIKit.hbox(content, 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	_status = UIKit.label(footer, "", "SmallLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_footer("CERRAR")
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var fid := TSBGame.player_faction()
	var inventory := TSBGame.trade_inventory(fid)
	var merchants := TSBGame.trade_merchants(fid)
	var available := TSBGame.trade_available_merchants(fid)
	var trade_ok := TSBGame.can_trade(fid)
	var owned := TSBGame.regions_owned_by(fid)

	var stats := UIKit.grid(_body, 4, 12, 4)
	_stat(stats, "Tesoro", "%d oro" % TSBGame.gold(fid))
	_stat(stats, "Comerciantes", "%d / %d asignados" % [merchants, available])
	_stat(stats, "Volumen de comercio", "%d unidades" % TSBGame.trade_volume(fid))
	_stat(stats, "Expediciones", str(TSBGame.trade_expeditions().size()))

	var merchant_row := UIKit.hbox(_body, 8)
	var merchant_label := UIKit.label(merchant_row, "Comerciantes asignados", "InkLabel")
	merchant_label.custom_minimum_size = Vector2(220, 0)
	merchant_label.tooltip_text = "Los comerciantes de tus regiones habilitan compra/venta; el volumen depende de cuántos asignes."
	var merchant_slider := HSlider.new()
	merchant_slider.min_value = 0
	merchant_slider.max_value = maxi(available, 0)
	merchant_slider.step = 1
	merchant_slider.value = merchants
	merchant_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	merchant_slider.custom_minimum_size = Vector2(300, 28)
	merchant_row.add_child(merchant_slider)
	var merchant_value := UIKit.label(merchant_row, "%d" % merchants, "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	merchant_value.custom_minimum_size = Vector2(60, 0)
	merchant_slider.value_changed.connect(func(value: float) -> void:
		merchant_value.text = "%d" % int(value)
	)
	merchant_slider.drag_ended.connect(func(_changed: bool) -> void:
		var ok := TSBGame.set_trade_merchants(fid, int(merchant_slider.value))
		_set_status("Comerciantes asignados: %d." % int(merchant_slider.value) if ok else "No se pudieron asignar comerciantes.")
		_rebuild()
	)
	_build_advisor_advice(fid)

	if owned.is_empty():
		var no_region := UIKit.label(_body, "No controlas regiones propias: no puedes operar en el mercado.", "InkLabel")
		no_region.add_theme_font_size_override("font_size", 15)
		no_region.add_theme_color_override("font_color", Palette.CRIMSON)
	else:
		var region_row := UIKit.hbox(_body, 8)
		var region_label := UIKit.label(region_row, "Región de operación", "InkLabel")
		region_label.custom_minimum_size = Vector2(220, 0)
		_region_picker = OptionButton.new()
		_region_picker.custom_minimum_size = Vector2(320, 36)
		for region_id: Variant in owned:
			_region_picker.add_item(TSBGame.region_name(str(region_id)))
			_region_picker.set_item_metadata(_region_picker.item_count - 1, str(region_id))
		region_row.add_child(_region_picker)
		var region_hint := UIKit.label(region_row, "La compra/venta se registra en esta región.", "InkLabel")
		region_hint.add_theme_font_size_override("font_size", 13)
		region_hint.add_theme_color_override("font_color", Palette.MUTED)

		if not trade_ok:
			var blocked := UIKit.label(
				_body,
				"Sin comerciantes asignados: compra, venta y expediciones deshabilitadas. Asigna al menos un comerciante con el control superior.",
				"InkLabel")
			blocked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			blocked.add_theme_font_size_override("font_size", 15)
			blocked.add_theme_color_override("font_color", Palette.CRIMSON)

		UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.5))
		var goods_title := UIKit.label(_body, "Mercancías", "InkLabel")
		goods_title.add_theme_font_size_override("font_size", 21)
		goods_title.add_theme_color_override("font_color", Palette.CRIMSON)
		var grid := UIKit.grid(_body, 3, 10, 7)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for good_id in TSBGame.trade_goods_ids():
			_build_good_card(grid, fid, good_id, inventory, trade_ok, str(_selected_region()))

		UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.5))
		var expedition_title := UIKit.label(_body, "Expedición de mercaderes", "InkLabel")
		expedition_title.add_theme_font_size_override("font_size", 21)
		expedition_title.add_theme_color_override("font_color", Palette.CRIMSON)
		var expedition_row := UIKit.hbox(_body, 8)
		var expedition_good := OptionButton.new()
		expedition_good.custom_minimum_size = Vector2(260, 38)
		for good_id in TSBGame.trade_goods_ids():
			expedition_good.add_item(TSBGame.trade_good(good_id).get("name", good_id))
			expedition_good.set_item_metadata(expedition_good.item_count - 1, good_id)
		expedition_row.add_child(expedition_good)
		var expedition_qty := SpinBox.new()
		expedition_qty.min_value = 1
		expedition_qty.max_value = maxi(1, TSBGame.trade_volume(fid))
		expedition_qty.value = 1
		expedition_qty.custom_minimum_size = Vector2(100, 36)
		expedition_row.add_child(expedition_qty)
		var expedition_button := UIKit.button(expedition_row, "Enviar expedición (2 PG)", "SmallButton", "TradeSystem.send_expedition(): retorno a los 2 trimestres")
		expedition_button.disabled = not trade_ok
		expedition_button.tooltip_text = "Sin comerciantes asignados" if not trade_ok else "Vende en el extranjero; retorno a 2 trimestres."
		expedition_button.pressed.connect(func() -> void: _on_expedition(fid, expedition_good, expedition_qty))
		expedition_good.item_selected.connect(func(_index: int) -> void: _update_expedition_button(expedition_button, expedition_good, trade_ok))
		_update_expedition_button(expedition_button, expedition_good, trade_ok)
		var expedition_hint := UIKit.label(_body, "Vende mercancía en el extranjero: 2 PG, retorno a los 2 trimestres con beneficio determinista.", "InkLabel")
		expedition_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		expedition_hint.add_theme_font_size_override("font_size", 13)
		expedition_hint.add_theme_color_override("font_color", Palette.MUTED)

	if _status != null and _status.text.is_empty():
		_set_status("Compra/venta y expediciones requieren comerciantes asignados y una región propia." if not trade_ok else "Selecciona una mercancía y una cantidad para operar.")


func _build_good_card(parent: Node, faction_id: String, good_id: String, inventory: Dictionary, trade_ok: bool, region_id: String) -> void:
	var good := TSBGame.trade_good(good_id)
	var amount := float(inventory.get(good_id, 0.0))
	var price := TSBGame.trade_price(faction_id, good_id, region_id)
	var base := float(good.get("base_price", 1.0))
	var factor := price / base if base > 0.0 else 1.0
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_SOFT, 0.10), Palette.with_alpha(Palette.GOLD_DIM, 0.55), 1, 4, 8, 6))
	parent.add_child(card)
	var column := UIKit.vbox(card, 3)
	var header := UIKit.hbox(column, 8)
	var name_label := UIKit.label(header, str(good.get("name", good_id)), "InkLabel")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var amount_label := UIKit.label(header, "Inv. %d" % int(amount), "InkLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	amount_label.add_theme_font_size_override("font_size", 14)
	amount_label.add_theme_color_override("font_color", Palette.GOLD_DIM)
	var price_label := UIKit.label(column, "Precio %d oro · factor ×%.2f" % [int(ceilf(price)), factor], "InkLabel")
	price_label.add_theme_font_size_override("font_size", 13)
	price_label.add_theme_color_override("font_color", Palette.MUTED)
	var controls := UIKit.hbox(column, 6)
	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = maxi(1, TSBGame.trade_volume(faction_id))
	qty.value = 1
	qty.custom_minimum_size = Vector2(100, 32)
	controls.add_child(qty)
	var buy := UIKit.button(controls, "Comprar", "SmallButton")
	buy.disabled = not trade_ok
	buy.tooltip_text = "Faltan comerciantes asignados" if not trade_ok else "Compra al precio actual; consume oro."
	buy.pressed.connect(func() -> void: _on_buy(faction_id, region_id, good_id, qty))
	var sell := UIKit.button(controls, "Vender", "SmallButton")
	sell.disabled = not trade_ok or amount < 1.0
	sell.tooltip_text = "Faltan comerciantes asignados" if not trade_ok else ("Inventario insuficiente" if amount < 1.0 else "Vende inventario y obtiene oro.")
	sell.pressed.connect(func() -> void: _on_sell(faction_id, region_id, good_id, qty))


func _update_expedition_button(button: Button, picker: OptionButton, trade_ok: bool) -> void:
	if picker.item_count == 0 or picker.selected < 0:
		button.disabled = true
		return
	var good_id := str(picker.get_item_metadata(picker.selected))
	var key := "expedition:%s" % good_id
	var used := TSBGame.action_used(key) or not TSBGame.can_use_action(key)
	button.disabled = not trade_ok or used
	button.tooltip_text = "Sin comerciantes asignados" if not trade_ok else ("Usado este turno" if used else "Vende en el extranjero; retorno a 2 trimestres.")


func _build_advisor_advice(fid: String) -> void:
	if not TSBGame.advisor_enabled():
		return
	var advice := TSBGame.trade_advice(fid, _selected_region())
	if advice.is_empty():
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(Palette.INK_DEEP, 0.10), Palette.with_alpha(Palette.GOLD_DIM, 0.7), 1, 4, 10, 7))
	_body.add_child(panel)
	var column := UIKit.vbox(panel, 2)
	var title := UIKit.label(column, "El Consejero · consejo comercial", "InkLabel")
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var text := str(advice.get("text", ""))
	if not bool(advice.get("ok", false)):
		text = "Consejo: %s." % str(advice.get("reason", "asigna comerciantes para operar"))
	elif text.is_empty():
		var kind := str(advice.get("kind", "hold"))
		var good := str(advice.get("good_id", ""))
		text = "%s: %s (precio %d, base %d, margen %+d%%)." % [
			kind.capitalize(), TSBGame.trade_good(good).get("name", good),
			int(advice.get("price", 0)), int(advice.get("base", 0)), int(roundf(float(advice.get("margin", 0.0)) * 100.0))]
	var label := UIKit.label(column, text, "InkLabel")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var deterministic := UIKit.label(column, "Cálculo determinista a partir de precios, inventario y volumen; sin azar.", "InkLabel")
	deterministic.add_theme_font_size_override("font_size", 12)
	deterministic.add_theme_color_override("font_color", Palette.MUTED)


func _selected_region() -> String:
	if _region_picker == null or _region_picker.item_count == 0 or _region_picker.selected < 0:
		return ""
	return str(_region_picker.get_item_metadata(_region_picker.selected))


func _on_buy(faction_id: String, region_id: String, good_id: String, qty: SpinBox) -> void:
	if TSBGame.buy_goods(faction_id, region_id, good_id, int(qty.value)):
		_set_status("Compra confirmada: %d de %s." % [int(qty.value), TSBGame.trade_good(good_id).get("name", good_id)])
	else:
		_set_status("No se pudo comprar (%s)." % _trade_reason())
	_rebuild()


func _on_sell(faction_id: String, region_id: String, good_id: String, qty: SpinBox) -> void:
	if TSBGame.sell_goods(faction_id, region_id, good_id, int(qty.value)):
		_set_status("Venta confirmada: %d de %s." % [int(qty.value), TSBGame.trade_good(good_id).get("name", good_id)])
	else:
		_set_status("No se pudo vender (%s)." % _trade_reason())
	_rebuild()


func _on_expedition(faction_id: String, picker: OptionButton, qty: SpinBox) -> void:
	if picker.item_count == 0 or picker.selected < 0:
		return
	var good_id := str(picker.get_item_metadata(picker.selected))
	if TSBGame.send_expedition(faction_id, good_id, int(qty.value)):
		_set_status("Expedición enviada: %d de %s; retorno a los 2 trimestres." % [int(qty.value), TSBGame.trade_good(good_id).get("name", good_id)])
	else:
		_set_status("No se pudo enviar la expedición (%s)." % _trade_reason())
	_rebuild()


func _trade_reason() -> String:
	var reason := TSBGame.trade_last_error()
	return reason if not reason.is_empty() else "recurso insuficiente"


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
