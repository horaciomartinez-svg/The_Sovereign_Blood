extends RefCounted
## Tests del sistema de eventos (GDD §7.6, §13): arranque de 1337, eventos de
## guerra, Peste Negra 1348 con population_modifier -0.35 y formato del log.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("events")
	_check_initial_event(runner, h)
	_check_black_death(runner, h)
	_check_war_events(runner, h)
	_check_event_log_shape(runner, h)


func _check_initial_event(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	runner.check("evento de 1337 en fired_events", _fired(h, "guerra_cien_anos_1337"))
	runner.check_eq("relación anglo-francesa tras el evento", -60, h.relation("england", "france"))
	runner.check("el evento concede casus belli a Inglaterra", (h.faction("england")["casus_belli"] as Dictionary).has("france"))
	runner.check_eq("el evento se registra una sola vez", 1, _count(h, "guerra_cien_anos_1337"))
	runner.check("el log guarda el texto del evento", _find_text(h, "guerra_cien_anos_1337").length() > 20)


func _check_black_death(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var population_before: int = _population_of_owned(h, "england")
	var london_before: int = SafeDict.as_int(h.region("region_londres").get("population"), 0)
	while h.year() < 1348:
		h.advance_year()
	runner.check_eq("el reloj llega a 1348", 1348, h.year())
	runner.check("Peste Negra disparada en 1348", _fired(h, "peste_negra_1348"))
	var london_after: int = SafeDict.as_int(h.region("region_londres").get("population"), 0)
	var population_after: int = _population_of_owned(h, "england")
	var ratio: float = float(population_after) / float(maxi(1, population_before))
	runner.check("Peste Negra aplica population_modifier -0.35 (ratio 0.65)",
		absf(ratio - 0.65) < 0.01, "ratio=%.4f (Londres %d → %d)" % [ratio, london_before, london_after])
	runner.check("la población de Londres cae un 35%", london_after == int(roundf(float(london_before) * 0.65)),
		"%d → %d" % [london_before, london_after])
	var count_before: int = _count(h, "peste_negra_1348")
	h.advance_year()
	runner.check_eq("el evento no se repite los años siguientes", count_before, _count(h, "peste_negra_1348"))
	var entry: Dictionary = _find_entry(h, "peste_negra_1348")
	runner.check("la entrada del log tiene año, trimestre, id y texto",
		not entry.is_empty() and entry.has("year") and entry.has("quarter")
		and entry.has("event_id") and str(entry.get("text", "")) != "")
	runner.check_eq("año del evento en el log", 1348, SafeDict.as_int(entry.get("year"), 0))


func _check_war_events(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	while h.year() < 1340:
		h.advance_year()
	runner.check("Sluys no dispara sin guerra", not _fired(h, "batalla_sluys_1340"))
	var prestige_before: int = SafeDict.as_int(h.faction("england").get("prestige"), 0)
	h.faction("england")["pg"] = 60
	h.propose("england", "france", {"type": "declare_war"})
	runner.check("declarar la guerra en 1340 dispara Sluys", _fired(h, "batalla_sluys_1340"))
	runner.check("Sluys da prestigio a Inglaterra",
		SafeDict.as_int(h.faction("england").get("prestige"), 0) > prestige_before,
		"%d → %d" % [prestige_before, SafeDict.as_int(h.faction("england").get("prestige"), 0)])
	# Con la guerra activa, Crecy (1346) se dispara al alcanzar el año.
	while h.year() < 1346:
		h.advance_year()
	runner.check("Crécy dispara con la guerra activa en 1346", _fired(h, "batalla_crecy_1346"))
	var france_men: int = _faction_men(h, "france")
	runner.check("Crécy causa bajas al ejército francés (army_loss)", france_men < 3000,
		"hombres franceses=%d" % france_men)


func _check_event_log_shape(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	for _year in 3:
		h.advance_year()
	var log: Array = h.state().get("event_log", [])
	runner.check("el log tiene entradas", log.size() > 0, str(log.size()))
	var shape_ok: bool = true
	var limit: int = mini(log.size(), 10)
	for index in limit:
		var entry: Dictionary = SafeDict.as_dict(log[index])
		if not entry.has("year") or not entry.has("quarter") or not entry.has("event_id") or not entry.has("text"):
			shape_ok = false
	runner.check("todas las entradas del log tienen el formato del contrato", shape_ok)
	var fired: Array = h.state().get("fired_events", [])
	var unique: Dictionary = {}
	for event_id in fired:
		unique[str(event_id)] = true
	runner.check_eq("fired_events sin duplicados", fired.size(), unique.size())


# --- helpers -------------------------------------------------------------

func _fired(h: HarnessScript, event_id: String) -> bool:
	return (h.state().get("fired_events", []) as Array).has(event_id)


func _count(h: HarnessScript, event_id: String) -> int:
	var count: int = 0
	for entry_value in (h.state().get("event_log", []) as Array):
		var entry: Dictionary = SafeDict.as_dict(entry_value)
		if SafeDict.as_string(entry.get("event_id"), "") == event_id:
			count += 1
	return count


func _find_entry(h: HarnessScript, event_id: String) -> Dictionary:
	for entry_value in (h.state().get("event_log", []) as Array):
		var entry: Dictionary = SafeDict.as_dict(entry_value)
		if SafeDict.as_string(entry.get("event_id"), "") == event_id:
			return entry
	return {}


func _find_text(h: HarnessScript, event_id: String) -> String:
	return SafeDict.as_string(_find_entry(h, event_id).get("text"), "")


func _population_of_owned(h: HarnessScript, faction_id: String) -> int:
	var total: int = 0
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			total += SafeDict.as_int(region.get("population"), 0)
	return total


func _faction_men(h: HarnessScript, faction_id: String) -> int:
	var total: int = 0
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			total += SafeDict.as_int(unit.get("size"), 0)
	return total
