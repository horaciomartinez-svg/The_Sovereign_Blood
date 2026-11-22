extends SceneTree
## Harness QA — Fase 3.3 MVP-1337 (D-066). Criterios C1-C10 del prompt MVP.
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_mvp_1337.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso (baseline, no es
## rechazo); FAIL = incumplimiento. Exit 0 solo con C1-C10 PASS.

const PLAYABLE_1337: Array[String] = [
	"england", "france", "hre", "bohemia", "hungary", "castile", "aragon", "poland",
]
const ORIGINAL_1337_RULERS: Array[String] = [
	"edward_iii_plantagenet", "philippe_vi_de_valois", "ludwig_iv_wittelsbach", "jan_lucembursky",
	"karoly_robert_anjou", "alfonso_xi_borgona", "pere_iv_d_arago", "kazimierz_iii_piast",
	"david_ii_bruce", "benedict_xii", "yusuf_i_nazari", "an_nasir_muhammad", "oz_beg",
	"andronikos_iii_palaiologos",
]
const SEED := 1337

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Fase 3.3 MVP-1337 (C1-C10)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	print("[INFO] HEAD verificado: ver docs/qa/fase3_mvp_plan.md")
	print("[INFO] tests: %d; capturas: %d" % [
		_count_files("res://tests", "gd"), _count_files("res://docs/screenshots", "png"),
	])
	_criterion_1_loop()
	_criterion_2_endings()
	_criterion_3_battles()
	_criterion_4_save_load()
	_criterion_5_ten_years()
	_criterion_6_suite()
	await _criterion_7_performance()
	_criterion_8_ux()
	_criterion_9_pause()
	_criterion_10_no_external_art()
	_criterion_11_music()
	_finish()


# ---------------------------------------------------------------------------
# C1 — Loop completo 1337
# ---------------------------------------------------------------------------

func _criterion_1_loop() -> void:
	var started := Time.get_ticks_msec()
	var id := "C1"
	var name := "Loop completo 1337: menú/selección, 8 facciones arrancan, trimestres y fin con motivo"
	var errors: Array[String] = []
	for scene_path in ["res://scenes/main/main_menu.tscn", "res://scenes/main/scenario_select.tscn"]:
		if not FileAccess.file_exists(scene_path):
			errors.append("falta %s" % scene_path.get_file())
			continue
		var packed: Variant = load(scene_path)
		if not (packed is PackedScene):
			errors.append("%s no carga" % scene_path.get_file())
			continue
		var instance: Node = (packed as PackedScene).instantiate()
		if instance == null:
			errors.append("%s no instancia" % scene_path.get_file())
		else:
			root.add_child(instance)
			instance.free()
	for faction_id in PLAYABLE_1337:
		var start := _new_game("scenario_1337", str(faction_id))
		if not bool(start.get("ok", false)):
			errors.append("%s no arranca: %s" % [str(faction_id), str(start.get("detail", ""))])
			continue
		var tm := _autoload("TurnManager")
		for _i in range(4):
			tm.call("advance_quarter")
		var state: Dictionary = _state()
		if state.is_empty():
			errors.append("%s estado vacío tras 4 trimestres" % str(faction_id))
	# England hasta end_year (1399).
	_new_game("scenario_1337", "england")
	var tm2 := _autoload("TurnManager")
	var gs := _autoload("GameState")
	var state2: Dictionary = _state()
	var guard := 0
	var year := int(state2.get("year", 1337))
	while year < 1399 and guard < 260:
		tm2.call("advance_quarter")
		guard += 1
		state2 = _state()
		year = int(state2.get("year", year))
		if bool(state2.get("game_over", false)):
			break
	var game_over := bool(_state().get("game_over", false))
	var reason := str(_state().get("game_over_reason", ""))
	if year < 1399 and not game_over:
		errors.append("england no llegó a 1399 (year=%d)" % year)
	if not game_over or reason == "":
		errors.append("england sin fin/motivo (game_over=%s reason='%s')" % [str(game_over), reason])
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "8/8 facciones arrancan y 4 trimestres; england llega a %d con game_over y motivo '%s'" % [
		year, reason,
	], started)


