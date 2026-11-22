extends Node
## TurnManager — orquestador del turno; la UI solo habla con él (GDD §8.2, §5.1).
##
## Autoridad del reloj de la partida (contrato Fase 1 §1/§3). Flujo de `end_turn`:
##   1. cierra la fase del jugador (turn_ended)
##   2. AIManager.run_all_ai() (13 rivales, <2 s)
##   3. resoluciones pendientes (batallas delegadas)
##   4. advance_quarter(): quarter+1 o, en el 4º, advance_year()
##   5. begin_turn() del nuevo trimestre
##
## PG (§5.1) = 30 + Prestigio/10 + bonus_líder − penalización, mínimo 0.

signal turn_started(quarter: int, year: int)
signal pg_changed(remaining: int)
signal turn_ended(quarter: int, year: int)
signal phase_changed(phase: String)
signal year_advanced(year: int)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const EventResolverScript = preload("res://scripts/utils/event_resolver.gd")

## 4 trimestres por año; 1 turno = 1 trimestre (GDD §5.1).
const QUARTERS_PER_YEAR: int = 4
## PG base por trimestre (GDD §5.1).
const PG_BASE: int = 30

var current_quarter: int = 1
var current_year: int = 1337
var current_faction_id: String = ""
var remaining_pg: int = 0
## "idle" | "governance" | "ai" | "resolutions" | "year_end".
var phase: String = "idle"


## Inicia el turno de la facción indicada (emite turn_started + pg_changed).
func begin_turn(faction_id: String) -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or faction_id == "" or SafeDict.as_bool(st.get("game_over"), false):
		return
	sync_clock_from_state()
	current_faction_id = faction_id
	GameState.current_faction_id = faction_id
	remaining_pg = calculate_pg(faction_id)
	_set_faction_pg(faction_id, remaining_pg)
	phase = "governance"
	emit_signal("turn_started", current_quarter, current_year)
	emit_signal("pg_changed", remaining_pg)
	emit_signal("phase_changed", phase)
	EventBus.emit_signal("turn_started", current_quarter, current_year)
	EventBus.emit_signal("pg_changed", faction_id, remaining_pg)
	EventBus.emit_signal("turn_phase_changed", phase)


## Cierra el turno: IA de rivales, resoluciones, avance y nuevo turno.
func end_turn() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or SafeDict.as_bool(st.get("game_over"), false):
		return
	phase = "resolutions"
	emit_signal("turn_ended", current_quarter, current_year)
	emit_signal("phase_changed", phase)
	EventBus.emit_signal("turn_ended", current_quarter, current_year)

	phase = "ai"
	emit_signal("phase_changed", phase)
	EventBus.emit_signal("turn_phase_changed", phase)
	AIManager.run_all_ai()

	MilitarySystem.resolve_pending_battles()
	# Fase 2 (D-031): la pérdida de la dinastía termina la partida de inmediato.
	_check_game_over()
	if SafeDict.as_bool(st.get("game_over"), false):
		phase = "idle"
		emit_signal("phase_changed", phase)
		return
	advance_quarter()


## Gasta PG de la facción activa; false si no alcanza (valida PG, GDD §5.1).
func spend_pg(amount: int) -> bool:
	return spend_pg_for(current_faction_id, amount)


func can_spend_pg(amount: int) -> bool:
	if amount < 0:
		return false
	return remaining_pg >= amount


## Gasta PG de cualquier facción (lo usan sistemas e IA).
func spend_pg_for(faction_id: String, amount: int) -> bool:
	var st: Dictionary = GameState.state
	if st.is_empty() or faction_id == "" or amount < 0:
		return false
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty():
		return false
	var available: int = SafeDict.as_int(faction.get("pg"), 0)
	if available < amount:
		return false
	faction["pg"] = available - amount
	if faction_id == current_faction_id:
		remaining_pg = available - amount
		emit_signal("pg_changed", remaining_pg)
		EventBus.emit_signal("pg_changed", faction_id, remaining_pg)
	return true


## PG del trimestre según fórmula de GDD §5.1.
func calculate_pg(faction_id: String) -> int:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return PG_BASE
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if faction.is_empty():
		return PG_BASE
	var prestige: int = SafeDict.as_int(faction.get("prestige"), 0)
	var leader_bonus: int = _leader_bonus(st, faction)
	var penalty: int = _unrest_penalty(st, faction_id)
	if SafeDict.as_string(faction.get("regent_id"), "") != "":
		penalty += Constants.PG_REGENCY_PENALTY
	var total: int = PG_BASE + int(floorf(float(prestige) / 10.0)) + leader_bonus - penalty
	return clampi(total, 0, Constants.PG_MAX)


