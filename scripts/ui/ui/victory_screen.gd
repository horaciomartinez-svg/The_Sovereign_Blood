extends "res://scripts/ui/widgets/overlay_base.gd"
## Pantalla de victoria/derrota con estadisticas de la partida (GDD §9.9).
## Se abre al recibir EventBus.game_over / GameState.game_over.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const WORLD_MAP_SCENE := "res://scenes/map/world_map.tscn"

var _payload: Dictionary = {}
var _body: VBoxContainer = null


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1120, 780)
	_body = add_body_scroll()
	UIKit.hsep(content, Palette.with_alpha(Palette.GOLD_DIM, 0.8))
	var footer := UIKit.hbox(content, 10)
	footer.alignment = BoxContainer.ALIGNMENT_END

	var load_button := UIKit.button(footer, "Cargar autoguardado", "SmallButton")
	load_button.disabled = not TSBGame.has_save("autosave")
	load_button.pressed.connect(_on_load)
	var menu_button := UIKit.button(footer, "Menú principal", "")
	menu_button.custom_minimum_size = Vector2(240, 50)
	menu_button.pressed.connect(_on_main_menu)
	var close_button := UIKit.button(footer, "CERRAR", "PrimaryButton")
	close_button.custom_minimum_size = Vector2(220, 50)
	close_button.pressed.connect(close_overlay)
	_rebuild()


func setup(payload: Variant) -> void:
	if payload is Dictionary:
		_payload = payload
	else:
		_payload = {}
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var faction_id := str(_payload.get("faction_id", TSBGame.player_faction()))
	var victory := bool(_payload.get("victory", false))
	var raw_reason := str(_payload.get("reason", ""))
	if raw_reason.is_empty():
		raw_reason = TSBGame.game_over_reason()
	var reason := _reason_category(raw_reason, victory)
	var banner_color := Palette.GREEN if victory else Palette.CRIMSON
	var banner_text := "VICTORIA" if victory else "DERROTA"

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", Palette.stylebox(Palette.with_alpha(banner_color, 0.18), banner_color, 2, 6, 16, 10))
	_body.add_child(banner)
	var banner_label := UIKit.label(banner, banner_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.add_theme_font_size_override("font_size", 46)
	banner_label.add_theme_color_override("font_color", Palette.INK_TEXT)

	var faction_label := UIKit.label(_body, TSBGame.faction_name(faction_id), "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	faction_label.add_theme_font_size_override("font_size", 26)
	faction_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	if not reason.is_empty():
		var reason_label := UIKit.label(_body, "Motivo: " + reason, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason_label.add_theme_font_size_override("font_size", 18)
		reason_label.add_theme_color_override("font_color", Palette.CRIMSON)
		if not raw_reason.is_empty() and raw_reason != reason:
			var detail_label := UIKit.label(_body, raw_reason, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_label.add_theme_font_size_override("font_size", 14)
			detail_label.add_theme_color_override("font_color", Palette.MUTED)

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var stats_title := UIKit.label(_body, "Estadísticas del reinado", "InkLabel")
	stats_title.add_theme_font_size_override("font_size", 22)
	stats_title.add_theme_color_override("font_color", Palette.CRIMSON)

	var years := maxi(TSBGame.current_year() - TSBGame.start_year(), 0)
	var stats := UIKit.grid(_body, 3, 14, 6)
	_stat(stats, "Años de reinado", str(years))
	_stat(stats, "Turnos jugados", str(TSBGame.current_turn()))
	_stat(stats, "Regiones gobernadas", "%d de %d" % [TSBGame.regions_owned_by(faction_id).size(), TSBGame.region_ids().size()])
	_stat(stats, "Tesoro final", "%d oro" % TSBGame.gold(faction_id))
	_stat(stats, "Prestigio", str(TSBGame.prestige(faction_id)))
	var army_count := 0
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == faction_id:
			army_count += 1
	_stat(stats, "Ejércitos", str(army_count))

	UIKit.hsep(_body, Palette.with_alpha(Palette.GOLD_DIM, 0.7))
	var casa_title := UIKit.label(_body, "La casa", "InkLabel")
	casa_title.add_theme_font_size_override("font_size", 22)
	casa_title.add_theme_color_override("font_color", Palette.CRIMSON)
	var members := TSBGame.family_members(faction_id)
	var alive := 0
	var dead := 0
	for member: Variant in members:
		if member is Dictionary:
			if bool((member as Dictionary).get("alive", false)):
				alive += 1
			else:
				dead += 1
	var casa_stats := UIKit.grid(_body, 3, 14, 6)
	_stat(casa_stats, "Casa real", "%d vivos" % alive)
	_stat(casa_stats, "Antepasados", "%d fallecidos" % dead)
	var ruler := TSBGame.ruler(faction_id)
	_stat(casa_stats, "Último soberano", str(ruler.get("name", "—")))

	var battles := TSBGame.battle_reports().size()
	if battles > 0:
		var battle_label := UIKit.label(_body, "Batallas registradas: %d" % battles, "InkLabel")
		battle_label.add_theme_font_size_override("font_size", 16)
		battle_label.add_theme_color_override("font_color", Palette.INK_TEXT)

	var next := UIKit.label(
		_body,
		"Puedes cargar el autoguardado del último fin de año o volver al menú para empezar otro reinado.",
		"InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next.add_theme_font_size_override("font_size", 15)
	next.add_theme_color_override("font_color", Palette.INK_TEXT.darkened(0.15))


func _reason_category(raw_reason: String, victory: bool) -> String:
	var lowered := raw_reason.to_lower()
	if lowered.contains("prestigio") or lowered.contains("prestige"):
		return "Prestigio Real sostenido"
	if lowered.contains("conquist") or lowered.contains("control"):
		return "Conquista territorial (≥ 70 % de regiones)"
	if lowered.contains("superviv") or lowered.contains("end_year") or lowered.contains("año final") or lowered.contains("final del escenario"):
		return "Supervivencia hasta el final del escenario"
	if lowered.contains("extint") or lowered.contains("dinast"):
		return "Extinción dinástica"
	if lowered.contains("perdido todas") or lowered.contains("pérdida total") or lowered.contains("perdida total") or lowered.contains("sin regiones"):
		return "Pérdida total de regiones"
	if not raw_reason.is_empty() and lowered.length() <= 32 and not lowered.contains(" "):
		return raw_reason.capitalize()
	return "Victoria" if victory else "Derrota"


func _stat(parent: Node, key_text: String, value_text: String) -> void:
	var box := UIKit.vbox(parent, 1)
	var key_label := UIKit.label(box, key_text, "InkLabel")
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", Palette.MUTED)
	var value_label := UIKit.label(box, value_text, "InkLabel")
	value_label.add_theme_font_size_override("font_size", 19)
	value_label.add_theme_color_override("font_color", Palette.INK_TEXT)


func _on_load() -> void:
	if TSBGame.load_game("autosave"):
		get_tree().change_scene_to_file(WORLD_MAP_SCENE)
	else:
		_payload = {"faction_id": str(_payload.get("faction_id", "")), "victory": false, "reason": "No se pudo cargar el autoguardado."}
		_rebuild()


func _on_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
