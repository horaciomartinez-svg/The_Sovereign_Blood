extends Node
## DynastySystem — nacimientos, muertes, matrimonios, educación y sucesión
## (GDD §5.3, §8.2). Toda la aleatoriedad sale de `GameState.rng`.
##
## Reglas Fase 1:
##   nacimiento 12% por año si el consorte del gobernante es fértil (<40),
##   enfermedad 2% por año en personajes >50, matrimonio ≥14 años,
##   educación de menores (6-16) con 1 PG/año por facción, sucesión con regencia
##   si el heredero <14, crisis (interregno 2 años) y extinción = derrota.

signal character_born(character_id: String, faction_id: String)
signal character_died(character_id: String, cause: String)
signal marriage_formed(character_id: String, spouse_id: String)
signal succession_resolved(faction_id: String, heir_id: String)
signal regency_started(faction_id: String, regent_id: String)
signal dynasty_extinct(faction_id: String)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")

const ELIGIBLE_ROLES: Array[String] = ["heir", "relative", "claimant", "regent"]


## Matrimonio dinámico: {ok, cost_pg, alliance, claim, reason}.
func marry(character_id: String, target_character_id: String) -> Dictionary:
	var result: Dictionary = {
		"ok": false,
		"cost_pg": SafeDict.as_int(Constants.ACTION_PG_COSTS.get("marriage"), 10),
		"alliance": "",
		"claim": {},
		"reason": "",
	}
	var st: Dictionary = GameState.state
	if st.is_empty():
		result["reason"] = "no_game"
		return result
	if character_id == target_character_id:
		result["reason"] = "same_character"
		return result
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var character_a: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
	var character_b: Dictionary = SafeDict.as_dict(characters.get(target_character_id, null))
	if character_a.is_empty() or character_b.is_empty():
		result["reason"] = "unknown_character"
		return result
	if not SafeDict.as_bool(character_a.get("alive"), false) or not SafeDict.as_bool(character_b.get("alive"), false):
		result["reason"] = "dead"
		return result
	var current_year: int = SafeDict.as_int(st.get("year"), 1337)
	var age_a: int = current_year - SafeDict.as_int(character_a.get("born"), current_year)
	var age_b: int = current_year - SafeDict.as_int(character_b.get("born"), current_year)
	if age_a < Constants.MARRIAGE_MIN_AGE or age_b < Constants.MARRIAGE_MIN_AGE:
		result["reason"] = "too_young"
		return result
	var family_a: Dictionary = SafeDict.as_dict(character_a.get("family", null))
	var family_b: Dictionary = SafeDict.as_dict(character_b.get("family", null))
	var spouse_a: String = SafeDict.as_string(family_a.get("spouse"), "")
	var spouse_b: String = SafeDict.as_string(family_b.get("spouse"), "")
	if spouse_a == target_character_id and spouse_b == character_id:
		result["reason"] = "already_married"
		return result
	if spouse_a != "" and spouse_a != target_character_id:
		result["reason"] = "already_married"
		return result
	if spouse_b != "" and spouse_b != character_id:
		result["reason"] = "target_already_married"
		return result
	var faction_a: String = SafeDict.as_string(character_a.get("faction"), "")
	var faction_b: String = SafeDict.as_string(character_b.get("faction"), "")
	var faction_state_a: Dictionary = GameState.get_faction_state(faction_a)
	if faction_state_a.is_empty() or SafeDict.as_bool(faction_state_a.get("eliminated"), false):
		result["reason"] = "faction_unavailable"
		return result
	var cost_pg: int = SafeDict.as_int(result.get("cost_pg"), 10)
	if not TurnManager.spend_pg_for(faction_a, cost_pg):
		result["reason"] = "pg"
		return result

	family_a["spouse"] = target_character_id
	family_b["spouse"] = character_id
	character_a["family"] = family_a
	character_b["family"] = family_b

	var alliance: String = ""
	var claim: Dictionary = {}
	if faction_a != faction_b:
		DiplomacySystem.set_relation(faction_a, faction_b,
			get_relation_between(faction_a, faction_b) + Constants.MARRIAGE_RELATION_BONUS)
		var role_a: String = SafeDict.as_string(character_a.get("role"), "")
		var role_b: String = SafeDict.as_string(character_b.get("role"), "")
		if _is_royal(role_a) or _is_royal(role_b):
			claim = {"target": faction_b, "strength": 0.5}
			var claims: Array = SafeDict.as_array(character_a.get("claims", null))
			claims.append(claim)
			character_a["claims"] = claims
		if role_a == "ruler" or role_b == "ruler":
			_add_alliance(faction_a, faction_b)
			alliance = faction_b
	result["ok"] = true
	result["alliance"] = alliance
	result["claim"] = claim
	result["reason"] = "ok"
	emit_signal("marriage_formed", character_id, target_character_id)
	EventBus.emit_signal("marriage_formed", character_id, target_character_id)
	_log_event("matrimonio_%s_%s" % [character_id, target_character_id],
		"Matrimonio dinástico entre %s y %s." % [
			SafeDict.as_string(character_a.get("name"), character_id),
			SafeDict.as_string(character_b.get("name"), target_character_id),
		])
	return result