## Avanza un trimestre (o el año si era el cuarto).
func advance_quarter() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or SafeDict.as_bool(st.get("game_over"), false):
		return
	var quarter: int = SafeDict.as_int(st.get("quarter"), 1)
	if quarter >= QUARTERS_PER_YEAR:
		advance_year()
		return
	st["quarter"] = quarter + 1
	st["turn"] = SafeDict.as_int(st.get("turn"), 1) + 1
	GameState.reset_turn_actions()
	GameState.sync_clock_from_state()
	current_quarter = quarter + 1
	_reset_movement()
	_run_quarterly_economy()
	_refresh_all_pg()
	_check_game_over()
	if SafeDict.as_bool(st.get("game_over"), false):
		return
	begin_turn(GameState.current_faction_id)


## Avanza el año: cosecha, dinastía, eventos, autoguardado y nuevo trimestre.
func advance_year() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or SafeDict.as_bool(st.get("game_over"), false):
		return
	var new_year: int = SafeDict.as_int(st.get("year"), 1337) + 1
	st["year"] = new_year
	st["quarter"] = 1
	st["turn"] = SafeDict.as_int(st.get("turn"), 1) + 1
	GameState.reset_turn_actions()
	GameState.sync_clock_from_state()
	current_year = new_year
	current_quarter = 1
	phase = "year_end"
	emit_signal("year_advanced", new_year)
	emit_signal("phase_changed", phase)
	EventBus.emit_signal("year_advanced", new_year)
	# D-015/D-066: campana de fin de año (audio generado, sin assets).
	AudioManager.play_year_bell()
	# D-067: música de informe de fin de año (AG-3 vuelve a "map" al cerrar).
	AudioManager.play_music("year_end")

	for faction_id in _faction_ids():
		EconomySystem.resolve_harvest(faction_id)
	DynastySystem.advance_year()
	EventResolverScript.new().resolve_year(new_year)

	_reset_movement()
	_run_quarterly_economy()
	_refresh_all_pg()
	GameState.save_game("autosave")
	_check_game_over()
	if SafeDict.as_bool(st.get("game_over"), false):
		return
	begin_turn(GameState.current_faction_id)


## Vuelve al estado inicial del reloj (lo usa GameState.reset).
func reset_turn_state() -> void:
	current_quarter = 1
	current_year = 1337
	current_faction_id = ""
	remaining_pg = 0
	phase = "idle"


## Sincroniza el espejo del reloj y los PG desde GameState.state.
func sync_clock_from_state() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return
	current_year = SafeDict.as_int(st.get("year"), current_year)
	current_quarter = SafeDict.as_int(st.get("quarter"), current_quarter)
	GameState.sync_clock_from_state()
	var player: String = SafeDict.as_string(st.get("player_faction"), GameState.current_faction_id)
	if player != "":
		current_faction_id = player
	GameState.current_faction_id = current_faction_id
	if current_faction_id != "":
		var faction: Dictionary = GameState.get_faction_state(current_faction_id)
		remaining_pg = SafeDict.as_int(faction.get("pg"), remaining_pg)


# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

func _leader_bonus(st: Dictionary, faction: Dictionary) -> int:
	var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
	if ruler_id == "":
		return 0
	var characters: Dictionary = SafeDict.as_dict(st.get("characters", null))
	var ruler: Dictionary = SafeDict.as_dict(characters.get(ruler_id, null))
	if ruler.is_empty() or not SafeDict.as_bool(ruler.get("alive"), false):
		return 0
	var stats: Dictionary = SafeDict.as_dict(ruler.get("stats", null))
	var charisma: int = SafeDict.as_int(stats.get("charisma"), 50)
	return clampi(int(roundf((float(charisma) - 50.0) / 10.0)), -10, 10)


func _unrest_penalty(st: Dictionary, faction_id: String) -> int:
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var unhappy: int = 0
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		if SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT) < Constants.PG_UNREST_SUPPORT_THRESHOLD:
			unhappy += 1
	return unhappy * Constants.PG_UNREST_PENALTY_PER_REGION


func _set_faction_pg(faction_id: String, value: int) -> void:
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	if not faction.is_empty():
		faction["pg"] = value


func _faction_ids() -> Array[String]:
	var st: Dictionary = GameState.state
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	return SafeDict.sorted_keys(factions)


func _reset_movement() -> void:
	var st: Dictionary = GameState.state
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	for army_id in SafeDict.sorted_keys(armies):
		var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
		army["movement_left"] = _army_speed(army)


