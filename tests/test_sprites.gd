extends RefCounted
## Tests de la integración de sprites Fase 3 v2 (§10.3, contrato fase3 §2-§3 y
## addendum 2.1, D-044/D-047/D-048): 17/17 hojas, orientación/mirroring, ciclo
## de marcha y proyectiles N2/N3 (virote/flecha/piedra) sin RNG de combate.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const BattleSpritesScript = preload("res://scripts/battle/battle_sprites.gd")

const EXPECTED_UNIT_COUNT: int = 17
const CAVALRY_UNITS: Array[String] = [
	"men_at_arms", "light_horseman", "mounted_sergeants",
	"mamluk", "teutonic_knights", "steppe_cavalry",
]
const PANORAMIC_UNITS: Array[String] = ["bombarda", "hussite_war_wagon"]
## D-065: 7 unidades a distancia/artillería con 15 frames (attack 6 cuadros).
const RANGED_UNITS: Array[String] = [
	"janissary", "arquebusier", "crossbowmen", "longbowman",
	"steppe_cavalry", "bombarda", "hussite_war_wagon",
]
const REGION: String = "region_normandia"

var _projectile_events: int = 0


func _on_projectile(_payload: Dictionary) -> void:
	_projectile_events += 1


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("sprites")
	_check_unit_data(runner, h)
	_check_fallback(runner, h)
	_check_animation_helpers(runner)
	_check_animation_state_helpers(runner, h)
	_check_tactical_animation(runner, h)
	_check_combat_animation_states(runner, h)
	_check_tactical_projectile(runner, h)
	_check_close_combat_projectiles(runner, h)
	_check_rng_untouched(runner, h)


func _check_unit_data(runner: TestRunnerScript, h: HarnessScript) -> void:
	var all_units: Array[String] = h.unit_ids()
	runner.check("units.json carga las 17 unidades", all_units.size() == EXPECTED_UNIT_COUNT,
		str(all_units.size()))
	var sprite_sheets_present: int = 0
	var total_frames: int = 0
	for unit_id in all_units:
		var definition: Dictionary = h.unit_definition(unit_id)
		runner.check("existe la unidad %s" % unit_id, not definition.is_empty())
		var sprite: Dictionary = SafeDict.as_dict(definition.get("sprite_sheet", null))
		runner.check("sprite_sheet presente en %s" % unit_id, not sprite.is_empty())
		if sprite.is_empty():
			continue
		sprite_sheets_present += 1
		var frames: Array = SafeDict.as_array(sprite.get("frames", null))
		var ranged: bool = RANGED_UNITS.has(unit_id)
		var expected_frame_count: int = 15 if ranged else 13
		runner.check_eq("%d frames en %s (D-065)" % [expected_frame_count, unit_id],
			expected_frame_count, frames.size())
		total_frames += frames.size()
		var expected_size: Array = _expected_size(unit_id)
		var size_value: Array = _int_array(SafeDict.as_array(sprite.get("size", null)))
		runner.check_eq("size %s en %s" % [JSON.stringify(expected_size), unit_id],
			JSON.stringify(expected_size), JSON.stringify(size_value))
		runner.check_eq("anchor bottom_center en %s" % unit_id, "bottom_center",
			SafeDict.as_string(sprite.get("anchor"), ""))
		runner.check_eq("facing E en %s" % unit_id, "E", SafeDict.as_string(sprite.get("facing"), ""))
		var anim: Dictionary = SafeDict.as_dict(sprite.get("anim", null))
		runner.check_eq("anim.march [0,1,2] en %s" % unit_id, "[0,1,2]",
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("march", null)))))
		runner.check_eq("anim.idle [3,4] en %s" % unit_id, "[3,4]",
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("idle", null)))))
		var expected_attack: String = "[5,6,7,8,9,10]" if ranged else "[5,6,7,8]"
		runner.check_eq("anim.attack %s en %s" % [expected_attack, unit_id], expected_attack,
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("attack", null)))))
		var impact_base: int = 11 if ranged else 9
		runner.check_eq("anim.impact [%d,%d] en %s" % [impact_base, impact_base + 1, unit_id],
			"[%d,%d]" % [impact_base, impact_base + 1],
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("impact", null)))))
		var death_base: int = 13 if ranged else 11
		runner.check_eq("anim.death [%d,%d] en %s" % [death_base, death_base + 1, unit_id],
			"[%d,%d]" % [death_base, death_base + 1],
			JSON.stringify(_int_array(SafeDict.as_array(anim.get("death", null)))))
		runner.check("sin clave 'hit' obsoleta en %s" % unit_id, not anim.has("hit"))
		runner.check_eq("anim.fps 6 en %s" % unit_id, 6, SafeDict.as_int(anim.get("fps"), 0))
		runner.check_eq("anim.fps_attack 9 en %s" % unit_id, 9, SafeDict.as_int(anim.get("fps_attack"), 0))
		runner.check_eq("anim.fps_impact 8 en %s" % unit_id, 8, SafeDict.as_int(anim.get("fps_impact"), 0))
		runner.check_eq("anim.fps_death 6 en %s" % unit_id, 6, SafeDict.as_int(anim.get("fps_death"), 0))
		runner.check("anim.loop true en %s" % unit_id, SafeDict.as_bool(anim.get("loop"), false))
		runner.check("anim.death_hold true en %s" % unit_id, SafeDict.as_bool(anim.get("death_hold"), false))
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
	runner.check_eq("17/17 sprite_sheet válidos", EXPECTED_UNIT_COUNT, sprite_sheets_present)
	runner.check_eq("235 frames de producción (10x13 + 7x15)", 235, total_frames)


