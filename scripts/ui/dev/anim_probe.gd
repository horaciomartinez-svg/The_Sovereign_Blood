extends SceneTree
## Sonda de animación N3: inspecciona qué estado expone CloseCombat durante una ronda.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")


func _initialize() -> void:
	await process_frame
	TSBGame.start_new_game_in_scenario("scenario_1337", "england")
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	scene.call("setup", _unit("longbowman", "england", "a"), _unit("militia_spearman", "france", "d"), {}, {"region_id": "region_inglaterra_sur"})
	await frames(4)
	var cc: Node = scene.get("_cc")
	print("initial ", cc.call("get_animation_state", "demo_a"), " / ", cc.call("get_animation_state", "demo_d"))
	var state0: Dictionary = cc.call("get_state")
	print("hands=", state0.get("hands", {}))
	var card := "disparo"
	var hand: Array = (state0.get("hands", {}) as Dictionary).get("attacker", [])
	if not hand.is_empty():
		card = str(hand[0])
	print("play ", card, " -> ", cc.call("play_order", card))
	print("respond -> ", cc.call("enemy_respond"))
	for elapsed in [0, 20, 80, 120, 250, 500]:
		await frames(2)
		print("tick %d attack=%s def=%s proj=%s" % [elapsed,
			cc.call("get_animation_state", "demo_a"), cc.call("get_animation_state", "demo_d"),
			cc.call("get_projectiles")])
		cc.call("tick_animation", 20.0)
	await frames(3)
	scene.queue_free()
	TSBGame.reset_game()
	quit(0)


func _unit(unit_id: String, faction: String, suffix: String) -> Dictionary:
	return {"id": "demo_%s" % suffix, "faction": faction, "unit_id": unit_id, "size": 2400, "strength": 12, "morale": 1.0, "experience": 50, "commander_stat": 80}


func frames(count: int) -> void:
	for i in range(count):
		await process_frame
