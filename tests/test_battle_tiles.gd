extends RefCounted
## Tests de tiles del campo de batalla §10.4 (GDD v1.7, contrato tiles §B,
## D-053): tabla `battle_tiles`, API `BattleTiles`, reglas tácticas N2/N3
## (intransitables, costes, defensa, penalización de caballería) y determinismo.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const BattleTilesScript = preload("res://scripts/battle/battle_tiles.gd")

const TILE_KEYS: Array[String] = [
	"pastizal", "pastizal_arbustos", "pradera", "rio", "puente", "puente_villa",
	"colina", "bosque", "montana", "villa", "villa_calle", "camino",
]
const REGION: String = "region_normandia"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("battle_tiles")
	_check_dataset(runner, h)
	_check_api(runner, h)
	_check_no_tiles_fallback(runner)
	_check_tactical_rules(runner, h)
	_check_close_combat_rules(runner, h)
	_check_determinism(runner, h)


func _check_dataset(runner: TestRunnerScript, h: HarnessScript) -> void:
	var keys: Array[String] = h.battle_tile_keys()
	runner.check_eq("12 tiles cargados en DataLoader", 12, keys.size())
	var expected: Dictionary = {
		"pastizal": [1.0, 0, true], "pastizal_arbustos": [1.0, 0, true],
		"pradera": [1.0, 0, true], "rio": [null, 0, false],
		"puente": [1.0, 0, true], "puente_villa": [1.0, 1, true],
		"colina": [2.0, 1, true], "bosque": [2.0, 1, true],
		"montana": [null, 0, false], "villa": [1.0, 1, true],
		"villa_calle": [1.0, 0, true], "camino": [0.5, 0, true],
	}
	for key in TILE_KEYS:
		var tile: Dictionary = h.battle_tile(key)
		runner.check("tile presente en datos: %s" % key, not tile.is_empty())
		if tile.is_empty():
			continue
		var spec: Array = expected[key]
		if spec[0] == null:
			runner.check("move_cost null en %s" % key, tile.get("move_cost") == null)
		else:
			runner.check_eq("move_cost de %s" % key, float(spec[0]), SafeDict.as_float(tile.get("move_cost"), -1.0))
		runner.check_eq("defense de %s" % key, int(spec[1]), SafeDict.as_int(tile.get("defense"), -1))
		runner.check_eq("passable de %s" % key, bool(spec[2]), SafeDict.as_bool(tile.get("passable"), not bool(spec[2])))
		runner.check("ruta de %s" % key,
			SafeDict.as_string(tile.get("tile"), "").begins_with("res://assets/art/battle/tiles/tile_"))
	runner.check("bosque con cavalry_penalty", SafeDict.as_bool(h.battle_tile("bosque").get("cavalry_penalty"), false))
	runner.check("camino con move_bonus", SafeDict.as_bool(h.battle_tile("camino").get("move_bonus"), false))
	runner.check("villa_calle con move_bonus", SafeDict.as_bool(h.battle_tile("villa_calle").get("move_bonus"), false))