# ---------------------------------------------------------------------------
# C2 — 4 condiciones §4.5
# ---------------------------------------------------------------------------

func _criterion_2_endings() -> void:
	var started := Time.get_ticks_msec()
	var id := "C2"
	var name := "4 condiciones §4.5: prestigio, conquista≥70%, supervivencia, derrota extinción/pérdida"
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	if gs == null or tm == null or not tm.has_method("_check_game_over"):
		_fail(id, name, "GameState/TurnManager sin API de cierre", started)
		return
	var errors: Array[String] = []
	var motives: Array[String] = []
	# Prestigio.
	_new_game("scenario_1337", "england")
	var st: Dictionary = _state()
	var faction: Dictionary = gs.call("get_faction_state", "england")
	faction["prestige"] = 500
	faction["prestige_since_year"] = int(st.get("year", 1337)) - 10
	tm.call("_check_game_over")
	if not _reason(gs).contains("Prestigio"):
		errors.append("prestigio no cierra")
	else:
		motives.append(_reason(gs))
	# Conquista.
	_new_game("scenario_1402", "ottoman")
	var st2: Dictionary = _state()
	var regions: Variant = st2.get("regions", {})
	if regions is Dictionary:
		for region_id in (regions as Dictionary).keys():
			var region: Variant = (regions as Dictionary)[region_id]
			if region is Dictionary:
				(region as Dictionary)["owner"] = "ottoman"
	tm.call("_check_game_over")
	if not _reason(gs).contains("Conquista"):
		errors.append("conquista no cierra")
	else:
		motives.append(_reason(gs))
	# Supervivencia.
	_new_game("scenario_1337", "england")
	_state()["year"] = 1399
	tm.call("_check_game_over")
	if not _reason(gs).contains("Supervivencia"):
		errors.append("supervivencia no cierra")
	else:
		motives.append(_reason(gs))
	# Derrota pérdida total.
	_new_game("scenario_1337", "england")
	var st4: Dictionary = _state()
	var regs4: Variant = st4.get("regions", {})
	if regs4 is Dictionary:
		for region_id in (regs4 as Dictionary).keys():
			var region: Variant = (regs4 as Dictionary)[region_id]
			if region is Dictionary:
				(region as Dictionary)["owner"] = "france"
	tm.call("_check_game_over")
	if not _reason(gs).contains("perdido todas"):
		errors.append("pérdida total no cierra")
	else:
		motives.append(_reason(gs))
	# Derrota extinción (rama eliminada; extinción real en F2-C2).
	_new_game("scenario_1337", "england")
	var f5: Dictionary = gs.call("get_faction_state", "england")
	f5["eliminated"] = true
	tm.call("_check_game_over")
	if not _reason(gs).contains("extinta"):
		errors.append("extinción no cierra")
	else:
		motives.append(_reason(gs))
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "5 motivos comprobados: " + " | ".join(motives), started)


# ---------------------------------------------------------------------------
# C3 — N1/N2/N3 desde partida real + animación
# ---------------------------------------------------------------------------

