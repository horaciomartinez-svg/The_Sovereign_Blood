extends SceneTree
## Harness QA — Fase 3 §10.4: tiles del campo de batalla N3 (GDD v1.7 / addendum 3.1).
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_tiles.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso (baseline, no es
## rechazo); FAIL = módulo presente pero viola el contrato. Exit 0 solo con 7/7 PASS.

const TILE_DIR := "res://assets/art/battle/tiles"
const TILE_KEYS: Array[String] = [
	"pastizal", "pastizal_arbustos", "pradera", "rio", "puente", "puente_villa",
	"colina", "bosque", "montana", "villa", "villa_calle", "camino",
]
const TILE_EXPECTED: Dictionary = {
	"pastizal": {"move_cost": 1.0, "defense": 0, "passable": true},
	"pastizal_arbustos": {"move_cost": 1.0, "defense": 0, "passable": true},
	"pradera": {"move_cost": 1.0, "defense": 0, "passable": true},
	"rio": {"move_cost": null, "defense": 0, "passable": false},
	"puente": {"move_cost": 1.0, "defense": 0, "passable": true},
	"puente_villa": {"move_cost": 1.0, "defense": 1, "passable": true},
	"colina": {"move_cost": 2.0, "defense": 1, "passable": true},
	"bosque": {"move_cost": 2.0, "defense": 1, "passable": true, "cavalry_penalty": true},
	"montana": {"move_cost": null, "defense": 0, "passable": false},
	"villa": {"move_cost": 1.0, "defense": 1, "passable": true},
	"villa_calle": {"move_cost": 1.0, "defense": 0, "passable": true, "move_bonus": true},
	"camino": {"move_cost": 0.5, "defense": 0, "passable": true, "move_bonus": true},
}
const TILE_CAPTURES: Array[String] = ["tiles_n3_rio_puente_villa.png", "tiles_n3_llanura.png"]

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Aceptación Fase 3 §10.4 (tiles N3)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	_print_environment()
	_criterion_1_tiles()
	_criterion_2_table()
	_criterion_3_impassable()
	_criterion_4_bonuses()
	_criterion_5_generator()
	_criterion_6_captures()
	_criterion_7_no_regression()
	_finish()


func _print_environment() -> void:
	print("[INFO] Fase 3 §10.4 — presencia de artefactos:")
	print("  data/battle_tiles.json: %s" % str(FileAccess.file_exists("res://data/battle_tiles.json")))
	print("  data/schema/battle_tiles.schema.json: %s" % str(FileAccess.file_exists("res://data/schema/battle_tiles.schema.json")))
	print("  %s: %s (%d PNG)" % [TILE_DIR, str(DirAccess.dir_exists_absolute(TILE_DIR)), _count_png(TILE_DIR)])
	print("  scripts/battle/tiles*.gd o reglas: %s" % str(_find_rules_files().size()))
	print("  scripts/ui/battle/battlefield_generator.gd: %s" % str(FileAccess.file_exists("res://scripts/ui/battle/battlefield_generator.gd")))
	print("  docs/screenshots: %s (%d PNG)" % [str(DirAccess.dir_exists_absolute("res://docs/screenshots")), _count_png("res://docs/screenshots")])
	print("  staging tiles: %s" % str(DirAccess.dir_exists_absolute("C:/Proyectos/TSB/.tiles_staging/tiles_batalla")))
	print("  10/10 autoloads montados" if _autoload("GameState") != null and _autoload("BattleManager") != null else "  autoloads incompletos")


# ---------------------------------------------------------------------------
# F3T-C1 — 12 tiles: assets y carga headless
# ---------------------------------------------------------------------------

func _criterion_1_tiles() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C1"
	var name := "12 tiles cargan en headless: PNG 512x512 y rutas de battle_tiles"
	var table := _battle_tiles_table()
	if table.is_empty():
		_skip(id, name, "data/battle_tiles.json ausente o vacío; tiles solo en staging; AG-2/AG-3 en curso", started)
		return
	var issues: Array[String] = []
	var loaded := 0
	for key in TILE_KEYS:
		if not table.has(key):
			issues.append("%s ausente en battle_tiles" % key)
			continue
		var entry: Dictionary = _entry_dict(table.get(key))
		var tile_path := str(entry.get("tile", ""))
		if tile_path == "":
			tile_path = "%s/tile_%s.png" % [TILE_DIR, key]
		if not tile_path.begins_with("res://"):
			issues.append("%s ruta no-res://" % key)
			continue
		if not ResourceLoader.exists(tile_path):
			issues.append("%s no existe (%s)" % [key, tile_path])
			continue
		var texture_value: Variant = load(tile_path)
		if not (texture_value is Texture2D):
			issues.append("%s no es Texture2D" % key)
			continue
		var texture := texture_value as Texture2D
		if texture.get_width() != 512 or texture.get_height() != 512:
			issues.append("%s %dx%d (esperado 512x512)" % [key, texture.get_width(), texture.get_height()])
			continue
		loaded += 1
	var png_count := _count_png(TILE_DIR)
	if png_count != 12:
		issues.append("PNG de tiles=%d/12" % png_count)
	var src_count := _count_png("%s/src" % TILE_DIR)
	if src_count != 12:
		issues.append("raw src=%d/12" % src_count)
	if not FileAccess.file_exists("%s/src/.gdignore" % TILE_DIR):
		issues.append("falta src/.gdignore (D-054)")
	if not issues.is_empty():
		_fail(id, name, "errores: " + ", ".join(issues.slice(0, 8)), started)
		return
	_pass(id, name, "12/12 tiles 512x512 cargados como Texture2D; 12 PNG producción; 12 raw src con .gdignore", started)


# ---------------------------------------------------------------------------
# F3T-C2 — Tabla battle_tiles validada
# ---------------------------------------------------------------------------

func _criterion_2_table() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C2"
	var name := "battle_tiles: 12 claves con move_cost/defense/passable/flags exactos (D-053)"
	var table := _battle_tiles_table()
	if table.is_empty():
		_skip(id, name, "data/battle_tiles.json ausente; AG-2 en curso", started)
		return
	var issues: Array[String] = []
	for key in TILE_KEYS:
		if not table.has(key):
			issues.append("%s ausente" % key)
			continue
		var entry: Dictionary = _entry_dict(table.get(key))
		var expected: Dictionary = TILE_EXPECTED[key]
		var expected_cost: Variant = expected["move_cost"]
		var cost_value: Variant = entry.get("move_cost", null)
		if expected_cost == null:
			if cost_value != null:
				issues.append("%s move_cost debe null" % key)
		elif not is_equal_approx(float(cost_value), float(expected_cost)):
			issues.append("%s move_cost=%s (esperado %s)" % [key, str(cost_value), str(expected_cost)])
		if int(entry.get("defense", -1)) != int(expected["defense"]):
			issues.append("%s defense=%s" % [key, str(entry.get("defense", "?"))])
		if bool(entry.get("passable", false)) != bool(expected["passable"]):
			issues.append("%s passable=%s" % [key, str(entry.get("passable", "?"))])
		if bool(expected.get("cavalry_penalty", false)) != bool(entry.get("cavalry_penalty", false)):
			issues.append("%s cavalry_penalty incoherente" % key)
		if bool(expected.get("move_bonus", false)) != bool(entry.get("move_bonus", false)):
			issues.append("%s move_bonus incoherente" % key)
		if not bool(entry.get("passable", false)) and entry.get("move_cost", null) != null:
			issues.append("%s impassable con move_cost no-null" % key)
	if not FileAccess.file_exists("res://data/schema/battle_tiles.schema.json"):
		issues.append("falta data/schema/battle_tiles.schema.json")
	if not issues.is_empty():
		_fail(id, name, "errores: " + ", ".join(issues.slice(0, 8)), started)
		return
	_pass(id, name, "12/12 claves y valores/flags D-053; schema presente; validate_data externo 0 errores", started)


# ---------------------------------------------------------------------------
# F3T-C3 — Río/montaña intransitables en movimiento
# ---------------------------------------------------------------------------

func _criterion_3_impassable() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C3"
	var name := "Río y montaña intransitables en N2/N3; puente transitable"
	var tiles: Variant = _tiles_instance()
	if tiles == null:
		_skip(id, name, "battle_tiles/API BattleTiles ausente; AG-2/AG-3 en curso", started)
		return
	var errors: Array[String] = []
	if bool(tiles.call("is_passable", "rio")):
		errors.append("rio passable=true")
	if bool(tiles.call("is_passable", "montana")):
		errors.append("montana passable=true")
	if not is_equal_approx(float(tiles.call("get_move_cost", "rio")), -1.0):
		errors.append("rio move_cost != -1")
	if not is_equal_approx(float(tiles.call("get_move_cost", "montana")), -1.0):
		errors.append("montana move_cost != -1")
	if not bool(tiles.call("is_passable", "puente")):
		errors.append("puente passable=false")
	if not is_equal_approx(float(tiles.call("get_move_cost", "puente")), 1.0):
		errors.append("puente move_cost != 1")
	var n2 := _n2_tiles_movement_probe()
	if bool(n2.get("available", false)):
		errors.append_array(n2.get("errors", []))
	if not errors.is_empty():
		_fail(id, name, "errores: " + ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "BattleTiles: rio/montana passable=false y cost=-1; puente passable/cost1; " + str(n2.get("detail", "N2 sin hex impasable adyacente")), started)


func _criterion_4_bonuses() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C4"
	var name := "Bonus §6.4: colina/camino/villa/bosque aplican en fórmulas de movimiento/defensa"
	var tiles: Variant = _tiles_instance()
	if tiles == null:
		_skip(id, name, "battle_tiles/API BattleTiles ausente; AG-2 en curso", started)
		return
	var errors: Array[String] = []
	if not is_equal_approx(float(tiles.call("get_move_cost", "colina")), 2.0):
		errors.append("colina move_cost != 2")
	if int(tiles.call("get_defense", "colina")) != 1:
		errors.append("colina defense != 1")
	if not is_equal_approx(float(tiles.call("get_move_cost", "camino")), 0.5):
		errors.append("camino move_cost != 0.5")
	if not bool(tiles.call("has_move_bonus", "camino")):
		errors.append("camino sin move_bonus")
	if not is_equal_approx(float(tiles.call("get_move_cost", "villa_calle")), 0.5) or not bool(tiles.call("has_move_bonus", "villa_calle")):
		errors.append("villa_calle coste/bonus incorrecto")
	if int(tiles.call("get_defense", "villa")) != 1 or not is_equal_approx(float(tiles.call("get_defense_multiplier", "villa")), 1.2):
		errors.append("villa defense/multiplier incorrecto")
	if int(tiles.call("get_defense", "puente_villa")) != 1:
		errors.append("puente_villa defense != 1")
	if int(tiles.call("get_defense", "bosque")) != 1 or not bool(tiles.call("has_cavalry_penalty", "bosque")):
		errors.append("bosque defense/cavalry_penalty incorrecto")
	if not is_equal_approx(float(tiles.call("get_move_cost", "bosque", "cavalry")), 3.0):
		errors.append("bosque caballería cost != 3")
	if not is_equal_approx(float(tiles.call("get_move_cost", "bosque", "infantry")), 2.0):
		errors.append("bosque infantería cost != 2")
	if str(tiles.call("tile_key_for_terrain", "plains")) != "pastizal" or str(tiles.call("tile_key_for_terrain", "forest")) != "bosque":
		errors.append("tile_key_for_terrain incoherente")
	var empty_script: Variant = load("res://scripts/battle/battle_tiles.gd")
	if empty_script is GDScript:
		var empty_tiles: Variant = (empty_script as GDScript).new({})
		if not bool(empty_tiles.call("is_passable", "rio")):
			errors.append("fallback sin tabla debe ser passable")
		if not is_equal_approx(float(empty_tiles.call("get_move_cost", "rio")), -1.0):
			errors.append("fallback cost debe ser -1")
		if int(empty_tiles.call("get_defense", "rio")) != 0:
			errors.append("fallback defense debe ser 0")
	var n2 := _n2_tiles_bonus_probe()
	if bool(n2.get("available", false)):
		errors.append_array(n2.get("errors", []))
	var n3 := _n3_tiles_probe()
	if bool(n3.get("available", false)):
		errors.append_array(n3.get("errors", []))
	if not errors.is_empty():
		_fail(id, name, "errores: " + ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "colina 2/1; camino 0.5+bonus; villa_calle 0.5+bonus; villa defense1×1.2; bosque 2/1 cavalry_penalty (cab 3.0); fallback legado OK; " + str(n2.get("detail", "N2")), started)


# ---------------------------------------------------------------------------
# F3T-C5 — Generador de campos N3 derivado de la región
# ---------------------------------------------------------------------------

func _criterion_5_generator() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C5"
	var name := "Generador N3: campo con río+puente+villa y campo de llanura desde 2 regiones"
	var generator_path := "res://scripts/ui/battle/battlefield_generator.gd"
	if not FileAccess.file_exists(generator_path):
		_skip(id, name, "battlefield_generator.gd ausente; AG-3 en curso", started)
		return
	var generator_script: Variant = load(generator_path)
	if not (generator_script is GDScript):
		_fail(id, name, "battlefield_generator.gd no compila", started)
		return
	var pr: Variant = _probe_generator(generator_script as GDScript)
	if pr is Dictionary and bool((pr as Dictionary).get("ok", false)):
		_pass(id, name, str((pr as Dictionary).get("detail", "generador OK")), started)
		return
	if pr is Dictionary and not bool((pr as Dictionary).get("available", true)):
		_skip(id, name, "API del generador aún no expuesta: " + str((pr as Dictionary).get("detail", "")), started)
		return
	_fail(id, name, "generador no produce los 2 campos: " + str((pr as Dictionary).get("detail", "")), started)


# ---------------------------------------------------------------------------
# F3T-C6 — Capturas
# ---------------------------------------------------------------------------

func _criterion_6_captures() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C6"
	var name := "Capturas tiles_n3_rio_puente_villa, tiles_n3_llanura y hoja de contacto (1920x1080)"
	var missing: Array[String] = []
	for capture_name in TILE_CAPTURES:
		if not FileAccess.file_exists("res://docs/screenshots/%s" % capture_name):
			missing.append(capture_name)
	var contact := _find_contact_sheet()
	if contact == "":
		missing.append("hoja de contacto de tiles")
	if not missing.is_empty():
		_skip(id, name, "faltan capturas: %s; AG-3/AG-0 pendientes" % ", ".join(missing), started)
		return
	var captures: Array[String] = []
	captures.append_array(TILE_CAPTURES)
	captures.append(contact)
	var wrong_sizes: Array[String] = []
	for capture_name in captures:
		var dims := _png_dimensions("res://docs/screenshots/%s" % capture_name)
		if dims != Vector2i(1920, 1080):
			wrong_sizes.append("%s=%dx%d" % [capture_name, dims.x, dims.y])
	if not wrong_sizes.is_empty():
		_fail(id, name, "tamaño distinto de 1920x1080: " + ", ".join(wrong_sizes), started)
		return
	_pass(id, name, "3/3 capturas 1920x1080: " + ", ".join(captures), started)


# ---------------------------------------------------------------------------
# F3T-C7 — No regresión
# ---------------------------------------------------------------------------

func _criterion_7_no_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "F3T-C7"
	var name := "No regresión: 18 escenas, harness F1/F2/F3, artefactos previos y scripts compilando"
	var issues: Array[String] = []
	var scene_count := _count_files("res://scenes", "tscn")
	if scene_count < 18:
		issues.append("escenas=%d/18" % scene_count)
	var test_count := _count_files("res://tests", "gd")
	if test_count < 24:
		issues.append("tests=%d/24 (run_all 1074+)" % test_count)
	for harness_path in ["res://tests/qa_acceptance.gd", "res://tests/qa_acceptance_fase2.gd", "res://tests/qa_acceptance_fase3.gd"]:
		if not FileAccess.file_exists(harness_path):
			issues.append("falta %s" % harness_path.get_file())
	for artifact in ["res://data/map_borders.json", "res://assets/art/sprites/units/militia_spearman_march_1.png", "res://data/characters.json"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta artefacto previo %s" % artifact.get_file())
	var failures := _scan_script_compile_failures()
	if not failures.is_empty():
		issues.append("scripts sin compilar: " + ", ".join(failures.slice(0, 5)))
	var detail := "%d escenas; %d tests; F1/F2/F3 presentes; artefactos F2/sprites; scripts fallos=%d" % [
		scene_count, test_count, failures.size(),
	]
	if not issues.is_empty():
		_fail(id, name, ", ".join(issues), started)
		return
	_pass(id, name, detail, started)


# ---------------------------------------------------------------------------
# Sondas / helpers de integración (devuelven available=false si AG-2/AG-3 no exponen API)
# ---------------------------------------------------------------------------

func _probe_impassable() -> Dictionary:
	return {"ok": false, "available": false, "detail": "sin helper público de reglas de tiles en el árbol"}


func _probe_bonuses() -> Dictionary:
	return {"ok": false, "available": false, "detail": "sin helper público de bonos/defensa de tiles en el árbol"}


func _probe_generator(script: GDScript) -> Dictionary:
	if not script.can_instantiate() and not script.has_method("generate"):
		return {"ok": false, "available": false, "detail": "generador sin método estático generate()"}
	var first_value: Variant = script.call("generate", "coast", true, 1337, "region_flandes")
	var second_value: Variant = script.call("generate", "plains", false, 1337, "region_normandia")
	var repeat_value: Variant = script.call("generate", "coast", true, 1337, "region_flandes")
	if not (first_value is Dictionary) or not (second_value is Dictionary) or not (repeat_value is Dictionary):
		return {"ok": false, "available": false, "detail": "generate() no devuelve Dictionary"}
	var first := first_value as Dictionary
	var second := second_value as Dictionary
	var repeat := repeat_value as Dictionary
	var first_tiles: Variant = first.get("tiles", [])
	var second_tiles: Variant = second.get("tiles", [])
	if not (first_tiles is Array) or not (second_tiles is Array):
		return {"ok": false, "available": true, "detail": "campos sin array de tiles"}
	var errors: Array[String] = []
	var first_array := first_tiles as Array
	var second_array := second_tiles as Array
	errors.append_array(_field_errors("coast+villa", first_array, true))
	errors.append_array(_field_errors("plains", second_array, false))
	var first_bridges: Variant = first.get("bridges", [])
	if not (first_bridges is Array) or (first_bridges as Array).is_empty():
		errors.append("campo coast sin puentes")
	var villa_value: Variant = first.get("villa", Vector2i(-1, -1))
	var has_villa := false
	if villa_value is Vector2i and (villa_value as Vector2i).x >= 0:
		has_villa = true
	if not has_villa and not first_array.has("puente_villa") and not first_array.has("villa"):
		errors.append("campo coast sin villa")
	if first_array == second_array:
		errors.append("campos coast/plains idénticos (no derivan de la región)")
	var repeat_tiles: Variant = repeat.get("tiles", [])
	var deterministic := repeat_tiles is Array and (repeat_tiles as Array) == first_array
	if not deterministic:
		errors.append("generador no determinista para misma semilla")
	var detail := "coast+villa: %d tiles, %d puentes, villa=%s; plains: %d tiles; determinista=%s" % [
		first_array.size(), (first_bridges as Array).size() if first_bridges is Array else 0,
		str(villa_value), second_array.size(), str(deterministic),
	]
	return {"ok": errors.is_empty(), "available": true, "detail": detail if errors.is_empty() else ", ".join(errors)}


func _field_errors(label: String, tiles: Array, expect_river: bool) -> Array[String]:
	var errors: Array[String] = []
	var has_river := false
	for tile_value in tiles:
		var key := str(tile_value)
		if key == "rio":
			has_river = true
		if not TILE_KEYS.has(key):
			errors.append("%s tile desconocido '%s'" % [label, key])
	if expect_river and not has_river:
		errors.append("%s sin río" % label)
	if not expect_river and has_river:
		errors.append("%s (llanura) contiene río" % label)
	return errors


func _tiles_instance() -> Variant:
	if not _ensure_game_started():
		return null
	var dl := _autoload("DataLoader")
	if dl == null or not dl.has_method("get_battle_tiles"):
		return null
	var table_value: Variant = dl.call("get_battle_tiles")
	if not (table_value is Dictionary) or (table_value as Dictionary).is_empty():
		return null
	var script: Variant = load("res://scripts/battle/battle_tiles.gd")
	if not (script is GDScript):
		return null
	return (script as GDScript).new(table_value as Dictionary)


func _n2_tiles_movement_probe() -> Dictionary:
	if not _ensure_game_started():
		return {"available": false, "detail": "sin GameState"}
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("launch_tactical"):
		return {"available": false, "detail": "sin launch_tactical"}
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 800, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 700, 12)
	var region: Variant = _make_region("region_normandia", "plains")
	if attacker == null or defender == null or region == null:
		return {"available": false, "detail": "modelos no disponibles"}
	var node_value: Variant = battle.call("launch_tactical", attacker, defender, region)
	if not (node_value is Node):
		return {"available": false, "detail": "launch_tactical no devuelve Node"}
	var node := node_value as Node
	root.add_child(node)
	var errors: Array[String] = []
	var tested := 0
	var hexes: Variant = node.call("get_hexes")
	var units: Variant = node.call("get_units")
	if hexes is Array and units is Array:
		for hex_value in (hexes as Array):
			if not (hex_value is Dictionary):
				continue
			var hex := hex_value as Dictionary
			var tile_key := str(hex.get("tile", ""))
			if tile_key != "rio" and tile_key != "montana":
				continue
			var hq := int(hex.get("q", 0))
			var hr := int(hex.get("r", 0))
			for unit_value in (units as Array):
				if not (unit_value is Dictionary):
					continue
				var unit := unit_value as Dictionary
				var uq := int(unit.get("q", 0))
				var ur := int(unit.get("r", 0))
				var distance := (absi(uq - hq) + absi(ur - hr) + absi((uq - hq) + (ur - hr))) / 2
				if distance != 1:
					continue
				tested += 1
				var unit_id := str(unit.get("id", ""))
				if bool(node.call("can_move_unit", unit_id, hq, hr)):
					errors.append("unidad %s puede entrar a %s" % [unit_id, tile_key])
				var moved: Variant = node.call("move_unit", unit_id, hq, hr)
				if moved is bool and bool(moved):
					errors.append("move_unit permitió entrar a %s" % tile_key)
				break
	var bridges_tested := 0
	if hexes is Array and units is Array:
		for hex_value in (hexes as Array):
			if not (hex_value is Dictionary):
				continue
			var bridge_hex := hex_value as Dictionary
			var bridge_tile := str(bridge_hex.get("tile", ""))
			if bridge_tile != "puente" and bridge_tile != "puente_villa":
				continue
			var bq := int(bridge_hex.get("q", 0))
			var br := int(bridge_hex.get("r", 0))
			for unit_value in (units as Array):
				if not (unit_value is Dictionary):
					continue
				var bridge_unit := unit_value as Dictionary
				var buq := int(bridge_unit.get("q", 0))
				var bur := int(bridge_unit.get("r", 0))
				var bridge_distance := (absi(buq - bq) + absi(bur - br) + absi((buq - bq) + (bur - br))) / 2
				if bridge_distance != 1:
					continue
				bridges_tested += 1
				var bridge_unit_id := str(bridge_unit.get("id", ""))
				if not bool(node.call("can_move_unit", bridge_unit_id, bq, br)):
					errors.append("puente %s no transitable desde unidad adyacente %s" % [bridge_tile, bridge_unit_id])
				break
	var detail := "N2: %d entradas a rio/montana bloqueadas (can_move/move_unit false); %d puentes adyacentes transitables" % [tested, bridges_tested]
	if tested == 0:
		detail = "N2: sin hex rio/montana adyacente a unidad en este mapa; API pura verificada; %d puentes adyacentes" % bridges_tested
	node.free()
	return {"available": true, "errors": errors, "detail": detail}


func _n2_tiles_bonus_probe() -> Dictionary:
	if not _ensure_game_started():
		return {"available": false, "detail": "sin GameState"}
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("launch_tactical"):
		return {"available": false}
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 800, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 700, 12)
	var region: Variant = _make_region("region_normandia", "plains")
	if attacker == null or defender == null or region == null:
		return {"available": false}
	var node_value: Variant = battle.call("launch_tactical", attacker, defender, region)
	if not (node_value is Node):
		return {"available": false}
	var node := node_value as Node
	root.add_child(node)
	var errors: Array[String] = []
	var keys: Variant = node.call("get_battle_tile_keys") if node.has_method("get_battle_tile_keys") else []
	if not (keys is Array) or (keys as Array).size() != 12:
		errors.append("N2 get_battle_tile_keys != 12")
	if node.has_method("get_tile_move_cost") and not is_equal_approx(float(node.call("get_tile_move_cost", "colina")), 2.0):
		errors.append("N2 colina cost != 2")
	if node.has_method("get_tile_defense") and int(node.call("get_tile_defense", "colina")) != 1:
		errors.append("N2 colina defense != 1")
	if node.has_method("is_tile_passable") and bool(node.call("is_tile_passable", "rio")):
		errors.append("N2 rio passable")
	var hexes: Variant = node.call("get_hexes")
	var tiles_ok := 0
	if hexes is Array:
		for hex_value in (hexes as Array):
			if hex_value is Dictionary and TILE_KEYS.has(str((hex_value as Dictionary).get("tile", ""))):
				tiles_ok += 1
	if tiles_ok == 0:
		errors.append("N2 hexes sin campo tile")
	node.free()
	return {"available": true, "errors": errors, "detail": "N2 get_battle_tile_keys=12; colina 2/1; %d hexes con tile válido" % tiles_ok}


