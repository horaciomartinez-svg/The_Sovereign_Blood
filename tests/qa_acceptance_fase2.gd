extends SceneTree
## QA Aceptación Fase 2 — The Sovereign's Blood (AG-4).
##
## Uso:
##   godot --headless --path <repo> --script tests/qa_acceptance_fase2.gd
##
## Cubre GDD v1.4 §10.1, §10.2, §12 Fase 2 y contrato
## docs/architecture_contracts_fase2.md §8:
##   F2-C1 Crécy Inglaterra vs Francia resuelto en Niveles 1, 2 y 3 (coherente, sin crash).
##   F2-C2 Extinción dinástica: gobernante + casa sin miembros vivos → game_over derrota
##          inmediata y sin turnos fantasma.
##   F2-C3 §10.1 datos: 47/47 polígonos × 1337/1402/1453, ids, anillos, área, ≤150 KB,
##          hit-test punto-en-polígono, benchmark CPU del controlador <8 ms/frame (≥120 frames),
##          terreno 4096×3072, integración map_borders y captura comparativa.
##   F2-C4 §10.2 retratos: 5 slots con fallback nunca vacío, sucesión actualiza el retrato del
##          mapa al heredero y capturas presentes.
##   F2-C5 Smoke de TODAS las escenas (nuevas tactical_map/close_combat + 16 previas).
##   F2-C6 No regresión Fase 1 embebida: save/load exacto, Peste Negra 1348, determinismo,
##          UI sin mutaciones de estado y 16 escenas previas.
##
## Semántica: [PASS] criterio verificado; [FAIL] regresión/incumplimiento con el sistema ya
## presente; [SKIP] módulo de Fase 2 aún no integrado (pendiente AG-1/AG-2/AG-3), justificado.
## Exit 0 SOLO si los 6 criterios son PASS. El harness compila siempre (no preload de archivos
## de Fase 2 que aún no existen; los detecta en runtime con FileAccess/load/has_method).

const PLAYER_FACTION: String = "england"
const SCENARIO_ID: String = "scenario_1337"
const SEED: int = 1337
const SAVE_SLOT: String = "qa_acceptance_fase2"
const YEARS: Array[int] = [1337, 1402, 1453]
const REGION_COUNT: int = 47
const MAP_BORDERS_PATH: String = "res://data/map_borders.json"
const MAP_BORDERS_MAX_BYTES: int = 147456
const MAP_FRAME_BUDGET_MS: float = 8.0
const MAP_BENCH_FRAMES: int = 120
const PORTRAIT_SCRIPT: String = "res://scripts/ui/widgets/portrait_frame.gd"
const F2_SCENES: Array[String] = [
	"res://scenes/battle/tactical_map.tscn",
	"res://scenes/battle/close_combat.tscn",
]
const F1_MIN_SCENES: int = 16
const PORTRAIT_SLOT_FILES: Array[String] = [
	"res://scripts/ui/map/world_map.gd",
	"res://scripts/ui/family/family_tree.gd",
	"res://scripts/ui/diplomacy/diplomacy_screen.gd",
	"res://scripts/ui/battle/battle_report.gd",
	"res://scripts/ui/ui/court_overview.gd",
]
const AUTOLOADS: Array[String] = [
	"EventBus", "DataLoader", "GameState", "TurnManager", "EconomySystem",
	"DynastySystem", "DiplomacySystem", "MilitarySystem", "BattleManager", "AIManager",
]
## Los 14 gobernantes del escenario 1337 con retrato final (v1.5). Los gobernantes
## añadidos en Fase 3 (1402/1453) usan fallback heráldico y no forman parte de esta lista.
const ORIGINAL_1337_RULERS: Array[String] = [
	"edward_iii_plantagenet", "philippe_vi_de_valois", "ludwig_iv_wittelsbach", "jan_lucembursky",
	"karoly_robert_anjou", "alfonso_xi_borgona", "pere_iv_d_arago", "kazimierz_iii_piast",
	"david_ii_bruce", "benedict_xii", "yusuf_i_nazari", "an_nasir_muhammad", "oz_beg",
	"andronikos_iii_palaiologos",
]

var results: Array[Dictionary] = []
var _game_over_events: Array[Dictionary] = []
var _extinct_signals: Array[String] = []
var _succession_signals: Array[Dictionary] = []


func _initialize() -> void:
	print("==============================================================")
	print(" The Sovereign's Blood — QA Aceptación Fase 2 (GDD §10.1/§10.2/§12)")
	print(" Godot %s · headless · %s" % [
		str(Engine.get_version_info().get("string", "")),
		Time.get_datetime_string_from_system(),
	])
	print("==============================================================")
	_print_environment()
	_connect_f2_signals()
	_criterion_1_crecy()
	_criterion_2_extinction()
	await _criterion_3_map_10_1()
	await _criterion_4_portraits_10_2()
	_criterion_5_scene_smoke()
	_criterion_6_no_regression()
	_finish()


# ---------------------------------------------------------------------------
# Infraestructura
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
	_record(id, name, "SKIP", reason + " (pendiente: módulo Fase 2 aún no integrado)", started_ms)


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


func _read_text(res_path: String) -> String:
	if not FileAccess.file_exists(res_path):
		return ""
	return FileAccess.get_file_as_string(res_path)


func _file_size(res_path: String) -> int:
	if not FileAccess.file_exists(res_path):
		return -1
	var file := FileAccess.open(res_path, FileAccess.READ)
	if file == null:
		return -1
	var size := file.get_length()
	file.close()
	return size


func _state() -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {}
	var st: Variant = gs.get("state")
	if st is Dictionary:
		return st as Dictionary
	return {}


func _state_is_empty() -> bool:
	var gs := _autoload("GameState")
	if gs == null:
		return true
	var st: Variant = gs.get("state")
	return not (st is Dictionary) or (st as Dictionary).is_empty()


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
	if _state_is_empty():
		return {"ok": false, "reason": "GameState.state vacío tras new_game()"}
	return {"ok": true, "reason": ""}


func _print_environment() -> void:
	print("[INFO] Fase 2 — presencia de artefactos:")
	print("  data/map_borders.json: %s" % str(FileAccess.file_exists(MAP_BORDERS_PATH)))
	print("  scripts/battle/tactical_battle.gd: %s" % str(FileAccess.file_exists("res://scripts/battle/tactical_battle.gd")))
	print("  scripts/battle/close_combat.gd: %s" % str(FileAccess.file_exists("res://scripts/battle/close_combat.gd")))
	print("  scripts/ui/widgets/portrait_frame.gd: %s" % str(FileAccess.file_exists(PORTRAIT_SCRIPT)))
	print("  scenes/battle/tactical_map.tscn: %s" % str(FileAccess.file_exists("res://scenes/battle/tactical_map.tscn")))
	print("  scenes/battle/close_combat.tscn: %s" % str(FileAccess.file_exists("res://scenes/battle/close_combat.tscn")))
	print("  assets/art/map/terrain_base.png: %s" % str(FileAccess.file_exists("res://assets/art/map/terrain_base.png")))
	print("  data/map_layout.json (debe retirarse al cerrar D-024): %s" % str(FileAccess.file_exists("res://data/map_layout.json")))
	var missing: Array[String] = []
	for autoload_name in AUTOLOADS:
		if _autoload(autoload_name) == null:
			missing.append(autoload_name)
	if missing.is_empty():
		print("  10/10 autoloads montados")
	else:
		print("  [WARN] autoloads ausentes: %s" % ", ".join(missing))


func _connect_f2_signals() -> void:
	var bus := _autoload("EventBus")
	if bus != null:
		if bus.has_signal("game_over"):
			bus.connect("game_over", Callable(self, "_on_game_over"))
		if bus.has_signal("dynasty_extinct"):
			bus.connect("dynasty_extinct", Callable(self, "_on_dynasty_extinct"))
		if bus.has_signal("succession_resolved"):
			bus.connect("succession_resolved", Callable(self, "_on_succession_resolved"))
	var dyn := _autoload("DynastySystem")
	if dyn != null and dyn.has_signal("dynasty_extinct"):
		dyn.connect("dynasty_extinct", Callable(self, "_on_dynasty_extinct"))


func _on_game_over(faction_id: String, victory: bool, reason: String) -> void:
	_game_over_events.append({"faction": faction_id, "victory": victory, "reason": reason})


func _on_dynasty_extinct(faction_id: String) -> void:
	_extinct_signals.append(faction_id)


func _on_succession_resolved(faction_id: String, heir_id: String) -> void:
	_succession_signals.append({"faction": faction_id, "heir": heir_id})


# ---------------------------------------------------------------------------
# Helpers de batalla (modelos dinámicos: si faltan, se reporta SKIP)
# ---------------------------------------------------------------------------

func _make_army(faction_id: String, region_id: String, leader_id: String, unit_id: String,
		size: int, strength: int) -> Variant:
	var script: Variant = load("res://scripts/model/army.gd")
	if not (script is GDScript):
		return null
	var army: Variant = (script as GDScript).new()
	if army == null:
		return null
	army.set("id", "qa_%s_%s" % [faction_id, unit_id])
	army.set("faction_id", faction_id)
	army.set("region_id", region_id)
	army.set("leader_id", leader_id)
	army.set("morale", 1.0)
	army.set("units", [{
		"id": "u1",
		"unit_id": unit_id,
		"size": size,
		"strength": strength,
		"morale": 1.0,
		"experience": 50,
	}])
	return army


func _make_region(region_id: String, terrain: String, support: int, wealth: int, has_city: bool) -> Variant:
	var script: Variant = load("res://scripts/model/region_state.gd")
	if not (script is GDScript):
		return null
	var region: Variant = (script as GDScript).new()
	if region == null:
		return null
	region.set("id", region_id)
	region.set("terrain", terrain)
	region.set("support", support)
	region.set("base_wealth", wealth)
	region.set("has_city", has_city)
	return region


func _report_dict(report: Variant) -> Dictionary:
	if report == null:
		return {}
	if report is Dictionary:
		return report as Dictionary
	if report is Object and (report as Object).has_method("to_dict"):
		var data: Variant = (report as Object).call("to_dict")
		if data is Dictionary:
			return data as Dictionary
	return {}


