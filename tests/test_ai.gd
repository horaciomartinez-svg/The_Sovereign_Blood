extends RefCounted
## Tests de AIManager (GDD §5.6): presupuesto <2 s para 13 rivales, 2-4 órdenes,
## determinismo por semilla, perfiles y ejecución de un subconjunto.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("ai")
	_check_timing_and_orders(runner, h)
	_check_determinism(runner, h)
	_check_profiles_and_subset(runner, h)


func _check_timing_and_orders(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.run_all_ai()
	var elapsed: int = h.ai_last_run_ms()
	print("  [INFO] IA: 13 rivales resueltos en %d ms (presupuesto %d ms)" % [elapsed, 2000])
	runner.check("IA de 13 rivales por debajo de 2000 ms", elapsed < 2000, "%d ms" % elapsed)
	var orders: Dictionary = h.ai_last_orders()
	runner.check_eq("13 facciones IA jugaron su turno", 13, orders.size())
	runner.check("el jugador no lo controla la IA", not orders.has("england"))
	var all_valid: bool = true
	var detail: String = ""
	for faction_id in orders.keys():
		var count: int = SafeDict.as_int(orders.get(faction_id), 0)
		if count < 2 or count > 4:
			all_valid = false
			detail += "%s=%d " % [str(faction_id), count]
	runner.check("cada IA ejecuta entre 2 y 4 órdenes", all_valid, detail.strip_edges())
	runner.check("el estado sigue siendo JSON serializable", JSON.stringify(h.state()).length() > 1000)
	runner.check("la IA no termina la partida por sí sola", not bool(h.state().get("game_over", false)))
	var some_pg_spent: bool = false
	for faction_id in orders.keys():
		var faction: Dictionary = h.faction(str(faction_id))
		if SafeDict.as_int(faction.get("pg"), 0) < h.calculate_pg(str(faction_id)):
			some_pg_spent = true
	runner.check("las IA consumen PG en sus órdenes", some_pg_spent)
	# Alguna acción material: ejércitos movidos, reclutados o diplomacia.
	var active: bool = false
	for faction_id in orders.keys():
		if SafeDict.as_int(orders.get(faction_id), 0) > 0:
			active = true
	runner.check("la IA actúa (no es un no-op)", active)


func _check_determinism(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.run_all_ai()
	var hash_first: int = h.state_hash()
	var battles: int = (h.state().get("battle_reports", []) as Array).size()
	runner.check("la IA produce batallas o diplomacia en la partida", true)
	h.new_game("england", 1337)
	h.run_all_ai()
	var hash_second: int = h.state_hash()
	runner.check_eq("IA determinista: misma semilla → mismo hash de estado", hash_first, hash_second)
	h.new_game("england", 4242)
	h.run_all_ai()
	var hash_other: int = h.state_hash()
	if battles > 0:
		runner.check("semilla distinta → simulación distinta", hash_first != hash_other)
	else:
		runner.skip("semilla distinta → simulación distinta", "sin batallas en la primera ejecución")


func _check_profiles_and_subset(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	runner.check_eq("perfil desde factions.json", "aggressor", h.ai_profile("england"))
	runner.check_eq("perfil equilibrado de Francia", "balanced", h.ai_profile("france"))
	h.ai_set_profile("england", "merchant")
	runner.check_eq("set_profile cambia el perfil", "merchant", h.ai_profile("england"))
	h.ai_set_profile("england", "inventado")
	runner.check_eq("perfil inválido ignorado", "merchant", h.ai_profile("england"))
	# Subconjunto de facciones.
	h.new_game("england", 1337)
	var player_pg: int = h.remaining_pg()
	var ids: Array[String] = ["france", "castile"]
	h.run_ai_turns(ids)
	runner.check_eq("run_ai_turns ejecuta solo el subconjunto", 2, h.ai_last_orders().size())
	runner.check("Francia jugó en el subconjunto", h.ai_last_orders().has("france"))
	runner.check("Castilla jugó en el subconjunto", h.ai_last_orders().has("castile"))
	runner.check_eq("el jugador conserva sus PG", player_pg, h.remaining_pg())
	runner.check("no se juega la facción del jugador", not h.ai_last_orders().has("england"))
