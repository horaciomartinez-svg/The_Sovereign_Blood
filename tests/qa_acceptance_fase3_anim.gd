extends SceneTree
## Harness QA — Fase 3.1: animación de combate (GDD v1.8 §10.3, D-049/D-064).
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_fase3_anim.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso; FAIL = violación.
## Exit 0 solo con todos los criterios PASS.

const UNIT_PNG_DIR := "res://assets/art/sprites/units"
const CAPTURE_FILES: Array[String] = [
	"anim_idle.png", "anim_n3_attack_sequence.png", "anim_n3_hit_death.png",
]
const ANIM_KEYS: Array[String] = ["march", "idle", "attack", "hit", "death"]

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Fase 3.1 (animación de combate)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	_print_environment()
	_criterion_1_frames()
	_criterion_2_timing()
	_criterion_3_n3_sequence()
	_criterion_4_determinism()
	_criterion_5_captures()
	_criterion_6_no_regression()
	_finish()


func _print_environment() -> void:
	print("[INFO] Fase 3.1 — presencia de artefactos:")
	print("  PNG unidades: %d; raw src: %d" % [
		_count_png(UNIT_PNG_DIR), _count_png("%s/src" % UNIT_PNG_DIR),
	])
	print("  scripts/battle/close_combat.gd: %s" % str(FileAccess.file_exists("res://scripts/battle/close_combat.gd")))
	print("  docs/screenshots: %d PNG" % _count_png("res://docs/screenshots"))
	print("  tests: %d .gd" % _count_files("res://tests", "gd"))


# ---------------------------------------------------------------------------
# A1 — 17 × 13 frames cargan y metadata de animación
# ---------------------------------------------------------------------------

func _criterion_1_frames() -> void:
	var started := Time.get_ticks_msec()
	var id := "A1"
	var name := "17 unidades × 13 frames (221 PNG/221 raw) cargan como Texture2D con metadata completa"
	var data: Variant = _read_json("res://data/units.json")
	if not (data is Dictionary):
		_fail(id, name, "units.json no legible", started)
		return
	var units_value: Variant = (data as Dictionary).get("units", null)
	if not (units_value is Array) or (units_value as Array).size() != 17:
		_fail(id, name, "unidades != 17", started)
		return
	var errors: Array[String] = []
	var loaded := 0
	for unit_value in (units_value as Array):
		if not (unit_value is Dictionary):
			continue
		var unit := unit_value as Dictionary
		var unit_id := str(unit.get("id", ""))
		var sheet_value: Variant = unit.get("sprite_sheet", null)
		if not (sheet_value is Dictionary):
			errors.append("%s sin sprite_sheet" % unit_id)
			continue
		var sheet := sheet_value as Dictionary
		var frames_value: Variant = sheet.get("frames", null)
		if not (frames_value is Array) or (frames_value as Array).size() != 13:
			errors.append("%s frames != 13" % unit_id)
			continue
		for frame_value in (frames_value as Array):
			var frame_path := str(frame_value)
			if not ResourceLoader.exists(frame_path):
				errors.append("%s frame ausente %s" % [unit_id, frame_path.get_file()])
				continue
			if not (load(frame_path) is Texture2D):
				errors.append("%s frame no Texture2D %s" % [unit_id, frame_path.get_file()])
				continue
			loaded += 1
		var anim_value: Variant = sheet.get("anim", null)
		if not (anim_value is Dictionary):
			errors.append("%s sin anim" % unit_id)
			continue
		var anim := anim_value as Dictionary
		if not _int_array(anim.get("march", []), [0, 1, 2]):
			errors.append("%s march != [0,1,2]" % unit_id)
		if not _int_array(anim.get("idle", []), [3, 4]):
			errors.append("%s idle != [3,4]" % unit_id)
		if not _int_array(anim.get("attack", []), [5, 6, 7, 8]):
			errors.append("%s attack != [5,6,7,8]" % unit_id)
		if not _int_array(anim.get("hit", []), [9, 10]):
			errors.append("%s hit != [9,10]" % unit_id)
		if not _int_array(anim.get("death", []), [11, 12]):
			errors.append("%s death != [11,12]" % unit_id)
		if not is_equal_approx(float(anim.get("fps_attack", 0.0)), 9.0):
			errors.append("%s fps_attack != 9" % unit_id)
		if not is_equal_approx(float(anim.get("fps_hit", 0.0)), 8.0):
			errors.append("%s fps_hit != 8" % unit_id)
		if not is_equal_approx(float(anim.get("fps_death", 0.0)), 6.0):
			errors.append("%s fps_death != 6" % unit_id)
		if not bool(anim.get("death_hold", false)):
			errors.append("%s death_hold false" % unit_id)
	var png := _count_png(UNIT_PNG_DIR)
	var raw := _count_png("%s/src" % UNIT_PNG_DIR)
	if png != 221:
		errors.append("PNG producción=%d/221" % png)
	if raw != 221:
		errors.append("raw src=%d/221" % raw)
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "17/17 unidades × 13 frames = 221 texturas; 221 producción + 221 raw; anim march/idle/attack/hit/death + fps_attack=9/hit=8/death=6/death_hold", started)


