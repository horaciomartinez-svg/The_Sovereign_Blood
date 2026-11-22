extends RefCounted
## Tests task-71: acciones singulares (actions_used) y costes de reclutamiento.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const PLAYER: String = "england"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_actions_state(runner, h)
	_check_diplomacy_gate(runner, h)
	_check_family_build_gate(runner, h)
	_check_espionage_expedition_gate(runner, h)
	_check_exempt_actions(runner, h)
	_check_reset_and_save(runner, h)
	_check_recruit_costs(runner, h)


func _check_actions_state(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_state")
	h.new_game(PLAYER)
	runner.check("actions_used inicia vacío", not h.is_action_used(PLAYER, "diplomacy:test:x"))
	runner.check("marcar acción", h.mark_action_used(PLAYER, "diplomacy:test:x"))
	runner.check("acción marcada", h.is_action_used(PLAYER, "diplomacy:test:x"))
	runner.check("no se puede repetir", not h.can_use_action(PLAYER, "diplomacy:test:x"))
	runner.check("marcar duplicado falla", not h.mark_action_used(PLAYER, "diplomacy:test:x"))
	runner.check("estado serializable", JSON.stringify(h.state().get("actions_used", null)).length() > 2)


func _check_diplomacy_gate(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_diplomacy")
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	var first: Dictionary = h.propose(PLAYER, "scotland", {"type": "declare_war"})
	runner.check("primera declaración de guerra pasa el gate", bool(first.get("ok")) or
		SafeDict.as_string(first.get("reason"), "") != "action_used", str(first))
	var pg_after_first: int = h.remaining_pg()
	var second: Dictionary = h.propose(PLAYER, "scotland", {"type": "declare_war"})
	runner.check_eq("segunda declaración bloqueada por action_used", "action_used",
		SafeDict.as_string(second.get("reason"), ""))
	runner.check_eq("duplicado no gasta PG", pg_after_first, h.remaining_pg())
	# Distinta acción/target sigue permitida.
	var other: Dictionary = h.propose(PLAYER, "france", {"type": "declare_war"})
	runner.check("acción distinta no bloqueada",
		SafeDict.as_string(other.get("reason"), "") != "action_used", str(other))


func _check_family_build_gate(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_family_build")
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	# Matrimonio propuesto dos veces.
	var marriage: Dictionary = h.propose(PLAYER, "aragon", {"type": "marriage"})
	runner.check("primer matrimonio no bloqueado por gate",
		SafeDict.as_string(marriage.get("reason"), "") != "action_used", str(marriage))
	var marriage_again: Dictionary = h.propose(PLAYER, "aragon", {"type": "marriage"})
	runner.check_eq("matrimonio duplicado action_used", "action_used",
		SafeDict.as_string(marriage_again.get("reason"), ""))
	# Construcción duplicada.
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	var build: Dictionary = h.build_building(PLAYER, "region_londres", "granary")
	runner.check("primera construcción OK", bool(build.get("ok")), str(build))
	var gold_after: int = h.treasury(PLAYER)
	var build_again: Dictionary = h.build_building(PLAYER, "region_londres", "granary")
	runner.check_eq("construcción duplicada action_used", "action_used",
		SafeDict.as_string(build_again.get("reason"), ""))
	runner.check_eq("duplicado no gasta oro", gold_after, h.treasury(PLAYER))
	h.reset_turn_actions()
	var built: Dictionary = h.build_building(PLAYER, "region_londres", "granary")
	runner.check("tras reset la acción ya está construida (no action_used)",
		SafeDict.as_string(built.get("reason"), "") != "action_used", str(built))


func _check_espionage_expedition_gate(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_espionage_expedition")
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	var spy: Dictionary = h.propose(PLAYER, "france", {"type": "espia"})
	runner.check("primer espionaje no bloqueado",
		SafeDict.as_string(spy.get("reason"), "") != "action_used", str(spy))
	var pg_spy: int = h.remaining_pg()
	var spy_again: Dictionary = h.propose(PLAYER, "france", {"type": "espia"})
	runner.check_eq("espionaje duplicado action_used", "action_used",
		SafeDict.as_string(spy_again.get("reason"), ""))
	runner.check_eq("espionaje duplicado no gasta PG", pg_spy, h.remaining_pg())
	# Expedición duplicada.
	h.new_game(PLAYER)
	h.set_merchants(PLAYER, 10)
	var region: String = _first_owned_region(h, PLAYER)
	var pg_before: int = h.remaining_pg()
	runner.check("primera expedición", h.send_expedition(PLAYER, "grano", 3), h.trade_error())
	runner.check_eq("expedición cuesta 2 PG", pg_before - 2, h.remaining_pg())
	var pg_after: int = h.remaining_pg()
	runner.check("expedición duplicada falla", not h.send_expedition(PLAYER, "grano", 3))
	runner.check_eq("expedición duplicada no gasta PG", pg_after, h.remaining_pg())
	runner.check_eq("motivo action_used", "action_used", h.trade_error())
	# Vender/comprar sigue permitido (exento) aunque la expedición esté usada.
	runner.check("comprar tras expedición sigue permitido", h.buy_good(PLAYER, region, "grano", 1),
		h.trade_error())


func _check_exempt_actions(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_exempt")
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	h.mark_action_used(PLAYER, "diplomacy:test:x")
	# Reclutar dos veces (sin mercancías requeridas para longbowman).
	runner.check("reclutar 1", h.recruit(PLAYER, "region_londres", "longbowman", 200), h.recruit_reason())
	runner.check("reclutar 2", h.recruit(PLAYER, "region_londres", "longbowman", 200), h.recruit_reason())
	# Asignar trabajadores dos veces.
	runner.check("asignar trabajadores 1", bool(h.allocate("region_londres", "farmers", 10)))
	runner.check("asignar trabajadores 2", bool(h.allocate("region_londres", "farmers", 11)))
	# Mercado: comprar dos veces no exige acción singular.
	var region: String = "region_londres"
	h.set_merchants(PLAYER, 10)
	runner.check("comprar 1", h.buy_good(PLAYER, region, "grano", 1), h.trade_error())
	runner.check("comprar 2", h.buy_good(PLAYER, region, "grano", 1), h.trade_error())
	runner.check("las exenciones no marcan acciones", not h.is_action_used(PLAYER, "recruit"))


func _check_reset_and_save(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("actions_reset_save")
	h.new_game(PLAYER)
	h.mark_action_used(PLAYER, "diplomacy:test:x")
	runner.check("acción usada antes de reset", h.is_action_used(PLAYER, "diplomacy:test:x"))
	h.reset_turn_actions()
	runner.check("reset limpia acciones", not h.is_action_used(PLAYER, "diplomacy:test:x"))
	h.mark_action_used(PLAYER, "diplomacy:test:y")
	var hash_save: int = h.state_hash()
	runner.check("guardar con actions_used", h.save_game("actions_save"))
	h.reset_turn_actions()
	runner.check("cargar con actions_used", h.load_game("actions_save"))
	runner.check_eq("hash con actions_used", hash_save, h.state_hash())
	runner.check("action_used persistida", h.is_action_used(PLAYER, "diplomacy:test:y"))
	h.advance_quarter()
	runner.check("avanzar trimestre resetea acciones", not h.is_action_used(PLAYER, "diplomacy:test:y"))


func _check_recruit_costs(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("recruit_costs")
	h.new_game(PLAYER)
	var militia: Dictionary = h.unit_recruit_cost("militia_spearman", 200)
	var longbow: Dictionary = h.unit_recruit_cost("longbowman", 200)
	var men_at_arms: Dictionary = h.unit_recruit_cost("men_at_arms", 200)
	var bombarda: Dictionary = h.unit_recruit_cost("bombarda", 200)
	runner.check_eq("militia 200: 20 oro, 1 bloque", [20, 1],
		[SafeDict.as_int(militia.get("gold"), -1), SafeDict.as_int(militia.get("blocks"), -1)])
	runner.check_eq("longbow 200: 60 oro", 60, SafeDict.as_int(longbow.get("gold"), -1))
	runner.check_eq("men_at_arms 200: 140 oro", 140, SafeDict.as_int(men_at_arms.get("gold"), -1))
	runner.check_eq("bombarda 200: 200 oro", 200, SafeDict.as_int(bombarda.get("gold"), -1))
	runner.check("costes distintos militia/longbow/men/bombarda",
		SafeDict.as_int(militia.get("gold"), 0) < SafeDict.as_int(longbow.get("gold"), 0)
		and SafeDict.as_int(longbow.get("gold"), 0) < SafeDict.as_int(men_at_arms.get("gold"), 0)
		and SafeDict.as_int(men_at_arms.get("gold"), 0) < SafeDict.as_int(bombarda.get("gold"), 0))
	runner.check_eq("men_at_arms consume 2 caballos/bloque", 2.0,
		SafeDict.as_float(SafeDict.as_dict(men_at_arms.get("goods_per_block", null)).get("caballos"), 0.0))
	var bombarda_goods: Dictionary = SafeDict.as_dict(bombarda.get("goods", null))
	runner.check("bombarda consume hierro y madera",
		SafeDict.as_float(bombarda_goods.get("hierro"), 0.0) > 0.0
		and SafeDict.as_float(bombarda_goods.get("madera"), 0.0) > 0.0)
	# Resumen de ejércitos expone coste por bloque.
	var summary: Array[Dictionary] = h.army_summary(PLAYER)
	var found: bool = false
	for entry in summary:
		if SafeDict.as_string(entry.get("unit_id"), "") == "men_at_arms":
			found = true
			runner.check_eq("resumen men_at_arms coste oro/bloque", 140,
				SafeDict.as_int(entry.get("recruit_gold_per_block"), -1))
			runner.check("resumen men_at_arms coste caballos/bloque",
				SafeDict.as_float(SafeDict.as_dict(entry.get("recruit_goods_per_block", null)).get("caballos"), 0.0) == 2.0)
	runner.check("resumen incluye men_at_arms", found)
	# Deducción real de oro distinta para milicia/arquero.
	h.new_game(PLAYER)
	var gold_before: int = h.treasury(PLAYER)
	h.recruit(PLAYER, "region_londres", "militia_spearman", 200)
	var gold_after_militia: int = h.treasury(PLAYER)
	h.recruit(PLAYER, "region_londres", "longbowman", 200)
	var gold_after_longbow: int = h.treasury(PLAYER)
	runner.check("deducción de milicia menor que arqueros",
		(gold_before - gold_after_militia) < (gold_after_militia - gold_after_longbow))


func _first_owned_region(h: HarnessScript, faction_id: String) -> String:
	for region_id in SafeDict.sorted_keys(h.regions()):
		if SafeDict.as_string(h.region(region_id).get("owner"), "") == faction_id:
			return region_id
	return ""