## Eventos vitales generados al avanzar el año (GDD §8.2).
## D-067: mortalidad dinástica de la Peste Negra. Mata como máximo un pariente
## por facción (nunca al gobernante, heredero o cónyuge) de forma determinista
## con el RNG central, para no romper la línea sucesoria jugable.
func apply_plague_mortality(year: int = 0) -> int:
	var st: Dictionary = GameState.state
	if st.is_empty() or GameState.rng == null:
		return 0
	var current_year: int = year if year > 0 else SafeDict.as_int(st.get("year"), 1337)
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var affected_factions: Dictionary = {}
	var killed: int = 0
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if character.is_empty() or not SafeDict.as_bool(character.get("alive"), false):
			continue
		var faction_id: String = SafeDict.as_string(character.get("faction"), "")
		if faction_id == "" or affected_factions.has(faction_id):
			continue
		var role: String = SafeDict.as_string(character.get("role"), "")
		if role == "ruler" or role == "heir" or role == "spouse":
			continue
		if SafeDict.as_int(character.get("born"), current_year) > current_year:
			continue
		if GameState.rng.next_float() >= Constants.PLAGUE_MORTALITY_CHANCE:
			continue
		_die(character_id, character, "peste negra", current_year)
		affected_factions[faction_id] = true
		killed += 1
	# Garantiza que la peste deje huella dinástica aunque el RNG no acierte.
	if killed == 0:
		for character_id in SafeDict.sorted_keys(characters):
			var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
			if character.is_empty() or not SafeDict.as_bool(character.get("alive"), false):
				continue
			var role: String = SafeDict.as_string(character.get("role"), "")
			if role == "ruler" or role == "heir" or role == "spouse":
				continue
			if SafeDict.as_int(character.get("born"), current_year) > current_year:
				continue
			_die(character_id, character, "peste negra", current_year)
			killed += 1
			break
	return killed