func _check_fallback(runner: TestRunnerScript, h: HarnessScript) -> void:
	var all_units: Array[String] = h.unit_ids()
	var without_sprite: int = 0
	for unit_id in all_units:
		if h.unit_sprite(unit_id).is_empty():
			without_sprite += 1
	runner.check_eq("17/17 unidades con sprite_sheet en datos (sin fallback real)", 0, without_sprite)
	# El fallback se prueba con una unidad SINTÉTICA sin sprite (addendum 2.1).
	runner.check("unidad sintética sin sprite en DataLoader", h.unit_sprite("sintetica_sin_sprite").is_empty())
	runner.check_eq("frame_path vacío sin sprite", "", BattleSpritesScript.frame_path({}, 0))
	# N2: unidad sintética sin sprite en la batalla → sprite_sheet null y ruta "".
	var ids: Array[String] = _prepare_battle(h)
	_add_fallback_unit_to_army(h, ids[0])
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("battle con unidad fallback", false)
		return
	var fallback_seen: bool = false
	for unit_value in node.call("get_units"):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") != "sintetica_sin_sprite":
			continue
		fallback_seen = true
		runner.check("fallback: sprite_sheet null", unit.get("sprite_sheet") == null)
		runner.check_eq("fallback: sprite_frame_path vacío", "", SafeDict.as_string(unit.get("sprite_frame_path"), "x"))
	runner.check("la unidad sintética de fallback aparece en la batalla", fallback_seen)
	node.free()
	# N3: misma unidad sintética en el duelo → fallback sin huecos.
	h.new_game("england", 1337)
	var duel: Node = h.launch_close_combat(
		_unit("sintetica_sin_sprite", "england", 300, 6, 60),
		_unit("men_at_arms", "france", 300, 12, 60))
	if duel == null:
		return
	var duel_state: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var duel_attacker: Dictionary = SafeDict.as_dict(duel_state.get("attacker", null))
	runner.check("fallback N3: sprite_sheet null", duel_attacker.get("sprite_sheet") == null)
	runner.check_eq("fallback N3: sprite_frame_path vacío", "",
		SafeDict.as_string(duel_attacker.get("sprite_frame_path"), "x"))
	duel.free()


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
	# D-048: jenízaro y caballería de estepa disparan flecha (500 ms/40).
	var janissary_shot: Dictionary = BattleSpritesScript.projectile_for_unit("janissary")
	runner.check_eq("janissary flecha", "flecha", SafeDict.as_string(janissary_shot.get("type"), ""))
	runner.check_eq("janissary 500 ms", 500, SafeDict.as_int(janissary_shot.get("duration_ms"), 0))
	var steppe_shot: Dictionary = BattleSpritesScript.projectile_for_unit("steppe_cavalry")
	runner.check_eq("steppe_cavalry flecha", "flecha", SafeDict.as_string(steppe_shot.get("type"), ""))
	runner.check_eq("steppe_cavalry 500 ms", 500, SafeDict.as_int(steppe_shot.get("duration_ms"), 0))
	runner.check_eq("steppe_cavalry arco 40", 40.0, SafeDict.as_float(steppe_shot.get("arc_height"), 0.0))
	runner.check("sin proyectil para infantería", BattleSpritesScript.projectile_for_unit("militia_spearman").is_empty())
	var sprite_ok: bool = true
	for projectile_spec in [virote, flecha, piedra, janissary_shot, steppe_shot]:
		var sprite_path: String = SafeDict.as_string(SafeDict.as_dict(projectile_spec).get("sprite"), "")
		if not ResourceLoader.exists(sprite_path):
			sprite_ok = false
	runner.check("los sprites de proyectil existen", sprite_ok)
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


