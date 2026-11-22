extends SceneTree
## Sonda de flujo Fase 5A: Terminar turno -> confirmación -> boletín -> fin de año.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _world: Node = null
var _gs: Node = null


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	if not TSBGame.start_new_game_in_scenario("scenario_1337", "england", 1337, "beginner"):
		print("[FAIL] partida")
		quit(1)
		return
	_gs = root.get_node("GameState")
	change_scene_to_file("res://scenes/map/world_map.tscn")
	await _frames(10)
	_world = current_scene
	await _end_turn_flow("Q1")
	_gs.state["quarter"] = 4
	_world.call("_refresh_all")
	await _end_turn_flow("Q4")
	TSBGame.reset_game()
	quit(0)


func _end_turn_flow(label: String) -> void:
	_world.call("_on_end_turn_requested")
	await _frames(2)
	print("[FLOW] ", label, " confirmacion kind=", _world.get("_overlay_kind"))
	var order: Variant = _world.get("_overlay")
	if order == null:
		print("[FAIL] sin confirmación")
		quit(1)
		return
	order.call("_on_confirm")
	await _frames(4)
	print("[FLOW] ", label, " tras confirmar kind=", _world.get("_overlay_kind"))
	var bulletin: Variant = _world.get("_overlay")
	if bulletin != null:
		bulletin.call("close_overlay")
	await _frames(4)
	print("[FLOW] ", label, " tras boletín kind=", _world.get("_overlay_kind"))
	var year_end: Variant = _world.get("_overlay")
	if year_end != null:
		year_end.call("close_overlay")
	await _frames(3)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