func advance_year() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	if st.is_empty():
		return events
	var current_year: int = SafeDict.as_int(st.get("year"), 1337)
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))

	# 0) Vivos por año (D-058): los nacidos después del inicio pasan a vivos al
	# llegar su año; los fallecidos históricamente dejan de estarlo.
	_refresh_character_lives(characters, current_year)

	# 1) Envejecimiento.
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		character["age"] = current_year - SafeDict.as_int(character.get("born"), current_year)

	# 2) Enfermedad (2% anual en >50).
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		var age: int = SafeDict.as_int(character.get("age"), 0)
		if age <= Constants.DISEASE_AGE:
			continue
		if GameState.rng.next_float() < Constants.DISEASE_CHANCE:
			var death_entry: Dictionary = _die(character_id, character, "enfermedad", current_year)
			events.append(death_entry)

	# 3) Nacimientos (12% por consorte fértil <40).
	for faction_id in SafeDict.sorted_keys(factions):
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
		var ruler: Dictionary = SafeDict.as_dict(characters.get(ruler_id, null))
		if ruler.is_empty() or not SafeDict.as_bool(ruler.get("alive"), false):
			continue
		var family: Dictionary = SafeDict.as_dict(ruler.get("family", null))
		var spouse_id: String = SafeDict.as_string(family.get("spouse"), "")
		var spouse: Dictionary = SafeDict.as_dict(characters.get(spouse_id, null))
		if spouse.is_empty() or not SafeDict.as_bool(spouse.get("alive"), false):
			continue
		var ruler_age: int = current_year - SafeDict.as_int(ruler.get("born"), current_year)
		var spouse_age: int = current_year - SafeDict.as_int(spouse.get("born"), current_year)
		if ruler_age < Constants.MARRIAGE_MIN_AGE or spouse_age < Constants.MARRIAGE_MIN_AGE:
			continue
		if spouse_age >= Constants.FERTILE_AGE:
			continue
		if GameState.rng.next_float() >= Constants.BIRTH_CHANCE:
			continue
		var child_id: String = _create_child(faction_id, ruler_id, spouse_id, current_year, characters)
		if child_id == "":
			continue
		emit_signal("character_born", child_id, faction_id)
		EventBus.emit_signal("character_born", child_id, faction_id)
		events.append(_log_event("nacimiento_%s" % child_id,
			"Nace un vástago en la casa de %s." % SafeDict.as_string(faction.get("profile"), faction_id)))

	# 4) Educación de menores (1 PG/año por facción).
	_educate_minors(factions, characters)

	# 5) Sucesiones por gobernante fallecido.
	for faction_id in SafeDict.sorted_keys(factions):
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
		# Un interregno ya abierto lo gestiona el paso 6 (no se reinicia aquí).
		if ruler_id == "" and SafeDict.as_int(faction.get("interregnum_until"), 0) > 0:
			continue
		var ruler_alive: bool = false
		if ruler_id != "":
			var ruler: Dictionary = SafeDict.as_dict(characters.get(ruler_id, null))
			ruler_alive = SafeDict.as_bool(ruler.get("alive"), false)
		if ruler_alive:
			continue
		var succession: Dictionary = resolve_succession(faction_id)
		if SafeDict.as_bool(succession.get("ok"), false):
			events.append(_log_event("sucesion_%s_%d" % [faction_id, current_year],
				"Nueva sucesión en %s." % faction_id))
		elif SafeDict.as_bool(succession.get("crisis"), false):
			events.append(_log_event("crisis_sucesoria_%s_%d" % [faction_id, current_year],
				"Crisis sucesoria en %s." % faction_id))

	# 6) Fin de interregnos y extinciones.
	_advance_interregna(factions, characters, current_year, events)
	return events


## Gobernante actual de una facción ({} si no hay).
func get_ruler(faction_id: String) -> Dictionary:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	if ruler_id == "":
		return {}
	var ruler: Dictionary = GameState.get_character_state(ruler_id)
	return ruler.duplicate(true)


## Heredero legal de una facción ({} si no hay).
func get_heir(faction_id: String) -> Dictionary:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var heir_id: String = SafeDict.as_string(faction.get("heir_id"), "")
	if heir_id == "":
		return {}
	var heir: Dictionary = GameState.get_character_state(heir_id)
	return heir.duplicate(true)