func _check_animation_state_helpers(runner: TestRunnerScript, h: HarnessScript) -> void:
	var sheet: Dictionary = h.unit_sprite("longbowman")
	runner.check("helpers: hoja de sprites no vacía", not sheet.is_empty())
	runner.check_eq("state_frame_indices march = 3", 3,
		BattleSpritesScript.state_frame_indices(sheet, "march").size())
	runner.check_eq("state_frame_indices idle = 2", 2,
		BattleSpritesScript.state_frame_indices(sheet, "idle").size())
	runner.check_eq("state_frame_indices attack = 6 (ranged, D-065)", 6,
		BattleSpritesScript.state_frame_indices(sheet, "attack").size())
	var melee_sheet: Dictionary = h.unit_sprite("men_at_arms")
	runner.check_eq("state_frame_indices attack = 4 (choque)", 4,
		BattleSpritesScript.state_frame_indices(melee_sheet, "attack").size())
	runner.check_eq("state_frame_indices impact = 2", 2,
		BattleSpritesScript.state_frame_indices(sheet, "impact").size())
	runner.check_eq("state_frame_indices dead = 2", 2,
		BattleSpritesScript.state_frame_indices(sheet, "dead").size())
	runner.check_eq("fps attack = 9", 9.0, BattleSpritesScript.state_fps(sheet, "attack"))
	runner.check_eq("fps impact = 8", 8.0, BattleSpritesScript.state_fps(sheet, "impact"))
	runner.check_eq("fps dead = 6", 6.0, BattleSpritesScript.state_fps(sheet, "dead"))
	runner.check_eq("attack_impact_index = attack_4 (abs 8)", 8,
		BattleSpritesScript.attack_impact_index(sheet))
	runner.check("attack_impact_ms ≈ 333.3",
		absf(BattleSpritesScript.attack_impact_ms(sheet) - 333.3) < 0.3,
		str(BattleSpritesScript.attack_impact_ms(sheet)))
	runner.check("reaction_delay_ms ≈ 444.4 (attack_4 + cuadro)",
		absf(BattleSpritesScript.reaction_delay_ms(sheet) - 444.4) < 0.3,
		str(BattleSpritesScript.reaction_delay_ms(sheet)))
	runner.check("attack frame 0 = attack_1",
		BattleSpritesScript.state_frame_path(sheet, "attack", 0.0).ends_with("_attack_1.png"))
	runner.check("attack a 250 ms = attack_3 (9 fps)",
		BattleSpritesScript.state_frame_path(sheet, "attack", 250.0).ends_with("_attack_3.png"))
	runner.check("attack a 340 ms = attack_4 (disparo/golpe)",
		BattleSpritesScript.state_frame_path(sheet, "attack", 340.0).ends_with("_attack_4.png"))
	runner.check("attack a 600 ms = attack_6 (recoil/recarga)",
		BattleSpritesScript.state_frame_path(sheet, "attack", 600.0).ends_with("_attack_6.png"))
	runner.check("ataque ranged dura 6 cuadros (666.7 ms)",
		absf(BattleSpritesScript.state_duration_ms(sheet, "attack") - 666.7) < 0.3,
		str(BattleSpritesScript.state_duration_ms(sheet, "attack")))
	runner.check("ataque choque dura 4 cuadros (444.4 ms)",
		absf(BattleSpritesScript.state_duration_ms(melee_sheet, "attack") - 444.4) < 0.3)
	runner.check_eq("ataque agotado (1000 ms) vuelve a idle", "idle",
		BattleSpritesScript.state_after_elapsed(sheet, "attack", 1000.0))
	runner.check_eq("impact agotado (300 ms) vuelve a idle", "idle",
		BattleSpritesScript.state_after_elapsed(sheet, "impact", 300.0))
	runner.check_eq("muerte nunca vuelve a idle (death_hold)", "dead",
		BattleSpritesScript.state_after_elapsed(sheet, "dead", 99999.0))
	var idle_info: Dictionary = BattleSpritesScript.animation_frame_info(sheet, "idle", 0.0)
	runner.check("idle en bucle", SafeDict.as_bool(idle_info.get("loop"), false))
	runner.check("idle frame_path = idle_1",
		SafeDict.as_string(idle_info.get("frame_path"), "").ends_with("_idle_1.png"))
	var death_info: Dictionary = BattleSpritesScript.animation_frame_info(sheet, "dead", 5000.0)
	runner.check("death_hold conserva el último cuadro (death_2)",
		SafeDict.as_string(death_info.get("frame_path"), "").ends_with("_death_2.png"))
	runner.check("death no es loop", not SafeDict.as_bool(death_info.get("loop"), true))


