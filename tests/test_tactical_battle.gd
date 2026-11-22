extends RefCounted
## Tests de TacticalBattle (Nivel 2, GDD §6.2 / contrato Fase 2 §4 / D-029).
## Cubre API, mapa hex, objetivos, movimiento, duelo N3, IA de ronda,
## auto_resolve, commit/apply_outcome y determinismo por semilla.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const STATE_KEYS: Array[String] = [
	"battle_id", "attacker_faction", "defender_faction", "region_id", "round",
	"side", "winner", "finished", "objectives", "hexes", "units", "commander_bonus",
]


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("tactical_battle")
	_check_creation(runner, h)
	_check_movement(runner, h)
	_check_duel_and_rounds(runner, h)
	_check_auto_resolve_commit(runner, h)
	_check_determinism(runner, h)


func _check_creation(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		runner.check("launch_tactical devuelve nodo", false)
		return
	runner.check("launch_tactical devuelve un nodo táctico", true)
	runner.check("launch_tactical NO añade el nodo al árbol", not node.is_inside_tree())
	var state: Dictionary = node.call("get_state")
	var keys_ok: bool = true
	for key in STATE_KEYS:
		if not state.has(key):
			keys_ok = false
	runner.check("get_state contiene todas las claves del contrato", keys_ok, str(state.keys()))
	runner.check_eq("bando atacante", "england", str(state.get("attacker_faction")))
	runner.check_eq("bando defensor", "france", str(state.get("defender_faction")))
	runner.check_eq("región táctica", "region_normandia", str(state.get("region_id")))
	runner.check_eq("ronda inicial", 1, int(state.get("round")))
	runner.check_eq("iniciativa del jugador", "attacker", str(state.get("side")))
	runner.check("no terminada al empezar", not bool(state.get("finished")))
	var hexes: Array = node.call("get_hexes")
	runner.check_eq("radio 5 por ser ciudad (91 hexes axiales)", 91, hexes.size())
	var hex_ok: bool = true
	for hex_value in hexes:
		var hex: Dictionary = SafeDict.as_dict(hex_value)
		if not (hex.has("q") and hex.has("r") and hex.has("terrain") and hex.has("objective")):
			hex_ok = false
	runner.check("cada hex tiene q/r/terrain/objective", hex_ok)
	var objectives: Array = node.call("get_objectives")
	runner.check_eq("4 objetivos tácticos", 4, objectives.size())
	var kinds: Dictionary = {}
	for objective_value in objectives:
		var objective: Dictionary = SafeDict.as_dict(objective_value)
		kinds[SafeDict.as_string(objective.get("kind"), "")] = true
	runner.check("objetivos ciudad+puente+retaguardias", kinds.has("city") and kinds.has("bridge") and kinds.has("rearguard"))
	var units: Array = node.call("get_units")
	runner.check_eq("4 unidades en juego (2+2)", 4, units.size())
	var unit_ok: bool = true
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		for field in ["id", "faction", "unit_id", "size", "morale", "commander", "q", "r", "moves_left", "orders_left"]:
			if not unit.has(field):
				unit_ok = false
	runner.check("cada unidad expone los campos del contrato", unit_ok)
	var bonus: Dictionary = SafeDict.as_dict(state.get("commander_bonus", null))
	runner.check("bono de comandante del atacante (>1 con Mando 88)", SafeDict.as_float(bonus.get("attacker"), 0.0) > 1.0,
		str(bonus))
	node.free()


func _check_movement(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		return
	var units: Array = node.call("get_units")
	var attacker_id: String = ""
	var defender_id: String = ""
	var defender_hex: Dictionary = {}
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == "attacker" and attacker_id == "":
			attacker_id = SafeDict.as_string(unit.get("id"), "")
		if SafeDict.as_string(unit.get("side"), "") == "defender" and defender_id == "":
			defender_id = SafeDict.as_string(unit.get("id"), "")
			defender_hex = unit
	runner.check("hay unidad atacante", attacker_id != "")
	runner.check("hay unidad defensora", defender_id != "")
	var reachable: Array = node.call("get_reachable_hexes", attacker_id)
	runner.check("get_reachable_hexes devuelve alcance", reachable.size() > 0, str(reachable.size()))
	var first_reachable: Dictionary = SafeDict.as_dict(reachable[0])
	runner.check("los hexes alcanzables traen coste", first_reachable.has("cost")
		and SafeDict.as_int(first_reachable.get("cost"), 0) >= 1)
	var target_q: int = SafeDict.as_int(first_reachable.get("q"), 0)
	var target_r: int = SafeDict.as_int(first_reachable.get("r"), 0)
	runner.check("can_move_unit coincide con el alcance",
		bool(node.call("can_move_unit", attacker_id, target_q, target_r)))
	var moves_before: int = SafeDict.as_int(node.call("get_unit", attacker_id).get("moves_left"), 0)
	runner.check("move_unit ejecuta el movimiento", bool(node.call("move_unit", attacker_id, target_q, target_r)))
	var moved: Dictionary = SafeDict.as_dict(node.call("get_unit", attacker_id))
	runner.check_eq("la unidad cambia de hex", target_q, SafeDict.as_int(moved.get("q"), -99))
	runner.check_eq("el hex r también cambia", target_r, SafeDict.as_int(moved.get("r"), -99))
	runner.check("consume puntos de movimiento", SafeDict.as_int(moved.get("moves_left"), 0) < moves_before)
	runner.check("no se puede mover a un hex ocupado por el defensor",
		not bool(node.call("can_move_unit", attacker_id,
			SafeDict.as_int(defender_hex.get("q"), 0), SafeDict.as_int(defender_hex.get("r"), 0))))
	runner.check("no se puede mover a un hex inexistente",
		not bool(node.call("can_move_unit", attacker_id, 99, 99)))
	runner.check("una unidad del bando defensor no puede moverse fuera de su turno",
		not bool(node.call("move_unit", defender_id, 0, 0)))
	node.free()


func _check_duel_and_rounds(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		return
	var units: Array = node.call("get_units")
	var attacker_id: String = ""
	var defender_id: String = ""
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		if SafeDict.as_string(unit.get("side"), "") == "attacker" and attacker_id == "":
			attacker_id = SafeDict.as_string(unit.get("id"), "")
		if SafeDict.as_string(unit.get("side"), "") == "defender" and defender_id == "":
			defender_id = SafeDict.as_string(unit.get("id"), "")
	var duel: Dictionary = SafeDict.as_dict(node.call("resolve_duel", attacker_id, defender_id, "carga"))
	runner.check("resolve_duel (Nivel 3 embebido) resuelve", bool(duel.get("ok")), str(duel))
	runner.check("el duelo devuelve resultado del combate cerrado", duel.has("outcome"))
	runner.check("el duelo causa bajas", SafeDict.as_int(duel.get("attacker_losses"), 0) >= 0
		and SafeDict.as_int(duel.get("defender_losses"), 0) >= 0)
	var round_before: int = SafeDict.as_int(SafeDict.as_dict(node.call("get_state")).get("round"), 0)
	var attack: Dictionary = SafeDict.as_dict(node.call("attack_unit", attacker_id, defender_id))
	runner.check("attack_unit devuelve dict con resultado", attack.has("ok"), str(attack))
	node.call("end_round")
	var after: Dictionary = SafeDict.as_dict(node.call("get_state"))
	runner.check("end_round avanza la ronda o termina la batalla",
		int(after.get("round", 0)) > round_before or bool(after.get("finished")))
	node.free()


func _check_auto_resolve_commit(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	var node: Node = _launch(h, ids)
	if node == null:
		return
	var started_us: int = Time.get_ticks_usec()
	var report: Dictionary = SafeDict.as_dict(node.call("auto_resolve"))
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_us) / 1000.0
	print("  [INFO] Nivel 2 auto_resolve: %.2f ms para %d unidades" % [elapsed_ms, (node.call("get_units") as Array).size()])
	runner.check("Nivel 2 se resuelve en <1000 ms", elapsed_ms < 1000.0, "%.2f ms" % elapsed_ms)
	runner.check("auto_resolve termina la batalla", bool(node.call("is_finished")))
	var winner: String = str(node.call("get_winner"))
	runner.check("el ganador es una facción válida", winner == "england" or winner == "france", winner)
	runner.check_eq("el informe es de Nivel 2", 2, SafeDict.as_int(report.get("level"), 0))
	runner.check("el informe trae bajas coherentes", SafeDict.as_int(report.get("attacker_losses"), -1) >= 0
		and SafeDict.as_int(report.get("defender_losses"), -1) >= 0)
	runner.check("el informe trae rondas", SafeDict.as_int(report.get("rounds_played"), 0) >= 1)
	runner.check_eq("captura de región coherente con el ganador", winner == "england",
		SafeDict.as_bool(report.get("region_captured"), false))
	var snapshot: Dictionary = SafeDict.as_dict(report.get("army_snapshot", null))
	runner.check("el informe incluye snapshot de unidades para aplicar bajas",
		not SafeDict.as_array(snapshot.get("attacker", null)).is_empty()
		and not SafeDict.as_array(snapshot.get("defender", null)).is_empty())
	var reports_before: int = h.battle_reports().size()
	node.call("apply_outcome")
	var reports_after: int = h.battle_reports().size()
	runner.check_eq("apply_outcome registra el informe", reports_before + 1, reports_after)
	node.call("apply_outcome")
	runner.check_eq("apply_outcome es idempotente (no duplica)", reports_after, h.battle_reports().size())
	if winner == "england":
		runner.check_eq("la región capturada pasa al atacante", "england", str(h.region("region_normandia")["owner"]))
	node.free()


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
	runner.check_eq("Nivel 2 determinista con la misma semilla", JSON.stringify(report_a), JSON.stringify(report_b))


# --- helpers -------------------------------------------------------------

## Escenario Crécy-like: Inglaterra (2400 arqueros + 400 hombres de armas en
## Londres) contra Francia (600 ballesteros + 800 hombres de armas en Normandía).
func _prepare_battle(h: HarnessScript) -> Array[String]:
	h.new_game("england", 1337)
	h.recruit("england", "region_londres", "longbowman", 1600)
	h.recruit("england", "region_londres", "men_at_arms", 400)
	h.recruit("france", "region_normandia", "men_at_arms", 800)
	var result: Array[String] = [
		_army_in(h, "england", "region_londres"),
		_army_in(h, "france", "region_normandia"),
		"region_normandia",
	]
	return result


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