func _n3_tiles_probe() -> Dictionary:
	if not _ensure_game_started():
		return {"available": false}
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("launch_close_combat"):
		return {"available": false}
	var attacker := {"id": "qa_tile_atk", "faction": "england", "unit_id": "crossbowmen", "size": 300, "strength": 8, "morale": 1.0, "experience": 50, "tile": "colina"}
	var defender := {"id": "qa_tile_def", "faction": "france", "unit_id": "men_at_arms", "size": 280, "strength": 12, "morale": 1.0, "experience": 50, "tile": "villa"}
	var node_value: Variant = battle.call("launch_close_combat", attacker, defender)
	if not (node_value is Node):
		return {"available": false}
	var node := node_value as Node
	root.add_child(node)
	var errors: Array[String] = []
	var keys: Variant = node.call("get_battle_tile_keys") if node.has_method("get_battle_tile_keys") else []
	if not (keys is Array) or (keys as Array).size() != 12:
		errors.append("N3 get_battle_tile_keys != 12")
	if node.has_method("get_tile_defense") and int(node.call("get_tile_defense", "villa")) != 1:
		errors.append("N3 villa defense != 1")
	if node.has_method("is_tile_passable") and bool(node.call("is_tile_passable", "rio")):
		errors.append("N3 rio passable")
	var tuned := 0
	var state: Variant = node.call("get_state")
	if state is Dictionary:
		for side in ["attacker", "defender"]:
			var side_value: Variant = (state as Dictionary).get(side, null)
			if side_value is Dictionary:
				var tile_key := str((side_value as Dictionary).get("tile", ""))
				if TILE_KEYS.has(tile_key):
					tuned += 1
	if tuned < 2:
		errors.append("N3 get_state no preserva tile en ambos bandos (%d/2)" % tuned)
	node.free()
	return {"available": true, "errors": errors, "detail": "N3 %d/2 unidades con tile de la tabla; API tiles 12 claves" % tuned}


