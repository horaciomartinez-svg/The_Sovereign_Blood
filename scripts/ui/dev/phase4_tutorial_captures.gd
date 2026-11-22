extends SceneTree
## Capturas Fase 4 (AG-3): dificultad, Consejero/tutorial, familia/consorte,
## Manual/Ayuda. 1920×1080; usa una partida 1337 en dificultad principiante.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _shots := 0
var _world: Node = null


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	# Menú principal con el botón Manual.
	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _frames(8)
	await _capture("manual_menu")

	# Selección con el selector de dificultad (Principiante).
	change_scene_to_file("res://scenes/main/scenario_select.tscn")
	await _frames(8)
	if current_scene != null and current_scene.get("_difficulty_picker") != null:
		var picker: OptionButton = current_scene.get("_difficulty_picker")
		picker.select(1)
		current_scene.set("_difficulty", "beginner")
		await _frames(2)
	await _capture("difficulty_selector")

	# Arranque real en principiante (Consejero activo).
	if not TSBGame.start_new_game_in_scenario("scenario_1337", "england", 1337, "beginner"):
		print("[WARN] no arranca partida beginner")
		_finish()
		return
	change_scene_to_file("res://scenes/map/world_map.tscn")
	await _frames(12)
	_world = current_scene
	await _frames(4)
	await _capture("tutorial_consejero")

	# Avanza el tutorial a un paso con resaltado claro (familia) sin abrir el overlay.
	TSBGame.tutorial_advance("open_region")
	TSBGame.tutorial_advance("assign_workers")
	await _frames(3)
	await _capture("tutorial_highlight")

	# Familia con la acción de consorte.
	if _world != null:
		_world.call("_open_overlay", "res://scenes/family/family_tree.tscn", "family", null)
		await _frames(6)
		await _capture("family_consort")
		var family_scene: Variant = _world.get("_overlay")
		if family_scene is Node and family_scene.has_method("_on_consort_action"):
			family_scene.call("_on_consort_action")
			await _frames(3)
			await _capture("family_consort_action")
		var family_overlay: Variant = _world.get("_overlay")
		if family_overlay is Node and is_instance_valid(family_overlay):
			(family_overlay as Node).call("close_overlay")
		await _frames(3)

		# Ayuda / Manual desde el consejo.
		_world.call("_open_overlay", "res://scenes/ui/help_overlay.tscn", "help", null)
		await _frames(5)
		await _capture("manual_help")
		var help_overlay: Variant = _world.get("_overlay")
		if help_overlay is Node and is_instance_valid(help_overlay):
			(help_overlay as Node).call("close_overlay")
		await _frames(2)

	_finish()


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
	print("CAPTURAS FASE 4 TUTORIAL: %d en %s" % [_shots, OUT_DIR])
	TSBGame.reset_game()
	quit(0)
