extends RefCounted
## Tests de GameState (contrato Fase 1 §1/§6): new_game, forma del estado,
## save/load con hash exacto y continuidad del RNG, reset y validación.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const RNGScript = preload("res://scripts/utils/rng.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("game_state")
	_check_new_game(runner, h)
	_check_save_load(runner, h)
	_check_validation(runner, h)
	_check_reset(runner, h)


func _check_new_game(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var st: Dictionary = h.state()
	runner.check("new_game construye el estado", not st.is_empty())
	runner.check_eq("save_version", 1, st.get("save_version"))
	runner.check_eq("scenario_id", "scenario_1337", st.get("scenario_id"))
	runner.check_eq("player_faction", "england", st.get("player_faction"))
	runner.check_eq("año inicial", 1337, h.year())
	runner.check_eq("quarter inicial", 1, h.quarter())
	runner.check_eq("turno inicial", 1, st.get("turn"))
	runner.check_eq("14 facciones", 14, h.factions().size())
	runner.check_eq("47 regiones", 47, h.regions().size())
	runner.check_eq("86 personajes", 86, h.characters().size())
	runner.check_eq("35 ejércitos iniciales", 35, h.armies().size())
	runner.check("el estado es JSON serializable", JSON.stringify(st).length() > 1000)
	runner.check("todas las facciones tienen gobernante", _all_rulers_present(h), _missing_rulers(h))
	runner.check_eq("gobernante de Inglaterra", "edward_iii_plantagenet", h.faction("england")["ruler_id"])
	runner.check_eq("heredero de Inglaterra", "eduardo_el_principe_negro", h.faction("england")["heir_id"])
	runner.check("Escocia empieza en regencia (David II, 13 años)",
		str(h.faction("scotland")["regent_id"]) != "" and int(h.faction("scotland")["regency_until"]) == 1338)
	runner.check_eq("Granada sin heredero nacido aún", "", h.faction("granada")["heir_id"])
	runner.check_eq("tesorería inicial de Inglaterra", 8000, h.treasury("england"))
	runner.check_eq("apoyo inicial de Londres", 60, h.support("region_londres"))
	var workers: Dictionary = h.region("region_londres")["workers"]
	var workers_total: int = int(workers["farmers"]) + int(workers["artisans"]) + int(workers["merchants"]) + int(workers["recruits"])
	runner.check_eq("mano de obra de Londres (120000/200)", 600, workers_total)
	runner.check_eq("pool inicial = recruits × 200", int(workers["recruits"]) * 200, h.recruitment_pool("region_londres"))
	# Evento histórico de arranque (GDD §4.2): casus belli y relación anglo-francesa.
	var fired: Array = st.get("fired_events", [])
	runner.check("evento de 1337 disparado", fired.has("guerra_cien_anos_1337"), str(fired))
	runner.check_eq("relación Inglaterra-Francia tras el evento", -60, h.relation("england", "france"))
	runner.check("casus belli inglés sobre Francia", h.faction("england")["casus_belli"].has("france"))
	runner.check_eq("log de eventos con el arranque", 1, (st.get("event_log", []) as Array).size())
	# Reloj y PG coherentes con TurnManager.
	runner.check_eq("PG inicial de Inglaterra (30+5+3)", 38, h.remaining_pg())
	runner.check_eq("jugador activo", "england", h.player())


func _all_rulers_present(h: HarnessScript) -> bool:
	return _missing_rulers(h) == ""


func _missing_rulers(h: HarnessScript) -> String:
	var missing: String = ""
	for faction_id in h.factions().keys():
		var faction: Dictionary = h.faction(str(faction_id))
		var ruler_id: String = str(faction.get("ruler_id", ""))
		if ruler_id == "" or h.character(ruler_id).is_empty():
			missing += str(faction_id) + " "
	return missing.strip_edges()


func _check_save_load(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var hash_before: int = h.state_hash()
	var snapshot_before: Dictionary = h.snapshot_rng()
	runner.check("save_game escribe el slot", h.save_game("test_hash"))
	runner.check("has_save detecta el guardado", h.has_save("test_hash"))
	runner.check("to_dict incluye el snapshot del RNG",
		h.to_dict().has("rng") and (h.to_dict()["rng"] as Dictionary).has("state"))
	h.advance_quarter()
	runner.check("mutar la partida cambia el hash", h.state_hash() != hash_before)
	runner.check("load_game restaura el slot", h.load_game("test_hash"))
	runner.check_eq("hash exacto to_dict→JSON→from_dict→to_dict (A4)", hash_before, h.state_hash())
	runner.check("rng restaurado tras cargar", h.snapshot_rng() == snapshot_before)
	var json_a: String = h.state_json()
	# Continuidad exacta del RNG: misma siguiente tirada que una copia de la semilla.
	var reference: RNGScript = RNGScript.new(1337)
	reference.restore(snapshot_before)
	var expected: int = reference.next_int(0, 1000000)
	var rng_object: Variant = h.rng()
	var actual: int = int(rng_object.call("next_int", 0, 1000000))
	runner.check_eq("continuidad del RNG tras cargar", expected, actual)
	# JSON de ida y vuelta estable byte a byte (se recarga para deshacer la tirada).
	runner.check("load_game de nuevo", h.load_game("test_hash"))
	runner.check_eq("JSON canónico estable", json_a, h.state_json())
	# Guardado en disco legible con save_version 1.
	var path := "user://saves/test_hash.json"
	runner.check("archivo de guardado existe", FileAccess.file_exists(path))
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null:
		var text := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(text)
		runner.check("guardado en disco es JSON válido", parsed is Dictionary)
		if parsed is Dictionary:
			runner.check_eq("save_version en disco", 1, (parsed as Dictionary).get("save_version"))
			runner.check("guardado incluye event_log", (parsed as Dictionary).has("event_log"))


func _check_validation(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.check("from_dict rechaza versión desconocida",
		not bool(h.gs.call("from_dict", {"save_version": 99})))
	runner.check("from_dict rechaza snapshot sin claves",
		not bool(h.gs.call("from_dict", {"save_version": 1})))
	var valid: Dictionary = h.to_dict()
	runner.check("from_dict acepta snapshot canónico", bool(h.gs.call("from_dict", valid)))
	runner.check("autosave se escribe al avanzar el año", _autosave_written(h))


func _autosave_written(h: HarnessScript) -> bool:
	h.new_game("england", 1337)
	h.advance_year()
	return h.has_save("autosave")


func _check_reset(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.gs.call("reset")
	runner.check("reset vacía el estado", h.state().is_empty())
	runner.check("reset detiene la partida", not bool(h.gs.get("is_running")))
	runner.check_eq("reset devuelve el año a 0", 0, h.year())
	h.new_game("england", 1337)
	runner.check_eq("se puede empezar de nuevo tras reset", 1337, h.year())
