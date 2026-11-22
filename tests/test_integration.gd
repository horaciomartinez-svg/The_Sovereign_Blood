extends RefCounted
## Test de integración de Fase 1: 4 trimestres de Inglaterra 1337 con órdenes
## válidas de economía, militar y diplomacia, sin crash y con estado serializable
## en cada paso (criterio de aceptación §9.1 del contrato).

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("integration")
	_check_four_quarters_england(runner, h)


func _check_four_quarters_england(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var all_orders_ok: bool = true
	var serializable: bool = true
	var failures: Array[String] = []
	var army_id: String = _army_in(h, "england", "region_inglaterra_sur")
	for quarter in 4:
		# Orden de economía: reasignar mano de obra (1 PG).
		var workers: Dictionary = SafeDict.as_dict(h.region("region_londres").get("workers", null))
		var merchants: int = SafeDict.as_int(workers.get("merchants"), 0)
		if not h.allocate("region_londres", "merchants", merchants + 5):
			all_orders_ok = false
			failures.append("Q%d allocate" % (quarter + 1))
		# Orden militar: reclutar arqueros en la capital.
		if not h.recruit("england", "region_londres", "longbowman", 200):
			all_orders_ok = false
			failures.append("Q%d recruit" % (quarter + 1))
		# Orden de movimiento (solo el primer trimestre): ejército a la capital.
		if quarter == 0 and army_id != "":
			if not h.move_army(army_id, "region_londres"):
				all_orders_ok = false
				failures.append("Q%d move" % (quarter + 1))
		# Orden diplomática: pacto comercial con el Papado (sin frontera con
		# Inglaterra, por lo que la IA no puede haber declarado la guerra).
		var pact: Dictionary = h.propose("england", "papacy", {"type": "trade_pact"})
		if not bool(pact.get("ok")):
			all_orders_ok = false
			failures.append("Q%d trade(%s)" % [quarter + 1, str(pact.get("reason"))])
		# El estado debe poder serializarse en cada paso (GDD §8.3).
		if h.state_json().length() < 1000:
			serializable = false
		h.end_turn()
		if bool(h.state().get("game_over", false)):
			break
	runner.check("4 trimestres de Inglaterra sin errores de órdenes", all_orders_ok, ", ".join(failures))
	runner.check("el estado es serializable en cada trimestre", serializable)
	runner.check_eq("la partida avanza al año 1338", 1338, h.year())
	runner.check_eq("empieza el trimestre 1 de 1338", 1, h.quarter())
	runner.check("la partida sigue viva", not bool(h.state().get("game_over", false)))
	runner.check("la IA se ejecutó en cada end_turn", h.ai_last_orders().size() == 13)
	var turn: int = SafeDict.as_int(h.state().get("turn"), 0)
	runner.check_eq("turno absoluto tras 4 trimestres", 5, turn)
	runner.check("Inglaterra conserva al menos una región", _owned_regions(h, "england") >= 1,
		str(_owned_regions(h, "england")))
	# Save/load al final de la integración conserva el hash exacto.
	var hash_before: int = h.state_hash()
	runner.check("guardar partida integrada", h.save_game("integration"))
	runner.check("cargar partida integrada", h.load_game("integration"))
	runner.check_eq("save/load conserva el hash en integración", hash_before, h.state_hash())


func _army_in(h: HarnessScript, faction_id: String, region_id: String) -> String:
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return str(army_id)
	return ""


func _owned_regions(h: HarnessScript, faction_id: String) -> int:
	var total: int = 0
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			total += 1
	return total