func _battle_report_ok(report: Dictionary) -> Dictionary:
	if report.is_empty():
		return {"ok": false, "reason": "informe vacío/null"}
	var winner := str(report.get("winner_faction", ""))
	if winner != "england" and winner != "france":
		return {"ok": false, "reason": "winner_faction inválido: '%s'" % winner}
	var attacker_losses: Variant = report.get("attacker_losses", null)
	var defender_losses: Variant = report.get("defender_losses", null)
	if attacker_losses == null or defender_losses == null:
		return {"ok": false, "reason": "sin campos de bajas"}
	var rounds: Variant = report.get("rounds", [])
	if not (rounds is Array):
		rounds = []
	var detail := "winner=%s; bajas=%s/%s; asaltos=%d" % [
		winner, str(attacker_losses), str(defender_losses), (rounds as Array).size(),
	]
	if (rounds as Array).size() < 1 or (rounds as Array).size() > 5:
		return {"ok": false, "reason": "asaltos fuera de 1..5: %s" % detail}
	return {"ok": true, "detail": detail}


# ---------------------------------------------------------------------------
# F2-C1 — Crécy Inglaterra vs Francia en Niveles 1, 2 y 3
# ---------------------------------------------------------------------------

func _criterion_1_crecy() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C1"
	var name := "Crécy Inglaterra vs Francia resuelto en Niveles 1, 2 y 3 (coherente, sin crash)"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var battle := _autoload("BattleManager")
	if battle == null or not battle.has_method("resolve_delegated"):
		_skip(id, name, "BattleManager.resolve_delegated() no disponible", started)
		return

	# Nivel 1 — combate delegado (debe existir ya en Fase 1).
	var n1_report := _run_crecy_n1(battle)
	var n1_check := _battle_report_ok(n1_report)
	var n1_ok := bool(n1_check["ok"])
	var n1_detail := str(n1_check.get("detail", n1_check.get("reason", "")))
	# Determinismo N1: misma semilla → mismo informe.
	var n1_again := _run_crecy_n1(battle)
	var n1_det := JSON.stringify(n1_report) == JSON.stringify(n1_again)

	# Nivel 2 — mapa táctico (TacticalBattle, Fase 2).
	var n2_status := "AUSENTE (BattleManager.launch_tactical no declarado)"
	var n2_ok := false
	var n2_detail := ""
	if battle.has_method("launch_tactical"):
		n2_status = "PRESENTE"
		var tactical_a := _run_crecy_n2(battle)
		var tactical_b := _run_crecy_n2(battle)
		var n2_same := str(tactical_a.get("signature", "?a")) == str(tactical_b.get("signature", "?b"))
		n2_ok = bool(tactical_a["ok"]) and bool(tactical_b["ok"]) and n2_same
		n2_detail = str(tactical_a.get("detail", tactical_a.get("reason", ""))) + "; determinista=" + str(n2_same)
		if not bool(tactical_a["ok"]) and str(tactical_a.get("reason", "")).contains("stub"):
			n2_status = "STUB"

	# Nivel 3 — combate cerrado (CloseCombat, Fase 2).
	var n3_status := "AUSENTE (BattleManager.launch_close_combat no declarado)"
	var n3_ok := false
	var n3_detail := ""
	if battle.has_method("launch_close_combat"):
		n3_status = "PRESENTE"
		var close_a := _run_crecy_n3(battle)
		var close_b := _run_crecy_n3(battle)
		var n3_same := str(close_a.get("signature", "?a")) == str(close_b.get("signature", "?b"))
		n3_ok = bool(close_a["ok"]) and bool(close_b["ok"]) and n3_same
		n3_detail = str(close_a.get("detail", close_a.get("reason", ""))) + "; determinista=" + str(n3_same)

	# D-033: el resultado del Nivel 3 debe aplicarse a la campaña (idempotente).
	var campaign := _check_n3_campaign_apply(battle)
	var campaign_ok := bool(campaign["ok"])
	var campaign_detail := str(campaign.get("detail", campaign.get("reason", "")))

	var detail := "N1=%s (%s; determinista=%s); N2=%s (%s); N3=%s (%s); N3→campaña(D-033)=%s (%s)" % [
		"PASS" if n1_ok else "FAIL", n1_detail, str(n1_det),
		n2_status, n2_detail, n3_status, n3_detail, str(campaign_ok), campaign_detail,
	]
	if not n1_ok:
		_fail(id, name, "Nivel 1 incoherente: " + detail, started)
		return
	if not n1_det:
		_fail(id, name, "Nivel 1 no determinista con la misma semilla: " + detail, started)
		return
	if n2_status == "PRESENTE" and not n2_ok:
		_fail(id, name, "Nivel 2 presente pero incoherente: " + detail, started)
		return
	if n3_status == "PRESENTE" and not n3_ok:
		_fail(id, name, "Nivel 3 presente pero incoherente: " + detail, started)
		return
	if not campaign_ok:
		_fail(id, name, "N3 no aplica correctamente a campaña (D-033): " + detail, started)
		return
	if n2_ok and n3_ok:
		_pass(id, name, detail, started)
		return
	_skip(id, name, "N1 verificado; N2/N3 pendientes de AG-2/AG-3: " + detail, started)


