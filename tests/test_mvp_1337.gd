extends RefCounted
## Tests del tramo MVP-1337 (D-066): audio mínimo, loop completo de las 8
## facciones jugables, condiciones §4.5, save/load en 3 puntos, rendimiento,
## balance de 10 años y reclutamiento era I.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const MvpBench = preload("res://tools/mvp_bench.gd")

const SCENARIO_ID: String = "scenario_1337"
const PLAYER: String = "england"
const AI_BUDGET_MS: int = 2000
const MAP_FRAME_BUDGET_MS: float = 8.0
const YEARS_BALANCE: int = 10


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_audio(runner, h)
	_check_playable_loop(runner, h)
	_check_events_1337(runner, h)
	_check_audit_fixes(runner, h)
	_check_victory_and_defeat(runner, h)
	_check_save_load_three_points(runner, h)
	_check_performance(runner, h)
	_check_recruitment_era_one(runner, h)
	_check_balance_ten_years(runner, h)


# ---------------------------------------------------------------------------
# Audio (D-015/D-066)
# ---------------------------------------------------------------------------

func _check_audio(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_audio")
	runner.check("autoload AudioManager registrado", h.audio != null)
	if h.audio == null:
		return
	runner.check("AudioManager tiene click/bell/sword generados",
		bool(h.audio.call("has_tone", "click"))
			and bool(h.audio.call("has_tone", "bell"))
			and bool(h.audio.call("has_tone", "sword")))
	runner.check_eq("click dura 45 ms", 45.0, h.audio.call("get_tone_duration_ms", "click"))
	runner.check_eq("campana dura 900 ms", 900.0, h.audio.call("get_tone_duration_ms", "bell"))
	runner.check_eq("espada dura 180 ms", 180.0, h.audio.call("get_tone_duration_ms", "sword"))
	h.reset_audio_counts()
	runner.check("play_ui_click reproduce", bool(h.audio.call("play_ui_click")))
	runner.check("play_year_bell reproduce", bool(h.audio.call("play_year_bell")))
	runner.check("play_sword reproduce", bool(h.audio.call("play_sword")))
	runner.check_eq("contador click", 1, h.audio_count("click"))
	runner.check_eq("contador bell", 1, h.audio_count("bell"))
	runner.check_eq("contador sword", 1, h.audio_count("sword"))
	h.audio.call("set_muted", true)
	runner.check("mute bloquea reproducción", not bool(h.audio.call("play_ui_click")))
	runner.check_eq("mute no incrementa contadores", 1, h.audio_count("click"))
	h.audio.call("set_muted", false)
	h.audio.call("set_volume_db", -12.0)
	runner.check_eq("volumen maestro -12 dB", -12.0, float(h.audio.call("get_volume_db")))
	h.audio.call("stop_all")
	# Campana enganchada al fin de año del TurnManager.
	h.new_game(PLAYER)
	h.reset_audio_counts()
	h.advance_year()
	runner.check("fin de año reproduce campana", h.audio_count("bell") >= 1)
	# Espada enganchada a la resolución de una ronda N3.
	h.new_game(PLAYER)
	var duel: Node = h.launch_close_combat(
		_close_unit("crossbowmen", PLAYER, 300, 8, 70),
		_close_unit("men_at_arms", "france", 300, 12, 70))
	if duel == null:
		runner.check("duelo N3 para audio", false)
		return
	h.reset_audio_counts()
	var hand: Array = SafeDict.as_array(SafeDict.as_dict(
		SafeDict.as_dict(duel.call("get_state")).get("hands", null)).get("attacker", null))
	var card: String = str(hand[0]) if not hand.is_empty() else "formacion"
	duel.call("play_order", card)
	duel.call("enemy_respond")
	runner.check("ronda N3 reproduce espada", h.audio_count("sword") >= 1)
	duel.free()


# ---------------------------------------------------------------------------
# Loop completo: 8 facciones jugables x 4 trimestres
# ---------------------------------------------------------------------------

func _check_playable_loop(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_loop")
	var playable: Array[String] = h.playable_factions(SCENARIO_ID)
	runner.check_eq("8 facciones jugables en 1337", 8, playable.size())
	var expected: Array[String] = ["england", "france", "hre", "bohemia", "hungary", "castile", "aragon", "poland"]
	for faction_id in expected:
		runner.check("jugable declarada: %s" % faction_id, playable.has(faction_id))
	var year_loop_ms: int = Time.get_ticks_msec()
	for faction_id in playable:
		h.new_game(faction_id)
		runner.check("arranca partida de %s" % faction_id, h.player() == faction_id and h.year() == 1337)
		var quarters_ok: bool = true
		for _quarter in 4:
			if h.is_game_over():
				break
			var before_turn: int = SafeDict.as_int(h.state().get("turn"), 0)
			h.end_turn()
			if not h.is_game_over() and SafeDict.as_int(h.state().get("turn"), 0) != before_turn + 1:
				quarters_ok = false
		runner.check("4 trimestres avanzan el turno de %s" % faction_id, quarters_ok)
		runner.check("el año avanza a 1337→1338 en %s" % faction_id,
			h.is_game_over() or h.year() == 1338)
		runner.check("sin batalla pendiente huérfana en %s" % faction_id, not h.has_pending_battle())
		_assert_state_integrity(runner, h, "loop %s" % faction_id)
	year_loop_ms = Time.get_ticks_msec() - year_loop_ms
	print("  [INFO] loop 8 facciones x 4 trimestres: %d ms" % year_loop_ms)


# ---------------------------------------------------------------------------
# Eventos 1337 (Peste Negra 1348 y guion)
# ---------------------------------------------------------------------------

func _check_events_1337(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_events")
	h.new_game(PLAYER)
	runner.check("evento inicial 1337 registrado",
		SafeDict.as_array(h.state().get("fired_events", null)).size() >= 1)
	h.set_year(1348)
	var before_events: int = SafeDict.as_array(h.state().get("fired_events", null)).size()
	_resolve_year(1348)
	var fired: Array = SafeDict.as_array(h.state().get("fired_events", null))
	runner.check("Peste Negra 1348 dispara", fired.has("peste_negra_1348"),
		str(fired))
	runner.check("el evento añade registro", fired.size() >= before_events + 1)
	_assert_state_integrity(runner, h, "evento peste")


# ---------------------------------------------------------------------------
# Correcciones de la auditoría AG-1 (D-067)
# ---------------------------------------------------------------------------

func _check_audit_fixes(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_audit_fixes")
	# 1) Guerra anglo-francesa declarada y eventos `war` disparan en año.
	h.new_game(PLAYER)
	runner.check("guerra anglo-francesa inicial declarada", h.at_war("england", "france"))
	h.set_year(1340)
	_resolve_year(1340)
	runner.check("evento de guerra Sluys 1340 dispara",
		SafeDict.as_array(h.state().get("fired_events", null)).has("batalla_sluys_1340"),
		str(h.state().get("fired_events", null)))
	# 2) Apoyo en montaña (HRE/Austria): no llega a 0 en 20 recálculos.
	h.new_game("hre")
	var mountain_region: String = ""
	for region_id in SafeDict.sorted_keys(h.regions()):
		var region: Dictionary = h.region(region_id)
		if SafeDict.as_string(region.get("owner"), "") == "hre" \
				and SafeDict.as_string(region.get("terrain"), "") == "mountain":
			mountain_region = region_id
			break
	runner.check("HRE tiene región de montaña", mountain_region != "")
	if mountain_region != "":
		var min_support: int = 100
		for _quarter in 20:
			h.eco.call("recalculate", "hre")
			min_support = mini(min_support, SafeDict.as_int(h.region(mountain_region).get("support"), 0))
		runner.check("apoyo en montaña >=20 tras 20 trimestres", min_support >= 20, str(min_support))
	# 3) Peste Negra con mortalidad dinástica acotada.
	h.new_game(PLAYER)
	var alive_before: int = _alive_characters(h)
	h.set_year(1348)
	_resolve_year(1348)
	var alive_after: int = _alive_characters(h)
	runner.check("Peste Negra dispara", SafeDict.as_array(h.state().get("fired_events", null)).has("peste_negra_1348"))
	runner.check("Peste Negra reduce personajes vivos (hook dinástico)", alive_after < alive_before,
		"%d → %d" % [alive_before, alive_after])
	runner.check("ningún gobernante muere por el hook de peste",
		_all_rulers_alive(h))
	_assert_state_integrity(runner, h, "peste dinástica")
	# 4) Polonia: el fallback de heredero no elige al cónyuge.
	h.new_game("poland")
	var heir_id: String = SafeDict.as_string(h.faction("poland").get("heir_id"), "")
	var heir_role: String = ""
	if heir_id != "":
		heir_role = SafeDict.as_string(h.character(heir_id).get("role"), "")
	runner.check("Polonia no nombra heredera a la cónyuge", heir_id == "" or heir_role != "spouse",
		"%s (%s)" % [heir_id, heir_role])


func _resolve_year(year: int) -> void:
	# Carga diferida: en --script los autoloads no son globals al compilar.
	var resolver_script: Variant = load("res://scripts/utils/event_resolver.gd")
	if resolver_script != null:
		resolver_script.new().call("resolve_year", year)


func _alive_characters(h: HarnessScript) -> int:
	var count: int = 0
	for character_id in SafeDict.sorted_keys(h.characters()):
		if SafeDict.as_bool(h.character(character_id).get("alive"), false):
			count += 1
	return count


func _all_rulers_alive(h: HarnessScript) -> bool:
	for faction_id in SafeDict.sorted_keys(h.factions()):
		var ruler_id: String = SafeDict.as_string(h.faction(faction_id).get("ruler_id"), "")
		if ruler_id == "":
			continue
		if not SafeDict.as_bool(h.character(ruler_id).get("alive"), false):
			return false
	return true


# ---------------------------------------------------------------------------
# §4.5 Victoria y derrota (4 condiciones)
# ---------------------------------------------------------------------------

func _check_victory_and_defeat(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_victory_defeat")
	var scenario: Dictionary = h.scenario_definition(SCENARIO_ID)
	var victory: Dictionary = SafeDict.as_dict(scenario.get("victory", null))
	var prestige_target: int = SafeDict.as_int(victory.get("prestige"), 500)
	var years_held: int = SafeDict.as_int(victory.get("years_held"), 10)
	# 1) Prestigio sostenido.
	h.new_game(PLAYER)
	var faction: Dictionary = h.faction(PLAYER)
	faction["prestige"] = prestige_target
	faction["prestige_since_year"] = h.year() - years_held
	var info: Dictionary = h.check_game_over()
	runner.check("victoria por prestigio §4.5.2", bool(info.get("over")) and bool(info.get("victory")),
		str(info))
	runner.check("motivo de prestigio correcto",
		SafeDict.as_string(info.get("reason"), "").contains("Prestigio"),
		SafeDict.as_string(info.get("reason"), ""))
	runner.check_eq("pantalla fin expone victoria", true, bool(info.get("victory")))
	# 2) Conquista ≥ control_pct de regiones.
	h.new_game(PLAYER)
	for region_id in SafeDict.sorted_keys(h.regions()):
		var region: Dictionary = h.region(region_id)
		region["owner"] = PLAYER
	info = h.check_game_over()
	runner.check("victoria por conquista §4.5.4", bool(info.get("over")) and bool(info.get("victory")), str(info))
	runner.check("motivo de conquista correcto",
		SafeDict.as_string(info.get("reason"), "").contains("Conquista"),
		SafeDict.as_string(info.get("reason"), ""))
	# 3) Supervivencia hasta end_year.
	h.new_game(PLAYER)
	var end_year: int = SafeDict.as_int(scenario.get("end_year"), 1399)
	h.set_year(end_year)
	info = h.check_game_over()
	runner.check("victoria por supervivencia §4.5.3", bool(info.get("over")) and bool(info.get("victory")), str(info))
	runner.check("motivo de supervivencia correcto",
		SafeDict.as_string(info.get("reason"), "").contains("Supervivencia"),
		SafeDict.as_string(info.get("reason"), ""))
	# 4) Derrota por pérdida de la última región.
	h.new_game(PLAYER)
	for region_id in SafeDict.sorted_keys(h.regions()):
		var region: Dictionary = h.region(region_id)
		region["owner"] = "france"
	info = h.check_game_over()
	runner.check("derrota por pérdida total §4.5", bool(info.get("over")) and not bool(info.get("victory")), str(info))
	runner.check("motivo de pérdida total",
		SafeDict.as_string(info.get("reason"), "").contains("perdido todas"),
		SafeDict.as_string(info.get("reason"), ""))
	# 5) Derrota por extinción de la casa (D-031).
	h.new_game(PLAYER)
	h.tm.call("on_dynasty_extinct", PLAYER)
	info = h.game_over_info()
	runner.check("derrota por extinción", bool(info.get("over")) and not bool(info.get("victory")), str(info))
	runner.check("motivo de extinción",
		SafeDict.as_string(info.get("reason"), "").contains("dinastía extinta"),
		SafeDict.as_string(info.get("reason"), ""))
	# El reloj queda congelado tras game over.
	var year_before: int = h.year()
	var quarter_before: int = h.quarter()
	h.end_turn()
	runner.check("game over congela el reloj",
		h.year() == year_before and h.quarter() == quarter_before)


# ---------------------------------------------------------------------------
# Save/load exacto en 3 puntos (D-066)
# ---------------------------------------------------------------------------

func _check_save_load_three_points(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_save_load")
	# Punto 1: turno intermedio (trimestre 2).
	h.new_game(PLAYER)
	h.end_turn()
	var hash_mid: int = h.state_hash()
	var hash_mid_json: String = JSON.stringify(h.gs.call("to_dict"))
	runner.check("guardar en turno intermedio", h.save_game("mvp_mid"))
	var gold_before: int = SafeDict.as_int(h.faction(PLAYER).get("gold"), 0)
	h.faction(PLAYER)["gold"] = gold_before + 12345
	runner.check("cargar en turno intermedio", h.load_game("mvp_mid"))
	runner.check_eq("hash exacto en turno intermedio", hash_mid, h.state_hash())
	runner.check_eq("JSON canónico exacto en turno intermedio", hash_mid_json, JSON.stringify(h.gs.call("to_dict")))
	runner.check_eq("trimestre preservado", 2, h.quarter())
	runner.check("sin batalla pendiente en turno intermedio", not h.has_pending_battle())
	# Punto 2: durante una batalla N2 pendiente.
	h.new_game(PLAYER)
	var enemy_faction: String = "france" if PLAYER != "france" else "england"
	var player_army_id: String = _first_army_of(h, PLAYER)
	var enemy_army_id: String = _first_army_of(h, enemy_faction)
	runner.check("hay ejércitos para batalla pendiente", player_army_id != "" and enemy_army_id != "")
	if player_army_id != "" and enemy_army_id != "":
		var attacker_model: Variant = h.get_army_model(player_army_id)
		var defender_model: Variant = h.get_army_model(enemy_army_id)
		var defender_region: String = SafeDict.as_string(h.army(enemy_army_id).get("region_id"), "")
		var region_model: Variant = h.get_region_model(defender_region)
		var battle: Node = h.launch_tactical(attacker_model, defender_model, region_model)
		runner.check("batalla N2 abierta", battle != null)
		if battle != null:
			runner.check("batalla pendiente registrada en el save", h.has_pending_battle())
			var pending: Dictionary = h.pending_battle()
			runner.check_eq("nivel de batalla pendiente 2", 2, SafeDict.as_int(pending.get("level"), 0))
			runner.check_eq("región de batalla pendiente", defender_region,
				SafeDict.as_string(pending.get("region_id"), ""))
			var hash_battle: int = h.state_hash()
			runner.check("guardar durante batalla pendiente", h.save_game("mvp_battle"))
			h.clear_pending_battle()
			runner.check("cargar durante batalla pendiente", h.load_game("mvp_battle"))
			runner.check_eq("hash exacto con batalla pendiente", hash_battle, h.state_hash())
			runner.check("contexto de batalla restaurado", h.has_pending_battle())
			runner.check_eq("región restaurada", defender_region,
				SafeDict.as_string(h.pending_battle().get("region_id"), ""))
			battle.free()
			h.clear_pending_battle()
	# Punto 3: fin de año.
	h.new_game(PLAYER)
	h.advance_year()
	var hash_year: int = h.state_hash()
	runner.check("guardar en fin de año", h.save_game("mvp_year"))
	runner.check("cargar en fin de año", h.load_game("mvp_year"))
	runner.check_eq("hash exacto en fin de año", hash_year, h.state_hash())
	runner.check_eq("año 1338 preservado", 1338, h.year())
	runner.check("sin batalla pendiente en fin de año", not h.has_pending_battle())
	runner.check("estado serializable tras cargar", JSON.stringify(h.state()).length() > 1000)


# ---------------------------------------------------------------------------
# Rendimiento (D-066 §2.2): IA <2 s, mapa <8 ms/frame
# ---------------------------------------------------------------------------

func _check_performance(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_performance")
	h.new_game(PLAYER)
	var ai_ms: int = MvpBench.measure_ai_ms(h.ai)
	runner.check("IA 13 rivales <2000 ms", ai_ms >= 0 and ai_ms < AI_BUDGET_MS, str(ai_ms))
	runner.check_eq("13 rivales jugaron", 13, SafeDict.as_int(h.ai.get("last_turn_count"), 0))
	var map_ms: float = MvpBench.measure_map_frame_ms(200)
	runner.check("mapa <8 ms CPU/frame", map_ms >= 0.0 and map_ms < MAP_FRAME_BUDGET_MS,
		"%.3f ms" % map_ms)
	print("  [INFO] rendimiento: IA=%d ms; mapa=%.3f ms/frame" % [ai_ms, map_ms])


# ---------------------------------------------------------------------------
# Reclutamiento era I (D-059)
# ---------------------------------------------------------------------------

func _check_recruitment_era_one(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_recruitment_era")
	h.new_game(PLAYER)
	runner.check_eq("era inicial I en 1337", "I", h.era())
	runner.check("militia_spearman disponible en era I", h.is_unit_available("militia_spearman", PLAYER))
	runner.check("arquebusier NO disponible en 1337", not h.is_unit_available("arquebusier", PLAYER))
	runner.check("swiss_pikeman NO disponible antes de 1386", not h.is_unit_available("swiss_pikeman", PLAYER))
	var available: Array[String] = h.available_units(PLAYER)
	var all_era_one: bool = not available.is_empty()
	for unit_id in available:
		if not h.is_unit_available(unit_id, PLAYER):
			all_era_one = false
	runner.check("available_units solo era I", all_era_one)
	var home_region: String = _first_owned_region(h, PLAYER)
	runner.check("hay región propia para reclutar", home_region != "")
	if home_region != "":
		runner.check("reclutar era III falla en 1337",
			not h.recruit(PLAYER, home_region, "arquebusier", 10))


# ---------------------------------------------------------------------------
# Balance: 10 años por cada facción jugable (D-066 §2.4)
# ---------------------------------------------------------------------------

func _check_balance_ten_years(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("mvp_balance_10y")
	var playable: Array[String] = h.playable_factions(SCENARIO_ID)
	var started_ms: int = Time.get_ticks_msec()
	for faction_id in playable:
		h.new_game(faction_id)
		var start_treasury: int = SafeDict.as_int(h.faction(faction_id).get("gold"), 0)
		var years_played: int = 0
		var over: bool = false
		var over_reason: String = ""
		var integrity_ok: bool = true
		var integrity_detail: String = ""
		for _year_index in YEARS_BALANCE:
			for _quarter in 4:
				if h.is_game_over():
					break
				h.end_turn()
			if h.is_game_over():
				over = true
				over_reason = h.game_over_reason()
				break
			years_played += 1
			var report: Dictionary = _state_integrity(h)
			if not bool(report.get("ok")):
				integrity_ok = false
				integrity_detail = str(report.get("errors"))
				break
			var year_now: int = 1337 + years_played
			if h.year() != year_now:
				integrity_ok = false
				integrity_detail = "año %d != %d" % [h.year(), year_now]
				break
		var faction: Dictionary = h.faction(faction_id)
		var treasury: int = SafeDict.as_int(faction.get("gold"), 0)
		var ratio: float = float(treasury) / maxf(1.0, float(start_treasury))
		var owned: int = _owned_regions(h, faction_id)
		var valid_money: bool = treasury > -1000000 and treasury < 10000000 and ratio <= 3.0
		runner.check("balance %s: 10 años sin crash" % faction_id, integrity_ok,
			integrity_detail if integrity_detail != "" else "ok")
		runner.check("balance %s: tesoro sin inflación trivial (x%.2f)" % [faction_id, ratio], valid_money)
		runner.check("balance %s: estado consistente" % faction_id, bool(_state_integrity(h).get("ok")))
		runner.check("balance %s: sobrevive los 10 años" % faction_id, not over,
			over_reason if over else "ok")
		if over:
			runner.check("balance %s: derrota con motivo" % faction_id, over_reason != "")
			print("  [INFO] balance %s: game_over en año %d (%s), oro=%d, regiones=%d" % [
				faction_id, h.year(), over_reason, treasury, owned])
		else:
			runner.check("balance %s: no derrota en 10 años" % faction_id, years_played == YEARS_BALANCE)
			runner.check("balance %s: conserva regiones" % faction_id, owned > 0)
			print("  [INFO] balance %s: 10 años OK, oro=%d, regiones=%d" % [faction_id, treasury, owned])
	var total_ms: int = Time.get_ticks_msec() - started_ms
	print("  [INFO] balance 10 años x %d facciones: %d ms" % [playable.size(), total_ms])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _close_unit(unit_id: String, faction_id: String, size: int, strength: int, morale: int) -> Dictionary:
	var type_name: String = "infantry"
	if unit_id in ["crossbowmen", "longbowman", "janissary", "arquebusier", "steppe_cavalry"]:
		type_name = "ranged"
	elif unit_id == "bombarda":
		type_name = "artillery"
	return {
		"id": "%s_%s" % [faction_id, unit_id],
		"unit_id": unit_id,
		"faction": faction_id,
		"type": type_name,
		"size": size,
		"strength": strength,
		"morale": float(morale) / 100.0,
		"experience": 0,
	}


func _first_army_of(h: HarnessScript, faction_id: String) -> String:
	for army_id in SafeDict.sorted_keys(h.armies()):
		var army: Dictionary = h.army(army_id)
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id:
			return army_id
	return ""


func _first_owned_region(h: HarnessScript, faction_id: String) -> String:
	for region_id in SafeDict.sorted_keys(h.regions()):
		if SafeDict.as_string(h.region(region_id).get("owner"), "") == faction_id:
			return region_id
	return ""


func _owned_regions(h: HarnessScript, faction_id: String) -> int:
	var count: int = 0
	for region_id in SafeDict.sorted_keys(h.regions()):
		if SafeDict.as_string(h.region(region_id).get("owner"), "") == faction_id:
			count += 1
	return count


func _assert_state_integrity(runner: TestRunnerScript, h: HarnessScript, label: String) -> void:
	var report: Dictionary = _state_integrity(h)
	runner.check("estado íntegro (%s)" % label, bool(report.get("ok")), str(report.get("errors")))


func _state_integrity(h: HarnessScript) -> Dictionary:
	var st: Dictionary = h.state()
	var errors: Array[String] = []
	if st.is_empty():
		return {"ok": false, "errors": ["estado vacío"]}
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var player: String = SafeDict.as_string(st.get("player_faction"), "")
	if not factions.has(player):
		errors.append("player_faction sin facción")
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		var owner: String = SafeDict.as_string(region.get("owner"), "")
		if owner != "" and not factions.has(owner):
			errors.append("región %s con owner huérfano %s" % [region_id, owner])
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		var faction_id: String = SafeDict.as_string(army.get("faction_id"), "")
		var region_id: String = SafeDict.as_string(army.get("region_id"), "")
		if not factions.has(faction_id):
			errors.append("ejército %s con facción huérfana %s" % [army_id, faction_id])
		if region_id != "" and not regions.has(region_id):
			errors.append("ejército %s en región inexistente %s" % [army_id, region_id])
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			var unit_id: String = SafeDict.as_string(unit.get("unit_id"), "")
			if unit_id != "" and h.unit_definition(unit_id).is_empty():
				errors.append("unidad huérfana %s en %s" % [unit_id, army_id])
	if not h.has_pending_battle() and SafeDict.as_dict(st.get("pending_battle", null)).is_empty():
		pass
	return {"ok": errors.is_empty(), "errors": errors}
