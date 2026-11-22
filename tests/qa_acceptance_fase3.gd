extends SceneTree
## Harness QA — Fase 3 PRIORIDAD 1: sprites de unidades núcleo (GDD v1.6 §10.3 / contrato F3 §5).
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_fase3.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso (baseline, no es
## rechazo); FAIL = módulo presente pero viola el contrato. Exit 0 solo con 6/6 PASS.

const SCENARIO_ID := "scenario_1337"
const PLAYER_FACTION := "england"
const SEED := 1337

const CORE_UNITS: Array[String] = [
	"militia_spearman", "swiss_pikeman", "crossbowmen", "longbowman", "men_at_arms", "light_horseman",
]
const UNIT_PNG_DIR := "res://assets/art/sprites/units"
const PROJECTILE_DIR := "res://assets/art/sprites/projectiles"
const PROJECTILE_FILES: Array[String] = [
	"proyectil_virote.png", "proyectil_flecha.png", "proyectil_piedra.png",
]
const EXPECTED_UNIT_COUNT := 17
const EXPECTED_FALLBACK_COUNT := 11
const FACING_VALUES: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N"]
const MIRROR_FACINGS: Array[String] = ["W", "SW", "NW", "N"]

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Aceptación Fase 3 (GDD v1.6 §10.3)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	_print_environment()
	_criterion_1_sprites()
	_criterion_2_fallback()
	_criterion_3_battle_sprites()
	_criterion_4_determinism()
	_criterion_5_captures()
	_criterion_6_no_regression()
	_finish()


func _print_environment() -> void:
	print("[INFO] Fase 3 — presencia de artefactos:")
	print("  data/units.json: %s" % str(FileAccess.file_exists("res://data/units.json")))
	print("  %s: %s (%d PNG)" % [UNIT_PNG_DIR, str(DirAccess.dir_exists_absolute(UNIT_PNG_DIR)), _count_png(UNIT_PNG_DIR)])
	print("  %s: %s (%d PNG)" % [PROJECTILE_DIR, str(DirAccess.dir_exists_absolute(PROJECTILE_DIR)), _count_png(PROJECTILE_DIR)])
	print("  scripts/battle/tactical_battle.gd: %s" % str(FileAccess.file_exists("res://scripts/battle/tactical_battle.gd")))
	print("  scripts/battle/close_combat.gd: %s" % str(FileAccess.file_exists("res://scripts/battle/close_combat.gd")))
	print("  scenes/battle/tactical_map.tscn: %s" % str(FileAccess.file_exists("res://scenes/battle/tactical_map.tscn")))
	print("  docs/screenshots: %s (%d PNG)" % [str(DirAccess.dir_exists_absolute("res://docs/screenshots")), _count_png("res://docs/screenshots")])
	print("  staging Kimi: %s" % str(DirAccess.dir_exists_absolute("C:/Proyectos/TSB/.sprites_staging/sprites_unidades")))
	print("  10/10 autoloads montados" if _autoload("GameState") != null and _autoload("BattleManager") != null else "  autoloads incompletos")


# ---------------------------------------------------------------------------
# F3-C1 — 6 sprites núcleo: datos, assets y carga headless
# ---------------------------------------------------------------------------

func _criterion_1_sprites() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C1"
	var name := "Sprites núcleo: 6 hojas válidas, 18 PNG de unidades y 3 proyectiles cargan en headless"
	var data: Variant = _read_json("res://data/units.json")
	if not (data is Dictionary):
		_fail(id, name, "data/units.json no legible", started)
		return
	var units := _units_by_id(data)
	var core_present: Array[String] = []
	var missing: Array[String] = []
	for unit_id in CORE_UNITS:
		var unit: Dictionary = units.get(unit_id, {})
		var sheet: Variant = unit.get("sprite_sheet", null)
		if sheet is Dictionary:
			core_present.append(unit_id)
		else:
			missing.append(unit_id)
	var unit_png := _count_png(UNIT_PNG_DIR)
	var projectile_png := _count_png(PROJECTILE_DIR)
	var assets_detail := "PNG unidades=%d/18; proyectiles=%d/3; dir_unidades=%s" % [
		unit_png, projectile_png, str(DirAccess.dir_exists_absolute(UNIT_PNG_DIR)),
	]
	if core_present.is_empty():
		_skip(id, name, "AG-2 aún no añade sprite_sheet a units.json (0/6); assets de AG-5: PNG unidades=%d/18, proyectiles=%d/3, dir=%s; C1 pendiente de datos/import" % [
			unit_png, projectile_png, str(DirAccess.dir_exists_absolute(UNIT_PNG_DIR)),
		], started)
		return
	if core_present.size() < CORE_UNITS.size():
		_skip(id, name, "integración parcial %d/6 (%s); faltan: %s; %s" % [
			core_present.size(), ", ".join(core_present), ", ".join(missing), assets_detail,
		], started)
		return

	var issues: Array[String] = []
	for unit_id in CORE_UNITS:
		var unit: Dictionary = units.get(unit_id, {})
		var sheet_value: Variant = unit.get("sprite_sheet", null)
		if not (sheet_value is Dictionary):
			issues.append("%s sin sprite_sheet" % unit_id)
			continue
		var sheet := sheet_value as Dictionary
		var frames_value: Variant = sheet.get("frames", [])
		if not (frames_value is Array) or (frames_value as Array).size() != 3:
			issues.append("%s frames != 3" % unit_id)
		else:
			for frame_index in range((frames_value as Array).size()):
				var frame_path := str((frames_value as Array)[frame_index])
				if not frame_path.begins_with("res://"):
					issues.append("%s frame %d no-res://" % [unit_id, frame_index])
					continue
				if not ResourceLoader.exists(frame_path):
					issues.append("%s frame %d ausente" % [unit_id, frame_index])
					continue
				var texture_value: Variant = load(frame_path)
				if not (texture_value is Texture2D):
					issues.append("%s frame %d no Texture2D" % [unit_id, frame_index])
					continue
				var texture := texture_value as Texture2D
				var expected := _expected_sprite_size(unit_id)
				if texture.get_width() != expected.x or texture.get_height() != expected.y:
					issues.append("%s frame %d %dx%d (esperado %dx%d)" % [
						unit_id, frame_index, texture.get_width(), texture.get_height(), expected.x, expected.y,
					])
		var anim_value: Variant = sheet.get("anim", null)
		if not (anim_value is Dictionary):
			issues.append("%s sin anim" % unit_id)
		else:
			var anim := anim_value as Dictionary
			if not _int_array_equals(anim.get("march", []), [0, 1, 2]):
				issues.append("%s anim.march != [0,1,2]" % unit_id)
			if not is_equal_approx(float(anim.get("fps", 0.0)), 6.0):
				issues.append("%s fps != 6" % unit_id)
			if not bool(anim.get("loop", false)):
				issues.append("%s loop != true" % unit_id)
		var size_expected := _expected_sprite_size(unit_id)
		if not _int_array_equals(sheet.get("size", []), [size_expected.x, size_expected.y]):
			issues.append("%s size != [%d,%d]" % [unit_id, size_expected.x, size_expected.y])
		if str(sheet.get("anchor", "")) != "bottom_center":
			issues.append("%s anchor != bottom_center" % unit_id)
		if str(sheet.get("facing", "")) != "E":
			issues.append("%s facing != E" % unit_id)
	if unit_png != 18:
		issues.append("PNG de unidades=%d/18" % unit_png)
	if projectile_png != 3:
		issues.append("proyectiles=%d/3" % projectile_png)
	for projectile_name in PROJECTILE_FILES:
		var projectile_path := "%s/%s" % [PROJECTILE_DIR, projectile_name]
		if not FileAccess.file_exists(projectile_path):
			issues.append("falta %s" % projectile_name)
		elif not ResourceLoader.exists(projectile_path) or not (load(projectile_path) is Texture2D):
			issues.append("%s no carga" % projectile_name)
	var detail := "6/6 sprite_sheet; 18 PNG; 3 proyectiles; cargan 18 texturas 64x64/64x80; anim march [0,1,2] fps=6 loop; anchor=bottom_center facing=E"
	if not issues.is_empty():
		_fail(id, name, "errores: %s" % ", ".join(issues.slice(0, 8)), started)
		return
	_pass(id, name, detail, started)


# ---------------------------------------------------------------------------
# F3-C2 — 11 unidades restantes sin sprite → fallback heráldico
# ---------------------------------------------------------------------------

func _criterion_2_fallback() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C2"
	var name := "Fallback: las 11 unidades no núcleo no tienen sprite_sheet (sin huecos)"
	var data: Variant = _read_json("res://data/units.json")
	if not (data is Dictionary):
		_fail(id, name, "data/units.json no legible", started)
		return
	var units := _units_by_id(data)
	if units.size() != EXPECTED_UNIT_COUNT:
		_fail(id, name, "unidades=%d (esperado %d)" % [units.size(), EXPECTED_UNIT_COUNT], started)
		return
	var core_count := 0
	var fallback_ids: Array[String] = []
	var violations: Array[String] = []
	for unit_id in units.keys():
		var unit: Dictionary = units[unit_id]
		var has_sheet := unit.get("sprite_sheet", null) is Dictionary
		if CORE_UNITS.has(str(unit_id)):
			if has_sheet:
				core_count += 1
		else:
			fallback_ids.append(str(unit_id))
			if has_sheet:
				violations.append(str(unit_id))
	if fallback_ids.size() != EXPECTED_FALLBACK_COUNT:
		_fail(id, name, "unidades no núcleo=%d (esperado %d)" % [fallback_ids.size(), EXPECTED_FALLBACK_COUNT], started)
		return
	if not violations.is_empty():
		_fail(id, name, "unidades no núcleo con sprite_sheet: %s" % ", ".join(violations), started)
		return
	var detail := "%d unidades: %d núcleo (sprite %d/6) + %d sin sprite_sheet → fallback heráldico de Fase 2 (sin huecos)" % [
		units.size(), CORE_UNITS.size(), core_count, fallback_ids.size(),
	]
	_pass(id, name, detail, started)


# ---------------------------------------------------------------------------
# F3-C3 — Crécy N1/N2/N3 con animación/facing/mirroring y proyectiles
# ---------------------------------------------------------------------------

func _criterion_3_battle_sprites() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C3"
	var name := "Crécy N1/N2/N3 con sprites: animación/facing/mirroring y proyectiles virote/flecha/piedra"
	var data: Variant = _read_json("res://data/units.json")
	var units: Dictionary = _units_by_id(data)
	var core_integrated := 0
	for unit_id in CORE_UNITS:
		var unit: Dictionary = units.get(unit_id, {})
		if unit.get("sprite_sheet", null) is Dictionary:
			core_integrated += 1
	if core_integrated < CORE_UNITS.size():
		_skip(id, name, "sin datos de sprites (sprite_sheet %d/6): no hay animación/proyectiles que verificar; AG-5/AG-2 pendientes" % core_integrated, started)
		return
	var tactical_text := _read_text("res://scripts/battle/tactical_battle.gd")
	var close_text := _read_text("res://scripts/battle/close_combat.gd")
	var required_markers: Array[String] = ["sprite_sheet", "facing", "mirror", "march_frame", "get_projectiles"]
	var missing_markers: Array[String] = []
	for marker in required_markers:
		if not tactical_text.contains(marker) and not close_text.contains(marker):
			missing_markers.append(marker)
	if not missing_markers.is_empty():
		_skip(id, name, "datos de sprites presentes pero código aún sin APIs de animación/proyectiles (faltan: %s); AG-2/AG-3 pendientes" % ", ".join(missing_markers), started)
		return
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("resolve_delegated"):
		_fail(id, name, "BattleManager.resolve_delegated ausente", started)
		return
	var n1 := _run_n1(battle)
	if bool(n1.get("ok", false)) == false:
		_fail(id, name, "N1 falla: " + str(n1.get("reason", n1.get("detail", ""))), started)
		return
	var n2 := _run_n2_sprites(battle)
	if not bool(n2.get("ok", false)):
		_fail(id, name, "N2 falla: " + str(n2.get("reason", n2.get("detail", ""))), started)
		return
	var n3 := _run_n3_close(battle)
	if not bool(n3.get("ok", false)):
		_fail(id, name, "N3 falla: " + str(n3.get("reason", n3.get("detail", ""))), started)
		return
	var detail := "N1=%s; N2=%s; N3=%s" % [
		str(n1.get("detail", "")), str(n2.get("detail", "")), str(n3.get("detail", "")),
	]
	_pass(id, name, detail, started)


func _run_n1(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs != null:
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 900, 12)
	var region: Variant = _make_region("region_normandia", "plains", 60, 60, false)
	if attacker == null or defender == null or region == null:
		return {"ok": false, "reason": "modelos Army/RegionState no disponibles"}
	var report: Variant = battle.call("resolve_delegated", attacker, defender, region, 1)
	var report_dict := _report_dict(report)
	if report_dict.is_empty():
		return {"ok": false, "reason": "informe N1 vacío"}
	return {
		"ok": true,
		"report": report_dict,
		"detail": "N1 winner=%s bajas=%d/%d" % [
			str(report_dict.get("winner_faction", "")),
			int(report_dict.get("attacker_losses", 0)),
			int(report_dict.get("defender_losses", 0)),
		],
	}


func _run_n2_sprites(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs != null:
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 900, 12)
	var region: Variant = _make_region("region_normandia", "plains", 60, 60, false)
	if attacker == null or defender == null or region == null:
		return {"ok": false, "reason": "modelos no disponibles"}
	if not battle.has_method("launch_tactical"):
		return {"ok": false, "reason": "BattleManager.launch_tactical ausente"}
	var node_value: Variant = battle.call("launch_tactical", attacker, defender, region)
	if not (node_value is Node):
		return {"ok": false, "reason": "launch_tactical no devuelve Node"}
	var node := node_value as Node
	root.add_child(node)
	var units_before: Variant = node.call("get_units")
	if not (units_before is Array) or (units_before as Array).is_empty():
		node.free()
		return {"ok": false, "reason": "N2 sin unidades"}
	var errors: Array[String] = []
	var textured_units := 0
	for unit_value in (units_before as Array):
		if not (unit_value is Dictionary):
			continue
		var unit := unit_value as Dictionary
		for field_name in ["sprite_sheet", "facing", "mirror", "moving", "march_frame", "sprite_frame_path"]:
			if not unit.has(field_name):
				errors.append("unidad %s sin campo %s" % [str(unit.get("id", "?")), field_name])
		var facing := str(unit.get("facing", ""))
		if not FACING_VALUES.has(facing):
			errors.append("facing inválido '%s'" % facing)
		if not (unit.get("mirror", false) is bool):
			errors.append("mirror no bool")
		if not (unit.get("march_frame", 0) is int):
			errors.append("march_frame no int")
		var sheet_value: Variant = unit.get("sprite_sheet", null)
		if sheet_value is Dictionary:
			var frame_path := str(unit.get("sprite_frame_path", ""))
			if frame_path == "":
				errors.append("unidad con sprite_sheet sin sprite_frame_path")
			elif not ResourceLoader.exists(frame_path) or not (load(frame_path) is Texture2D):
				errors.append("sprite_frame_path no carga: %s" % frame_path)
			else:
				textured_units += 1
	if textured_units < 1:
		errors.append("ninguna unidad de N2 con sprite_sheet")
	if not node.has_method("get_projectiles"):
		errors.append("TacticalBattle sin get_projectiles()")
	else:
		var projectiles: Variant = node.call("get_projectiles")
		if not (projectiles is Array):
			errors.append("get_projectiles() no devuelve Array")
	var movement_detail := "movimiento no probado"
	var moved := false
	if node.has_method("get_units") and node.has_method("get_reachable_hexes") and node.has_method("move_unit"):
		var current_units: Variant = node.call("get_units")
		if current_units is Array and not (current_units as Array).is_empty():
			var first_unit: Dictionary = (current_units as Array)[0]
			var first_id := str(first_unit.get("id", ""))
			if first_id != "":
				var reachable: Variant = node.call("get_reachable_hexes", first_id)
				if reachable is Array and not (reachable as Array).is_empty():
					var hex: Dictionary = (reachable as Array)[0]
					var moved_ok: Variant = node.call("move_unit", first_id, int(hex.get("q", 0)), int(hex.get("r", 0)))
					if moved_ok is bool and bool(moved_ok):
						moved = true
						var after_units: Variant = node.call("get_units")
						if after_units is Array:
							for unit_value in (after_units as Array):
								if unit_value is Dictionary and str((unit_value as Dictionary).get("id", "")) == first_id:
									var moved_unit := unit_value as Dictionary
									var facing := str(moved_unit.get("facing", ""))
									var mirror := bool(moved_unit.get("mirror", false))
									var expected_mirror := MIRROR_FACINGS.has(facing)
									if mirror != expected_mirror:
										errors.append("mirror incoherente con facing %s" % facing)
									movement_detail = "movido %s → facing=%s mirror=%s" % [first_id, facing, str(mirror)]
									break
	var auto_detail := "auto_resolve no usado"
	if node.has_method("auto_resolve"):
		node.call("auto_resolve")
		auto_detail = "auto_resolve OK"
	var projectiles_after: Variant = node.call("get_projectiles") if node.has_method("get_projectiles") else []
	var projectile_count := 0
	if projectiles_after is Array:
		projectile_count = (projectiles_after as Array).size()
	node.free()
	if not errors.is_empty():
		return {"ok": false, "reason": "errores: " + ", ".join(errors.slice(0, 8))}
	var detail := "N2 unidades=%d texturizadas=%d; %s; %s; proyectiles activos=%d" % [
		(units_before as Array).size(), textured_units, movement_detail, auto_detail, projectile_count,
	]
	return {"ok": moved, "reason": "" if moved else "no se pudo probar movimiento/facing en N2", "detail": detail}


func _run_n3_close(battle: Node) -> Dictionary:
	if not battle.has_method("launch_close_combat"):
		return {"ok": false, "reason": "BattleManager.launch_close_combat ausente"}
	var attacker_unit := {
		"id": "qa_f3_attacker", "faction": "england", "unit_id": "crossbowmen",
		"size": 300, "strength": 8, "morale": 1.0, "experience": 50,
	}
	var defender_unit := {
		"id": "qa_f3_defender", "faction": "france", "unit_id": "men_at_arms",
		"size": 220, "strength": 12, "morale": 1.0, "experience": 50,
	}
	var node_value: Variant = battle.call("launch_close_combat", attacker_unit, defender_unit)
	if not (node_value is Node):
		return {"ok": false, "reason": "launch_close_combat no devuelve Node"}
	var node := node_value as Node
	root.add_child(node)
	if node.has_method("auto_resolve"):
		node.call("auto_resolve")
	var outcome: Variant = node.call("get_outcome") if node.has_method("get_outcome") else null
	node.free()
	if not (outcome is Dictionary) or (outcome as Dictionary).is_empty():
		return {"ok": false, "reason": "N3 sin outcome"}
	var outcome_dict := outcome as Dictionary
	return {
		"ok": true,
		"detail": "N3 winner=%s bajas=%d/%d" % [
			str(outcome_dict.get("winner_faction", "")),
			int(outcome_dict.get("attacker_losses", 0)),
			int(outcome_dict.get("defender_losses", 0)),
		],
	}


# ---------------------------------------------------------------------------
# F3-C4 — Determinismo de combate
# ---------------------------------------------------------------------------

func _criterion_4_determinism() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C4"
	var name := "Determinismo de combate intacto (misma semilla/entradas → mismo informe)"
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("resolve_delegated"):
		_fail(id, name, "BattleManager.resolve_delegated ausente", started)
		return
	var first := _run_n1(battle)
	var second := _run_n1(battle)
	if not bool(first.get("ok", false)) or not bool(second.get("ok", false)):
		_fail(id, name, "N1 no se pudo ejecutar dos veces", started)
		return
	var first_report: Dictionary = first.get("report", {})
	var second_report: Dictionary = second.get("report", {})
	var first_hash := _hash(first_report)
	var second_hash := _hash(second_report)
	if first_hash != second_hash:
		_fail(id, name, "informes no deterministas: %s vs %s" % [first_hash.substr(0, 12), second_hash.substr(0, 12)], started)
		return
	var detail := "N1 determinista: hash=%s; winner=%s bajas=%d/%d (2 ejecuciones)" % [
		first_hash.substr(0, 16), str(first_report.get("winner_faction", "")),
		int(first_report.get("attacker_losses", 0)), int(first_report.get("defender_losses", 0)),
	]
	_pass(id, name, detail, started)


# ---------------------------------------------------------------------------
# F3-C5 — Capturas 64 px + N2/N3 con sprites/proyectiles
# ---------------------------------------------------------------------------

func _criterion_5_captures() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C5"
	var name := "Capturas 64 px de milicia/ballesteros/arqueros + N2/N3 con sprites y proyectiles"
	var files := _files_in("res://docs/screenshots", "png")
	var unit_captures: Array[String] = []
	var unit_groups: Array[Array] = [
		["militia", "milicia"],
		["crossbow", "ballester"],
		["longbow", "arquero"],
	]
	for group in unit_groups:
		var found := _find_capture(files, group, ["64", "sprite", "unit", "unidad"])
		if found != "":
			unit_captures.append(found)
	var n2_capture := _find_capture(files, ["n2", "tactical"], ["sprite", "unit", "unidad"])
	var n3_capture := _find_capture(files, ["n3", "close"], ["project", "proyectil", "virote", "flecha", "piedra", "sprite"])
	var missing: Array[String] = []
	if unit_captures.size() < 3:
		missing.append("3 capturas de unidades 64px (%d/3)" % unit_captures.size())
	if n2_capture == "":
		missing.append("captura N2 con sprites")
	if n3_capture == "":
		missing.append("captura N3 con proyectiles")
	if not missing.is_empty():
		_skip(id, name, "faltan: %s; PNG en docs/screenshots=%d; AG-3/AG-0 pendientes" % [", ".join(missing), files.size()], started)
		return
	var captures: Array[String] = []
	captures.append_array(unit_captures)
	captures.append(n2_capture)
	captures.append(n3_capture)
	var wrong_sizes: Array[String] = []
	for capture_name in captures:
		var path := "res://docs/screenshots/%s" % capture_name
		var dims := _png_dimensions(path)
		if dims != Vector2i(1920, 1080):
			wrong_sizes.append("%s=%dx%d" % [capture_name, dims.x, dims.y])
	if not wrong_sizes.is_empty():
		_fail(id, name, "capturas con tamaño distinto de 1920x1080: " + ", ".join(wrong_sizes), started)
		return
	_pass(id, name, "5/5 capturas: %s" % ", ".join(captures), started)


# ---------------------------------------------------------------------------
# F3-C6 — No regresión
# ---------------------------------------------------------------------------

func _criterion_6_no_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3-C6"
	var name := "No regresión: 17 unidades, 18 escenas, tests y artefactos F2, scripts compilando"
	var issues: Array[String] = []
	var data: Variant = _read_json("res://data/units.json")
	var units := _units_by_id(data)
	if units.size() != EXPECTED_UNIT_COUNT:
		issues.append("unidades=%d/%d" % [units.size(), EXPECTED_UNIT_COUNT])
	var scene_count := _count_files("res://scenes", "tscn")
	if scene_count < 18:
		issues.append("escenas=%d/18" % scene_count)
	var test_count := _count_files("res://tests", "gd")
	if test_count < 22:
		issues.append("tests=%d/22" % test_count)
	for harness_path in ["res://tests/qa_acceptance.gd", "res://tests/qa_acceptance_fase2.gd", "res://tests/run_all.gd"]:
		if not FileAccess.file_exists(harness_path):
			issues.append("falta %s" % harness_path.get_file())
	for artifact in ["res://data/map_borders.json", "res://assets/art/map/terrain_base.png", "res://data/characters.json"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta artefacto F2 %s" % artifact.get_file())
	var script_failures := _scan_script_compile_failures()
	if not script_failures.is_empty():
		issues.append("scripts sin compilar: %s" % ", ".join(script_failures.slice(0, 5)))
	var detail := "17 unidades; %d escenas; %d tests; F1/F2/run_all presentes; F2 map_borders/retratos presentes; scripts fallos=%d" % [
		scene_count, test_count, script_failures.size(),
	]
	if not issues.is_empty():
		_fail(id, name, ", ".join(issues), started)
		return
	_pass(id, name, detail, started)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _record(id: String, name: String, status: String, detail: String, started_ms: int) -> void:
	var elapsed := Time.get_ticks_msec() - started_ms
	_results.append({"id": id, "name": name, "status": status, "detail": detail, "ms": elapsed})
	var suffix := "" if detail == "" else " :: " + detail
	print("  [%s] %s — %s%s" % [status, id, name, suffix])


func _pass(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "PASS", detail, started_ms)


func _fail(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "FAIL", detail, started_ms)


func _skip(id: String, name: String, reason: String, started_ms: int) -> void:
	_record(id, name, "SKIP", reason + " (pendiente: módulo Fase 3 en curso)", started_ms)


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
	print("RESULTADO QA ACEPTACIÓN FASE 3: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [
		passed, failed, skipped, _results.size(),
	])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [
			str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0)),
		])
	var code := 0
	if failed > 0:
		print("ACEPTACIÓN FASE 3: NO ACEPTADA — FAIL en %d criterio(s) (exit 1)" % failed)
		code = 1
	elif skipped > 0:
		print("BASELINE FASE 3: PENDIENTE — %d criterio(s) a la espera de módulos en curso (no es rechazo)" % skipped)
		code = 1
	else:
		print("ACEPTACIÓN FASE 3: OK — 6/6 criterios PASS (exit 0)")
	print("--------------------------------------------------------------")
	quit(code)


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


