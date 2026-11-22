extends SceneTree
## Capturas de tiles N3 (GDD v1.7 §10.4): campo río+puente+villa y llanura.
## Herramienta de desarrollo; guarda en C:\Proyectos\TSB\.ui_check_f3.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _captures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	TSBGame.start_new_game("england", 1337)
	for i in range(4):
		await process_frame

	await _capture_case("region_flandes", "tiles_n3_rio_puente_villa")
	await _capture_case("region_normandia", "tiles_n3_llanura")
	print("CAPTURAS TILES: %d en %s" % [_captures, OUT_DIR])
	quit(0)


func _capture_case(region_id: String, file_name: String) -> void:
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	scene.call("setup", _unit_dict("longbowman", "england", "atk"), _unit_dict("militia_spearman", "france", "def"), {}, {"region_id": region_id})
	await _frames(6)
	var field_data: Variant = scene.get("_field_data")
	if field_data is Dictionary:
		var data := field_data as Dictionary
		print("[TILES] %s terrain=%s axis=%s tiles=%s bridges=%s villa=%s spawn=%s/%s" % [
			region_id, str(data.get("terrain", "")), str(data.get("axis", "")),
			str(data.get("tiles", [])), str(data.get("bridges", [])), str(data.get("villa", "")),
			str(data.get("attacker_spawn", "")), str(data.get("defender_spawn", "")),
		])
	await _frames(3)
	await _capture(file_name)
	scene.queue_free()
	await _frames(3)


func _unit_dict(unit_id: String, faction: String, suffix: String) -> Dictionary:
	return {
		"id": "demo_%s" % suffix, "faction": faction, "unit_id": unit_id,
		"size": 2400, "strength": 12, "morale": 1.0, "experience": 50, "commander_stat": 80,
	}


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
