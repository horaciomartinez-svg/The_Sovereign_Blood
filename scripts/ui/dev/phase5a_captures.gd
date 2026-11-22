extends SceneTree
## Capturas Fase 5A (AG-3): estaciones/tinte, boletín, Crónica, confirmación,
## consejo del Mercado, ayuda contextual y paneles N2/N3. 1920×1080.
## Herramienta de QA: puede preparar estado para fotografiar la UI; no es código
## de producción y no altera la simulación desde la UI.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIHelp = preload("res://scripts/ui/ui_help.gd")

var _world: Node = null
var _gs: Node = null
var _shots := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	if not TSBGame.start_new_game_in_scenario("scenario_1337", "england", 1337, "beginner"):
		print("[WARN] no arranca partida")
		_finish()
		return
	_gs = root.get_node("GameState")
	change_scene_to_file("res://scenes/map/world_map.tscn")
	await _frames(12)
	_world = current_scene
	await _capture_seasons()
	await _capture_bulletin()
	await _capture_chronicle()
	await _capture_orders()
	await _capture_market_advisor()
	await _capture_help_screens()
	await _capture_n3()
	await _capture_n2()
	_finish()


func _capture_seasons() -> void:
	var names := ["primavera", "verano", "otono", "invierno"]
	for index in range(4):
		_gs.state["quarter"] = index + 1
		_gs.state["year"] = 1337
		_world.call("_refresh_all")
		await _frames(3)
		await _capture("season_%d_%s" % [index + 1, names[index]])
	_gs.state["quarter"] = 1


func _capture_bulletin() -> void:
	_hide_advisor()
	var scene: Node = load("res://scenes/ui/quarterly_bulletin.tscn").instantiate()
	var layer := _add_modal(scene)
	scene.call("setup", {"season": "Invierno", "year": 1337, "actions": []})
	await _frames(5)
	await _capture("bulletin_trimestral")
	layer.queue_free()
	await _frames(2)
	_show_advisor()


func _capture_chronicle() -> void:
	_hide_advisor()
	_gs.append_chronicle({"year": 1337, "season_or_year": "Primavera 1337", "kind": "quarter", "text": "El reino abrió el año con las arcas estables y el apoyo del pueblo intacto."})
	_gs.append_chronicle({"year": 1337, "season_or_year": "Verano 1337", "kind": "quarter", "text": "Los comerciantes ingleses cruzaron el canal y las ferias reportaron beneficios."})
	_gs.append_chronicle({"year": 1337, "season_or_year": "Otoño 1337", "kind": "quarter", "text": "La corte recibió noticias de la guerra con Francia y preparó nuevas levas."})
	_gs.append_chronicle({"year": 1337, "season_or_year": "Invierno 1337", "kind": "year", "text": "El año cerró con el tesoro en 8.000 oro y la casa Plantagenet a la cabeza del prestigio."})
	var scene: Node = load("res://scenes/ui/chronicle_screen.tscn").instantiate()
	var layer := _add_modal(scene)
	await _frames(5)
	await _capture("chronicle_anual")
	layer.queue_free()
	await _frames(2)
	var year_end: Node = load("res://scenes/ui/year_end_report.tscn").instantiate()
	var layer_end := _add_modal(year_end)
	year_end.call("setup", 1337)
	await _frames(5)
	await _capture("chronicle_year_end")
	layer_end.queue_free()
	await _frames(2)
	_show_advisor()


func _capture_orders() -> void:
	_hide_advisor()
	_gs.clear_turn_actions()
	var empty: Node = load("res://scenes/ui/order_confirmation.tscn").instantiate()
	var layer_empty := _add_modal(empty)
	await _frames(4)
	await _capture("orders_empty")
	layer_empty.queue_free()
	await _frames(2)
	_gs.record_turn_action("diplomacy", "Francia", 6)
	_gs.record_turn_action("family", "consorte", 3)
	_gs.record_turn_action("build", "Londres · mercado", 2)
	var with_actions: Node = load("res://scenes/ui/order_confirmation.tscn").instantiate()
	var layer_actions := _add_modal(with_actions)
	await _frames(4)
	await _capture("orders_with_actions")
	layer_actions.queue_free()
	await _frames(2)
	_gs.clear_turn_actions()
	_show_advisor()