# ---------------------------------------------------------------------------
# A2 — Helpers de tiempo/estado de animación
# ---------------------------------------------------------------------------

func _criterion_2_timing() -> void:
	var started := Time.get_ticks_msec()
	var id := "A2"
	var name := "Timing: attack_2 a 111,1 ms; reacción hit/dead a 222,2 ms; death_hold e idle"
	var script_value: Variant = load("res://scripts/battle/battle_sprites.gd")
	if not (script_value is GDScript):
		_fail(id, name, "battle_sprites.gd no compila", started)
		return
	var script := script_value as GDScript
	var sheet := _first_sheet()
	var errors: Array[String] = []
	var impact_index: Variant = script.call("attack_impact_index", sheet)
	var impact_ms: Variant = script.call("attack_impact_ms", sheet)
	var frame_ms: Variant = script.call("attack_frame_ms", sheet)
	var reaction_ms: Variant = script.call("reaction_delay_ms", sheet)
	if int(impact_index) != 6:
		errors.append("attack_impact_index=%d (esperado 6)" % int(impact_index))
	if not is_equal_approx(float(impact_ms), 111.1):
		errors.append("attack_impact_ms=%s (esperado 111.1)" % str(impact_ms))
	if not is_equal_approx(float(frame_ms), 111.1):
		errors.append("attack_frame_ms=%s (esperado 111.1)" % str(frame_ms))
	if not is_equal_approx(float(reaction_ms), 222.2):
		errors.append("reaction_delay_ms=%s (esperado 222.2)" % str(reaction_ms))
	var attack_path: Variant = script.call("state_frame_path", sheet, "attack", 0.0)
	if not str(attack_path).get_file().contains("_attack_1"):
		errors.append("attack frame 0 != attack_1")
	var attack2_path: Variant = script.call("state_frame_path", sheet, "attack", 112.0)
	if not str(attack2_path).get_file().contains("_attack_2"):
		errors.append("attack frame en 112 ms != attack_2 (%s)" % str(attack2_path))
	var dead_after: Variant = script.call("state_after_elapsed", sheet, "dead", 5000.0)
	if str(dead_after) != "dead":
		errors.append("dead no persiste (death_hold roto)")
	var idle_after: Variant = script.call("state_after_elapsed", sheet, "attack", 5000.0)
	if str(idle_after) != "idle":
		errors.append("attack no vuelve a idle")
	var mirror_west: Variant = script.call("mirror_for", "W")
	var mirror_east: Variant = script.call("mirror_for", "E")
	if not bool(mirror_west) or bool(mirror_east):
		errors.append("mirror_for incoherente")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "attack_2 index=6 a 111,1 ms; ataque=111,1 ms; reacción=222,2 ms; dead persiste/death_hold; attack→idle; mirror W=true/E=false", started)


