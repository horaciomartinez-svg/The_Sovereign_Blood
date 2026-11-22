extends Node
## DiplomacySystem — relaciones bilaterales y acciones diplomáticas (GDD §5.4, §8.2).
##
## Relación bilateral −100..100. Las 7 acciones de §5.4 con sus costes PG exactos
## (ACTION_PG_COSTS). La aceptación se decide con una puntuación determinista
## (§5.6: relación + perfil del receptor + fuerza relativa), sin RNG, para que
## las partidas y los tests sean reproducibles.

signal proposal_sent(actor: String, target: String, action: String)
signal proposal_resolved(actor: String, target: String, action: String, accepted: bool)
signal relation_changed(faction_a: String, faction_b: String, value: int)
signal war_declared(attacker: String, defender: String)
signal peace_made(faction_a: String, faction_b: String)
signal alliance_changed(faction_a: String, faction_b: String, allied: bool)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const EventResolverScript = preload("res://scripts/utils/event_resolver.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")

## Coste en PG por acción diplomática (GDD §5.4). `espia` = espionaje Fase 2.
const ACTION_PG_COSTS: Dictionary = {
	"alliance": 8,
	"marriage": 10,
	"trade_pact": 6,
	"demand_tribute": 5,
	"offer_tribute": 3,
	"declare_war": 0,
	"propose_peace": 4,
	"espia": 6,
}


## Propuesta diplomática: {ok, cost_pg, accepted, reason}.
func propose(actor: String, target: String, action: Dictionary) -> Dictionary:
	var action_type: String = SafeDict.as_string(action.get("type"), SafeDict.as_string(action.get("action"), ""))
	var cost_pg: int = get_action_cost(action_type)
	var result: Dictionary = {
		"ok": false,
		"cost_pg": cost_pg,
		"accepted": false,
		"reason": "",
	}
	var st: Dictionary = GameState.state
	if st.is_empty():
		result["reason"] = "no_game"
		return result
	if action_type == "" or cost_pg < 0:
		result["reason"] = "unknown_action"
		return result
	if actor == target:
		result["reason"] = "same_faction"
		return result
	var faction_actor: Dictionary = GameState.get_faction_state(actor)
	var faction_target: Dictionary = GameState.get_faction_state(target)
	if faction_actor.is_empty() or faction_target.is_empty():
		result["reason"] = "unknown_faction"
		return result
	if SafeDict.as_bool(faction_actor.get("eliminated"), false) or SafeDict.as_bool(faction_target.get("eliminated"), false):
		result["reason"] = "eliminated"
		return result
	# El matrimonio cobra su PG dentro de DynastySystem.marry (evita doble cobro).
	if cost_pg > 0 and action_type != "marriage" and not TurnManager.spend_pg_for(actor, cost_pg):
		result["reason"] = "pg"
		return result

	emit_signal("proposal_sent", actor, target, action_type)
	EventBus.emit_signal("proposal_sent", actor, target, action_type)

	match action_type:
		"declare_war":
			_propose_war(actor, target, action, result)
		"propose_peace":
			_propose_peace(actor, target, result)
		"alliance":
			_propose_alliance(actor, target, result)
		"trade_pact":
			_propose_trade_pact(actor, target, result)
		"marriage":
			_propose_marriage(actor, target, action, result)
		"demand_tribute":
			_propose_demand_tribute(actor, target, result)
		"offer_tribute":
			_propose_offer_tribute(actor, target, result)
		"espia":
			_propose_espionage(actor, target, result)
		_:
			result["reason"] = "unknown_action"
			return result

	emit_signal("proposal_resolved", actor, target, action_type, SafeDict.as_bool(result.get("accepted"), false))
	EventBus.emit_signal("proposal_resolved", actor, target, action_type, SafeDict.as_bool(result.get("accepted"), false))
	return result


## Relación bilateral −100..100 (0 = neutral).
func get_relation(faction_a: String, faction_b: String) -> int:
	var faction: Dictionary = GameState.get_faction_state(faction_a)
	var relations: Dictionary = SafeDict.as_dict(faction.get("relations", null))
	if relations.has(faction_b):
		return SafeDict.as_int(relations.get(faction_b), 0)
	var reverse: Dictionary = GameState.get_faction_state(faction_b)
	var reverse_relations: Dictionary = SafeDict.as_dict(reverse.get("relations", null))
	return SafeDict.as_int(reverse_relations.get(faction_a), 0)