func _check_n3_campaign_apply(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs == null:
		return {"ok": false, "reason": "GameState no montado"}
	if not battle.has_method("apply_close_combat_outcome"):
		return {"ok": false, "reason": "BattleManager.apply_close_combat_outcome ausente (D-033)"}
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		return {"ok": false, "reason": str(start["reason"])}
	var state := _state()
	var armies: Variant = state.get("armies", {})
	if not (armies is Dictionary):
		return {"ok": false, "reason": "state.armies no disponible"}
	var attacker_id := ""
	var defender_id := ""
	for army_id in (armies as Dictionary).keys():
		var army_value: Variant = (armies as Dictionary)[army_id]
		if not (army_value is Dictionary):
			continue
		var faction_id := str((army_value as Dictionary).get("faction_id", ""))
		if faction_id == "england" and attacker_id == "":
			attacker_id = str(army_id)
		elif faction_id == "france" and defender_id == "":
			defender_id = str(army_id)
	if attacker_id == "" or defender_id == "":
		return {"ok": false, "reason": "sin ejércitos Inglaterra/Francia en el escenario"}
	var attacker_state: Dictionary = gs.call("get_army_state", attacker_id)
	var defender_state: Dictionary = gs.call("get_army_state", defender_id)
	var region_id := str(defender_state.get("region_id", ""))
	if region_id == "":
		return {"ok": false, "reason": "ejército defensor sin región"}
	var attacker_unit := _unit_from_state_army(attacker_state, "england")
	var defender_unit := _unit_from_state_army(defender_state, "france")
	var node: Variant = battle.call("launch_close_combat", attacker_unit, defender_unit)
	if not (node is Node):
		return {"ok": false, "reason": "launch_close_combat no devuelve Node"}
	var duel := node as Node
	root.add_child(duel)
	if not duel.has_method("auto_resolve"):
		duel.free()
		return {"ok": false, "reason": "CloseCombat sin auto_resolve para la prueba D-033"}
	duel.call("auto_resolve")
	var outcome_value: Variant = duel.call("get_outcome")
	duel.free()
	if not (outcome_value is Dictionary) or (outcome_value as Dictionary).is_empty():
		return {"ok": false, "reason": "sin outcome de N3 para aplicar"}
	var outcome := outcome_value as Dictionary
	var applied_first: Variant = battle.call("apply_close_combat_outcome", attacker_id, defender_id, region_id, outcome)
	if not (applied_first is Dictionary) or (applied_first as Dictionary).is_empty():
		return {"ok": false, "reason": "apply_close_combat_outcome devuelve informe vacío"}
	var report := applied_first as Dictionary
	if str(report.get("region_id", "")) != region_id:
		return {"ok": false, "reason": "informe aplicado sin region_id correcto"}
	var hash_first := _hash(gs.call("to_dict"))
	var applied_second: Variant = battle.call("apply_close_combat_outcome", attacker_id, defender_id, region_id, outcome)
	var hash_second := _hash(gs.call("to_dict"))
	if not (applied_second is Dictionary) or (applied_second as Dictionary).is_empty():
		return {"ok": false, "reason": "segunda aplicación devuelve vacío (idempotencia rota)"}
	var idempotent := hash_first == hash_second
	if not idempotent:
		return {"ok": false, "reason": "aplicación N3 no idempotente (hash cambió)"}
	return {"ok": true, "detail": "informe=%d claves; region=%s; idempotente=%s; winner=%s" % [
		report.size(), region_id, str(idempotent), str(report.get("winner_faction", "")),
	]}


func _unit_from_state_army(army_state: Dictionary, faction_id: String) -> Dictionary:
	var units: Variant = army_state.get("units", [])
	var size := 0
	var unit_id := "militia_spearman"
	var strength := 4
	if units is Array and not (units as Array).is_empty() and (units as Array)[0] is Dictionary:
		var first := (units as Array)[0] as Dictionary
		size = int(first.get("size", 0))
		unit_id = str(first.get("unit_id", unit_id))
		strength = int(first.get("strength", strength))
	return {
		"id": "qa_apply_%s" % faction_id,
		"faction": faction_id,
		"unit_id": unit_id,
		"size": size,
		"strength": strength,
		"morale": 1.0,
		"experience": 50,
	}


func _run_crecy_n1(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs != null:
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 900, 12)
	var region: Variant = _make_region("region_normandia", "plains", 60, 60, false)
	if attacker == null or defender == null or region == null:
		return {}
	var report: Variant = battle.call("resolve_delegated", attacker, defender, region, 1)
	return _report_dict(report)


func _run_crecy_n2(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs != null:
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var attacker: Variant = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: Variant = _make_army("france", "region_normandia", "philippe_vi_de_valois", "men_at_arms", 900, 12)
	var region: Variant = _make_region("region_normandia", "plains", 60, 60, false)
	if attacker == null or defender == null or region == null:
		return {"ok": false, "reason": "modelos Army/RegionState no disponibles"}
	var node: Variant = battle.call("launch_tactical", attacker, defender, region)
	if node == null:
		return {"ok": false, "reason": "stub: launch_tactical devuelve null"}
	if not (node is Node):
		return {"ok": false, "reason": "launch_tactical no devuelve Node"}
	var api_check := _tactical_api_ok(node as Node)
	if not bool(api_check["ok"]):
		(node as Node).free()
		return {"ok": false, "reason": str(api_check["reason"])}
	var sim: Dictionary = _simulate_tactical(node as Node)
	return sim


func _tactical_api_ok(node: Node) -> Dictionary:
	var required: Array[String] = [
		"get_state", "get_hexes", "get_units", "select_unit", "move_unit", "attack_unit",
		"end_round", "resolve_duel", "get_objectives", "is_finished", "get_winner", "commit",
	]
	for method_name in required:
		if not node.has_method(method_name):
			return {"ok": false, "reason": "TacticalBattle sin método %s()" % method_name}
	return {"ok": true, "reason": ""}


func _simulate_tactical(node: Node) -> Dictionary:
	root.add_child(node)
	var side_map: Dictionary = _unit_side_map(node.call("get_units"))
	var start_men: Variant = node.get("_start_men")
	var auto_used := false
	if node.has_method("auto_resolve"):
		node.call("auto_resolve")
		auto_used = true
	var rounds := 0
	var actions := 0
	if not auto_used:
		while rounds < 80:
			var finished_now: Variant = node.call("is_finished")
			if finished_now is bool and bool(finished_now):
				break
			var units: Variant = node.call("get_units")
			if units is Array and not (units as Array).is_empty():
				var own_id := ""
				var enemy_id := ""
				var enemy_q := 0
				var enemy_r := 0
				for unit_value in (units as Array):
					if not (unit_value is Dictionary):
						continue
					var unit := unit_value as Dictionary
					if str(unit.get("faction", "")) == PLAYER_FACTION and own_id == "":
						own_id = str(unit.get("id", ""))
					elif str(unit.get("faction", "")) != PLAYER_FACTION and enemy_id == "":
						enemy_id = str(unit.get("id", ""))
						enemy_q = int(unit.get("q", 0))
						enemy_r = int(unit.get("r", 0))
				if own_id != "":
					node.call("select_unit", own_id)
					if enemy_id != "":
						var attack: Variant = node.call("attack_unit", own_id, enemy_id)
						if attack is Dictionary and not (attack as Dictionary).is_empty():
							actions += 1
						else:
							var moved: Variant = node.call("move_unit", own_id, enemy_q, enemy_r)
							if moved is bool and bool(moved):
								actions += 1
			node.call("end_round")
			rounds += 1
	var finished_final: Variant = node.call("is_finished")
	var finished_ok := finished_final is bool and bool(finished_final)
	var winner := str(node.call("get_winner"))
	var outcome_dict := _report_dict(node.call("commit"))
	var signature := JSON.stringify(outcome_dict)
	var expected_losses := _expected_tactical_losses(start_men, side_map, node.call("get_units"))
	node.free()
	if not finished_ok:
		return {"ok": false, "reason": "táctica no termina (auto=%s, rondas=%d, acciones=%d)" % [str(auto_used), rounds, actions]}
	if winner != "england" and winner != "france":
		return {"ok": false, "reason": "get_winner() inválido: '%s'" % winner}
	var coherence := _tactical_outcome_ok(outcome_dict, winner)
	if not bool(coherence["ok"]):
		return {"ok": false, "reason": "informe táctico incoherente: %s" % str(coherence.get("reason", ""))}
	if bool(expected_losses["ok"]):
		var expected_a := int(expected_losses["attacker_losses"])
		var expected_d := int(expected_losses["defender_losses"])
		var reported_a := int(outcome_dict.get("attacker_losses", -1))
		var reported_d := int(outcome_dict.get("defender_losses", -1))
		if expected_a != reported_a or expected_d != reported_d:
			return {"ok": false, "reason": "bajas N2 incoherentes: informe=%d/%d, esperado=%d/%d (start_men vs unidades finales)" % [
				reported_a, reported_d, expected_a, expected_d,
			]}
	return {"ok": true, "signature": signature, "detail": "auto=%s rondas=%d acciones=%d winner=%s bajas=%s/%s (esperado %s/%s)" % [
		str(auto_used), int(outcome_dict.get("rounds_played", rounds)), actions, winner,
		str(outcome_dict.get("attacker_losses", "?")), str(outcome_dict.get("defender_losses", "?")),
		str(expected_losses.get("attacker_losses", "?")), str(expected_losses.get("defender_losses", "?")),
	]}


func _unit_side_map(units: Variant) -> Dictionary:
	var side_map: Dictionary = {}
	if units is Array:
		for unit_value in (units as Array):
			if unit_value is Dictionary:
				var unit := unit_value as Dictionary
				side_map[str(unit.get("id", ""))] = str(unit.get("side", ""))
	return side_map


func _expected_tactical_losses(start_men: Variant, side_map: Dictionary, final_units: Variant) -> Dictionary:
	if not (start_men is Dictionary) or (start_men as Dictionary).is_empty() or side_map.is_empty():
		return {"ok": false}
	var start_by_side: Dictionary = {"attacker": 0, "defender": 0}
	for unit_id in (start_men as Dictionary).keys():
		var side := str(side_map.get(str(unit_id), ""))
		if start_by_side.has(side):
			start_by_side[side] = int(start_by_side[side]) + int((start_men as Dictionary)[unit_id])
	var current_by_side: Dictionary = {"attacker": 0, "defender": 0}
	if final_units is Array:
		for unit_value in (final_units as Array):
			if unit_value is Dictionary:
				var unit := unit_value as Dictionary
				var side := str(unit.get("side", ""))
				if current_by_side.has(side):
					current_by_side[side] = int(current_by_side[side]) + int(unit.get("size", 0))
	return {
		"ok": true,
		"attacker_losses": maxi(0, int(start_by_side["attacker"]) - int(current_by_side["attacker"])),
		"defender_losses": maxi(0, int(start_by_side["defender"]) - int(current_by_side["defender"])),
	}


func _tactical_outcome_ok(report: Dictionary, expected_winner: String) -> Dictionary:
	if report.is_empty():
		return {"ok": false, "reason": "commit() vacío"}
	var winner := str(report.get("winner_faction", ""))
	if winner != "england" and winner != "france":
		return {"ok": false, "reason": "winner_faction inválido '%s'" % winner}
	if expected_winner != "" and winner != expected_winner:
		return {"ok": false, "reason": "get_winner()=%s ≠ informe=%s" % [expected_winner, winner]}
	var attacker_losses: Variant = report.get("attacker_losses", null)
	var defender_losses: Variant = report.get("defender_losses", null)
	if attacker_losses == null or defender_losses == null:
		return {"ok": false, "reason": "sin campos de bajas"}
	var losses := int(attacker_losses) + int(defender_losses)
	if losses <= 0:
		return {"ok": false, "reason": "bajas totales 0 en una batalla resuelta"}
	if str(report.get("region_id", "")) == "":
		return {"ok": false, "reason": "informe sin region_id"}
	var rounds_played := int(report.get("rounds_played", 0))
	var rounds_array: Variant = report.get("rounds", [])
	if rounds_played < 1 and not (rounds_array is Array and not (rounds_array as Array).is_empty()):
		return {"ok": false, "reason": "informe sin rondas"}
	if bool(report.get("region_captured", false)) and winner != str(report.get("attacker_faction", "")):
		return {"ok": false, "reason": "region_captured=true pero no vence el atacante"}
	return {"ok": true, "reason": ""}


func _run_crecy_n3(battle: Node) -> Dictionary:
	var gs := _autoload("GameState")
	if gs != null:
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var attacker_unit: Dictionary = _make_unit_dict("england", "longbowman", 1200, 9)
	var defender_unit: Dictionary = _make_unit_dict("france", "men_at_arms", 900, 12)
	var node: Variant = battle.call("launch_close_combat", attacker_unit, defender_unit)
	if node == null:
		return {"ok": false, "reason": "stub: launch_close_combat devuelve null"}
	if not (node is Node):
		return {"ok": false, "reason": "launch_close_combat no devuelve Node"}
	var required: Array[String] = ["get_state", "play_order", "enemy_respond", "is_finished", "get_outcome"]
	for method_name in required:
		if not (node as Node).has_method(method_name):
			(node as Node).free()
			return {"ok": false, "reason": "CloseCombat sin método %s()" % method_name}
	root.add_child(node as Node)
	var start_state: Variant = (node as Node).call("get_state")
	var start_attacker := _combat_side_size(start_state, "attacker")
	var start_defender := _combat_side_size(start_state, "defender")
	var orders: Array[String] = ["carga", "disparo", "formacion", "finta", "retirada", "charge", "volley", "formation", "feint", "retreat"]
	var accepted := 0
	var rounds := 0
	if (node as Node).has_method("auto_resolve"):
		(node as Node).call("auto_resolve")
	else:
		var order_index := 0
		while rounds < 40:
			var finished_now: Variant = (node as Node).call("is_finished")
			if finished_now is bool and bool(finished_now):
				break
			var played := false
			for attempt in range(orders.size()):
				var order_id := orders[(order_index + attempt) % orders.size()]
				var played_result: Variant = (node as Node).call("play_order", order_id)
				if played_result is bool and bool(played_result):
					played = true
					accepted += 1
					order_index = (order_index + attempt + 1) % orders.size()
					break
			(node as Node).call("enemy_respond")
			rounds += 1
			if not played and rounds > 4:
				break
	var finished_final: Variant = (node as Node).call("is_finished")
	var finished_ok := finished_final is bool and bool(finished_final)
	var outcome_final: Variant = (node as Node).call("get_outcome")
	var outcome_dict: Dictionary = {}
	if outcome_final is Dictionary:
		outcome_dict = outcome_final as Dictionary
	var signature := JSON.stringify(outcome_dict)
	var end_state: Variant = (node as Node).call("get_state")
	var end_attacker := _combat_side_size(end_state, "attacker")
	var end_defender := _combat_side_size(end_state, "defender")
	(node as Node).free()
	if not finished_ok:
		return {"ok": false, "reason": "combate cerrado no termina (rondas=%d, órdenes=%d)" % [rounds, accepted]}
	var winner := str(outcome_dict.get("winner_faction", ""))
	if winner != "england" and winner != "france":
		return {"ok": false, "reason": "outcome sin winner_faction válido: %s" % str(outcome_dict)}
	var attacker_losses: Variant = outcome_dict.get("attacker_losses", null)
	var defender_losses: Variant = outcome_dict.get("defender_losses", null)
	if attacker_losses == null or defender_losses == null:
		return {"ok": false, "reason": "outcome sin bajas"}
	var expected_attacker_losses := maxi(0, start_attacker - end_attacker)
	var expected_defender_losses := maxi(0, start_defender - end_defender)
	if int(attacker_losses) != expected_attacker_losses or int(defender_losses) != expected_defender_losses:
		return {"ok": false, "reason": "bajas N3 incoherentes: informe=%d/%d, esperado=%d/%d" % [
			int(attacker_losses), int(defender_losses), expected_attacker_losses, expected_defender_losses,
		]}
	if int(attacker_losses) + int(defender_losses) <= 0:
		return {"ok": false, "reason": "outcome con bajas 0/0"}
	if int(outcome_dict.get("rounds", 0)) < 1:
		return {"ok": false, "reason": "outcome sin rondas"}
	return {"ok": true, "signature": signature, "detail": "rondas=%d órdenes=%d winner=%s bajas=%d/%d" % [
		int(outcome_dict.get("rounds", 0)), accepted, winner, int(attacker_losses), int(defender_losses),
	]}


func _combat_side_size(state_data: Variant, side_name: String) -> int:
	if not (state_data is Dictionary):
		return 0
	var side_value: Variant = (state_data as Dictionary).get(side_name, {})
	if side_value is Dictionary:
		return int((side_value as Dictionary).get("size", 0))
	return 0


func _make_unit_dict(faction_id: String, unit_id: String, size: int, strength: int) -> Dictionary:
	return {
		"id": "qa_%s_%s" % [faction_id, unit_id],
		"faction": faction_id,
		"unit_id": unit_id,
		"size": size,
		"strength": strength,
		"morale": 1.0,
		"experience": 50,
	}


func _outcome_ok(outcome: Dictionary, expected_winner: String) -> Dictionary:
	if outcome.is_empty():
		return {"ok": false, "reason": "outcome vacío"}
	var serialized := JSON.stringify(outcome)
	var winner := ""
	for key in ["winner", "winner_faction"]:
		if outcome.has(key) and outcome[key] is String:
			winner = str(outcome[key])
			break
	if winner == "":
		if serialized.contains("england"):
			winner = "england"
		elif serialized.contains("france"):
			winner = "france"
	if winner != "england" and winner != "france":
		return {"ok": false, "reason": "outcome sin ganador válido (%s)" % serialized.substr(0, 120)}
	if expected_winner != "" and winner != expected_winner:
		return {"ok": false, "reason": "ganador %s ≠ %s" % [winner, expected_winner]}
	var has_numeric := false
	for key in outcome.keys():
		var value: Variant = outcome[key]
		if value is int or value is float:
			has_numeric = true
			break
	if not has_numeric:
		return {"ok": false, "reason": "outcome sin métricas numéricas (bajas/daño)"}
	return {"ok": true, "detail": "winner=%s" % winner}


# ---------------------------------------------------------------------------
# F2-C2 — Extinción dinástica → game_over derrota inmediata
# ---------------------------------------------------------------------------

func _criterion_2_extinction() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C2"
	var name := "Extinción dinástica: gobernante + casa sin vivos → game_over derrota sin turnos fantasma"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return
	var dyn := _autoload("DynastySystem")
	var tm := _autoload("TurnManager")
	var gs := _autoload("GameState")
	if dyn == null or tm == null or gs == null:
		_skip(id, name, "DynastySystem/TurnManager/GameState no montados", started)
		return
	if not dyn.has_method("resolve_succession"):
		_skip(id, name, "DynastySystem.resolve_succession() no declarado", started)
		return

	_game_over_events.clear()
	_extinct_signals.clear()
	_succession_signals.clear()
	var state := _state()
	var factions: Variant = state.get("factions", {})
	var characters: Variant = state.get("characters", {})
	if not (factions is Dictionary) or not (characters is Dictionary):
		_skip(id, name, "state sin factions/characters (stub)", started)
		return
	var player_faction: Variant = (factions as Dictionary).get(PLAYER_FACTION, {})
	if not (player_faction is Dictionary):
		_skip(id, name, "state.factions.england ausente", started)
		return
	var faction_data := player_faction as Dictionary
	var ruler_id := str(faction_data.get("ruler_id", ""))
	var ruler: Variant = (characters as Dictionary).get(ruler_id, {})
	if ruler_id == "" or not (ruler is Dictionary):
		_skip(id, name, "sin gobernante en el estado inicial", started)
		return
	var ruler_house := str((ruler as Dictionary).get("house", ""))
	var year: int = int(state.get("year", 1337))
	# Fuerza la extinción: mata a todos los vivos de la facción jugable (gobernante,
	# herederos, casa y cualquier pariente con opción sucesoria). D-058 filtra vivos
	# por año; con la facción sin vivos no puede quedar línea sucesoria.
	var killed := 0
	for character_id in (characters as Dictionary).keys():
		var character: Variant = (characters as Dictionary)[character_id]
		if not (character is Dictionary):
			continue
		var c := character as Dictionary
		if str(c.get("faction", "")) != PLAYER_FACTION:
			continue
		# Incluye vivos actuales y nacimientos futuros (D-058): `died=year` los saca
		# también de la línea sucesoria futura, de modo que no quede ninguna rama viva.
		c["alive"] = false
		c["died"] = year
		killed += 1
	faction_data["heir_id"] = ""
	var result: Variant = dyn.call("resolve_succession", PLAYER_FACTION)
	var succession_dict: Dictionary = result if result is Dictionary else {}
	if tm.has_method("advance_quarter"):
		tm.call("advance_quarter")
	var state_after := _state()
	var game_over_flag := bool(state_after.get("game_over", false))
	var defeat_signal := false
	for event in _game_over_events:
		if not bool(event.get("victory", true)):
			defeat_signal = true
	var extinct_signal := _extinct_signals.has(PLAYER_FACTION)
	var extinct_flag := bool(succession_dict.get("extinct", false))
	var detail := "muertos=%d (casa=%s); resolve.extinct=%s; señal dynasty_extinct=%s; game_over=%s; señales game_over=%d; resultado=%s" % [
		killed, ruler_house, str(extinct_flag), str(extinct_signal), str(game_over_flag),
		_game_over_events.size(), str(succession_dict),
	]
	if game_over_flag or defeat_signal:
		if not extinct_signal:
			_fail(id, name, "game_over de derrota sin señal dynasty_extinct: " + detail, started)
			return
		# Sin turnos fantasma: con la partida terminada el reloj no debe avanzar.
		var year_before := int(_state().get("year", 0))
		var quarter_before := int(_state().get("quarter", 0))
		if tm.has_method("advance_quarter"):
			tm.call("advance_quarter")
		if tm.has_method("end_turn"):
			tm.call("end_turn")
		var year_after := int(_state().get("year", 0))
		var quarter_after := int(_state().get("quarter", 0))
		if year_after != year_before or quarter_after != quarter_before:
			_fail(id, name, "turnos fantasma tras game_over: %d·T%d → %d·T%d" % [
				year_before, quarter_before, year_after, quarter_after,
			], started)
			return
		_pass(id, name, detail + "; reloj congelado en %d·T%d" % [year_before, quarter_before], started)
		return
	if extinct_flag:
		_fail(id, name, "extinción marcada sin game_over de derrota: " + detail, started)
		return
	var f2_markers := 0
	for method_name in ["check_extinction", "_check_extinction", "is_dynasty_extinct", "trigger_extinction"]:
		if dyn.has_method(method_name):
			f2_markers += 1
	if f2_markers == 0:
		_skip(id, name, "extinción inmediata F2 aún no integrada (AG-2 task-12 en curso): " + detail, started)
		return
	_fail(id, name, "extinción F2 presente pero no declara derrota: " + detail, started)


# ---------------------------------------------------------------------------
# F2-C3 — §10.1 Mapa: datos + hit-test + benchmark + integración
# ---------------------------------------------------------------------------

func _criterion_3_map_10_1() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C3"
	var name := "§10.1 Mapa: 47/47 polígonos × 3 años, hit-test, ≤150 KB, CPU <8 ms/frame, terreno y captura"
	if not FileAccess.file_exists(MAP_BORDERS_PATH):
		var pending := "data/map_borders.json ausente (AG-1 task-11); terreno=%s; tactical=%s; comparativa=%s" % [
			str(FileAccess.file_exists("res://assets/art/map/terrain_base.png")),
			str(FileAccess.file_exists("res://scenes/battle/tactical_map.tscn")),
			str(FileAccess.file_exists("res://docs/screenshots/map_comparison.png")),
		]
		_skip(id, name, pending, started)
		return

	var bytes := _file_size(MAP_BORDERS_PATH)
	if bytes < 0:
		_fail(id, name, "no se puede leer data/map_borders.json", started)
		return
	if bytes > MAP_BORDERS_MAX_BYTES:
		_fail(id, name, "map_borders.json %d B > %d B (150 KB)" % [bytes, MAP_BORDERS_MAX_BYTES], started)
		return
	var borders_root: Variant = _read_json(MAP_BORDERS_PATH)
	if not (borders_root is Dictionary):
		_fail(id, name, "map_borders.json no es un objeto JSON válido", started)
		return
	var borders := borders_root as Dictionary
	var regions_root: Variant = _read_json("res://data/regions.json")
	var region_ids: Array[String] = []
	if regions_root is Dictionary and (regions_root as Dictionary).get("regions") is Array:
		for region_value in ((regions_root as Dictionary).get("regions") as Array):
			if region_value is Dictionary:
				region_ids.append(str((region_value as Dictionary).get("id", "")))
	var factions_root: Variant = _read_json("res://data/factions.json")
	var faction_ids: Array[String] = []
	if factions_root is Dictionary and (factions_root as Dictionary).get("factions") is Array:
		for faction_value in ((factions_root as Dictionary).get("factions") as Array):
			if faction_value is Dictionary:
				faction_ids.append(str((faction_value as Dictionary).get("id", "")))

	var years_value: Variant = borders.get("years", {})
	if not (years_value is Dictionary):
		_fail(id, name, "map_borders.json sin objeto 'years'", started)
		return
	var years_dict := years_value as Dictionary
	var data_issues: Array[String] = []
	if int(borders.get("schema_version", 0)) != 1:
		data_issues.append("schema_version != 1")
	var canvas_value: Variant = borders.get("canvas", {})
	if canvas_value is Dictionary:
		var canvas := canvas_value as Dictionary
		if int(canvas.get("width_px", 0)) != 4096 or int(canvas.get("height_px", 0)) != 3072:
			data_issues.append("canvas != 4096x3072 (%sx%s)" % [str(canvas.get("width_px")), str(canvas.get("height_px"))])
	else:
		data_issues.append("sin canvas")
	var year_entries_by_year: Dictionary = {}
	var total_points := 0
	var total_regions := 0
	for year_value in YEARS:
		var year_key := str(year_value)
		var entries: Variant = years_dict.get(year_key, null)
		if not (entries is Array):
			data_issues.append("año %s ausente o no es array" % year_key)
			continue
		var year_entries := entries as Array
		if year_entries.size() != REGION_COUNT:
			data_issues.append("año %s: %d regiones (esperadas %d)" % [year_key, year_entries.size(), REGION_COUNT])
		var seen_ids: Dictionary = {}
		var check_points := 0
		for entry_value in year_entries:
			if not (entry_value is Dictionary):
				data_issues.append("año %s: entrada no-diccionario" % year_key)
				continue
			var entry := entry_value as Dictionary
			var region_id := str(entry.get("region_id", ""))
			if region_id == "" or not region_ids.has(region_id):
				data_issues.append("año %s: region_id inválido '%s'" % [year_key, region_id])
			if seen_ids.has(region_id):
				data_issues.append("año %s: region_id duplicado '%s'" % [year_key, region_id])
			seen_ids[region_id] = true
			if str(entry.get("owner", "")) == "":
				data_issues.append("año %s/%s: owner vacío" % [year_key, region_id])
			if year_value == 1337 and not faction_ids.has(str(entry.get("owner", ""))):
				data_issues.append("año 1337/%s: owner '%s' no existe en factions.json" % [region_id, str(entry.get("owner", ""))])
			var has_source := entry.has("source") and str(entry.get("source", "")) != ""
			var is_estimate := entry.get("estimate") is bool and bool(entry.get("estimate"))
			if not has_source and not is_estimate:
				data_issues.append("año %s/%s: sin source ni estimate:true" % [year_key, region_id])
			var ring_value: Variant = entry.get("ring", null)
			if not (ring_value is Array):
				data_issues.append("año %s/%s: sin ring" % [year_key, region_id])
				continue
			var ring := ring_value as Array
			if ring.size() < 3 or ring.size() > 400:
				data_issues.append("año %s/%s: ring %d puntos (3..400)" % [year_key, region_id, ring.size()])
			check_points += ring.size()
			for point_value in ring:
				if not (point_value is Array) or (point_value as Array).size() < 2:
					data_issues.append("año %s/%s: punto inválido" % [year_key, region_id])
					continue
				var point := point_value as Array
				var px: Variant = point[0]
				var py: Variant = point[1]
				if not ((px is float or px is int) and (py is float or py is int)):
					data_issues.append("año %s/%s: coords no numéricas" % [year_key, region_id])
					continue
				if float(px) < 0.0 or float(px) > 1.0 or float(py) < 0.0 or float(py) > 1.0:
					data_issues.append("año %s/%s: coord fuera de [0,1]" % [year_key, region_id])
			if _ring_area(ring) <= 0.0000001:
				data_issues.append("año %s/%s: área ≤ 0" % [year_key, region_id])
			var center_value: Variant = entry.get("center", null)
			if not (center_value is Array) or (center_value as Array).size() < 2:
				data_issues.append("año %s/%s: center inválido" % [year_key, region_id])
			total_regions += 1
		year_entries_by_year[year_value] = year_entries
		total_points += check_points
		for region_id in region_ids:
			if not seen_ids.has(region_id):
				data_issues.append("año %s: región huérfana/faltante '%s'" % [year_key, region_id])
	var data_ok := data_issues.is_empty()

	# Hit-test punto-en-polígono (implementación propia; independiente de AG-3).
	var hit_failures: Array[String] = []
	var hit_checks := 0
	var synthetic_ok := _point_in_polygon(Vector2(0.5, 0.5), [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]]) \
		and not _point_in_polygon(Vector2(1.5, 0.5), [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]])
	if not synthetic_ok:
		hit_failures.append("hit-test sintético incorrecto (cuadrado)")
	for year_value in YEARS:
		var entries: Variant = year_entries_by_year.get(year_value, null)
		if not (entries is Array):
			continue
		for entry_value in (entries as Array):
			if not (entry_value is Dictionary):
				continue
			var entry := entry_value as Dictionary
			var ring: Array = entry.get("ring", [])
			if ring.size() < 3:
				continue
			var center: Array = entry.get("center", [])
			var test_point := _ring_centroid(ring)
			if center.size() >= 2:
				test_point = Vector2(float(center[0]), float(center[1]))
			if not _point_in_polygon(test_point, ring):
				test_point = _ring_centroid(ring)
			hit_checks += 1
			if not _point_in_polygon(test_point, ring):
				hit_failures.append("%s/%s" % [str(year_value), str(entry.get("region_id", ""))])
	var hit_ok := hit_failures.is_empty() and hit_checks > 0

	# Integración de AG-3: world_map consume map_borders y no map_layout (D-024).
	var world_map_text := _read_text("res://scripts/ui/map/world_map.gd")
	var integration_uses := world_map_text.contains("map_borders")
	var integration_legacy := world_map_text.contains("map_layout")
	var integration_ok := integration_uses and not integration_legacy

	# Terreno y captura comparativa (§10.1 / D-026 / D-028).
	var terrain_ok := FileAccess.file_exists("res://assets/art/map/terrain_base.png")
	var terrain_detail := "terrain_base.png presente"
	var terrain_dims := Vector2i(0, 0)
	if terrain_ok:
		terrain_dims = _png_dimensions("res://assets/art/map/terrain_base.png")
		var big_enough := terrain_dims.x >= 4096 and terrain_dims.y >= 3072
		terrain_detail = "%dx%d" % [terrain_dims.x, terrain_dims.y]
		terrain_ok = big_enough
	var comparison_ok := FileAccess.file_exists("res://docs/screenshots/map_comparison.png")

	# Benchmark CPU del controlador del mapa (§10.1 / contrato §2).
	var benchmark_result: Dictionary = await _benchmark_map_controller()
	var benchmark_ok := bool(benchmark_result["ok"])
	var detail := "bytes=%d; regiones=%d; puntos=%d; datos=%d incidencias; hit-test %d/%d OK (%d fallos); integración map_borders=%s/map_layout_ausente=%s; terreno=%s; comparativa=%s; benchmark=%s" % [
		bytes, total_regions, total_points, data_issues.size(), hit_checks - hit_failures.size(), hit_checks,
		hit_failures.size(), str(integration_uses), str(not integration_legacy), terrain_detail,
		str(comparison_ok), str(benchmark_result["detail"]),
	]
	if not data_issues.is_empty():
		_fail(id, name, "datos §10.1: %d incidencias (primeras: %s) :: %s" % [
			data_issues.size(), ", ".join(data_issues.slice(0, 5)), detail,
		], started)
		return
	if not hit_ok:
		_fail(id, name, "hit-test: %d/%d regiones sin punto interior propio: %s :: %s" % [
			hit_failures.size(), hit_checks, ", ".join(hit_failures.slice(0, 5)), detail,
		], started)
		return
	if not integration_ok:
		if not integration_uses:
			_skip(id, name, "datos/hit-test OK; AG-3 aún no integra map_borders en world_map.gd: " + detail, started)
		else:
			_fail(id, name, "world_map.gd aún usa map_layout (D-024 incompleto): " + detail, started)
		return
	if not terrain_ok or not comparison_ok or not benchmark_ok:
		_fail(id, name, "mapa integrado pero falta terreno/comparativa/benchmark: " + detail, started)
		return
	_pass(id, name, detail, started)