## Resuelve la sucesión: {ok, heir_id, regency, crisis, extinct}.
func resolve_succession(faction_id: String) -> Dictionary:
	var result: Dictionary = {
		"ok": false,
		"heir_id": "",
		"regency": false,
		"crisis": false,
		"extinct": false,
	}
	var st: Dictionary = GameState.state
	if st.is_empty():
		return result
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
		return result
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var current_year: int = SafeDict.as_int(st.get("year"), 1337)
	var faction_house: String = SafeDict.as_string(faction.get("house"), "")
	# Fase 2 (D-031, task-17): si no queda NINGÚN miembro vivo de la casa del
	# gobernante en la facción, la dinastía se extingue aunque sobrevivan nobles
	# de otras casas. Emite dynasty_extinct y el jugador pierde la partida.
	if faction_house != "" and _faction_house_members_alive(characters, faction_id, faction_house, current_year).is_empty():
		var extinction_events: Array[Dictionary] = []
		_extinguish(faction_id, extinction_events)
		result["extinct"] = true
		_log_event("extincion_casa_%s_%d" % [faction_id, current_year],
			"La casa %s se extingue: %s queda sin gobernante ni parientes." % [faction_house, faction_id])
		return result
	var heir_id: String = _choose_heir(faction_id, characters, current_year)
	if heir_id == "":
		faction["ruler_id"] = ""
		faction["heir_id"] = ""
		faction["regent_id"] = ""
		faction["regency_until"] = 0
		faction["interregnum_until"] = current_year + Constants.INTERREGNUM_YEARS
		faction["prestige"] = maxi(0, SafeDict.as_int(faction.get("prestige"), 0) - Constants.CRISIS_PRESTIGE_LOSS)
		result["crisis"] = true
		_log_event("crisis_sucesoria_%s_%d" % [faction_id, current_year],
			"Sin herederos: comienza un interregno en %s." % faction_id)
		EventBus.emit_signal("ui_notification",
			"Crisis sucesoria en %s: interregno de %d años." % [faction_id, Constants.INTERREGNUM_YEARS], 2)
		return result
	var heir: Dictionary = SafeDict.as_dict(characters.get(heir_id, null))
	var heir_age: int = current_year - SafeDict.as_int(heir.get("born"), current_year)
	# Adopción dinástica: un pariente de la casa en otra facción hereda el trono.
	var heir_faction: String = SafeDict.as_string(heir.get("faction"), "")
	if heir_faction != "" and heir_faction != faction_id:
		var old_faction: Dictionary = GameState.get_faction_state(heir_faction)
		if not old_faction.is_empty():
			if SafeDict.as_string(old_faction.get("heir_id"), "") == heir_id:
				old_faction["heir_id"] = ""
			if SafeDict.as_string(old_faction.get("ruler_id"), "") == heir_id:
				old_faction["ruler_id"] = ""
		heir["faction"] = faction_id
	faction["house"] = SafeDict.as_string(heir.get("house"), faction_house)
	faction["ruler_id"] = heir_id
	faction["interregnum_until"] = 0
	heir["role"] = "ruler"
	faction["heir_id"] = _choose_heir(faction_id, characters, current_year, heir_id)
	if heir_age < Constants.REGENCY_AGE:
		var regent_id: String = _choose_regent(faction_id, characters, current_year, heir_id)
		faction["regent_id"] = regent_id
		faction["regency_until"] = SafeDict.as_int(heir.get("born"), current_year) + Constants.REGENCY_AGE
		result["regency"] = true
		emit_signal("regency_started", faction_id, regent_id)
		EventBus.emit_signal("regency_started", faction_id, regent_id)
	else:
		faction["regent_id"] = ""
		faction["regency_until"] = 0
	result["ok"] = true
	result["heir_id"] = heir_id
	emit_signal("succession_resolved", faction_id, heir_id)
	EventBus.emit_signal("succession_resolved", faction_id, heir_id)
	_log_event("sucesion_%s_%d" % [faction_id, current_year],
		"%s accede al trono de %s." % [SafeDict.as_string(heir.get("name"), heir_id), faction_id])
	return result


## Árbol familiar serializable de una facción.
func get_family_tree(faction_id: String) -> Array[Dictionary]:
	var tree: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	if st.is_empty():
		return tree
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		var family: Dictionary = SafeDict.as_dict(character.get("family", null))
		tree.append({
			"id": character_id,
			"name": SafeDict.as_string(character.get("name"), character_id),
			"role": SafeDict.as_string(character.get("role"), ""),
			"alive": SafeDict.as_bool(character.get("alive"), false),
			"age": SafeDict.as_int(character.get("age"), 0),
			"born": SafeDict.as_int(character.get("born"), 0),
			"died": character.get("died", null),
			"father": SafeDict.as_string(family.get("father"), ""),
			"mother": SafeDict.as_string(family.get("mother"), ""),
			"spouse": SafeDict.as_string(family.get("spouse"), ""),
			"children": SafeDict.as_array(family.get("children", null)).duplicate(),
			"stats": SafeDict.as_dict(character.get("stats", null)).duplicate(true),
		})
	return tree


## Relación bilateral actual (helper para evitar depender del orden de autoloads).
func get_relation_between(faction_a: String, faction_b: String) -> int:
	var faction: Dictionary = GameState.get_faction_state(faction_a)
	var relations: Dictionary = SafeDict.as_dict(faction.get("relations", null))
	return SafeDict.as_int(relations.get(faction_b), 0)


# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

