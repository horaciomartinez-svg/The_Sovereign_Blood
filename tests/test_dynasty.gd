extends RefCounted
## Tests de DynastySystem (GDD §5.3): matrimonios, nacimientos, enfermedad,
## educación, sucesión con regencia, crisis y extinción.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("dynasty")
	_check_marriage(runner, h)
	_check_births_and_deaths(runner, h)
	_check_education(runner, h)
	_check_succession_regency(runner, h)
	_check_crisis_and_extinction(runner, h)
	_check_family_tree(runner, h)


func _check_marriage(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	# Matrimonio ya casado: rechazado sin gastar PG.
	var pg_before: int = int(h.faction("england")["pg"])
	var already: Dictionary = h.marry("edward_iii_plantagenet", "philippa_de_hainault")
	runner.check("matrimonio ya existente rechazado", not bool(already.get("ok")), str(already))
	runner.check_eq("rechazo sin gastar PG", pg_before, int(h.faction("england")["pg"]))
	# Matrimonio entre casas: heredero de Aragón (16) con gobernante de Granada (sin consorte).
	h.faction("aragon")["pg"] = 60
	var marriage: Dictionary = h.marry("jaume_d_urgell", "yusuf_i_nazari")
	runner.check("matrimonio dinástico aceptado", bool(marriage.get("ok")), str(marriage))
	runner.check_eq("coste de matrimonio", 10, marriage.get("cost_pg"))
	runner.check("consorte registrado en ambos", str(h.character("jaume_d_urgell")["family"]["spouse"]) == "yusuf_i_nazari"
		and str(h.character("yusuf_i_nazari")["family"]["spouse"]) == "jaume_d_urgell")
	runner.check("matrimonio crea alianza", str(marriage.get("alliance")) == "granada", str(marriage.get("alliance")))
	runner.check("matrimonio genera pretensión", not (marriage.get("claim") as Dictionary).is_empty(), str(marriage.get("claim")))
	runner.check("matrimonio mejora la relación", h.relation("aragon", "granada") > 0)
	# Matrimonio entre menores de 14: rechazado.
	h.faction("aragon")["pg"] = 60
	var child: Dictionary = h.marry("jaume_d_urgell", "muhammad_v_nazari")
	runner.check("matrimonio con menor rechazado", not bool(child.get("ok")))


func _check_births_and_deaths(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var births: int = 0
	var deaths: int = 0
	for _year in 25:
		h.advance_year()
		if bool(h.state().get("game_over", false)):
			break
	var event_log: Array = h.state().get("event_log", [])
	for entry_value in event_log:
		var entry: Dictionary = SafeDict.as_dict(entry_value)
		var event_id: String = SafeDict.as_string(entry.get("event_id"), "")
		if event_id.begins_with("nacimiento_"):
			births += 1
		elif event_id.begins_with("muerte_"):
			deaths += 1
	runner.check("hay nacimientos en 25 años (12% anual)", births > 0, "nacimientos=%d" % births)
	runner.check("hay muertes en 25 años (enfermedad 2% en >50)", deaths > 0, "muertes=%d" % deaths)
	# Los nacidos son personajes válidos con edad 0 en su año de nacimiento.
	var newborns: Array[String] = []
	for character_id in h.characters().keys():
		var character: Dictionary = h.character(str(character_id))
		if SafeDict.as_string(character.get("source"), "") == "generated":
			newborns.append(str(character_id))
	runner.check("los nacimientos existen en el estado", newborns.is_empty() == (births == 0), str(newborns.size()))
	if not newborns.is_empty():
		var newborn: Dictionary = h.character(newborns[0])
		runner.check("recién nacido vivo y con padre/madre",
			SafeDict.as_bool(newborn.get("alive"), false)
			and SafeDict.as_string((newborn.get("family") as Dictionary).get("father"), "") != "")
		runner.check("recién nacido con stats 1-100", _stats_valid(newborn))


func _check_education(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var heir_id: String = str(h.faction("england")["heir_id"])
	var education_before: int = _stat(h.character(heir_id), "education")
	var any_increase: bool = false
	for _year in 3:
		h.advance_year()
		if _stat(h.character(heir_id), "education") > education_before:
			any_increase = true
	runner.check("educación mejora los stats del heredero", any_increase,
		"%d → %d" % [education_before, _stat(h.character(heir_id), "education")])
	# La educación se paga con PG: sin PG no hay progreso.
	var education_after: int = _stat(h.character(heir_id), "education")
	h.faction("england")["pg"] = 0
	h.dyn.call("advance_year")
	runner.check("sin PG no hay educación", _stat(h.character(heir_id), "education") == education_after)


func _check_succession_regency(runner: TestRunnerScript, h: HarnessScript) -> void:
	# Heredero menor de 14 → regencia.
	h.new_game("england", 1337)
	_kill(h, "edward_iii_plantagenet")
	var result: Dictionary = h.resolve_succession("england")
	runner.check("sucesión resuelta", bool(result.get("ok")), str(result))
	runner.check_eq("heredero promovido a gobernante", "eduardo_el_principe_negro", result.get("heir_id"))
	runner.check_eq("gobernante actualizado", "eduardo_el_principe_negro", h.faction("england")["ruler_id"])
	runner.check("regencia por heredero menor", bool(result.get("regency")))
	runner.check("regente nombrado", str(h.faction("england")["regent_id"]) != "")
	runner.check_eq("regencia hasta los 14", 1330 + 14, int(h.faction("england")["regency_until"]))
	# Heredero adulto → sin regencia.
	h.new_game("england", 1337)
	h.character("eduardo_el_principe_negro")["born"] = 1317
	h.character("eduardo_el_principe_negro")["age"] = 20
	_kill(h, "edward_iii_plantagenet")
	var adult: Dictionary = h.resolve_succession("england")
	runner.check("sucesión de adulto", bool(adult.get("ok")))
	runner.check("adulto no necesita regencia", not bool(adult.get("regency")))
	runner.check_eq("sin regente", "", str(h.faction("england")["regent_id"]))


func _check_crisis_and_extinction(runner: TestRunnerScript, h: HarnessScript) -> void:
	# Crisis con parientes vivos pero sin heredero elegible: Granada 1337
	# (Muhammad V nace en 1338: pariente vivo pero aún no elegible). D-031.
	h.new_game("england", 1337)
	_kill(h, "yusuf_i_nazari")
	h.faction("granada")["heir_id"] = ""
	var crisis: Dictionary = h.resolve_succession("granada")
	runner.check("crisis sucesoria con parientes vivos (no extinción)",
		bool(crisis.get("crisis")) and not bool(crisis.get("extinct")), str(crisis))
	runner.check("interregno programado (2 años)",
		int(h.faction("granada")["interregnum_until"]) == h.year() + 2,
		str(h.faction("granada")["interregnum_until"]))
	runner.check_eq("sin gobernante durante la crisis", "", str(h.faction("granada")["ruler_id"]))
	# Al nacer el heredero (1338) la sucesión se resuelve sola.
	h.advance_year()
	runner.check("el interregno se resuelve cuando el heredero nace",
		str(h.faction("granada")["ruler_id"]) == "muhammad_v_nazari", str(h.faction("granada")["ruler_id"]))
	runner.check("la casa nazarí no se extingue", not SafeDict.as_bool(h.faction("granada").get("eliminated"), false))
	# Extinción del JUGADOR: muere el gobernante y no queda ningún miembro vivo
	# de su casa (ni heredero ni parientes). D-031 / GDD §5.3.
	h.new_game("england", 1337)
	_kill_faction_members(h, "england")
	_kill_house_members_outside(h, "england", "plantagenet")
	h.faction("england")["heir_id"] = ""
	var extinction: Dictionary = h.resolve_succession("england")
	runner.check("extinción de la casa del jugador detectada", bool(extinction.get("extinct")), str(extinction))
	runner.check("facción del jugador eliminada", SafeDict.as_bool(h.faction("england").get("eliminated"), false))
	h.tm.call("_check_game_over")
	runner.check("derrota inmediata del jugador", SafeDict.as_bool(h.state().get("game_over"), false))
	runner.check_eq("motivo de derrota", "dinastía extinta", SafeDict.as_string(h.state().get("game_over_reason"), ""))
	var quarter_before: int = h.quarter()
	h.end_turn()
	runner.check_eq("sin turnos fantasma tras la extinción", quarter_before, h.quarter())
	# Extinción de una IA: el jugador sigue jugando sin crash.
	h.new_game("england", 1337)
	_kill_faction_members(h, "byzantium")
	_kill_house_members_outside(h, "byzantium", "paleologo")
	h.faction("byzantium")["heir_id"] = ""
	h.faction("byzantium")["ruler_id"] = ""
	var ai_extinction: Dictionary = h.resolve_succession("byzantium")
	runner.check("extinción de una IA detectada", bool(ai_extinction.get("extinct")), str(ai_extinction))
	runner.check("IA eliminada", SafeDict.as_bool(h.faction("byzantium").get("eliminated"), false))
	runner.check("la partida del jugador continúa", not SafeDict.as_bool(h.state().get("game_over"), false))
	runner.check("regiones de la IA extinguida reasignadas", _no_regions_of(h, "byzantium"))
	# F2-C2 (task-17): si la casa gobernante no tiene vivos, la dinastía se extingue
	# aunque sobrevivan nobles de OTRAS casas: no hereda un noble ajeno.
	h.new_game("england", 1337)
	var plantagenets_killed: int = 0
	for character_id in h.characters().keys():
		var character: Dictionary = h.character(str(character_id))
		if SafeDict.as_string(character.get("faction"), "") != "england":
			continue
		if SafeDict.as_string(character.get("house"), "") != "plantagenet":
			continue
		# Incluye los nacidos después de 1337: con D-058 un heredero futuro
		# mantiene viva la casa; para forzar la extinción deben morir todos.
		character["alive"] = false
		character["died"] = h.year()
		plantagenets_killed += 1
	runner.check("se mataron los plantagenet de la facción", plantagenets_killed >= 3, str(plantagenets_killed))
	runner.check("quedan nobles de otras casas en Inglaterra",
		_alive_other_house_nobles(h, "england", "plantagenet") > 0)
	var other_house: Dictionary = h.resolve_succession("england")
	runner.check("extinción aunque sobrevivan otras casas", bool(other_house.get("extinct")), str(other_house))
	runner.check("game_over por extinción con otras casas vivas", SafeDict.as_bool(h.state().get("game_over"), false))
	runner.check_eq("motivo con otras casas vivas", "dinastía extinta",
		SafeDict.as_string(h.state().get("game_over_reason"), ""))
	var frozen_quarter: int = h.quarter()
	h.advance_quarter()
	runner.check_eq("reloj congelado con otras casas vivas", frozen_quarter, h.quarter())


func _check_family_tree(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var tree: Array[Dictionary] = h.family_tree("england")
	runner.check("árbol familiar de Inglaterra", tree.size() >= 5, str(tree.size()))
	var ruler_in_tree: bool = false
	for node_value in tree:
		var node: Dictionary = node_value
		if str(node.get("id", "")) == "edward_iii_plantagenet":
			ruler_in_tree = true
	runner.check("el gobernante aparece en el árbol", ruler_in_tree)
	runner.check_eq("árbol del jugador coincide con get_ruler", "edward_iii_plantagenet", str(h.ruler("england").get("id")))
	runner.check_eq("get_heir devuelve al heredero", "eduardo_el_principe_negro", str(h.heir("england").get("id")))


# --- helpers -------------------------------------------------------------

## Nobles vivos de una facción que NO son de la casa indicada (D-031/task-17).
func _alive_other_house_nobles(h: HarnessScript, faction_id: String, house: String) -> int:
	var count: int = 0
	for character_id in h.characters().keys():
		var character: Dictionary = h.character(str(character_id))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if SafeDict.as_string(character.get("house"), "") == house:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		count += 1
	return count


func _stat(character: Dictionary, stat_name: String) -> int:
	return SafeDict.as_int(SafeDict.as_dict(character.get("stats", null)).get(stat_name), 0)


func _stats_valid(character: Dictionary) -> bool:
	var stats: Dictionary = SafeDict.as_dict(character.get("stats", null))
	for stat_name in ["command", "intrigue", "charisma", "loyalty", "education"]:
		var value: int = SafeDict.as_int(stats.get(stat_name), -1)
		if value < 1 or value > 100:
			return false
	return true


func _kill(h: HarnessScript, character_id: String) -> void:
	var character: Dictionary = h.character(character_id)
	character["alive"] = false
	character["died"] = h.year()


func _kill_faction_members(h: HarnessScript, faction_id: String) -> void:
	for character_id in h.characters().keys():
		var character: Dictionary = h.character(str(character_id))
		if SafeDict.as_string(character.get("faction"), "") == faction_id:
			character["alive"] = false
			character["died"] = h.year()


## Mata a los miembros vivos de una casa que están en OTRA facción (D-031).
func _kill_house_members_outside(h: HarnessScript, faction_id: String, house: String) -> void:
	for character_id in h.characters().keys():
		var character: Dictionary = h.character(str(character_id))
		if SafeDict.as_string(character.get("faction"), "") == faction_id:
			continue
		if SafeDict.as_string(character.get("house"), "") != house:
			continue
		character["alive"] = false
		character["died"] = h.year()


func _faction_armies(h: HarnessScript, faction_id: String) -> int:
	var count: int = 0
	for army_id in h.armies().keys():
		var army: Dictionary = SafeDict.as_dict(h.armies().get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id:
			count += 1
	return count


func _no_regions_of(h: HarnessScript, faction_id: String) -> bool:
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			return false
	return true