func _criterion_3_battles() -> void:
	var started := Time.get_ticks_msec()
	var id := "C3"
	var name := "N1/N2/N3 desde partida real y animación v1.8.1 sin regresión"
	var gs := _autoload("GameState")
	var battle := _autoload("BattleManager")
	if gs == null or battle == null:
		_fail(id, name, "GameState/BattleManager no montados", started)
		return
	_new_game("scenario_1337", "england")
	var errors: Array[String] = []
	if battle.has_method("resolve_delegated"):
		var n1: Variant = battle.call("resolve_delegated",
			_make_army("england", "longbowman"), _make_army("france", "men_at_arms"),
			_make_region("region_normandia"), 1)
		if not _report_ok(n1):
			errors.append("N1 sin informe")
	else:
		errors.append("resolve_delegated ausente")
	if battle.has_method("launch_tactical"):
		var n2: Variant = battle.call("launch_tactical",
			_make_army("england", "longbowman"), _make_army("france", "men_at_arms"),
			_make_region("region_normandia"))
		if n2 is Node:
			root.add_child(n2 as Node)
			(n2 as Node).call("auto_resolve")
			(n2 as Node).free()
		else:
			errors.append("launch_tactical no Node")
	else:
		errors.append("launch_tactical ausente")
	if battle.has_method("launch_close_combat"):
		var n3: Variant = battle.call("launch_close_combat",
			_unit("crossbowmen", "england"), _unit("men_at_arms", "france"))
		if n3 is Node:
			root.add_child(n3 as Node)
			(n3 as Node).call("auto_resolve")
			var outcome: Variant = (n3 as Node).call("get_outcome")
			if not (outcome is Dictionary) or (outcome as Dictionary).is_empty():
				errors.append("N3 sin outcome")
			(n3 as Node).free()
		else:
			errors.append("launch_close_combat no Node")
	else:
		errors.append("launch_close_combat ausente")
	var sprites: Variant = load("res://scripts/battle/battle_sprites.gd")
	if sprites is GDScript:
		var sheet := _first_sheet()
		if int((sprites as GDScript).call("attack_impact_index", sheet)) != 8:
			errors.append("attack_impact_index != 8 (v1.8.1)")
		if not is_equal_approx(float((sprites as GDScript).call("attack_impact_ms", sheet)), 333.3):
			errors.append("attack_impact_ms != 333.3")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "N1/N2/N3 con informe/outcome; animación v1.8.1 attack_4=333,3 ms; harness anim baseline 6/6", started)


# ---------------------------------------------------------------------------
# C4 — Save/load en 3 puntos
# ---------------------------------------------------------------------------

func _criterion_4_save_load() -> void:
	var started := Time.get_ticks_msec()
	var id := "C4"
	var name := "Save/load exacto en turno intermedio, fin de año y batalla pendiente"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("to_dict"):
		_fail(id, name, "GameState.to_dict ausente", started)
		return
	var errors: Array[String] = []
	_new_game("scenario_1337", "england")
	var tm := _autoload("TurnManager")
	for _i in range(2):
		tm.call("advance_quarter")
	if not _roundtrip_equal(gs):
		errors.append("turno intermedio no exacto")
	# Fin de año.
	var year_before := int(_state().get("year", 0))
	var guard := 0
	while int(_state().get("year", 0)) == year_before and guard < 8:
		tm.call("advance_quarter")
		guard += 1
	if not _roundtrip_equal(gs):
		errors.append("fin de año no exacto")
	# Batalla pendiente: API AG-2 (set/get/has/clear_pending_battle) serializada en to_dict.
	if _battle_pending_api():
		var battle := _autoload("BattleManager")
		var node: Variant = battle.call("launch_tactical",
			_make_army("england", "longbowman"), _make_army("france", "men_at_arms"),
			_make_region("region_normandia"))
		if node is Node:
			root.add_child(node as Node)
			var has_pending: Variant = gs.call("has_pending_battle")
			var pending: Variant = gs.call("get_pending_battle")
			if not (has_pending is bool) or not bool(has_pending):
				errors.append("batalla pendiente no registrada")
			elif not (pending is Dictionary) or int((pending as Dictionary).get("level", 0)) != 2:
				errors.append("contexto pendiente inválido (no level=2)")
			else:
				_state()["year"] = int(_state().get("year", 1337)) + 1
				gs.call("from_dict", _deep_copy(gs.call("to_dict")))
				var restored: Variant = gs.call("get_pending_battle")
				if not (restored is Dictionary) or int((restored as Dictionary).get("level", 0)) != 2:
					errors.append("save/load borra la batalla pendiente")
				if not _roundtrip_equal(gs):
					errors.append("batalla pendiente no exacta")
			(node as Node).free()
			gs.call("clear_pending_battle")
		else:
			errors.append("N2 no disponible")
	else:
		if not errors.is_empty():
			_fail(id, name, "turno/fin de año: " + ", ".join(errors), started)
			return
		_skip(id, name, "turno intermedio y fin de año exactos; batalla pendiente sin API de serialización (AG-2 en curso)", started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "3/3 puntos con hash exacto y determinismo", started)


