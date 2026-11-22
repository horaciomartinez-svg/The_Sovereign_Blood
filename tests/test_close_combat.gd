extends RefCounted
## Tests de CloseCombat (Nivel 3, GDD §6.3 / contrato Fase 2 §4 / D-029):
## cartas de orden, mano 3 vs 2 por Mando, rondas, multiplicadores y determinismo.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("close_combat")
	_check_setup_and_api(runner, h)
	_check_orders_and_rounds(runner, h)
	_check_card_rules(runner, h)
	_check_determinism(runner, h)
	_check_apply_to_campaign(runner, h)


var _battle_resolved_events: int = 0


func _on_battle_resolved(_report: Dictionary) -> void:
	_battle_resolved_events += 1


## D-033: el resultado del duelo se aplica a la campaña (bajas/captura) de forma
## idempotente y sin dobles emisiones.
func _check_apply_to_campaign(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 80
	h.recruit("england", "region_londres", "longbowman", 400)
	h.recruit("france", "region_normandia", "men_at_arms", 600)
	var attacker_id: String = _army_in(h, "england", "region_londres")
	var defender_id: String = _army_in(h, "france", "region_normandia")
	runner.check("hay ejércitos de campaña para el duelo", attacker_id != "" and defender_id != "")
	if attacker_id == "" or defender_id == "":
		return
	var attacker_men_before: int = h.army_men(attacker_id)
	var defender_men_before: int = h.army_men(defender_id)
	var attacker_model: Variant = h.get_army_model(attacker_id)
	var defender_model: Variant = h.get_army_model(defender_id)
	var attacker_unit: Dictionary = SafeDict.as_dict(
		SafeDict.as_array(attacker_model.get("units"))[0]).duplicate(true)
	var defender_unit: Dictionary = SafeDict.as_dict(
		SafeDict.as_array(defender_model.get("units"))[0]).duplicate(true)
	attacker_unit["commander_stat"] = 88
	attacker_unit["faction"] = "england"
	defender_unit["commander_stat"] = 74
	defender_unit["faction"] = "france"
	var node: Node = h.launch_close_combat(attacker_unit, defender_unit)
	if node == null:
		return
	var outcome: Dictionary = SafeDict.as_dict(node.call("auto_resolve"))
	node.free()
	var resolved_handler := Callable(self, "_on_battle_resolved")
	_battle_resolved_events = 0
	if h.bus != null:
		h.bus.connect("battle_resolved", resolved_handler)
	var reports_before: int = h.battle_reports().size()
	var report: Dictionary = h.apply_close_combat_outcome(attacker_id, defender_id, "region_normandia", outcome)
	runner.check("apply_close_combat_outcome devuelve informe", not report.is_empty(), str(report))
	if report.is_empty():
		if h.bus != null:
			h.bus.disconnect("battle_resolved", resolved_handler)
		return
	runner.check_eq("el informe aplicado es de Nivel 3", 3, SafeDict.as_int(report.get("level"), 0))
	runner.check_eq("informe asociado al ejército atacante", attacker_id,
		SafeDict.as_string(report.get("attacker_army_id"), ""))
	runner.check_eq("ganador coherente con el duelo",
		SafeDict.as_string(outcome.get("winner_faction"), ""), SafeDict.as_string(report.get("winner_faction"), ""))
	runner.check_eq("bajas del atacante del duelo",
		SafeDict.as_int(outcome.get("attacker_losses"), 0), SafeDict.as_int(report.get("attacker_losses"), -1))
	runner.check_eq("informe registrado en la partida", reports_before + 1, h.battle_reports().size())
	runner.check_eq("una sola señal battle_resolved", 1, _battle_resolved_events)
	var attacker_men_after: int = h.army_men(attacker_id)
	var defender_men_after: int = h.army_men(defender_id)
	runner.check("las bajas del atacante se aplican al ejército",
		attacker_men_after == maxi(0, attacker_men_before - SafeDict.as_int(report.get("attacker_losses"), 0)),
		"%d → %d" % [attacker_men_before, attacker_men_after])
	runner.check("las bajas del defensor se aplican al ejército",
		defender_men_after == maxi(0, defender_men_before - SafeDict.as_int(report.get("defender_losses"), 0)),
		"%d → %d" % [defender_men_before, defender_men_after])
	if SafeDict.as_bool(report.get("region_captured"), false):
		runner.check_eq("la región capturada pasa al atacante", "england", str(h.region("region_normandia")["owner"]))
	# Idempotencia: mismo outcome aplicado dos veces no duplica efectos ni señales.
	var report_again: Dictionary = h.apply_close_combat_outcome(attacker_id, defender_id, "region_normandia", outcome)
	runner.check_eq("idempotente: devuelve el mismo informe", JSON.stringify(report), JSON.stringify(report_again))
	runner.check_eq("idempotente: no duplica el informe", reports_before + 1, h.battle_reports().size())
	runner.check_eq("idempotente: no re-emite battle_resolved", 1, _battle_resolved_events)
	runner.check_eq("idempotente: los hombres no cambian otra vez",
		attacker_men_after, h.army_men(attacker_id))
	if h.bus != null:
		h.bus.disconnect("battle_resolved", resolved_handler)
	# Outcome inválido / ejército inexistente → {} sin crash.
	runner.check("outcome vacío no aplica nada", h.apply_close_combat_outcome(attacker_id, defender_id, "region_normandia", {}).is_empty())
	runner.check("ejército inexistente no aplica nada",
		h.apply_close_combat_outcome("army_nope", defender_id, "region_normandia", {"winner_side": "attacker"}).is_empty())


func _army_in(h: HarnessScript, faction_id: String, region_id: String) -> String:
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return str(army_id)
	return ""


func _check_setup_and_api(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var node: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if node == null:
		runner.check("launch_close_combat devuelve nodo", false)
		return
	runner.check("launch_close_combat devuelve un nodo", true)
	runner.check("el nodo de combate cerrado no se añade al árbol", not node.is_inside_tree())
	var state: Dictionary = SafeDict.as_dict(node.call("get_state"))
	for key in ["round", "attacker", "defender", "orders_left", "hands", "cards", "finished", "winner"]:
		runner.check("get_state contiene '%s'" % key, state.has(key))
	runner.check_eq("mano del atacante (Mando 88 > 74) = 3 cartas", 3,
		SafeDict.as_array(SafeDict.as_dict(state.get("hands", null)).get("attacker", null)).size())
	runner.check_eq("mano del defensor = 2 cartas", 2,
		SafeDict.as_array(SafeDict.as_dict(state.get("hands", null)).get("defender", null)).size())
	runner.check_eq("5 cartas de orden disponibles", 5,
		SafeDict.as_array(state.get("cards", null)).size())
	runner.check("el duelo empieza no terminado", not bool(state.get("finished")))
	node.free()
	# Mando inverso: el defensor tiene la mano de 3.
	var reverse_attacker: Dictionary = _attacker_unit()
	reverse_attacker["commander_stat"] = 40
	var reverse_defender: Dictionary = _defender_unit()
	reverse_defender["commander_stat"] = 95
	var reversed_node: Node = h.launch_close_combat(reverse_attacker, reverse_defender)
	if reversed_node != null:
		var reversed_state: Dictionary = SafeDict.as_dict(reversed_node.call("get_state"))
		runner.check_eq("con Mando inverso el defensor tiene 3 cartas", 3,
			SafeDict.as_array(SafeDict.as_dict(reversed_state.get("hands", null)).get("defender", null)).size())
		runner.check_eq("y el atacante se queda con 2", 2,
			SafeDict.as_array(SafeDict.as_dict(reversed_state.get("hands", null)).get("attacker", null)).size())
		reversed_node.free()


func _check_orders_and_rounds(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var node: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if node == null:
		return
	runner.check("carta inventada rechazada", not bool(node.call("play_order", "magia")))
	runner.check("carta válida aceptada", bool(node.call("play_order", "carga")))
	runner.check("no se pueden jugar dos cartas en la misma ronda", not bool(node.call("play_order", "disparo")))
	var round_result: Dictionary = SafeDict.as_dict(node.call("enemy_respond"))
	runner.check("enemy_respond resuelve la ronda", bool(round_result.get("ok")), str(round_result))
	runner.check("la ronda registra ambas cartas", round_result.has("attacker_card") and round_result.has("defender_card"))
	runner.check("la ronda causa bajas", SafeDict.as_int(round_result.get("defender_losses"), 0) > 0
		or SafeDict.as_int(round_result.get("attacker_losses"), 0) > 0)
	var state: Dictionary = SafeDict.as_dict(node.call("get_state"))
	runner.check("la ronda avanza (o termina)", int(state.get("round", 0)) > 1 or bool(state.get("finished")))
	node.free()
	# Simulación completa headless.
	h.new_game("england", 1337)
	var auto_node: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if auto_node == null:
		return
	var started_us: int = Time.get_ticks_usec()
	var outcome: Dictionary = SafeDict.as_dict(auto_node.call("auto_resolve"))
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_us) / 1000.0
	print("  [INFO] Nivel 3 auto_resolve: %.2f ms" % elapsed_ms)
	runner.check("Nivel 3 se resuelve en <1000 ms", elapsed_ms < 1000.0, "%.2f ms" % elapsed_ms)
	runner.check("el combate cerrado termina", bool(auto_node.call("is_finished")))
	runner.check_eq("el resultado es de Nivel 3", 3, SafeDict.as_int(outcome.get("level"), 0))
	runner.check("el ganador es un bando válido",
		str(outcome.get("winner_side")) == "attacker" or str(outcome.get("winner_side")) == "defender"
		or str(outcome.get("winner_side")) == "", str(outcome.get("winner_side")))
	runner.check("el resultado trae bajas", SafeDict.as_int(outcome.get("attacker_losses"), -1) >= 0
		and SafeDict.as_int(outcome.get("defender_losses"), -1) >= 0)
	runner.check("el resultado trae rondas", SafeDict.as_int(outcome.get("rounds"), 0) >= 1)
	auto_node.free()


func _check_card_rules(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var node: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if node == null:
		return
	var charge_plain: float = float(node.call("_attack_multiplier", "carga", "infantry", "disparo"))
	var charge_formation: float = float(node.call("_attack_multiplier", "carga", "infantry", "formacion"))
	runner.check("carga ×1.4 contra infantería en llano", is_equal_approx(charge_plain, 1.4), str(charge_plain))
	runner.check("carga ×0.6 contra formación/piqueros", charge_formation < charge_plain,
		"%.2f vs %.2f" % [charge_formation, charge_plain])
	runner.check("disparo daña antes del choque", is_equal_approx(float(node.call("_attack_multiplier", "disparo", "cavalry", "carga")), 0.7))
	runner.check("formación reduce el daño recibido (×0.5)",
		is_equal_approx(float(node.call("_defense_reduction", "formacion")), 0.5))
	runner.check("finta reduce el daño recibido (×0.7)",
		is_equal_approx(float(node.call("_defense_reduction", "finta")), 0.7))
	runner.check("retirada ordenada reduce bajas (×0.5)",
		is_equal_approx(float(node.call("_defense_reduction", "retirada")), 0.5))
	runner.check("retirada no ataca", is_equal_approx(float(node.call("_attack_multiplier", "retirada", "infantry", "carga")), 0.0))
	runner.check("formación también reduce el propio ataque",
		float(node.call("_attack_multiplier", "formacion", "infantry", "carga")) < 1.0)
	node.free()


func _check_determinism(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var node_a: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if node_a == null:
		return
	var outcome_a: Dictionary = SafeDict.as_dict(node_a.call("auto_resolve"))
	node_a.free()
	h.new_game("england", 1337)
	var node_b: Node = h.launch_close_combat(_attacker_unit(), _defender_unit())
	if node_b == null:
		return
	var outcome_b: Dictionary = SafeDict.as_dict(node_b.call("auto_resolve"))
	node_b.free()
	runner.check_eq("Nivel 3 determinista con la misma semilla", JSON.stringify(outcome_a), JSON.stringify(outcome_b))


# --- helpers -------------------------------------------------------------

func _attacker_unit() -> Dictionary:
	return {
		"id": "crecy_england_longbow",
		"faction": "england",
		"unit_id": "longbowman",
		"size": 1200,
		"strength": 9,
		"morale": 1.0,
		"experience": 50,
		"commander_stat": 88,
		"terrain": "plains",
	}


func _defender_unit() -> Dictionary:
	return {
		"id": "crecy_france_men_at_arms",
		"faction": "france",
		"unit_id": "men_at_arms",
		"size": 1000,
		"strength": 12,
		"morale": 1.0,
		"experience": 50,
		"commander_stat": 74,
		"terrain": "plains",
	}
