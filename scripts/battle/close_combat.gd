class_name CloseCombat
extends Node
## Batalla Nivel 3 — combate cerrado unidad contra unidad (GDD §6.3, contrato §4).
##
## Lógica pura, sin UI. `BattleManager.launch_close_combat(attacker_unit,
## defender_unit)` devuelve el nodo ya configurado (no lo añade al árbol).
##
## Cartas de orden (una por bando y ronda): `carga`, `disparo`, `formacion`,
## `finta`, `retirada`. Reglas de GDD §6.3/§6.4:
##   - disparo daña antes del choque (más si la unidad es a distancia);
##   - carga ×1.4 contra infantería en llano y ×0.6 contra formación/piqueros;
##   - formación reduce el daño recibido (×0.5) y también el propio ataque;
##   - finta reduce daño recibido (×0.7) y reposiciona (moral +0.05);
##   - retirada ordenada reduce bajas (×0.5) y escapa si quedan <40% efectivos.
##   - el comandante con mayor Mando tiene una mano de 3 cartas en vez de 2.
## Determinismo: tiradas con `GameState.rng`.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")
const BATTLE_SPRITES = preload("res://scripts/battle/battle_sprites.gd")

## Proyectil disparado en el duelo (Fase 3 §3).
signal projectile_fired(payload: Dictionary)

var round: int = 1
var finished: bool = false
## "attacker" | "defender" | "" (empate/indeciso).
var winner: String = ""
var attacker: Dictionary = {}
var defender: Dictionary = {}
var hands: Dictionary = {"attacker": [], "defender": []}
var orders_left: Dictionary = {"attacker": 0, "defender": 0}
var log_entries: Array[Dictionary] = []

var _start_size: Dictionary = {"attacker": 0, "defender": 0}
var _orders_per_round: Dictionary = {"attacker": Constants.CLOSE_COMBAT_HAND_BASE, "defender": Constants.CLOSE_COMBAT_HAND_BASE}
var _pending_attacker_card: String = ""
var _last_round: Dictionary = {}
var _max_rounds: int = Constants.CLOSE_COMBAT_MAX_ROUNDS
## Fase 3 (D-042): reloj de animación determinista y proyectiles del duelo.
var _animation_ms: float = 0.0
var _projectiles: Array[Dictionary] = []
var _projectile_seq: int = 0


## Configura el duelo a partir de dos dicts de unidad del estado/ejército.
func setup(attacker_unit: Dictionary, defender_unit: Dictionary) -> void:
	attacker = _normalize_unit(attacker_unit, "attacker")
	defender = _normalize_unit(defender_unit, "defender")
	_start_size["attacker"] = SafeDict.as_int(attacker.get("size"), 0)
	_start_size["defender"] = SafeDict.as_int(defender.get("size"), 0)
	round = 1
	finished = false
	winner = ""
	_pending_attacker_card = ""
	_last_round = {}
	log_entries.clear()
	_animation_ms = 0.0
	_projectiles = []
	_projectile_seq = 0
	var attacker_command: int = SafeDict.as_int(attacker.get("commander_stat"), Constants.BATTLE_COMMANDER_STAT_BASE)
	var defender_command: int = SafeDict.as_int(defender.get("commander_stat"), Constants.BATTLE_COMMANDER_STAT_BASE)
	_orders_per_round["attacker"] = Constants.CLOSE_COMBAT_HAND_BASE
	_orders_per_round["defender"] = Constants.CLOSE_COMBAT_HAND_BASE
	if attacker_command > defender_command:
		_orders_per_round["attacker"] = Constants.CLOSE_COMBAT_HAND_BASE + Constants.CLOSE_COMBAT_HAND_BONUS
	elif defender_command > attacker_command:
		_orders_per_round["defender"] = Constants.CLOSE_COMBAT_HAND_BASE + Constants.CLOSE_COMBAT_HAND_BONUS
	_draw_hands()
	_log("start", "Comienza el combate cerrado: %s vs %s" % [
		SafeDict.as_string(attacker.get("faction"), ""),
		SafeDict.as_string(defender.get("faction"), ""),
	])