func _ring_area(ring: Array) -> float:
	if ring.size() < 3:
		return 0.0
	var area := 0.0
	for index in range(ring.size()):
		var a: Array = ring[index]
		var b: Array = ring[(index + 1) % ring.size()]
		if a.size() < 2 or b.size() < 2:
			return 0.0
		area += float(a[0]) * float(b[1]) - float(b[0]) * float(a[1])
	return absf(area) * 0.5


func _ring_centroid(ring: Array) -> Vector2:
	var sum := Vector2.ZERO
	if ring.is_empty():
		return sum
	for point_value in ring:
		if point_value is Array and (point_value as Array).size() >= 2:
			sum += Vector2(float((point_value as Array)[0]), float((point_value as Array)[1]))
	return sum / float(ring.size())


func _point_in_polygon(point: Vector2, ring: Array) -> bool:
	if ring.size() < 3:
		return false
	var inside := false
	var j := ring.size() - 1
	for i in range(ring.size()):
		var pi: Array = ring[i]
		var pj: Array = ring[j]
		if pi.size() < 2 or pj.size() < 2:
			j = i
			continue
		var xi := float(pi[0])
		var yi := float(pi[1])
		var xj := float(pj[0])
		var yj := float(pj[1])
		var intersects := ((yi > point.y) != (yj > point.y)) \
			and (point.x < (xj - xi) * (point.y - yi) / ((yj - yi) if absf(yj - yi) > 0.0000001 else 0.0000001) + xi)
		if intersects:
			inside = not inside
		j = i
	return inside


