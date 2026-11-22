extends SceneTree
## Capturas del flujo MVP-1337 (D-066): menú, selección con 1402/1453 EN PAUSA,
## mapa, panel de región, pantallas §9, N1/N2/N3, fin de partida y guardar/cargar.
## Herramienta de desarrollo; AG-0 copia las finales a docs/screenshots.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _shots: Array[String] = []
var _world: Node = null


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _settle(10)
	await _capture("mvp_01_main_menu")
	if current_scene != null:
		current_scene.call("_on_new_game")
	await _settle(10)
	await _capture("mvp_02_scenario_select_paused")
	if current_scene != null:
		current_scene.call("_on_start")
	await _settle(14)
	_world = current_scene
	await _capture("mvp_03_world_map_1337")

	if _world == null:
		print("[WARN] no se abrió el mapa")
		_finish()
		return

	# Panel de región.
	_world.call("_on_region_clicked", "region_londres")
	await _settle(2)
	await _capture("mvp_04_region_panel")
	_world.call("_on_region_panel_closed")
	await _settle(2)

	# Pantallas §9.
	await _overlay("mvp_05_diplomacy", "res://scenes/diplomacy/diplomacy_screen.tscn", "diplomacy", null)
	await _overlay("mvp_06_dynasty", "res://scenes/family/family_tree.tscn", "family", null)
	await _overlay("mvp_07_military", "res://scenes/military/military_screen.tscn", "military", null)
	await _overlay("mvp_08_economy", "res://scenes/economy/economy_screen.tscn", "economy", null)

	# N1: informe de batalla (Nivel 1 delegado).
	await _overlay("mvp_09_n1_battle_report", "res://scenes/battle/battle_report.tscn", "battle", _sample_battle_report())

	# N2: mapa táctico con una batalla real de campaña si hay ejércitos.
	var context := _find_battle_context()
	if not context.is_empty():
		_world.call("_open_tactical_battle", str(context.get("attacker", "")), str(context.get("defender", "")), str(context.get("region", "")))
		await _settle(5)
		var tactical: Variant = _world.get("_overlay")
		if tactical is Node and tactical.has_method("_begin_level2"):
			tactical.call("_begin_level2")
			await _settle(8)
			await _capture("mvp_10_n2_tactical")
			if tactical.has_method("_abandon"):
				tactical.call("_abandon")
			await _settle(3)
	else:
		print("[SKIP] N2: sin ejércitos enemigos adyacentes")

	# N3: combate cerrado con animación v1.8.1 (attack_4 + proyectil).
	await _n3_capture()

	# Fin de partida (overlay representativo, sin mutar la campaña).
	_world.call("_open_victory", TSBGame.player_faction(), false, "Pérdida total de regiones")
	await _settle(4)
	await _capture("mvp_11_game_over")
	var victory_overlay: Variant = _world.get("_overlay")
	if victory_overlay is Node and is_instance_valid(victory_overlay):
		(victory_overlay as Node).call("close_overlay")
	await _settle(2)

	# Guardar con feedback y opciones.
	_world.call("_on_save_pressed")
	await _settle(3)
	await _capture("mvp_12_save_feedback")
	_world.call("_open_options")
	await _settle(3)
	await _capture("mvp_13_options")
	var options_overlay: Variant = _world.get("_overlay")
	if options_overlay is Node and is_instance_valid(options_overlay):
		(options_overlay as Node).call("close_overlay")
	await _settle(2)

	# Cargar desde el menú principal (el botón ya está habilitado).
	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _settle(10)
	await _capture("mvp_14_load_menu")

	_finish()


func _n3_capture() -> void:
	# La escena N3 se abre sobre el mapa: oculta el HUD para una captura limpia.
	var hud_hidden := false
	if _world != null:
		var hud_layer: Variant = _world.get("_hud_layer")
		if hud_layer is CanvasLayer:
			(hud_layer as CanvasLayer).visible = false
			hud_hidden = true
			await _settle(2)
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	scene.call("setup",
		{"id": "mvp_atk", "faction": "england", "unit_id": "longbowman", "size": 800, "strength": 9, "morale": 1.0, "experience": 20},
		{"id": "mvp_def", "faction": "france", "unit_id": "militia_spearman", "size": 700, "strength": 8, "morale": 1.0, "experience": 10},
		{}, {"region_id": "region_inglaterra_sur"})
	await _settle(5)
	var cc: Variant = scene.get("_cc")
	if cc == null:
		print("[SKIP] N3: CloseCombat no disponible")
		scene.queue_free()
		return
	var state: Dictionary = cc.call("get_state")
	var hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
	if not hand.is_empty():
		scene.call("_play_card", str(hand[0]))
		cc.call("tick_animation", 340.0)
		await _settle(1)
	await _capture("mvp_15_n3_animation")
	scene.queue_free()
	await _settle(3)
	if hud_hidden and _world != null:
		var hud_layer: Variant = _world.get("_hud_layer")
		if hud_layer is CanvasLayer:
			(hud_layer as CanvasLayer).visible = true
		await _settle(2)


func _overlay(capture_name: String, scene_path: String, kind: String, setup_arg: Variant) -> void:
	if _world == null:
		return
	_world.call("_open_overlay", scene_path, kind, setup_arg)
	await _settle(4)
	await _capture(capture_name)
	var overlay: Variant = _world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _settle(3)


func _sample_battle_report() -> Dictionary:
	return {
		"attacker_faction": "england",
		"defender_faction": "france",
		"region_id": "region_normandia",
		"winner_faction": "england",
		"attacker_losses": 420,
		"defender_losses": 1150,
		"rounds": [
			{"round": 1, "attacker_damage": 60, "defender_damage": 210},
			{"round": 2, "attacker_damage": 95, "defender_damage": 320},
			{"round": 3, "attacker_damage": 130, "defender_damage": 410},
		],
		"region_captured": true,
		"loot_gold": 1200,
		"prisoners": 34,
		"notes": "Nivel 1 delegado: los arqueros largos rompen la línea francesa.",
	}


func _find_battle_context() -> Dictionary:
	var player := TSBGame.player_faction()
	for army: Variant in TSBGame.armies().values():
		if not (army is Dictionary):
			continue
		if str((army as Dictionary).get("faction_id", "")) != player:
			continue
		var from_region := str((army as Dictionary).get("region_id", ""))
		for adjacent: Variant in TSBGame.region_adjacency(from_region):
			var target := str(adjacent)
			var defender := TSBGame.defender_army_in(target, player)
			if not defender.is_empty():
				return {
					"attacker": str((army as Dictionary).get("id", "")),
					"defender": str(defender.get("id", "")),
					"region": target,
				}
	return {}


func _capture(capture_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("  [WARN] sin imagen para ", capture_name)
		return
	image.save_png(OUT_DIR.path_join(capture_name + ".png"))
	_shots.append(capture_name)
	print("  [OK] ", capture_name, " ", image.get_size())


func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame


func _finish() -> void:
	print("CAPTURAS MVP-1337: %d en %s" % [_shots.size(), OUT_DIR])
	quit(0)