## Juega una carta de la mano del atacante (una por ronda).
func play_order(order_id: String) -> bool:
	if finished or _pending_attacker_card != "":
		return false
	if not Constants.CLOSE_COMBAT_CARDS.has(order_id):
		return false
	var hand: Array = SafeDict.as_array(hands.get("attacker", null))
	if not hand.has(order_id):
		return false
	if SafeDict.as_int(orders_left.get("attacker"), 0) <= 0:
		return false
	hand.erase(order_id)
	hands["attacker"] = hand
	orders_left["attacker"] = maxi(0, SafeDict.as_int(orders_left.get("attacker"), 0) - 1)
	_pending_attacker_card = order_id
	return true


## La IA del defensor responde y se resuelve la ronda. Devuelve el resultado.
func enemy_respond() -> Dictionary:
	if finished:
		return {}
	if _pending_attacker_card == "":
		return {"ok": false, "reason": "no_order_pending"}
	var defender_card: String = _ai_choose_card()
	_remove_from_hand("defender", defender_card)
	orders_left["defender"] = maxi(0, SafeDict.as_int(orders_left.get("defender"), 0) - 1)
	var attacker_card: String = _pending_attacker_card
	_pending_attacker_card = ""
	var round_result: Dictionary = _resolve_round(attacker_card, defender_card)
	_last_round = round_result.duplicate(true)
	log_entries.append(round_result.duplicate(true))
	if not finished:
		round += 1
		if round > _max_rounds:
			_finish_by_ratio()
		else:
			_draw_hands()
	return round_result


func is_finished() -> bool:
	return finished


func get_state() -> Dictionary:
	return {
		"round": round,
		"attacker": attacker.duplicate(true),
		"defender": defender.duplicate(true),
		"orders_left": orders_left.duplicate(true),
		"hands": hands.duplicate(true),
		"orders_per_round": _orders_per_round.duplicate(true),
		"cards": Constants.CLOSE_COMBAT_CARDS.duplicate(),
		"pending_card": _pending_attacker_card,
		"finished": finished,
		"winner": winner,
		"last_round": _last_round.duplicate(true),
		"log": log_entries.duplicate(true),
		# Fase 3 §3 (aditivo): animación y proyectiles para el render.
		"animation_ms": _animation_ms,
		"projectiles": get_projectiles(),
	}


## Unidades del duelo (aditivo, mismo formato que TacticalBattle.get_units()).
func get_units() -> Array[Dictionary]:
	return [attacker.duplicate(true), defender.duplicate(true)]


## Avanza el reloj de animación/proyectiles (lo llama el render, sin RNG).
func tick_animation(delta_ms: float) -> void:
	_animation_ms += maxf(0.0, delta_ms)
	var active: Array[Dictionary] = []
	for projectile_value in _projectiles:
		var projectile: Dictionary = SafeDict.as_dict(projectile_value)
		var started_ms: float = SafeDict.as_float(projectile.get("started_ms"), 0.0)
		var duration_ms: float = maxf(1.0, SafeDict.as_float(projectile.get("duration_ms"), 1.0))
		if _animation_ms - started_ms >= duration_ms:
			continue
		active.append(projectile)
	_projectiles = active


## Proyectiles activos del duelo con posición/t interpolados por el reloj.
func get_projectiles() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for projectile_value in _projectiles:
		var projectile: Dictionary = SafeDict.as_dict(projectile_value)
		var duration_ms: float = maxf(1.0, SafeDict.as_float(projectile.get("duration_ms"), 1.0))
		var started_ms: float = SafeDict.as_float(projectile.get("started_ms"), 0.0)
		var elapsed_ms: float = clampf(_animation_ms - started_ms, 0.0, duration_ms)
		var t: float = clampf(elapsed_ms / duration_ms, 0.0, 1.0)
		var copy: Dictionary = projectile.duplicate(true)
		copy["elapsed_ms"] = snappedf(elapsed_ms, 0.1)
		copy["t"] = snappedf(t, 0.001)
		copy["position"] = BATTLE_SPRITES.projectile_position(
			SafeDict.as_dict(projectile.get("from", null)),
			SafeDict.as_dict(projectile.get("to", null)),
			SafeDict.as_float(projectile.get("arc_height"), 0.0), t)
		result.append(copy)
	return result


