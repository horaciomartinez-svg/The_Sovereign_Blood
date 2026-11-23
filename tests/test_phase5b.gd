extends RefCounted
## Tests Fase 5B (D-084…D-089): ataque multi-ejército/guerra automática,
## guardado multislot, propiedad de decisiones y condiciones de tutorial.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const PLAYER: String = "england"
const TARGET_NO_WAR: String = "region_burgos"      # Castilla, adyacente a Aquitania.
const TARGET_WAR: String = "region_normandia"      # Francia, ya en guerra inicial.


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_attack_validation(runner, h)
	_check_attack_auto_war(runner, h)
	_check_attack_already_war(runner, h)
	_check_attack_multi(runner, h)
	_check_save_slots(runner, h)
	_check_ownership(runner, h)
	_check_tutorial_hooks(runner, h)


func _check_attack_validation(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("attack_validation")
	h.new_game(PLAYER)
	var own: Dictionary = h.preview_attack(PLAYER, "region_londres")
	runner.check("no se puede atacar región propia", not bool(own.get("ok"))
		and SafeDict.as_string(own.get("reason"), "") == "own_region", str(own))
	var missing: Dictionary = h.preview_attack(PLAYER, "region_inexistente")
	runner.check("región inexistente rechazada", not bool(missing.get("ok")), str(missing))
	# Aliado bloqueado.
	h.faction(PLAYER)["allies"] = ["castile"]
	var ally: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR)
	runner.check("aliado bloqueado", not bool(ally.get("ok"))
		and str(ally.get("reason")) == "ally", str(ally))
	h.faction(PLAYER)["allies"] = []
	# PG insuficiente.
	h.faction(PLAYER)["pg"] = 0
	var no_pg: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR)
	runner.check("PG insuficiente bloquea", not bool(no_pg.get("ok"))
		and str(no_pg.get("reason")) == "pg", str(no_pg))
	# Ejército no elegible.
	h.new_game(PLAYER)
	var bad: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR, ["army_scotland_1"])
	runner.check("ejército ajeno/no elegible rechazado", not bool(bad.get("ok")), str(bad))
	var hash_before: int = h.state_hash()
	h.preview_attack(PLAYER, TARGET_NO_WAR)
	runner.check_eq("preview no muta estado", hash_before, h.state_hash())


func _check_attack_auto_war(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("attack_auto_war")
	h.new_game(PLAYER)
	var castile: Dictionary = h.faction("castile")
	castile["at_war"] = []
	h.faction(PLAYER)["at_war"] = []
	h.state()["tutorial"] = {"active": true, "step_index": 5, "completed_steps": [], "skipped": false}
	var preview: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR)
	runner.check("preview de ataque válido", bool(preview.get("ok")), str(preview))
	runner.check("preview incluye ejércitos elegibles", not SafeDict.as_array(preview.get("eligible_armies", null)).is_empty())
	var initial_pg: int = h.remaining_pg()
	var attack: Dictionary = h.attack_region(PLAYER, TARGET_NO_WAR,
		SafeDict.as_array(preview.get("selected_ids", null)))
	runner.check("ataque confirmado", bool(attack.get("ok")), str(attack))
	runner.check("declara guerra automáticamente", bool(attack.get("declared_war")), str(attack))
	runner.check("queda en guerra", h.at_war(PLAYER, "castile"))
	runner.check("coste PG positivo y descontado",
		SafeDict.as_int(attack.get("pg_spent"), 0) > 0 and h.remaining_pg() < initial_pg, str(attack))
	var results: Array = SafeDict.as_array(attack.get("results", null))
	runner.check("resultado por ejército", not results.is_empty())
	for entry in results:
		runner.check("resultado tiene army_id/moved/battle",
			SafeDict.as_dict(entry).has("army_id") and SafeDict.as_dict(entry).has("moved")
			and SafeDict.as_dict(entry).has("battle"))
	runner.check("tutorial avanza attack_launched",
		SafeDict.as_int(h.tutorial_state().get("step_index"), -1) > 5, str(h.tutorial_state()))