func _army_speed(army: Dictionary) -> int:
	var units: Array = SafeDict.as_array(army.get("units", null))
	var speed: int = 2
	var first: bool = true
	for unit_value in units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		var definition: Dictionary = DataLoader.get_unit(SafeDict.as_string(unit.get("unit_id"), ""))
		if definition.is_empty():
			continue
		var move: int = SafeDict.as_int(definition.get("move"), 2)
		if first:
			speed = move
			first = false
		else:
			speed = mini(speed, move)
	return maxi(1, speed)


func _run_quarterly_economy() -> void:
	for faction_id in _faction_ids():
		EconomySystem.recalculate(faction_id)
	# D-069: producción de mercancías y resolución de expediciones cada trimestre.
	TradeSystem.produce_quarter_all()


func _refresh_all_pg() -> void:
	for faction_id in _faction_ids():
		var faction: Dictionary = GameState.get_faction_state(faction_id)
		if faction.is_empty() or SafeDict.as_bool(faction.get("eliminated"), false):
			continue
		faction["pg"] = calculate_pg(faction_id)


## Derrota inmediata del jugador cuando su dinastía se extingue (D-031/task-17).
## La facción IA queda eliminada por DynastySystem._extinguish; el reloj se
## congela porque advance_quarter/advance_year/end_turn comprueban game_over.
func on_dynasty_extinct(faction_id: String) -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or faction_id == "":
		return
	if SafeDict.as_bool(st.get("game_over"), false):
		return
	if faction_id != GameState.current_faction_id:
		return
	GameState.end_game(false, "dinastía extinta")
	phase = "idle"
	emit_signal("phase_changed", phase)
	EventBus.emit_signal("turn_phase_changed", phase)


## API pública (UI/tests, D-066): evalúa las condiciones §4.5 y devuelve el
## resumen de fin de partida sin exponer el detalle interno.
func check_game_over() -> Dictionary:
	_check_game_over()
	return GameState.get_game_over_info()


func _check_game_over() -> void:
	var st: Dictionary = GameState.state
	if st.is_empty() or SafeDict.as_bool(st.get("game_over"), false):
		return
	var player: String = GameState.current_faction_id
	if player == "":
		return
	var faction: Dictionary = GameState.get_faction_state(player)
	if faction.is_empty():
		return
	# Primero comprobamos la línea sucesoria (puede extinguir la dinastía, D-031).
	DynastySystem.check_ruling_line(player)
	if SafeDict.as_bool(st.get("game_over"), false):
		return
	faction = GameState.get_faction_state(player)
	if faction.is_empty():
		return
	if SafeDict.as_bool(faction.get("eliminated"), false):
		GameState.end_game(false, "dinastía extinta")
		return
	var owned_regions: int = 0
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") == player:
			owned_regions += 1
	if owned_regions == 0:
		GameState.end_game(false, "El jugador ha perdido todas sus regiones")
		return
	# Victoria dinástica: Prestigio Real mantenido `years_held` años (GDD §4.5.2).
	var scenario: Dictionary = DataLoader.get_scenario(GameState.scenario_id)
	var victory: Dictionary = SafeDict.as_dict(scenario.get("victory", null))
	var prestige_target: int = SafeDict.as_int(victory.get("prestige"), 500)
	var years_held: int = SafeDict.as_int(victory.get("years_held"), 10)
	var prestige: int = SafeDict.as_int(faction.get("prestige"), 0)
	var since: int = SafeDict.as_int(faction.get("prestige_since_year"), 0)
	if prestige >= prestige_target:
		if since == 0:
			faction["prestige_since_year"] = SafeDict.as_int(st.get("year"), 1337)
		elif SafeDict.as_int(st.get("year"), 1337) - since >= years_held:
			GameState.end_game(true, "Prestigio Real sostenido durante %d años" % years_held)
			return
	else:
		faction["prestige_since_year"] = 0
	# Victoria por conquista: controlar ≥ `control_pct` de las regiones (D-060).
	var control_pct: int = SafeDict.as_int(victory.get("control_pct"), 70)
	var total_regions: int = regions.size()
	if control_pct > 0 and total_regions > 0 \
			and float(owned_regions) / float(total_regions) >= float(control_pct) / 100.0:
		GameState.end_game(true, "Conquista: controlas ≥%d%% de las regiones" % control_pct)
		return
	# Victoria por supervivencia: llegar al `end_year` sin derrota (D-060).
	var end_year: int = SafeDict.as_int(scenario.get("end_year"), 0)
	if end_year > 0 and SafeDict.as_int(st.get("year"), 0) >= end_year:
		GameState.end_game(true, "Supervivencia hasta el año final (%d)" % end_year)