func _check_combat_animation_states(runner: TestRunnerScript, h: HarnessScript) -> void:
	# N2: ataque → attack; defensor → hit/dead; transición a idle tras la duración.
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("battle para estados de animación", false)
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
	if archer_id == "" or crossbow_id == "":
		node.free()
		return
	var attacker_internal: Dictionary = node.call("_find_unit", archer_id)
	attacker_internal["q"] = 0
	attacker_internal["r"] = 0
	attacker_internal["orders_left"] = 1
	var defender_internal: Dictionary = node.call("_find_unit", crossbow_id)
	defender_internal["q"] = 2
	defender_internal["r"] = 0
	var attack: Dictionary = SafeDict.as_dict(node.call("attack_unit", archer_id, crossbow_id))
	runner.check("ataque para animación", bool(attack.get("ok")), str(attack))
	runner.check("resultado con attack_impact_ms ≈333,3",
		absf(SafeDict.as_float(attack.get("attack_impact_ms"), 0.0) - 333.3) < 0.3)
	runner.check_eq("resultado con attack_impact_frame = 8 (attack_4)", 8,
		SafeDict.as_int(attack.get("attack_impact_frame"), -1))
	runner.check("resultado con reaction_delay_ms ≈444,4",
		absf(SafeDict.as_float(attack.get("reaction_delay_ms"), 0.0) - 444.4) < 0.3)
	var attacker_after: Dictionary = SafeDict.as_dict(node.call("get_unit", archer_id))
	runner.check_eq("atacante en estado attack", "attack", SafeDict.as_string(attacker_after.get("anim_state"), ""))
	runner.check("atacante en frame de ataque",
		SafeDict.as_string(attacker_after.get("sprite_frame_path"), "").contains("_attack_"))
	var defender_after: Dictionary = SafeDict.as_dict(node.call("get_unit", crossbow_id))
	var pending_reaction: String = SafeDict.as_string(defender_after.get("anim_reaction_state"), "")
	runner.check("N2: reacción impact/dead programada",
		pending_reaction == "impact" or pending_reaction == "dead", pending_reaction)
	runner.check("N2: reaction_at_ms ≈444,4",
		absf(SafeDict.as_float(defender_after.get("anim_reaction_at_ms"), 0.0) - 444.4) < 0.3,
		str(defender_after.get("anim_reaction_at_ms")))
	# attack_4 ocupa 333,3–444,4 ms; después llega impact/death.
	node.call("tick_animation", 350.0)
	var during_impact: Dictionary = SafeDict.as_dict(node.call("get_unit", crossbow_id))
	runner.check("N2: defensor aún no en impact a 350 ms",
		SafeDict.as_string(during_impact.get("anim_state"), "") != "impact")
	node.call("tick_animation", 120.0)
	var defender_reaction: Dictionary = SafeDict.as_dict(node.call("get_unit", crossbow_id))
	var defender_state: String = SafeDict.as_string(defender_reaction.get("anim_state"), "")
	if bool(attack.get("defender_destroyed")):
		runner.check_eq("N2: defensor destruido en estado dead", "dead", defender_state)
	else:
		runner.check("N2: defensor en impact tras attack_4", defender_state == "impact", defender_state)
	node.call("tick_animation", 5000.0)
	var attacker_settled: Dictionary = SafeDict.as_dict(node.call("get_unit", archer_id))
	runner.check_eq("ataque agotado vuelve a idle", "idle",
		SafeDict.as_string(attacker_settled.get("anim_state"), ""))
	node.free()
	# Muerte: unidad a 0 → death + death_hold y aparece en get_dead_units().
	ids = _prepare_battle(h)
	node = _launch(h, ids)
	if node == null:
		return
	units = node.call("get_units")
	archer_id = ""
	crossbow_id = ""
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("unit_id"), "") == "longbowman":
			archer_id = SafeDict.as_string(unit.get("id"), "")
		if SafeDict.as_string(unit.get("unit_id"), "") == "crossbowmen":
			crossbow_id = SafeDict.as_string(unit.get("id"), "")
	if archer_id == "" or crossbow_id == "":
		node.free()
		return
	attacker_internal = node.call("_find_unit", archer_id)
	attacker_internal["q"] = 0
	attacker_internal["r"] = 0
	attacker_internal["orders_left"] = 1
	defender_internal = node.call("_find_unit", crossbow_id)
	defender_internal["q"] = 2
	defender_internal["r"] = 0
	defender_internal["size"] = 0
	var lethal: Dictionary = SafeDict.as_dict(node.call("attack_unit", archer_id, crossbow_id))
	runner.check("ataque letal detectado", bool(lethal.get("defender_destroyed")), str(lethal))
	runner.check_eq("el cadáver aparece en get_dead_units", 1, (node.call("get_dead_units") as Array).size())
	var dead_units: Array = node.call("get_dead_units")
	if dead_units.size() == 1:
		var dead: Dictionary = SafeDict.as_dict(dead_units[0])
		runner.check_eq("cadáver en estado dead", "dead", SafeDict.as_string(dead.get("anim_state"), ""))
		node.call("tick_animation", 5000.0)
		var dead_after: Array = node.call("get_dead_units")
		if dead_after.size() == 1:
			var dead_hold: Dictionary = SafeDict.as_dict(dead_after[0])
			runner.check("death_hold mantiene death_2",
				SafeDict.as_string(dead_hold.get("sprite_frame_path"), "").ends_with("_death_2.png"))
	node.free()
	# N3: ataque de ronda → estado attack y reacción hit/dead.
	h.new_game("england", 1337)
	var duel: Node = h.launch_close_combat(
		_unit("crossbowmen", "england", 300, 8, 70),
		_unit("men_at_arms", "france", 300, 12, 70))
	if duel == null:
		return
	var duel_state: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var duel_attacker: Dictionary = SafeDict.as_dict(duel_state.get("attacker", null))
	runner.check_eq("N3: estado inicial idle", "idle", SafeDict.as_string(duel_attacker.get("anim_state"), ""))
	runner.check("N3: sprite inicial idle_1",
		SafeDict.as_string(duel_attacker.get("sprite_frame_path"), "").ends_with("_idle_1.png"))
	runner.check("N3: attack_impact_ms ≈333,3",
		absf(SafeDict.as_float(duel_attacker.get("attack_impact_ms"), 0.0) - 333.3) < 0.3)
	runner.check("N3: get_animation_state disponible",
		not SafeDict.as_dict(duel.call("get_animation_state", SafeDict.as_string(duel_attacker.get("id"), ""))).is_empty())
	var duel_hand: Array = SafeDict.as_array(SafeDict.as_dict(
		SafeDict.as_dict(duel.call("get_state")).get("hands", null)).get("attacker", null))
	var duel_card: String = "carga" if duel_hand.has("carga") else (str(duel_hand[0]) if not duel_hand.is_empty() else "carga")
	duel.call("play_order", duel_card)
	duel.call("enemy_respond")
	var after_round: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var duel_attacker_after: Dictionary = SafeDict.as_dict(after_round.get("attacker", null))
	var duel_defender: Dictionary = SafeDict.as_dict(after_round.get("defender", null))
	runner.check_eq("N3: atacante en attack durante attack_4", "attack",
		SafeDict.as_string(duel_attacker_after.get("anim_state"), ""))
	runner.check_eq("N3: defensor en attack hasta attack_4 (reacción programada)", "attack",
		SafeDict.as_string(duel_defender.get("anim_state"), ""))
	var n3_pending_reaction: String = SafeDict.as_string(duel_defender.get("anim_reaction_state"), "")
	runner.check("N3: reacción pendiente impact/dead",
		n3_pending_reaction == "impact" or n3_pending_reaction == "dead", n3_pending_reaction)
	runner.check("N3: reaction_at_ms incluye ventana de attack_4 (>333 ms)",
		SafeDict.as_float(duel_defender.get("anim_reaction_at_ms"), 0.0) > 333.0)
	runner.check("N3: reaction_delay_ms ≈444,4 (attack_4 + cuadro)",
		absf(SafeDict.as_float(duel_defender.get("anim_reaction_delay_ms"), 0.0) - 444.4) < 0.3,
		str(duel_defender.get("anim_reaction_delay_ms")))
	# attack_4 debe verse antes de pasar a impact/dead (ventana de ~111 ms).
	duel.call("tick_animation", 350.0)
	var n3_during_impact: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var duel_defender_impact: Dictionary = SafeDict.as_dict(n3_during_impact.get("defender", null))
	var duel_defender_state: String = SafeDict.as_string(duel_defender_impact.get("anim_state"), "")
	runner.check("N3: defensor sigue en attack a 350 ms (attack_4 visible)", duel_defender_state == "attack",
		duel_defender_state)
	runner.check("N3: frame actual attack_4 a 350 ms",
		SafeDict.as_string(duel_defender_impact.get("sprite_frame_path"), "").ends_with("_attack_4.png"),
		SafeDict.as_string(duel_defender_impact.get("sprite_frame_path"), ""))
	# Tras la ventana (≈444 ms) entra impact/dead.
	duel.call("tick_animation", 120.0)
	var after_impact: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var duel_defender_after: Dictionary = SafeDict.as_dict(after_impact.get("defender", null))
	duel_defender_state = SafeDict.as_string(duel_defender_after.get("anim_state"), "")
	runner.check("N3: defensor en impact/dead tras la ventana de attack_4",
		duel_defender_state == "impact" or duel_defender_state == "dead", duel_defender_state)
	duel.call("tick_animation", 5000.0)
	var settled: Dictionary = SafeDict.as_dict(duel.call("get_state"))
	var settled_defender: Dictionary = SafeDict.as_dict(settled.get("defender", null))
	var settled_state: String = SafeDict.as_string(settled_defender.get("anim_state"), "")
	runner.check("N3: impact vuelve a idle o dead hace death_hold",
		settled_state == "idle" or settled_state == "dead", settled_state)
	duel.free()


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
	for field in ["sprite_sheet", "facing", "mirror", "moving", "march_frame", "sprite_frame_path",
			"anim_state", "anim_frame", "anim_fps", "attack_impact_ms"]:
		runner.check("la unidad expone '%s'" % field, archer.has(field))
	var sprite: Dictionary = SafeDict.as_dict(archer.get("sprite_sheet", null))
	runner.check("el arquero tiene sprite_sheet", not sprite.is_empty())
	runner.check_eq("orientación inicial E", "E", SafeDict.as_string(archer.get("facing"), ""))
	runner.check("sin espejo inicial", not SafeDict.as_bool(archer.get("mirror"), true))
	runner.check("en reposo inicial", not SafeDict.as_bool(archer.get("moving"), true))
	runner.check_eq("estado inicial idle (D-065)", "idle", SafeDict.as_string(archer.get("anim_state"), ""))
	runner.check_eq("march_frame en reposo 0", 0, SafeDict.as_int(archer.get("march_frame"), -1))
	var first_frame: String = SafeDict.as_string(archer.get("sprite_frame_path"), "")
	runner.check("sprite_frame_path inicial = idle_1", first_frame.ends_with("_idle_1.png")
		and ResourceLoader.exists(first_frame), first_frame)
	runner.check("attack_impact_ms ≈ 3/fps_attack (333,3 ms)",
		absf(SafeDict.as_float(archer.get("attack_impact_ms"), 0.0) - 333.3) < 0.3,
		str(archer.get("attack_impact_ms")))
	runner.check_eq("attack_impact_frame = attack_4 (índice 8)", 8,
		SafeDict.as_int(archer.get("attack_impact_frame"), -1))
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
		runner.check_eq("anim_state march tras moverse", "march", SafeDict.as_string(moved_unit.get("anim_state"), ""))
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
		runner.check("proyectil lanzado en attack_4 (impact_ms ≈333,3)",
			absf(SafeDict.as_float(projectile.get("impact_ms"), 0.0) - 333.3) < 0.3)
		runner.check("launch_ms = started_ms (sale en attack_4)",
			is_equal_approx(SafeDict.as_float(projectile.get("launch_ms"), -1.0),
				SafeDict.as_float(projectile.get("started_ms"), -2.0)))
		node.call("tick_animation", 333.3)
		runner.check_eq("a 333,3 ms el proyectil aún no avanza", 0.0,
			SafeDict.as_float((node.call("get_projectiles") as Array)[0].get("t"), -1.0))
		node.call("tick_animation", 250.0)
		var mid_projectiles: Array = node.call("get_projectiles")
		runner.check_eq("a 250 ms de vuelo el proyectil sigue activo", 1, mid_projectiles.size())
		if mid_projectiles.size() == 1:
			var mid: Dictionary = SafeDict.as_dict(mid_projectiles[0])
			runner.check_eq("t = 0.5 a mitad de vuelo", 0.5, SafeDict.as_float(mid.get("t"), -1.0))
			var mid_position: Dictionary = SafeDict.as_dict(mid.get("position", null))
			runner.check_eq("x intermedia (72)", 72.0, SafeDict.as_float(mid_position.get("x"), -1.0))
			runner.check_eq("y con arco (-40)", -40.0, SafeDict.as_float(mid_position.get("y"), 1.0))
		node.call("tick_animation", 300.0)
		runner.check_eq("a 550 ms de vuelo el proyectil ya no está activo", 0, (node.call("get_projectiles") as Array).size())
		runner.check_eq("animation_ms acumulado", 883.3, float(node.call("get_animation_time_ms")))
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
	duel.call("tick_animation", 1200.0)
	runner.check_eq("los proyectiles del duelo expiran", 0, (duel.call("get_projectiles") as Array).size())
	duel.free()
	# Bombarda v2: ahora SÍ tiene sprite panorámico 64×43 y dispara piedra.
	h.new_game("england", 1337)
	var siege: Node = h.launch_close_combat(
		_unit("bombarda", "england", 300, 18, 70),
		_unit("men_at_arms", "france", 900, 12, 70))
	if siege == null:
		return
	var siege_state: Dictionary = SafeDict.as_dict(siege.call("get_state"))
	var siege_attacker: Dictionary = SafeDict.as_dict(siege_state.get("attacker", null))
	var siege_sprite: Dictionary = SafeDict.as_dict(siege_attacker.get("sprite_sheet", null))
	runner.check("bombarda con sprite_sheet v2", not siege_sprite.is_empty())
	runner.check_eq("bombarda size [64,43]", "[64,43]",
		JSON.stringify(_int_array(SafeDict.as_array(siege_sprite.get("size", null)))))
	runner.check("bombarda con sprite_frame_path que carga",
		ResourceLoader.exists(SafeDict.as_string(siege_attacker.get("sprite_frame_path"), "")))
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
		"unit_id": "sintetica_sin_sprite",
		"size": 300,
		"strength": 8,
		"morale": 1.0,
		"experience": 0,
	})
	army["units"] = units_value


## Tamaño de producción esperado por unidad (D-047).
func _expected_size(unit_id: String) -> Array:
	if PANORAMIC_UNITS.has(unit_id):
		return [64, 43]
	if CAVALRY_UNITS.has(unit_id):
		return [64, 80]
	return [64, 64]
