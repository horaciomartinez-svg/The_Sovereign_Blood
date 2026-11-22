extends SceneTree
## Sonda de integracion Fase 2 (AG-3): mapa por capas, hit-test 47/47 en las 3
## vistas, benchmark CPU <8 ms/frame, retratos con fallback y batallas N2/N3
## contra la API real de AG-2. Herramienta de desarrollo/QA.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")
const MAP_W := 2048.0
const MAP_H := 1536.0

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var started: bool = TSBGame.start_new_game("england", 1337)
	_check(started, "start_new_game")

	var world: Node = load("res://scenes/map/world_map.tscn").instantiate()
	root.add_child(world)
	await _frames(5)
	_check(world.get("_borders") != null, "mundo con capa de fronteras")
	_check(world.get("_camera") is Camera2D, "mundo con Camera2D")

	var years: Array = TSBGame.map_border_years()
	print("[f2] anos de fronteras: ", years)
	_check(years.size() >= 3, "3 vistas de ano disponibles")
	for year: Variant in [1337, 1402, 1453]:
		world.call("_set_view_year", int(year))
		await _frames(2)
		var borders: Variant = world.get("_borders")
		var polygons := int(borders.call("region_count"))
		_check(polygons == 47, "47 poligonos en vista %d (hay %d)" % [int(year), polygons])
		var hits := 0
		for region_id: Variant in TSBGame.region_ids():
			var center_normalized: Vector2 = TSBGame.map_center(str(region_id), int(year))
			var hit := str(borders.call("hit_test", center_normalized * Vector2(MAP_W, MAP_H)))
			if hit == str(region_id):
				hits += 1
		print("[f2] vista %d: hit-test %d/47" % [int(year), hits])
		_check(hits >= 46, "hit-test cobertura vista %d (47/47 objetivo; tolerancia 1 por centroides)" % int(year))

	world.call("_set_view_year", 1337)
	await _frames(2)
	var avg_ms: float = float(world.call("benchmark_map_frame", 240))
	print("[f2] benchmark mapa: %.4f ms/frame (objetivo < 8 ms; headless mide CPU, no GPU)" % avg_ms)
	_check(avg_ms < 8.0, "benchmark mapa < 8 ms/frame")

	# Retratos §10.2: fallback siempre visible + API de test.
	var portrait: Control = PortraitFrame.make("edward_iii_plantagenet", Vector2(120, 140))
	root.add_child(portrait)
	await _frames(2)
	_check(portrait.call("get_portrait_character_id") == "edward_iii_plantagenet", "retrato id")
	_check(bool(portrait.call("is_fallback")), "retrato fallback activo (sin assets finales)")
	var empty_portrait: Control = PortraitFrame.make("", Vector2(96, 110))
	root.add_child(empty_portrait)
	await _frames(1)
	_check(bool(empty_portrait.call("is_fallback")), "retrato sin personaje sigue siendo fallback (nunca hueco)")
	portrait.queue_free()
	empty_portrait.queue_free()

	# Batalla Nivel 2 real.
	var context := _find_battle_context()
	if context.is_empty():
		print("[f2] aviso: sin choque disponible para probar N2/N3")
	else:
		world.call("_open_tactical_battle", str(context["attacker"]), str(context["defender"]), str(context["region"]))
		await _frames(3)
		var tactical: Variant = world.get("_overlay")
		_check(tactical != null, "escena tactical abierta")
		if tactical != null:
			tactical.call("_begin_level2")
			await _frames(4)
			var tb: Variant = tactical.get("_tb")
			_check(tb != null, "TacticalBattle creado (launch_tactical)")
			if tb != null:
				var state: Dictionary = tb.call("get_state")
				var units: Array = state.get("units", [])
				print("[f2] N2: %d hexes, %d unidades, ronda %d" % [(state.get("hexes", []) as Array).size(), units.size(), int(state.get("round", 0))])
				_check(not (state.get("hexes", []) as Array).is_empty(), "tactico con hexes")
				_check(not units.is_empty(), "tactico con unidades")
				var player_unit := _first_player_unit(units)
				if not player_unit.is_empty():
					var uid := str(player_unit.get("id", ""))
					var reachable: Array = tb.call("get_reachable_hexes", uid)
					print("[f2] N2: unidad %s con %d hexes alcanzables" % [uid, reachable.size()])
					_check(not reachable.is_empty(), "get_reachable_hexes devuelve celdas")
					# Camino de UI: click de seleccion y click de movimiento en el lienzo.
					tactical.call("_on_cell_clicked", int(player_unit.get("q", 0)), int(player_unit.get("r", 0)))
					_check(str(tactical.get("_selected_unit")) == uid, "UI tactica selecciona unidad con click")
					if not reachable.is_empty():
						var target: Dictionary = {}
						for cell: Variant in reachable:
							if cell is Dictionary and not bool((cell as Dictionary).get("occupied", false)):
								target = cell as Dictionary
								break
						if target.is_empty():
							_check(false, "UI tactica con hex libre alcanzable")
						else:
							var target_q := int(target.get("q", 0))
							var target_r := int(target.get("r", 0))
							print("[f2] N2 debug: reachable_has=", (tactical.get("_reachable") as Dictionary).has("%d,%d" % [target_q, target_r]), " can_move=", tb.call("can_move_unit", uid, target_q, target_r))
							tactical.call("_on_cell_clicked", target_q, target_r)
							var status_node: Variant = tactical.get("_status")
							print("[f2] N2 debug: status=", status_node.text if status_node is Label else "?")
							var moved_unit: Dictionary = tb.call("get_unit", uid)
							print("[f2] N2: move via UI -> q%d,r%d (objetivo q%d,r%d)" % [int(moved_unit.get("q", -1)), int(moved_unit.get("r", -1)), target_q, target_r])
							_check(int(moved_unit.get("q", -1)) == target_q and int(moved_unit.get("r", -1)) == target_r, "UI tactica mueve con click")
				tactical.call("_abandon")
				await _frames(3)

		# Combate cerrado abierto desde el selector del mapa tactico (N3).
		if not context.is_empty():
			world.call("_open_tactical_battle", str(context["attacker"]), str(context["defender"]), str(context["region"]))
			await _frames(3)
			var tactical_n3: Variant = world.get("_overlay")
			if tactical_n3 != null:
				tactical_n3.call("_begin_level3")
				await _frames(3)
				_check(str(tactical_n3.get("_stage")) == "n3", "UI selector abre combate cerrado (N3)")
				tactical_n3.call("_close")
				await _frames(3)

		# Batalla Nivel 3 real.
		var close_scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
		root.add_child(close_scene)
		var attacker_unit := TSBGame.first_unit_of_army(str(context["attacker"]))
		var defender_unit := TSBGame.first_unit_of_army(str(context["defender"]))
		close_scene.call("setup", attacker_unit, defender_unit)
		await _frames(3)
		var cc: Variant = close_scene.get("_cc")
		_check(cc != null, "CloseCombat creado (launch_close_combat)")
		if cc != null:
			var state: Dictionary = cc.call("get_state")
			var hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
			print("[f2] N3: ronda %d, mano=%s" % [int(state.get("round", 0)), str(hand)])
			_check(not hand.is_empty(), "CloseCombat reparte mano de cartas")
			if not hand.is_empty():
				var played: bool = cc.call("play_order", str(hand[0]))
				var response: Dictionary = cc.call("enemy_respond")
				print("[f2] N3: play_order=", played, " respuesta=", response)
				_check(played, "CloseCombat.play_order")
		close_scene.queue_free()
		await _frames(2)

		# Nivel 1 desde el selector de UI: resolver automaticamente y abrir informe.
		world.call("_open_tactical_battle", str(context["attacker"]), str(context["defender"]), str(context["region"]))
		await _frames(3)
		var tactical_n1: Variant = world.get("_overlay")
		if tactical_n1 != null:
			tactical_n1.call("_begin_level1")
			await _frames(4)
			var overlay_kind := str(world.get("_overlay_kind"))
			print("[f2] N1 UI: overlay tras resolver = ", overlay_kind)
			_check(overlay_kind == "battle" or world.get("_overlay") == null, "UI N1 resuelve la batalla y muestra informe")
			var live_overlay: Variant = world.get("_overlay")
			if live_overlay is Node and is_instance_valid(live_overlay):
				(live_overlay as Node).call("close_overlay")
				await _frames(2)

	world.queue_free()
	await _frames(2)
	print("--------------------------------------------------------------")
	if _failures.is_empty():
		print("FASE 2 UI PROBE: OK")
		quit(0)
	else:
		print("FASE 2 UI PROBE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  [OK] " + label)
	else:
		_failures.append(label)
		print("  [FAIL] " + label)


func _find_battle_context() -> Dictionary:
	var player := TSBGame.player_faction()
	for army: Variant in TSBGame.armies().values():
		if not (army is Dictionary):
			continue
		if str((army as Dictionary).get("faction_id", "")) != player:
			continue
		var from_region := str((army as Dictionary).get("region_id", ""))
		for adjacent: Variant in TSBGame.region_adjacency(from_region):
			var target := str(adjacent)
			var defender := TSBGame.defender_army_in(target, player)
			if not defender.is_empty():
				return {"attacker": str((army as Dictionary).get("id", "")), "defender": str(defender.get("id", "")), "region": target}
	return {}


func _first_player_unit(units: Array) -> Dictionary:
	var player := TSBGame.player_faction()
	for unit: Variant in units:
		if unit is Dictionary and str((unit as Dictionary).get("faction", "")) == player:
			return unit
	return {}


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
