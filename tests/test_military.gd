extends RefCounted
## Tests de MilitarySystem (GDD §5.5, §6.1): reclutamiento, movimiento por
## adyacencia con coste de terreno, ocupación, batalla delegada y disolución.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("military")
	_check_recruitment(runner, h)
	_check_movement(runner, h)
	_check_occupation(runner, h)
	_check_battle_via_move(runner, h)
	_check_army_slots_and_disband(runner, h)


func _check_recruitment(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var army_id: String = _army_in(h, "england", "region_londres")
	var men_before: int = h.army_men(army_id)
	var pool_before: int = h.recruitment_pool("region_londres")
	var gold_before: int = h.treasury("england")
	runner.check("reclutamiento válido", h.recruit("england", "region_londres", "longbowman", 400))
	runner.check_eq("el ejército suma 400 hombres", men_before + 400, h.army_men(army_id))
	runner.check_eq("el pool baja 400", pool_before - 400, h.recruitment_pool("region_londres"))
	# 400 hombres = 2 bloques × 60 oro = 120.
	runner.check_eq("oro gastado en reclutar", gold_before - 120, h.treasury("england"))
	runner.check_eq("el apoyo baja por reclutamiento forzoso", 59, h.support("region_londres"))
	# Restricciones.
	runner.check("unidad con etiqueta de otra facción rechazada",
		not h.recruit("france", "region_normandia", "longbowman", 200))
	runner.check("unidad fuera de época rechazada",
		not h.recruit("england", "region_londres", "bombarda", 200))
	runner.check("cantidad mayor que el pool rechazada",
		not h.recruit("england", "region_londres", "longbowman", 999999))
	h.faction("england")["gold"] = 0
	runner.check("sin oro no se recluta", not h.recruit("england", "region_londres", "longbowman", 200))
	h.new_game("england", 1337)
	runner.check("no se recluta en región enemiga",
		not h.recruit("england", "region_ile_de_france", "longbowman", 200))
	runner.check("unidad inexistente rechazada", not h.recruit("england", "region_londres", "dragones", 200))


func _check_movement(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var army_id: String = _army_in(h, "england", "region_londres")
	runner.check_eq("coste a región adyacente llana", 1, h.move_cost(army_id, "region_inglaterra_sur"))
	runner.check_eq("coste a región adyacente de bosque", 2, h.move_cost(army_id, "region_inglaterra_norte"))
	runner.check_eq("coste a región no adyacente", -1, h.move_cost(army_id, "region_normandia"))
	var pg_before: int = h.remaining_pg()
	runner.check("mover a región propia", h.move_army(army_id, "region_inglaterra_sur"))
	runner.check_eq("movimiento cuesta 1 PG", pg_before - 1, h.remaining_pg())
	runner.check_eq("el ejército cambia de región", "region_inglaterra_sur", str(h.army(army_id)["region_id"]))
	runner.check("no se mueve a región no adyacente", not h.move_army(army_id, "region_burgos"))
	runner.check("no se mueve a la misma región", not h.move_army(army_id, "region_inglaterra_sur"))
	# Los puntos de movimiento se agotan (el ejército tiene 2).
	h.move_army(army_id, "region_inglaterra_norte")
	runner.check("sin puntos de movimiento no se mueve", not h.move_army(army_id, "region_londres"))


func _check_occupation(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var army_id: String = _army_in(h, "england", "region_aquitania")
	runner.check("ocupar región enemiga sin defensores", h.move_army(army_id, "region_bretana"))
	runner.check_eq("Bretaña pasa a Inglaterra", "england", str(h.region("region_bretana")["owner"]))
	runner.check("la ocupación declara la guerra", h.at_war("england", "france"))
	runner.check_eq("el ejército queda en la región ocupada", "region_bretana", str(h.army(army_id)["region_id"]))


func _check_battle_via_move(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var army_id: String = _army_in(h, "england", "region_londres")
	# Refuerzos: 1200 arqueros largos frente a 600 ballesteros franceses.
	h.recruit("england", "region_londres", "longbowman", 400)
	runner.check("avanzar a Inglaterra del sur", h.move_army(army_id, "region_inglaterra_sur"))
	runner.check("atacar Normandía", h.move_army(army_id, "region_normandia"))
	var reports: Array = h.state().get("battle_reports", [])
	runner.check_eq("informe de batalla registrado", 1, reports.size())
	if reports.is_empty():
		return
	var report: Dictionary = SafeDict.as_dict(reports[reports.size() - 1])
	runner.check_eq("el ganador es Inglaterra", "england", str(report.get("winner_faction")))
	runner.check("la región es capturada", SafeDict.as_bool(report.get("region_captured"), false))
	runner.check_eq("Normandía pasa a Inglaterra", "england", str(h.region("region_normandia")["owner"]))
	runner.check("hubo bajas en ambos bandos",
		int(report.get("attacker_losses", 0)) > 0 and int(report.get("defender_losses", 0)) > 0)
	runner.check("asaltos en el rango 1-5", int((report.get("rounds", []) as Array).size()) >= 1
		and int((report.get("rounds", []) as Array).size()) <= 5)
	runner.check("botín transferido", int(report.get("loot_gold", 0)) > 0)
	runner.check("informe con notas legibles", str(report.get("notes", "")) != "")
	# La batalla es determinista con la misma semilla.
	h.new_game("england", 1337)
	var army_again: String = _army_in(h, "england", "region_londres")
	h.recruit("england", "region_londres", "longbowman", 400)
	h.move_army(army_again, "region_inglaterra_sur")
	h.move_army(army_again, "region_normandia")
	var reports_again: Array = h.state().get("battle_reports", [])
	runner.check_eq("batalla determinista (1 informe)", 1, reports_again.size())
	if not reports_again.is_empty():
		var report_again: Dictionary = SafeDict.as_dict(reports_again[reports_again.size() - 1])
		runner.check_eq("mismo ganador con la misma semilla",
			str(report.get("winner_faction")), str(report_again.get("winner_faction")))
		runner.check_eq("mismas bajas con la misma semilla",
			int(report.get("defender_losses", 0)), int(report_again.get("defender_losses", 0)))


func _check_army_slots_and_disband(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	runner.check_eq("Londres tiene 3 huecos (base+castillo+murallas)", 3, h.army_slots("region_londres"))
	var created: Dictionary = h.create_army("england", "region_londres")
	runner.check("se crea un ejército nuevo", not created.is_empty())
	var second: Dictionary = h.create_army("england", "region_londres")
	runner.check("segundo ejército (hasta el límite)", not second.is_empty())
	var third: Dictionary = h.create_army("england", "region_londres")
	runner.check("el cuarto ejército supera el límite", third.is_empty())
	if not created.is_empty():
		var created_id: String = str(created.get("id", ""))
		var pool_before: int = h.recruitment_pool("region_londres")
		runner.check("disolver ejército", h.disband_army(created_id))
		runner.check("ejército disuelto desaparece", h.army(created_id).is_empty())
		runner.check("parte de los hombres vuelve al pool", h.recruitment_pool("region_londres") >= pool_before)
	runner.check("no se disuelve un ejército inexistente", not h.disband_army("army_nope"))
	runner.check("no se crea un ejército en región ajena", h.create_army("england", "region_ile_de_france").is_empty())
	runner.check_eq("las fuerzas iniciales suman sus hombres", 2400, _faction_men(h, "england"))


# --- helpers -------------------------------------------------------------

func _army_in(h: HarnessScript, faction_id: String, region_id: String) -> String:
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id \
				and SafeDict.as_string(army.get("region_id"), "") == region_id:
			return str(army_id)
	return ""


func _faction_men(h: HarnessScript, faction_id: String) -> int:
	var total: int = 0
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in (SafeDict.as_array(army.get("units", null))):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			total += SafeDict.as_int(unit.get("size"), 0)
	return total
