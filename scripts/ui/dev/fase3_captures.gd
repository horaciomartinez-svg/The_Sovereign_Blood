extends SceneTree
## Capturas de la PRIORIDAD 1 de Fase 3 (AG-3): sprites 64 px, N2 y N3 con
## sprites/proyectiles. Herramienta de desarrollo; guarda en .ui_check_f3.
##
## Uso: godot --path <repo> --script scripts/ui/dev/fase3_captures.gd

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")

const SHOWCASE_UNITS := [
	["militia_spearman", "sprites_64_milicia", "MILICIA · lanza"],
	["crossbowmen", "sprites_64_ballesteros", "BALLESTEROS · ballesta"],
	["longbowman", "sprites_64_arqueros", "ARQUEROS · arco largo"],
]
const RANGED_UNITS := ["longbowman", "crossbowmen", "bombarda"]

var _captures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	for entry: Array in SHOWCASE_UNITS:
		await _capture_unit_64(str(entry[0]), str(entry[1]), str(entry[2]))

	var world: Node = load("res://scenes/map/world_map.tscn").instantiate()
	root.add_child(world)
	for i in range(5):
		await process_frame
	var started: bool = TSBGame.start_new_game("england", 1337)
	if not started:
		print("[WARN] no se pudo iniciar partida")
	for i in range(3):
		await process_frame
	await _capture_n2(world)
	world.queue_free()
	await _frames(3)
	await _capture_n3()

	print("CAPTURAS FASE 3: %d en %s" % [_captures, OUT_DIR])
	quit(0)