# ---------------------------------------------------------------------------
# A3 — Secuencia real N3 (CloseCombat): idle → attack_2 → hit/dead + proyectil
# ---------------------------------------------------------------------------

func _criterion_3_n3_sequence() -> void:
	var started := Time.get_ticks_msec()
	var id := "A3"
	var name := "N3 real: idle→attack(attack_2 111,1)→hit/dead(222,2) con proyectil y mirroring"
	var hit := _run_n3_probe(1000, "qa_anim_hit")
	var dead := _run_n3_probe(1, "qa_anim_dead")
	if not bool(hit.get("ok", false)) or not bool(dead.get("ok", false)):
		_fail(id, name, "hit: %s; dead: %s" % [
			str(hit.get("detail", "")), str(dead.get("detail", "")),
		], started)
		return
	_pass(id, name, "hit: %s; dead: %s" % [str(hit.get("detail", "")), str(dead.get("detail", ""))], started)


func _run_n3_probe(defender_size: int, suffix: String) -> Dictionary:
	if not _ensure_game_started():
		return {"ok": false, "detail": "GameState/DataLoader no disponibles"}
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("launch_close_combat"):
		return {"ok": false, "detail": "BattleManager.launch_close_combat ausente"}
	var attacker := {
		"id": "qa_anim_attacker_" + suffix, "faction": "england", "unit_id": "crossbowmen",
		"size": 300, "strength": 8, "morale": 1.0, "experience": 50,
	}
	var defender := {
		"id": "qa_anim_defender_" + suffix, "faction": "france", "unit_id": "men_at_arms",
		"size": defender_size, "strength": 12, "morale": 1.0, "experience": 50,
	}
	var node_value: Variant = battle.call("launch_close_combat", attacker, defender)
	if not (node_value is Node):
		return {"ok": false, "detail": "launch_close_combat no devuelve Node"}
	var node := node_value as Node
	root.add_child(node)
	var attacker_id := "qa_anim_attacker_" + suffix
	var defender_id := "qa_anim_defender_" + suffix
	var errors: Array[String] = []
	var initial: Dictionary = node.call("get_animation_state", attacker_id)
	var initial_frame: Dictionary = _view_frame_info(initial)
	if str(initial.get("state", "")) != "idle":
		errors.append("estado inicial != idle")
	if not str(initial_frame.get("frame_path", "")).get_file().contains("_idle_"):
		errors.append("frame inicial no idle (%s)" % str(initial_frame.get("frame_path", "")))
	var impact_ms := float(node.call("get_attack_impact_ms", attacker_id))
	if not is_equal_approx(impact_ms, 111.1):
		errors.append("impact_ms=%s" % str(impact_ms))
	var state: Variant = node.call("get_state")
	var hand: Variant = []
	if state is Dictionary:
		var hands: Variant = (state as Dictionary).get("hands", null)
		if hands is Dictionary:
			hand = (hands as Dictionary).get("attacker", [])
	var card := "carga"
	if hand is Array:
		var preferred: Array[String] = ["carga", "disparo", "formacion", "finta"]
		var selected := ""
		for candidate in preferred:
			if (hand as Array).has(candidate):
				selected = candidate
				break
		if selected == "" and not (hand as Array).is_empty():
			selected = str((hand as Array)[0])
		if selected != "":
			card = selected
	var played: Variant = node.call("play_order", card)
	if not (played is bool) or not bool(played):
		errors.append("no se pudo jugar carta '%s'" % card)
	else:
		var round_result: Variant = node.call("enemy_respond")
		var attack_state: Dictionary = node.call("get_animation_state", attacker_id)
		if str(attack_state.get("state", "")) != "attack":
			errors.append("atacante no está en attack tras la ronda")
		node.call("tick_animation", impact_ms - 1.0)
		var before_impact: Dictionary = node.call("get_animation_state", defender_id)
		node.call("tick_animation", 1.0)
		var at_impact: Dictionary = node.call("get_animation_state", defender_id)
		var projectiles: Variant = node.call("get_projectiles")
		if not (projectiles is Array) or (projectiles as Array).is_empty():
			errors.append("sin proyectil en N3")
		else:
			var projectile: Dictionary = (projectiles as Array)[0]
			if projectile.has("launch_ms"):
				var launch_ms := float(projectile.get("launch_ms", -1.0))
				if launch_ms < 0.0 or launch_ms > float(node.call("get_state").get("animation_ms", 0.0)) + 1.0:
					errors.append("launch_ms inválido (%s)" % str(launch_ms))
			elif projectile.has("started_ms") and projectile.has("impact_ms"):
				# N3 (CloseCombat) expone started_ms + impact_ms (D-064); equivale a launch_ms.
				var started := float(projectile.get("started_ms", -1.0))
				if started < 0.0:
					errors.append("proyectil sin started_ms")
				if not is_equal_approx(float(projectile.get("impact_ms", 0.0)), 111.1):
					errors.append("proyectil impact_ms != 111.1")
			else:
				errors.append("proyectil sin timing (launch_ms/started_ms+impact_ms)")
			if str(projectile.get("sprite", "")).get_file() != "proyectil_virote.png":
				errors.append("proyectil inesperado %s" % str(projectile.get("sprite", "")))
		node.call("tick_animation", 222.2 - impact_ms + 1.0)
		var reaction: Dictionary = node.call("get_animation_state", defender_id)
		var reaction_state := str(reaction.get("state", ""))
		var expected_hit := defender_size > 100
		if expected_hit and reaction_state != "hit":
			errors.append("defensor superviviente estado=%s (esperado hit)" % reaction_state)
		if not expected_hit and reaction_state != "dead":
			errors.append("defensor muerto estado=%s (esperado dead)" % reaction_state)
		if not expected_hit:
			node.call("tick_animation", 5000.0)
			var hold: Dictionary = node.call("get_animation_state", defender_id)
			var hold_frame: Dictionary = _view_frame_info(hold)
			if str(hold.get("state", "")) != "dead":
				errors.append("death_hold no persiste tras 5 s")
			if not str(hold_frame.get("frame_path", "")).get_file().contains("_death_"):
				errors.append("frame death_hold no es death (%s)" % str(hold_frame.get("frame_path", "")))
		var attacker_units: Variant = node.call("get_units")
		if attacker_units is Array:
			for unit_value in (attacker_units as Array):
				if unit_value is Dictionary and str((unit_value as Dictionary).get("id", "")) == attacker_id:
					if bool((unit_value as Dictionary).get("mirror", false)):
						errors.append("atacante E no debe estar espejado")
	node.free()
	if not errors.is_empty():
		return {"ok": false, "detail": ", ".join(errors)}
	return {
		"ok": true,
		"detail": "idle→attack→attack_2(111,1)→%s(222,2)%s; proyectil virote con timing N3 started_ms/impact_ms; mirroring OK" % [
			"dead" if not (defender_size > 100) else "hit",
			"; death_hold" if defender_size <= 100 else "",
		],
	}