## Comprueba que la facción tenga gobernante vivo; si no, resuelve la sucesión.
## Lo usa MilitarySystem tras la muerte de un líder en batalla (Fase 2, D-031).
func check_ruling_line(faction_id: String) -> Dictionary:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty():
		return {"ok": false, "reason": "unknown_faction"}
	if SafeDict.as_bool(faction.get("eliminated"), false):
		return {"ok": false, "reason": "eliminated"}
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	if ruler_id == "" and SafeDict.as_int(faction.get("interregnum_until"), 0) > 0:
		return {"ok": false, "heir_id": "", "reason": "interregnum"}
	if ruler_id != "":
		var ruler: Dictionary = GameState.get_character_state(ruler_id)
		if SafeDict.as_bool(ruler.get("alive"), false):
			return {"ok": true, "heir_id": ruler_id, "reason": "ruler_alive"}
	return resolve_succession(faction_id)


## Actualiza `alive`/`age` de todos los personajes para el año en curso (D-058):
## nacidos <= año y no fallecidos todavía. Los nacimientos dinásticos ya vienen
## con `alive=true`; aquí se incorporan también los históricos nacidos después
## del año de inicio del escenario.
func _refresh_character_lives(characters: Dictionary, year: int) -> void:
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if character.is_empty():
			continue
		var born: int = SafeDict.as_int(character.get("born"), year)
		var died_value: Variant = character.get("died", null)
		var dead: bool = died_value != null and SafeDict.as_int(died_value, year) <= year
		character["alive"] = born <= year and not dead
		character["age"] = year - born


## Miembros de la línea dinástica vivos o aún no nacidos (D-058): un heredero
## futuro (born > año y sin fallecimiento registrado) mantiene viva la casa y
## evita declarar extinción; la sucesión sigue en crisis/interregno hasta nacer.
func _character_line_alive(character: Dictionary, year: int) -> bool:
	if SafeDict.as_bool(character.get("alive"), false):
		return true
	var born: int = SafeDict.as_int(character.get("born"), year)
	if born > year:
		var died_value: Variant = character.get("died", null)
		# Sigue en la línea si aún no ha nacido y no consta muerto antes de nacer
		# (los fallecimientos registrados por el motor usan el año actual < born).
		if died_value == null or SafeDict.as_int(died_value, year) >= born:
			return true
	return false


## Miembros vivos de la casa gobernante DENTRO de una facción (D-031/task-17).
## La extinción se decide con esta lista: nobles de otras casas no cuentan.
func _faction_house_members_alive(characters: Dictionary, faction_id: String, house: String, year: int) -> Array[String]:
	var result: Array[String] = []
	if house == "":
		return result
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if not _character_line_alive(character, year):
			continue
		if SafeDict.as_string(character.get("house"), "") != house:
			continue
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		result.append(character_id)
	return result


## Miembros vivos de una casa dinástica (en cualquier facción). D-031.
func _house_members_alive(characters: Dictionary, house: String, year: int) -> Array[String]:
	var result: Array[String] = []
	if house == "":
		return result
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if not _character_line_alive(character, year):
			continue
		if SafeDict.as_string(character.get("house"), "") == house:
			result.append(character_id)
	return result


func _is_royal(role: String) -> bool:
	return role == "ruler" or role == "heir" or role == "claimant" or role == "relative"