func _capture_unit_64(unit_id: String, file_name: String, title_text: String) -> void:
	var unit_data: Dictionary = TSBGame.unit(unit_id)
	var frames: Array = []
	var sheet: Variant = unit_data.get("sprite_sheet", null)
	if sheet is Dictionary:
		var raw_frames: Variant = (sheet as Dictionary).get("frames", [])
		if raw_frames is Array:
			frames = raw_frames as Array
	var path := str(frames[0]) if not frames.is_empty() else ""
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			texture = loaded as Texture2D
	if texture == null:
		print("[WARN] sin textura para ", unit_id, " path=", path)
		return

	var layer := CanvasLayer.new()
	layer.layer = 70
	root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color("18212c")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.theme = ThemeBuilder.get_theme()
	panel.custom_minimum_size = Vector2(1180, 760)
	center.add_child(panel)
	var margin := UIKit.margin(panel, 30, 24, 30, 24)
	var column := UIKit.vbox(margin, 12)
	var heading := UIKit.label(column, "SPRITES 64 PX · %s" % title_text, "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Palette.INK_TEXT)
	var subtitle := UIKit.label(column, "Tamaño real de producción, sin escala (64×64 px). El arma debe reconocerse en silueta a 64 px; a la derecha, detalle 8× para revisión de silueta.", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Palette.CRIMSON)
	var row := UIKit.hbox(column, 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var real_box := UIKit.vbox(row, 6)
	real_box.custom_minimum_size = Vector2(220, 0)
	var real_rect := TextureRect.new()
	real_rect.texture = texture
	real_rect.custom_minimum_size = Vector2(64, 64)
	real_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	real_rect.stretch_mode = TextureRect.STRETCH_KEEP
	real_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	real_box.add_child(real_rect)
	var real_label := UIKit.label(real_box, "64 × 64 px (tamaño real)", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	real_label.add_theme_font_size_override("font_size", 14)
	real_label.add_theme_color_override("font_color", Palette.INK_TEXT)
	var inset_box := UIKit.vbox(row, 6)
	inset_box.custom_minimum_size = Vector2(520, 0)
	var inset_rect := TextureRect.new()
	inset_rect.texture = texture
	inset_rect.custom_minimum_size = Vector2(512, 512)
	inset_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inset_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inset_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inset_box.add_child(inset_rect)
	var inset_label := UIKit.label(inset_box, "Detalle 8× NEAREST · silueta/arma", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	inset_label.add_theme_font_size_override("font_size", 13)
	inset_label.add_theme_color_override("font_color", Palette.MUTED)
	var footer := UIKit.label(column, "Assets: Kimi (encargo del proyecto) · data/units.json sprite_sheet · RGBA, ancla pies-centro, facing E.", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Palette.MUTED)
	await _frames(4)
	await _capture(file_name)
	layer.queue_free()
	await _frames(2)


func _capture_n2(world: Node) -> void:
	var context := _find_ranged_context()
	if context.is_empty():
		context = _find_any_context()
	if context.is_empty():
		print("[WARN] N2 sin contexto de batalla")
		return
	world.call("_open_tactical_battle", str(context.get("attacker", "")), str(context.get("defender", "")), str(context.get("region", "")))
	await _frames(4)
	var tactical: Variant = world.get("_overlay")
	if tactical == null:
		print("[WARN] N2 sin overlay")
		return
	tactical.call("_begin_level2")
	await _frames(6)
	var tb: Variant = tactical.get("_tb")
	if tb == null:
		print("[WARN] N2 sin TacticalBattle")
		tactical.call("_abandon")
		return
	var units: Array = tb.call("get_units")
	print("[F3] N2 unidades: ", _unit_names(units))
	# Si hay una unidad a distancia, moverla a rango y atacar para que salga
	# un proyectil en la captura; si no, la captura muestra los sprites en formación.
	var ranged := _find_ranged_unit(units)
	var enemy := _find_enemy_unit(units)
	if not ranged.is_empty() and not enemy.is_empty():
		var ranged_id := str(ranged.get("id", ""))
		var enemy_q := int(enemy.get("q", 0))
		var enemy_r := int(enemy.get("r", 0))
		for step in range(6):
			var current: Dictionary = tb.call("get_unit", ranged_id)
			var distance := _hex_distance(int(current.get("q", 0)), int(current.get("r", 0)), enemy_q, enemy_r)
			if distance <= 2:
				break
			var range_hexes: Array = tb.call("get_reachable_hexes", ranged_id)
			var best := Vector2i(-999, -999)
			var best_distance := distance
			for cell: Variant in range_hexes:
				if not (cell is Dictionary):
					continue
				var q := int((cell as Dictionary).get("q", 0))
				var r := int((cell as Dictionary).get("r", 0))
				if _hex_distance(int(current.get("q", 0)), int(current.get("r", 0)), q, r) != 1:
					continue
				var candidate_distance := _hex_distance(q, r, enemy_q, enemy_r)
				if candidate_distance < best_distance:
					best_distance = candidate_distance
					best = Vector2i(q, r)
			if best.x == -999:
				break
			var moved: bool = tb.call("move_unit", ranged_id, best.x, best.y)
			print("[F3] N2 movimiento a distancia -> q%d,r%d (dist=%d): %s" % [best.x, best.y, best_distance, str(moved)])
			await _frames(2)
		var attack_result: Variant = tb.call("attack_unit", ranged_id, str(enemy.get("id", "")))
		print("[F3] N2 ataque a distancia: ", attack_result)
		tactical.call("_sync_n2")
		await create_timer(0.10).timeout
		await _frames(4)
		print("[F3] N2 proyectiles activos: ", (tb.call("get_projectiles") as Array).size())
	await _capture("sprites_n2")
	tactical.call("_abandon")
	await _frames(3)


func _capture_n3() -> void:
	var scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
	root.add_child(scene)
	var attacker_unit: Dictionary = {
		"id": "demo_longbowman", "faction": "england", "unit_id": "longbowman",
		"size": 2400, "strength": 12, "morale": 1.0, "experience": 60, "commander_stat": 85,
	}
	var defender_unit: Dictionary = {
		"id": "demo_spearman", "faction": "france", "unit_id": "militia_spearman",
		"size": 2400, "strength": 10, "morale": 1.0, "experience": 50, "commander_stat": 75,
	}
	scene.call("setup", attacker_unit, defender_unit)
	await _frames(5)
	var cc: Variant = scene.get("_cc")
	if cc == null:
		print("[WARN] N3 sin CloseCombat")
		scene.queue_free()
		return
	var fired := false
	for attempt in range(8):
		var state: Dictionary = cc.call("get_state")
		var hands: Variant = state.get("hands", {})
		var hand: Array = []
		if hands is Dictionary:
			var raw_hand: Variant = (hands as Dictionary).get("attacker", [])
			if raw_hand is Array:
				hand = raw_hand as Array
		if hand.has("disparo"):
			scene.call("_play_card", "disparo")
			fired = true
			break
		if hand.is_empty():
			break
		scene.call("_play_card", str(hand[0]))
		await _frames(2)
		if bool(cc.call("is_finished")):
			break
	if fired:
		await create_timer(0.14).timeout
		await _frames(4)
		print("[F3] N3 proyectiles activos: ", (cc.call("get_projectiles") as Array).size())
	await _frames(2)
	await _capture("sprites_n3")
	scene.queue_free()
	await _frames(2)


func _find_ranged_context() -> Dictionary:
	# Cualquier facción con unidad de proyectil y un enemigo adyacente sirve para
	# la captura N2 (la escena admite atacante IA en este modo de demostración).
	for army: Variant in TSBGame.armies().values():
		if not (army is Dictionary):
			continue
		var units: Variant = (army as Dictionary).get("units", [])
		var has_ranged := false
		if units is Array:
			for unit_value: Variant in (units as Array):
				if unit_value is Dictionary and RANGED_UNITS.has(str((unit_value as Dictionary).get("unit_id", ""))):
					has_ranged = true
					break
		if not has_ranged:
			continue
		var context := _context_for_army(army as Dictionary)
		if not context.is_empty():
			return context
	return {}


func _find_any_context() -> Dictionary:
	for army: Variant in TSBGame.armies().values():
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) == TSBGame.player_faction():
			var context := _context_for_army(army as Dictionary)
			if not context.is_empty():
				return context
	return {}


func _context_for_army(army: Dictionary) -> Dictionary:
	var from_region := str(army.get("region_id", ""))
	var faction_id := str(army.get("faction_id", ""))
	for adjacent: Variant in TSBGame.region_adjacency(from_region):
		var target := str(adjacent)
		var defender := TSBGame.defender_army_in(target, faction_id)
		if not defender.is_empty():
			return {"attacker": str(army.get("id", "")), "defender": str(defender.get("id", "")), "region": target}
	return {}


func _find_ranged_unit(units: Array) -> Dictionary:
	for unit: Variant in units:
		if unit is Dictionary and RANGED_UNITS.has(str((unit as Dictionary).get("unit_id", ""))):
			return unit as Dictionary
	return {}


func _find_enemy_unit(units: Array) -> Dictionary:
	for unit: Variant in units:
		if unit is Dictionary and str((unit as Dictionary).get("side", "")) == "defender":
			return unit as Dictionary
	for unit: Variant in units:
		if unit is Dictionary and str((unit as Dictionary).get("side", "")) == "attacker":
			return unit as Dictionary
	return {}


func _unit_names(units: Array) -> String:
	var names: Array[String] = []
	for unit: Variant in units:
		if unit is Dictionary:
			names.append("%s(%s)" % [str((unit as Dictionary).get("unit_id", "?")), str((unit as Dictionary).get("id", ""))])
	return ", ".join(names)


func _hex_distance(q1: int, r1: int, q2: int, r2: int) -> int:
	return int((absi(q1 - q2) + absi(q1 + r1 - q2 - r2) + absi(r1 - r2)) / 2)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("  [WARN] sin imagen ", file_name)
		return
	image.save_png(OUT_DIR.path_join(file_name + ".png"))
	_captures += 1
	print("  [OK] ", file_name, " ", image.get_size())