func _check_api(runner: TestRunnerScript, h: HarnessScript) -> void:
	var tiles: BattleTilesScript = BattleTilesScript.new(h.battle_tiles())
	runner.check("API: 12 claves", tiles.keys().size() == 12)
	runner.check_eq("API: coste pastizal", 1.0, tiles.get_move_cost("pastizal"))
	runner.check_eq("API: coste colina", 2.0, tiles.get_move_cost("colina"))
	runner.check_eq("API: coste camino con bonus", 0.5, tiles.get_move_cost("camino"))
	runner.check_eq("API: villa_calle con bonus", 0.5, tiles.get_move_cost("villa_calle"))
	runner.check_eq("API: bosque para caballería (×1.5)", 3.0, tiles.get_move_cost("bosque", "cavalry"))
	runner.check_eq("API: bosque para caballería ligera", 3.0, tiles.get_move_cost("bosque", "light_cavalry"))
	runner.check_eq("API: bosque para infantería", 2.0, tiles.get_move_cost("bosque", "infantry"))
	runner.check_eq("API: río intransitable", -1.0, tiles.get_move_cost("rio"))
	runner.check_eq("API: montaña intransitable", -1.0, tiles.get_move_cost("montana"))
	runner.check("API: is_passable rio=false", not tiles.is_passable("rio"))
	runner.check("API: is_passable montana=false", not tiles.is_passable("montana"))
	runner.check("API: is_passable puente=true", tiles.is_passable("puente"))
	runner.check("API: is_passable puente_villa=true", tiles.is_passable("puente_villa"))
	runner.check_eq("API: defense colina", 1, tiles.get_defense("colina"))
	runner.check_eq("API: defense villa", 1, tiles.get_defense("villa"))
	runner.check_eq("API: defense pastizal", 0, tiles.get_defense("pastizal"))
	runner.check("API: multiplicador defensa colina", is_equal_approx(tiles.get_defense_multiplier("colina"), 1.2))
	runner.check("API: cavalry_penalty bosque", tiles.has_cavalry_penalty("bosque"))
	runner.check("API: sin cavalry_penalty en pastizal", not tiles.has_cavalry_penalty("pastizal"))
	runner.check("API: move_bonus camino", tiles.has_move_bonus("camino"))
	runner.check_eq("API: terreno plains→pastizal", "pastizal", BattleTilesScript.tile_key_for_terrain("plains"))
	runner.check_eq("API: terreno forest→bosque", "bosque", BattleTilesScript.tile_key_for_terrain("forest"))
	runner.check_eq("API: terreno river→rio", "rio", BattleTilesScript.tile_key_for_terrain("river"))
	runner.check("API: cavalry detectada", BattleTilesScript.is_cavalry("cavalry"))
	runner.check("API: light_cavalry detectada", BattleTilesScript.is_cavalry("light_cavalry"))
	runner.check("API: infantería no es caballería", not BattleTilesScript.is_cavalry("infantry"))


func _check_no_tiles_fallback(runner: TestRunnerScript) -> void:
	var empty: BattleTilesScript = BattleTilesScript.new({})
	runner.check("sin tiles: is_empty", empty.is_empty())
	runner.check("sin tiles: is_passable=true (legado)", empty.is_passable("rio"))
	runner.check_eq("sin tiles: move_cost=-1 (usa legado)", -1.0, empty.get_move_cost("colina"))
	runner.check_eq("sin tiles: defense=0", 0, empty.get_defense("colina"))
	runner.check("sin tiles: get_tile {}", empty.get_tile("bosque").is_empty())
	runner.check("sin tiles: sin cavalry_penalty", not empty.has_cavalry_penalty("bosque"))


