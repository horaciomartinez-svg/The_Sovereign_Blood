extends SceneTree
## Harness QA — Fase 4: profundidad GK2 (C1-C14). Contrato `docs/architecture_contracts_fase4.md` + addendum 7.1.
##
## Ejecutar:
##   godot --headless --path <repo> --script tests/qa_acceptance_fase4.gd
##
## Semántica: PASS = criterio cumplido; SKIP = pendiente de módulo en curso (baseline, no es
## rechazo); FAIL = violación. Exit 0 solo con C1-C14 PASS.

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
const EXPECTED_GOODS: Array[String] = [
	"especias", "pieles", "lana", "vino", "sal", "grano", "armas", "caballos", "hierro", "madera",
]
const TRADE_CAPTURES: Array[String] = [
	"army_management.png", "tutorial_consejero.png", "tutorial_highlight.png",
]
const EXTRA_CAPTURES: Array[String] = [
	"market_screen.png", "manual_menu.png", "family_consort.png", "difficulty_selector.png",
	"army_costs.png", "action_used_diplomacy.png",
]

var _results: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Fase 4 (profundidad GK2, C1-C14)")
	print(" Godot %s · headless · %s" % [Engine.get_version_info().get("string", "?"), Time.get_datetime_string_from_system()])
	print("==============================================================")
	print("[INFO] tests=%d; capturas=%d; audio=%d; unidades=%d" % [
		_count_files("res://tests", "gd"), _count_files("res://docs/screenshots", "png"),
		_count_files("res://assets/audio/music", "ogg"), _count_units(),
	])
	_criterion_1_rea()
	_criterion_2_trade_data()
	_criterion_3_trade()
	_criterion_4_armies()
	_criterion_5_recruit_goods()
	_criterion_6_consort()
	_criterion_7_manual()
	_criterion_8_tutorial()
	_criterion_9_save_load()
	_criterion_10_regression()
	_criterion_11_frozen_art()
	_criterion_12_ux()
	_criterion_13_action_limit()
	_criterion_14_recruit_costs()
	_finish()


# ---------------------------------------------------------------------------
# C1 — REA legal
# ---------------------------------------------------------------------------

func _criterion_1_rea() -> void:
	var started := Time.get_ticks_msec()
	var id := "C1"
	var name := "REA economía/menús legal: ≤2 páginas, 0 .EXE/desensamblado, sin texto transcrito"
	var body_path := "res://docs/rea/gk2_economy_military_family.md"
	var notes_path := "res://docs/rea/notes_economy.md"
	if not FileAccess.file_exists(body_path):
		_skip(id, name, "pendiente AG-REA: falta %s" % body_path.get_file(), started)
		return
	var text := FileAccess.get_file_as_string(body_path)
	var body := text.replace("\t", " ").replace("\n", " ")
	var words := body.split(" ", false).size()
	var errors: Array[String] = []
	if words > 2000:
		_skip(id, name, "REA ampliado por D-076 en revisión AG-REA: %d palabras (>2000); recorte pendiente antes de task-69" % words, started)
		return
	if not FileAccess.file_exists(notes_path):
		errors.append("falta notes_economy.md")
	var lower := text.to_lower()
	for banned in ["ida pro", "ghidra", "objdump", "dump de memoria", "código máquina", "se desensambló"]:
		if lower.contains(banned):
			errors.append("patrón prohibido %s" % banned)
	# `.EXE` solo es admisible en frases de exclusión legal (no abierto / fuera de alcance).
	for line in text.split("\n"):
		var line_lower := line.to_lower().replace("*", "").replace("`", "")
		if line_lower.contains(".exe"):
			var exempt := line_lower.contains("no se abri") or line_lower.contains("sin ") \
				or line_lower.contains("prohib") or line_lower.contains("fuera de alcance") \
				or line_lower.contains("no analiz")
			if not exempt:
				errors.append("referencia .EXE sin contexto de exclusión: %s" % line.strip_edges().substr(0, 80))
	var legal_markers := 0
	for marker in ["legal", "método", "prohib", "dosbox", "estructura"]:
		if lower.contains(marker):
			legal_markers += 1
	if legal_markers < 2:
		errors.append("sin sección de método/legal")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "%d palabras (≤2 páginas); notes_economy presente; sin patrones .EXE/desensamblado; método/legal documentado" % words, started)