func _capture_market_advisor() -> void:
	var fid := TSBGame.player_faction()
	TSBGame.set_trade_merchants(fid, mini(TSBGame.trade_available_merchants(fid), 12))
	_world.call("_open_overlay", "res://scenes/economy/market_screen.tscn", "market", null)
	await _frames(6)
	await _capture("market_advisor")
	var overlay: Variant = _world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _frames(3)


func _capture_help_screens() -> void:
	_hide_advisor()
	for screen in ["main_menu", "world_map", "diplomacy", "battle_n2"]:
		var scene: Node = load("res://scenes/ui/context_help_overlay.tscn").instantiate()
		var layer := _add_modal(scene)
		scene.call("setup", screen)
		await _frames(3)
		await _capture("help_%s" % screen)
		layer.queue_free()
		await _frames(1)
	_show_advisor()


func _add_modal(scene: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	layer.add_child(scene)
	return layer


func _hide_advisor() -> void:
	var advisor: Variant = _world.get("_advisor")
	if advisor is CanvasItem:
		(advisor as CanvasItem).visible = false


func _show_advisor() -> void:
	if _world != null and _world.has_method("_refresh_tutorial_ui"):
		_world.call("_refresh_tutorial_ui")


func _capture_n3() -> void:
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	var attacker := {
		"id": "demo_england", "faction": "england", "unit_id": "men_at_arms",
		"size": 1800, "strength": 12, "morale": 1.0, "experience": 60,
		"commander_stat": 82, "commander_status": "sano",
	}
	var defender := {
		"id": "demo_france", "faction": "france", "unit_id": "longbowman",
		"size": 2000, "strength": 9, "morale": 0.9, "experience": 45,
		"commander_stat": 64, "commander_wounded": true,
	}
	scene.call("setup", attacker, defender)
	await _frames(6)
	await _capture("panel_n3")
	scene.queue_free()
	await _frames(3)


func _capture_n2() -> void:
	var context := _find_battle_context()
	if context.is_empty():
		print("[WARN] N2 sin contexto de batalla")
		return
	_world.call("_open_tactical_battle", str(context.get("attacker", "")), str(context.get("defender", "")), str(context.get("region", "")))
	await _frames(4)
	var tactical: Variant = _world.get("_overlay")
	if tactical == null:
		print("[WARN] N2 sin overlay")
		return
	tactical.call("_begin_level2")
	await _frames(6)
	var tb: Variant = tactical.get("_tb")
	if tb == null:
		print("[WARN] N2 sin TacticalBattle")
		(tactical as Node).call("_abandon")
		return
	var units: Array = tb.call("get_units")
	var chosen: Dictionary = {}
	for unit_value: Variant in units:
		if unit_value is Dictionary and str((unit_value as Dictionary).get("side", "")) == "attacker":
			if chosen.is_empty() or bool((unit_value as Dictionary).get("commander", false)):
				chosen = (unit_value as Dictionary)
			if bool(chosen.get("commander", false)):
				break
	if not chosen.is_empty():
		tactical.call("_on_cell_clicked", int(chosen.get("q", 0)), int(chosen.get("r", 0)))
	await _frames(4)
	await _capture("panel_n2")
	(tactical as Node).call("_abandon")
	await _frames(3)


func _find_battle_context() -> Dictionary:
	var player := TSBGame.player_faction()
	for army_value: Variant in TSBGame.armies().values():
		if not (army_value is Dictionary):
			continue
		var army: Dictionary = army_value
		if str(army.get("faction_id", "")) != player:
			continue
		var region := str(army.get("region_id", ""))
		for adjacent: Variant in TSBGame.region_adjacency(region):
			var target := str(adjacent)
			var defender := TSBGame.defender_army_in(target, player)
			if not defender.is_empty():
				return {"attacker": str(army.get("id", "")), "defender": str(defender.get("id", "")), "region": target}
	return {}


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("[WARN] sin imagen ", file_name)
		return
	image.save_png(OUT_DIR.path_join(file_name + ".png"))
	_shots += 1
	print("  [OK] ", file_name, " ", image.get_size())


func _finish() -> void:
	print("CAPTURAS FASE 5A: %d en %s" % [_shots, OUT_DIR])
	TSBGame.reset_game()
	quit(0)
