extends Node
## BattleManager — fachada única para los 3 niveles de batalla (GDD §6, §8.2).
##
## Fase 1 implementa el Nivel 1 (combate delegado, §6.1):
##   Poder = Σ(fuerza × moral × veterania) × moral_apoyo × comandante × terreno
##   comandante = 1 + (Mando − 50)/200
##   moral_apoyo = 0.5 + apoyo/200 (clampeada)
##   tirada gaussiana μ=1 σ=0.15 desde GameState.rng
##   hasta 5 asaltos; retirada si <25% de efectivos o moral rota (<0.3)
##   15% de muerte/cautiverio del líder derrotado; captura de región con botín.
## Niveles 2/3 son Fase 2 (`launch_tactical` devuelve null).

signal battle_started(attacker_faction: String, defender_faction: String, region_id: String)
signal battle_resolved(report: Dictionary)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")

const STANCE_DEFENSIVE: int = 0
const STANCE_BALANCED: int = 1
const STANCE_OFFENSIVE: int = 2

const MAX_ASSAULTS: int = 5
const RETREAT_THRESHOLD: float = 0.25

const ARMY_SCRIPT = preload("res://scripts/model/army.gd")
const REGION_SCRIPT = preload("res://scripts/model/region_state.gd")
const REPORT_SCRIPT = preload("res://scripts/model/battle_report.gd")


## Poder estimado de un ejército (fórmula GDD §6.1).
func estimate_power(army: ARMY_SCRIPT, region: REGION_SCRIPT, is_attacker: bool) -> float:
	if army == null:
		return 0.0
	var commander_bonus: float = _commander_bonus(army.leader_id)
	var support: int = _support_reference(army.faction_id, region, is_attacker)
	var morale_factor: float = clampf(0.5 + float(support) / 200.0, 0.5, 1.0)
	var army_morale: float = clampf(army.morale, 0.0, 1.0)
	var unit_power: float = 0.0
	for unit_value in army.units:
		var size: int = SafeDict.as_int(_unit_field(unit_value, "size", 0), 0)
		var strength: int = SafeDict.as_int(_unit_field(unit_value, "strength", 1), 1)
		var unit_morale: float = SafeDict.as_float(_unit_field(unit_value, "morale", 1.0), 1.0)
		var experience: int = SafeDict.as_int(_unit_field(unit_value, "experience", 0), 0)
		var veterancy: float = 1.0 + (float(experience) - 50.0) / 200.0
		unit_power += float(strength) * (float(size) / 100.0) * clampf(unit_morale, 0.0, 1.0) * veterancy
	var power: float = unit_power * morale_factor * army_morale * commander_bonus
	if not is_attacker and region != null:
		power *= _terrain_defense(region.terrain)
	return maxf(power, 0.0)