func set_relation(faction_a: String, faction_b: String, value: int) -> void:
	var clamped: int = clampi(value, Constants.RELATION_MIN, Constants.RELATION_MAX)
	for pair in [[faction_a, faction_b], [faction_b, faction_a]]:
		var faction: Dictionary = GameState.get_faction_state(str(pair[0]))
		if faction.is_empty():
			continue
		var relations: Dictionary = SafeDict.as_dict(faction.get("relations", null))
		relations[str(pair[1])] = clamped
		faction["relations"] = relations
	emit_signal("relation_changed", faction_a, faction_b, clamped)
	EventBus.emit_signal("relation_changed", faction_a, faction_b, clamped)


func are_at_war(faction_a: String, faction_b: String) -> bool:
	var faction: Dictionary = GameState.get_faction_state(faction_a)
	var at_war: Array = SafeDict.as_array(faction.get("at_war", null))
	return at_war.has(faction_b)


func are_allied(faction_a: String, faction_b: String) -> bool:
	var faction: Dictionary = GameState.get_faction_state(faction_a)
	var allies: Array = SafeDict.as_array(faction.get("allies", null))
	return allies.has(faction_b)


## Coste en PG de una acción de GDD §5.4 (-1 si la acción no existe).
func get_action_cost(action_id: String) -> int:
	if not ACTION_PG_COSTS.has(action_id):
		return -1
	return SafeDict.as_int(ACTION_PG_COSTS.get(action_id), -1)


## Declara la guerra (sin coste PG; aplica la penalización por falta de casus belli).
func declare_war(attacker: String, defender: String) -> bool:
	return begin_hostilities(attacker, defender)


## Inicia hostilidades entre dos facciones (usado también por MilitarySystem al
## invadir una región enemiga). Devuelve true si la guerra es nueva.
func begin_hostilities(attacker: String, defender: String) -> bool:
	var st: Dictionary = GameState.state
	if st.is_empty() or attacker == defender:
		return false
	var faction_attacker: Dictionary = GameState.get_faction_state(attacker)
	var faction_defender: Dictionary = GameState.get_faction_state(defender)
	if faction_attacker.is_empty() or faction_defender.is_empty():
		return false
	if are_at_war(attacker, defender):
		return false
	var casus_belli: Dictionary = SafeDict.as_dict(faction_attacker.get("casus_belli", null))
	if not casus_belli.has(defender):
		faction_attacker["prestige"] = maxi(0,
			SafeDict.as_int(faction_attacker.get("prestige"), 0) - Constants.WAR_WITHOUT_CASUS_BELLI_PRESTIGE_LOSS)
	_add_to_array(faction_attacker, "at_war", defender)
	_add_to_array(faction_defender, "at_war", attacker)
	# Una alianza rota por la guerra deja de estar activa.
	_remove_from_array(faction_attacker, "allies", defender)
	_remove_from_array(faction_defender, "allies", attacker)
	set_relation(attacker, defender, get_relation(attacker, defender) - 20)
	emit_signal("war_declared", attacker, defender)
	EventBus.emit_signal("war_declared", attacker, defender)
	EventResolverScript.new().resolve_war(attacker, defender, SafeDict.as_int(st.get("year"), 1337))
	return true


## Termina una guerra activa.
func end_war(faction_a: String, faction_b: String) -> bool:
	var faction_a_state: Dictionary = GameState.get_faction_state(faction_a)
	var faction_b_state: Dictionary = GameState.get_faction_state(faction_b)
	if faction_a_state.is_empty() or faction_b_state.is_empty():
		return false
	if not are_at_war(faction_a, faction_b):
		return false
	_remove_from_array(faction_a_state, "at_war", faction_b)
	_remove_from_array(faction_b_state, "at_war", faction_a)
	set_relation(faction_a, faction_b, get_relation(faction_a, faction_b) + Constants.PEACE_RELATION_BONUS)
	emit_signal("peace_made", faction_a, faction_b)
	EventBus.emit_signal("peace_made", faction_a, faction_b)
	return true


func has_casus_belli(faction_id: String, target_id: String) -> bool:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var casus_belli: Dictionary = SafeDict.as_dict(faction.get("casus_belli", null))
	return casus_belli.has(target_id)


## Fuerza militar total (hombres) de una facción; base de la puntuación §5.6.
func get_strength(faction_id: String) -> int:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var total: int = 0
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		var units: Array = SafeDict.as_array(army.get("units", null))
		for unit_value in units:
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			total += SafeDict.as_int(unit.get("size"), 0)
	return total


