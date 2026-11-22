extends SceneTree
## Capturas de pantalla de la UI (AG-3) para revision visual y de integracion.
## NO forma parte del juego: herramienta de desarrollo. Requiere render.
##
## Uso:
##   godot --path <repo> --script scripts/ui/dev/ui_screenshots.gd
## Guarda PNGs en C:/Proyectos/TSB/.ui_check/.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check"

var _shots: Array[String] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	# Flujo real de navegacion: menu -> seleccion -> mapa (nueva partida).
	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _settle(8)
	await _capture("01_main_menu")

	if current_scene != null:
		current_scene.call("_on_new_game")
	await _settle(8)
	await _capture("02_scenario_select")

	if current_scene != null:
		current_scene.call("_on_start")
	await _settle(12)
	await _capture("03_world_map")

	var world := current_scene
	if world != null:
		# Tooltip de region.
		world.call("_on_region_hovered", "region_londres")
		var tooltip: Variant = world.get("_tooltip")
		if tooltip is Control:
			(tooltip as Control).call("follow", Vector2(760, 420))
		await _settle(2)
		await _capture("03b_tooltip")
		if tooltip is Control:
			(tooltip as Control).call("hide_tip")

		# Panel de region con estado real.
		world.call("_on_region_clicked", "region_londres")
		await _settle(3)
		await _capture("04_region_panel")
		world.call("_on_region_panel_closed")

		await _overlay(world, "res://scenes/ui/court_overview.tscn", "court", null, "05_court")
		await _overlay(world, "res://scenes/family/family_tree.tscn", "family", null, "06_family_tree")
		await _overlay(world, "res://scenes/diplomacy/diplomacy_screen.tscn", "diplomacy", null, "07_diplomacy")
		await _overlay(world, "res://scenes/military/military_screen.tscn", "military", null, "08_military")
		await _overlay(world, "res://scenes/economy/economy_screen.tscn", "economy", null, "09_economy")
		await _overlay(world, "res://scenes/ui/options_menu.tscn", "options", true, "10_options")
		await _overlay(world, "res://scenes/battle/battle_report.tscn", "battle", {
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
			"loot": 1200,
			"prisoners": 34,
			"notes": "Los arqueros largos rompen la linea francesa al tercer asalto.",
		}, "11_battle_report")
		await _overlay(world, "res://scenes/ui/year_end_report.tscn", "year_end", 1338, "12_year_end")
		await _overlay(world, "res://scenes/ui/victory_screen.tscn", "victory", {
			"faction_id": "england",
			"victory": true,
			"reason": "Dos coronas sostenidas durante una decada (GDD §4.5).",
		}, "13_victory")

		# Terminar turno real (IA rival + resoluciones).
		world.call("_on_end_turn_requested")
		await create_timer(3.0).timeout
		await _settle(6)
		await _capture("14_after_end_turn")
		var live_overlay: Variant = world.get("_overlay")
		if live_overlay is Node and is_instance_valid(live_overlay):
			await _capture("15_live_overlay_" + str(world.get("_overlay_kind")))
			(live_overlay as Node).call("close_overlay")
			await _settle(3)
			await _capture("16_after_overlay")

	print("CAPTURAS: %d imagenes en %s" % [_shots.size(), OUT_DIR])
	quit(0)


func _overlay(world: Node, scene_path: String, kind: String, setup_arg: Variant, capture_name: String) -> void:
	world.call("_open_overlay", scene_path, kind, setup_arg)
	await _settle(3)
	await _capture(capture_name)
	var overlay: Variant = world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _settle(3)


func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame


func _capture(capture_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("  [WARN] sin imagen para ", capture_name)
		return
	image.save_png(OUT_DIR.path_join(capture_name + ".png"))
	_shots.append(capture_name)
	print("  [OK] ", capture_name, " ", image.get_size())