## Nivel 1 — combate delegado. Devuelve un BattleReport (GDD §6.1).
func resolve_delegated(
		attacker_army: ARMY_SCRIPT,
		defender_army: ARMY_SCRIPT,
		region: REGION_SCRIPT,
		stance: int) -> REPORT_SCRIPT:
	var report: REPORT_SCRIPT = REPORT_SCRIPT.new()
	if attacker_army == null or defender_army == null:
		return report
	report.attacker_faction = attacker_army.faction_id
	report.defender_faction = defender_army.faction_id
	report.region_id = region.id if region != null else defender_army.region_id
	var rng = GameState.rng
	if rng == null:
		rng = SeededRNGScript.new(GameState.rng_seed)
	report.attacker_start_power = snappedf(estimate_power(attacker_army, region, true), 0.01)
	report.defender_start_power = snappedf(estimate_power(defender_army, region, false), 0.01)
	var attacker_start_men: int = _men(attacker_army)
	var defender_start_men: int = _men(defender_army)
	if attacker_start_men <= 0 or defender_start_men <= 0:
		report.winner_faction = attacker_army.faction_id if defender_start_men <= 0 else defender_army.faction_id
		report.region_captured = defender_start_men <= 0
		report.notes = "Sin combatientes: la región se rinde."
		return report
	var stance_coefficient: float = _stance_coefficient(stance)
	var winner: String = ""
	var round_index: int = 0
	while round_index < Constants.MAX_ASSAULTS:
		round_index += 1
		var attacker_power: float = estimate_power(attacker_army, region, true)
		var defender_power: float = estimate_power(defender_army, region, false)
		if attacker_power <= 0.0 or defender_power <= 0.0:
			break
		var men_attacker_before: int = _men(attacker_army)
		var men_defender_before: int = _men(defender_army)
		var roll_attacker: float = rng.gaussian(1.0, 0.15)
		var roll_defender: float = rng.gaussian(1.0, 0.15)
		var damage_attacker: float = attacker_power * roll_attacker * stance_coefficient
		var damage_defender: float = defender_power * roll_defender
		var defender_loss_fraction: float = clampf(
			damage_attacker / maxf(defender_power, 1.0) * Constants.BATTLE_LOSS_COEF,
			0.0, Constants.BATTLE_MAX_LOSS_FRACTION)
		var attacker_loss_fraction: float = clampf(
			damage_defender / maxf(attacker_power, 1.0) * Constants.BATTLE_LOSS_COEF,
			0.0, Constants.BATTLE_MAX_LOSS_FRACTION)
		_apply_losses(defender_army, defender_loss_fraction)
		_apply_losses(attacker_army, attacker_loss_fraction)
		report.rounds.append({
			"round": round_index,
			"attacker_power": snappedf(attacker_power, 0.01),
			"defender_power": snappedf(defender_power, 0.01),
			"attacker_losses": maxi(0, men_attacker_before - _men(attacker_army)),
			"defender_losses": maxi(0, men_defender_before - _men(defender_army)),
			"attacker_morale": snappedf(attacker_army.morale, 0.001),
			"defender_morale": snappedf(defender_army.morale, 0.001),
		})
		var attacker_broken: bool = _is_broken(attacker_army, attacker_start_men)
		var defender_broken: bool = _is_broken(defender_army, defender_start_men)
		if defender_broken and not attacker_broken:
			winner = attacker_army.faction_id
			break
		if attacker_broken:
			winner = defender_army.faction_id
			break
	if winner == "":
		# Sin retirada clara tras 5 asaltos: gana quien conserve más proporción.
		var attacker_ratio: float = float(_men(attacker_army)) / float(maxi(1, attacker_start_men))
		var defender_ratio: float = float(_men(defender_army)) / float(maxi(1, defender_start_men))
		if attacker_ratio > defender_ratio:
			winner = attacker_army.faction_id
		else:
			winner = defender_army.faction_id
	report.winner_faction = winner
	report.attacker_losses = maxi(0, attacker_start_men - _men(attacker_army))
	report.defender_losses = maxi(0, defender_start_men - _men(defender_army))
	report.attacker_start_power = snappedf(report.attacker_start_power, 0.01)
	report.defender_start_power = snappedf(report.defender_start_power, 0.01)
	var attacker_won: bool = winner == attacker_army.faction_id
	report.region_captured = attacker_won
	if attacker_won and region != null:
		report.loot_gold = int(roundf(float(region.base_wealth) * Constants.LOOT_GOLD_PER_WEALTH))
	# Suerte del líder derrotado (15%: mitad muerte, mitad cautiverio).
	var loser_army: ARMY_SCRIPT = attacker_army if not attacker_won else defender_army
	var loser_leader: String = loser_army.leader_id
	if loser_leader != "" and rng.next_float() < Constants.BATTLE_DEATH_CHANCE:
		if rng.next_float() < 0.5:
			report.leader_captured = true
		else:
			report.leader_killed = true
	report.notes = _build_notes(report, attacker_won, stance)
	emit_signal("battle_resolved", report.to_dict())
	return report


## Nivel 2 — mapa táctico de ejércitos (Fase 2; devuelve null en Fase 1).
func launch_tactical(
		_attacker_army: ARMY_SCRIPT,
		_defender_army: ARMY_SCRIPT,
		_region: REGION_SCRIPT) -> Node:
	return null


# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

