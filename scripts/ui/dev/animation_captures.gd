extends SceneTree
## Capturas Fase 3.2 — animación N3 (idle, ataque con attack_4/proyectil,
## impact + death_hold) sobre el campo de tiles real. Herramienta de desarrollo.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _captures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	TSBGame.start_new_game_in_scenario("scenario_1337", "england")
	await _frames(3)

	await _capture_idle()
	await _capture_attack()
	await _capture_impact_death()

	print("CAPTURAS ANIMACION: %d en %s" % [_captures, OUT_DIR])
	TSBGame.reset_game()
	quit(0)


func _new_scene(attacker_size: int = 2400, defender_size: int = 2400) -> Node:
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	scene.call("setup",
		_unit("longbowman", "england", "atk", attacker_size),
		_unit("militia_spearman", "france", "def", defender_size),
		{}, {"region_id": "region_inglaterra_sur"})
	return scene


func _capture_idle() -> void:
	var scene := _new_scene()
	await _frames(8)
	var cc: Node = scene.get("_cc")
	var state: Dictionary = cc.call("get_animation_state", "demo_atk")
	print("[IDLE] ", state)
	await _capture("anim_idle")
	scene.queue_free()
	await _frames(2)


func _capture_attack() -> void:
	# Ronda de retirada/finta: sin bajas → el motor deja a ambos en attack, con
	# el proyectil del arquero en vuelo. Se captura en attack_4.
	var captured := false
	for attempt in range(6):
		var scene := _new_scene()
		await _frames(4)
		var cc: Node = scene.get("_cc")
		var state: Dictionary = cc.call("get_state")
		var hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
		var card := "retirada" if hand.has("retirada") else ("finta" if hand.has("finta") else (str(hand[0]) if not hand.is_empty() else "carga"))
		scene.call("_play_card", card)
		# Avanza el reloj de render hasta attack_4 (frame 8, ≈333,3 ms); la
		# reacción todavía no se aplica (444,4 ms). La UI refresca el Sprite2D.
		cc.call("tick_animation", 340.0)
		await _frames(1)
		# Avanza la UI frame a frame y captura en attack_4 (índice 3 del estado
		# attack; frame absoluto 8, disparo/golpe a ≈333,3 ms).
		var captured_frame := false
		for step in range(8):
			var view: Dictionary = cc.call("get_animation_state", "demo_atk")
			var info: Dictionary = view.get("frame_info", {})
			if str(view.get("state", "")) == "attack" and int(info.get("frame_index", 0)) >= 3:
				print("[ATTACK] attempt=%d card=%s state=%s frame=%s proj=%d" % [attempt, card, view.get("state", ""), info.get("frame_path", ""), (cc.call("get_projectiles") as Array).size()])
				await _capture("anim_n3_attack_sequence")
				captured = true
				captured_frame = true
				break
			cc.call("tick_animation", 20.0)
			await _frames(1)
		if captured_frame:
			scene.queue_free()
			await _frames(2)
			break
		scene.queue_free()
		await _frames(2)
	if not captured:
		print("[WARN] no se pudo capturar attack_4")


func _capture_impact_death() -> void:
	var scene := _new_scene(500, 1200)
	await _frames(4)
	var cc: Node = scene.get("_cc")
	# Juega rondas hasta que uno de los duelistas muera; la reacción impact/dead
	# se aplica tras attack_4 y el cadáver queda en death_hold.
	for round_index in range(10):
		var state: Dictionary = cc.call("get_state")
		if bool(state.get("finished", false)):
			break
		var hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
		if hand.is_empty():
			break
		var card := "carga" if hand.has("carga") else str(hand[0])
		scene.call("_play_card", card)
		await _frames(3)
		var after: Dictionary = cc.call("get_state")
		print("[IMPACT/DEATH] round=%d card=%s attacker=%s defender=%s finished=%s" % [
			round_index, card, after.get("attacker", {}).get("anim_state", ""),
			after.get("defender", {}).get("anim_state", ""), after.get("finished", false)])
		if bool(after.get("finished", false)):
			break
	# Fuerza el reloj visual hasta la reacción programada (attack_4 → impact/dead
	# a 444,4 ms) y deja que la UI repinte el Sprite2D.
	cc.call("tick_animation", 500.0)
	await _frames(2)
	var final_state: Dictionary = cc.call("get_state")
	print("[IMPACT/DEATH] final attacker=%s defender=%s finished=%s" % [
		final_state.get("attacker", {}).get("anim_state", ""),
		final_state.get("defender", {}).get("anim_state", ""), final_state.get("finished", false)])
	# Impact + inicio de death (captura requerida).
	await _capture("anim_n3_impact_death")
	# Persistencia final del cadáver (death_hold) como evidencia adicional.
	cc.call("tick_animation", 500.0)
	await _frames(2)
	var held_state: Dictionary = cc.call("get_state")
	print("[IMPACT/DEATH] held attacker=%s defender=%s" % [
		held_state.get("attacker", {}).get("anim_state", ""),
		held_state.get("defender", {}).get("anim_state", "")])
	await _capture("anim_n3_death_hold")
	scene.queue_free()
	await _frames(2)


func _unit(unit_id: String, faction: String, suffix: String, size: int) -> Dictionary:
	return {
		"id": "demo_" + suffix, "faction": faction, "unit_id": unit_id,
		"size": size, "strength": 12, "morale": 1.0, "experience": 50, "commander_stat": 80,
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