func get_outcome() -> Dictionary:
	var attacker_faction: String = SafeDict.as_string(attacker.get("faction"), "")
	var defender_faction: String = SafeDict.as_string(defender.get("faction"), "")
	return {
		"level": 3,
		"winner_side": winner,
		"winner_faction": attacker_faction if winner == "attacker" else (defender_faction if winner == "defender" else ""),
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"attacker_losses": maxi(0, SafeDict.as_int(_start_size.get("attacker"), 0) - SafeDict.as_int(attacker.get("size"), 0)),
		"defender_losses": maxi(0, SafeDict.as_int(_start_size.get("defender"), 0) - SafeDict.as_int(defender.get("size"), 0)),
		"rounds": round - 1,
		"log": log_entries.duplicate(true),
		"notes": "Combate cerrado: %s (rondas=%d)" % [winner if winner != "" else "indeciso", round - 1],
	}


## Simula el duelo con la IA de ambos bandos (headless/QA).
func auto_resolve() -> Dictionary:
	var guard: int = 0
	while not finished and guard < _max_rounds * 3:
		guard += 1
		var hand: Array = SafeDict.as_array(hands.get("attacker", null))
		var order: String = "formacion"
		if not hand.is_empty():
			order = str(hand[0])
		if not play_order(order):
			break
		enemy_respond()
	if not finished:
		_finish_by_ratio()
	return get_outcome()


# ---------------------------------------------------------------------------
# Resolución de la ronda
# ---------------------------------------------------------------------------

func _resolve_round(attacker_card: String, defender_card: String) -> Dictionary:
	var rng: SeededRNGScript = _rng()
	var attacker_power: float = _unit_power(attacker)
	var defender_power: float = _unit_power(defender)
	var defender_type: String = SafeDict.as_string(defender.get("type"), "infantry")
	var attacker_type: String = SafeDict.as_string(attacker.get("type"), "infantry")
	var result: Dictionary = {
		"round": round,
		"attacker_card": attacker_card,
		"defender_card": defender_card,
		"ok": true,
		"pre_damage": 0,
	}
	# Disparo: daño previo al choque.
	var pre_damage: int = 0
	if attacker_card == "disparo":
		var shot_ratio: float = 1.2 if attacker_type == "ranged" else 0.5
		pre_damage += _apply_damage(defender, attacker_power * Constants.CLOSE_COMBAT_SHOT_PRE_DAMAGE * shot_ratio * rng.gaussian(1.0, 0.15))
	if defender_card == "disparo":
		var shot_ratio_def: float = 1.2 if defender_type == "ranged" else 0.5
		pre_damage += _apply_damage(attacker, defender_power * Constants.CLOSE_COMBAT_SHOT_PRE_DAMAGE * shot_ratio_def * rng.gaussian(1.0, 0.15))
	result["pre_damage"] = pre_damage
	# Choque: multiplicadores de carta y de tipo de unidad.
	var attack_multiplier_a: float = _attack_multiplier(attacker_card, defender_type, defender_card)
	var attack_multiplier_d: float = _attack_multiplier(defender_card, attacker_type, attacker_card)
	var damage_a: float = attacker_power * attack_multiplier_a * rng.gaussian(1.0, 0.15)
	var damage_d: float = defender_power * attack_multiplier_d * rng.gaussian(1.0, 0.15)
	var defense_reduction_d: float = _defense_reduction(defender_card)
	var defense_reduction_a: float = _defense_reduction(attacker_card)
	var defender_loss_fraction: float = clampf(damage_a / maxf(defender_power, 1.0) * 0.4, 0.0, 0.5) * defense_reduction_d
	var attacker_loss_fraction: float = clampf(damage_d / maxf(attacker_power, 1.0) * 0.4, 0.0, 0.5) * defense_reduction_a
	# El terreno del defensor protege (llanura/ciudad...).
	var defender_terrain: String = SafeDict.as_string(defender.get("terrain"), "plains")
	if defender_terrain == "hills" or defender_terrain == "city":
		defender_loss_fraction *= 0.85
	var defender_losses: int = _apply_damage(defender, defender_loss_fraction * maxf(defender_power, 1.0))
	var attacker_losses: int = _apply_damage(attacker, attacker_loss_fraction * maxf(attacker_power, 1.0))
	if attacker_card == "finta":
		attacker["morale"] = minf(1.0, SafeDict.as_float(attacker.get("morale"), 1.0) + 0.05)
	if defender_card == "finta":
		defender["morale"] = minf(1.0, SafeDict.as_float(defender.get("morale"), 1.0) + 0.05)
	result["attacker_power"] = snappedf(attacker_power, 0.01)
	result["defender_power"] = snappedf(defender_power, 0.01)
	result["attacker_losses"] = attacker_losses
	result["defender_losses"] = defender_losses
	result["attacker_size"] = SafeDict.as_int(attacker.get("size"), 0)
	result["defender_size"] = SafeDict.as_int(defender.get("size"), 0)
	result["attacker_morale"] = snappedf(SafeDict.as_float(attacker.get("morale"), 1.0), 0.001)
	result["defender_morale"] = snappedf(SafeDict.as_float(defender.get("morale"), 1.0), 0.001)
	# Fase 3 §3: los duelistas a distancia disparan su proyectil (sin RNG).
	if not BATTLE_SPRITES.projectile_for_unit(SafeDict.as_string(attacker.get("unit_id"), "")).is_empty():
		_fire_projectile(attacker, defender, "attacker")
	if not BATTLE_SPRITES.projectile_for_unit(SafeDict.as_string(defender.get("unit_id"), "")).is_empty():
		_fire_projectile(defender, attacker, "defender")
	# Fin por destrucción, moral rota o retirada ordenada.
	var attacker_destroyed: bool = _is_destroyed(attacker)
	var defender_destroyed: bool = _is_destroyed(defender)
	if attacker_card == "retirada" and not attacker_destroyed:
		var attacker_ratio: float = float(SafeDict.as_int(attacker.get("size"), 0)) / float(maxi(1, SafeDict.as_int(_start_size.get("attacker"), 1)))
		if attacker_ratio <= Constants.CLOSE_COMBAT_RETREAT_THRESHOLD:
			attacker_destroyed = true
	if defender_card == "retirada" and not defender_destroyed:
		var defender_ratio: float = float(SafeDict.as_int(defender.get("size"), 0)) / float(maxi(1, SafeDict.as_int(_start_size.get("defender"), 1)))
		if defender_ratio <= Constants.CLOSE_COMBAT_RETREAT_THRESHOLD:
			defender_destroyed = true
	if defender_destroyed and not attacker_destroyed:
		_finish_with("attacker")
	elif attacker_destroyed and not defender_destroyed:
		_finish_with("defender")
	elif attacker_destroyed and defender_destroyed:
		_finish_with("defender")
	result["finished"] = finished
	result["winner"] = winner
	_log("round", "Ronda %d: carta %s vs %s (bajas %d/%d)" % [round, attacker_card, defender_card, attacker_losses, defender_losses])
	return result