func _commander_bonus(leader_id: String) -> float:
	if leader_id == "":
		return 1.0
	var leader: Dictionary = GameState.get_character_state(leader_id)
	if leader.is_empty():
		return 1.0
	var stats: Dictionary = SafeDict.as_dict(leader.get("stats", null))
	var command: int = SafeDict.as_int(stats.get("command"), Constants.BATTLE_COMMANDER_STAT_BASE)
	return 1.0 + (float(command) - 50.0) / Constants.BATTLE_COMMANDER_STAT_RANGE


## Apoyo de referencia: defensa = apoyo de la región; ataque = media del atacante.
func _support_reference(faction_id: String, region: REGION_SCRIPT, is_attacker: bool) -> int:
	if not is_attacker and region != null:
		return region.support
	var st: Dictionary = GameState.state
	if st.is_empty():
		return Constants.SUPPORT_DEFAULT
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var total: int = 0
	var count: int = 0
	for region_id in SafeDict.sorted_keys(regions):
		var region_state: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region_state.get("owner"), "") != faction_id:
			continue
		total += SafeDict.as_int(region_state.get("support"), Constants.SUPPORT_DEFAULT)
		count += 1
	if count == 0:
		return Constants.SUPPORT_DEFAULT
	return int(roundf(float(total) / float(count)))


func _terrain_defense(terrain: String) -> float:
	return SafeDict.as_float(Constants.TERRAIN_DEFENSE.get(terrain), 1.0)


func _stance_coefficient(stance: int) -> float:
	match stance:
		STANCE_OFFENSIVE:
			return Constants.STANCE_OFFENSIVE_COEF
		STANCE_DEFENSIVE:
			return Constants.STANCE_DEFENSIVE_COEF
		_:
			return Constants.STANCE_BALANCED_COEF


func _apply_losses(army: ARMY_SCRIPT, fraction: float) -> void:
	if fraction <= 0.0:
		return
	for unit_value in army.units:
		if not (unit_value is Dictionary):
			# Instancias UnitInstance (si algún día se usan): muta su size.
			if unit_value is Object and unit_value.get("size") != null:
				unit_value.set("size", maxi(0, int(unit_value.get("size")) - int(roundf(float(unit_value.get("size")) * fraction))))
			continue
		var unit: Dictionary = unit_value
		var size: int = SafeDict.as_int(unit.get("size"), 0)
		var lost: int = int(roundf(float(size) * fraction))
		unit["size"] = maxi(0, size - lost)
		unit["morale"] = maxf(Constants.BATTLE_MIN_MORALE,
			SafeDict.as_float(unit.get("morale"), 1.0) - fraction * Constants.BATTLE_MORALE_LOSS_COEF)
		unit["experience"] = clampi(SafeDict.as_int(unit.get("experience"), 0) + 1, 0, 100)
	army.morale = maxf(Constants.BATTLE_MIN_MORALE, army.morale - fraction * 0.4)


func _is_broken(army: ARMY_SCRIPT, start_men: int) -> bool:
	if army.morale < Constants.MORALE_BREAK:
		return true
	var current_men: int = _men(army)
	return float(current_men) <= float(start_men) * Constants.RETREAT_THRESHOLD


func _men(army: ARMY_SCRIPT) -> int:
	var total: int = 0
	for unit_value in army.units:
		total += SafeDict.as_int(_unit_field(unit_value, "size", 0), 0)
	return total


func _unit_field(unit: Variant, key: String, default_value: Variant) -> Variant:
	if unit is Dictionary:
		var unit_dict: Dictionary = unit
		return unit_dict.get(key, default_value)
	if unit is Object:
		return unit.get(key)
	return default_value


func _build_notes(report: REPORT_SCRIPT, attacker_won: bool, stance: int) -> String:
	var stance_name: String = "equilibrada"
	if stance == STANCE_OFFENSIVE:
		stance_name = "ofensiva"
	elif stance == STANCE_DEFENSIVE:
		stance_name = "defensiva"
	var winner_name: String = report.attacker_faction if attacker_won else report.defender_faction
	var text := "Batalla de %s (%s): vence %s en %d asalto(s); bajas %d/%d" % [
		report.region_id, stance_name, winner_name, report.rounds.size(),
		report.attacker_losses, report.defender_losses,
	]
	if report.region_captured:
		text += "; región capturada"
	if report.leader_captured:
		text += "; líder capturado"
	elif report.leader_killed:
		text += "; líder caído"
	return text