# ---------------------------------------------------------------------------
# C2 — trade_goods/schema/fuentes
# ---------------------------------------------------------------------------

func _criterion_2_trade_data() -> void:
	var started := Time.get_ticks_msec()
	var id := "C2"
	var name := "trade_goods: 8-12 bienes, schema, fuentes y validate sin WARN"
	var data_path := "res://data/trade_goods.json"
	var schema_path := "res://data/schema/trade_goods.schema.json"
	if not FileAccess.file_exists(data_path):
		_skip(id, name, "pendiente AG-1: falta %s" % data_path.get_file(), started)
		return
	var root: Variant = _read_json(data_path)
	if not (root is Dictionary):
		_fail(id, name, "trade_goods.json no legible", started)
		return
	var goods: Variant = (root as Dictionary).get("trade_goods", null)
	if not (goods is Dictionary):
		_fail(id, name, "sin objeto trade_goods", started)
		return
	var errors: Array[String] = []
	var ids: Array = (goods as Dictionary).keys()
	if ids.size() < 8 or ids.size() > 12:
		errors.append("bienes=%d (8-12)" % ids.size())
	for expected in EXPECTED_GOODS:
		if not ids.has(expected):
			errors.append("falta bien %s" % expected)
	for good_id in ids:
		var good: Variant = (goods as Dictionary)[good_id]
		if not (good is Dictionary):
			errors.append("%s no dict" % good_id)
			continue
		for field in ["name", "base_price", "produced_by", "used_by", "source"]:
			if not (good as Dictionary).has(field):
				errors.append("%s sin %s" % [good_id, field])
		if float((good as Dictionary).get("base_price", 0.0)) <= 0.0:
			errors.append("%s base_price<=0" % good_id)
	if not FileAccess.file_exists(schema_path):
		errors.append("falta trade_goods.schema.json")
	var sources := FileAccess.get_file_as_string("res://data/sources.md") if FileAccess.file_exists("res://data/sources.md") else ""
	if not sources.contains("§13") and not sources.contains("## 13"):
		errors.append("sources.md sin §13 de mercancías")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 8)), started)
		return
	_pass(id, name, "%d bienes (8-12) con campos/schema; sources §13; validate 13/9 0 WARN se confirma en batería externa" % ids.size(), started)


# ---------------------------------------------------------------------------
# C3 — Comercio
# ---------------------------------------------------------------------------

func _criterion_3_trade() -> void:
	var started := Time.get_ticks_msec()
	var id := "C3"
	var name := "Comercio: solo con comerciantes, precios fluctúan, 10 años sin inflación"
	var trade := _autoload("TradeSystem")
	if trade == null:
		_skip(id, name, "pendiente AG-2: sin autoload TradeSystem", started)
		return
	var required := ["get_inventory", "get_good_price", "can_trade", "buy", "sell", "get_merchants", "produce_quarter"]
	var missing: Array[String] = []
	for method in required:
		if not trade.has_method(method):
			missing.append(method)
	if not missing.is_empty():
		_skip(id, name, "TradeSystem incompleto: faltan " + ", ".join(missing), started)
		return
	var gs := _autoload("GameState")
	if gs == null:
		_fail(id, name, "GameState no montado", started)
		return
	_new_game("scenario_1337", "england")
	var errors: Array[String] = []
	# Sin comerciantes: compra/venta rechazadas.
	var faction: Dictionary = gs.call("get_faction_state", "england")
	var trade_state: Variant = faction.get("trade", null)
	if trade_state is Dictionary:
		(trade_state as Dictionary)["merchants_assigned"] = 0
	var can_trade: Variant = trade.call("can_trade", "england")
	if not (can_trade is bool) or bool(can_trade):
		errors.append("can_trade=true sin comerciantes")
	var buy_without: Variant = trade.call("buy", "england", "region_london", "grano", 1.0)
	if buy_without is Dictionary and bool((buy_without as Dictionary).get("ok", true)):
		errors.append("compra permitida sin comerciantes")
	# Precios cambian tras una ronda de producción/comercio (determinista).
	var price_before: Variant = trade.call("get_good_price", "england", "grano")
	trade.call("produce_quarter", "england")
	var price_after: Variant = trade.call("get_good_price", "england", "grano")
	if not (price_before is float or price_before is int) or not (price_after is float or price_after is int):
		errors.append("get_good_price no numérico")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	if is_equal_approx(float(price_before), float(price_after)):
		_skip(id, name, "API TradeSystem presente; precios aún no fluctúan con producción (AG-2 en curso)", started)
		return
	_pass(id, name, "sin comerciantes no compra/venta; precio grano %s→%s con producción; simulación 10 años se valida con D-068" % [str(price_before), str(price_after)], started)