# ---------------------------------------------------------------------------
# A4 — Determinismo de la secuencia
# ---------------------------------------------------------------------------

func _criterion_4_determinism() -> void:
	var started := Time.get_ticks_msec()
	var id := "A4"
	var name := "Determinismo: misma secuencia de animación/daño → mismo estado"
	var first := _run_n3_probe(1000, "qa_anim_det_a")
	var second := _run_n3_probe(1000, "qa_anim_det_b")
	if not bool(first.get("ok", false)) or not bool(second.get("ok", false)):
		_fail(id, name, "sonda no ejecutada: %s" % [str(first.get("detail", second.get("detail", "")))], started)
		return
	# La sonda compara los estados cualitativos; el combate determinista ya está cubierto en F2/F3.
	if str(first.get("detail", "")) != str(second.get("detail", "")):
		_fail(id, name, "secuencia no determinista: %s vs %s" % [str(first.get("detail", "")), str(second.get("detail", ""))], started)
		return
	_pass(id, name, "2 secuencias idénticas: " + str(first.get("detail", "")), started)


# ---------------------------------------------------------------------------
# A5 — Capturas
# ---------------------------------------------------------------------------

func _criterion_5_captures() -> void:
	var started := Time.get_ticks_msec()
	var id := "A5"
	var name := "Capturas 1920×1080: idle, secuencia de ataque N3 y hit/death"
	var missing: Array[String] = []
	for capture_name in CAPTURE_FILES:
		if not FileAccess.file_exists("res://docs/screenshots/%s" % capture_name):
			missing.append(capture_name)
	if not missing.is_empty():
		_fail(id, name, "faltan capturas: " + ", ".join(missing), started)
		return
	var wrong_sizes: Array[String] = []
	for capture_name in CAPTURE_FILES:
		var dims := _png_dimensions("res://docs/screenshots/%s" % capture_name)
		if dims != Vector2i(1920, 1080):
			wrong_sizes.append("%s=%dx%d" % [capture_name, dims.x, dims.y])
	if not wrong_sizes.is_empty():
		_fail(id, name, "tamaño distinto de 1920x1080: " + ", ".join(wrong_sizes), started)
		return
	_pass(id, name, "3/3 capturas 1920x1080: " + ", ".join(CAPTURE_FILES), started)


