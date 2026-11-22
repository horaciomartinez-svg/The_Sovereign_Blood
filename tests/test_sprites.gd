extends RefCounted
## Tests de la integración de sprites Fase 3 (§10.3, contrato fase3 §2-§3,
## D-040/D-042): datos `sprite_sheet`, orientación/mirroring, ciclo de marcha y
## proyectiles N2/N3 (virote/flecha/piedra) sin RNG de combate.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const BattleSpritesScript = preload("res://scripts/battle/battle_sprites.gd")

const CORE_UNITS: Array[String] = [
	"militia_spearman", "swiss_pikeman", "crossbowmen",
	"longbowman", "men_at_arms", "light_horseman",
]
const TALL_UNITS: Array[String] = ["men_at_arms", "light_horseman"]
const REGION: String = "region_normandia"

var _projectile_events: int = 0


func _on_projectile(_payload: Dictionary) -> void:
	_projectile_events += 1


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("sprites")
	_check_unit_data(runner, h)
	_check_fallback(runner, h)
	_check_animation_helpers(runner)
	_check_tactical_animation(runner, h)
	_check_tactical_projectile(runner, h)
	_check_close_combat_projectiles(runner, h)
	_check_rng_untouched(runner, h)


func _check_unit_data(runner: TestRunnerScript, h: HarnessScript) -> void:
	var all_units: Array[String] = h.unit_ids()
	runner.check("units.json carga las 17 unidades", all_units.size() == 17, str(all_units.size()))
	for unit_id in CORE_UNITS:
		var definition: Dictionary = h.unit_definition(unit_id)
		runner.check("existe la unidad núcleo %s" % unit_id, not definition.is_empty())
		var sprite: Dictionary = SafeDict.as_dict(definition.get("sprite_sheet", null))
		runner.check("sprite_sheet presente en %s" % unit_id, not sprite.is_empty())
		if sprite.is_empty():
			continue
		var frames: Array = SafeDict.as_array(sprite.get("frames", null))
		runner.check_eq("3 frames en %s" % unit_id, 3, frames.size())
		var expected_size: Array = [64, 80] if TALL_UNITS.has(unit_id) else [64, 64]
		var size_value: Array = _int_array(SafeDict.as_array(sprite.get("size", null)))
		runner.check_eq("size correcto en %s" % unit_id, JSON.stringify(expected_size), JSON.stringify(size_value))
		runner.check_eq("anchor bottom_center en %s" % unit_id, "bottom_center",
			SafeDict.as_string(sprite.get("anchor"), ""))
		runner.check_eq("facing E en %s" % unit_id, "E", SafeDict.as_string(sprite.get("facing"), ""))
		var anim: Dictionary = SafeDict.as_dict(sprite.get("anim", null))
		runner.check_eq("anim.march [0,1,2] en %s" % unit_id, "[0,1,2]",
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("march", null)))))
		runner.check_eq("anim.fps 6 en %s" % unit_id, 6, SafeDict.as_int(anim.get("fps"), 0))
		runner.check("anim.loop true en %s" % unit_id, SafeDict.as_bool(anim.get("loop"), false))
		var frames_exist: bool = true
		var frames_load: bool = true
		var dimensions_ok: bool = true
		var texture_ok: bool = true
		for frame_value in frames:
			var frame_path: String = str(frame_value)
			if not frame_path.begins_with("res://assets/art/sprites/units/"):
				frames_exist = false
			if not ResourceLoader.exists(frame_path):
				frames_exist = false
				continue
			var resource: Variant = load(frame_path)
			if resource == null:
				frames_load = false
				continue
			var texture: Texture2D = resource as Texture2D
			if texture == null:
				texture_ok = false
				continue
			if texture.get_width() != int(expected_size[0]) or texture.get_height() != int(expected_size[1]):
				dimensions_ok = false
		runner.check("frames existen para %s (ResourceLoader.exists)" % unit_id, frames_exist)
		runner.check("frames cargan para %s (load)" % unit_id, frames_load)
		runner.check("texturas válidas para %s" % unit_id, texture_ok)
		runner.check("dimensiones %dx%d para %s" % [int(expected_size[0]), int(expected_size[1]), unit_id],
			dimensions_ok)


