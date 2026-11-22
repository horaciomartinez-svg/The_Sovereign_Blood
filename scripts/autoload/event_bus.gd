extends Node
## EventBus — señales globales tipadas (GDD §8.3).
##
## Regla de oro de GDD §8.2: las escenas de UI nunca mutan estado directamente;
## emiten/escuchan aquí o llaman a los autoloads de sistema.
##
## Fase 0: solo se declaran las señales (autoload "vacío", GDD §12). La lógica
## que las emite llega en Fase 1. Ningún sistema debe conectar-se a un canal que
## no esté declarado aquí: este archivo es el contrato de eventos del juego.

# --- Turno y tiempo (turn_manager.gd) ---
signal turn_started(quarter: int, year: int)
signal turn_ended(quarter: int, year: int)
signal year_advanced(year: int)
signal pg_changed(faction_id: String, remaining: int)
signal turn_phase_changed(phase: String)

# --- Economía (economy_system.gd) ---
signal treasury_changed(faction_id: String, gold: int)
signal region_assignment_changed(region_id: String, worker_class: String, amount: int)
signal region_output_changed(region_id: String, output: Dictionary)
signal unrest_triggered(region_id: String, support: int)
signal revolt_triggered(region_id: String, faction_id: String)

# --- Dinastía (dynasty_system.gd) ---
signal character_born(character_id: String, faction_id: String)
signal character_died(character_id: String, cause: String)
signal marriage_formed(ruler_id: String, spouse_id: String)
signal succession_resolved(faction_id: String, heir_id: String)
signal regency_started(faction_id: String, regent_id: String)
signal dynasty_extinct(faction_id: String)

# --- Diplomacia (diplomacy_system.gd) ---
signal proposal_sent(actor: String, target: String, action: String)
signal proposal_resolved(actor: String, target: String, action: String, accepted: bool)
signal war_declared(attacker: String, defender: String)
signal peace_made(faction_a: String, faction_b: String)
signal alliance_changed(faction_a: String, faction_b: String, allied: bool)
signal relation_changed(faction_a: String, faction_b: String, value: int)

# --- Militar y batalla (military_system.gd / battle_manager.gd) ---
signal army_created(army_id: String, faction_id: String, region_id: String)
signal army_moved(army_id: String, from_region: String, to_region: String)
signal army_destroyed(army_id: String, faction_id: String)
signal battle_started(attacker: String, defender: String, region_id: String)
signal battle_resolved(report: Dictionary)
signal region_captured(region_id: String, faction_id: String)

# --- Eventos de partida, guardado y UI ---
signal game_event_triggered(event_id: String, payload: Dictionary)
signal game_over(faction_id: String, victory: bool, reason: String)
signal save_completed(slot: String)
signal load_completed(slot: String)
signal ui_notification(message: String, level: int)