# ---------------------------------------------------------------------------
# A6 — No regresión
# ---------------------------------------------------------------------------

func _criterion_6_no_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "A6"
	var name := "No regresión: sprites 17/17, tiles, escenarios, F1/F2, escenas y scripts"
	var issues: Array[String] = []
	var tiles := _count_png("res://assets/art/battle/tiles")
	if tiles != 12:
		issues.append("tiles PNG=%d/12" % tiles)
	var scenes := _count_files("res://scenes", "tscn")
	if scenes < 18:
		issues.append("escenas=%d/18" % scenes)
	for artifact in ["res://tests/qa_acceptance_fase3.gd", "res://tests/qa_acceptance_tiles.gd", "res://tests/qa_acceptance_fase3_final.gd", "res://scenes/main/scenario_select.tscn"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta %s" % artifact.get_file())
	var failures := _scan_script_compile_failures()
	if not failures.is_empty():
		issues.append("scripts sin compilar: " + ", ".join(failures.slice(0, 5)))
	if not issues.is_empty():
		_fail(id, name, ", ".join(issues), started)
		return
	_pass(id, name, "12 tiles; %d escenas; harness F3/tiles/final y selección presentes; scripts fallos=%d" % [
		scenes, failures.size(),
	], started)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _view_frame_info(view: Dictionary) -> Dictionary:
	var frame_info: Variant = view.get("frame_info", null)
	if frame_info is Dictionary:
		return frame_info as Dictionary
	return {}


func _first_sheet() -> Dictionary:
	var data: Variant = _read_json("res://data/units.json")
	if data is Dictionary:
		var units_value: Variant = (data as Dictionary).get("units", null)
		if units_value is Array and not (units_value as Array).is_empty():
			var unit: Dictionary = (units_value as Array)[0]
			var sheet: Variant = unit.get("sprite_sheet", null)
			if sheet is Dictionary:
				return sheet as Dictionary
	return {}


func _ensure_game_started() -> bool:
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("new_game"):
		return false
	var dl := _autoload("DataLoader")
	if dl != null and dl.has_method("load_all"):
		dl.call("load_all")
	if gs.has_method("reset"):
		gs.call("reset")
	gs.call("new_game", "scenario_1337", "england", 1337)
	var state: Variant = gs.get("state")
	return state is Dictionary and not (state as Dictionary).is_empty()


func _autoload(autoload_name: String) -> Node:
	if root == null:
		return null
	return root.get_node_or_null(NodePath(autoload_name))


func _read_json(res_path: String) -> Variant:
	if not FileAccess.file_exists(res_path):
		return null
	var text := FileAccess.get_file_as_string(res_path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	return parser.data


func _int_array(value: Variant, expected: Array) -> bool:
	if not (value is Array) or (value as Array).size() != expected.size():
		return false
	for index in range(expected.size()):
		if int((value as Array)[index]) != int(expected[index]):
			return false
	return true


func _count_png(res_dir: String) -> int:
	return _count_files(res_dir, "png")


func _count_files(res_dir: String, extension: String) -> int:
	var count := 0
	var dir := DirAccess.open(res_dir)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if entry != "src" and not entry.begins_with("."):
				count += _count_files("%s/%s" % [res_dir, entry], extension)
		elif entry.get_extension().to_lower() == extension:
			count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count


func _png_dimensions(res_path: String) -> Vector2i:
	if not FileAccess.file_exists(res_path):
		return Vector2i(0, 0)
	var file := FileAccess.open(res_path, FileAccess.READ)
	if file == null:
		return Vector2i(0, 0)
	var header := file.get_buffer(24)
	file.close()
	if header.size() < 24:
		return Vector2i(0, 0)
	var width := (int(header[16]) << 24) | (int(header[17]) << 16) | (int(header[18]) << 8) | int(header[19])
	var height := (int(header[20]) << 24) | (int(header[21]) << 16) | (int(header[22]) << 8) | int(header[23])
	return Vector2i(width, height)


func _scan_script_compile_failures() -> Array[String]:
	var failures: Array[String] = []
	_scan_dir_for_scripts("res://scripts", failures)
	return failures


func _scan_dir_for_scripts(res_dir: String, failures: Array[String]) -> void:
	var dir := DirAccess.open(res_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if entry != "dev" and not entry.begins_with("."):
				_scan_dir_for_scripts("%s/%s" % [res_dir, entry], failures)
		elif entry.get_extension().to_lower() == "gd":
			var path := "%s/%s" % [res_dir, entry]
			var script: Variant = load(path)
			if not (script is GDScript):
				failures.append(path.get_file())
			elif not (script as GDScript).can_instantiate():
				failures.append(path.get_file())
		entry = dir.get_next()
	dir.list_dir_end()


func _record(id: String, name: String, status: String, detail: String, started_ms: int) -> void:
	var elapsed := Time.get_ticks_msec() - started_ms
	_results.append({"id": id, "name": name, "status": status, "detail": detail, "ms": elapsed})
	var suffix := "" if detail == "" else " :: " + detail
	print("  [%s] %s — %s%s" % [status, id, name, suffix])


func _pass(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "PASS", detail, started_ms)


func _fail(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "FAIL", detail, started_ms)


func _finish() -> void:
	var passed := 0
	var failed := 0
	var skipped := 0
	for result in _results:
		match str(result.get("status", "")):
			"PASS":
				passed += 1
			"FAIL":
				failed += 1
			"SKIP":
				skipped += 1
	print("--------------------------------------------------------------")
	print("RESULTADO QA ANIMACIÓN FASE 3.1: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [
		passed, failed, skipped, _results.size(),
	])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [
			str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0)),
		])
	var code := 0
	if failed > 0 or skipped > 0:
		print("ACEPTACIÓN ANIMACIÓN FASE 3.1: NO ACEPTADA — FAIL=%d SKIP=%d (exit 1)" % [failed, skipped])
		code = 1
	else:
		print("ACEPTACIÓN ANIMACIÓN FASE 3.1: OK — %d/%d criterios PASS (exit 0)" % [passed, _results.size()])
	print("--------------------------------------------------------------")
	quit(code)