## Puntuación de aceptación §5.6 (relación + perfil + fuerza relativa).
func compute_acceptance(actor: String, target: String, action_type: String) -> int:
	var relation: int = get_relation(actor, target)
	var score: int = relation
	var profile: String = "balanced"
	var target_state: Dictionary = GameState.get_faction_state(target)
	profile = SafeDict.as_string(target_state.get("profile"), "balanced")
	match profile:
		"merchant":
			if action_type == "trade_pact":
				score += 45
			elif action_type == "alliance":
				score += 10
		"aggressor":
			if action_type == "alliance":
				score -= 20
			elif action_type == "propose_peace":
				score -= 25
			elif action_type == "demand_tribute":
				score -= 15
		"dynastic":
			if action_type == "marriage":
				score += 35
			elif action_type == "alliance":
				score += 15
		"survivor":
			if action_type == "alliance":
				score += 25
			elif action_type == "propose_peace":
				score += 30
	var actor_strength: int = get_strength(actor)
	var target_strength: int = get_strength(target)
	if actor_strength > 0:
		if action_type == "demand_tribute" or action_type == "propose_peace" or action_type == "alliance":
			if float(target_strength) < float(actor_strength) * 0.75:
				score += 20
	if target_strength > 0 and float(actor_strength) < float(target_strength) * 0.5:
		score -= 15
	return score


# ---------------------------------------------------------------------------
# Acciones internas
# ---------------------------------------------------------------------------

func _propose_war(actor: String, target: String, action: Dictionary, result: Dictionary) -> void:
	if are_at_war(actor, target):
		result["reason"] = "already_at_war"
		return
	if are_allied(actor, target):
		result["reason"] = "allied"
		return
	var forced_casus: bool = SafeDict.as_bool(action.get("casus_belli"), false)
	if forced_casus:
		var faction: Dictionary = GameState.get_faction_state(actor)
		var casus_belli: Dictionary = SafeDict.as_dict(faction.get("casus_belli", null))
		casus_belli[target] = true
		faction["casus_belli"] = casus_belli
	begin_hostilities(actor, target)
	result["ok"] = true
	result["accepted"] = true
	result["reason"] = "declared_war"


func _propose_peace(actor: String, target: String, result: Dictionary) -> void:
	if not are_at_war(actor, target):
		result["reason"] = "not_at_war"
		return
	var score: int = compute_acceptance(actor, target, "propose_peace")
	var accepted: bool = score >= -30
	result["ok"] = true
	result["accepted"] = accepted
	result["reason"] = "accepted" if accepted else "rejected"
	if accepted:
		end_war(actor, target)


func _propose_alliance(actor: String, target: String, result: Dictionary) -> void:
	if are_at_war(actor, target):
		result["reason"] = "at_war"
		return
	if are_allied(actor, target):
		result["reason"] = "already_allied"
		return
	var score: int = compute_acceptance(actor, target, "alliance")
	var accepted: bool = score >= 10
	result["ok"] = true
	result["accepted"] = accepted
	result["reason"] = "accepted" if accepted else "rejected"
	if accepted:
		var faction_actor: Dictionary = GameState.get_faction_state(actor)
		var faction_target: Dictionary = GameState.get_faction_state(target)
		_add_to_array(faction_actor, "allies", target)
		_add_to_array(faction_target, "allies", actor)
		set_relation(actor, target, get_relation(actor, target) + Constants.ALLIANCE_RELATION_BONUS)
		emit_signal("alliance_changed", actor, target, true)
		EventBus.emit_signal("alliance_changed", actor, target, true)


func _propose_trade_pact(actor: String, target: String, result: Dictionary) -> void:
	if are_at_war(actor, target):
		result["reason"] = "at_war"
		return
	var score: int = compute_acceptance(actor, target, "trade_pact")
	var accepted: bool = score >= -10
	result["ok"] = true
	result["accepted"] = accepted
	result["reason"] = "accepted" if accepted else "rejected"
	if accepted:
		var faction_actor: Dictionary = GameState.get_faction_state(actor)
		var faction_target: Dictionary = GameState.get_faction_state(target)
		_add_to_array(faction_actor, "trade_pacts", target)
		_add_to_array(faction_target, "trade_pacts", actor)
		set_relation(actor, target, get_relation(actor, target) + Constants.TRADE_PACT_RELATION_BONUS)


