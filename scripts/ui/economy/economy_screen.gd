extends "res://scripts/ui/widgets/overlay_base.gd"
## Pantalla de economia (GDD §9.4): tesoro, apoyo por region y produccion.
## Las ordenes de mano de obra (1 PG/orden) se ejecutan en el panel de region.

signal region_requested(region_id: String)
signal market_requested

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1320, 820)
	add_title("ECONOMÍA DEL REINO", "Tesoro, apoyo popular y producción de las regiones")
	_body = add_body_scroll()
	var footer := add_footer("CERRAR")
	var market_button := UIKit.button(footer, "MERCADO", "SmallButton", "Abrir el mercado de mercancías y comerciantes")
	market_button.pressed.connect(_open_market)
	market_button.move_to_front()
	_rebuild()


func _open_market() -> void:
	market_requested.emit()
	close_overlay()


func refresh() -> void:
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var fid := TSBGame.player_faction()
	var owned := TSBGame.regions_owned_by(fid)
	var total_population := 0
	var total_buildings := 0
	for region_id: Variant in owned:
		var data := TSBGame.region(str(region_id))
		total_population += int(data.get("population", 0))
		var buildings: Variant = data.get("buildings", [])
		if buildings is Array:
			total_buildings += (buildings as Array).size()

	var stats := UIKit.grid(_body, 4, 14, 4)
	_stat(stats, "Tesoro", "%d oro" % TSBGame.gold(fid))
	_stat(stats, "PG del trimestre", "%d / %d" % [TSBGame.pg_remaining(), maxi(TSBGame.pg_max(), 1)])
	_stat(stats, "Población", TSBGame.short_number(total_population))
	_stat(stats, "Edificios", str(total_buildings))

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var title := UIKit.label(_body, "Regiones del reino", "InkLabel")
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Palette.CRIMSON)
	var hint := UIKit.label(
		_body,
		"Las órdenes de mano de obra (farmers/artisans/merchants/recruits) cuestan 1 PG cada una y se dan en el panel de región del mapa. Aquí solo se consultan los valores.",
		"InkLabel")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.MUTED)

	if owned.is_empty():
		var empty := UIKit.label(_body, "No controlas ninguna región.", "InkLabel")
		empty.add_theme_font_size_override("font_size", 15)
		return

	var grid := UIKit.grid(_body, 3, 12, 5)
	_cell_header(grid, "Región")
	_cell_header(grid, "Apoyo")
	_cell_header(grid, "Producción / estado")
	for region_id: Variant in owned:
		var rid := str(region_id)
		var name_button := UIKit.button(grid, TSBGame.region_name(rid), "GhostButton", "Abrir el panel de esta región en el mapa")
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_button.add_theme_font_size_override("font_size", 15)
		name_button.pressed.connect(func() -> void: _open_region(rid))
		var support := TSBGame.support(rid)
		var support_box := UIKit.vbox(grid, 2)
		var bar := UIKit.bar(support_box, support, 100, Palette.support_color(support), 10)
		var support_label := UIKit.label(support_box, "%d/100" % support, "InkLabel")
		support_label.add_theme_font_size_override("font_size", 11)
		support_label.add_theme_color_override("font_color", Palette.INK_TEXT)
		var output := TSBGame.region_output(rid)
		var output_text := "Sin datos de producción (EconomySystem en integración)."
		if not output.is_empty():
			var parts: Array[String] = []
			for key: Variant in output.keys():
				parts.append("%s: %s" % [str(key).replace("_", " "), str(output[key])])
				if parts.size() >= 4:
					break
			output_text = " · ".join(parts)
		var output_label := UIKit.label(grid, output_text, "InkLabel")
		output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		output_label.add_theme_font_size_override("font_size", 13)
		output_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _cell_header(parent: Node, text: String) -> void:
	var label := UIKit.label(parent, text, "InkLabel")
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Palette.CRIMSON)


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 13)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _open_region(region_id: String) -> void:
	region_requested.emit(region_id)
	close_overlay()
