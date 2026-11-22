extends SceneTree
## Capturas Fase 3 escenarios (AG-3): selección de 3 escenarios, partidas
## 1402/1453 y HUD de era. Tolerante a datos aún no entregados.
## Uso: godot --path <repo> --script scripts/ui/dev/scenario_captures.gd

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _captures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	change_scene_to_file("res://scenes/main/scenario_select.tscn")
	await _frames(8)
	# Selecciona 1402 para que la captura muestre sus 8 casas jugables.
	var initial_scene := current_scene
	if initial_scene != null and TSBGame.scenario_available("scenario_1402") and initial_scene.has_method("_select_scenario"):
		initial_scene.call("_select_scenario", "scenario_1402")
		await _frames(4)
	await _capture("selection_3_scenarios")

	var captured_era := false
	for scenario_id: String in ["scenario_1402", "scenario_1453"]:
		var playable := TSBGame.playable_factions(scenario_id)
		if not TSBGame.scenario_available(scenario_id) or playable.is_empty():
			print("[SKIP] %s: datos aún no disponibles" % scenario_id)
			continue
		# Arranque real desde la UI de selección (data-driven).
		change_scene_to_file("res://scenes/main/scenario_select.tscn")
		await _frames(8)
		var selection := current_scene
		if selection == null or not selection.has_method("_select_scenario"):
			print("[SKIP] %s: selección no disponible" % scenario_id)
			continue
		selection.call("_select_scenario", scenario_id)
		await _frames(3)
		selection.call("_select_faction", str(playable[0]))
		await _frames(2)
		selection.call("_on_start")
		await _frames(12)
		var capture_name := "game_" + scenario_id.trim_prefix("scenario_")
		await _capture(capture_name)
		if not captured_era:
			await _capture("era_hud")
			captured_era = true

	if not captured_era:
		# Con datos en preparación, al menos documenta el HUD de era en 1337.
		if TSBGame.start_new_game_in_scenario("scenario_1337", "england"):
			change_scene_to_file("res://scenes/map/world_map.tscn")
			await _frames(10)
			await _capture("era_hud")

	print("CAPTURAS ESCENARIOS: %d en %s" % [_captures, OUT_DIR])
	quit(0)


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
	_captures += 1
	print("  [OK] ", file_name, " ", image.get_size())
