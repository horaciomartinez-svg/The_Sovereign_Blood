extends SceneTree

const TSBGame = preload("res://scripts/ui/tsb_game.gd")


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	TSBGame.start_new_game_in_scenario("scenario_1337", "england", 1337, "beginner")
	for path in ["res://scenes/economy/market_screen.tscn", "res://scenes/family/family_tree.tscn", "res://scenes/diplomacy/diplomacy_screen.tscn"]:
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		await process_frame
		var key := str(scene.call("_context_help_key")) if scene.has_method("_context_help_key") else "?"
		var buttons: Array[String] = []
		for child: Node in scene.get_children():
			if child is Button:
				buttons.append((child as Button).text)
				print("[HELP]   button global=", (child as Button).get_global_rect())
		print("[HELP] ", path, " key=", key, " buttons=", buttons)
		scene.queue_free()
		await process_frame
	TSBGame.reset_game()
	quit(0)