func _propose_marriage(actor: String, target: String, action: Dictionary, result: Dictionary) -> void:
	var actor_character: String = SafeDict.as_string(action.get("character"), "")
	if actor_character == "":
		actor_character = _marriage_candidate(actor)
	var target_character: String = SafeDict.as_string(action.get("target_character"), "")
	if target_character == "":
		target_character = _marriage_candidate(target)
	if actor_character == "" or target_character == "":
		result["reason"] = "no_candidate"
		return
	var score: int = compute_acceptance(actor, target, "marriage") + 20
	var accepted: bool = score >= 10
	result["ok"] = true
	result["accepted"] = accepted
	result["reason"] = "accepted" if accepted else "rejected"
	result["character"] = actor_character
	result["target_character"] = target_character
	if accepted:
		var marriage: Dictionary = DynastySystem.marry(actor_character, target_character)
		result["ok"] = SafeDict.as_bool(marriage.get("ok"), false)
		result["accepted"] = result["ok"]
		result["reason"] = SafeDict.as_string(marriage.get("reason"), "rejected")
		result["alliance"] = SafeDict.as_string(marriage.get("alliance"), "")
		result["claim"] = SafeDict.as_dict(marriage.get("claim", null))


func _propose_demand_tribute(actor: String, target: String, result: Dictionary) -> void:
	if are_at_war(actor, target):
		result["reason"] = "at_war"
		return
	var score: int = compute_acceptance(actor, target, "demand_tribute")
	var accepted: bool = score >= 30
	result["ok"] = true
	result["accepted"] = accepted
	result["reason"] = "accepted" if accepted else "rejected"
	var faction_actor: Dictionary = GameState.get_faction_state(actor)
	var faction_target: Dictionary = GameState.get_faction_state(target)
	if accepted:
		var target_gold: int = SafeDict.as_int(faction_target.get("gold"), 0)
		var amount: int = mini(target_gold, Constants.DEMAND_TRIBUTE_GOLD)
		faction_target["gold"] = target_gold - amount
		faction_actor["gold"] = SafeDict.as_int(faction_actor.get("gold"), 0) + amount
		set_relation(actor, target, get_relation(actor, target) - 10)
	elif get_relation(actor, target) < -20:
		begin_hostilities(actor, target)
		result["reason"] = "rejected_war"


func _propose_offer_tribute(actor: String, target: String, result: Dictionary) -> void:
	if are_at_war(actor, target):
		result["reason"] = "at_war"
		return
	var faction_actor: Dictionary = GameState.get_faction_state(actor)
	var faction_target: Dictionary = GameState.get_faction_state(target)
	var actor_gold: int = SafeDict.as_int(faction_actor.get("gold"), 0)
	if actor_gold < Constants.TRIBUTE_GOLD:
		result["reason"] = "no_gold"
		return
	faction_actor["gold"] = actor_gold - Constants.TRIBUTE_GOLD
	faction_target["gold"] = SafeDict.as_int(faction_target.get("gold"), 0) + Constants.TRIBUTE_GOLD
	set_relation(actor, target, get_relation(actor, target) + Constants.TRIBUTE_RELATION_BONUS)
	result["ok"] = true
	result["accepted"] = true
	result["reason"] = "accepted"


## Espionaje (Fase 2, D-030): 6 PG; éxito por Astucia del actor y relación.
## En éxito guarda el informe en state.factions[actor].intel[target] (serializable).
func _propose_espionage(actor: String, target: String, result: Dictionary) -> void:
	var st: Dictionary = GameState.state
	var faction_actor: Dictionary = GameState.get_faction_state(actor)
	if faction_actor.is_empty():
		result["reason"] = "unknown_faction"
		return
	var intrigue: int = _best_intrigue(actor)
	var relation: int = get_relation(actor, target)
	var chance: float = clampf(
		Constants.ESPIONAGE_BASE_CHANCE
		+ float(intrigue) / Constants.ESPIONAGE_INTRIGUE_DIVISOR
		+ float(relation) / Constants.ESPIONAGE_RELATION_DIVISOR,
		Constants.ESPIONAGE_MIN_CHANCE, Constants.ESPIONAGE_MAX_CHANCE)
	if GameState.rng == null:
		GameState.rng = SeededRNGScript.new(GameState.rng_seed)
	var success: bool = GameState.rng.next_float() < chance
	result["ok"] = true
	result["chance"] = snappedf(chance, 0.001)
	var status_text: String = "descubierto"
	if success:
		var intel: Dictionary = _build_intel(actor, target)
		var intel_map: Dictionary = SafeDict.as_dict(faction_actor.get("intel", null))
		intel_map[target] = intel
		faction_actor["intel"] = intel_map
		result["accepted"] = true
		result["reason"] = "success"
		result["intel"] = intel
		status_text = "éxito"
		EventBus.emit_signal("ui_notification",
			"El espía de %s informa sobre %s." % [actor, target], 1)
	else:
		result["accepted"] = false
		result["reason"] = "failed"
		result["intel"] = {}
		set_relation(actor, target, relation - 5)
		EventBus.emit_signal("ui_notification",
			"Un espía de %s fue descubierto en %s." % [actor, target], 2)
	var entry: Dictionary = {
		"year": SafeDict.as_int(st.get("year"), 0),
		"quarter": SafeDict.as_int(st.get("quarter"), 0),
		"event_id": "espionaje_%s_%s" % [actor, target],
		"text": "Espionaje de %s sobre %s: %s" % [actor, target, status_text],
	}
	var event_log: Array = SafeDict.as_array(st.get("event_log", null))
	event_log.append(entry)
	st["event_log"] = event_log