func _check_tactical_rules(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("battle táctico para tiles", false)
		return
	runner.check_eq("N2 expone 12 tiles", 12, (node.call("get_battle_tile_keys") as Array).size())
	runner.check("N2: rio intransitable (API)", not bool(node.call("is_tile_passable", "rio")))
	runner.check_eq("N2: coste colina", 2.0, float(node.call("get_tile_move_cost", "colina", "infantry")))
	runner.check_eq("N2: coste camino con bonus", 0.5, float(node.call("get_tile_move_cost", "camino", "infantry")))
	runner.check_eq("N2: defense colina", 1, int(node.call("get_tile_defense", "colina")))
	# Cada hex lleva su clave de tile y hay al menos un puente en el río.
	var hexes: Array = node.call("get_hexes")
	var tiles_ok: bool = true
	var bridge_count: int = 0
	var river_hex: Dictionary = {}
	for hex_value in hexes:
		var hex: Dictionary = SafeDict.as_dict(hex_value)
		var tile_key: String = SafeDict.as_string(hex.get("tile"), "")
		if tile_key == "":
			tiles_ok = false
		if tile_key == "puente" or tile_key == "puente_villa":
			bridge_count += 1
		if tile_key == "rio" and river_hex.is_empty():
			river_hex = hex
	runner.check("N2: todos los hexes tienen tile", tiles_ok)
	runner.check("N2: hay 1-2 puentes sobre el río", bridge_count >= 1 and bridge_count <= 2, str(bridge_count))
	# Río: una unidad adyacente no puede entrar (ni con move_unit).
	var unit: Dictionary = _first_attacker(node)
	runner.check("N2: hay unidad atacante", not unit.is_empty())
	if not unit.is_empty() and not river_hex.is_empty():
		var unit_q: int = SafeDict.as_int(unit.get("q"), 0)
		var unit_r: int = SafeDict.as_int(unit.get("r"), 0)
		var river_q: int = SafeDict.as_int(river_hex.get("q"), 0)
		var river_r: int = SafeDict.as_int(river_hex.get("r"), 0)
		var neighbour: Dictionary = _find_free_neighbour(node, river_q, river_r, SafeDict.as_string(unit.get("id"), ""))
		if not neighbour.is_empty():
			var internal: Dictionary = node.call("_find_unit", SafeDict.as_string(unit.get("id"), ""))
			internal["q"] = SafeDict.as_int(neighbour.get("q"), 0)
			internal["r"] = SafeDict.as_int(neighbour.get("r"), 0)
			internal["moves_left"] = 3.0
			runner.check("N2: can_move a río = false",
				not bool(node.call("can_move_unit", SafeDict.as_string(unit.get("id"), ""), river_q, river_r)))
			runner.check("N2: move_unit a río = false",
				not bool(node.call("move_unit", SafeDict.as_string(unit.get("id"), ""), river_q, river_r)))
		else:
			runner.check("N2: hay vecino libre del río", false)
	# Montaña: se marca un hex y no se puede entrar.
	if not unit.is_empty():
		var internal_unit: Dictionary = node.call("_find_unit", SafeDict.as_string(unit.get("id"), ""))
		var current_q: int = SafeDict.as_int(internal_unit.get("q"), 0)
		var current_r: int = SafeDict.as_int(internal_unit.get("r"), 0)
		for neighbour in _neighbours(current_q, current_r):
			var q: int = SafeDict.as_int(neighbour.get("q"), 0)
			var r: int = SafeDict.as_int(neighbour.get("r"), 0)
			var hex_key: String = "%d,%d" % [q, r]
			var hexes_internal: Dictionary = node.get("_hexes")
			if not hexes_internal.has(hex_key) or not bool(node.call("_is_hex_free", q, r, SafeDict.as_string(unit.get("id"), ""))):
				continue
			var hex: Dictionary = SafeDict.as_dict(hexes_internal.get(hex_key, null))
			hex["tile"] = "montana"
			hexes_internal[hex_key] = hex
			internal_unit["moves_left"] = 3.0
			runner.check("N2: can_move a montaña = false",
				not bool(node.call("can_move_unit", SafeDict.as_string(unit.get("id"), ""), q, r)))
			break
	# Defensa por tile aplicada en la fórmula.
	var colina_defense: float = 1.0
	for hex_value in hexes:
		var hex: Dictionary = SafeDict.as_dict(hex_value)
		if SafeDict.as_string(hex.get("tile"), "") == "colina":
			colina_defense = float(node.call("_terrain_defense_multiplier_at",
				SafeDict.as_int(hex.get("q"), 0), SafeDict.as_int(hex.get("r"), 0)))
			break
	runner.check("N2: defensa de colina en la fórmula (1.2)", is_equal_approx(colina_defense, 1.2),
		str(colina_defense))
	# Fallback legado: sin tabla, el río vuelve a costar 2 (comportamiento previo).
	var battle_tiles_instance: Variant = node.get("_battle_tiles")
	if battle_tiles_instance is BattleTilesScript:
		(battle_tiles_instance as BattleTilesScript).tiles = {}
		var legacy_cost: float = float(node.call("_tile_move_cost_at",
			SafeDict.as_int(river_hex.get("q"), 0), SafeDict.as_int(river_hex.get("r"), 0), unit))
		runner.check_eq("N2 sin tiles: coste legado del río (2)", 2.0, legacy_cost)
		runner.check("N2 sin tiles: is_tile_passable=true", bool(node.call("is_tile_passable", "rio")))
	node.free()


func _check_close_combat_rules(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var duel: Node = h.launch_close_combat(
		{"id": "tile_cav", "faction": "france", "unit_id": "men_at_arms", "type": "cavalry",
			"size": 800, "strength": 12, "morale": 1.0, "experience": 50, "commander_stat": 70,
			"terrain": "plains", "tile": "pastizal"},
		{"id": "tile_inf", "faction": "england", "unit_id": "militia_spearman", "type": "infantry",
			"size": 900, "strength": 4, "morale": 1.0, "experience": 50, "commander_stat": 70,
			"terrain": "plains", "tile": "pastizal"})
	if duel == null:
		runner.check("duelo para tiles", false)
		return
	runner.check_eq("N3 expone 12 tiles", 12, (duel.call("get_battle_tile_keys") as Array).size())
	runner.check("N3: rio intransitable", not bool(duel.call("is_tile_passable", "rio")))
	runner.check_eq("N3: defense villa", 1, int(duel.call("get_tile_defense", "villa")))
	runner.check_eq("N3: coste colina", 2.0, float(duel.call("get_tile_move_cost", "colina", "infantry")))
	var attacker: Dictionary = SafeDict.as_dict(duel.get("attacker"))
	var power_plain: float = float(duel.call("_unit_power", attacker))
	attacker["tile"] = "bosque"
	var power_forest: float = float(duel.call("_unit_power", attacker))
	runner.check("N3: penalización de caballería en bosque (×0.6)",
		is_equal_approx(power_forest, power_plain * 0.6), "%.3f vs %.3f" % [power_forest, power_plain])
	var tiles: BattleTilesScript = BattleTilesScript.new(h.battle_tiles())
	runner.check("N3: defensa de villa multiplica 1.2", is_equal_approx(tiles.get_defense_multiplier("villa"), 1.2))
	runner.check_eq("N3: tile del defensor expuesto", "pastizal", SafeDict.as_string(
		SafeDict.as_dict(duel.get("defender")).get("tile"), ""))
	duel.free()


func _check_determinism(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids_a: Array[String] = _prepare_battle(h)
	var node_a: Node = _launch(h, ids_a)
	if node_a == null:
		return
	var report_a: Dictionary = SafeDict.as_dict(node_a.call("auto_resolve"))
	node_a.free()
	var ids_b: Array[String] = _prepare_battle(h)
	var node_b: Node = _launch(h, ids_b)
	if node_b == null:
		return
	var report_b: Dictionary = SafeDict.as_dict(node_b.call("auto_resolve"))
	node_b.free()
	runner.check_eq("N2 con tiles determinista", JSON.stringify(report_a), JSON.stringify(report_b))
	# Las consultas de tiles no consumen RNG.
	var ids_c: Array[String] = _prepare_battle(h)
	var node_c: Node = _launch(h, ids_c)
	if node_c != null:
		var rng_before: Dictionary = h.rng_snapshot()
		node_c.call("get_battle_tile_keys")
		node_c.call("get_tile_move_cost", "bosque", "cavalry")
		node_c.call("get_tile_defense", "colina")
		node_c.call("is_tile_passable", "rio")
		var rng_after: Dictionary = h.rng_snapshot()
		runner.check_eq("consultar tiles no consume RNG", JSON.stringify(rng_before), JSON.stringify(rng_after))
		node_c.free()


# --- helpers -------------------------------------------------------------

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


func _first_attacker(node: Node) -> Dictionary:
	for unit_value in node.call("get_units"):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == "attacker":
			return unit
	return {}


func _find_free_neighbour(node: Node, q: int, r: int, unit_id: String) -> Dictionary:
	for neighbour in _neighbours(q, r):
		var nq: int = SafeDict.as_int(neighbour.get("q"), 0)
		var nr: int = SafeDict.as_int(neighbour.get("r"), 0)
		var hexes: Dictionary = node.get("_hexes")
		if not hexes.has("%d,%d" % [nq, nr]):
			continue
		if not bool(node.call("_is_hex_free", nq, nr, unit_id)):
			continue
		return {"q": nq, "r": nr}
	return {}


func _neighbours(q: int, r: int) -> Array[Dictionary]:
	return [
		{"q": q + 1, "r": r}, {"q": q - 1, "r": r}, {"q": q, "r": r + 1},
		{"q": q, "r": r - 1}, {"q": q + 1, "r": r - 1}, {"q": q - 1, "r": r + 1},
	]