func _benchmark_map_controller() -> Dictionary:
	var packed: Variant = load("res://scenes/map/world_map.tscn")
	if not (packed is PackedScene):
		return {"ok": false, "detail": "world_map.tscn no carga"}
	if not bool(_ensure_game_started()["ok"]):
		return {"ok": false, "detail": "no hay partida para configurar el mapa"}
	var instance: Node = (packed as PackedScene).instantiate()
	if instance == null:
		return {"ok": false, "detail": "world_map no instancia"}
	root.add_child(instance)
	# En --script, _ready() se difiere al primer frame real; se espera antes de medir.
	await process_frame
	if not instance.has_method("_process"):
		instance.free()
		return {"ok": false, "detail": "controlador sin _process medible (limitación headless)"}
	if instance.get_child_count() == 0:
		instance.free()
		return {"ok": false, "detail": "world_map no construyó sus capas (_ready no ejecutado)"}
	var interactive := _find_node_with_method(instance, "hit_test")
	var borders := _find_node_with_method(instance, "get_center")
	if interactive == null or borders == null:
		instance.free()
		return {"ok": false, "detail": "mapa sin capa interactiva (hit_test/get_center)"}
	var region_ids: Array[String] = []
	var borders_root: Variant = _read_json(MAP_BORDERS_PATH)
	if borders_root is Dictionary:
		var years_value: Variant = (borders_root as Dictionary).get("years", {})
		if years_value is Dictionary:
			var entries: Variant = (years_value as Dictionary).get("1337", [])
			if entries is Array:
				for entry_value in (entries as Array):
					if entry_value is Dictionary:
						region_ids.append(str((entry_value as Dictionary).get("region_id", "")))
	var setter := ""
	for method_name in ["set_view_year", "set_map_year", "set_year", "show_year"]:
		if instance.has_method(method_name):
			setter = method_name
			break
	var total_us := 0
	var max_us := 0
	var hit_tests := 0
	var year_switches := 0
	for frame in range(MAP_BENCH_FRAMES):
		var t0 := Time.get_ticks_usec()
		if setter != "" and frame % 40 == 0:
			instance.call(setter, YEARS[(frame / 40) % YEARS.size()])
			year_switches += 1
		if not region_ids.is_empty():
			var region_id := region_ids[frame % region_ids.size()]
			var center: Variant = borders.call("get_center", region_id)
			if center is Vector2:
				interactive.call("hit_test", center)
				hit_tests += 1
		instance.call("_process", 1.0 / 60.0)
		if instance is CanvasItem:
			(instance as CanvasItem).queue_redraw()
		var elapsed: int = int(Time.get_ticks_usec() - t0)
		total_us += elapsed
		if elapsed > max_us:
			max_us = elapsed
	var avg_ms := float(total_us) / float(MAP_BENCH_FRAMES) / 1000.0
	var max_ms := float(max_us) / 1000.0
	# Hover/click correcto en las 3 vistas usando la implementación real del mapa.
	var layer_hits := 0
	var layer_tests := 0
	for year_value in YEARS:
		if setter != "":
			instance.call(setter, year_value)
		for region_id in region_ids:
			var center_for_year: Variant = borders.call("get_center", region_id)
			if not (center_for_year is Vector2):
				continue
			var hit_id := str(interactive.call("hit_test", center_for_year))
			layer_tests += 1
			if hit_id == region_id:
				layer_hits += 1
	var ok := avg_ms < MAP_FRAME_BUDGET_MS and hit_tests > 0 and layer_tests > 0 and layer_hits == layer_tests
	var detail := "%d frames; hit-tests benchmark=%d; cambios de vista=%d; media=%.3f ms; máx=%.3f ms; presupuesto=%.1f ms; hit-test 3 vistas AG-3=%d/%d (nota: CPU _process+hit-test+redraw; GPU no medible en headless)" % [
		MAP_BENCH_FRAMES, hit_tests, year_switches, avg_ms, max_ms, MAP_FRAME_BUDGET_MS,
		layer_hits, layer_tests,
	]
	instance.free()
	if not ok:
		return {"ok": false, "detail": detail}
	return {"ok": true, "detail": detail}


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