func _check_attack_already_war(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("attack_already_war")
	h.new_game(PLAYER)
	# Inglaterra ya está en guerra con Francia en 1337.
	runner.check("guerra inicial con Francia", h.at_war(PLAYER, "france"))
	var preview: Dictionary = h.preview_attack(PLAYER, TARGET_WAR)
	runner.check("preview en guerra", bool(preview.get("ok")) and bool(preview.get("at_war")), str(preview))
	var attack: Dictionary = h.attack_region(PLAYER, TARGET_WAR,
		SafeDict.as_array(preview.get("selected_ids", null)))
	runner.check("ataque en guerra existente", bool(attack.get("ok")), str(attack))
	runner.check("no duplica declaración de guerra", not bool(attack.get("declared_war")), str(attack))


func _check_attack_multi(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("attack_multi")
	h.new_game(PLAYER)
	h.faction(PLAYER)["at_war"] = []
	h.faction("castile")["at_war"] = []
	var preview: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR)
	var ids: Array = SafeDict.as_array(preview.get("selected_ids", null))
	runner.check("hay al menos un ejército elegible", not ids.is_empty())
	# Clona el primer ejército para probar selección múltiple.
	var armies: Dictionary = SafeDict.as_dict(h.state().get("armies", null))
	var base_id: String = str(ids[0])
	var clone: Dictionary = SafeDict.as_dict(armies.get(base_id, null)).duplicate(true)
	clone["id"] = "army_test_multi"
	armies["army_test_multi"] = clone
	var multi_preview: Dictionary = h.preview_attack(PLAYER, TARGET_NO_WAR, [base_id, "army_test_multi"])
	runner.check("preview multi-ejército", bool(multi_preview.get("ok")), str(multi_preview))
	runner.check("coste total suma ambos ejércitos", SafeDict.as_int(multi_preview.get("pg_total"), 0) >= 2,
		str(multi_preview.get("pg_total")))
	var attack: Dictionary = h.attack_region(PLAYER, TARGET_NO_WAR, [base_id, "army_test_multi"])
	runner.check("ataque multi-ejército", bool(attack.get("ok")), str(attack))
	runner.check_eq("resultados para 2 ejércitos", 2, SafeDict.as_array(attack.get("results", null)).size())
	var moved: int = 0
	for entry in SafeDict.as_array(attack.get("results", null)):
		if SafeDict.as_bool(SafeDict.as_dict(entry).get("moved"), false):
			moved += 1
	runner.check("ambos ejércitos se mueven o resuelven", moved >= 1, str(attack))


func _check_save_slots(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("save_slots")
	h.new_game(PLAYER)
	var hash_original: int = h.state_hash()
	for slot in ["slot_1", "slot_2", "slot_3"]:
		runner.check("guardar %s" % slot, h.save_game(slot))
	runner.check("autosave explícito", h.autosave())
	var saves: Array[Dictionary] = h.list_saves()
	runner.check_eq("4 ranuras guardadas (autosave+3)", 4, saves.size())
	var slots: Array = []
	for entry in saves:
		slots.append(SafeDict.as_string(entry.get("slot"), ""))
		runner.check("metadatos year/quarter/faction/saved_at",
			SafeDict.as_int(entry.get("year"), 0) > 0
			and SafeDict.as_int(entry.get("quarter"), 0) > 0
			and SafeDict.as_string(entry.get("faction"), "") == PLAYER
			and SafeDict.as_string(entry.get("saved_at"), "") != "", str(entry))
	runner.check("están autosave y slot_1..slot_3",
		slots.has("autosave") and slots.has("slot_1") and slots.has("slot_2") and slots.has("slot_3"))
	# Mutar y cargar una ranura manual: hash exacto.
	h.faction(PLAYER)["gold"] = 1
	runner.check("cargar slot_2", h.load_game("slot_2"))
	runner.check_eq("hash exacto slot_2", hash_original, h.state_hash())
	# Autosave no sobrescribe la ranura manual.
	h.faction(PLAYER)["gold"] = 777
	runner.check("autosave con estado distinto", h.autosave())
	h.load_game("slot_2")
	runner.check("slot_2 intacto tras autosave", SafeDict.as_int(h.faction(PLAYER).get("gold"), 0) != 777)


func _check_ownership(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("ownership")
	h.new_game(PLAYER)
	var region: String = "region_londres"
	runner.check("propietario puede asignar", h.allocate_as(region, "farmers", 10, PLAYER))
	var before_workers: Dictionary = SafeDict.as_dict(h.region(region).get("workers", null)).duplicate(true)
	var before_pg: int = h.remaining_pg()
	runner.check("actor ajeno rechazado", not h.allocate_as(region, "farmers", 10, "france"))
	runner.check_eq("motivo not_owner", "not_owner", h.allocate_reason())
	runner.check_eq("fallo no gasta PG", before_pg, h.remaining_pg())
	var after_workers: Dictionary = SafeDict.as_dict(h.region(region).get("workers", null))
	runner.check_eq("fallo no cambia trabajadores",
		JSON.stringify(before_workers), JSON.stringify(after_workers))
	# Compatibilidad sin actor (IA/tests antiguos).
	runner.check("sin actor mantiene compatibilidad", h.allocate(region, "farmers", 10))


func _check_tutorial_hooks(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("tutorial_conditions_5b")
	h.new_game_with_difficulty(PLAYER, "beginner")
	var conditions: Array = h.tutorial.call("get_conditions")
	for condition in ["expedition_sent", "attack_launched"]:
		runner.check("condición %s presente" % condition, conditions.has(condition))
	# Expedición avanza el paso 5 (índice 4 → 5).
	h.state()["tutorial"] = {"active": true, "step_index": 4, "completed_steps": [], "skipped": false}
	h.set_merchants(PLAYER, 10)
	runner.check("enviar expedición para tutorial", h.send_expedition(PLAYER, "grano", 2), h.trade_error())
	runner.check("tutorial avanza con expedition_sent",
		SafeDict.as_int(h.tutorial_state().get("step_index"), -1) > 4, str(h.tutorial_state()))
