extends SceneTree
## Capturas Fase 3.1 — animación N3 (idle, ataque con attack_2/proyectil,
## hit + death_hold) sobre el campo de tiles real. Herramienta de desarrollo.

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
	await _capture_hit_death()

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
	# el proyectil del arquero en vuelo. Se captura en attack_2.
	var captured := false
	for attempt in range(6):
		var scene := _new_scene()
		await _frames(4)
		var cc: Node = scene.get("_cc")
		var state: Dictionary = cc.call("get_state")
		var hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
		var card := "retirada" if hand.has("retirada") else ("finta" if hand.has("finta") else (str(hand[0]) if not hand.is_empty() else "carga"))
		scene.call("_play_card", card)
		await _frames(2)
		# Avanza la UI frame a frame y captura en attack_2 (índice 1 del estado
		# attack) antes de que el motor aplique la reacción hit/dead.
		var captured_frame := false
		for step in range(24):
			var view: Dictionary = cc.call("get_animation_state", "demo_atk")
			var info: Dictionary = view.get("frame_info", {})
			if str(view.get("state", "")) == "attack" and int(info.get("frame_index", 0)) >= 1:
				print("[ATTACK] attempt=%d card=%s state=%s frame=%s proj=%d" % [attempt, card, view.get("state", ""), info.get("frame_path", ""), (cc.call("get_projectiles") as Array).size()])
				await _capture("anim_n3_attack_sequence")
				captured = true
				captured_frame = true
				break
			await _frames(1)
		if captured_frame:
			scene.queue_free()
			await _frames(2)
			break
		scene.queue_free()
		await _frames(2)
	if not captured:
		print("[WARN] no se pudo capturar attack_2")


func _capture_hit_death() -> void:
	var scene := _new_scene(500, 1200)
	await _frames(4)
	var cc: Node = scene.get("_cc")
	# Juega rondas hasta que uno de los duelistas muera; la reacción hit/death
	# se aplica tras el impacto y el cadáver queda en death_hold.
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
		print("[HIT/DEATH] round=%d card=%s attacker=%s defender=%s finished=%s" % [
			round_index, card, after.get("attacker", {}).get("anim_state", ""),
			after.get("defender", {}).get("anim_state", ""), after.get("finished", false)])
		if bool(after.get("finished", false)):
			break
	# Espera a que la reacción programada (attack_2 → hit/dead) se aplique.
	for wait_step in range(20):
		var current: Dictionary = cc.call("get_state")
		if str(current.get("attacker", {}).get("anim_state", "")) != "attack" \
				or str(current.get("defender", {}).get("anim_state", "")) != "attack":
			break
		await _frames(1)
	await _frames(2)
	var final_state: Dictionary = cc.call("get_state")
	print("[HIT/DEATH] final attacker=%s defender=%s finished=%s" % [
		final_state.get("attacker", {}).get("anim_state", ""),
		final_state.get("defender", {}).get("anim_state", ""), final_state.get("finished", false)])
	# Captura de la reacción hit/dead inmediata (attack_2 ya pasó)…
	var immediate: Dictionary = cc.call("get_state")
	var any_hit := str(immediate.get("attacker", {}).get("anim_state", "")) == "hit" \
		or str(immediate.get("defender", {}).get("anim_state", "")) == "hit"
	if any_hit:
		await _capture("anim_n3_hit")
	# …y del cadáver en death_hold (último cuadro persistente).
	for wait_step in range(24):
		var held: Dictionary = cc.call("get_state")
		if str(held.get("defender", {}).get("anim_state", "")) == "dead" or str(held.get("attacker", {}).get("anim_state", "")) == "dead":
			break
		await _frames(1)
	await _frames(24)
	var held_state: Dictionary = cc.call("get_state")
	print("[HIT/DEATH] held attacker=%s defender=%s" % [
		held_state.get("attacker", {}).get("anim_state", ""),
		held_state.get("defender", {}).get("anim_state", "")])
	await _capture("anim_n3_hit_death")
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