# ---------------------------------------------------------------------------
# F2-C4 — §10.2 Retratos: fallback + 5 slots + sucesión + capturas
# ---------------------------------------------------------------------------

func _criterion_4_portraits_10_2() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C4"
	var name := "§10.2 Retratos v1.5: 14/14 con textura en 5 slots, fallback heráldico y sucesión"
	var widget_exists := FileAccess.file_exists(PORTRAIT_SCRIPT)
	var schema_root: Variant = _read_json("res://data/schema/characters.schema.json")
	var schema_has_portrait := _schema_has_portrait(schema_root)
	if not widget_exists or not schema_has_portrait:
		_skip(id, name, "retratos aún no integrados (widget o schema 'portrait' ausente)", started)
		return

	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_skip(id, name, str(start["reason"]), started)
		return

	var data := _portrait_data_check()
	var widget := _portrait_widget_check(data)
	var slots := await _check_five_slots_textured()
	var succession := await _test_portrait_succession_v15()
	var captures := _portrait_captures_check()
	var detail := "datos=%s (%s); widget=%s (%s); slots=%s (%s); sucesión=%s (%s); capturas=%s (%s)" % [
		str(data["ok"]), str(data["detail"]), str(widget["ok"]), str(widget["detail"]),
		str(slots["ok"]), str(slots["detail"]), str(succession["ok"]), str(succession["detail"]),
		str(captures["ok"]), str(captures["detail"]),
	]
	if not bool(data["ok"]):
		_fail(id, name, "datos v1.5 de retratos incompletos: " + detail, started)
		return
	if not bool(widget["ok"]):
		_fail(id, name, "widget de retrato no renderiza textura/fallback según v1.5: " + detail, started)
		return
	if not bool(slots["ok"]):
		_fail(id, name, "los 5 slots no renderizan retrato con textura: " + detail, started)
		return
	if not bool(succession["ok"]):
		_fail(id, name, "la sucesión no actualiza correctamente el retrato (textura→heredero): " + detail, started)
		return
	if not bool(captures["ok"]):
		_fail(id, name, "faltan capturas v1.5 requeridas (o no son 1920×1080): " + detail, started)
		return
	_pass(id, name, detail, started)


func _character_map() -> Dictionary:
	var out: Dictionary = {}
	var characters_root: Variant = _read_json("res://data/characters.json")
	if characters_root is Dictionary and (characters_root as Dictionary).get("characters") is Array:
		for character_value in ((characters_root as Dictionary).get("characters") as Array):
			if character_value is Dictionary:
				var character := character_value as Dictionary
				out[str(character.get("id", ""))] = character
	return out


func _portrait_data_check() -> Dictionary:
	var characters := _character_map()
	var ruler_ids: Array[String] = []
	var fallback_id := ""
	var used: Dictionary = {}
	var issues: Array[String] = []
	var new_rulers := 0
	for ruler_id in ORIGINAL_1337_RULERS:
		var character: Dictionary = characters.get(ruler_id, {})
		if character.is_empty():
			issues.append("falta gobernante 1337 %s" % ruler_id)
			continue
		ruler_ids.append(ruler_id)
		var portrait := str(character.get("portrait", "")).strip_edges()
		if portrait == "":
			issues.append("%s sin portrait" % ruler_id)
		elif not portrait.begins_with("res://"):
			issues.append("%s portrait no-res://" % ruler_id)
		elif not FileAccess.file_exists(portrait):
			issues.append("%s archivo ausente" % ruler_id)
		else:
			var dims := _png_dimensions(portrait)
			if dims != Vector2i(256, 256):
				issues.append("%s PNG %dx%d" % [ruler_id, dims.x, dims.y])
		used[portrait] = true
	for character_id in characters.keys():
		var character: Dictionary = characters[character_id]
		if str(character.get("role", "")) != "ruler":
			continue
		if ORIGINAL_1337_RULERS.has(str(character_id)):
			continue
		new_rulers += 1
		if fallback_id == "" and str(character.get("portrait", "")).strip_edges() == "":
			fallback_id = str(character_id)
	if fallback_id == "":
		for character_id in characters.keys():
			var character: Dictionary = characters[character_id]
			if not ORIGINAL_1337_RULERS.has(str(character_id)) and str(character.get("portrait", "")).strip_edges() == "":
				fallback_id = str(character_id)
				break
	if ruler_ids.size() != ORIGINAL_1337_RULERS.size():
		issues.append("gobernantes 1337 con ficha: %d/%d" % [ruler_ids.size(), ORIGINAL_1337_RULERS.size()])
	if used.size() != ORIGINAL_1337_RULERS.size():
		issues.append("retratos únicos 1337: %d/%d" % [used.size(), ORIGINAL_1337_RULERS.size()])
	if fallback_id == "":
		issues.append("sin personaje nuevo para probar fallback")
	ruler_ids.sort()
	var detail := "gobernantes 1337 con retrato=%d/%d; PNG 256x256=%d/%d; únicos=%d; gobernantes nuevos=%d con fallback (%s); incidencias=%s" % [
		ruler_ids.size(), ORIGINAL_1337_RULERS.size(), ruler_ids.size() - issues.size(), ORIGINAL_1337_RULERS.size(),
		used.size(), new_rulers, fallback_id,
		"ninguna" if issues.is_empty() else ", ".join(issues.slice(0, 5)),
	]
	return {
		"ok": issues.is_empty(),
		"detail": detail,
		"ruler_ids": ruler_ids,
		"fallback_id": fallback_id,
	}


func _portrait_widget_check(data: Dictionary) -> Dictionary:
	var ruler_ids: Array = data.get("ruler_ids", [])
	var fallback_id := str(data.get("fallback_id", ""))
	var script: Variant = load(PORTRAIT_SCRIPT)
	if not (script is GDScript) or not (script as GDScript).can_instantiate():
		return {"ok": false, "detail": "portrait_frame.gd no instanciable"}
	var widget: Variant = (script as GDScript).new()
	if not (widget is Node):
		return {"ok": false, "detail": "portrait_frame.gd no es Node"}
	var node := widget as Node
	root.add_child(node)
	if not (node.has_method("get_portrait_character_id") and node.has_method("is_fallback") and node.has_method("setup")):
		node.free()
		return {"ok": false, "detail": "widget sin API get_portrait_character_id/is_fallback/setup"}
	var textured := 0
	var failures: Array[String] = []
	for ruler_value in ruler_ids:
		var ruler_id := str(ruler_value)
		node.call("setup", ruler_id)
		var got_id := str(node.call("get_portrait_character_id"))
		var is_fb := bool(node.call("is_fallback"))
		if got_id == ruler_id and not is_fb:
			textured += 1
		else:
			failures.append("%s(id=%s,fallback=%s)" % [ruler_id, got_id, str(is_fb)])
	node.call("setup", fallback_id)
	var fallback_got := str(node.call("get_portrait_character_id"))
	var fallback_is_fb := bool(node.call("is_fallback"))
	var fallback_ok := fallback_got == fallback_id and fallback_is_fb and fallback_got != ""
	node.free()
	var ok := textured == ruler_ids.size() and ruler_ids.size() == 14 and fallback_ok
	var detail := "texturizados=%d/%d; fallback %s: id=%s is_fallback=%s; fallos=%s" % [
		textured, ruler_ids.size(), fallback_id, fallback_got, str(fallback_is_fb),
		"ninguno" if failures.is_empty() else ", ".join(failures.slice(0, 5)),
	]
	return {"ok": ok, "detail": detail}


func _collect_descendants_with_method(node: Node, method_name: String, out: Array[Node]) -> void:
	for child in node.get_children():
		if child.has_method(method_name):
			out.append(child)
		_collect_descendants_with_method(child, method_name, out)