## Mejor Astucia disponible en la facción (gobernante o cortesano).
func _best_intrigue(faction_id: String) -> int:
	var st: Dictionary = GameState.state
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	var ruler: Dictionary = SafeDict.as_dict(characters.get(ruler_id, null))
	var best: int = 0
	if not ruler.is_empty() and SafeDict.as_bool(ruler.get("alive"), false):
		best = SafeDict.as_int(SafeDict.as_dict(ruler.get("stats", null)).get("intrigue"), 0)
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		best = maxi(best, SafeDict.as_int(SafeDict.as_dict(character.get("stats", null)).get("intrigue"), 0))
	return best


## Informe de espionaje serializable (ejércitos, tesoro, regente, guerras).
func _build_intel(actor: String, target: String) -> Dictionary:
	var st: Dictionary = GameState.state
	var faction_target: Dictionary = GameState.get_faction_state(target)
	var armies_intel: Array = []
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != target:
			continue
		armies_intel.append({
			"id": army_id,
			"region_id": SafeDict.as_string(army.get("region_id"), ""),
			"men": _army_men_value(army),
			"units": SafeDict.as_array(army.get("units", null)).size(),
			"leader_id": SafeDict.as_string(army.get("leader_id"), ""),
		})
	return {
		"target": target,
		"armies": armies_intel,
		"army_count": armies_intel.size(),
		"treasury": SafeDict.as_int(faction_target.get("gold"), 0),
		"regent_id": SafeDict.as_string(faction_target.get("regent_id"), ""),
		"at_war": SafeDict.as_array(faction_target.get("at_war", null)).duplicate(),
		"ruler_id": SafeDict.as_string(faction_target.get("ruler_id"), ""),
		"heir_id": SafeDict.as_string(faction_target.get("heir_id"), ""),
		"prestige": SafeDict.as_int(faction_target.get("prestige"), 0),
		"year": SafeDict.as_int(st.get("year"), 0),
		"quarter": SafeDict.as_int(st.get("quarter"), 0),
		"source": "espia",
	}


func _army_men_value(army: Dictionary) -> int:
	var total: int = 0
	for unit_value in SafeDict.as_array(army.get("units", null)):
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		total += SafeDict.as_int(unit.get("size"), 0)
	return total


func _marriage_candidate(faction_id: String) -> String:
	var st: Dictionary = GameState.state
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var current_year: int = SafeDict.as_int(st.get("year"), 1337)
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	var candidates: Array[String] = [ruler_id, SafeDict.as_string(faction.get("heir_id"), "")]
	for candidate_id in candidates:
		if candidate_id == "":
			continue
		var character: Dictionary = SafeDict.as_dict(characters.get(candidate_id, null))
		if character.is_empty() or not SafeDict.as_bool(character.get("alive"), false):
			continue
		var age: int = current_year - SafeDict.as_int(character.get("born"), current_year)
		if age < Constants.MARRIAGE_MIN_AGE:
			continue
		var family: Dictionary = SafeDict.as_dict(character.get("family", null))
		if SafeDict.as_string(family.get("spouse"), "") == "":
			return candidate_id
	for character_id in SafeDict.sorted_keys(characters):
		var character: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		var role: String = SafeDict.as_string(character.get("role"), "")
		if role != "relative" and role != "heir" and role != "claimant":
			continue
		var age: int = current_year - SafeDict.as_int(character.get("born"), current_year)
		if age < Constants.MARRIAGE_MIN_AGE:
			continue
		var family: Dictionary = SafeDict.as_dict(character.get("family", null))
		if SafeDict.as_string(family.get("spouse"), "") == "":
			return character_id
	return ""


func _add_to_array(owner: Dictionary, key: String, value: String) -> void:
	var items: Array = SafeDict.as_array(owner.get(key, null))
	if not items.has(value):
		items.append(value)
	owner[key] = items


func _remove_from_array(owner: Dictionary, key: String, value: String) -> void:
	var items: Array = SafeDict.as_array(owner.get(key, null))
	var filtered: Array = []
	for item in items:
		if str(item) != value:
			filtered.append(item)
	owner[key] = filtered