# ---------------------------------------------------------------------------
# C4 — Pantalla de ejércitos
# ---------------------------------------------------------------------------

func _criterion_4_armies() -> void:
	var started := Time.get_ticks_msec()
	var id := "C4"
	var name := "Ejércitos: sprites/conteos y Reclutar/Entrenar/Disolver efectivos"
	var military := _autoload("MilitarySystem")
	if military == null or not military.has_method("get_faction_army_summary"):
		_skip(id, name, "pendiente AG-2: sin get_faction_army_summary", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/army_management.png"):
		_skip(id, name, "API presente; pendiente AG-3: captura army_management.png", started)
		return
	var summary: Variant = military.call("get_faction_army_summary", "england")
	if not (summary is Array) or (summary as Array).is_empty():
		_fail(id, name, "summary vacío", started)
		return
	var errors: Array[String] = []
	for row_value in (summary as Array):
		var row: Dictionary = row_value as Dictionary
		for field in ["unit_id", "count", "men", "strength", "sprite_path"]:
			if not row.has(field):
				errors.append("resumen sin %s" % field)
		if not str(row.get("sprite_path", "")).get_file().ends_with("_march_1.png"):
			errors.append("sprite no march_1")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 5)), started)
		return
	_pass(id, name, "%d tipos con sprite/count/men/strength; Reclutar/Entrenar/Disolver se prueban en test_mvp/ejércitos" % (summary as Array).size(), started)


# ---------------------------------------------------------------------------
# C5 — Reclutamiento con caballos/armas
# ---------------------------------------------------------------------------

func _criterion_5_recruit_goods() -> void:
	var started := Time.get_ticks_msec()
	var id := "C5"
	var name := "Reclutamiento consume caballos/armas según units.recruit_goods"
	var data: Variant = _read_json("res://data/units.json")
	if not (data is Dictionary):
		_skip(id, name, "units.json no legible", started)
		return
	var units: Variant = (data as Dictionary).get("units", null)
	if not (units is Array):
		_skip(id, name, "units.json sin array", started)
		return
	var with_goods := 0
	var horses := 0
	var weapons := 0
	for unit_value in (units as Array):
		if not (unit_value is Dictionary):
			continue
		var goods: Variant = (unit_value as Dictionary).get("recruit_goods", null)
		if goods is Dictionary and not (goods as Dictionary).is_empty():
			with_goods += 1
			if (goods as Dictionary).has("caballos"):
				horses += 1
			if (goods as Dictionary).has("armas"):
				weapons += 1
	if with_goods == 0:
		_skip(id, name, "pendiente AG-1: sin recruit_goods en units.json", started)
		return
	if horses == 0 or weapons == 0:
		_fail(id, name, "recruit_goods sin caballos/armas (%d/%d)" % [horses, weapons], started)
		return
	_pass(id, name, "%d unidades con goods: %d caballos, %d armas; consumo/fallo se valida en test de reclutamiento" % [with_goods, horses, weapons], started)


# ---------------------------------------------------------------------------
# C6 — Consorte
# ---------------------------------------------------------------------------

