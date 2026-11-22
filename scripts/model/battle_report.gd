class_name BattleReport
extends RefCounted
## Dataclass mínima del informe de batalla delegada (GDD §6.1, §8.2).
##
## Fase 0: solo estructura tipada y serialización (sin lógica de juego).
## Salida de BattleManager.resolve_delegated(): bajas por bando, rondas,
## capturas y región conquistada si cae la capital regional.

var attacker_faction: String = ""
var defender_faction: String = ""
var region_id: String = ""
## Faction id ganadora ("" si indecisa).
var winner_faction: String = ""
var attacker_losses: int = 0
var defender_losses: int = 0
## Una entrada por asalto: {round, attacker_damage, defender_damage, ...}.
var rounds: Array[Dictionary] = []
var region_captured: bool = false
var notes: String = ""


func is_attacker_victory() -> bool:
	return winner_faction != "" and winner_faction == attacker_faction


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
	notes = str(data.get("notes", notes))