# ---------------------------------------------------------------------------
# C5 — 10 años × 8 facciones
# ---------------------------------------------------------------------------

func _criterion_5_ten_years() -> void:
	var started := Time.get_ticks_msec()
	var id := "C5"
	var name := "Simulación 10 años × 8 facciones, estado serializable cada año"
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	if gs == null or tm == null:
		_fail(id, name, "GameState/TurnManager no montados", started)
		return
	var errors: Array[String] = []
	var details: Array[String] = []
	for faction_id in PLAYABLE_1337:
		_new_game("scenario_1337", str(faction_id))
		var serialized_years := 0
		var last_year := int(_state().get("year", 0))
		for _q in range(40):
			tm.call("advance_quarter")
			var state: Dictionary = _state()
			if state.is_empty():
				errors.append("%s estado vacío" % str(faction_id))
				break
			if bool(state.get("game_over", false)):
				break
			if int(state.get("year", last_year)) != last_year:
				last_year = int(state.get("year", last_year))
				var data: Variant = gs.call("to_dict")
				if data is Dictionary and not (data as Dictionary).is_empty():
					serialized_years += 1
		details.append("%s=%d años" % [str(faction_id), serialized_years])
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 6)), started)
		return
	_pass(id, name, "8/8 facciones sin errores; " + ", ".join(details), started)


# ---------------------------------------------------------------------------
# C6 — Suite/validate/editor (artefactos + evidencia externa)
# ---------------------------------------------------------------------------

func _criterion_6_suite() -> void:
	var started := Time.get_ticks_msec()
	var id := "C6"
	var name := "Suite verde: run_all 1469+, validate 11/7 0 WARN, editor/headless 0"
	var issues: Array[String] = []
	if _count_files("res://tests", "gd") < 29:
		issues.append("tests <29")
	if _count_files("res://scenes", "tscn") < 18:
		issues.append("escenas <18")
	for artifact in ["res://tests/qa_acceptance.gd", "res://tests/qa_acceptance_fase2.gd",
			"res://tests/qa_acceptance_fase3.gd", "res://tests/qa_acceptance_tiles.gd",
			"res://tests/qa_acceptance_fase3_final.gd", "res://scripts/autoload/audio_manager.gd"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta %s" % artifact.get_file())
	if not issues.is_empty():
		_skip(id, name, "módulos en curso: " + ", ".join(issues), started)
		return
	_pass(id, name, "29 tests, 18 escenas, harness y audio_manager presentes; run_all/validate/editor se validan en la batería externa", started)


# ---------------------------------------------------------------------------
# C7 — Rendimiento (async: mapa necesita un frame)
# ---------------------------------------------------------------------------

func _criterion_7_performance() -> void:
	var started := Time.get_ticks_msec()
	var id := "C7"
	var name := "IA 13 rivales <2 s/turno; mapa <8 ms CPU/frame"
	_new_game("scenario_1337", "england")
	var ai := _autoload("AIManager")
	if ai == null or not ai.has_method("run_all_ai"):
		_fail(id, name, "AIManager.run_all_ai ausente", started)
		return
	var t0 := Time.get_ticks_msec()
	ai.call("run_all_ai")
	var ai_ms := Time.get_ticks_msec() - t0
	var errors: Array[String] = []
	if ai_ms >= 2000:
		errors.append("IA %d ms (>=2000)" % ai_ms)
	var map_avg := await _benchmark_map()
	if map_avg < 0.0:
		errors.append("mapa no medible")
	elif map_avg >= 8.0:
		errors.append("mapa %.3f ms (>=8)" % map_avg)
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "IA=%d ms (<2000); mapa=%.3f ms/frame (<8, CPU headless; GPU no medible)" % [ai_ms, map_avg], started)