func _read_text(res_path: String) -> String:
	if not FileAccess.file_exists(res_path):
		return ""
	return FileAccess.get_file_as_string(res_path)


func _units_by_id(data: Variant) -> Dictionary:
	var out: Dictionary = {}
	if data is Dictionary:
		var units_value: Variant = (data as Dictionary).get("units", null)
		if units_value is Array:
			for unit_value in (units_value as Array):
				if unit_value is Dictionary:
					var unit := unit_value as Dictionary
					out[str(unit.get("id", ""))] = unit
	return out


func _expected_sprite_size(unit_id: String) -> Vector2i:
	if unit_id == "men_at_arms" or unit_id == "light_horseman":
		return Vector2i(64, 80)
	return Vector2i(64, 64)


func _int_array_equals(value: Variant, expected: Array) -> bool:
	if not (value is Array):
		return false
	if (value as Array).size() != expected.size():
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


func _files_in(res_dir: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(res_dir)
	if dir == null:
		return files
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.get_extension().to_lower() == extension:
			files.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _find_capture(files: Array[String], group_a: Array, group_b: Array) -> String:
	for file_name in files:
		var lower := file_name.to_lower()
		var matches_a := false
		for term in group_a:
			if lower.contains(str(term)):
				matches_a = true
				break
		if not matches_a:
			continue
		for term in group_b:
			if lower.contains(str(term)):
				return file_name
	return ""


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


func _hash(value: Variant) -> String:
	var text := JSON.stringify(value)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _make_army(faction_id: String, region_id: String, leader_id: String, unit_id: String, size: int, strength: int) -> Variant:
	var script: Variant = load("res://scripts/model/army.gd")
	if not (script is GDScript):
		return null
	var army: Variant = (script as GDScript).new()
	if army == null:
		return null
	army.set("id", "qa_f3_%s_%s" % [faction_id, unit_id])
	army.set("faction_id", faction_id)
	army.set("region_id", region_id)
	army.set("leader_id", leader_id)
	army.set("morale", 1.0)
	army.set("units", [{
		"id": "u1", "unit_id": unit_id, "size": size, "strength": strength,
		"morale": 1.0, "experience": 50,
	}])
	return army


func _make_region(region_id: String, terrain: String, support: int, wealth: int, has_city: bool) -> Variant:
	var script: Variant = load("res://scripts/model/region_state.gd")
	if not (script is GDScript):
		return null
	var region: Variant = (script as GDScript).new()
	if region == null:
		return null
	region.set("id", region_id)
	region.set("terrain", terrain)
	region.set("support", support)
	region.set("base_wealth", wealth)
	region.set("has_city", has_city)
	return region


func _report_dict(report: Variant) -> Dictionary:
	if report == null:
		return {}
	if report is Dictionary:
		return report as Dictionary
	if report is Object and (report as Object).has_method("to_dict"):
		var data: Variant = (report as Object).call("to_dict")
		if data is Dictionary:
			return data as Dictionary
	return {}


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
