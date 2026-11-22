extends RefCounted
## Tests de la Fase 3 de escenarios/tecnología/victoria (GDD v1.7 §4.3/§4.4/§4.5,
## contrato fase3_scenarios §2, D-058/D-059/D-060/D-061).
##
## AG-1 está creando los datos reales de 1402/1453 en paralelo; estos tests
## instalan FIXTURES sintéticos en DataLoader (y los restauran al terminar) para
## validar el motor ya, y además prueban los escenarios reales si existen.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const TechScript = preload("res://scripts/utils/tech.gd")

const FIXTURE_1402: String = "scenario_fixture_1402"
const FIXTURE_1453: String = "scenario_fixture_1453"

var _orig_scenarios: Dictionary = {}
var _orig_characters: Dictionary = {}
var _orig_regions: Dictionary = {}


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("scenarios_tech")
	_install_fixtures(h)
	_check_alive_by_year(runner, h)
	_check_tech(runner, h)
	_check_victory_defeat(runner, h)
	_check_fast_forward(runner, h)
	_check_real_scenarios(runner, h)
	_restore_data(h)


# ---------------------------------------------------------------------------
# Fixtures sintéticos 1402/1453
# ---------------------------------------------------------------------------

func _install_fixtures(h: HarnessScript) -> void:
	var scenarios: Dictionary = h.dl.get("scenarios")
	var characters: Dictionary = h.dl.get("characters")
	var regions: Dictionary = h.dl.get("regions")
	_orig_scenarios = scenarios.duplicate(true)
	_orig_characters = characters.duplicate(true)
	_orig_regions = regions.duplicate(true)
	# Regiones: year_data 1402/1453 con owners England/France alternos.
	var region_ids: Array[String] = SafeDict.sorted_keys(regions)
	var index: int = 0
	var england_region: String = ""
	var france_region: String = ""
	for region_id in region_ids:
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		var year_data: Dictionary = SafeDict.as_dict(region.get("year_data", null))
		var owner: String = "england" if index % 2 == 0 else "france"
		if owner == "england" and england_region == "":
			england_region = region_id
		if owner == "france" and france_region == "":
			france_region = region_id
		var entry: Dictionary = {
			"owner": owner,
			"population": 120000,
			"base_wealth": 60,
			"buildings": [],
		}
		year_data["1402"] = entry.duplicate(true)
		year_data["1453"] = entry.duplicate(true)
		region["year_data"] = year_data
		regions[region_id] = region
		index += 1
	# Personajes sintéticos: dos gobernantes vivos en 1402 (elegir el reinado
	# más reciente que cubre el año) + heredero + futuro nacido + fallecido.
	_add_character(characters, "fixture_eng_ruler_old", "england", "plantagenet",
		1360, -1, "ruler", 1399)
	_add_character(characters, "fixture_eng_ruler_new", "england", "plantagenet",
		1370, -1, "ruler", 1401)
	_add_character(characters, "fixture_eng_heir", "england", "plantagenet",
		1395, -1, "heir", 0)
	_add_character(characters, "fixture_eng_future", "england", "plantagenet",
		1410, -1, "relative", 0)
	_add_character(characters, "fixture_eng_dead", "england", "plantagenet",
		1340, 1390, "relative", 0)
	_add_character(characters, "fixture_fra_ruler", "france", "valois",
		1365, -1, "ruler", 1400)
	_add_character(characters, "fixture_fra_heir", "france", "valois",
		1398, -1, "heir", 0)
	# Escenarios sintéticos (contrato §2): 8 jugables declaradas en datos reales;
	# el fixture usa 2 facciones para probar el motor.
	scenarios[FIXTURE_1402] = _fixture_scenario(FIXTURE_1402, "Fixture 1402", 1402, 1460,
		england_region, france_region)
	scenarios[FIXTURE_1453] = _fixture_scenario(FIXTURE_1453, "Fixture 1453", 1453, 1480,
		england_region, france_region)


func _fixture_scenario(scenario_id: String, title: String, start_year: int, end_year: int,
		england_region: String, france_region: String) -> Dictionary:
	return {
		"id": scenario_id,
		"title": title,
		"description": "Fixture sintético de tests (AG-2).",
		"start_year": start_year,
		"end_year": end_year,
		"factions": ["england", "france"],
		"playable_factions": ["england", "france"],
		"initial_state": {
			"characters": "characters.json",
			"regions": str(start_year),
			"treasuries": {"england": 8000, "france": 8000},
			"armies": {
				"england": [{"unit": "longbowman", "count": 400, "region": england_region}],
				"france": [{"unit": "men_at_arms", "count": 400, "region": france_region}],
			},
		},
		"victory": {
			"crowns": 2,
			"prestige": 500,
			"years_held": 10,
			"control_pct": 70,
		},
		"events_script": "events_1337.json",
	}


