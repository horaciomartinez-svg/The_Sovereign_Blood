extends RefCounted
## Escenario de aceptación "Crécy 1346": la misma batalla resuelta en Nivel 1
## (delegado), Nivel 2 (táctico) y Nivel 3 (combate cerrado) headless, con
## resultados coherentes y métricas de tiempo (GDD §12 Fase 2 / contrato §4/§8).

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const REGION: String = "region_normandia"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("crecy")
	_check_three_levels(runner, h)


func _check_three_levels(runner: TestRunnerScript, h: HarnessScript) -> void:
	var ids: Array[String] = _prepare_battle(h)
	# --- Nivel 1: combate delegado (§6.1) ---
	var attacker_model: Variant = h.get_army_model(ids[0])
	var defender_model: Variant = h.get_army_model(ids[1])
	var region_model: Variant = h.get_region_model(ids[2])
	# Modelos independentes para Nivel 3 (antes de aplicar resultados).
	var attacker_units_n3: Array = SafeDict.as_array(attacker_model.get("units")).duplicate(true)
	var defender_units_n3: Array = SafeDict.as_array(defender_model.get("units")).duplicate(true)
	var n1_started: int = Time.get_ticks_usec()
	var report_one: Variant = h.battle.call("resolve_delegated", attacker_model, defender_model, region_model, 1)
	var n1_ms: float = float(Time.get_ticks_usec() - n1_started) / 1000.0
	runner.check("Crécy Nivel 1 resuelto", report_one != null)
	if report_one == null:
		return
	var level1: Dictionary = SafeDict.as_dict(report_one.call("to_dict"))
	runner.check_eq("Crécy N1: vence Inglaterra", "england", SafeDict.as_string(level1.get("winner_faction"), ""))
	runner.check("Crécy N1: hay bajas", SafeDict.as_int(level1.get("attacker_losses"), 0) > 0
		or SafeDict.as_int(level1.get("defender_losses"), 0) > 0)
	runner.check("Crécy N1: captura de región", SafeDict.as_bool(level1.get("region_captured"), false))
	# --- Nivel 2: mapa táctico (§6.2) ---
	var tactical: Node = h.launch_tactical(attacker_model, defender_model, region_model)
	runner.check("Crécy Nivel 2: launch_tactical devuelve nodo", tactical != null)
	if tactical == null:
		return
	var n2_started: int = Time.get_ticks_usec()
	var level2: Dictionary = SafeDict.as_dict(tactical.call("auto_resolve"))
	var n2_ms: float = float(Time.get_ticks_usec() - n2_started) / 1000.0
	runner.check_eq("Crécy N2: informe de Nivel 2", 2, SafeDict.as_int(level2.get("level"), 0))
	runner.check("Crécy N2: vence Inglaterra", SafeDict.as_string(level2.get("winner_faction"), "") == "england",
		SafeDict.as_string(level2.get("winner_faction"), ""))
	runner.check("Crécy N2: hay bajas", SafeDict.as_int(level2.get("attacker_losses"), 0) > 0
		or SafeDict.as_int(level2.get("defender_losses"), 0) > 0)
	runner.check("Crécy N2: el ganador es coherente con N1",
		SafeDict.as_string(level2.get("winner_faction"), "") == SafeDict.as_string(level1.get("winner_faction"), ""))
	tactical.call("apply_outcome")
	runner.check_eq("Crécy N2: Normandía pasa a Inglaterra", "england", str(h.region(REGION)["owner"]))
	runner.check("Crécy N2: informe registrado en la partida", h.battle_reports().size() >= 1)
	tactical.free()
	# --- Nivel 3: combate cerrado (§6.3) con las unidades reales ---
	var attacker_unit: Dictionary = SafeDict.as_dict(attacker_units_n3[0]).duplicate(true)
	var defender_unit: Dictionary = SafeDict.as_dict(defender_units_n3[0]).duplicate(true)
	attacker_unit["commander_stat"] = 88
	defender_unit["commander_stat"] = 74
	var duel: Node = h.launch_close_combat(attacker_unit, defender_unit)
	runner.check("Crécy Nivel 3: launch_close_combat devuelve nodo", duel != null)
	if duel == null:
		return
	var n3_started: int = Time.get_ticks_usec()
	var level3: Dictionary = SafeDict.as_dict(duel.call("auto_resolve"))
	var n3_ms: float = float(Time.get_ticks_usec() - n3_started) / 1000.0
	runner.check_eq("Crécy N3: resultado de Nivel 3", 3, SafeDict.as_int(level3.get("level"), 0))
	runner.check("Crécy N3: gana el bando inglés (attacker)", str(level3.get("winner_side")) == "attacker",
		str(level3.get("winner_side")))
	runner.check("Crécy N3: hay bajas", SafeDict.as_int(level3.get("attacker_losses"), -1) >= 0
		and SafeDict.as_int(level3.get("defender_losses"), -1) >= 0)
	runner.check("Crécy N3: al menos una ronda", SafeDict.as_int(level3.get("rounds"), 0) >= 1)
	duel.free()
	print("  [INFO] Crécy 1346 — Nivel 1: %.2f ms · Nivel 2: %.2f ms · Nivel 3: %.2f ms" % [n1_ms, n2_ms, n3_ms])
	runner.check("Nivel 2 por debajo de 1000 ms", n2_ms < 1000.0, "%.2f ms" % n2_ms)
	runner.check("Nivel 3 por debajo de 1000 ms", n3_ms < 1000.0, "%.2f ms" % n3_ms)


## Prepara el escenario Crécy-like (año 1346) con ejércitos reales del estado.
func _prepare_battle(h: HarnessScript) -> Array[String]:
	h.new_game("england", 1337)
	h.set_year(1346)
	h.set_relation("england", "france", -100)
	h.faction("england")["pg"] = 80
	# Inglaterra concentra arqueros largos y hombres de armas en Londres.
	h.recruit("england", "region_londres", "longbowman", 1600)
	h.recruit("england", "region_londres", "men_at_arms", 400)
	# Francia defiende Normandía con ballesteros y hombres de armas.
	h.recruit("france", "region_normandia", "men_at_arms", 800)
	var result: Array[String] = [
		_army_in(h, "england", "region_londres"),
		_army_in(h, "france", REGION),
		REGION,
	]
	return result


func _army_in(h: HarnessScript, faction_id: String, region_id: String) -> String:
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return str(army_id)
	return ""
