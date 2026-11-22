class_name BattleReport
extends RefCounted
## Informe de batalla delegada (GDD §6.1, §8.2).
##
## Salida de `BattleManager.resolve_delegated()`: bajas por bando, rondas,
## captura de región, botín y suerte del líder derrotado. `to_dict()` produce el
## diccionario serializable que `MilitarySystem` guarda en `state.battle_reports`
## y que la UI muestra.

var attacker_faction: String = ""
var defender_faction: String = ""
var region_id: String = ""
## Faction id ganadora ("" si indecisa).
var winner_faction: String = ""
var attacker_losses: int = 0
var defender_losses: int = 0
## Una entrada por asalto: {round, attacker_power, defender_power, ...}.
var rounds: Array[Dictionary] = []
var region_captured: bool = false
var loot_gold: int = 0
var leader_killed: bool = false
var leader_captured: bool = false
var attacker_start_power: float = 0.0
var defender_start_power: float = 0.0
var notes: String = ""


func is_attacker_victory() -> bool:
	return winner_faction != "" and winner_faction == attacker_faction


func total_rounds() -> int:
	return rounds.size()


func to_dict() -> Dictionary:
	return {
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"region_id": region_id,
		"winner_faction": winner_faction,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses,
		"rounds": rounds.duplicate(true),
		"region_captured": region_captured,
		"loot_gold": loot_gold,
		"leader_killed": leader_killed,
		"leader_captured": leader_captured,
		"attacker_start_power": attacker_start_power,
		"defender_start_power": defender_start_power,
		"notes": notes,
	}


func apply_dict(data: Dictionary) -> void:
	attacker_faction = str(data.get("attacker_faction", attacker_faction))
	defender_faction = str(data.get("defender_faction", defender_faction))
	region_id = str(data.get("region_id", region_id))
	winner_faction = str(data.get("winner_faction", winner_faction))
	attacker_losses = int(data.get("attacker_losses", attacker_losses))
	defender_losses = int(data.get("defender_losses", defender_losses))
	var raw_rounds: Variant = data.get("rounds", null)
	if raw_rounds is Array:
		rounds.clear()
		for item: Variant in (raw_rounds as Array):
			if item is Dictionary:
				rounds.append((item as Dictionary).duplicate(true))
	region_captured = bool(data.get("region_captured", region_captured))
	loot_gold = int(data.get("loot_gold", loot_gold))
	leader_killed = bool(data.get("leader_killed", leader_killed))
	leader_captured = bool(data.get("leader_captured", leader_captured))
	attacker_start_power = float(data.get("attacker_start_power", attacker_start_power))
	defender_start_power = float(data.get("defender_start_power", defender_start_power))
	notes = str(data.get("notes", notes))