func _create_child(faction_id: String, father_id: String, mother_id: String, birth_year: int, characters: Dictionary) -> String:
	var base_id := "char_%s_%d" % [faction_id, birth_year]
	var child_id: String = base_id
	var counter: int = 1
	while characters.has(child_id):
		counter += 1
		child_id = "%s_%d" % [base_id, counter]
	var father: Dictionary = SafeDict.as_dict(characters.get(father_id, null))
	var mother: Dictionary = SafeDict.as_dict(characters.get(mother_id, null))
	var father_stats: Dictionary = SafeDict.as_dict(father.get("stats", null))
	var mother_stats: Dictionary = SafeDict.as_dict(mother.get("stats", null))
	var stats: Dictionary = {}
	for stat_name in ["command", "intrigue", "charisma", "loyalty", "education"]:
		var parent_average: float = (float(SafeDict.as_int(father_stats.get(stat_name), 50))
			+ float(SafeDict.as_int(mother_stats.get(stat_name), 50))) / 2.0
		var noise: int = GameState.rng.next_int(-3, 3)
		stats[stat_name] = clampi(int(roundf(parent_average)) + noise, 1, 100)
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var role: String = "relative"
	if SafeDict.as_string(faction.get("heir_id"), "") == "":
		role = "heir"
	var father_family: Dictionary = SafeDict.as_dict(father.get("family", null))
	var mother_family: Dictionary = SafeDict.as_dict(mother.get("family", null))
	var father_children: Array = SafeDict.as_array(father_family.get("children", null))
	father_children.append(child_id)
	father_family["children"] = father_children
	father["family"] = father_family
	var mother_children: Array = SafeDict.as_array(mother_family.get("children", null))
	mother_children.append(child_id)
	mother_family["children"] = mother_children
	mother["family"] = mother_family
	characters[child_id] = {
		"id": child_id,
		"name": "Vástago de %s" % SafeDict.as_string(father.get("name"), faction_id),
		"house": SafeDict.as_string(father.get("house"), ""),
		"faction": faction_id,
		"born": birth_year,
		"died": null,
		"role": role,
		"stats": stats,
		"traits": ["newborn"],
		"family": {
			"father": father_id,
			"mother": mother_id,
			"spouse": null,
			"children": [],
		},
		"claims": [],
		"source": "generated",
		"estimate": true,
		"alive": true,
		"age": 0,
	}
	if role == "heir":
		faction["heir_id"] = child_id
	return child_id


func _die(character_id: String, character: Dictionary, cause: String, year: int) -> Dictionary:
	character["alive"] = false
	character["died"] = year
	character["age"] = year - SafeDict.as_int(character.get("born"), year)
	emit_signal("character_died", character_id, cause)
	EventBus.emit_signal("character_died", character_id, cause)
	return _log_event("muerte_%s" % character_id,
		"Fallece %s (%s)." % [SafeDict.as_string(character.get("name"), character_id), cause])


func _educate_minors(factions: Dictionary, characters: Dictionary) -> void:
	for faction_id in SafeDict.sorted_keys(factions):
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		var minors: Array[String] = []
		for character_id in SafeDict.sorted_keys(characters):
			var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
			if SafeDict.as_string(character.get("faction"), "") != faction_id:
				continue
			if not SafeDict.as_bool(character.get("alive"), false):
				continue
			var age: int = SafeDict.as_int(character.get("age"), 0)
			if age < Constants.EDUCATION_MIN_AGE or age > Constants.EDUCATION_MAX_AGE:
				continue
			if not ELIGIBLE_ROLES.has(SafeDict.as_string(character.get("role"), "")):
				continue
			minors.append(character_id)
		if minors.is_empty():
			continue
		if not TurnManager.spend_pg_for(faction_id, Constants.EDUCATION_PG_COST):
			continue
		var stat_names: Array[String] = ["command", "intrigue", "charisma", "loyalty", "education"]
		for minor_id in minors:
			var minor: Dictionary = SafeDict.as_dict(characters.get(minor_id, null))
			var stats: Dictionary = SafeDict.as_dict(minor.get("stats", null))
			var chosen: String = stat_names[GameState.rng.next_int(0, stat_names.size() - 1)]
			stats[chosen] = clampi(SafeDict.as_int(stats.get(chosen), 1) + Constants.EDUCATION_STAT_GAIN, 1, 100)
			stats["education"] = clampi(SafeDict.as_int(stats.get("education"), 1) + Constants.EDUCATION_STAT_GAIN, 1, 100)
			minor["stats"] = stats


func _choose_heir(faction_id: String, characters: Dictionary, year: int, exclude_id: String = "") -> String:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var current_heir: String = SafeDict.as_string(faction.get("heir_id"), "")
	if current_heir != "" and current_heir != exclude_id:
		var heir: Dictionary = SafeDict.as_dict(characters.get(current_heir, null))
		if not heir.is_empty() and SafeDict.as_bool(heir.get("alive"), false) \
				and SafeDict.as_int(heir.get("born"), year) <= year:
			return current_heir
	# Hijo vivo más joven del gobernante (mayoría de edad no requerida).
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	var best_child: String = ""
	var best_born: int = 9999
	if ruler_id != "":
		var ruler: Dictionary = SafeDict.as_dict(characters.get(ruler_id, null))
		var family: Dictionary = SafeDict.as_dict(ruler.get("family", null))
		var children: Array = SafeDict.as_array(family.get("children", null))
		for child_value in children:
			var child_id: String = str(child_value)
			if child_id == exclude_id or child_id == ruler_id:
				continue
			var child: Dictionary = SafeDict.as_dict(characters.get(child_id, null))
			if child.is_empty() or not SafeDict.as_bool(child.get("alive"), false):
				continue
			if SafeDict.as_int(child.get("born"), 9999) > year:
				continue
			if SafeDict.as_int(child.get("born"), 9999) < best_born:
				best_born = SafeDict.as_int(child.get("born"), 9999)
				best_child = child_id
	if best_child != "":
		return best_child
	# Fase 2 (D-031, task-17): la sucesión se mantiene en la casa gobernante.
	var faction_house: String = SafeDict.as_string(faction.get("house"), "")
	if faction_house == "":
		# Sin información de casa: comportamiento clásico (cualquier pariente vivo).
		return _oldest_faction_relative(characters, faction_id, year, exclude_id)
	return _oldest_house_member(characters, faction_id, faction_house, year, exclude_id)