func _attack_multiplier(card: String, opponent_type: String, opponent_card: String) -> float:
	match card:
		"carga":
			var multiplier: float = 1.0
			if opponent_type == "infantry":
				multiplier = Constants.CLOSE_COMBAT_CHARGE_VS_INFANTRY
			if opponent_card == "formacion" or opponent_type == "infantry" and opponent_card == "formacion":
				multiplier *= Constants.CLOSE_COMBAT_CHARGE_VS_FORMATION
			return multiplier
		"disparo":
			return 0.7
		"formacion":
			return 0.7
		"finta":
			return 0.5
		"retirada":
			return 0.0
		_:
			return 0.5


func _defense_reduction(card: String) -> float:
	match card:
		"formacion":
			return Constants.CLOSE_COMBAT_FORMATION_DAMAGE_REDUCTION
		"finta":
			return 1.0 - Constants.CLOSE_COMBAT_FAINT_DAMAGE_REDUCTION
		"retirada":
			return Constants.CLOSE_COMBAT_RETREAT_LOSS_REDUCTION
		_:
			return 1.0


func _ai_choose_card() -> String:
	var hand: Array = SafeDict.as_array(hands.get("defender", null))
	var attacker_card: String = _pending_attacker_card
	if hand.is_empty():
		return "formacion"
	if attacker_card == "carga":
		if hand.has("formacion"):
			return "formacion"
		if hand.has("finta"):
			return "finta"
	if attacker_card == "disparo":
		if hand.has("carga"):
			return "carga"
		if hand.has("finta"):
			return "finta"
	if attacker_card == "retirada":
		if hand.has("disparo"):
			return "disparo"
		return str(hand[0])
	var defender_ratio: float = float(SafeDict.as_int(defender.get("size"), 0)) / float(maxi(1, SafeDict.as_int(_start_size.get("defender"), 1)))
	if defender_ratio < Constants.CLOSE_COMBAT_RETREAT_THRESHOLD and hand.has("retirada"):
		return "retirada"
	if hand.has("disparo"):
		return "disparo"
	if hand.has("carga"):
		return "carga"
	return str(hand[0])


