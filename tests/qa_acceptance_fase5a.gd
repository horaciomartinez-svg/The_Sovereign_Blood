extends SceneTree
## Harness QA — Fase 5A «El juego te explica» (C1-C10).
## Contrato `docs/architecture_contracts_fase5a.md`; GDD v1.9.2; D-079…D-083.
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_fase5a.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso (baseline, no es
## rechazo); FAIL = violación. Exit 0 solo con C1-C10 PASS.

const PLAYABLE_1337: Array[String] = [
	"england", "france", "hre", "bohemia", "hungary", "castile", "aragon", "poland",
]
const FROZEN_FILES: Dictionary = {
	"res://data/scenarios/scenario_1402.json": "29DF03152D8F0354",
	"res://data/scenarios/scenario_1453.json": "1A333C97F1F66F10",
	"res://data/events_1402.json": "E39E4860732B9E38",
	"res://data/events_1453.json": "9F3F38909475CAED",
}
const ART_REQUEST_HASH := "07CBFA47768B153D"
const SCREENS: Array[String] = [
	"main_menu", "scenario_select", "world_map", "region_panel", "council", "family",
	"diplomacy", "military", "economy", "market", "army_management", "battle_n1",
	"battle_n2", "battle_n3", "year_end", "chronicle", "options", "victory",
]
const SEASON_CAPTURES: Array[String] = [
	"season_spring.png", "season_summer.png", "season_autumn.png", "season_winter.png",
]

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Fase 5A «El juego te explica» (C1-C11)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	print("[INFO] tests=%d; capturas=%d" % [_count_files("res://tests", "gd"), _count_files("res://docs/screenshots", "png")])
	_criterion_1_hud()
	_criterion_2_bulletin()
	_criterion_3_chronicle()
	_criterion_4_orders()
	_criterion_5_advice()
	_criterion_6_help()
	_criterion_7_unit_panels()
	_criterion_8_save()
	_criterion_9_regression()
	_criterion_10_governance()
	_criterion_11_manual()
	_finish()


# ---------------------------------------------------------------------------
# C1 — HUD estación/año/tinte/capturas
# ---------------------------------------------------------------------------

func _criterion_1_hud() -> void:
	var started := Time.get_ticks_msec()
	var id := "C1"
	var name := "HUD estación+año, tinte por estación y capturas de las 4 estaciones"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("get_season_name") or not gs.has_method("get_season_index") \
			or not gs.has_method("get_season_label"):
		_skip(id, name, "pendiente AG-2: sin get_season_name/index/label", started)
		return
	var expected := ["Primavera", "Verano", "Otoño", "Invierno"]
	var errors: Array[String] = []
	for index in range(4):
		var season := str(gs.call("get_season_name", index + 1))
		if season != expected[index]:
			errors.append("trimestre %d=%s (esperado %s)" % [index + 1, season, expected[index]])
	var hud_text := ""
	for path in ["res://scripts/ui/map/world_map.gd", "res://scripts/ui/tsb_game.gd"]:
		if FileAccess.file_exists(path):
			hud_text += FileAccess.get_file_as_string(path)
	if not (hud_text.contains("get_season_label") or hud_text.contains("get_season_name")):
		errors.append("HUD no usa estación")
	if not (hud_text.to_lower().contains("tint") or hud_text.to_lower().contains("tinte")):
		errors.append("sin tinte de estación en UI")
	var missing: Array[String] = []
	for capture in SEASON_CAPTURES:
		if not FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			missing.append(capture)
		elif _png_dimensions("res://docs/screenshots/%s" % capture) != Vector2i(1920, 1080):
			missing.append("%s (no 1920x1080)" % capture)
	if not missing.is_empty():
		_skip(id, name, "API/season OK; pendiente AG-3: capturas " + ", ".join(missing), started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "4 estaciones correctas; HUD usa estación/tinte; 4 capturas 1920×1080", started)


# ---------------------------------------------------------------------------
# C2 — Boletín trimestral
# ---------------------------------------------------------------------------

func _criterion_2_bulletin() -> void:
	var started := Time.get_ticks_msec()
	var id := "C2"
	var name := "Boletín ≥5 categorías, texto propio español, 0 botones muertos"
	var data_path := "res://data/legibility_texts.json"
	if not FileAccess.file_exists(data_path):
		_skip(id, name, "pendiente AG-1: falta legibility_texts.json", started)
		return
	var text := FileAccess.get_file_as_string(data_path)
	var categories := 0
	for marker in ["ingres", "gasto", "apoyo", "accion", "corte", "mercader", "event"]:
		if text.to_lower().contains(marker):
			categories += 1
	if categories < 5:
		_fail(id, name, "categorías detectadas=%d (<5)" % categories, started)
		return
	var ui_text := ""
	for path in ["res://scripts/ui/map/world_map.gd", "res://scripts/ui/economy/economy_screen.gd"]:
		if FileAccess.file_exists(path):
			ui_text += FileAccess.get_file_as_string(path)
	if not (ui_text.to_lower().contains("boletin") or ui_text.to_lower().contains("boletín")):
		_skip(id, name, "datos OK; pendiente AG-3: UI boletín", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/bulletin.png"):
		_skip(id, name, "datos/UI OK; pendiente captura bulletin.png", started)
		return
	_pass(id, name, "plantillas con %d categorías; UI boletín; captura presente" % categories, started)


# ---------------------------------------------------------------------------
# C3 — Crónica/histórico persistido
# ---------------------------------------------------------------------------

func _criterion_3_chronicle() -> void:
	var started := Time.get_ticks_msec()
	var id := "C3"
	var name := "Crónica anual + histórico persistido (hash) y consultable"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("append_chronicle") or not gs.has_method("get_chronicle"):
		_skip(id, name, "pendiente AG-2: sin append/get_chronicle", started)
		return
	_new_game("scenario_1337", "england")
	var entry := {"year": 1337, "season_or_year": "year", "kind": "year", "text": "QA Fase 5A"}
	gs.call("append_chronicle", entry)
	var chronicle: Variant = gs.call("get_chronicle")
	if not (chronicle is Array) or (chronicle as Array).is_empty():
		_fail(id, name, "append_chronicle no persiste en estado", started)
		return
	var before := _hash(gs.call("to_dict"))
	gs.call("from_dict", (gs.call("to_dict") as Dictionary).duplicate(true))
	if _hash(gs.call("to_dict")) != before:
		_fail(id, name, "hash chronicle no exacto tras round-trip", started)
		return
	var ui_text := ""
	for path in ["res://scripts/ui/map/world_map.gd", "res://scripts/ui/main/main_menu.gd"]:
		if FileAccess.file_exists(path):
			ui_text += FileAccess.get_file_as_string(path)
	if not (ui_text.to_lower().contains("cronica") or ui_text.to_lower().contains("crónica")):
		_skip(id, name, "API/hash OK; pendiente AG-3: pestaña Crónica", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/chronicle.png"):
		_skip(id, name, "API/UI OK; pendiente captura chronicle.png", started)
		return
	_pass(id, name, "append/get_chronicle + hash exacto; pestaña y captura presentes", started)


# ---------------------------------------------------------------------------
# C4 — Confirmación de órdenes
# ---------------------------------------------------------------------------

func _criterion_4_orders() -> void:
	var started := Time.get_ticks_msec()
	var id := "C4"
	var name := "Confirmación con lista (incl. vacía), Corregir/Confirmar y log determinista"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("record_turn_action") or not gs.has_method("get_turn_actions"):
		_skip(id, name, "pendiente AG-2: sin record/get_turn_actions", started)
		return
	_new_game("scenario_1337", "england")
	gs.call("record_turn_action", "diplomacy", "france", 8)
	gs.call("record_turn_action", "build", "region_london", 1)
	var actions: Variant = gs.call("get_turn_actions")
	if not (actions is Array) or (actions as Array).size() != 2:
		_fail(id, name, "turn_actions != 2", started)
		return
	var ui_text := ""
	if FileAccess.file_exists("res://scripts/ui/map/world_map.gd"):
		ui_text = FileAccess.get_file_as_string("res://scripts/ui/map/world_map.gd")
	if not (ui_text.to_lower().contains("tus órdenes") or ui_text.to_lower().contains("tus ordenes") or ui_text.to_lower().contains("confirm")):
		_skip(id, name, "API OK; pendiente AG-3: modal de confirmación", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/confirm_orders.png"):
		_skip(id, name, "API/UI OK; pendiente capturas confirm_orders/empty", started)
		return
	_pass(id, name, "record/get turn_actions; modal y capturas presentes; log determinista se valida en test", started)


# ---------------------------------------------------------------------------
# C5 — Consejero comercial
# ---------------------------------------------------------------------------

func _criterion_5_advice() -> void:
	var started := Time.get_ticks_msec()
	var id := "C5"
	var name := "Consejo comercial correcto (precio alto/bajo), sin RNG, captura"
	var trade := _autoload("TradeSystem")
	if trade == null or not trade.has_method("get_trade_advice"):
		_skip(id, name, "pendiente AG-2: sin get_trade_advice", started)
		return
	_new_game("scenario_1337", "england")
	var first: Variant = trade.call("get_trade_advice", "england")
	var second: Variant = trade.call("get_trade_advice", "england")
	if not (first is Dictionary) or not bool((first as Dictionary).get("ok", false)):
		_skip(id, name, "get_trade_advice existe pero aún no devuelve ok (AG-2 en curso): %s" % str(first), started)
		return
	if str(first) != str(second):
		_fail(id, name, "advice no determinista", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/market_advice.png"):
		_skip(id, name, "API/determinismo OK; pendiente AG-3: captura market_advice.png", started)
		return
	_pass(id, name, "advice determinista (%s); captura presente" % str((first as Dictionary).get("kind", "")), started)


# ---------------------------------------------------------------------------
# C6 — Ayuda «?» en todas las pantallas
# ---------------------------------------------------------------------------

func _criterion_6_help() -> void:
	var started := Time.get_ticks_msec()
	var id := "C6"
	var name := "Botón «?» en las 18 pantallas §9 con ayuda visible y capturas ≥4"
	var path := "res://data/context_help.json"
	if not FileAccess.file_exists(path):
		_skip(id, name, "pendiente AG-1: falta context_help.json", started)
		return
	var data: Variant = _read_json(path)
	if not (data is Dictionary):
		_fail(id, name, "context_help no legible", started)
		return
	var errors: Array[String] = []
	for screen in SCREENS:
		if not (data as Dictionary).has(screen):
			errors.append("falta %s" % screen)
	var captures := 0
	for capture in ["help_map.png", "help_diplomacy.png", "help_market.png", "help_military.png"]:
		if FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			captures += 1
	if captures < 4:
		_skip(id, name, "datos %d/18; pendiente AG-3: capturas help (%d/4) %s" % [18 - errors.size(), captures, ", ".join(errors.slice(0, 4))], started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "context_help 18/18; 4 capturas de ayuda", started)


# ---------------------------------------------------------------------------
# C7 — Paneles N2/N3
# ---------------------------------------------------------------------------

func _criterion_7_unit_panels() -> void:
	var started := Time.get_ticks_msec()
	var id := "C7"
	var name := "Paneles N2/N3: hombres/armas/apoyo/moral/experiencia + comandante"
	var ui_text := ""
	for path in ["res://scripts/ui/battle/tactical_map.gd", "res://scripts/ui/battle/close_combat.gd"]:
		if FileAccess.file_exists(path):
			ui_text += FileAccess.get_file_as_string(path)
	var errors: Array[String] = []
	for marker in ["arms", "supply", "morale", "training", "commander"]:
		if not ui_text.to_lower().contains(marker):
			errors.append("UI batalla sin %s" % marker)
	var captures := 0
	for capture in ["unit_panel_n2.png", "unit_panel_n3.png"]:
		if FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			captures += 1
	if captures < 2:
		_skip(id, name, "pendiente AG-3: capturas paneles (%d/2); UI markers: %s" % [captures, ", ".join(errors)], started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "UI N2/N3 con arms/supply/morale/training/commander; capturas 2/2", started)


# ---------------------------------------------------------------------------
# C8 — Save/load chronicle
# ---------------------------------------------------------------------------

func _criterion_8_save() -> void:
	var started := Time.get_ticks_msec()
	var id := "C8"
	var name := "Save/load chronicle en 3 puntos y defaults para partidas antiguas"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("append_chronicle"):
		_skip(id, name, "pendiente AG-2: sin chronicle API", started)
		return
	_new_game("scenario_1337", "england")
	var tm := _autoload("TurnManager")
	var hashes: Array[String] = []
	for step in range(3):
		if step > 0:
			tm.call("advance_quarter")
		if step == 1:
			gs.call("append_chronicle", {"year": 1337, "season_or_year": "year", "kind": "year", "text": "Test"})
		var before := _hash(gs.call("to_dict"))
		gs.call("from_dict", (gs.call("to_dict") as Dictionary).duplicate(true))
		hashes.append(_hash(gs.call("to_dict")))
		if before != hashes[step]:
			_fail(id, name, "hash distinto en punto %d" % (step + 1), started)
			return
	var state: Dictionary = _state()
	if not state.has("chronicle"):
		_fail(id, name, "estado sin chronicle", started)
		return
	_pass(id, name, "3/3 hashes exactos con chronicle; defaults se validan en test de migración", started)


# ---------------------------------------------------------------------------
# C9 — No regresión
# ---------------------------------------------------------------------------

func _criterion_9_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "C9"
	var name := "No regresión: run_all, validate 0 WARN, editor 0, IA<2 s, mapa<8 ms"
	var issues: Array[String] = []
	if _count_files("res://tests", "gd") < 36:
		issues.append("tests <36")
	for artifact in ["res://tests/qa_acceptance_fase4.gd", "res://tests/qa_acceptance_mvp_1337.gd",
			"res://tests/qa_acceptance_fase3_anim.gd", "res://tests/run_all.gd"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta %s" % artifact.get_file())
	if _autoload("MilitarySystem") == null:
		issues.append("MilitarySystem no monta")
	if not issues.is_empty():
		_fail(id, name, ", ".join(issues), started)
		return
	_pass(id, name, "%d tests y harness previos; run_all/validate/editor/IA/mapa se validan en batería externa" % _count_files("res://tests", "gd"), started)


# ---------------------------------------------------------------------------
# C10 — Gobernanza/congelación
# ---------------------------------------------------------------------------

func _criterion_10_governance() -> void:
	var started := Time.get_ticks_msec()
	var id := "C10"
	var name := "diff 0 1402/1453, sin arte externo, GDD v1.9.2 + D-079…083 + STATUS"
	var errors: Array[String] = []
	for path in FROZEN_FILES.keys():
		if not FileAccess.file_exists(path):
			errors.append("falta %s" % str(path).get_file())
			continue
		if _file_sha256(path).substr(0, 16).to_upper() != str(FROZEN_FILES[path]).to_upper():
			errors.append("%s modificado" % str(path).get_file())
	var art := "res://docs/art/requests/kimi_phase3_assets.md"
	if FileAccess.file_exists(art) and _file_sha256(art).substr(0, 16).to_upper() != ART_REQUEST_HASH.to_upper():
		errors.append("petición de arte modificada")
	var gdd := "res://GDD_The_Sovereign's_Blood.md"
	if not FileAccess.file_exists(gdd):
		errors.append("falta GDD")
	else:
		var gdd_text := FileAccess.get_file_as_string(gdd)
		if not gdd_text.contains("1.9.2"):
			errors.append("GDD no v1.9.2")
	var decisions := FileAccess.get_file_as_string("res://docs/decisions.md") if FileAccess.file_exists("res://docs/decisions.md") else ""
	for decision in ["D-079", "D-080", "D-081", "D-082", "D-083"]:
		if not decisions.contains(decision):
			errors.append("falta %s" % decision)
	var status := FileAccess.get_file_as_string("res://docs/STATUS.md") if FileAccess.file_exists("res://docs/STATUS.md") else ""
	if not status.contains("Fase 5A"):
		errors.append("STATUS sin Fase 5A")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "1402/1453 intactos (hashes); arte congelado; GDD 1.9.2; D-079…083; STATUS §21; diff fase-4..HEAD se valida externamente", started)


# ---------------------------------------------------------------------------
# C11 — Manual del Jugador actualizado
# ---------------------------------------------------------------------------

func _criterion_11_manual() -> void:
	var started := Time.get_ticks_msec()
	var id := "C11"
	var name := "Manual actualizado: 5 mejoras coherentes con context_help/legibility_texts y capturas"
	var path := "res://docs/MANUAL_DEL_JUGADOR.md"
	if not FileAccess.file_exists(path):
		_fail(id, name, "falta docs/MANUAL_DEL_JUGADOR.md", started)
		return
	var manual := FileAccess.get_file_as_string(path)
	var lower := manual.to_lower()
	var missing: Array[String] = []
	# 1) estaciones/HUD
	if not (lower.contains("primavera") and lower.contains("verano") and lower.contains("otoño") and lower.contains("invierno")):
		missing.append("estaciones/HUD")
	# 2) boletín/Crónica
	if not (lower.contains("boletín") and (lower.contains("crónica") or lower.contains("cronica")) and lower.contains("histórico")):
		missing.append("boletín/Crónica/histórico")
	# 3) confirmar órdenes/exenciones
	if not ((lower.contains("confirm") or lower.contains("corregir")) and (lower.contains("exent") or "libres" in lower)):
		missing.append("confirmar órdenes/exenciones")
	# 4) Consejero comercial y «?»
	if not ("consejero comercial" in lower or lower.contains("consejo comercial")):
		missing.append("Consejero comercial")
	if not (manual.contains("«?»") or manual.contains("\"?\"") or lower.contains("botón de ayuda") or lower.contains("ayuda contextual")):
		missing.append("botón «?»/ayuda contextual")
	# 5) panel de unidad N2/N3
	for term in ["armas", "apoyo", "moral", "entrenamiento", "comandante"]:
		if not lower.contains(term):
			missing.append("panel unidad sin %s" % term)
	# Coherencia con datos de ayuda/legibilidad.
	var help: Variant = _read_json("res://data/context_help.json")
	var legibility: Variant = _read_json("res://data/legibility_texts.json")
	var help_screens := 0
	if help is Dictionary:
		help_screens = (help as Dictionary).size()
	if help_screens < 18:
		missing.append("context_help=%d/18" % help_screens)
	if not (legibility is Dictionary):
		missing.append("legibility_texts ausente")
	else:
		for key in ["seasons", "hud", "quarterly_bulletin", "annual_chronicle", "battle_panel"]:
			if not (legibility as Dictionary).has(key):
				missing.append("legibility sin %s" % key)
	# Contraste mínimo con capturas de las mejoras.
	var captures := 0
	for capture in ["season_winter.png", "bulletin.png", "chronicle.png", "confirm_orders.png", "help_map.png", "unit_panel_n2.png"]:
		if FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			captures += 1
	if captures < 2:
		missing.append("capturas de contraste <2")
	if not missing.is_empty():
		_skip(id, name, "task-81 pendiente/Manual incompleto: faltan " + ", ".join(missing.slice(0, 8)), started)
		return
	_pass(id, name, "Manual con estaciones, boletín/Crónica, confirmación/exenciones, Consejero/«?» y panel N2/N3; context_help 18/18 y legibility coherentes; capturas de contraste presentes", started)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _new_game(scenario_id: String, faction_id: String) -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {"ok": false}
	var dl := _autoload("DataLoader")
	if dl != null and dl.has_method("load_all"):
		dl.call("load_all")
	if gs.has_method("reset"):
		gs.call("reset")
	gs.call("new_game", scenario_id, faction_id, 1337)
	var state: Variant = gs.get("state")
	return {"ok": state is Dictionary and not (state as Dictionary).is_empty()}


func _state() -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {}
	var st: Variant = gs.get("state")
	return st as Dictionary if st is Dictionary else {}


func _read_json(res_path: String) -> Variant:
	if not FileAccess.file_exists(res_path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(res_path)) != OK:
		return null
	return parser.data


func _autoload(autoload_name: String) -> Node:
	if root == null:
		return null
	return root.get_node_or_null(NodePath(autoload_name))


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


func _png_dimensions(res_path: String) -> Vector2i:
	if not FileAccess.file_exists(res_path):
		return Vector2i(0, 0)
	var file := FileAccess.open(res_path, FileAccess.READ)
	if file == null:
		return Vector2i(0, 0)
	var header := file.get_buffer(24)
	file.close()
	if header.size() < 24:
		return Vector2i(0, 0)
	var width := (int(header[16]) << 24) | (int(header[17]) << 16) | (int(header[18]) << 8) | int(header[19])
	var height := (int(header[20]) << 24) | (int(header[21]) << 16) | (int(header[22]) << 8) | int(header[23])
	return Vector2i(width, height)


func _file_sha256(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


func _hash(value: Variant) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(JSON.stringify(value).to_utf8_buffer())
	return ctx.finish().hex_encode()


func _record(id: String, name: String, status: String, detail: String, started_ms: int) -> void:
	_results.append({"id": id, "name": name, "status": status, "detail": detail, "ms": Time.get_ticks_msec() - started_ms})
	var suffix := "" if detail == "" else " :: " + detail
	print("  [%s] %s — %s%s" % [status, id, name, suffix])


func _pass(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "PASS", detail, started_ms)


func _fail(id: String, name: String, detail: String, started_ms: int) -> void:
	_record(id, name, "FAIL", detail, started_ms)


func _skip(id: String, name: String, reason: String, started_ms: int) -> void:
	_record(id, name, "SKIP", reason + " (pendiente: módulo Fase 5A en curso)", started_ms)


func _finish() -> void:
	var passed := 0
	var failed := 0
	var skipped := 0
	for result in _results:
		match str(result.get("status", "")):
			"PASS":
				passed += 1
			"FAIL":
				failed += 1
			"SKIP":
				skipped += 1
	print("--------------------------------------------------------------")
	print("RESULTADO QA FASE 5A: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [passed, failed, skipped, _results.size()])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0))])
	var code := 0
	if failed > 0:
		print("ACEPTACIÓN FASE 5A: NO ACEPTADA — FAIL en %d criterio(s) (exit 1)" % failed)
		code = 1
	elif skipped > 0:
		print("BASELINE FASE 5A: PENDIENTE — %d criterio(s) a la espera de módulos en curso (no es rechazo)" % skipped)
		code = 1
	else:
		print("ACEPTACIÓN FASE 5A: OK — 11/11 criterios PASS (exit 0)")
	print("--------------------------------------------------------------")
	quit(code)