## Pariente vivo más antiguo de la facción (fallback sin información de casa).
func _oldest_faction_relative(characters: Dictionary, faction_id: String, year: int, exclude_id: String) -> String:
	var best_id: String = ""
	var best_born: int = 9999
	for character_id in SafeDict.sorted_keys(characters):
		if character_id == exclude_id:
			continue
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		if SafeDict.as_int(character.get("born"), 9999) > year:
			continue
		if SafeDict.as_int(character.get("born"), 9999) < best_born:
			best_born = SafeDict.as_int(character.get("born"), 9999)
			best_id = character_id
	return best_id


## Miembro vivo elegible más antiguo de la casa (prefiere la propia facción y,
## si no hay, otra facción == adopción dinástica).
func _oldest_house_member(characters: Dictionary, faction_id: String, house: String, year: int, exclude_id: String) -> String:
	var best_id: String = ""
	var best_born: int = 9999
	for character_id in SafeDict.sorted_keys(characters):
		if character_id == exclude_id:
			continue
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("house"), "") != house:
			continue
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		if SafeDict.as_int(character.get("born"), 9999) > year:
			continue
		if SafeDict.as_int(character.get("born"), 9999) < best_born:
			best_born = SafeDict.as_int(character.get("born"), 9999)
			best_id = character_id
	if best_id != "":
		return best_id
	# Miembro de la casa en otra facción: adopción dinástica (D-031).
	for character_id in SafeDict.sorted_keys(characters):
		if character_id == exclude_id:
			continue
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("house"), "") != house:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		if SafeDict.as_int(character.get("born"), 9999) > year:
			continue
		if SafeDict.as_int(character.get("born"), 9999) < best_born:
			best_born = SafeDict.as_int(character.get("born"), 9999)
			best_id = character_id
	return best_id


func _choose_regent(faction_id: String, characters: Dictionary, year: int, exclude_id: String) -> String:
	var preferred_roles: Array[String] = ["spouse", "relative", "general", "advisor", "heir"]
	for role in preferred_roles:
		for character_id in SafeDict.sorted_keys(characters):
			if character_id == exclude_id:
				continue
			var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
			if SafeDict.as_string(character.get("faction"), "") != faction_id:
				continue
			if SafeDict.as_string(character.get("role"), "") != role:
				continue
			if not SafeDict.as_bool(character.get("alive"), false):
				continue
			var age: int = year - SafeDict.as_int(character.get("born"), year)
			if age >= Constants.REGENCY_AGE:
				return character_id
	return ""


func _advance_interregna(factions: Dictionary, characters: Dictionary, year: int, events: Array[Dictionary]) -> void:
	for faction_id in SafeDict.sorted_keys(factions):
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		if SafeDict.as_string(faction.get("ruler_id"), "") != "":
			continue
		var interregnum_until: int = SafeDict.as_int(faction.get("interregnum_until"), 0)
		if interregnum_until == 0:
			continue
		var candidate: String = _choose_heir(faction_id, characters, year)
		if candidate != "":
			resolve_succession(faction_id)
			events.append(_log_event("fin_interregno_%s_%d" % [faction_id, year],
				"Termina el interregno en %s." % faction_id))
			continue
		if year >= interregnum_until:
			# Fase 2 (D-031, task-17): la casa solo cuenta por sus miembros vivos
			# en la propia facción; sin ellos, extinción aunque haya otras casas.
			var faction_house: String = SafeDict.as_string(faction.get("house"), "")
			var house_alive: bool = faction_house != "" \
				and not _faction_house_members_alive(characters, faction_id, faction_house, year).is_empty()
			if house_alive:
				faction["interregnum_until"] = year + Constants.INTERREGNUM_YEARS
				events.append(_log_event("interregno_prorrogado_%s_%d" % [faction_id, year],
					"El interregno de %s se prolonga: quedan parientes de la casa %s." % [faction_id, faction_house]))
			else:
				_extinguish(faction_id, events)
		else:
			EventBus.emit_signal("ui_notification",
				"%s sigue en interregno hasta %d." % [faction_id, interregnum_until], 1)


