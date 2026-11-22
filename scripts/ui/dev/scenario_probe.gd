extends SceneTree
## Verificación headless Fase 3 escenarios/UI (AG-3): datos 1402/1453, era,
## playable_factions y motivo de fin de partida en la pantalla de victoria.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	for scenario_id: String in ["scenario_1402", "scenario_1453"]:
		var playable := TSBGame.playable_factions(scenario_id)
		_check(TSBGame.scenario_available(scenario_id), "%s disponible" % scenario_id)
		_check(playable.size() == 8, "%s con 8 playable_factions (%d)" % [scenario_id, playable.size()])
		var start_year := TSBGame.scenario_start_year(scenario_id)
		_check(start_year == (1402 if scenario_id == "scenario_1402" else 1453), "%s start_year" % scenario_id)
		_check(not playable.is_empty(), "%s tiene facciones" % scenario_id)
		if playable.is_empty():
			continue
		var started := TSBGame.start_new_game_in_scenario(scenario_id, str(playable[0]))
		_check(started, "%s arranca" % scenario_id)
		_check(TSBGame.current_year() == start_year, "%s vista en su año (%d)" % [scenario_id, TSBGame.current_year()])
		_check(TSBGame.start_year() == start_year, "%s start_year en estado" % scenario_id)
		_check(TSBGame.current_era() == "III", "%s era III" % scenario_id)
		_check(TSBGame.scenario_id() == scenario_id, "%s scenario_id en estado" % scenario_id)

	# Pantalla de fin de partida: motivo legible (no solo el texto crudo).
	var screen: Node = load("res://scenes/ui/victory_screen.tscn").instantiate()
	root.add_child(screen)
	screen.call("setup", {"faction_id": "ottoman", "victory": true, "reason": "Conquista: controlas ≥70% de las regiones"})
	await _frames(3)
	var labels := screen.find_children("*", "Label", true, false)
	var text := ""
	for label: Node in labels:
		text += str(label.get("text")) + "\n"
	_check(text.contains("Motivo: Conquista territorial"), "victoria muestra motivo conquista")
	screen.queue_free()
	await _frames(2)

	TSBGame.reset_game()
	print("--------------------------------------------------------------")
	if _failures.is_empty():
		print("ESCENARIOS UI PROBE: OK")
		quit(0)
	else:
		print("ESCENARIOS UI PROBE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  [OK] " + label)
	else:
		_failures.append(label)
		print("  [FAIL] " + label)