func _check_fallback(runner: TestRunnerScript, h: HarnessScript) -> void:
	var all_units: Array[String] = h.unit_ids()
	var fallback_count: int = 0
	for unit_id in all_units:
		if CORE_UNITS.has(unit_id):
			continue
		fallback_count += 1
		runner.check("sin sprite_sheet: %s" % unit_id, h.unit_sprite(unit_id).is_empty())
	runner.check_eq("11 unidades de fallback", 11, fallback_count)
	runner.check_eq("frame_path vacío sin sprite", "", BattleSpritesScript.frame_path({}, 0))
	# Unidad sin sprite en batalla: get_units devuelve sprite_sheet null y ruta vacía.
	var ids: Array[String] = _prepare_battle(h)
	_add_fallback_unit_to_army(h, ids[0])
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("battle con unidad fallback", false)
		return
	var fallback_seen: bool = false
	for unit_value in node.call("get_units"):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") != "mounted_sergeants":
			continue
		fallback_seen = true
		runner.check("fallback: sprite_sheet null", unit.get("sprite_sheet") == null)
		runner.check_eq("fallback: sprite_frame_path vacío", "", SafeDict.as_string(unit.get("sprite_frame_path"), "x"))
	runner.check("la unidad de fallback aparece en la batalla", fallback_seen)
	node.free()


func _check_animation_helpers(runner: TestRunnerScript) -> void:
	runner.check_eq("facing E", "E", BattleSpritesScript.facing_from_delta(1, 0))
	runner.check_eq("facing W", "W", BattleSpritesScript.facing_from_delta(-1, 0))
	runner.check_eq("facing S", "S", BattleSpritesScript.facing_from_delta(0, 1))
	runner.check_eq("facing N", "N", BattleSpritesScript.facing_from_delta(0, -1))
	runner.check_eq("facing SE", "SE", BattleSpritesScript.facing_from_delta(1, -1))
	runner.check_eq("facing SW", "SW", BattleSpritesScript.facing_from_delta(-1, 1))
	var mirror_ok: bool = BattleSpritesScript.mirror_for("W") \
		and BattleSpritesScript.mirror_for("SW") \
		and BattleSpritesScript.mirror_for("NW") \
		and BattleSpritesScript.mirror_for("N")
	var base_ok: bool = not BattleSpritesScript.mirror_for("E") \
		and not BattleSpritesScript.mirror_for("SE") \
		and not BattleSpritesScript.mirror_for("S")
	runner.check("mirroring W/SW/NW/N", mirror_ok)
	runner.check("base E/SE/S sin espejo", base_ok)
	var all_facings_valid: bool = true
	for facing in ["E", "SE", "S", "SW", "W", "NW", "N"]:
		if not BattleSpritesScript.is_valid_facing(facing):
			all_facings_valid = false
	runner.check("7 orientaciones válidas", all_facings_valid)
	runner.check("NE no es una orientación válida", not BattleSpritesScript.is_valid_facing("NE"))
	var sheet: Dictionary = {"frames": ["a.png", "b.png", "c.png"], "anim": {"march": [0, 1, 2], "fps": 6, "loop": true}}
	runner.check_eq("frame_path 0", "a.png", BattleSpritesScript.frame_path(sheet, 0))
	runner.check_eq("frame_path 2", "c.png", BattleSpritesScript.frame_path(sheet, 2))
	runner.check_eq("frame_path da la vuelta", "a.png", BattleSpritesScript.frame_path(sheet, 3))
	runner.check_eq("march_frame en reposo = 0", 0, BattleSpritesScript.march_frame(sheet, 500.0, false))
	runner.check_eq("march_frame 0 ms = 0", 0, BattleSpritesScript.march_frame(sheet, 0.0, true))
	runner.check_eq("march_frame 200 ms = 1", 1, BattleSpritesScript.march_frame(sheet, 200.0, true))
	runner.check_eq("march_frame 400 ms = 2", 2, BattleSpritesScript.march_frame(sheet, 400.0, true))
	runner.check_eq("march_frame 600 ms vuelve a 0", 0, BattleSpritesScript.march_frame(sheet, 600.0, true))
	# Proyectiles
	var virote: Dictionary = BattleSpritesScript.projectile_for_unit("crossbowmen")
	runner.check_eq("virote tipo", "virote", SafeDict.as_string(virote.get("type"), ""))
	runner.check_eq("virote 350 ms", 350, SafeDict.as_int(virote.get("duration_ms"), 0))
	runner.check_eq("virote arco 24", 24.0, SafeDict.as_float(virote.get("arc_height"), 0.0))
	var flecha: Dictionary = BattleSpritesScript.projectile_for_unit("longbowman")
	runner.check_eq("flecha tipo", "flecha", SafeDict.as_string(flecha.get("type"), ""))
	runner.check_eq("flecha 500 ms", 500, SafeDict.as_int(flecha.get("duration_ms"), 0))
	runner.check_eq("flecha arco 40", 40.0, SafeDict.as_float(flecha.get("arc_height"), 0.0))
	var piedra: Dictionary = BattleSpritesScript.projectile_for_unit("bombarda")
	runner.check_eq("piedra tipo", "piedra", SafeDict.as_string(piedra.get("type"), ""))
	runner.check_eq("piedra 700 ms", 700, SafeDict.as_int(piedra.get("duration_ms"), 0))
	runner.check_eq("piedra arco 56", 56.0, SafeDict.as_float(piedra.get("arc_height"), 0.0))
	runner.check("sin proyectil para infantería", BattleSpritesScript.projectile_for_unit("militia_spearman").is_empty())
	var sprite_ok: bool = true
	for projectile_spec in [virote, flecha, piedra]:
		var sprite_path: String = SafeDict.as_string(SafeDict.as_dict(projectile_spec).get("sprite"), "")
		if not ResourceLoader.exists(sprite_path):
			sprite_ok = false
	runner.check("los 3 sprites de proyectil existen", sprite_ok)
	# Trayectoria paramétrica: x lineal, arco senoidal.
	var start_point: Dictionary = {"x": 0.0, "y": 0.0}
	var end_point: Dictionary = {"x": 100.0, "y": 0.0}
	var position_start: Dictionary = BattleSpritesScript.projectile_position(start_point, end_point, 40.0, 0.0)
	var position_mid: Dictionary = BattleSpritesScript.projectile_position(start_point, end_point, 40.0, 0.5)
	var position_end: Dictionary = BattleSpritesScript.projectile_position(start_point, end_point, 40.0, 1.0)
	runner.check_eq("t=0 x", 0.0, SafeDict.as_float(position_start.get("x"), -1.0))
	runner.check_eq("t=0.5 x intermedio", 50.0, SafeDict.as_float(position_mid.get("x"), -1.0))
	runner.check_eq("t=0.5 arco arriba", -40.0, SafeDict.as_float(position_mid.get("y"), 1.0))
	runner.check_eq("t=1 x final", 100.0, SafeDict.as_float(position_end.get("x"), -1.0))
	runner.check_eq("t=1 y final", 0.0, SafeDict.as_float(position_end.get("y"), 1.0))