func _finish_with(winning_side: String) -> void:
	if finished:
		return
	finished = true
	winner = winning_side
	_log("finish", "Fin del combate cerrado: vence %s en la ronda %d" % [winner, round])


func _finish_by_ratio() -> void:
	var attacker_ratio: float = float(SafeDict.as_int(attacker.get("size"), 0)) / float(maxi(1, SafeDict.as_int(_start_size.get("attacker"), 1)))
	var defender_ratio: float = float(SafeDict.as_int(defender.get("size"), 0)) / float(maxi(1, SafeDict.as_int(_start_size.get("defender"), 1)))
	if attacker_ratio > defender_ratio:
		_finish_with("attacker")
	elif defender_ratio > attacker_ratio:
		_finish_with("defender")
	else:
		finished = true
		winner = ""
		_log("finish", "Combate cerrado indeciso tras %d rondas" % (round - 1))


func _is_destroyed(unit: Dictionary) -> bool:
	return SafeDict.as_int(unit.get("size"), 0) <= 0 \
		or SafeDict.as_float(unit.get("morale"), 1.0) < Constants.CLOSE_COMBAT_MORALE_BREAK


func _unit_power(unit: Dictionary) -> float:
	var size: int = SafeDict.as_int(unit.get("size"), 0)
	var strength: int = SafeDict.as_int(unit.get("strength"), 1)
	var morale: float = clampf(SafeDict.as_float(unit.get("morale"), 1.0), 0.0, 1.0)
	var experience: int = SafeDict.as_int(unit.get("experience"), 0)
	var veterancy: float = 1.0 + (float(experience) - 50.0) / 200.0
	var commander_stat: int = SafeDict.as_int(unit.get("commander_stat"), Constants.BATTLE_COMMANDER_STAT_BASE)
	var commander_bonus: float = 1.0 + (float(commander_stat) - 50.0) / Constants.BATTLE_COMMANDER_STAT_RANGE
	return maxf(0.0, float(strength) * (float(size) / 100.0) * morale * veterancy * commander_bonus)


## Aplica daño en puntos de poder; devuelve efectivos perdidos.
func _apply_damage(unit: Dictionary, damage: float) -> int:
	if damage <= 0.0:
		return 0
	var size: int = SafeDict.as_int(unit.get("size"), 0)
	if size <= 0:
		return 0
	var strength: int = SafeDict.as_int(unit.get("strength"), 1)
	var fraction: float = clampf(damage / (float(strength) * float(size) / 100.0), 0.0, 0.6)
	var losses: int = int(roundf(float(size) * fraction))
	unit["size"] = maxi(0, size - losses)
	unit["morale"] = maxf(0.05, SafeDict.as_float(unit.get("morale"), 1.0) - fraction * 0.6)
	unit["experience"] = clampi(SafeDict.as_int(unit.get("experience"), 0) + 1, 0, 100)
	return losses


func _draw_hands() -> void:
	var rng: SeededRNGScript = _rng()
	var deck: Array = Constants.CLOSE_COMBAT_CARDS.duplicate()
	var shuffled: Array = rng.shuffled(deck)
	var attacker_count: int = SafeDict.as_int(_orders_per_round.get("attacker"), Constants.CLOSE_COMBAT_HAND_BASE)
	var defender_count: int = SafeDict.as_int(_orders_per_round.get("defender"), Constants.CLOSE_COMBAT_HAND_BASE)
	hands["attacker"] = _take_cards(shuffled, attacker_count)
	hands["defender"] = _take_cards(shuffled, defender_count)
	orders_left["attacker"] = attacker_count
	orders_left["defender"] = defender_count


func _take_cards(source: Array, count: int) -> Array:
	var result: Array = []
	var index: int = 0
	while result.size() < count and source.size() > 0:
		result.append(source[index % source.size()])
		index += 1
	return result


func _remove_from_hand(side_name: String, card: String) -> void:
	var hand: Array = SafeDict.as_array(hands.get(side_name, null))
	var index: int = hand.find(card)
	if index >= 0:
		hand.remove_at(index)
	hands[side_name] = hand