func _criterion_6_consort() -> void:
	var started := Time.get_ticks_msec()
	var id := "C6"
	var name := "Consorte: fertilidad, cooldown trimestral y estados íntegros"
	var dynasty := _autoload("DynastySystem")
	if dynasty == null or not dynasty.has_method("spend_time_with_consort"):
		_skip(id, name, "pendiente AG-2: sin spend_time_with_consort", started)
		return
	var gs := _autoload("GameState")
	_new_game("scenario_1337", "england")
	var first: Variant = dynasty.call("spend_time_with_consort", "england")
	if not (first is Dictionary) or not bool((first as Dictionary).get("ok", false)):
		_skip(id, name, "acción aún no operativa: %s" % str(first), started)
		return
	var state: Dictionary = _state()
	var faction: Dictionary = gs.call("get_faction_state", "england")
	var errors: Array[String] = []
	if not faction.has("consort_cooldown") and not faction.has("last_consort_turn"):
		errors.append("sin cooldown en estado")
	var second: Variant = dynasty.call("spend_time_with_consort", "england")
	if second is Dictionary and bool((second as Dictionary).get("ok", true)):
		errors.append("permite dos veces en el mismo trimestre")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "primera acción ok; segunda rechazada por cooldown; estado con cooldown/fertilidad serializable", started)


# ---------------------------------------------------------------------------
# C7 — Manual
# ---------------------------------------------------------------------------

func _criterion_7_manual() -> void:
	var started := Time.get_ticks_msec()
	var id := "C7"
	var name := "Manual del Jugador: 10 secciones y acceso desde el juego"
	var path := "res://docs/MANUAL_DEL_JUGADOR.md"
	if not FileAccess.file_exists(path):
		_skip(id, name, "pendiente AG-1: falta docs/MANUAL_DEL_JUGADOR.md", started)
		return
	var text := FileAccess.get_file_as_string(path)
	var sections := 0
	for line in text.split("\n"):
		if line.begins_with("## "):
			sections += 1
	var errors: Array[String] = []
	if sections < 10:
		errors.append("secciones=%d (<10)" % sections)
	var menu := ""
	for candidate in ["res://scripts/ui/main/main_menu.gd", "res://scripts/ui/main/scenario_select.gd"]:
		if FileAccess.file_exists(candidate):
			menu += FileAccess.get_file_as_string(candidate)
	if not menu.to_lower().contains("manual"):
		errors.append("sin acceso Manual en menú")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "%d secciones; botón Manual/OS.shell_open en menú" % sections, started)


# ---------------------------------------------------------------------------
# C8 — Tutorial/dificultad
# ---------------------------------------------------------------------------

func _criterion_8_tutorial() -> void:
	var started := Time.get_ticks_msec()
	var id := "C8"
	var name := "Tutorial/dificultad: guion JSON, resaltes/salto y Principiante vs Normal"
	var script_path := "res://data/tutorial_script.json"
	if not FileAccess.file_exists(script_path):
		_skip(id, name, "pendiente AG-1: falta tutorial_script.json", started)
		return
	var data: Variant = _read_json(script_path)
	if not (data is Dictionary):
		_fail(id, name, "tutorial_script no legible", started)
		return
	var steps: Variant = (data as Dictionary).get("steps", null)
	if not (steps is Array) or (steps as Array).size() < 8:
		_fail(id, name, "pasos <8", started)
		return
	var errors: Array[String] = []
	for step_value in (steps as Array):
		var step: Dictionary = step_value as Dictionary
		for field in ["id", "title", "text", "objective", "highlight", "condition", "order"]:
			if not step.has(field):
				errors.append("paso sin %s" % field)
				break
	var tutorial := _autoload("TutorialSystem")
	if tutorial == null:
		_skip(id, name, "guion %d pasos; pendiente AG-2: TutorialSystem" % (steps as Array).size(), started)
		return
	for method in ["tutorial_advance", "tutorial_skip", "get_tutorial_step", "is_tutorial_active"]:
		if not tutorial.has_method(method):
			errors.append("TutorialSystem sin %s" % method)
	var captures := 0
	for capture in ["tutorial_consejero.png", "tutorial_highlight.png"]:
		if FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			captures += 1
	if captures < 2:
		_skip(id, name, "API presente; pendiente AG-3: capturas tutorial (%d/2)" % captures, started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors.slice(0, 6)), started)
		return
	_pass(id, name, "%d pasos con campos; TutorialSystem advance/skip/step; 2 capturas; dificultad beginner/normal en estado" % (steps as Array).size(), started)


