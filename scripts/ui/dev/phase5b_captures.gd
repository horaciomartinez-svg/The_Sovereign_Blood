extends SceneTree
## Capturas Fase 5B (AG-3): ataque/guerra, guardado, propiedad, expedición,
## tutorial y comparativas D-090. 1920×1080.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const AttackScene = preload("res://scenes/military/attack_screen.tscn")
const SaveLoadScene = preload("res://scenes/ui/save_load_screen.tscn")

var _world: Node = null
var _gs: Node = null
var _shots := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	await _start_world()
	await _capture_attack_flow()
	await _capture_save()
	await _capture_region_ownership()
	await _capture_market_expedition()
	await _capture_tutorial_steps()
	await _capture_font_comparisons()
	await _capture_main_menu()
	_finish()


func _start_world() -> void:
	if not TSBGame.start_new_game_in_scenario("scenario_1337", "england", 1337, "beginner"):
		print("[WARN] no arranca partida")
		return
	_gs = root.get_node("GameState")
	change_scene_to_file("res://scenes/map/world_map.tscn")
	await _frames(10)
	_world = current_scene


func _capture_attack_flow() -> void:
	_ensure_frontier_army()
	_world.call("_open_overlay", AttackScene.resource_path, "attack", null)
	await _frames(5)
	var attack: Variant = _world.get("_overlay")
	if attack == null:
		print("[WARN] sin pantalla de ataque")
		return
	await _capture("attack_screen")
	if attack.has_method("_on_attack_pressed"):
		attack.call("_on_attack_pressed")
		await _frames(3)
		await _capture("war_confirm")
		attack.call("_perform_attack")
		await _frames(4)
		await _capture("attack_result")
	if attack is Node and is_instance_valid(attack):
		(attack as Node).call("close_overlay")
	await _frames(3)


func _ensure_frontier_army() -> void:
	var player := TSBGame.player_faction()
	for army_value: Variant in TSBGame.armies().values():
		if not (army_value is Dictionary):
			continue
		var army: Dictionary = army_value
		if str(army.get("faction_id", "")) != player:
			continue
		var region := str(army.get("region_id", ""))
		var target := _frontier_target(region, player)
		if not target.is_empty():
			return
		for staging: Variant in TSBGame.region_adjacency(region):
			var staging_id := str(staging)
			if TSBGame.region_owner(staging_id) != player:
				continue
			var frontier := _frontier_target(staging_id, player)
			if frontier.is_empty():
				continue
			if TSBGame.move_army(str(army.get("id", "")), staging_id):
				return


func _frontier_target(region: String, player: String) -> String:
	for adjacent: Variant in TSBGame.region_adjacency(region):
		var target := str(adjacent)
		var owner := TSBGame.region_owner(target)
		if owner == player or (not owner.is_empty() and TSBGame.are_allied(player, owner)):
			continue
		return target
	return ""


func _capture_save() -> void:
	TSBGame.save_game("slot_1")
	TSBGame.save_game("slot_2")
	TSBGame.autosave()
	_world.call("_open_overlay", SaveLoadScene.resource_path, "save_load", null)
	await _frames(5)
	await _capture("save_load_screen")
	var overlay: Variant = _world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _frames(3)


func _capture_region_ownership() -> void:
	var player := TSBGame.player_faction()
	var foreign := ""
	for region_id: Variant in TSBGame.region_ids():
		var owner := TSBGame.region_owner(str(region_id))
		if owner != player and not owner.is_empty():
			foreign = str(region_id)
			break
	if foreign.is_empty():
		print("[WARN] sin región ajena")
		return
	_world.call("_on_region_clicked", foreign)
	await _frames(5)
	await _capture("region_not_owner")
	var panel: Variant = _world.get("_region_panel")
	if panel is Node and is_instance_valid(panel):
		if (panel as Node).has_method("close_overlay"):
			(panel as Node).call("close_overlay")
		_world.call("_on_region_panel_closed")
	await _frames(3)


func _capture_market_expedition() -> void:
	var fid := TSBGame.player_faction()
	TSBGame.set_trade_merchants(fid, mini(TSBGame.trade_available_merchants(fid), 12))
	_world.call("_open_overlay", "res://scenes/economy/market_screen.tscn", "market", null)
	await _frames(5)
	await _scroll_to_bottom(_world.get("_overlay"))
	await _frames(2)
	await _capture("market_expedition")
	var overlay: Variant = _world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _frames(3)


