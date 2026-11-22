extends RefCounted
## Tests de espionaje (GDD §5.4, contrato Fase 2 §5, D-030): acción `espia`,
## coste 6 PG, éxito por Astucia/relación, intel serializable y persistente.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("espionage")
	_check_cost(runner, h)
	_check_success_and_intel(runner, h)
	_check_failure(runner, h)
	_check_determinism(runner, h)


func _check_cost(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	runner.check_eq("coste de la acción espia = 6 PG", 6, h.action_cost("espia"))
	runner.check_eq("las 7 acciones previas conservan su coste", 8, h.action_cost("alliance"))
	runner.check_eq("acción desconocida sigue dando -1", -1, h.action_cost("magia"))
	h.faction("england")["pg"] = 60
	var result: Dictionary = h.propose("england", "france", {"action": "espia"})
	runner.check("espia se procesa como acción diplomática", bool(result.get("ok")), str(result))
	runner.check_eq("cobra exactamente 6 PG", 54, int(h.faction("england")["pg"]))
	runner.check("devuelve cost_pg en el resultado", SafeDict.as_int(result.get("cost_pg"), 0) == 6)
	# Sin PG no hay espionaje.
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 0
	var no_pg: Dictionary = h.propose("england", "france", {"action": "espia"})
	runner.check("sin PG el espionaje falla", not bool(no_pg.get("ok"))
		and SafeDict.as_string(no_pg.get("reason"), "") == "pg", str(no_pg))


func _check_success_and_intel(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	# Astucia máxima + buena relación → probabilidad alta.
	h.character("edward_iii_plantagenet")["stats"]["intrigue"] = 100
	h.set_relation("england", "france", 100)
	var success: Dictionary = {}
	var attempts: int = 0
	while success.is_empty() and attempts < 10:
		attempts += 1
		h.faction("england")["pg"] = 60
		h.reset_turn_actions()
		var result: Dictionary = h.propose("england", "france", {"action": "espia"})
		if bool(result.get("accepted")):
			success = result
	runner.check("espionaje con éxito en <=10 intentos", not success.is_empty(), "intentos=%d" % attempts)
	runner.check("el resultado incluye intel", not SafeDict.as_dict(success.get("intel", null)).is_empty())
	var intel: Dictionary = SafeDict.as_dict(success.get("intel", null))
	runner.check("intel.armies presente", intel.has("armies"))
	runner.check("intel.treasury presente", intel.has("treasury"))
	runner.check("intel.regent_id presente", intel.has("regent_id"))
	runner.check("intel.at_war presente", intel.has("at_war"))
	runner.check_eq("intel.treasury = tesoro real de Francia", h.treasury("france"), SafeDict.as_int(intel.get("treasury"), -1))
	runner.check("intel.armies cuenta los ejércitos franceses", SafeDict.as_int(intel.get("army_count"), 0) > 0)
	# Persistencia en el estado y en el guardado.
	var stored: Dictionary = h.intel("england", "france")
	runner.check("el informe queda en state.factions[england].intel[france]", not stored.is_empty())
	runner.check("el estado con intel es JSON serializable", JSON.stringify(h.state()).length() > 1000)
	runner.check("guardar partida con intel", h.save_game("espionage_test"))
	runner.check("cargar partida con intel", h.load_game("espionage_test"))
	runner.check("el intel persiste tras guardar/cargar", not h.intel("england", "france").is_empty())
	runner.check("el informe no se mezcla con otras facciones", h.intel("england", "castile").is_empty())


func _check_failure(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	# Astucia mínima + relación pésima → probabilidad mínima (15%).
	h.character("edward_iii_plantagenet")["stats"]["intrigue"] = 1
	h.set_relation("england", "france", -100)
	var failed: Dictionary = {}
	var attempts: int = 0
	var intel_before: Dictionary = h.intel("england", "france").duplicate(true)
	while failed.is_empty() and attempts < 25:
		attempts += 1
		h.faction("england")["pg"] = 60
		h.reset_turn_actions()
		var intel_previous: Dictionary = h.intel("england", "france").duplicate(true)
		var result: Dictionary = h.propose("england", "france", {"action": "espia"})
		if not bool(result.get("accepted")):
			failed = result
			intel_before = intel_previous
	runner.check("espionaje puede fracasar y ser descubierto", not failed.is_empty(), "intentos=%d" % attempts)
	if not failed.is_empty():
		runner.check_eq("motivo del fracaso", "failed", SafeDict.as_string(failed.get("reason"), ""))
		runner.check("el fracaso no devuelve intel", SafeDict.as_dict(failed.get("intel", null)).is_empty())
		runner.check("un fracaso no modifica el intel guardado",
			JSON.stringify(h.intel("england", "france")) == JSON.stringify(intel_before))
		runner.check("ser descubierto empeora la relación", h.relation("england", "france") < -100 + 5)


func _check_determinism(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.character("edward_iii_plantagenet")["stats"]["intrigue"] = 70
	h.set_relation("england", "france", -40)
	h.faction("england")["pg"] = 60
	var first: Dictionary = h.propose("england", "france", {"action": "espia"})
	h.new_game("england", 1337)
	h.character("edward_iii_plantagenet")["stats"]["intrigue"] = 70
	h.set_relation("england", "france", -40)
	h.faction("england")["pg"] = 60
	var second: Dictionary = h.propose("england", "france", {"action": "espia"})
	runner.check_eq("espionaje determinista con la misma semilla y estado",
		JSON.stringify(first), JSON.stringify(second))
	runner.check_eq("misma probabilidad calculada", SafeDict.as_float(first.get("chance"), 0.0),
		SafeDict.as_float(second.get("chance"), 0.0))
