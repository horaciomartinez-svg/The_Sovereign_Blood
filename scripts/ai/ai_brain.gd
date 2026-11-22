extends RefCounted
## Cerebro de una facción IA (GDD §5.6): genera y puntúa órdenes candidatas.
##
## Decisión trimestral en 3 pasos (§5.6): (1) evaluar amenazas y oportunidades,
## (2) priorizar PG según perfil, (3) proponer 2-4 órdenes. `AIManager` ejecuta
## las de mayor utilidad hasta agotar órdenes/PG.
##
## Determinismo: la puntuación es puramente determinista (sin RNG), con desempate
## por clave estable, de modo que la IA es reproducible por semilla.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const AIProfiles = preload("res://scripts/ai/ai_profiles.gd")
const TechScript = preload("res://scripts/utils/tech.gd")


## Órdenes candidatas ordenadas de mayor a menor utilidad.
func plan(faction_id: String, profile: String, _max_orders: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	if st.is_empty():
		return candidates
	var profile_weights: Dictionary = AIProfiles.weights(profile)
	_collect_moves(faction_id, profile_weights, candidates)
	_collect_recruit(faction_id, profile_weights, candidates)
	_collect_diplomacy(faction_id, profile_weights, candidates)
	candidates.sort_custom(_compare_actions)
	return candidates


func _collect_moves(faction_id: String, weights: Dictionary, candidates: Array[Dictionary]) -> void:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		if SafeDict.as_int(army.get("movement_left"), 0) <= 0:
			continue
		var from_region: String = SafeDict.as_string(army.get("region_id"), "")
		var own_men: int = _army_men(army)
		if own_men <= 0:
			continue
		var adjacency: Array = SafeDict.as_array(DataLoader.get_region(from_region).get("adjacency", null))
		for neighbour_value in adjacency:
			var to_region: String = str(neighbour_value)
			var target: Dictionary = GameState.get_region_state(to_region)
			if target.is_empty():
				continue
			var owner: String = SafeDict.as_string(target.get("owner"), "")
			if owner == faction_id:
				continue
			# D-067: la IA no invade regiones de facciones con las que no está en
			# guerra (debe declararla antes); evita conquistas sorpresa imposibles.
			if owner != "" and not DiplomacySystem.are_at_war(faction_id, owner):
				continue
			var defense: int = _defense_men(owner, to_region)
			var terrain: String = SafeDict.as_string(target.get("terrain"), "plains")
			var cost_pg: int = Constants.MOVE_PG_COST \
				+ SafeDict.as_int(Constants.TERRAIN_MOVE_PENALTY.get(terrain), 0)
			var advantage: float = float(own_men - defense) / maxf(1.0, float(own_men))
			var utility: float = weights_territory(weights) * 2.0 * advantage
			if owner == "":
				utility += weights_prestige(weights) * 0.9
			else:
				utility += weights_security(weights) * 0.3
			if defense >= own_men:
				utility -= weights_security(weights) * 1.5
			utility -= float(cost_pg) * 0.05
			# D-073: la dificultad Principiante reduce la agresividad de la IA.
			if owner != "":
				utility *= _aggression_multiplier()
			candidates.append({
				"type": "move",
				"army_id": army_id,
				"to_region": to_region,
				"utility": snappedf(utility, 0.001),
				"cost_pg": cost_pg,
				"key": "move_%s_%s" % [army_id, to_region],
			})


func _collect_recruit(faction_id: String, weights: Dictionary, candidates: Array[Dictionary]) -> void:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty():
		return
	var gold: int = SafeDict.as_int(faction.get("gold"), 0)
	if gold < Constants.AI_RECRUIT_GOLD_MIN:
		return
	var st: Dictionary = GameState.state
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		if SafeDict.as_int(region.get("recruit_pool"), 0) < Constants.AI_RECRUIT_MEN:
			continue
		var unit_id: String = _best_unit_for(faction_id, region_id)
		if unit_id == "":
			continue
		var gold_cost: int = _recruit_gold_cost(unit_id, Constants.AI_RECRUIT_MEN)
		if gold_cost > gold:
			continue
		var has_army_slot: bool = false
		var armies_in_region: Array[Dictionary] = MilitarySystem.get_armies_in(region_id)
		for army_value in armies_in_region:
			var army: Dictionary = SafeDict.as_dict(army_value)
			if SafeDict.as_string(army.get("faction_id"), "") == faction_id:
				has_army_slot = true
				break
		if not has_army_slot:
			has_army_slot = MilitarySystem.get_army_slots(region_id) > 0
		if not has_army_slot:
			continue
		var utility: float = weights_security(weights) * 1.0 + weights_territory(weights) * 0.4 \
			- float(gold_cost) / maxf(1.0, float(gold)) * weights_gold(weights)
		candidates.append({
			"type": "recruit",
			"region_id": region_id,
			"unit_id": unit_id,
			"amount": Constants.AI_RECRUIT_MEN,
			"utility": snappedf(utility, 0.001),
			"cost_pg": 0,
			"key": "recruit_%s" % region_id,
		})
		return


func _collect_diplomacy(faction_id: String, weights: Dictionary, candidates: Array[Dictionary]) -> void:
	var targets: Array[String] = _neighbour_factions(faction_id)
	var own_strength: int = DiplomacySystem.get_strength(faction_id)
	for target_value in targets:
		var target: String = str(target_value)
		var relation: int = DiplomacySystem.get_relation(faction_id, target)
		var at_war: bool = DiplomacySystem.are_at_war(faction_id, target)
		var allied: bool = DiplomacySystem.are_allied(faction_id, target)
		var target_strength: int = DiplomacySystem.get_strength(target)
		if at_war:
			var peace_utility: float = weights_security(weights) * 1.7 - weights_territory(weights) * 1.1
			if own_strength < target_strength:
				peace_utility += weights_security(weights) * 0.8
			candidates.append({
				"type": "diplomacy",
				"action": "propose_peace",
				"target": target,
				"utility": snappedf(peace_utility, 0.001),
				"cost_pg": SafeDict.as_int(Constants.ACTION_PG_COSTS.get("propose_peace"), 4),
				"key": "peace_%s" % target,
			})
			continue
		if not allied and relation >= -20:
			var alliance_utility: float = weights_security(weights) * 1.2 + weights_gold(weights) * 0.4
			candidates.append({
				"type": "diplomacy",
				"action": "alliance",
				"target": target,
				"utility": snappedf(alliance_utility, 0.001),
				"cost_pg": SafeDict.as_int(Constants.ACTION_PG_COSTS.get("alliance"), 8),
				"key": "alliance_%s" % target,
			})
		var trade_utility: float = weights_gold(weights) * 1.5 + float(relation) / 100.0
		candidates.append({
			"type": "diplomacy",
			"action": "trade_pact",
			"target": target,
			"utility": snappedf(trade_utility, 0.001),
			"cost_pg": SafeDict.as_int(Constants.ACTION_PG_COSTS.get("trade_pact"), 6),
			"key": "trade_%s" % target,
		})
		if weights_territory(weights) >= 1.0 and own_strength > int(float(target_strength) * 1.2):
			var war_utility: float = weights_territory(weights) * 1.9 - weights_security(weights) * 0.4
			war_utility *= _aggression_multiplier()
			candidates.append({
				"type": "diplomacy",
				"action": "declare_war",
				"target": target,
				"utility": snappedf(war_utility, 0.001),
				"cost_pg": 0,
				"key": "war_%s" % target,
			})
		if weights_security(weights) >= 1.0 and relation < 0:
			var marriage_utility: float = weights_security(weights) * 0.8
			candidates.append({
				"type": "diplomacy",
				"action": "marriage",
				"target": target,
				"utility": snappedf(marriage_utility, 0.001),
				"cost_pg": SafeDict.as_int(Constants.ACTION_PG_COSTS.get("marriage"), 10),
				"key": "marriage_%s" % target,
			})


func _compare_actions(left: Dictionary, right: Dictionary) -> bool:
	var left_utility: float = SafeDict.as_float(left.get("utility"), 0.0)
	var right_utility: float = SafeDict.as_float(right.get("utility"), 0.0)
	if not is_equal_approx(left_utility, right_utility):
		return left_utility > right_utility
	return str(left.get("key", "")) < str(right.get("key", ""))


func _neighbour_factions(faction_id: String) -> Array[String]:
	var result: Array[String] = []
	var st: Dictionary = GameState.state
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var adjacency: Array = SafeDict.as_array(DataLoader.get_region(region_id).get("adjacency", null))
		for neighbour_value in adjacency:
			var neighbour_id: String = str(neighbour_value)
			var neighbour: Dictionary = GameState.get_region_state(neighbour_id)
			var owner: String = SafeDict.as_string(neighbour.get("owner"), "")
			if owner == "" or owner == faction_id:
				continue
			if not result.has(owner):
				result.append(owner)
	result.sort()
	return result


func _defense_men(faction_id: String, region_id: String) -> int:
	if faction_id == "":
		return 0
	var total: int = 0
	for army_value in MilitarySystem.get_armies_in(region_id):
		var army: Dictionary = SafeDict.as_dict(army_value)
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		var units: Array = SafeDict.as_array(army.get("units", null))
		for unit_value in units:
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			total += SafeDict.as_int(unit.get("size"), 0)
	return total


func _army_men(army: Dictionary) -> int:
	var total: int = 0
	var units: Array = SafeDict.as_array(army.get("units", null))
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		total += SafeDict.as_int(unit.get("size"), 0)
	return total


func _best_unit_for(faction_id: String, region_id: String) -> String:
	var st: Dictionary = GameState.state
	var year: int = SafeDict.as_int(st.get("year"), 1337)
	var best_unit: String = ""
	var best_strength: int = -1
	for unit_id in DataLoader.get_unit_ids():
		var definition: Dictionary = DataLoader.get_unit(unit_id)
		var tags: Array = SafeDict.as_array(definition.get("faction_tags", null))
		if not tags.is_empty() and not tags.has(faction_id):
			continue
		# D-059: era/año centralizados en Tech.
		if not TechScript.is_unit_available(definition, year):
			continue
		var strength: int = SafeDict.as_int(definition.get("strength"), 0)
		if strength > best_strength:
			best_strength = strength
			best_unit = unit_id
	if best_unit == "":
		return ""
	var cost: Dictionary = SafeDict.as_dict(DataLoader.get_unit(best_unit).get("cost", null))
	var gold_cost: int = int(ceilf(float(Constants.AI_RECRUIT_MEN) / float(Constants.UNIT_MEN_PER_BLOCK))) \
		* SafeDict.as_int(cost.get("gold"), 0)
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if gold_cost > SafeDict.as_int(faction.get("gold"), 0):
		return ""
	return best_unit


func _recruit_gold_cost(unit_id: String, amount: int) -> int:
	var definition: Dictionary = DataLoader.get_unit(unit_id)
	var cost: Dictionary = SafeDict.as_dict(definition.get("cost", null))
	var blocks: int = int(ceilf(float(amount) / float(Constants.UNIT_MEN_PER_BLOCK)))
	return blocks * SafeDict.as_int(cost.get("gold"), 0)


# Helpers de pesos con nombre (claridad de fórmulas).
func weights_gold(weights: Dictionary) -> float:
	return SafeDict.as_float(weights.get("gold"), 0.8)


func weights_territory(weights: Dictionary) -> float:
	return SafeDict.as_float(weights.get("territory"), 0.8)


## D-073: multiplicador de agresividad según dificultad de la partida.
func _aggression_multiplier() -> float:
	var difficulty: String = "normal"
	if not GameState.state.is_empty():
		difficulty = str(GameState.state.get("difficulty", "normal"))
	if difficulty == "beginner":
		return Constants.AI_AGGRESSION_BEGINNER
	return Constants.AI_AGGRESSION_NORMAL


func weights_security(weights: Dictionary) -> float:
	return SafeDict.as_float(weights.get("security"), 0.8)


func weights_prestige(weights: Dictionary) -> float:
	return SafeDict.as_float(weights.get("prestige"), 0.8)