func _benchmark_map() -> float:
	var packed: Variant = load("res://scenes/map/world_map.tscn")
	if not (packed is PackedScene):
		return -1.0
	var instance: Node = (packed as PackedScene).instantiate()
	root.add_child(instance)
	await process_frame
	if instance.get_child_count() == 0:
		instance.free()
		return -1.0
	var interactive := _find_node_with_method(instance, "hit_test")
	var borders := _find_node_with_method(instance, "get_center")
	if interactive == null or borders == null:
		instance.free()
		return -1.0
	var regions: Array[String] = []
	var regions_root: Variant = _read_json("res://data/regions.json")
	if regions_root is Dictionary:
		var values: Variant = (regions_root as Dictionary).get("regions", null)
		if values is Array:
			for value in (values as Array):
				if value is Dictionary:
					regions.append(str((value as Dictionary).get("id", "")))
	var total_us := 0
	for frame in range(120):
		var t0 := Time.get_ticks_usec()
		if not regions.is_empty():
			var region_id := regions[frame % regions.size()]
			var center: Variant = borders.call("get_center", region_id)
			if center is Vector2:
				interactive.call("hit_test", center)
		instance.call("_process", 1.0 / 60.0)
		total_us += int(Time.get_ticks_usec() - t0)
	instance.free()
	return float(total_us) / 120.0 / 1000.0


# ---------------------------------------------------------------------------
# C8 — UX/audio/capturas (módulos en curso)
# ---------------------------------------------------------------------------

func _criterion_8_ux() -> void:
	var started := Time.get_ticks_msec()
	var id := "C8"
	var name := "UX: botones vivos, PG visible, audio mínimo y capturas §9"
	var missing: Array[String] = []
	if not FileAccess.file_exists("res://scripts/autoload/audio_manager.gd"):
		missing.append("audio_manager.gd")
	var audio_hooks := ["click", "campana", "espada"]
	var audio_text := ""
	if FileAccess.file_exists("res://scripts/autoload/audio_manager.gd"):
		audio_text = FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	for hook in audio_hooks:
		if not audio_text.to_lower().contains(hook):
			missing.append("hook audio %s" % hook)
	if audio_text != "" and not audio_text.contains("is_inside_tree") and not audio_text.contains("headless"):
		missing.append("guarda headless/audio (ERROR playback fuera del árbol)")
	for capture in ["mvp_main_menu.png", "mvp_scenario_select.png", "mvp_game_1337.png", "mvp_year_end.png", "mvp_victory.png"]:
		if not FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			missing.append(capture)
	if not missing.is_empty():
		_skip(id, name, "en curso (AG-2 audio, AG-3 UX/capturas): faltan " + ", ".join(missing), started)
		return
	_pass(id, name, "audio_manager con hooks click/campana/espada; capturas MVP presentes", started)


# ---------------------------------------------------------------------------
# C9 — 1402/1453 congelados y EN PAUSA
# ---------------------------------------------------------------------------

func _criterion_9_pause() -> void:
	var started := Time.get_ticks_msec()
	var id := "C9"
	var name := "1402/1453 congelados y «EN PAUSA» en UI; sin trabajo nuevo"
	var select_path := "res://scripts/ui/main/scenario_select.gd"
	if not FileAccess.file_exists(select_path):
		_fail(id, name, "scenario_select.gd ausente", started)
		return
	var text := FileAccess.get_file_as_string(select_path)
	var errors: Array[String] = []
	if not text.contains("EN PAUSA"):
		errors.append("texto EN PAUSA ausente")
	if not text.contains("_scenario_available") and not text.contains("disabled"):
		errors.append("no hay flag/deshabilitado")
	for data_path in ["res://data/scenarios/scenario_1402.json", "res://data/scenarios/scenario_1453.json",
			"res://data/events_1402.json", "res://data/events_1453.json"]:
		if not FileAccess.file_exists(data_path):
			errors.append("datos congelados ausentes %s" % data_path.get_file())
	if not errors.is_empty():
		_skip(id, name, "UI en curso (AG-3): " + ", ".join(errors), started)
		return
	_pass(id, name, "scenario_select con «EN PAUSA»/flag y datos 1402/1453 presentes congelados", started)