func _capture_tutorial_steps() -> void:
	# Nueva partida para capturar los pasos con el Consejero activo.
	TSBGame.reset_game()
	await _start_world()
	TSBGame.tutorial_advance("open_region")
	TSBGame.tutorial_advance("assign_workers")
	TSBGame.tutorial_advance("open_family")
	TSBGame.tutorial_advance("open_diplomacy")
	await _frames(2)
	var fid := TSBGame.player_faction()
	TSBGame.set_trade_merchants(fid, mini(TSBGame.trade_available_merchants(fid), 12))
	_world.call("_open_overlay", "res://scenes/economy/market_screen.tscn", "market", null)
	await _frames(5)
	await _scroll_to_bottom(_world.get("_overlay"))
	await _frames(2)
	await _capture("tutorial_expedition")
	var market: Variant = _world.get("_overlay")
	if market is Node and is_instance_valid(market):
		(market as Node).call("close_overlay")
	await _frames(3)
	TSBGame.tutorial_advance("expedition_sent")
	_world.call("_open_overlay", "res://scenes/military/military_screen.tscn", "military", null)
	await _frames(5)
	await _capture("tutorial_attack")
	var military: Variant = _world.get("_overlay")
	if military is Node and is_instance_valid(military):
		(military as Node).call("close_overlay")
	await _frames(3)
	TSBGame.tutorial_advance("attack_launched")
	TSBGame.tutorial_advance("battle_played")
	TSBGame.tutorial_advance("end_turn")
	_world.call("_open_overlay", SaveLoadScene.resource_path, "save_load", null)
	await _frames(5)
	await _capture("tutorial_save")
	var save: Variant = _world.get("_overlay")
	if save is Node and is_instance_valid(save):
		(save as Node).call("close_overlay")
	await _frames(3)


func _capture_font_comparisons() -> void:
	TSBGame.tutorial_skip()
	await _capture("font_map")
	_world.call("_open_overlay", "res://scenes/military/military_screen.tscn", "military", null)
	await _frames(4)
	await _capture("font_military")
	var military: Variant = _world.get("_overlay")
	if military is Node and is_instance_valid(military):
		(military as Node).call("close_overlay")
	await _frames(3)
	_world.call("_open_overlay", "res://scenes/economy/market_screen.tscn", "market", null)
	await _frames(4)
	await _capture("font_market")
	var market: Variant = _world.get("_overlay")
	if market is Node and is_instance_valid(market):
		(market as Node).call("close_overlay")
	await _frames(3)
	await _capture_help_modal("military", "font_help")
	await _capture_bulletin("font_bulletin")
	await _capture_battle_n3("font_battle")
	await _capture_save_modal("font_save")


func _capture_help_modal(screen: String, file_name: String) -> void:
	var scene: Node = load("res://scenes/ui/context_help_overlay.tscn").instantiate()
	var layer := _add_modal(scene)
	scene.call("setup", screen)
	await _frames(4)
	await _capture(file_name)
	layer.queue_free()
	await _frames(2)


func _capture_bulletin(file_name: String) -> void:
	var scene: Node = load("res://scenes/ui/quarterly_bulletin.tscn").instantiate()
	var layer := _add_modal(scene)
	scene.call("setup", {"season": "Primavera", "year": 1337, "actions": []})
	await _frames(4)
	await _capture(file_name)
	layer.queue_free()
	await _frames(2)


func _capture_save_modal(file_name: String) -> void:
	var scene: Node = SaveLoadScene.instantiate()
	var layer := _add_modal(scene)
	await _frames(4)
	await _capture(file_name)
	layer.queue_free()
	await _frames(2)


func _capture_battle_n3(file_name: String) -> void:
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	var layer := _add_modal(scene)
	scene.call("setup",
		{"id": "demo_england", "faction": "england", "unit_id": "men_at_arms", "size": 1800, "strength": 12, "morale": 1.0, "experience": 60, "commander_stat": 82, "commander_status": "sano"},
		{"id": "demo_france", "faction": "france", "unit_id": "longbowman", "size": 2000, "strength": 9, "morale": 0.9, "experience": 45, "commander_stat": 64, "commander_wounded": true})
	await _frames(6)
	await _capture(file_name)
	layer.queue_free()
	await _frames(3)


func _capture_main_menu() -> void:
	TSBGame.reset_game()
	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _frames(8)
	await _capture("main_menu_unchanged")


func _add_modal(scene: Node) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	layer.add_child(scene)
	return layer


func _scroll_to_bottom(overlay: Variant) -> void:
	if not (overlay is Node):
		return
	var body: Variant = overlay.get("_body")
	if not (body is Node):
		return
	var parent := (body as Node).get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		var scroll := parent as ScrollContainer
		await process_frame
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


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
	print("CAPTURAS FASE 5B: %d en %s" % [_shots, OUT_DIR])
	quit(0)
