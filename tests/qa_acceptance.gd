extends SceneTree
## QA Aceptación Fase 1 — The Sovereign's Blood (AG-4).
##
## Uso:
##   godot --headless --path <repo> --script tests/qa_acceptance.gd
##
## Implementa los 6 criterios de aceptación de GDD §12 / contrato
## docs/architecture_contracts_fase1.md §9:
##   C1 Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash.
##   C2 IA de las 13 facciones IA en <2000 ms (medido).
##   C3 Save/load exacto: hash de to_dict() igual + continuidad del RNG.
##   C4 Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west).
##   C5 Batalla delegada con informe coherente y captura de región.
##   C6 Smoke UI: instanciar/free todas las escenas de scenes/** en headless.
##
## Reglas del harness:
## - Solo usa la API pública §2 y LEE `GameState.state`/`DataLoader` (nunca muta
##   archivos de producción ni escribe en data/).
## - Compila siempre: los sistemas ausentes o aún stub se detectan en ejecución
##   con has_method()/estado vacío y se reportan como [SKIP] justificado
##   ("pendiente"), no como crash.
## - Exit code: 0 SOLO si los 6 criterios son [PASS]. Cualquier [FAIL] (regresión
##   o criterio incumplido) o [SKIP] (sistema aún stub) devuelve 1 en el baseline.
##
## Sin GUT: runner mínimo propio (asserts nativos) para no acoplarse a tests de AG-2.

const PLAYER_FACTION: String = "england"
const SCENARIO_ID: String = "scenario_1337"
const SEED: int = 1337
const SAVE_SLOT: String = "qa_acceptance_ag4"
const AI_BUDGET_MS: int = 2000
const EXPECTED_AI_FACTIONS: int = 13
const MAX_SCENES_REPORTED: int = 8
const AUTOLOADS: Array[String] = [
	"EventBus", "DataLoader", "GameState", "TurnManager", "EconomySystem",
	"DynastySystem", "DiplomacySystem", "MilitarySystem", "BattleManager", "AIManager",
]

# Resultados: {id, name, status: "PASS"|"FAIL"|"SKIP", detail, ms}
var results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Aceptación Fase 1 (GDD §12 / contrato §9)")
	print(" Godot %s · headless · %s" % [
		str(Engine.get_version_info().get("string", "")),
		Time.get_datetime_string_from_system(),
	])
	print("==============================================================")
	_print_environment()
	_criterion_1_england_year()
	_criterion_2_ai_budget()
	_criterion_3_save_load()
	_criterion_4_black_death()
	_criterion_5_delegated_battle()
	_criterion_6_ui_smoke()
	_finish()


# ---------------------------------------------------------------------------
# Infraestructura del harness
# ---------------------------------------------------------------------------

func _autoload(autoload_name: String) -> Node:
	if root == null:
		return null
	return root.get_node_or_null(NodePath(autoload_name))


func _record(id: String, name: String, status: String, detail: String, started_ms: int) -> void:
	var elapsed := Time.get_ticks_msec() - started_ms
	results.append({"id": id, "name": name, "status": status, "detail": detail, "ms": elapsed})
	var suffix := ""
	if detail != "":
		suffix = " :: " + detail
	print("  [%s] %s — %s%s" % [status, id, name, suffix])


func _pass(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "PASS", detail, started_ms)


func _fail(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "FAIL", detail, started_ms)


func _skip(id: String, name: String, reason: String, started_ms: int) -> void:
	_record(id, name, "SKIP", reason + " (pendiente: sistema aún stub/no disponible)", started_ms)