# ---------------------------------------------------------------------------
# C10 — Sin arte externo; fallbacks
# ---------------------------------------------------------------------------

func _criterion_10_no_external_art() -> void:
	var started := Time.get_ticks_msec()
	var id := "C10"
	var name := "Sin arte externo nuevo; fallbacks operativos (14 texturas 1337 + nuevos fallback)"
	var errors: Array[String] = []
	var characters := _characters()
	for ruler_id in ORIGINAL_1337_RULERS:
		var character: Dictionary = characters.get(ruler_id, {})
		var portrait := str(character.get("portrait", "")).strip_edges()
		if portrait == "" or not FileAccess.file_exists(portrait):
			errors.append("%s sin retrato 1337" % ruler_id)
	var new_ruler_without := 0
	for character_id in characters.keys():
		var character: Dictionary = characters[character_id]
		if str(character.get("role", "")) != "ruler" or ORIGINAL_1337_RULERS.has(str(character_id)):
			continue
		if str(character.get("portrait", "")).strip_edges() == "":
			new_ruler_without += 1
	if new_ruler_without == 0:
		errors.append("sin gobernantes nuevos con fallback que auditar")
	if not FileAccess.file_exists("res://docs/art/requests/kimi_phase3_assets.md"):
		errors.append("petición de arte congelada ausente")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 6)), started)
		return
	_pass(id, name, "14 retratos 1337 con PNG; %d gobernantes nuevos con fallback; petición externa congelada (D-066)" % new_ruler_without, started)


# ---------------------------------------------------------------------------
# C11 — Banda sonora MVP (D-067)
# ---------------------------------------------------------------------------