func _extinguish(faction_id: String, events: Array[Dictionary]) -> void:
	var st: Dictionary = GameState.state
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty():
		return
	faction["eliminated"] = true
	faction["ruler_id"] = ""
	faction["heir_id"] = ""
	faction["regent_id"] = ""
	faction["interregnum_until"] = 0
	# Ejércitos eliminados.
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") == faction_id:
			armies.erase(army_id)
	# Regiones: pasan al vecino más prestigioso o quedan independientes.
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		region["owner"] = _strongest_neighbour_owner(region_id, factions)
		region["support"] = Constants.REVOLT_SUPPORT_RESET
	emit_signal("dynasty_extinct", faction_id)
	EventBus.emit_signal("dynasty_extinct", faction_id)
	events.append(_log_event("extincion_%s" % faction_id,
		"La dinastía de %s se extingue: sus tierras quedan sin señor." % faction_id))
	EventBus.emit_signal("ui_notification",
		"La dinastía de %s se ha extinguido." % faction_id, 2)
	# Fase 2 (D-031/task-17): si es la facción del jugador, derrota inmediata y
	# reloj congelado (TurnManager comprueba game_over en sus avances).
	TurnManager.on_dynasty_extinct(faction_id)


func _strongest_neighbour_owner(region_id: String, factions: Dictionary) -> String:
	var definition: Dictionary = DataLoader.get_region(region_id)
	var adjacency: Array = SafeDict.as_array(definition.get("adjacency", null))
	var best_faction: String = ""
	var best_prestige: int = -1
	var regions: Dictionary = SafeDict.as_dict(GameState.state.get("regions", null))
	for neighbour_value in adjacency:
		var neighbour_id: String = str(neighbour_value)
		var neighbour: Dictionary = SafeDict.as_dict(regions.get(neighbour_id, null))
		var owner: String = SafeDict.as_string(neighbour.get("owner"), "")
		if owner == "" or not factions.has(owner):
			continue
		var owner_state: Dictionary = SafeDict.as_dict(factions.get(owner, null))
		if SafeDict.as_bool(owner_state.get("eliminated"), false):
			continue
		var prestige: int = SafeDict.as_int(owner_state.get("prestige"), 0) + GameState.rng.next_int(0, 5)
		if prestige > best_prestige:
			best_prestige = prestige
			best_faction = owner
	return best_faction


func _add_alliance(faction_a: String, faction_b: String) -> void:
	var state_a: Dictionary = GameState.get_faction_state(faction_a)
	var state_b: Dictionary = GameState.get_faction_state(faction_b)
	if state_a.is_empty() or state_b.is_empty():
		return
	var allies_a: Array = SafeDict.as_array(state_a.get("allies", null))
	if not allies_a.has(faction_b):
		allies_a.append(faction_b)
	state_a["allies"] = allies_a
	var allies_b: Array = SafeDict.as_array(state_b.get("allies", null))
	if not allies_b.has(faction_a):
		allies_b.append(faction_a)
	state_b["allies"] = allies_b
	EventBus.emit_signal("alliance_changed", faction_a, faction_b, true)


func _log_event(event_id: String, text: String) -> Dictionary:
	var entry: Dictionary = {
		"year": GameState.year,
		"quarter": GameState.quarter,
		"event_id": event_id,
		"text": text,
	}
	var st: Dictionary = GameState.state
	if not st.is_empty():
		var event_log: Array = SafeDict.as_array(st.get("event_log", null))
		event_log.append(entry)
		st["event_log"] = event_log
	return entry