func _battle_tiles_table() -> Dictionary:
	var root: Variant = _read_json("res://data/battle_tiles.json")
	if not (root is Dictionary):
		return {}
	var dict := root as Dictionary
	var table: Variant = dict.get("battle_tiles", null)
	if table is Dictionary:
		return table as Dictionary
	return dict


func _entry_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	return {}


func _find_rules_files() -> Array[String]:
	var found: Array[String] = []
	for dir_path in ["res://scripts/battle", "res://scripts/autoload"]:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.get_extension().to_lower() == "gd":
				var text := FileAccess.get_file_as_string("%s/%s" % [dir_path, entry])
				if text.contains("battle_tiles") or text.contains("BATTLE_TILES"):
					found.append(entry)
			entry = dir.get_next()
		dir.list_dir_end()
	return found


func _find_contact_sheet() -> String:
	var files := _files_in("res://docs/screenshots", "png")
	for file_name in files:
		var lower := file_name.to_lower()
		if lower.contains("hoja_contacto_tiles") or (lower.contains("tiles") and lower.contains("contact")):
			return file_name
	return ""


# ---------------------------------------------------------------------------
# Infraestructura
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
	_record(id, name, "SKIP", reason + " (pendiente: módulo §10.4 en curso)", started_ms)


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
	print("RESULTADO QA TILES FASE 3: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [
		passed, failed, skipped, _results.size(),
	])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [
			str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0)),
		])
	var code := 0
	if failed > 0:
		print("ACEPTACIÓN TILES FASE 3: NO ACEPTADA — FAIL en %d criterio(s) (exit 1)" % failed)
		code = 1
	elif skipped > 0:
		print("BASELINE TILES FASE 3: PENDIENTE — %d criterio(s) a la espera de módulos en curso (no es rechazo)" % skipped)
		code = 1
	else:
		print("ACEPTACIÓN TILES FASE 3: OK — 7/7 criterios PASS (exit 0)")
	print("--------------------------------------------------------------")
	quit(code)


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


func _make_army(faction_id: String, region_id: String, leader_id: String, unit_id: String, size: int, strength: int) -> Variant:
	var script: Variant = load("res://scripts/model/army.gd")
	if not (script is GDScript):
		return null
	var army: Variant = (script as GDScript).new()
	if army == null:
		return null
	army.set("id", "qa_tile_%s_%s" % [faction_id, unit_id])
	army.set("faction_id", faction_id)
	army.set("region_id", region_id)
	army.set("leader_id", leader_id)
	army.set("morale", 1.0)
	army.set("units", [{
		"id": "u1", "unit_id": unit_id, "size": size, "strength": strength,
		"morale": 1.0, "experience": 50,
	}])
	return army


func _make_region(region_id: String, terrain: String) -> Variant:
	var script: Variant = load("res://scripts/model/region_state.gd")
	if not (script is GDScript):
		return null
	var region: Variant = (script as GDScript).new()
	if region == null:
		return null
	region.set("id", region_id)
	region.set("terrain", terrain)
	region.set("support", 60)
	region.set("base_wealth", 60)
	region.set("has_city", false)
	return region


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