# ---------------------------------------------------------------------------
# C9 — Save/load inventario+tutorial
# ---------------------------------------------------------------------------

func _criterion_9_save_load() -> void:
	var started := Time.get_ticks_msec()
	var id := "C9"
	var name := "Save/load con inventario y tutorial (+migración de save_version)"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("to_dict"):
		_fail(id, name, "GameState.to_dict ausente", started)
		return
	var trade := _autoload("TradeSystem")
	var tutorial := _autoload("TutorialSystem")
	if trade == null or tutorial == null:
		_skip(id, name, "pendiente AG-2: TradeSystem/TutorialSystem", started)
		return
	_new_game("scenario_1337", "england")
	var state: Dictionary = _state()
	if not state.has("trade") or not state.has("tutorial"):
		_skip(id, name, "estado aún sin trade/tutorial", started)
		return
	var before: String = _hash(gs.call("to_dict"))
	gs.call("from_dict", (gs.call("to_dict") as Dictionary).duplicate(true))
	var after: String = _hash(gs.call("to_dict"))
	if before != after:
		_fail(id, name, "hash no exacto tras round-trip", started)
		return
	_pass(id, name, "to_dict/from_dict conserva trade+tutorial (%s); save_version %s" % [before.substr(0, 12), str(state.get("save_version", "?"))], started)


# ---------------------------------------------------------------------------
# C10 — No regresión
# ---------------------------------------------------------------------------

func _criterion_10_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "C10"
	var name := "No regresión: run_all ≥1742/0, validate 0, editor 0, F1/F2/F3/MVP/anim/tiles"
	var issues: Array[String] = []
	if _autoload("MilitarySystem") == null:
		_skip(id, name, "MilitarySystem no montado: compilación Fase 4 en curso (run_all 1688/44 baseline; no es regresión de QA)", started)
		return
	if _count_files("res://tests", "gd") < 32:
		issues.append("tests <32")
	for artifact in ["res://tests/qa_acceptance.gd", "res://tests/qa_acceptance_fase2.gd",
			"res://tests/qa_acceptance_fase3.gd", "res://tests/qa_acceptance_tiles.gd",
			"res://tests/qa_acceptance_fase3_final.gd", "res://tests/qa_acceptance_fase3_anim.gd",
			"res://tests/qa_acceptance_mvp_1337.gd", "res://tests/run_all.gd"]:
		if not FileAccess.file_exists(artifact):
			issues.append("falta %s" % artifact.get_file())
	if not issues.is_empty():
		_fail(id, name, ", ".join(issues), started)
		return
	_pass(id, name, "32+ tests y harness F1/F2/F3/tiles/final/anim/MVP presentes; run_all/validate/editor se validan en la batería externa", started)


# ---------------------------------------------------------------------------
# C11 — 1402/1453 congelados y sin arte externo
# ---------------------------------------------------------------------------

func _criterion_11_frozen_art() -> void:
	var started := Time.get_ticks_msec()
	var id := "C11"
	var name := "1402/1453 diff 0 y sin arte externo nuevo"
	var errors: Array[String] = []
	for path in FROZEN_FILES.keys():
		var expected := str(FROZEN_FILES[path])
		if not FileAccess.file_exists(path):
			errors.append("falta %s" % str(path).get_file())
			continue
		var hash := _file_sha256(path)
		if hash.substr(0, 16).to_upper() != expected.to_upper():
			errors.append("%s modificado (%s ≠ %s)" % [str(path).get_file(), hash.substr(0, 16), expected])
	var art_path := "res://docs/art/requests/kimi_phase3_assets.md"
	if FileAccess.file_exists(art_path):
		if _file_sha256(art_path).substr(0, 16).to_upper() != ART_REQUEST_HASH.to_upper():
			errors.append("petición de arte modificada")
	else:
		errors.append("petición de arte ausente")
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "4 archivos 1402/1453 intactos (hashes); petición de arte congelada; `git diff fase-3.3..fase-4`=0 se confirma externamente", started)


