extends Node
## DiplomacySystem — relaciones bilaterales y acciones diplomáticas (GDD §5.4, §8.2).
##
## Fase 0: contrato declarado, sin lógica (autoload vacío, GDD §12).
## Fase 1: relación −100..100, las 7 acciones de §5.4, casus belli y tratados.

signal proposal_sent(actor: String, target: String, action: String)
signal proposal_resolved(actor: String, target: String, action: String, accepted: bool)
signal relation_changed(faction_a: String, faction_b: String, value: int)
signal war_declared(attacker: String, defender: String)
signal peace_made(faction_a: String, faction_b: String)
signal alliance_changed(faction_a: String, faction_b: String, allied: bool)

## Coste en PG por acción diplomática (GDD §5.4). La acción llega como clave de
## "action.type" en el diccionario de propose().
const ACTION_PG_COSTS: Dictionary = {
	"alliance": 8,
	"marriage": 10,
	"trade_pact": 6,
	"demand_tribute": 5,
	"offer_tribute": 3,
	"declare_war": 0,
	"propose_peace": 4,
	"spy": 6,  # Fase 2
}


## Propuesta diplomática: {ok: bool, accepted?: bool, reason?: String} (GDD §8.2).
func propose(_actor: String, _target: String, _action: Dictionary) -> Dictionary:
	return {}


## Relación bilateral −100..100 (0 = neutral en Fase 0).
func get_relation(_faction_a: String, _faction_b: String) -> int:
	return 0


func set_relation(_faction_a: String, _faction_b: String, _value: int) -> void:
	pass


func are_at_war(_faction_a: String, _faction_b: String) -> bool:
	return false


func are_allied(_faction_a: String, _faction_b: String) -> bool:
	return false


## Coste en PG de una acción de GDD §5.4 (-1 si la acción no existe).
func get_action_cost(action_id: String) -> int:
	var cost: int = ACTION_PG_COSTS.get(action_id, -1)
	return cost