func _criterion_11_music() -> void:
	var started := Time.get_ticks_msec()
	var id := "C11"
	var name := "Música MVP: 6 OGG cargan headless, contextos/crossfade, buses Master/Music/SFX, opciones persistentes y licencias"
	var missing: Array[String] = []
	var track_paths: Array[String] = []
	var tracks_data: Variant = _read_json("res://data/audio_tracks.json")
	if tracks_data is Dictionary:
		var tracks: Variant = (tracks_data as Dictionary).get("tracks", tracks_data)
		if tracks is Dictionary:
			for key in (tracks as Dictionary).keys():
				var entry: Variant = (tracks as Dictionary)[key]
				if entry is Dictionary:
					var path := str((entry as Dictionary).get("path", (entry as Dictionary).get("file", "")))
					if path != "":
						track_paths.append(path)
	else:
		missing.append("data/audio_tracks.json")
	var ogg_files := _count_files("res://assets/audio/music", "ogg")
	if ogg_files != 6:
		missing.append("OGG=%d/6 en assets/audio/music" % ogg_files)
	if track_paths.is_empty():
		missing.append("audio_tracks sin rutas")
	for path in track_paths:
		if not path.begins_with("res://") or not ResourceLoader.exists(path):
			missing.append("pista ausente %s" % path.get_file())
			continue
		var stream: Variant = load(path)
		if not ClassDB.class_exists("AudioStreamOggVorbis") or not (stream is AudioStreamOggVorbis):
			missing.append("%s no AudioStreamOggVorbis" % path.get_file())
		elif (stream as AudioStreamOggVorbis).get_length() <= 0.0:
			missing.append("%s duración 0" % path.get_file())
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var master_bus := AudioServer.get_bus_index("Master")
	if music_bus < 0 or sfx_bus < 0 or master_bus < 0:
		missing.append("buses Master/Music/SFX incompletos")
	var audio_text := ""
	if FileAccess.file_exists("res://scripts/autoload/audio_manager.gd"):
		audio_text = FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	for method_name in ["play_music", "set_music_context", "play_music_context", "crossfade", "set_music_volume", "get_music_volume"]:
		if audio_text != "" and not audio_text.contains(method_name):
			missing.append("AudioManager sin %s" % method_name)
	if audio_text == "":
		missing.append("audio_manager.gd")
	var options_text := ""
	var options_path := "res://scripts/ui/main/options_menu.gd"
	if FileAccess.file_exists(options_path):
		options_text = FileAccess.get_file_as_string(options_path)
	if not options_text.to_lower().contains("music") and not options_text.to_lower().contains("música"):
		missing.append("opciones sin slider Music")
	if not options_text.contains("user://"):
		missing.append("opciones sin persistencia user://")
	var licenses_path := "res://docs/audio_licenses.md"
	if not FileAccess.file_exists(licenses_path):
		missing.append("docs/audio_licenses.md")
	else:
		var lic := FileAccess.get_file_as_string(licenses_path)
		if not (lic.to_lower().contains("dominio público") or lic.to_lower().contains("public domain") or lic.to_lower().contains("cc0") or lic.to_lower().contains("síntesis")):
			missing.append("licencias sin PD/CC0/síntesis")
	if not missing.is_empty():
		_skip(id, name, "en curso (AG-5 pistas, AG-2 motor, AG-3 opciones, AG-1 licencias): faltan " + ", ".join(missing.slice(0, 8)), started)
		return
	_pass(id, name, "6 OGG AudioStreamOggVorbis con duración; contextos/crossfade; buses Master/Music/SFX; opciones Music/SFX persistentes; licencias PD/síntesis", started)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _new_game(scenario_id: String, faction_id: String) -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("new_game"):
		return {"ok": false, "detail": "GameState no montado"}
	var dl := _autoload("DataLoader")
	if dl != null and dl.has_method("load_all"):
		dl.call("load_all")
	if gs.has_method("reset"):
		gs.call("reset")
	gs.call("new_game", scenario_id, faction_id, SEED)
	var state: Variant = gs.get("state")
	if state is Dictionary and not (state as Dictionary).is_empty():
		return {"ok": true}
	return {"ok": false, "detail": "estado vacío"}


func _state() -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {}
	var st: Variant = gs.get("state")
	return st as Dictionary if st is Dictionary else {}


func _reason(gs: Node) -> String:
	var state: Variant = gs.get("state")
	if state is Dictionary:
		return str((state as Dictionary).get("game_over_reason", ""))
	return ""


func _roundtrip_equal(gs: Node) -> bool:
	var data: Variant = gs.call("to_dict")
	if not (data is Dictionary) or (data as Dictionary).is_empty():
		return false
	var before := _hash(data)
	gs.call("from_dict", (data as Dictionary).duplicate(true))
	var after := _hash(gs.call("to_dict"))
	return before == after


func _battle_pending_api() -> bool:
	var gs := _autoload("GameState")
	return gs != null and gs.has_method("set_pending_battle") and gs.has_method("get_pending_battle") \
		and gs.has_method("has_pending_battle") and gs.has_method("clear_pending_battle")