func _normalize_unit(source: Dictionary, unit_side: String) -> Dictionary:
	var unit: Dictionary = SafeDict.as_dict(source).duplicate(true)
	var unit_id: String = SafeDict.as_string(unit.get("unit_id"), "")
	var definition: Dictionary = DataLoader.get_unit(unit_id)
	var faction_id: String = SafeDict.as_string(unit.get("faction"), "")
	var unit_type: String = SafeDict.as_string(unit.get("type"), SafeDict.as_string(definition.get("type"), "infantry"))
	var commander_stat: int = SafeDict.as_int(unit.get("commander_stat"), -1)
	if commander_stat < 0:
		var faction: Dictionary = GameState.get_faction_state(faction_id)
		var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
		var ruler: Dictionary = GameState.get_character_state(ruler_id)
		var stats: Dictionary = SafeDict.as_dict(ruler.get("stats", null))
		commander_stat = SafeDict.as_int(stats.get("command"), Constants.BATTLE_COMMANDER_STAT_BASE)
	# Fase 3 (D-040/D-042): sprite/orientación; atacante mira a E y defensor a O
	# (el render espeja el asset base que mira a E).
	var sprite_sheet: Dictionary = SafeDict.as_dict(definition.get("sprite_sheet", null))
	var frames: Array[String] = BATTLE_SPRITES.frames_of(sprite_sheet)
	var facing: String = "E" if unit_side == "attacker" else "W"
	return {
		"id": SafeDict.as_string(unit.get("id"), "unit_%s" % unit_side),
		"side": unit_side,
		"faction": faction_id,
		"unit_id": unit_id,
		"type": unit_type,
		"size": SafeDict.as_int(unit.get("size"), 100),
		"strength": SafeDict.as_int(unit.get("strength"), SafeDict.as_int(definition.get("strength"), 1)),
		"morale": clampf(SafeDict.as_float(unit.get("morale"), 1.0), 0.0, 1.0),
		"experience": SafeDict.as_int(unit.get("experience"), 0),
		"commander_stat": commander_stat,
		"terrain": SafeDict.as_string(unit.get("terrain"), "plains"),
		"facing": facing,
		"mirror": BATTLE_SPRITES.mirror_for(facing),
		"moving": false,
		"march_frame": 0,
		"sprite_frame_path": frames[0] if not frames.is_empty() else "",
		"sprite_sheet": _sprite_or_null(sprite_sheet),
	}


## Dict de sprite o null (fallback) como en TacticalBattle.
func _sprite_or_null(sprite: Dictionary) -> Variant:
	if sprite.is_empty():
		return null
	return sprite.duplicate(true)


## Dispara un proyectil del duelista a su rival (coordenadas normalizadas 0..1
## para que la UI las mapee a su layout; sin RNG de combate).
func _fire_projectile(shooter: Dictionary, target: Dictionary, shooter_side: String) -> void:
	var spec: Dictionary = BATTLE_SPRITES.projectile_for_unit(
		SafeDict.as_string(shooter.get("unit_id"), ""))
	if spec.is_empty():
		return
	_projectile_seq += 1
	var shooter_left: bool = shooter_side == "attacker"
	var payload: Dictionary = {
		"id": "duel_proj_%d" % _projectile_seq,
		"type": SafeDict.as_string(spec.get("type"), ""),
		"sprite": SafeDict.as_string(spec.get("sprite"), ""),
		"space": "normalized",
		"from": {"x": 0.3 if shooter_left else 0.7, "y": 0.42},
		"to": {"x": 0.7 if shooter_left else 0.3, "y": 0.58},
		"duration_ms": SafeDict.as_int(spec.get("duration_ms"), 0),
		"arc_height": SafeDict.as_float(spec.get("arc_height"), 0.0),
		"ballistic": SafeDict.as_bool(spec.get("ballistic"), true),
		"started_ms": _animation_ms,
		"target_id": SafeDict.as_string(target.get("id"), ""),
	}
	_projectiles.append(payload)
	emit_signal("projectile_fired", payload.duplicate(true))
	EventBus.emit_signal("projectile_fired", payload.duplicate(true))


func _rng() -> SeededRNGScript:
	var rng: SeededRNGScript = GameState.rng
	if rng == null:
		rng = SeededRNGScript.new(GameState.rng_seed)
		GameState.rng = rng
	return rng


func _log(kind: String, text: String) -> void:
	log_entries.append({"round": round, "kind": kind, "text": text})