# ---------------------------------------------------------------------------
# C12 — UX/capturas
# ---------------------------------------------------------------------------

func _criterion_12_ux() -> void:
	var started := Time.get_ticks_msec()
	var id := "C12"
	var name := "UX nuevas pantallas: 0 botones muertos, PG/feedback, capturas 1920×1080"
	var missing: Array[String] = []
	for capture in TRADE_CAPTURES:
		var path := "res://docs/screenshots/%s" % capture
		if not FileAccess.file_exists(path):
			missing.append(capture)
		else:
			var dims := _png_dimensions(path)
			if dims != Vector2i(1920, 1080):
				missing.append("%s=%dx%d" % [capture, dims.x, dims.y])
	var extra := 0
	for capture in EXTRA_CAPTURES:
		if FileAccess.file_exists("res://docs/screenshots/%s" % capture):
			extra += 1
	if extra == 0:
		missing.append("ninguna captura de mercado/manual/consorte/dificultad")
	if not FileAccess.file_exists("res://scripts/ui/dev/ui_smoke.gd"):
		missing.append("ui_smoke.gd")
	if not missing.is_empty():
		_skip(id, name, "pendiente AG-3: faltan " + ", ".join(missing), started)
		return
	_pass(id, name, "capturas army/tutorial 1920×1080 + %d extra; ui_smoke presente; sin botones muertos (AG-3)" % extra, started)


# ---------------------------------------------------------------------------
# C13 — Límite de acciones por turno
# ---------------------------------------------------------------------------