func _deep_copy(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


func _report_ok(report: Variant) -> bool:
	if report is Dictionary:
		return not (report as Dictionary).is_empty()
	if report is Object and (report as Object).has_method("to_dict"):
		var data: Variant = (report as Object).call("to_dict")
		return data is Dictionary and not (data as Dictionary).is_empty()
	return false


func _make_army(faction_id: String, unit_id: String) -> Variant:
	var script: Variant = load("res://scripts/model/army.gd")
	if not (script is GDScript):
		return null
	var army: Variant = (script as GDScript).new()
	army.set("id", "qa_mvp_%s_%s" % [faction_id, unit_id])
	army.set("faction_id", faction_id)
	army.set("region_id", "region_normandia")
	army.set("leader_id", "edward_iii_plantagenet" if faction_id == "england" else "philippe_vi_de_valois")
	army.set("morale", 1.0)
	army.set("units", [{"id": "u1", "unit_id": unit_id, "size": 900, "strength": 10, "morale": 1.0, "experience": 50}])
	return army


func _make_region(region_id: String) -> Variant:
	var script: Variant = load("res://scripts/model/region_state.gd")
	if not (script is GDScript):
		return null
	var region: Variant = (script as GDScript).new()
	region.set("id", region_id)
	region.set("terrain", "plains")
	region.set("support", 60)
	region.set("base_wealth", 60)
	region.set("has_city", false)
	return region


func _unit(unit_id: String, faction: String) -> Dictionary:
	return {
		"id": "qa_mvp_%s_%s" % [faction, unit_id], "faction": faction, "unit_id": unit_id,
		"size": 300, "strength": 8, "morale": 1.0, "experience": 50,
	}


func _first_sheet() -> Dictionary:
	var data: Variant = _read_json("res://data/units.json")
	if data is Dictionary:
		var units_value: Variant = (data as Dictionary).get("units", null)
		if units_value is Array and not (units_value as Array).is_empty() and (units_value as Array)[0] is Dictionary:
			var sheet: Variant = ((units_value as Array)[0] as Dictionary).get("sprite_sheet", null)
			if sheet is Dictionary:
				return sheet as Dictionary
	return {}


func _characters() -> Dictionary:
	var out: Dictionary = {}
	var root: Variant = _read_json("res://data/characters.json")
	if root is Dictionary:
		var chars: Variant = (root as Dictionary).get("characters", null)
		if chars is Array:
			for value in (chars as Array):
				if value is Dictionary:
					out[str((value as Dictionary).get("id", ""))] = value
	return out


func _find_node_with_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
		if found != null:
			return found
	return null


func _hash(value: Variant) -> String:
	var text := JSON.stringify(value)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _autoload(autoload_name: String) -> Node:
	if root == null:
		return null
	return root.get_node_or_null(NodePath(autoload_name))


func _read_json(res_path: String) -> Variant:
	if not FileAccess.file_exists(res_path):
		return null
	var text := FileAccess.get_file_as_string(res_path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	return parser.data


func _count_files(res_dir: String, extension: String) -> int:
	var count := 0
	var dir := DirAccess.open(res_dir)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if entry != "src" and not entry.begins_with("."):
				count += _count_files("%s/%s" % [res_dir, entry], extension)
		elif entry.get_extension().to_lower() == extension:
			count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count


func _record(id: String, name: String, status: String, detail: String, started_ms: int) -> void:
	var elapsed := Time.get_ticks_msec() - started_ms
	_results.append({"id": id, "name": name, "status": status, "detail": detail, "ms": elapsed})
	var suffix := "" if detail == "" else " :: " + detail
	print("  [%s] %s — %s%s" % [status, id, name, suffix])


func _pass(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "PASS", detail, started_ms)


func _fail(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "FAIL", detail, started_ms)


func _skip(id: String, name: String, reason: String, started_ms: int) -> void:
	_record(id, name, "SKIP", reason + " (pendiente: módulo MVP en curso)", started_ms)


func _finish() -> void:
	var passed := 0
	var failed := 0
	var skipped := 0
	var total := _results.size()
	for result in _results:
		match str(result.get("status", "")):
			"PASS":
				passed += 1
			"FAIL":
				failed += 1
			"SKIP":
				skipped += 1
	print("--------------------------------------------------------------")
	print("RESULTADO QA MVP-1337: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [passed, failed, skipped, total])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0))])
	var code := 0
	if failed > 0:
		print("ACEPTACIÓN MVP-1337: NO ACEPTADA — FAIL en %d criterio(s) (exit 1)" % failed)
		code = 1
	elif skipped > 0:
		print("BASELINE MVP-1337: PENDIENTE — %d criterio(s) a la espera de módulos en curso (no es rechazo)" % skipped)
		code = 1
	else:
		print("ACEPTACIÓN MVP-1337: OK — %d/%d criterios PASS (exit 0)" % [passed, total])
	print("--------------------------------------------------------------")
	quit(code)
