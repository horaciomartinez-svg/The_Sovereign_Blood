extends RefCounted
## Tests de DiplomacySystem (GDD §5.4, §5.6): costes PG exactos, guerra/paz,
## alianzas, pactos comerciales, tributos, matrimonio y puntuación de aceptación.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("diplomacy")
	_check_action_costs(runner, h)
	_check_war_and_peace(runner, h)
	_check_alliance(runner, h)
	_check_trade_pact(runner, h)
	_check_tribute(runner, h)
	_check_marriage_proposal(runner, h)
	_check_acceptance_scoring(runner, h)


func _check_action_costs(runner: TestRunnerScript, h: HarnessScript) -> void:
	var expected: Dictionary = {
		"alliance": 8,
		"marriage": 10,
		"trade_pact": 6,
		"demand_tribute": 5,
		"offer_tribute": 3,
		"declare_war": 0,
		"propose_peace": 4,
	}
	for action_id in expected.keys():
		runner.check_eq("coste de %s" % str(action_id), int(expected[action_id]), h.action_cost(str(action_id)))
	runner.check_eq("acción desconocida = -1", -1, h.action_cost("spy"))


func _check_war_and_peace(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 60
	var prestige_before: int = int(h.faction("england")["prestige"])
	var war: Dictionary = h.propose("england", "scotland", {"type": "declare_war"})
	runner.check("guerra declarada", bool(war.get("ok")) and bool(war.get("accepted")), str(war))
	runner.check("estado de guerra bilateral", h.at_war("england", "scotland") and h.at_war("scotland", "england"))
	runner.check("guerra sin casus belli cuesta prestigio", int(h.faction("england")["prestige"]) < prestige_before,
		"%d → %d" % [prestige_before, int(h.faction("england")["prestige"])])
	var again: Dictionary = h.propose("england", "scotland", {"type": "declare_war"})
	runner.check("no se declara dos veces", not bool(again.get("ok")) and str(again.get("reason")) == "already_at_war", str(again))
	# Paz: Escocia es "survivor" (+30) y la relación no es extrema → acepta.
	h.faction("england")["pg"] = 60
	var relation_before_peace: int = h.relation("england", "scotland")
	var peace: Dictionary = h.propose("england", "scotland", {"type": "propose_peace"})
	runner.check("paz aceptada", bool(peace.get("ok")) and bool(peace.get("accepted")), str(peace))
	runner.check("ya no hay guerra", not h.at_war("england", "scotland"))
	runner.check("la paz mejora la relación", h.relation("england", "scotland") > relation_before_peace)
	var peace_again: Dictionary = h.propose("england", "scotland", {"type": "propose_peace"})
	runner.check("paz sin guerra rechazada", not bool(peace_again.get("ok")))
	# Guerra CON casus belli (Francia): no pierde prestigio.
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 60
	var prestige_with_cb: int = int(h.faction("england")["prestige"])
	h.propose("england", "france", {"type": "declare_war"})
	runner.check_eq("guerra con casus belli no cuesta prestigio", prestige_with_cb, int(h.faction("england")["prestige"]))
	runner.check("guerra anglo-francesa activa", h.at_war("england", "france"))


func _check_alliance(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.set_relation("england", "scotland", 50)
	h.faction("england")["pg"] = 60
	var relation_before: int = h.relation("england", "scotland")
	var alliance: Dictionary = h.propose("england", "scotland", {"type": "alliance"})
	runner.check("alianza aceptada con buena relación", bool(alliance.get("ok")) and bool(alliance.get("accepted")), str(alliance))
	runner.check("alianza bilateral", h.allied("england", "scotland") and h.allied("scotland", "england"))
	runner.check("la alianza mejora la relación", h.relation("england", "scotland") > relation_before)
	var again: Dictionary = h.propose("england", "scotland", {"type": "alliance"})
	runner.check("alianza duplicada rechazada", not bool(again.get("ok")))
	# Relación pésima → rechazo.
	h.new_game("england", 1337)
	_force_peace(h, "england", "france")
	h.set_relation("england", "france", -100)
	h.faction("england")["pg"] = 60
	var rejected: Dictionary = h.propose("england", "france", {"type": "alliance"})
	runner.check("alianza rechazada con relación -100", bool(rejected.get("ok")) and not bool(rejected.get("accepted")), str(rejected))
	runner.check("no se crea alianza rechazada", not h.allied("england", "france"))


func _check_trade_pact(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	_force_peace(h, "england", "france")
	h.set_relation("england", "france", 0)
	h.faction("england")["pg"] = 60
	var commerce_before: float = SafeDict.as_float(h.region_output("region_londres").get("commerce"), 0.0)
	var pact: Dictionary = h.propose("england", "france", {"type": "trade_pact"})
	runner.check("pacto comercial aceptado", bool(pact.get("ok")) and bool(pact.get("accepted")), str(pact))
	runner.check("pacto bilateral", (h.faction("england")["trade_pacts"] as Array).has("france")
		and (h.faction("france")["trade_pacts"] as Array).has("england"))
	var commerce_after: float = SafeDict.as_float(h.region_output("region_londres").get("commerce"), 0.0)
	runner.check("el pacto aumenta el comercio (+25%)", commerce_after > commerce_before,
		"%.2f → %.2f" % [commerce_before, commerce_after])
	runner.check_eq("coste del pacto cobrado", 54, int(h.faction("england")["pg"]))


func _force_peace(h: HarnessScript, faction_a: String, faction_b: String) -> void:
	var a: Dictionary = h.faction(faction_a)
	var b: Dictionary = h.faction(faction_b)
	var a_wars: Array = SafeDict.as_array(a.get("at_war", null))
	var b_wars: Array = SafeDict.as_array(b.get("at_war", null))
	a_wars.erase(faction_b)
	b_wars.erase(faction_a)
	a["at_war"] = a_wars
	b["at_war"] = b_wars


func _check_tribute(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 60
	var england_gold: int = h.treasury("england")
	var scotland_gold: int = h.treasury("scotland")
	var offer: Dictionary = h.propose("england", "scotland", {"type": "offer_tribute"})
	runner.check("tributo ofrecido", bool(offer.get("ok")) and bool(offer.get("accepted")), str(offer))
	runner.check_eq("Inglaterra paga 300", england_gold - 300, h.treasury("england"))
	runner.check_eq("Escocia recibe 300", scotland_gold + 300, h.treasury("scotland"))
	runner.check("el tributo mejora la relación", h.relation("england", "scotland") > 0)
	# Exigir tributo: Inglaterra es mucho más fuerte → acepta y transfiere 500.
	var gold_before_demand: int = h.treasury("scotland")
	h.faction("england")["pg"] = 60
	var demand: Dictionary = h.propose("england", "scotland", {"type": "demand_tribute"})
	runner.check("tributo exigido aceptado", bool(demand.get("ok")) and bool(demand.get("accepted")), str(demand))
	runner.check_eq("Escocia paga 500", gold_before_demand - 500, h.treasury("scotland"))
	# Exigir tributo a un igual con mala relación → rechazo y guerra.
	h.new_game("england", 1337)
	h.set_relation("england", "france", -50)
	h.faction("england")["pg"] = 60
	var rejected: Dictionary = h.propose("england", "france", {"type": "demand_tribute"})
	runner.check("tributo rechazado por Francia", not bool(rejected.get("accepted")), str(rejected))
	runner.check("rechazo con mala relación → guerra", h.at_war("england", "france"))


func _check_marriage_proposal(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.faction("england")["pg"] = 60
	var marriage: Dictionary = h.propose("england", "aragon", {"type": "marriage"})
	runner.check("propuesta de matrimonio procesada", bool(marriage.get("ok")), str(marriage))
	runner.check_eq("coste de matrimonio cobrado una sola vez", 50, int(h.faction("england")["pg"]))
	if bool(marriage.get("accepted")):
		var actor_character: String = SafeDict.as_string(marriage.get("character"), "")
		var target_character: String = SafeDict.as_string(marriage.get("target_character"), "")
		runner.check("el matrimonio fija los consortes",
			actor_character != "" and target_character != ""
			and str(h.character(actor_character)["family"]["spouse"]) == target_character)
		runner.check("el matrimonio real crea alianza", str(marriage.get("alliance")) == "aragon",
			str(marriage.get("alliance")))


func _check_acceptance_scoring(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.set_relation("england", "scotland", 40)
	h.set_relation("england", "france", -40)
	var good: int = int(h.dip.call("compute_acceptance", "england", "scotland", "alliance"))
	var bad: int = int(h.dip.call("compute_acceptance", "england", "france", "alliance"))
	runner.check("la aceptación crece con la relación", good > bad, "%d vs %d" % [good, bad])
	# Perfil mercader valora más un pacto comercial que un agresor.
	h.set_relation("england", "aragon", 0)
	h.set_relation("england", "castile", 0)
	var merchant_score: int = int(h.dip.call("compute_acceptance", "england", "aragon", "trade_pact"))
	var aggressor_score: int = int(h.dip.call("compute_acceptance", "england", "castile", "trade_pact"))
	runner.check("perfil mercader acepta mejor el pacto comercial", merchant_score > aggressor_score,
		"%d vs %d" % [merchant_score, aggressor_score])