func _check_tactical_animation(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("launch_tactical para animación", false)
		return
	var units: Array = node.call("get_units")
	var longbow_id: String = ""
	var longbow_q: int = 0
	var longbow_r: int = 0
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") == "longbowman":
			longbow_id = SafeDict.as_string(unit.get("id"), "")
			longbow_q = SafeDict.as_int(unit.get("q"), 0)
			longbow_r = SafeDict.as_int(unit.get("r"), 0)
	runner.check("hay arquero largo para animar", longbow_id != "")
	if longbow_id == "":
		node.free()
		return
	var archer: Dictionary = SafeDict.as_dict(node.call("get_unit", longbow_id))
	for field in ["sprite_sheet", "facing", "mirror", "moving", "march_frame", "sprite_frame_path"]:
		runner.check("la unidad expone '%s'" % field, archer.has(field))
	var sprite: Dictionary = SafeDict.as_dict(archer.get("sprite_sheet", null))
	runner.check("el arquero tiene sprite_sheet", not sprite.is_empty())
	runner.check_eq("orientación inicial E", "E", SafeDict.as_string(archer.get("facing"), ""))
	runner.check("sin espejo inicial", not SafeDict.as_bool(archer.get("mirror"), true))
	runner.check("en reposo inicial", not SafeDict.as_bool(archer.get("moving"), true))
	runner.check_eq("march_frame en reposo 0", 0, SafeDict.as_int(archer.get("march_frame"), -1))
	var first_frame: String = SafeDict.as_string(archer.get("sprite_frame_path"), "")
	runner.check("sprite_frame_path apunta a un frame real", first_frame.ends_with("_march_1.png")
		and ResourceLoader.exists(first_frame), first_frame)
	# Moverse al oeste debe espejar el sprite.
	var west_hex: Dictionary = {}
	for hex_value in node.call("get_reachable_hexes", longbow_id):
		var hex: Dictionary = SafeDict.as_dict(hex_value)
		if SafeDict.as_int(hex.get("q"), 0) == longbow_q - 1 and SafeDict.as_int(hex.get("r"), 0) == longbow_r:
			west_hex = hex
			break
	if not west_hex.is_empty():
		var moved: bool = bool(node.call("move_unit", longbow_id,
			SafeDict.as_int(west_hex.get("q"), 0), SafeDict.as_int(west_hex.get("r"), 0)))
		runner.check("la unidad se mueve al oeste", moved)
		var moved_unit: Dictionary = SafeDict.as_dict(node.call("get_unit", longbow_id))
		runner.check_eq("facing W tras moverse al oeste", "W", SafeDict.as_string(moved_unit.get("facing"), ""))
		runner.check("mirror true con facing W", SafeDict.as_bool(moved_unit.get("mirror"), false))
		runner.check("moving true tras moverse", SafeDict.as_bool(moved_unit.get("moving"), false))
		node.call("tick_animation", 200.0)
		var animated: Dictionary = SafeDict.as_dict(node.call("get_unit", longbow_id))
		runner.check_eq("march_frame 1 a 200 ms (6 fps)", 1, SafeDict.as_int(animated.get("march_frame"), -1))
		runner.check("sprite_frame_path cambia al ciclo de marcha",
			SafeDict.as_string(animated.get("sprite_frame_path"), "").ends_with("_march_2.png"),
			SafeDict.as_string(animated.get("sprite_frame_path"), ""))
		node.call("tick_animation", 400.0)
		var looped: Dictionary = SafeDict.as_dict(node.call("get_unit", longbow_id))
		runner.check_eq("ciclo de marcha con loop (600 ms → frame 0)", 0,
			SafeDict.as_int(looped.get("march_frame"), -1))
	else:
		runner.check("hay un hex al oeste alcanzable", false)
	node.free()


func _check_tactical_projectile(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		return
	var units: Array = node.call("get_units")
	var archer_id: String = ""
	var crossbow_id: String = ""
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") == "longbowman":
			archer_id = SafeDict.as_string(unit.get("id"), "")
		if SafeDict.as_string(unit.get("unit_id"), "") == "crossbowmen":
			crossbow_id = SafeDict.as_string(unit.get("id"), "")
	runner.check("hay arquero y ballestero", archer_id != "" and crossbow_id != "")
	if archer_id == "" or crossbow_id == "":
		node.free()
		return
	# Coloca ambos a distancia 2 (blanco: fuego a distancia).
	var attacker_internal: Dictionary = node.call("_find_unit", archer_id)
	attacker_internal["q"] = 0
	attacker_internal["r"] = 0
	attacker_internal["orders_left"] = 1
	var defender_internal: Dictionary = node.call("_find_unit", crossbow_id)
	defender_internal["q"] = 2
	defender_internal["r"] = 0
	_projectile_events = 0
	node.connect("projectile_fired", Callable(self, "_on_projectile"))
	var attack: Dictionary = SafeDict.as_dict(node.call("attack_unit", archer_id, crossbow_id))
	runner.check("ataque a distancia válido", bool(attack.get("ok")), str(attack))
	var projectiles: Array = node.call("get_projectiles")
	runner.check_eq("se dispara 1 proyectil flecha", 1, projectiles.size())
	runner.check_eq("se emite la señal projectile_fired", 1, _projectile_events)
	node.disconnect("projectile_fired", Callable(self, "_on_projectile"))
	if projectiles.size() == 1:
		var projectile: Dictionary = SafeDict.as_dict(projectiles[0])
		runner.check_eq("tipo flecha", "flecha", SafeDict.as_string(projectile.get("type"), ""))
		runner.check_eq("duración 500 ms", 500, SafeDict.as_int(projectile.get("duration_ms"), 0))
		runner.check_eq("arco 40 px", 40.0, SafeDict.as_float(projectile.get("arc_height"), 0.0))
		runner.check("ballistic true", SafeDict.as_bool(projectile.get("ballistic"), false))
		runner.check_eq("sprite de flecha", "res://assets/art/sprites/projectiles/proyectil_flecha.png",
			SafeDict.as_string(projectile.get("sprite"), ""))
		var from_point: Dictionary = SafeDict.as_dict(projectile.get("from", null))
		var to_point: Dictionary = SafeDict.as_dict(projectile.get("to", null))
		runner.check_eq("from q=0", 0, SafeDict.as_int(from_point.get("q"), -1))
		runner.check_eq("to q=2", 2, SafeDict.as_int(to_point.get("q"), -1))
		runner.check_eq("t inicial 0", 0.0, SafeDict.as_float(projectile.get("t"), -1.0))
		runner.check("el sprite del proyectil existe",
			ResourceLoader.exists(SafeDict.as_string(projectile.get("sprite"), "")))
		node.call("tick_animation", 250.0)
		var mid_projectiles: Array = node.call("get_projectiles")
		runner.check_eq("a 250 ms el proyectil sigue activo", 1, mid_projectiles.size())
		if mid_projectiles.size() == 1:
			var mid: Dictionary = SafeDict.as_dict(mid_projectiles[0])
			runner.check_eq("t = 0.5 a mitad de vuelo", 0.5, SafeDict.as_float(mid.get("t"), -1.0))
			var mid_position: Dictionary = SafeDict.as_dict(mid.get("position", null))
			runner.check_eq("x intermedia (72)", 72.0, SafeDict.as_float(mid_position.get("x"), -1.0))
			runner.check_eq("y con arco (-40)", -40.0, SafeDict.as_float(mid_position.get("y"), 1.0))
		node.call("tick_animation", 300.0)
		runner.check_eq("a 550 ms el proyectil ya no está activo", 0, (node.call("get_projectiles") as Array).size())
		runner.check_eq("animation_ms acumulado", 550.0, float(node.call("get_animation_time_ms")))
	node.free()


func _check_close_combat_projectiles(runner: TestRunnerScript, h: HarnessScript) -> void:
	# Duelo ballesta vs arco: virote y flecha, con sprites core.
	h.new_game("england", 1337)
	var duel: Node = h.launch_close_combat(
		_unit("crossbowmen", "england", 1200, 8, 80),
		_unit("longbowman", "france", 1000, 9, 70))
	if duel == null:
		runner.check("launch_close_combat para proyectiles", false)
		return
	var state_before: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	runner.check("get_state incluye projectiles", state_before.has("projectiles"))
	runner.check("get_state incluye animation_ms", state_before.has("animation_ms"))
	var attacker_unit: Dictionary = SafeDict.as_dict(state_before.get("attacker", null))
	runner.check_eq("atacante con sprite core", "crossbowmen", SafeDict.as_string(attacker_unit.get("unit_id"), ""))
	runner.check("atacante tiene sprite_sheet", not SafeDict.as_dict(attacker_unit.get("sprite_sheet", null)).is_empty())
	runner.check_eq("atacante mira a E", "E", SafeDict.as_string(attacker_unit.get("facing"), ""))
	var defender_unit: Dictionary = SafeDict.as_dict(state_before.get("defender", null))
	runner.check_eq("defensor mira a W", "W", SafeDict.as_string(defender_unit.get("facing"), ""))
	runner.check("defensor con mirror", SafeDict.as_bool(defender_unit.get("mirror"), false))
	_projectile_events = 0
	duel.connect("projectile_fired", Callable(self, "_on_projectile"))
	var outcome: Dictionary = SafeDict.as_dict(duel.call("auto_resolve"))
	duel.disconnect("projectile_fired", Callable(self, "_on_projectile"))
	var projectiles: Array = duel.call("get_projectiles")
	runner.check("el duelo dispara proyectiles", projectiles.size() >= 2, str(projectiles.size()))
	runner.check_eq("cada proyectil emitió señal", projectiles.size(), _projectile_events)
	var types: Dictionary = {}
	var sprites_ok: bool = true
	for projectile_value in projectiles:
		var projectile: Dictionary = SafeDict.as_dict(projectile_value)
		types[SafeDict.as_string(projectile.get("type"), "")] = true
		if not ResourceLoader.exists(SafeDict.as_string(projectile.get("sprite"), "")):
			sprites_ok = false
		runner.check_eq("space normalizado en N3", "normalized", SafeDict.as_string(projectile.get("space"), ""))
	runner.check("el duelo incluye virote", types.has("virote"), str(types.keys()))
	runner.check("el duelo incluye flecha", types.has("flecha"), str(types.keys()))
	runner.check("sprites de proyectil N3 existen", sprites_ok)
	runner.check("el resultado N3 sigue siendo nivel 3", SafeDict.as_int(outcome.get("level"), 0) == 3)
	duel.call("tick_animation", 1000.0)
	runner.check_eq("los proyectiles del duelo expiran", 0, (duel.call("get_projectiles") as Array).size())
	duel.free()
	# Bombarda (unidad SIN sprite): piedra y fallback heráldico.
	h.new_game("england", 1337)
	var siege: Node = h.launch_close_combat(
		_unit("bombarda", "england", 300, 18, 70),
		_unit("men_at_arms", "france", 900, 12, 70))
	if siege == null:
		return
	var siege_state: Dictionary = SafeDict.as_dict(siege.call("get_state"))
	var siege_attacker: Dictionary = SafeDict.as_dict(siege_state.get("attacker", null))
	runner.check("bombarda sin sprite (fallback)", siege_attacker.get("sprite_sheet") == null)
	runner.check_eq("bombarda con sprite_frame_path vacío", "",
		SafeDict.as_string(siege_attacker.get("sprite_frame_path"), "x"))
	siege.call("auto_resolve")
	var siege_projectiles: Array = siege.call("get_projectiles")
	var stone_seen: bool = false
	for projectile_value in siege_projectiles:
		var projectile: Dictionary = SafeDict.as_dict(projectile_value)
		if SafeDict.as_string(projectile.get("type"), "") != "piedra":
			continue
		stone_seen = true
		runner.check_eq("piedra 700 ms", 700, SafeDict.as_int(projectile.get("duration_ms"), 0))
		runner.check_eq("piedra arco 56", 56.0, SafeDict.as_float(projectile.get("arc_height"), 0.0))
		runner.check_eq("sprite de piedra", "res://assets/art/sprites/projectiles/proyectil_piedra.png",
			SafeDict.as_string(projectile.get("sprite"), ""))
	runner.check("la bombarda dispara piedra", stone_seen)
	siege.free()


func _check_rng_untouched(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		return
	var rng_before: String = JSON.stringify(h.to_dict().get("rng", null))
	node.call("tick_animation", 1000.0)
	var units: Array = node.call("get_units")
	var archer_id: String = ""
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") == "longbowman":
			archer_id = SafeDict.as_string(unit.get("id"), "")
	var defender_id: String = ""
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == "defender":
			defender_id = SafeDict.as_string(unit.get("id"), "")
			break
	if archer_id != "" and defender_id != "":
		var attacker_internal: Dictionary = node.call("_find_unit", archer_id)
		var defender_internal: Dictionary = node.call("_find_unit", defender_id)
		node.call("_fire_projectile", attacker_internal, defender_internal)
	var rng_after: String = JSON.stringify(h.to_dict().get("rng", null))
	runner.check_eq("la animación/proyectiles NO consumen RNG", rng_before, rng_after)
	node.free()


# --- helpers -------------------------------------------------------------

## JSON carga los enteros como float; normaliza para comparar arrays de ints.
func _int_array(values: Array) -> Array:
	var result: Array = []
	for value in values:
		result.append(int(value))
	return result


func _unit(unit_id: String, faction_id: String, size: int, strength: int, command: int) -> Dictionary:
	return {
		"id": "%s_%s" % [faction_id, unit_id],
		"faction": faction_id,
		"unit_id": unit_id,
		"size": size,
		"strength": strength,
		"morale": 1.0,
		"experience": 50,
		"commander_stat": command,
		"terrain": "plains",
	}


func _prepare_battle(h: HarnessScript) -> Array[String]:
	h.new_game("england", 1337)
	h.recruit("england", "region_londres", "longbowman", 1600)
	h.recruit("england", "region_londres", "men_at_arms", 400)
	h.recruit("france", REGION, "men_at_arms", 800)
	return [
		_army_in(h, "england", "region_londres"),
		_army_in(h, "france", REGION),
		REGION,
	]


func _launch(h: HarnessScript, ids: Array[String]) -> Node:
	var attacker_model: Variant = h.get_army_model(ids[0])
	var defender_model: Variant = h.get_army_model(ids[1])
	var region_model: Variant = h.get_region_model(ids[2])
	if attacker_model == null or defender_model == null or region_model == null:
		return null
	return h.launch_tactical(attacker_model, defender_model, region_model)


func _army_in(h: HarnessScript, faction_id: String, region_id: String) -> String:
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return str(army_id)
	return ""


## Añade al ejército una unidad SIN sprite para probar el fallback heráldico.
func _add_fallback_unit_to_army(h: HarnessScript, army_id: String) -> void:
	var armies: Dictionary = h.armies()
	var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
	if army.is_empty():
		return
	var units_value: Array = SafeDict.as_array(army.get("units", null))
	units_value.append({
		"id": "synthetic_fallback",
		"unit_id": "mounted_sergeants",
		"size": 300,
		"strength": 8,
		"morale": 1.0,
		"experience": 0,
	})
	army["units"] = units_value