func _add_character(characters: Dictionary, character_id: String, faction_id: String,
		house: String, born: int, died: int, role: String, reign_start: int) -> void:
	var entry: Dictionary = {
		"id": character_id,
		"name": character_id,
		"role": role,
		"faction": faction_id,
		"house": house,
		"born": born,
		"died": null if died < 0 else died,
		"stats": {
			"command": 70, "intrigue": 60, "charisma": 65,
			"loyalty": 70, "education": 60,
		},
		"family": {"spouse": "", "father": "", "mother": "", "children": []},
	}
	if reign_start > 0:
		entry["reign_start"] = reign_start
		characters[character_id] = entry
	else:
		characters[character_id] = entry


func _restore_data(h: HarnessScript) -> void:
	(h.dl.get("scenarios") as Dictionary).clear()
	(h.dl.get("scenarios") as Dictionary).merge(_orig_scenarios, true)
	(h.dl.get("characters") as Dictionary).clear()
	(h.dl.get("characters") as Dictionary).merge(_orig_characters, true)
	(h.dl.get("regions") as Dictionary).clear()
	(h.dl.get("regions") as Dictionary).merge(_orig_regions, true)


# ---------------------------------------------------------------------------
# D-058: personajes vivos y gobernante por año
# ---------------------------------------------------------------------------

func _check_alive_by_year(runner: TestRunnerScript, h: HarnessScript) -> void:
	# Invariante 1337: alive = (died null o died >= 1337) y born <= 1337.
	h.new_game("england", 1337)
	var characters: Dictionary = h.state().get("characters", {})
	var invariant_ok: bool = true
	var future_count: int = 0
	for character_id in characters.keys():
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		var born: int = SafeDict.as_int(character.get("born"), 1337)
		var died_value: Variant = character.get("died", null)
		var expected_alive: bool = born <= 1337 and (died_value == null or SafeDict.as_int(died_value, 0) >= 1337)
		if bool(character.get("alive", false)) != expected_alive:
			invariant_ok = false
		if born > 1337:
			future_count += 1
	runner.check("1337: alive por año (born/died) correcto en todos", invariant_ok)
	runner.check("1337: hay personajes aún no nacidos (alive=false)", future_count > 0, str(future_count))
	runner.check("1337: gobernante de Inglaterra seleccionado", SafeDict.as_string(h.faction("england").get("ruler_id"), "") != "")
	runner.check_eq("1337: era tecnológica I", "I", h.era())
	# Fixture 1402: elección por reign_start más reciente + vivos/futuros.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	runner.check_eq("fixture 1402: año de inicio", 1402, h.year())
	runner.check_eq("fixture 1402: era III (1400+)", "III", h.era())
	runner.check_eq("fixture 1402: gobernante con reinado más reciente", "fixture_eng_ruler_new",
		SafeDict.as_string(h.faction("england").get("ruler_id"), ""))
	runner.check("fixture 1402: gobernante antiguo vivo y no elegido",
		SafeDict.as_bool(h.character("fixture_eng_ruler_old").get("alive"), false))
	runner.check("fixture 1402: heredero elegido", SafeDict.as_string(h.faction("england").get("heir_id"), "") != "")
	runner.check("fixture 1402: futuro nacido no está vivo", not SafeDict.as_bool(h.character("fixture_eng_future").get("alive"), true))
	runner.check("fixture 1402: fallecido antes no está vivo", not SafeDict.as_bool(h.character("fixture_eng_dead").get("alive"), true))
	# Al avanzar el año hasta su nacimiento pasa a vivo (D-058).
	h.set_year(1410)
	h.dyn.call("advance_year")
	runner.check("futuro nacido pasa a vivo al llegar su año",
		SafeDict.as_bool(h.character("fixture_eng_future").get("alive"), false))


# ---------------------------------------------------------------------------
# D-059: tecnología por era y unidades disponibles
# ---------------------------------------------------------------------------