func _scene_portrait_texture(scene_path: String, configure_method: String, configure_args: Array) -> Dictionary:
	var packed: Variant = load(scene_path)
	if not (packed is PackedScene):
		return {"ok": false, "detail": "%s no carga" % scene_path.get_file()}
	var instance: Node = (packed as PackedScene).instantiate()
	if instance == null:
		return {"ok": false, "detail": "%s no instancia" % scene_path.get_file()}
	root.add_child(instance)
	await process_frame
	if configure_method != "" and instance.has_method(configure_method):
		instance.callv(configure_method, configure_args)
	await process_frame
	var nodes: Array[Node] = []
	_collect_descendants_with_method(instance, "get_portrait_character_id", nodes)
	var textured := 0
	var fallbacks := 0
	var ids: Array[String] = []
	for portrait_node in nodes:
		var portrait_id := str(portrait_node.call("get_portrait_character_id"))
		if portrait_id == "":
			continue
		ids.append(portrait_id)
		if bool(portrait_node.call("is_fallback")):
			fallbacks += 1
		else:
			textured += 1
	instance.free()
	var detail := "%d nodos: texturizados=%d, fallback=%d; ids=%s" % [
		nodes.size(), textured, fallbacks, ", ".join(ids.slice(0, 4)),
	]
	return {"ok": textured > 0, "detail": detail}


func _check_five_slots_textured() -> Dictionary:
	var results: Array[Dictionary] = []
	results.append(await _scene_portrait_texture("res://scenes/map/world_map.tscn", "", []))
	results.append(await _scene_portrait_texture("res://scenes/family/family_tree.tscn", "setup", [PLAYER_FACTION]))
	results.append(await _scene_portrait_texture("res://scenes/diplomacy/diplomacy_screen.tscn", "refresh", []))
	results.append(await _scene_portrait_texture("res://scenes/battle/battle_report.tscn", "setup", [_sample_battle_report()]))
	results.append(await _scene_portrait_texture("res://scenes/ui/court_overview.tscn", "refresh", []))
	var ok_count := 0
	var parts: Array[String] = []
	var labels: Array[String] = ["mapa", "árbol", "diplomacia", "batalla", "corte"]
	for index in range(results.size()):
		if bool(results[index]["ok"]):
			ok_count += 1
		parts.append("%s[%s]" % [labels[index], str(results[index]["detail"])])
	var detail := "%d/5 slots con textura: %s" % [ok_count, " | ".join(parts)]
	return {"ok": ok_count == 5, "detail": detail}


func _sample_battle_report() -> Dictionary:
	return {
		"attacker_faction": "england",
		"defender_faction": "france",
		"region_id": "region_normandia",
		"winner_faction": "england",
		"attacker_losses": 100,
		"defender_losses": 200,
		"rounds": [],
		"rounds_played": 1,
	}


func _portrait_captures_check() -> Dictionary:
	var required: Array[String] = [
		"res://docs/screenshots/map_portrait.png",
		"res://docs/screenshots/map_comparison.png",
		"res://docs/screenshots/portraits_contact_sheet_final.png",
		"res://docs/screenshots/succession_portrait.png",
	]
	var missing: Array[String] = []
	var wrong_size: Array[String] = []
	for path in required:
		if not FileAccess.file_exists(path):
			missing.append(path.get_file())
			continue
		var dims := _png_dimensions(path)
		if dims != Vector2i(1920, 1080):
			wrong_size.append("%s=%dx%d" % [path.get_file(), dims.x, dims.y])
	var ok := missing.is_empty() and wrong_size.is_empty()
	return {
		"ok": ok,
		"detail": "presentes=%d/%d; faltan=%s; tamaño≠1920x1080=%s" % [
			required.size() - missing.size(), required.size(),
			"ninguna" if missing.is_empty() else ", ".join(missing),
			"ninguna" if wrong_size.is_empty() else ", ".join(wrong_size),
		],
	}


func _schema_has_portrait(schema_root: Variant) -> bool:
	if not (schema_root is Dictionary):
		return false
	var schema := schema_root as Dictionary
	var properties: Variant = schema.get("properties", {})
	if not (properties is Dictionary):
		return false
	var characters: Variant = (properties as Dictionary).get("characters", {})
	if not (characters is Dictionary):
		return false
	var items: Variant = (characters as Dictionary).get("items", {})
	if not (items is Dictionary):
		return false
	var item_props: Variant = (items as Dictionary).get("properties", {})
	return item_props is Dictionary and (item_props as Dictionary).has("portrait")


func _test_portrait_succession_v15() -> Dictionary:
	var gs := _autoload("GameState")
	var dyn := _autoload("DynastySystem")
	if gs == null or dyn == null or not dyn.has_method("get_ruler") or not dyn.has_method("get_heir"):
		return {"ok": false, "detail": "sin API de dinastía"}
	var packed: Variant = load("res://scenes/map/world_map.tscn")
	if not (packed is PackedScene):
		return {"ok": false, "detail": "world_map.tscn no carga"}
	var map_node: Node = (packed as PackedScene).instantiate()
	if map_node == null:
		return {"ok": false, "detail": "world_map no instancia"}
	root.add_child(map_node)
	await process_frame
	if map_node.get_child_count() == 0:
		map_node.free()
		return {"ok": false, "detail": "world_map no construyó sus capas"}
	var ruler: Dictionary = dyn.call("get_ruler", PLAYER_FACTION)
	var heir: Dictionary = dyn.call("get_heir", PLAYER_FACTION)
	var ruler_id := str(ruler.get("id", ""))
	var heir_id := str(heir.get("id", ""))
	if ruler_id == "" or heir_id == "":
		map_node.free()
		return {"ok": false, "detail": "sin gobernante/heredero inicial"}
	var characters := _character_map()
	var ruler_char: Dictionary = characters.get(ruler_id, {})
	var heir_char: Dictionary = characters.get(heir_id, {})
	var ruler_has_texture := _has_texture_portrait(ruler_char)
	var heir_has_texture := _has_texture_portrait(heir_char)
	var before_node := _find_descendant_portrait_by_id(map_node, ruler_id)
	if before_node == null:
		map_node.free()
		return {"ok": false, "detail": "no hay slot de retrato con el gobernante en el mapa"}
	var before_fallback := bool(before_node.call("is_fallback"))
	# Fuerza la muerte del gobernante (el heredero sigue vivo) y resuelve sucesión.
	var state := _state()
	var state_characters: Variant = state.get("characters", {})
	if state_characters is Dictionary and (state_characters as Dictionary).has(ruler_id):
		var character_value: Variant = (state_characters as Dictionary)[ruler_id]
		if character_value is Dictionary:
			(character_value as Dictionary)["alive"] = false
			(character_value as Dictionary)["died"] = int(state.get("year", 1337))
	dyn.call("resolve_succession", PLAYER_FACTION)
	if _autoload("TurnManager") != null and _autoload("TurnManager").has_method("advance_quarter"):
		_autoload("TurnManager").call("advance_quarter")
	await process_frame
	for method_name in ["refresh", "refresh_all", "_refresh_all", "refresh_portrait", "_refresh_sovereign", "update_portrait"]:
		if map_node.has_method(method_name):
			map_node.call(method_name)
			break
	await process_frame
	var after_node := _find_descendant_portrait_by_id(map_node, heir_id)
	if after_node == null:
		map_node.free()
		return {"ok": false, "detail": "tras la sucesión no hay slot con el heredero %s" % heir_id}
	var after_fallback := bool(after_node.call("is_fallback"))
	var expected_fallback := not heir_has_texture
	var ok := before_fallback == (not ruler_has_texture) and after_fallback == expected_fallback
	var detail := "gobernante %s(textura=%s) → heredero %s(textura=%s, fallback=%s; esperado fallback=%s)" % [
		ruler_id, str(ruler_has_texture), heir_id, str(heir_has_texture),
		str(after_fallback), str(expected_fallback),
	]
	map_node.free()
	return {"ok": ok, "detail": detail}


func _has_texture_portrait(character: Dictionary) -> bool:
	var portrait := str(character.get("portrait", "")).strip_edges()
	return portrait != "" and FileAccess.file_exists(portrait)


func _find_descendant_portrait_by_id(node: Node, character_id: String) -> Node:
	if node.has_method("get_portrait_character_id"):
		if str(node.call("get_portrait_character_id")) == character_id:
			return node
	for child in node.get_children():
		var found := _find_descendant_portrait_by_id(child, character_id)
		if found != null:
			return found
	return null


func _find_descendant_with_method(node: Node, method_name: String) -> Node:
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
		if found != null:
			return found
	return null


func _find_node_with_method(node: Node, method_name: String) -> Node:
	if node.has_method(method_name):
		return node
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
		if found != null:
			return found
	return null


# ---------------------------------------------------------------------------
# F2-C5 — Smoke de todas las escenas (nuevas + 16 previas)
# ---------------------------------------------------------------------------

func _criterion_5_scene_smoke() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C5"
	var name := "Smoke UI: todas las escenas (tactical_map/close_combat + 16 previas) instanciables headless"
	var scenes: Array[String] = []
	_scan_scenes("res://scenes", scenes)
	if scenes.is_empty():
		_skip(id, name, "scenes/** sin .tscn", started)
		return
	var failures: Array[String] = []
	var script_failures: Array[String] = []
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
		script_failures.append_array(_scene_script_failures(scene_path))
	# Scripts críticos de Fase 2 que pueden fallar sin romper el .tscn (dependencias).
	if FileAccess.file_exists(PORTRAIT_SCRIPT):
		var portrait_script: Variant = load(PORTRAIT_SCRIPT)
		if portrait_script == null or (portrait_script is GDScript and not (portrait_script as GDScript).can_instantiate()):
			script_failures.append("portrait_frame.gd (no compila)")
	_scan_script_compile_failures("res://scripts/battle", script_failures)
	var missing_f2: Array[String] = []
	for scene_path in F2_SCENES:
		if not FileAccess.file_exists(scene_path):
			missing_f2.append(scene_path.get_file())
	var previous_ok := scenes.size() >= F1_MIN_SCENES
	var detail := "%d/%d escenas instanciadas; total=%d (mín. F1=%d); scripts que no compilan=%d; faltan F2: %s" % [
		ok, scenes.size(), scenes.size(), F1_MIN_SCENES, script_failures.size(),
		"ninguna" if missing_f2.is_empty() else ", ".join(missing_f2),
	]
	if not failures.is_empty():
		_fail(id, name, "%d fallos: %s; %s" % [failures.size(), "; ".join(failures.slice(0, 5)), detail], started)
		return
	if not previous_ok:
		_fail(id, name, "regresión: menos de %d escenas previas; %s" % [F1_MIN_SCENES, detail], started)
		return
	if not script_failures.is_empty():
		var f2_in_progress := not missing_f2.is_empty() or not FileAccess.file_exists(MAP_BORDERS_PATH) \
			or not FileAccess.file_exists(PORTRAIT_SCRIPT)
		if f2_in_progress:
			_skip(id, name, "escenas instancian pero scripts en edición (AG-2/AG-3): %s; %s" % [
				", ".join(script_failures.slice(0, 5)), detail,
			], started)
			return
		_fail(id, name, "escenas con scripts que no compilan: %s; %s" % [
			", ".join(script_failures.slice(0, 5)), detail,
		], started)
		return
	if not missing_f2.is_empty():
		_skip(id, name, "escenas previas OK; AG-3 aún no crea: " + detail, started)
		return
	_pass(id, name, detail, started)