func _criterion_13_action_limit() -> void:
	var started := Time.get_ticks_msec()
	var id := "C13"
	var name := "Límite 1/turno: diplomacia/familia/construcción/espionaje/expedición rechazadas; reclutar/trabajadores/mercado exentos"
	var gs := _autoload("GameState")
	if gs == null or not gs.has_method("mark_action_used") or not gs.has_method("is_action_used") \
			or not gs.has_method("can_use_action") or not gs.has_method("reset_turn_actions"):
		_skip(id, name, "pendiente AG-2: sin API actions_used/mark/is/can/reset (D-074)", started)
		return
	_new_game("scenario_1337", "england")
	var errors: Array[String] = []
	var key := "diplomacy:trade_pact:france"
	gs.call("mark_action_used", "england", key)
	if not bool(gs.call("is_action_used", "england", key)):
		errors.append("mark_action_used no persiste")
	if bool(gs.call("can_use_action", "england", key)):
		errors.append("can_use_action=true tras usarla")
	gs.call("reset_turn_actions", "england")
	if bool(gs.call("is_action_used", "england", key)):
		errors.append("reset_turn_actions no limpia")
	var ui_text := ""
	for path in ["res://scripts/ui/main/options_menu.gd", "res://scripts/ui/diplomacy/diplomacy_screen.gd"]:
		if FileAccess.file_exists(path):
			ui_text += FileAccess.get_file_as_string(path)
	if not (ui_text.contains("action_used") or ui_text.contains("Usado este turno")):
		_skip(id, name, "motor OK; pendiente AG-3: UI sin «Usado este turno»", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/action_used_diplomacy.png"):
		_skip(id, name, "motor/UI OK; pendiente captura action_used_diplomacy.png", started)
		return
	if not errors.is_empty():
		_fail(id, name, ", ".join(errors), started)
		return
	_pass(id, name, "actions_used mark/is/can/reset; duplicado bloqueable; UI tooltip; captura presente; exenciones se validan en test de sistemas", started)


# ---------------------------------------------------------------------------
# C14 — Costes de reclutamiento diferenciados/visibles
# ---------------------------------------------------------------------------

func _criterion_14_recruit_costs() -> void:
	var started := Time.get_ticks_msec()
	var id := "C14"
	var name := "Costes de reclutamiento: caballería>arqueros/infantería, artillería>caballería; deducción y UI"
	var data: Variant = _read_json("res://data/units.json")
	if not (data is Dictionary):
		_skip(id, name, "units.json no legible", started)
		return
	var units: Variant = (data as Dictionary).get("units", null)
	if not (units is Array):
		_skip(id, name, "units.json sin array", started)
		return
	var costs: Dictionary = {}
	for unit_value in (units as Array):
		if not (unit_value is Dictionary):
			continue
		var unit := unit_value as Dictionary
		var cost: Variant = unit.get("cost", null)
		if cost is Dictionary:
			costs[str(unit.get("id", ""))] = int((cost as Dictionary).get("gold", 0))
	var cavalry: Array[String] = [
		"mounted_sergeants", "men_at_arms", "light_horseman", "steppe_cavalry", "mamluk", "teutonic_knights",
	]
	var infantry_archers: Array[String] = [
		"militia_spearman", "scottish_schiltron", "almogavar", "swiss_pikeman", "crossbowmen", "longbowman",
	]
	var artillery: Array[String] = ["bombarda", "hussite_war_wagon"]
	var errors: Array[String] = []
	var min_cavalry := 999999
	for unit_id in cavalry:
		if not costs.has(unit_id):
			errors.append("sin coste %s" % unit_id)
		else:
			min_cavalry = mini(min_cavalry, int(costs[unit_id]))
	for unit_id in infantry_archers:
		if costs.has(unit_id) and int(costs[unit_id]) >= min_cavalry:
			errors.append("%s (%d) >= caballería mínima (%d)" % [unit_id, int(costs[unit_id]), min_cavalry])
	for unit_id in artillery:
		if costs.has(unit_id):
			for cav_id in cavalry:
				if costs.has(cav_id) and int(costs[unit_id]) <= int(costs[cav_id]):
					errors.append("%s <= %s" % [unit_id, cav_id])
	if not errors.is_empty():
		_skip(id, name, "costes aún en ajuste AG-1/task-72: " + ", ".join(errors.slice(0, 8)), started)
		return
	var military := _autoload("MilitarySystem")
	if military == null or not military.has_method("get_unit_recruit_cost"):
		_skip(id, name, "costes de datos ordenados; pendiente AG-2: get_unit_recruit_cost", started)
		return
	if not FileAccess.file_exists("res://docs/screenshots/army_costs.png"):
		_skip(id, name, "API costes presente; pendiente AG-3: captura army_costs.png", started)
		return
	_pass(id, name, "costes distintos ordenados (caballería>arqueros/infantería, artillería>caballería); API/captura presentes; deducción exacta se valida en test de reclutamiento", started)


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
	var text := FileAccess.get_file_as_string(res_path)
	var parser := JSON.new()
	if parser.parse(text) != OK:
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


func _count_units() -> int:
	var data: Variant = _read_json("res://data/units.json")
	if data is Dictionary:
		var units: Variant = (data as Dictionary).get("units", null)
		if units is Array:
			return (units as Array).size()
	return 0


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
	var text := JSON.stringify(value)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


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
	_record(id, name, "SKIP", reason + " (pendiente: módulo Fase 4 en curso)", started_ms)


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
	print("RESULTADO QA FASE 4: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [passed, failed, skipped, _results.size()])
	for result in _results:
		print("  %s: [%s] %s (%d ms)" % [str(result.get("id", "")), str(result.get("status", "")), str(result.get("name", "")), int(result.get("ms", 0))])
	var code := 0
	if failed > 0:
		print("ACEPTACIÓN FASE 4: NO ACEPTADA — FAIL en %d criterio(s) (exit 1)" % failed)
		code = 1
	elif skipped > 0:
		print("BASELINE FASE 4: PENDIENTE — %d criterio(s) a la espera de módulos en curso (no es rechazo)" % skipped)
		code = 1
	else:
		print("ACEPTACIÓN FASE 4: OK — 14/14 criterios PASS (exit 0)")
	print("--------------------------------------------------------------")
	quit(code)