func _hash(value: Variant) -> String:
	var text := JSON.stringify(value)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _read_json(res_path: String) -> Variant:
	if not FileAccess.file_exists(res_path):
		return null
	var text := FileAccess.get_file_as_string(res_path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	return parser.data


func _expected_counts() -> Dictionary:
	var result := {"factions": 14, "regions": 47}
	var factions_root: Variant = _read_json("res://data/factions.json")
	if factions_root is Dictionary and (factions_root as Dictionary).get("factions") is Array:
		result["factions"] = ((factions_root as Dictionary).get("factions") as Array).size()
	var regions_root: Variant = _read_json("res://data/regions.json")
	if regions_root is Dictionary and (regions_root as Dictionary).get("regions") is Array:
		result["regions"] = ((regions_root as Dictionary).get("regions") as Array).size()
	return result


func _print_environment() -> void:
	var counts := _expected_counts()
	print("[INFO] datasets esperados: %d facciones, %d regiones" % [int(counts["factions"]), int(counts["regions"])])
	var missing: Array[String] = []
	for autoload_name in AUTOLOADS:
		if _autoload(autoload_name) == null:
			missing.append(autoload_name)
	if missing.is_empty():
		print("[INFO] 10/10 autoloads montados")
	else:
		print("[WARN] autoloads ausentes: %s" % ", ".join(missing))
	var gs := _autoload("GameState")
	if gs == null:
		print("[WARN] GameState no disponible: los criterios de partida se reportarán SKIP")
	else:
		print("[INFO] GameState.state inicial: %s" % ("vacío" if _state_is_empty(gs) else "con datos"))


func _state() -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {}
	var st: Variant = gs.get("state")
	if st is Dictionary:
		return st as Dictionary
	return {}


func _state_is_empty(gs: Node) -> bool:
	var st: Variant = gs.get("state")
	return not (st is Dictionary) or (st as Dictionary).is_empty()


## Arranca una partida nueva limpia. Devuelve {ok, reason}.
func _ensure_game_started() -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {"ok": false, "reason": "GameState no montado"}
	if not gs.has_method("new_game"):
		return {"ok": false, "reason": "GameState.new_game() no declarado"}
	var dl := _autoload("DataLoader")
	if dl != null and dl.has_method("load_all"):
		dl.call("load_all")
	if gs.has_method("reset"):
		gs.call("reset")
	gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	if _state_is_empty(gs):
		return {"ok": false, "reason": "GameState.state vacío tras new_game()"}
	if not _state().has("factions"):
		return {"ok": false, "reason": "GameState.state sin clave 'factions'"}
	return {"ok": true, "reason": ""}


func _first_owned_region(state: Dictionary) -> String:
	var regions: Variant = state.get("regions", {})
	if not (regions is Dictionary):
		return ""
	for region_id in (regions as Dictionary).keys():
		var region_data: Variant = (regions as Dictionary)[region_id]
		if region_data is Dictionary and str((region_data as Dictionary).get("owner", "")) == PLAYER_FACTION:
			return str(region_id)
	return ""


# ---------------------------------------------------------------------------
# C1 — Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas
# ---------------------------------------------------------------------------

func _criterion_1_england_year() -> void:
	var started := Time.get_ticks_msec()
	var id := "C1"
	var name := "Partida Inglaterra 1337: new_game + 4 trimestres de órdenes válidas sin crash"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	if tm == null or not tm.has_method("begin_turn") or not tm.has_method("end_turn"):
		_skip(id, name, "TurnManager sin begin_turn()/end_turn() del contrato", started)
		return

	var state := _state()
	var counts := _expected_counts()
	var state_factions: Variant = state.get("factions", {})
	var state_regions: Variant = state.get("regions", {})
	var n_factions := (state_factions as Dictionary).size() if state_factions is Dictionary else 0
	var n_regions := (state_regions as Dictionary).size() if state_regions is Dictionary else 0
	if n_factions < int(counts["factions"]) or n_regions < int(counts["regions"]):
		_fail(id, name, "state inicial incompleto: %d/%d facciones, %d/%d regiones" % [
			n_factions, int(counts["factions"]), n_regions, int(counts["regions"]),
		], started)
		return

	var year0 := int(state.get("year", 0))
	var quarter0 := int(state.get("quarter", 0))
	var turns_advanced := 0
	var orders_attempted := 0
	var orders_accepted := 0
	for _q in range(4):
		tm.call("begin_turn", PLAYER_FACTION)
		var eco := _try_economy_order()
		if bool(eco["attempted"]):
			orders_attempted += 1
			if bool(eco["accepted"]):
				orders_accepted += 1
		var dip := _try_diplomacy_order()
		if bool(dip["attempted"]):
			orders_attempted += 1
			if bool(dip["accepted"]):
				orders_accepted += 1
		tm.call("end_turn")

	var final_state := _state()
	var year1 := int(final_state.get("year", year0))
	var quarter1 := int(final_state.get("quarter", quarter0))
	turns_advanced = (year1 - year0) * 4 + (quarter1 - quarter0)
	var detail := "año %d·T%d → %d·T%d (%d trimestres); órdenes intentadas=%d aceptadas=%d" % [
		year0, quarter0, year1, quarter1, turns_advanced, orders_attempted, orders_accepted,
	]
	if turns_advanced <= 0:
		_skip(id, name, "TurnManager.end_turn() no avanza el turno: " + detail, started)
		return
	if turns_advanced < 4:
		_fail(id, name, "solo %d/4 trimestres avanzados: %s" % [turns_advanced, detail], started)
		return
	if orders_attempted == 0:
		_fail(id, name, "sin órdenes ejecutables (EconomySystem.allocate/DiplomacySystem.propose stubs): " + detail, started)
		return
	if orders_accepted == 0:
		_fail(id, name, "ninguna orden aceptada (%d intentadas): %s" % [orders_attempted, detail], started)
		return
	_pass(id, name, detail, started)


func _try_economy_order() -> Dictionary:
	var eco := _autoload("EconomySystem")
	if eco == null or not eco.has_method("allocate"):
		return {"attempted": false, "accepted": false}
	var region := _first_owned_region(_state())
	if region == "":
		return {"attempted": false, "accepted": false}
	var outcome: Variant = eco.call("allocate", region, "farmers", 1)
	return {"attempted": true, "accepted": outcome is bool and bool(outcome)}


func _try_diplomacy_order() -> Dictionary:
	var dip := _autoload("DiplomacySystem")
	if dip == null or not dip.has_method("propose"):
		return {"attempted": false, "accepted": false}
	var outcome: Variant = dip.call("propose", PLAYER_FACTION, "france", {"type": "offer_tribute"})
	var accepted := outcome is Dictionary and not (outcome as Dictionary).is_empty()
	return {"attempted": true, "accepted": accepted}


# ---------------------------------------------------------------------------
# C2 — IA de las 13 facciones IA en <2000 ms
# ---------------------------------------------------------------------------

func _criterion_2_ai_budget() -> void:
	var started := Time.get_ticks_msec()
	var id := "C2"
	var name := "IA de 13 facciones rivales en <2000 ms (medido)"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var ai := _autoload("AIManager")
	var gs := _autoload("GameState")
	if ai == null or not ai.has_method("run_all_ai"):
		_skip(id, name, "AIManager.run_all_ai() no declarado", started)
		return

	var ai_factions := _count_ai_factions(_state())
	if ai_factions != EXPECTED_AI_FACTIONS:
		_fail(id, name, "%d facciones IA en state (se esperaban %d)" % [ai_factions, EXPECTED_AI_FACTIONS], started)
		return

	var hash_before := _hash(_state())
	var t0 := Time.get_ticks_msec()
	ai.call("run_all_ai")
	var elapsed := Time.get_ticks_msec() - t0
	var hash_after := _hash(_state())
	if hash_before == hash_after and elapsed < 20:
		_skip(id, name, "AIManager.run_all_ai() no altera el estado (%d ms): stub" % elapsed, started)
		return
	if elapsed >= AI_BUDGET_MS:
		_fail(id, name, "presupuesto IA excedido: %d ms ≥ %d ms" % [elapsed, AI_BUDGET_MS], started)
		return
	if hash_before == hash_after:
		_fail(id, name, "la IA no produjo cambios de estado (%d ms)" % elapsed, started)
		return
	_pass(id, name, "%d facciones IA en %d ms (< %d ms)" % [ai_factions, elapsed, AI_BUDGET_MS], started)


func _count_ai_factions(state: Dictionary) -> int:
	var factions: Variant = state.get("factions", {})
	if not (factions is Dictionary):
		return 0
	var count := 0
	for faction_id in (factions as Dictionary).keys():
		var faction_data: Variant = (factions as Dictionary)[faction_id]
		if faction_data is Dictionary and not bool((faction_data as Dictionary).get("is_player", false)):
			count += 1
	return count


# ---------------------------------------------------------------------------
# C3 — Save/load exacto (hash de to_dict) + continuidad del RNG
# ---------------------------------------------------------------------------

func _criterion_3_save_load() -> void:
	var started := Time.get_ticks_msec()
	var id := "C3"
	var name := "Save/load exacto: hash de to_dict() igual + continuidad del RNG"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var gs := _autoload("GameState")
	var required: Array[String] = ["to_dict", "save_game", "load_game"]
	for method_name in required:
		if not gs.has_method(method_name):
			_skip(id, name, "GameState.%s() no declarado" % method_name, started)
			return

	var before: Variant = gs.call("to_dict")
	if not (before is Dictionary) or (before as Dictionary).is_empty():
		_skip(id, name, "GameState.to_dict() devuelve vacío: stub", started)
		return
	var hash_before := _hash(before)

	var save_ok: Variant = gs.call("save_game", SAVE_SLOT)
	if not (save_ok is bool) or not bool(save_ok):
		_skip(id, name, "GameState.save_game() devuelve false/no implementado", started)
		return
	if gs.has_method("has_save"):
		var exists: Variant = gs.call("has_save", SAVE_SLOT)
		if exists is bool and not bool(exists):
			_fail(id, name, "save_game()=true pero has_save(%s)=false" % SAVE_SLOT, started)
			_cleanup_save()
			return
	var load_ok: Variant = gs.call("load_game", SAVE_SLOT)
	if not (load_ok is bool) or not bool(load_ok):
		_fail(id, name, "GameState.load_game() devuelve false/no implementado", started)
		_cleanup_save()
		return

	var after: Variant = gs.call("to_dict")
	var hash_after := _hash(after)
	var hash_equal := hash_before == hash_after
	var rng_result := _check_rng_continuity(gs)
	_cleanup_save()
	if not hash_equal:
		_fail(id, name, "hash to_dict distinto tras load (%s → %s)" % [hash_before.substr(0, 16), hash_after.substr(0, 16)], started)
		return
	if not bool(rng_result["ok"]):
		_fail(id, name, "hash OK pero RNG no continuo: %s" % str(rng_result["detail"]), started)
		return
	_pass(id, name, "hash %s idéntico; %s" % [hash_before.substr(0, 16), str(rng_result["detail"])], started)


func _check_rng_continuity(gs: Node) -> Dictionary:
	# Vía preferente: acceso directo al SeededRNG de GameState (contrato §1).
	var rng: Variant = gs.get("rng")
	if rng != null and rng is Object and (rng as Object).has_method("next_int"):
		var x: Variant = (rng as Object).call("next_int", 1, 100000)
		gs.call("load_game", SAVE_SLOT)
		var y: Variant = (rng as Object).call("next_int", 1, 100000)
		return {"ok": int(x) == int(y), "detail": "RNG directo: next_int post-load reproducible (%d)" % int(x)}
	# Fallback: snapshot "rng" incluido en to_dict + SeededRNG reconstruido.
	var snapshot_dict: Variant = gs.call("to_dict")
	if snapshot_dict is Dictionary and (snapshot_dict as Dictionary).has("rng"):
		var snap: Variant = (snapshot_dict as Dictionary)["rng"]
		var rng_script: Variant = load("res://scripts/utils/rng.gd")
		if snap is Dictionary and rng_script is GDScript:
			var a: Variant = (rng_script as GDScript).new()
			var b: Variant = (rng_script as GDScript).new()
			if a != null and b != null and (a as Object).has_method("restore") and (b as Object).has_method("restore"):
				(a as Object).call("restore", snap)
				(b as Object).call("restore", snap)
				var a1: Variant = (a as Object).call("next_int", 1, 100000)
				var b1: Variant = (b as Object).call("next_int", 1, 100000)
				return {"ok": int(a1) == int(b1), "detail": "RNG vía snapshot to_dict restaurado (next=%d)" % int(a1)}
	return {"ok": false, "detail": "GameState no expone 'rng' ni snapshot restaurable"}


func _cleanup_save() -> void:
	var dir := DirAccess.open("user://saves")
	if dir != null:
		dir.remove(SAVE_SLOT + ".json")


# ---------------------------------------------------------------------------
# C4 — Peste Negra 1348 en event_log con population_modifier -0.35
# ---------------------------------------------------------------------------

func _criterion_4_black_death() -> void:
	var started := Time.get_ticks_msec()
	var id := "C4"
	var name := "Peste Negra 1348 en event_log con population_modifier -0.35 (europe_west)"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	if tm == null or not tm.has_method("advance_quarter"):
		_skip(id, name, "TurnManager.advance_quarter() no declarado", started)
		return

	var state := _state()
	if not state.has("year"):
		_skip(id, name, "GameState.state sin clave 'year' (stub)", started)
		return

	var year := int(state.get("year", 1337))
	var pop_before_plague := 0
	var pop_after_plague := 0
	var advanced_any := false
	var path := "advance_quarter"
	var guard := 0
	while year < 1348 and guard < 60:
		var year_before := year
		tm.call("advance_quarter")
		guard += 1
		state = _state()
		year = int(state.get("year", year_before))
		if year > year_before:
			advanced_any = true
		if year == 1347:
			pop_before_plague = _total_population(state)
		if year == year_before and guard >= 8:
			break
	if year < 1348 and tm.has_method("advance_year"):
		path = "advance_year"
		for _i in range(20):
			if year >= 1348:
				break
			var year_before := year
			tm.call("advance_year")
			state = _state()
			year = int(state.get("year", year_before))
			if year > year_before:
				advanced_any = true
			if year == 1347:
				pop_before_plague = _total_population(state)
			if year == year_before:
				break
	if not advanced_any:
		_skip(id, name, "TurnManager no avanza el año (stub)", started)
		return
	if year < 1348:
		_fail(id, name, "no se alcanzó 1348 (año=%d, 60 iteraciones)" % year, started)
		return
	if pop_before_plague == 0:
		pop_before_plague = _total_population(state)
	pop_after_plague = _total_population(state)

	var event_found := false
	var event_entry: Variant = null
	var event_log: Variant = state.get("event_log", [])
	if event_log is Array:
		for entry in (event_log as Array):
			if _event_matches(entry, "peste_negra_1348"):
				event_found = true
				event_entry = entry
				break
	var fired: Variant = state.get("fired_events", [])
	var in_fired := fired is Array and (fired as Array).has("peste_negra_1348")
	var data_ok := _black_death_data_ok()
	var effect_applied := false
	var effect_detail := ""
	if pop_before_plague > 0 and pop_after_plague > 0:
		effect_applied = pop_after_plague < pop_before_plague
		effect_detail = "población %d → %d (%+.1f%%)" % [
			pop_before_plague, pop_after_plague,
			(float(pop_after_plague - pop_before_plague) / float(pop_before_plague)) * 100.0,
		]
	elif event_entry != null:
		var serialized := JSON.stringify(event_entry)
		effect_applied = serialized.contains("population_modifier") or serialized.contains("-0.35")
		effect_detail = "efecto declarado en la entrada de event_log"
	var detail := "año=%d vía %s; event_log=%s; fired_events=%s; datos(1348 -0.35 europe_west)=%s; %s" % [
		year, path, str(event_found), str(in_fired), str(data_ok), effect_detail,
	]
	if not data_ok:
		_fail(id, name, "el dataset events_1337.json no define la Peste Negra 1348 correctamente: " + detail, started)
		return
	if not event_found:
		_fail(id, name, "peste_negra_1348 ausente de event_log: " + detail, started)
		return
	if not in_fired:
		_fail(id, name, "peste_negra_1348 ausente de fired_events: " + detail, started)
		return
	if not effect_applied:
		_fail(id, name, "evento registrado pero sin evidencia de -0.35 aplicado: " + detail, started)
		return
	_pass(id, name, detail, started)


func _total_population(state: Dictionary) -> int:
	var regions: Variant = state.get("regions", {})
	if not (regions is Dictionary):
		return 0
	var total := 0
	for region_id in (regions as Dictionary).keys():
		var region_data: Variant = (regions as Dictionary)[region_id]
		if region_data is Dictionary and (region_data as Dictionary).has("population"):
			total += int((region_data as Dictionary).get("population", 0))
	return total


func _event_matches(entry: Variant, event_id: String) -> bool:
	if entry is Dictionary:
		var d := entry as Dictionary
		for key in ["event_id", "id", "event"]:
			if d.has(key) and str(d.get(key, "")) == event_id:
				return true
		return JSON.stringify(d).contains(event_id)
	if entry is String:
		return str(entry).contains(event_id)
	return false


func _black_death_data_ok() -> bool:
	var events_root: Variant = _read_json("res://data/events_1337.json")
	if not (events_root is Dictionary) or not ((events_root as Dictionary).get("events") is Array):
		return false
	for event_data in ((events_root as Dictionary).get("events") as Array):
		if not (event_data is Dictionary) or int((event_data as Dictionary).get("year", 0)) != 1348:
			continue
		for effect in ((event_data as Dictionary).get("effects", []) as Array):
			if not (effect is Dictionary):
				continue
			var e := effect as Dictionary
			if str(e.get("type", "")) != "population_modifier":
				continue
			if abs(float(e.get("value", 0.0)) - (-0.35)) < 0.0001 and str(e.get("scope", "")) == "europe_west":
				return true
	return false


# ---------------------------------------------------------------------------
# C5 — Batalla delegada: informe coherente + captura de región
# ---------------------------------------------------------------------------

func _criterion_5_delegated_battle() -> void:
	var started := Time.get_ticks_msec()
	var id := "C5"
	var name := "Batalla delegada: informe coherente y captura de región"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	var mil := _autoload("MilitarySystem")
	if tm == null or mil == null:
		_skip(id, name, "TurnManager/MilitarySystem no montados", started)
		return
	if not mil.has_method("move_army"):
		_skip(id, name, "MilitarySystem.move_army() no declarado", started)
		return

	var state := _state()
	var armies: Variant = state.get("armies", {})
	if not (armies is Dictionary) or (armies as Dictionary).is_empty():
		_skip(id, name, "GameState.state.armies vacío (MilitarySystem aún stub)", started)
		return
	var player_army := _find_player_army(armies as Dictionary)
	if player_army.is_empty():
		_skip(id, name, "sin ejército del jugador en state.armies", started)
		return
	var army_id := str(player_army.get("id", ""))
	var from_region := str(player_army.get("region_id", ""))
	var target := _find_enemy_target(from_region, state)
	if target == "":
		_skip(id, name, "sin región enemiga adyacente en el estado inicial", started)
		return
	var reports_before := _reports_hash(state)

	if tm.has_method("begin_turn"):
		tm.call("begin_turn", PLAYER_FACTION)
	var moved: Variant = mil.call("move_army", army_id, target)
	state = _state()
	if _reports_hash(state) == reports_before and tm.has_method("end_turn"):
		tm.call("end_turn")
		state = _state()
	if _reports_hash(state) == reports_before:
		if not (moved is bool) or not bool(moved):
			_skip(id, name, "move_army() rechazado y sin informe de batalla (stub de sistemas)", started)
			return
		_fail(id, name, "movimiento aceptado pero sin BattleReport resuelto (región %s)" % target, started)
		return

	var report: Variant = _last_report(state)
	if not (report is Dictionary):
		_fail(id, name, "ultimo battle_report no es Dictionary", started)
		return
	var rd := report as Dictionary
	var coherence := _report_coherence(rd)
	var captured := _report_captured(rd, state, target)
	var detail := "army=%s %s→%s; report.keys=%s; coerente=%s; capturada=%s" % [
		army_id, from_region, target, str(rd.keys()), str(coherence["ok"]), str(captured),
	]
	if not bool(coherence["ok"]):
		_fail(id, name, "informe incoherente: %s (%s)" % [str(coherence["reason"]), detail], started)
		return
	if not captured:
		_fail(id, name, "informe sin captura de región: " + detail, started)
		return
	_pass(id, name, detail, started)


func _find_player_army(armies: Dictionary) -> Dictionary:
	for army_id in armies.keys():
		var army_data: Variant = armies[army_id]
		if army_data is Dictionary and str((army_data as Dictionary).get("faction_id", "")) == PLAYER_FACTION:
			var found := (army_data as Dictionary).duplicate()
			found["id"] = str((army_data as Dictionary).get("id", army_id))
			return found
	return {}


func _find_enemy_target(from_region: String, state: Dictionary) -> String:
	var regions_root: Variant = _read_json("res://data/regions.json")
	if not (regions_root is Dictionary):
		return ""
	var regions_data: Variant = (regions_root as Dictionary).get("regions", [])
	var adjacency: Array = []
	for region_data in (regions_data as Array):
		if region_data is Dictionary and str((region_data as Dictionary).get("id", "")) == from_region:
			adjacency = (region_data as Dictionary).get("adjacency", [])
			break
	var state_regions: Variant = state.get("regions", {})
	if not (state_regions is Dictionary):
		return ""
	for neighbor in adjacency:
		var neighbor_id := str(neighbor)
		if not (state_regions as Dictionary).has(neighbor_id):
			continue
		var neighbor_data: Variant = (state_regions as Dictionary)[neighbor_id]
		if neighbor_data is Dictionary and str((neighbor_data as Dictionary).get("owner", "")) != PLAYER_FACTION:
			return neighbor_id
	return ""


func _reports_count(state: Dictionary) -> int:
	var reports: Variant = state.get("battle_reports", [])
	return (reports as Array).size() if reports is Array else 0


func _reports_hash(state: Dictionary) -> String:
	var reports: Variant = state.get("battle_reports", [])
	return _hash(reports)


func _last_report(state: Dictionary) -> Variant:
	var reports: Variant = state.get("battle_reports", [])
	if reports is Array and not (reports as Array).is_empty():
		return (reports as Array)[(reports as Array).size() - 1]
	return null


func _report_coherence(report: Dictionary) -> Dictionary:
	if report.is_empty():
		return {"ok": false, "reason": "informe vacío"}
	if report.size() < 4:
		return {"ok": false, "reason": "menos de 4 campos"}
	var has_side := false
	var has_casualty := false
	var has_rounds := false
	for key in report.keys():
		var k := str(key).to_lower()
		if k.contains("attacker") or k.contains("defender") or k.contains("winner") or k.contains("faction"):
			has_side = true
		if k.contains("casualt") or k.contains("loss") or k.contains("dead") or k.contains("bajas"):
			has_casualty = true
		if k.contains("assault") or k.contains("round") or k.contains("asalt"):
			has_rounds = true
	if not has_side:
		return {"ok": false, "reason": "sin bandos (attacker/defender/winner)"}
	if not has_casualty:
		return {"ok": false, "reason": "sin bajas"}
	if not has_rounds:
		# No es bloqueante si el informe declara captura y bajas; se anota.
		return {"ok": true, "reason": "sin rondas declaradas (aceptable si hay bajas+captura)"}
	return {"ok": true, "reason": ""}


func _report_captured(report: Dictionary, state: Dictionary, target: String) -> bool:
	var serialized := JSON.stringify(report)
	var declared := serialized.contains("\"captured\":true") or serialized.contains("\"region_captured\":true") \
		or serialized.contains("\"captured\": true") or serialized.contains("\"region_captured\": true")
	var state_regions: Variant = state.get("regions", {})
	var owner := ""
	if state_regions is Dictionary and (state_regions as Dictionary).has(target):
		var region_data: Variant = (state_regions as Dictionary)[target]
		if region_data is Dictionary:
			owner = str((region_data as Dictionary).get("owner", ""))
	return declared or owner == PLAYER_FACTION


# ---------------------------------------------------------------------------
# C6 — Smoke UI: instanciar/free todas las escenas de scenes/**
# ---------------------------------------------------------------------------

func _criterion_6_ui_smoke() -> void:
	var started := Time.get_ticks_msec()
	var id := "C6"
	var name := "Smoke UI: instanciar/free todas las escenas de scenes/** en headless"
	var scenes: Array[String] = []
	_scan_scenes("res://scenes", scenes)
	if scenes.is_empty():
		_skip(id, name, "scenes/** no contiene .tscn todavía (AG-3 en curso)", started)
		return
	var failures: Array[String] = []
	var ok := 0
	for scene_path in scenes:
		var packed: Variant = load(scene_path)
		if not (packed is PackedScene):
			failures.append("%s (load falló)" % scene_path)
			continue
		var instance: Node = (packed as PackedScene).instantiate()
		if instance == null:
			failures.append("%s (instantiate null)" % scene_path)
			continue
		instance.free()
		ok += 1
	if failures.is_empty():
		_pass(id, name, "%d/%d escenas instanciadas y liberadas" % [ok, scenes.size()], started)
		return
	var shown: Array[String] = []
	for i in range(min(failures.size(), MAX_SCENES_REPORTED)):
		shown.append(failures[i])
	_fail(id, name, "%d/%d escenas OK; fallos: %s%s" % [
		ok, scenes.size(), "; ".join(shown),
		"" if failures.size() <= MAX_SCENES_REPORTED else " (+%d)" % (failures.size() - MAX_SCENES_REPORTED),
	], started)


func _scan_scenes(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path := path.path_join(entry)
			if dir.current_is_dir():
				_scan_scenes(full_path, out)
			elif entry.ends_with(".tscn") or entry.ends_with(".scn"):
				out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


# ---------------------------------------------------------------------------
# Resumen y exit code
# ---------------------------------------------------------------------------

func _finish() -> void:
	var passed := 0
	var failed := 0
	var skipped := 0
	var failed_names: Array[String] = []
	for result in results:
		match str(result["status"]):
			"PASS":
				passed += 1
			"FAIL":
				failed += 1
				failed_names.append(str(result["id"]))
			"SKIP":
				skipped += 1
	print("--------------------------------------------------------------")
	print("RESULTADO QA ACEPTACIÓN FASE 1: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [
		passed, failed, skipped, results.size(),
	])
	for result in results:
		print("  %s: [%s] %s (%d ms)" % [
			str(result["id"]), str(result["status"]), str(result["name"]), int(result["ms"]),
		])
	print("--------------------------------------------------------------")
	if failed > 0:
		print("ACEPTACIÓN: NO ACEPTADA — FAIL en %s (exit 1)" % ", ".join(failed_names))
		quit(1)
		return
	if skipped > 0:
		print("ACEPTACIÓN: PENDIENTE — %d criterio(s) SKIP por sistemas aún stub (baseline; exit 1)" % skipped)
		quit(1)
		return
	print("ACEPTACIÓN: OK — 6/6 criterios PASS (exit 0)")
	quit(0)
