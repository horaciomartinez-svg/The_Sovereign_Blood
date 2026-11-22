extends SceneTree
## Verificacion headless de Fase 3 §4 (AG-3): 6 hojas de sprites cargan, las 11
## restantes no tienen sprite_sheet (fallback), Sprite2D/flip_h en N2, campo N3
## con sprite/mirror y proyectiles activos tras un disparo.

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	_check(TSBGame.start_new_game("england", 1337), "partida iniciada")
	for i in range(3):
		await process_frame

	var sprite_units := 0
	var units_without_sprite := 0
	for unit_value: Variant in TSBGame.all_units():
		if not (unit_value is Dictionary):
			continue
		var unit_data := unit_value as Dictionary
		var unit_id := str(unit_data.get("id", ""))
		var sheet_value: Variant = unit_data.get("sprite_sheet", null)
		if not (sheet_value is Dictionary) or (sheet_value as Dictionary).is_empty():
			units_without_sprite += 1
			continue
		var sheet := sheet_value as Dictionary
		var frames: Variant = sheet.get("frames", [])
		if not (frames is Array) or (frames as Array).size() != 3:
			_check(false, "3 frames de %s" % unit_id)
			continue
		var frames_ok := true
		var expected_size := Vector2i(64, 64)
		var raw_size: Variant = sheet.get("size", [64, 64])
		if raw_size is Array and (raw_size as Array).size() >= 2:
			expected_size = Vector2i(int(float((raw_size as Array)[0])), int(float((raw_size as Array)[1])))
		for frame: Variant in (frames as Array):
			var path := str(frame)
			if not ResourceLoader.exists(path):
				frames_ok = false
				break
			var loaded: Variant = load(path)
			if not (loaded is Texture2D):
				frames_ok = false
				break
			var texture := loaded as Texture2D
			if texture.get_size() != Vector2(expected_size):
				frames_ok = false
				break
		_check(frames_ok, "3 texturas %d×%d cargan para %s" % [expected_size.x, expected_size.y, unit_id])
		if frames_ok:
			sprite_units += 1
	_check(sprite_units == 17, "17/17 unidades con sprite_sheet válido (hay %d)" % sprite_units)
	_check(units_without_sprite == 0, "0 unidades sin sprite en el dataset (hay %d)" % units_without_sprite)

	var world: Node = load("res://scenes/map/world_map.tscn").instantiate()
	root.add_child(world)
	for i in range(5):
		await process_frame
	var context := _find_sprite_context()
	if context.is_empty():
		_check(false, "contexto N2 con unidades con sprite")
	else:
		world.call("_open_tactical_battle", str(context.get("attacker", "")), str(context.get("defender", "")), str(context.get("region", "")))
		await _frames(3)
		var tactical: Variant = world.get("_overlay")
		if tactical != null:
			tactical.call("_begin_level2")
			await _frames(4)
			var tb: Variant = tactical.get("_tb")
			var canvas: Variant = tactical.get("_canvas")
			_check(tb != null and canvas != null, "N2 con TacticalBattle y lienzo")
			if tb != null and canvas != null:
				var units: Array = tb.call("get_units")
				var sprites: Variant = canvas.get("_unit_sprites")
				var expected := 0
				var mirror_ok := true
				for unit_value: Variant in units:
					if not (unit_value is Dictionary):
						continue
					var unit := unit_value as Dictionary
					var sheet: Variant = unit.get("sprite_sheet", null)
					var has_sheet := sheet is Dictionary and not (sheet as Dictionary).is_empty()
					var unit_id := str(unit.get("id", ""))
					if has_sheet:
						expected += 1
						if not (sprites is Dictionary) or not (sprites as Dictionary).has(unit_id):
							_check(false, "Sprite2D creado para %s" % unit_id)
							continue
						var sprite: Variant = (sprites as Dictionary)[unit_id]
						if not (sprite is Sprite2D) or (sprite as Sprite2D).texture == null:
							_check(false, "textura visible para %s" % unit_id)
						elif bool((sprite as Sprite2D).flip_h) != bool(unit.get("mirror", false)):
							mirror_ok = false
					elif sprites is Dictionary and (sprites as Dictionary).has(unit_id):
						_check(false, "unidad sin sprite no debe tener Sprite2D (%s)" % unit_id)
				_check(expected > 0, "N2 con al menos un sprite (%d)" % expected)
				_check(mirror_ok, "flip_h coincide con mirror en N2")
			tactical.call("_abandon")
			await _frames(2)
	world.queue_free()
	await _frames(2)

	# N3: bombarda (64×43 panorámica) + defensor sintético sin sprite → fallback
	# y proyectil de piedra.
	var close_scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(close_scene)
	close_scene.call("setup", _unit_dict("bombarda", "england", "bombarda"), _unit_dict("synthetic_peasant", "france", "fallback"))
	await _frames(5)
	var cc: Variant = close_scene.get("_cc")
	_check(cc != null, "N3 CloseCombat")
	if cc != null:
		var attacker_sprite: Variant = close_scene.get("_field_attacker")
		var defender_sprite: Variant = close_scene.get("_field_defender")
		var defender_fallback: Variant = close_scene.get("_field_defender_fallback")
		_check(attacker_sprite != null and (attacker_sprite as Sprite2D).texture != null and (attacker_sprite as Sprite2D).visible, "N3 sprite panorámico bombarda visible")
		if attacker_sprite is Sprite2D and (attacker_sprite as Sprite2D).texture != null:
			_check(int((attacker_sprite as Sprite2D).texture.get_height()) == 43, "N3 bombarda usa textura 64×43 sin deformar")
		_check(defender_fallback != null and (defender_fallback as CanvasItem).visible, "N3 fallback sintético visible")
		_check(defender_sprite != null and not (defender_sprite as Sprite2D).visible, "N3 sin Sprite2D para unidad sintética sin sprite")
		var fired := false
		for attempt in range(8):
			var state: Dictionary = cc.call("get_state")
			var hands: Variant = state.get("hands", {})
			var hand: Array = []
			if hands is Dictionary:
				var raw: Variant = (hands as Dictionary).get("attacker", [])
				if raw is Array:
					hand = raw as Array
			if hand.has("disparo"):
				close_scene.call("_play_card", "disparo")
				fired = true
				break
			if hand.is_empty():
				break
			close_scene.call("_play_card", str(hand[0]))
			await _frames(2)
		if fired:
			cc.call("tick_animation", 120.0)
			var projectile_types := _projectile_types(cc)
			print("  [info] N3 tipos de proyectil: ", projectile_types)
			_check(projectile_types.has("piedra"), "N3 proyectil de piedra activo tras disparo")
		else:
			_check(false, "N3 mano con disparo")
	close_scene.queue_free()
	await _frames(2)

	print("--------------------------------------------------------------")
	if _failures.is_empty():
		print("FASE 3 RENDER PROBE: OK")
		quit(0)
	else:
		print("FASE 3 RENDER PROBE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _unit_dict(unit_id: String, faction: String, suffix: String) -> Dictionary:
	return {
		"id": "probe_%s" % suffix, "faction": faction, "unit_id": unit_id,
		"size": 2400, "strength": 12, "morale": 1.0, "experience": 50, "commander_stat": 80,
	}


func _find_sprite_context() -> Dictionary:
	for army: Variant in TSBGame.armies().values():
		if not (army is Dictionary):
			continue
		var units: Variant = (army as Dictionary).get("units", [])
		var has_sprite := false
		if units is Array:
			for unit_value: Variant in (units as Array):
				if unit_value is Dictionary:
					var unit_id := str((unit_value as Dictionary).get("unit_id", ""))
					var sheet: Variant = TSBGame.unit(unit_id).get("sprite_sheet", null)
					if sheet is Dictionary and not (sheet as Dictionary).is_empty():
						has_sprite = true
						break
		if not has_sprite:
			continue
		var from_region := str((army as Dictionary).get("region_id", ""))
		var faction_id := str((army as Dictionary).get("faction_id", ""))
		for adjacent: Variant in TSBGame.region_adjacency(from_region):
			var target := str(adjacent)
			var defender := TSBGame.defender_army_in(target, faction_id)
			if not defender.is_empty():
				return {"attacker": str((army as Dictionary).get("id", "")), "defender": str(defender.get("id", "")), "region": target}
	return {}


func _projectile_types(cc: Node) -> Array[String]:
	var types: Array[String] = []
	var projectiles: Variant = cc.call("get_projectiles")
	if projectiles is Array:
		for projectile_value: Variant in (projectiles as Array):
			if projectile_value is Dictionary:
				var projectile_type := str((projectile_value as Dictionary).get("type", ""))
				if not projectile_type.is_empty() and not types.has(projectile_type):
					types.append(projectile_type)
	return types


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  [OK] " + label)
	else:
		_failures.append(label)
		print("  [FAIL] " + label)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