func _scan_script_compile_failures(path: String, out: Array[String]) -> void:
	var files: Array[String] = []
	_scan_files(path, files, ".gd")
	for file_path in files:
		if file_path.contains("/dev/"):
			continue
		var script: Variant = load(file_path)
		if script == null:
			out.append(file_path.get_file())
		elif script is GDScript and not (script as GDScript).can_instantiate():
			out.append(file_path.get_file() + " (no compila)")


func _scene_script_failures(scene_path: String) -> Array[String]:
	var failures: Array[String] = []
	var text := _read_text(scene_path)
	if text == "":
		return failures
	var regex := RegEx.new()
	if regex.compile("res://[A-Za-z0-9_./-]+\\.gd") != OK:
		return failures
	var seen: Dictionary = {}
	for match_result in regex.search_all(text):
		var script_path := match_result.get_string()
		if seen.has(script_path):
			continue
		seen[script_path] = true
		var script: Variant = load(script_path)
		if script == null:
			failures.append(script_path.get_file())
		elif script is GDScript and not (script as GDScript).can_instantiate():
			failures.append(script_path.get_file() + " (no compila)")
	return failures


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
# F2-C6 — No regresión Fase 1 (embebida)
# ---------------------------------------------------------------------------

func _criterion_6_no_regression() -> void:
	var started := Time.get_ticks_msec()
	var id := "F2-C6"
	var name := "No regresión Fase 1: save/load, Peste Negra 1348, determinismo, UI sin mutaciones y escenas"
	var start := _ensure_game_started()
	if not bool(start["ok"]):
		_fail(id, name, "GameState/sistemas Fase 1 no funcionan: " + str(start["reason"]), started)
		return
	var gs := _autoload("GameState")
	var tm := _autoload("TurnManager")
	if gs == null or tm == null:
		_fail(id, name, "GameState/TurnManager ausentes (regresión Fase 1)", started)
		return

	# 1) Save/load exacto con roundtrip real (perturbación + load).
	var save_check := _check_save_load(gs, tm)
	if not bool(save_check["ok"]):
		_fail(id, name, "save/load: " + str(save_check["detail"]), started)
		return

	# 2) Peste Negra 1348 en event_log/fired_events.
	var plague_check := _check_plague_1348(gs, tm)
	if not bool(plague_check["ok"]):
		_fail(id, name, "Peste Negra 1348: " + str(plague_check["detail"]), started)
		return

	# 3) Determinismo: misma semilla → mismo estado inicial.
	var det_ok := true
	var det_detail := ""
	if gs.has_method("reset") and tm.has_method("advance_quarter"):
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
		var hash_a := _hash(gs.call("to_dict"))
		gs.call("reset")
		gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
		var hash_b := _hash(gs.call("to_dict"))
		det_ok = hash_a == hash_b
		det_detail = "hash %s vs %s" % [hash_a.substr(0, 16), hash_b.substr(0, 16)]
	else:
		det_ok = false
		det_detail = "sin reset/new_game"

	# 4) UI sin mutaciones de estado (auditoría estática).
	var ui_check := _check_ui_mutations()
	# 5) Escenas previas suficientes (el detalle lo aporta C5).
	var scenes: Array[String] = []
	_scan_scenes("res://scenes", scenes)
	var scenes_ok := scenes.size() >= F1_MIN_SCENES
	var detail := "save/load=%s; peste=%s; determinismo=%s (%s); UI sin mutaciones=%s (%d hallazgos); escenas=%d (mín %d)" % [
		str(save_check["detail"]), str(plague_check["detail"]), str(det_ok), det_detail,
		str(ui_check["ok"]), int(ui_check["hits"]), scenes.size(), F1_MIN_SCENES,
	]
	if not det_ok:
		_fail(id, name, "determinismo roto: " + detail, started)
		return
	if not bool(ui_check["ok"]):
		_fail(id, name, "UI muta estado: " + detail, started)
		return
	if not scenes_ok:
		_fail(id, name, "escenas de Fase 1 ausentes: " + detail, started)
		return
	_pass(id, name, detail, started)


func _check_save_load(gs: Node, tm: Node) -> Dictionary:
	if not gs.has_method("save_game") or not gs.has_method("load_game") or not gs.has_method("to_dict"):
		return {"ok": false, "detail": "GameState sin save/load/to_dict"}
	gs.call("reset")
	gs.call("new_game", SCENARIO_ID, PLAYER_FACTION, SEED)
	var before: Variant = gs.call("to_dict")
	if not (before is Dictionary) or (before as Dictionary).is_empty():
		return {"ok": false, "detail": "to_dict vacío"}
	var hash_before := _hash(before)
	var save_ok: Variant = gs.call("save_game", SAVE_SLOT)
	if not (save_ok is bool) or not bool(save_ok):
		return {"ok": false, "detail": "save_game()=false"}
	var save_path := "user://saves/%s.json" % SAVE_SLOT
	var save_size := _file_size(save_path)
	if save_size <= 0:
		return {"ok": false, "detail": "save en disco vacío"}
	if tm.has_method("advance_quarter"):
		tm.call("advance_quarter")
	var load_ok: Variant = gs.call("load_game", SAVE_SLOT)
	if not (load_ok is bool) or not bool(load_ok):
		_cleanup_save()
		return {"ok": false, "detail": "load_game()=false"}
	var after: Variant = gs.call("to_dict")
	var hash_equal := hash_before == _hash(after)
	_cleanup_save()
	return {"ok": hash_equal, "detail": "hash=%s; save=%d B; restaurado=%s" % [
		hash_before.substr(0, 16), save_size, str(hash_equal),
	]}


func _check_plague_1348(gs: Node, tm: Node) -> Dictionary:
	if not tm.has_method("advance_quarter"):
		return {"ok": false, "detail": "TurnManager sin advance_quarter"}
	var state := _state()
	var year := int(state.get("year", 1337))
	var last_turn := int(state.get("turn", 0))
	var guard := 0
	while year < 1348 and guard < 80:
		tm.call("advance_quarter")
		guard += 1
		state = _state()
		var new_year := int(state.get("year", year))
		var new_turn := int(state.get("turn", last_turn))
		if new_year == year and new_turn == last_turn:
			break
		year = new_year
		last_turn = new_turn
	if year < 1348 and tm.has_method("advance_year"):
		for _i in range(20):
			if year >= 1348:
				break
			var year_before := year
			tm.call("advance_year")
			state = _state()
			year = int(state.get("year", year_before))
			if year == year_before:
				break
	if year < 1348:
		return {"ok": false, "detail": "no se alcanzó 1348 (año=%d tras %d pasos)" % [year, guard]}
	var found := false
	var event_log: Variant = state.get("event_log", [])
	if event_log is Array:
		for entry in (event_log as Array):
			if entry is Dictionary:
				var event_id := str((entry as Dictionary).get("event_id", (entry as Dictionary).get("id", "")))
				if event_id == "peste_negra_1348":
					found = true
					break
			elif entry is String and str(entry).contains("peste_negra_1348"):
				found = true
				break
	var fired: Variant = state.get("fired_events", [])
	var in_fired := fired is Array and (fired as Array).has("peste_negra_1348")
	return {"ok": found and in_fired, "detail": "año=%d; event_log=%s; fired=%s" % [year, str(found), str(in_fired)]}


func _check_ui_mutations() -> Dictionary:
	var patterns: Array[String] = [
		"(GameState|DataLoader|TurnManager|EconomySystem|DynastySystem|DiplomacySystem|MilitarySystem|BattleManager|AIManager)\\.[A-Za-z_]+\\s*=(?!=)",
		"(GameState\\.state|DataLoader\\.(factions|regions|characters|units|scenarios|events))(\\[[^\\]]*\\])?\\s*=(?!=)",
		"(?<![A-Za-z_])state\\s*\\[[^\\]]+\\]\\s*=(?!=)",
	]
	var regexes: Array[RegEx] = []
	for pattern in patterns:
		var regex := RegEx.new()
		if regex.compile(pattern) == OK:
			regexes.append(regex)
	var files: Array[String] = []
	_scan_files("res://scripts/ui", files, ".gd")
	var hits := 0
	var examples: Array[String] = []
	for file_path in files:
		if file_path.contains("/dev/"):
			continue
		var text := _read_text(file_path)
		var lines := text.split("\n")
		for line_index in range(lines.size()):
			var line := lines[line_index]
			var trimmed := line.strip_edges()
			if trimmed.begins_with("#"):
				continue
			for regex in regexes:
				if regex.search(line) != null:
					hits += 1
					if examples.size() < 5:
						examples.append("%s:%d" % [file_path.get_file(), line_index + 1])
					break
	return {"ok": hits == 0, "hits": hits, "detail": ", ".join(examples)}


func _scan_files(path: String, out: Array[String], suffix: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path := path.path_join(entry)
			if dir.current_is_dir():
				_scan_files(full_path, out, suffix)
			elif entry.ends_with(suffix):
				out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _cleanup_save() -> void:
	var dir := DirAccess.open("user://saves")
	if dir != null:
		dir.remove(SAVE_SLOT + ".json")


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
	print("RESULTADO QA ACEPTACIÓN FASE 2: %d PASS, %d FAIL, %d SKIP (de %d criterios)" % [
		passed, failed, skipped, results.size(),
	])
	for result in results:
		print("  %s: [%s] %s (%d ms)" % [
			str(result["id"]), str(result["status"]), str(result["name"]), int(result["ms"]),
		])
	print("--------------------------------------------------------------")
	if failed > 0:
		print("ACEPTACIÓN FASE 2: NO ACEPTADA — FAIL en %s (exit 1)" % ", ".join(failed_names))
		quit(1)
		return
	if skipped > 0:
		print("ACEPTACIÓN FASE 2: PENDIENTE — %d criterio(s) SKIP por módulos Fase 2 en curso (baseline; exit 1)" % skipped)
		quit(1)
		return
	print("ACEPTACIÓN FASE 2: OK — 6/6 criterios PASS (exit 0)")
	quit(0)