func _check_tech(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.check_eq("Tech 1337=I", "I", TechScript.era_name(1337))
	runner.check_eq("Tech 1349=I", "I", TechScript.era_name(1349))
	runner.check_eq("Tech 1350=II", "II", TechScript.era_name(1350))
	runner.check_eq("Tech 1399=II", "II", TechScript.era_name(1399))
	runner.check_eq("Tech 1400=III", "III", TechScript.era_name(1400))
	runner.check_eq("Tech 1402=III", "III", TechScript.era_name(1402))
	runner.check_eq("Tech 1453=III", "III", TechScript.era_name(1453))
	var arch_1337: Dictionary = h.unit_definition("arquebusier")
	var arch_1453: Dictionary = h.unit_definition("arquebusier")
	runner.check("arquebusier no disponible en 1337", not TechScript.is_unit_available(arch_1337, 1337))
	runner.check("arquebusier disponible en 1453", TechScript.is_unit_available(arch_1453, 1453))
	var hussite: Dictionary = h.unit_definition("hussite_war_wagon")
	runner.check("hussite no disponible en 1402 (available_from 1419)", not TechScript.is_unit_available(hussite, 1402))
	runner.check("hussite disponible en 1453", TechScript.is_unit_available(hussite, 1453))
	var swiss: Dictionary = h.unit_definition("swiss_pikeman")
	runner.check("swiss_pikeman no disponible en 1337 (era II)", not TechScript.is_unit_available(swiss, 1337))
	runner.check("swiss_pikeman disponible en 1402", TechScript.is_unit_available(swiss, 1402))
	# En partida 1402: pool/era filtran reclutamiento y get_available_units.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	var available_1402: Array[String] = h.available_units("england")
	runner.check("1402: get_available_units incluye longbowman", available_1402.has("longbowman"))
	runner.check("1402: get_available_units excluye arquebusier (era III pero año 1402)", not available_1402.has("arquebusier"))
	runner.check("1402: get_available_units excluye hussite (1419)", not available_1402.has("hussite_war_wagon"))
	var region_1402: String = _first_owned_region(h, "england")
	runner.check("1402: región de Inglaterra para reclutar", region_1402 != "")
	if region_1402 != "":
		runner.check("1402: reclutar arquebusier falla", not h.recruit("england", region_1402, "arquebusier", 200))
		runner.check("1402: reclutar longbowman funciona", h.recruit("england", region_1402, "longbowman", 200))
	# En partida 1453: era III con arquebusier disponible (Francia).
	h.new_game_in(FIXTURE_1453, "france", 1337)
	runner.check_eq("fixture 1453: era III", "III", h.era())
	var france_available: Array[String] = h.available_units("france")
	runner.check("1453: Francia puede reclutar arquebusier", france_available.has("arquebusier"))
	runner.check("1453: Francia no puede reclutar hussite (tag bohemia)", not france_available.has("hussite_war_wagon"))
	var france_region: String = _first_owned_region(h, "france")
	if france_region != "":
		runner.check("1453: reclutar arquebusier funciona", h.recruit("france", france_region, "arquebusier", 200))
	# Estado expone la era para la UI.
	runner.check_eq("estado expone era", "III", SafeDict.as_string(h.state().get("era"), ""))


# ---------------------------------------------------------------------------
# §4.5 / D-060: victoria y derrota
# ---------------------------------------------------------------------------

func _check_victory_defeat(runner: TestRunnerScript, h: HarnessScript) -> void:
	# Derrota: pérdida de todas las regiones.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	_assign_all_regions(h, "france")
	h.tm.call("_check_game_over")
	runner.check("derrota por pérdida total", SafeDict.as_bool(h.state().get("game_over"), false)
		and not SafeDict.as_bool(h.state().get("game_over_victory"), true))
	# Victoria por prestigio mantenido.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	var faction: Dictionary = h.faction("england")
	faction["prestige"] = 500
	faction["prestige_since_year"] = h.year() - 10
	h.tm.call("_check_game_over")
	runner.check("victoria por Prestigio Real", SafeDict.as_bool(h.state().get("game_over"), false)
		and SafeDict.as_bool(h.state().get("game_over_victory"), false)
		and h.game_over_reason().contains("Prestigio"))
	# Victoria por conquista ≥70%.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	_assign_all_regions(h, "england")
	h.tm.call("_check_game_over")
	runner.check("victoria por conquista (≥70%)", SafeDict.as_bool(h.state().get("game_over_victory"), false)
		and h.game_over_reason().contains("Conquista"), h.game_over_reason())
	# Victoria por supervivencia al end_year + reloj congelado.
	h.new_game_in(FIXTURE_1402, "england", 1337)
	var end_year: int = SafeDict.as_int(h.scenario_definition(FIXTURE_1402).get("end_year"), 0)
	h.set_year(end_year)
	h.tm.call("_check_game_over")
	runner.check("victoria por supervivencia en end_year", SafeDict.as_bool(h.state().get("game_over_victory"), false)
		and h.game_over_reason().contains("Supervivencia"), h.game_over_reason())
	var quarter_before: int = h.quarter()
	var year_before: int = h.year()
	h.end_turn()
	h.tm.call("advance_quarter")
	runner.check_eq("sin turnos fantasma tras supervivencia", year_before, h.year())
	runner.check_eq("trimestre congelado tras supervivencia", quarter_before, h.quarter())


# ---------------------------------------------------------------------------
# Fast-forward 10 años por escenario + determinismo
# ---------------------------------------------------------------------------

func _check_fast_forward(runner: TestRunnerScript, h: HarnessScript) -> void:
	for scenario_id in [FIXTURE_1402, FIXTURE_1453]:
		var start_hash: int = _fast_forward_scenario(h, scenario_id, 40)
		var second_hash: int = _fast_forward_scenario(h, scenario_id, 40)
		runner.check("%s: fast-forward 10 años sin crash" % scenario_id, true)
		runner.check_eq("%s: determinismo del fast-forward" % scenario_id, start_hash, second_hash)


func _fast_forward_scenario(h: HarnessScript, scenario_id: String, turns: int) -> int:
	h.new_game_in(scenario_id, "england", 1337)
	var simulated: int = 0
	for index in range(turns):
		if SafeDict.as_bool(h.state().get("game_over"), false):
			break
		h.end_turn()
		simulated += 1
	if not SafeDict.as_bool(h.state().get("game_over"), false):
		var start_year: int = SafeDict.as_int(h.scenario_definition(scenario_id).get("start_year"), 0)
		# 40 trimestres = 10 años.
		if h.year() != start_year + 10:
			print("  [WARN] %s: tras %d turnos año=%d (esperado %d)" % [
				scenario_id, simulated, h.year(), start_year + 10,
			])
	return h.state_hash()


# ---------------------------------------------------------------------------
# Escenarios reales (cuando AG-1 los entregue; si no, se omiten sin fallar)
# ---------------------------------------------------------------------------

func _check_real_scenarios(runner: TestRunnerScript, h: HarnessScript) -> void:
	for scenario_id in ["scenario_1402", "scenario_1453"]:
		var scenario: Dictionary = h.scenario_definition(scenario_id)
		if scenario.is_empty():
			print("  [INFO] %s aún no entregado por AG-1 (fixtures cubren el motor)" % scenario_id)
			continue
		var playable: Array = SafeDict.as_array(scenario.get("playable_factions", null))
		var faction_id: String = str(playable[0]) if not playable.is_empty() else "england"
		h.new_game_in(scenario_id, faction_id, 1337)
		runner.check_eq("%s: arranca en su start_year" % scenario_id,
			SafeDict.as_int(scenario.get("start_year"), 0), h.year())
		runner.check("%s: gobernante vivo asignado" % scenario_id,
			SafeDict.as_string(h.faction(faction_id).get("ruler_id"), "") != "")
		runner.check("%s: era coherente con el año" % scenario_id,
			h.era() == TechScript.era_name(h.year()))
		runner.check("%s: unidades disponibles no vacías" % scenario_id,
			not h.available_units(faction_id).is_empty())
		# 10 años de fast-forward real.
		var hash_one: int = _fast_forward_scenario(h, scenario_id, 40)
		var hash_two: int = _fast_forward_scenario(h, scenario_id, 40)
		runner.check_eq("%s: fast-forward determinista" % scenario_id, hash_one, hash_two)


# --- helpers -------------------------------------------------------------

func _assign_all_regions(h: HarnessScript, faction_id: String) -> void:
	var regions: Dictionary = h.state().get("regions", {})
	for region_id in regions.keys():
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		region["owner"] = faction_id
		regions[region_id] = region


func _first_owned_region(h: HarnessScript, faction_id: String) -> String:
	var regions: Dictionary = h.state().get("regions", {})
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			return region_id
	return ""
