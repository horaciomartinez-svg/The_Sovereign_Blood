extends Node
## GameState — estado global de la partida y guardado/carga (GDD §7.7, §8.4).
##
## Fase 1 (contrato §1): `state` es un snapshot **JSON puro** (Dictionary/Array/
## primitivos) construido desde `scenario_1337.json` + `DataLoader`. Los sistemas
## lo leen/mutan; la UI solo lo lee. El RNG central (`rng`) viaja en el snapshot
## (`rng.snapshot()`) para que guardar/cargar sea determinista (GDD §13).
##
## Convenciones: ids string, diccionarios indexados por id, oro/población/
## efectivos enteros, moral/factores float.

signal game_initialized(scenario_id: String, faction_id: String)
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal game_over(faction_id: String, victory: bool, reason: String)

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")
const EventResolverScript = preload("res://scripts/utils/event_resolver.gd")
const TechScript = preload("res://scripts/utils/tech.gd")

## Versión del formato de guardado (GDD §8.4); migraciones al subirla.
const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const DEFAULT_SEED: int = 1337

# Espejo del reloj de TurnManager (autoridad del reloj: TurnManager).
var turn: int = 0
var year: int = 0
var quarter: int = 0
var current_faction_id: String = ""
var scenario_id: String = ""
var rng_seed: int = DEFAULT_SEED
var is_running: bool = false

## Snapshot puro y serializable de toda la partida (contrato §1).
var state: Dictionary = {}
## RNG central: TODA la aleatoriedad de Fase 1 sale de aquí (GDD §8.3).
var rng: SeededRNGScript = null
var last_errors: Array[String] = []


func _ready() -> void:
	if rng == null:
		rng = SeededRNGScript.new(rng_seed)


func has_state() -> bool:
	return not state.is_empty()


## Arranca una partida nueva y construye `state` desde el escenario.
func new_game(p_scenario_id: String, p_faction_id: String, p_seed_value: int = DEFAULT_SEED) -> void:
	if not DataLoader.is_loaded:
		DataLoader.load_all()
	var scenario: Dictionary = DataLoader.get_scenario(p_scenario_id)
	if scenario.is_empty():
		last_errors.append("escenario '%s' no disponible en DataLoader" % p_scenario_id)
		push_warning("GameState.new_game: escenario '%s' no disponible" % p_scenario_id)
		return
	scenario_id = p_scenario_id
	rng_seed = p_seed_value
	rng = SeededRNGScript.new(p_seed_value)
	var start_year: int = SafeDict.as_int(scenario.get("start_year"), 1337)
	year = start_year
	quarter = 1
	turn = 1
	current_faction_id = p_faction_id
	is_running = true
	state = {
		"save_version": SAVE_VERSION,
		"scenario_id": p_scenario_id,
		"player_faction": p_faction_id,
		"rng": rng.snapshot(),
		"year": start_year,
		"quarter": 1,
		"turn": 1,
		"game_over": false,
		# Fase 3 §4.3/D-059: era tecnológica actual (I/II/III) para UI y reglas.
		"start_year": start_year,
		"end_year": SafeDict.as_int(scenario.get("end_year"), start_year + 60),
		"era": TechScript.era_name(start_year),
		"factions": {},
		"regions": {},
		"characters": {},
		"armies": {},
		"event_log": [],
		"fired_events": [],
		"battle_reports": [],
		# D-066: batalla en curso (N2/N3) serializable para guardar/cargar.
		"pending_battle": {},
	}
	_build_characters(start_year)
	_build_factions(scenario, start_year)
	_build_regions(scenario)
	_build_armies(scenario)
	_apply_initial_regency(start_year)
	# D-067: la Guerra de los Cien Años empieza declarada (el evento 1337 la
	# contextualiza); así los eventos `trigger: war` pueden dispararse.
	_ensure_initial_wars(p_scenario_id, start_year)
	rng_seed = rng.get_seed()
	# Eventos del año de inicio (1337: casus belli y tensión anglo-francesa).
	EventResolverScript.new().resolve_year(start_year)
	emit_signal("game_initialized", p_scenario_id, p_faction_id)
	TurnManager.begin_turn(p_faction_id)
	# D-067: la música de mapa arranca al iniciar/cargar la partida (si hay pistas).
	AudioManager.play_music("map")


## Devuelve el estado a "sin partida".
func reset() -> void:
	state = {}
	last_errors.clear()
	rng = SeededRNGScript.new(DEFAULT_SEED)
	rng_seed = DEFAULT_SEED
	turn = 0
	year = 0
	quarter = 0
	current_faction_id = ""
	scenario_id = ""
	is_running = false
	TurnManager.reset_turn_state()


## Snapshot serializable listo para JSON (incluye `rng.snapshot()`, contrato §1).
##
## Canonicalización: JSON.parse devuelve todos los números como float, así que
## `to_dict()` normaliza los enteros integrales y serializa el estado del RNG
## (64 bits) como texto. Resultado: `to_dict()` → JSON → `from_dict()` →
## `to_dict()` produce exactamente el mismo documento (criterio A4) y el RNG
## continúa bit a bit.
func to_dict() -> Dictionary:
	if state.is_empty():
		return {}
	if rng != null:
		state["rng"] = rng.snapshot()
	var copy: Dictionary = state.duplicate(true)
	copy["rng"] = _rng_snapshot_json_safe()
	var canonical: Variant = _canonicalize(copy)
	if canonical is Dictionary:
		return canonical
	return copy


## Restaura el estado desde un snapshot (valida versión y claves mínimas).
func from_dict(data: Dictionary) -> bool:
	var candidate: Dictionary = SafeDict.as_dict(data)
	if candidate.is_empty():
		return false
	var version: int = SafeDict.as_int(candidate.get("save_version"), -1)
	if version != SAVE_VERSION:
		last_errors.append("save_version no soportada: %d" % version)
		return false
	for required_key in ["scenario_id", "player_faction", "factions", "regions", "characters", "armies"]:
		if not candidate.has(required_key):
			last_errors.append("snapshot sin clave requerida '%s'" % required_key)
			return false
	# Normaliza tipos numéricos (JSON no distingue int/float) para que to_dict
	# vuelva a producir el mismo documento.
	var normalized: Variant = _canonicalize(candidate)
	var restored: Dictionary = candidate
	if normalized is Dictionary:
		restored = normalized
	state = restored.duplicate(true)
	scenario_id = SafeDict.as_string(state.get("scenario_id"), "")
	current_faction_id = SafeDict.as_string(state.get("player_faction"), "")
	year = SafeDict.as_int(state.get("year"), 1337)
	quarter = SafeDict.as_int(state.get("quarter"), 1)
	turn = SafeDict.as_int(state.get("turn"), 1)
	is_running = true
	var snapshot: Dictionary = SafeDict.as_dict(state.get("rng", null))
	if snapshot.is_empty():
		rng = SeededRNGScript.new(rng_seed)
	else:
		if rng == null:
			rng = SeededRNGScript.new(SafeDict.as_int(snapshot.get("seed"), DEFAULT_SEED))
		rng.restore(snapshot)
	# El estado en memoria guarda siempre el snapshot con enteros.
	state["rng"] = rng.snapshot()
	rng_seed = rng.get_seed()
	TurnManager.sync_clock_from_state()
	return true


## Guarda en user://saves/<slot>.json (JSON legible, save_version 1).
func save_game(slot: String = "autosave") -> bool:
	if state.is_empty():
		return false
	var save_dir_absolute: String = ProjectSettings.globalize_path(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(save_dir_absolute)
	var path := SAVE_DIR.path_join("%s.json" % slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_errors.append("no se puede escribir %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(to_dict(), "\t", true, true))
	file.close()
	emit_signal("game_saved", slot)
	EventBus.emit_signal("save_completed", slot)
	return true


## Carga user://saves/<slot>.json.
func load_game(slot: String = "autosave") -> bool:
	var path := SAVE_DIR.path_join("%s.json" % slot)
	if not FileAccess.file_exists(path):
		last_errors.append("no existe el guardado %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		last_errors.append("guardado corrupto %s (línea %d)" % [path, json.get_error_line()])
		return false
	var data: Dictionary = SafeDict.as_dict(json.data)
	if not from_dict(data):
		return false
	emit_signal("game_loaded", slot)
	EventBus.emit_signal("load_completed", slot)
	return true


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR.path_join("%s.json" % slot))


## Sincroniza el espejo del reloj desde el estado (lo llama TurnManager).
func sync_clock_from_state() -> void:
	if state.is_empty():
		return
	year = SafeDict.as_int(state.get("year"), year)
	quarter = SafeDict.as_int(state.get("quarter"), quarter)
	turn = SafeDict.as_int(state.get("turn"), turn)
	state["era"] = TechScript.era_name(year)
	var player: String = SafeDict.as_string(state.get("player_faction"), current_faction_id)
	if player != "":
		current_faction_id = player


## Era tecnológica actual ("I" | "II" | "III", D-059).
func get_era() -> String:
	if state.is_empty():
		return TechScript.era_name(year)
	return TechScript.era_name(SafeDict.as_int(state.get("year"), year))


func get_era_index() -> int:
	return TechScript.era_index(SafeDict.as_int(state.get("year"), year))


## D-067: guerras históricas iniciales por escenario (solo 1337 en MVP).
func _ensure_initial_wars(p_scenario_id: String, start_year: int) -> void:
	if p_scenario_id != "scenario_1337" or start_year != 1337:
		return
	var factions: Dictionary = SafeDict.as_dict(state.get("factions", null))
	if not factions.has("england") or not factions.has("france"):
		return
	var england: Dictionary = SafeDict.as_dict(factions.get("england", null))
	var france: Dictionary = SafeDict.as_dict(factions.get("france", null))
	var eng_wars: Array = SafeDict.as_array(england.get("at_war", null))
	var fra_wars: Array = SafeDict.as_array(france.get("at_war", null))
	if not eng_wars.has("france"):
		eng_wars.append("france")
	if not fra_wars.has("england"):
		fra_wars.append("england")
	england["at_war"] = eng_wars
	france["at_war"] = fra_wars


## Facciones jugables del escenario actual (contrato fase3 §3): lista declarada
## por el escenario (`playable_factions`) o, si no existe, las facciones del
## escenario marcadas `playable:true` en `factions.json` (D-066: 8 en 1337).
func get_playable_factions(p_scenario_id: String = "") -> Array[String]:
	var sid: String = p_scenario_id if p_scenario_id != "" else scenario_id
	var scenario: Dictionary = DataLoader.get_scenario(sid)
	var result: Array[String] = []
	for faction_value in SafeDict.as_array(scenario.get("playable_factions", null)):
		result.append(str(faction_value))
	if not result.is_empty():
		return result
	var declared: Array[String] = []
	for faction_value in SafeDict.as_array(scenario.get("factions", null)):
		declared.append(str(faction_value))
	for faction_id in declared:
		var definition: Dictionary = DataLoader.get_faction(faction_id)
		if definition.is_empty() or SafeDict.as_bool(definition.get("playable"), false):
			result.append(faction_id)
	if result.is_empty():
		return declared
	return result


## Año final del escenario actual (para UI y supervivencia, D-060).
func get_end_year() -> int:
	var scenario: Dictionary = DataLoader.get_scenario(scenario_id)
	return SafeDict.as_int(scenario.get("end_year"), SafeDict.as_int(state.get("end_year"), 0))


func get_faction_state(faction_id: String) -> Dictionary:
	var factions: Dictionary = SafeDict.as_dict(state.get("factions", null))
	var entry: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
	return entry


func get_region_state(region_id: String) -> Dictionary:
	var regions: Dictionary = SafeDict.as_dict(state.get("regions", null))
	var entry: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
	return entry


func get_character_state(character_id: String) -> Dictionary:
	var characters: Dictionary = SafeDict.as_dict(state.get("characters", null))
	var entry: Dictionary = SafeDict.as_dict(characters.get(character_id, null))
	return entry


func get_army_state(army_id: String) -> Dictionary:
	var armies: Dictionary = SafeDict.as_dict(state.get("armies", null))
	var entry: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
	return entry


## Marca la partida como terminada (victoria/derrota) y avisa a la UI.
func end_game(victory: bool, reason: String) -> void:
	if state.is_empty():
		return
	state["game_over"] = true
	state["game_over_victory"] = victory
	state["game_over_reason"] = reason
	is_running = false
	# D-067: fanfarria de fin (victoria/derrota).
	AudioManager.play_music("end")
	emit_signal("game_over", current_faction_id, victory, reason)
	EventBus.emit_signal("game_over", current_faction_id, victory, reason)


## Resumen de fin de partida para la pantalla de fin (AG-3) y tests.
func get_game_over_info() -> Dictionary:
	if state.is_empty():
		return {"over": false, "victory": false, "reason": ""}
	return {
		"over": SafeDict.as_bool(state.get("game_over"), false),
		"victory": SafeDict.as_bool(state.get("game_over_victory"), false),
		"reason": SafeDict.as_string(state.get("game_over_reason"), ""),
		"faction_id": SafeDict.as_string(state.get("player_faction"), ""),
		"year": SafeDict.as_int(state.get("year"), 0),
		"quarter": SafeDict.as_int(state.get("quarter"), 0),
	}


## Registra la batalla N2/N3 en curso dentro del snapshot (D-066).
## `context` es JSON puro; debe incluir al menos `level` y `region_id`/`faction`.
func set_pending_battle(context: Dictionary) -> void:
	if state.is_empty():
		return
	state["pending_battle"] = context.duplicate(true)


func get_pending_battle() -> Dictionary:
	if state.is_empty():
		return {}
	return SafeDict.as_dict(state.get("pending_battle", null)).duplicate(true)


func has_pending_battle() -> bool:
	return not get_pending_battle().is_empty()


func clear_pending_battle() -> void:
	if state.is_empty():
		return
	state["pending_battle"] = {}


## Snapshot del RNG en forma JSON-segura (state como texto: 64 bits exactos).
func _rng_snapshot_json_safe() -> Dictionary:
	if rng == null:
		return {"seed": rng_seed, "state": "0"}
	var snapshot: Dictionary = rng.snapshot()
	return {
		"seed": SafeDict.as_int(snapshot.get("seed"), rng_seed),
		"state": str(SafeDict.as_int(snapshot.get("state"), 0)),
	}


## Normaliza números para el documento canónico: los float integrales pasan a
## int (JSON.parse no distingue) y el resto se conserva.
func _canonicalize(value: Variant) -> Variant:
	if value is float:
		var number: float = value
		if is_finite(number) and number == roundf(number) and absf(number) < 9000000000000000.0:
			return int(number)
		return number
	if value is Dictionary:
		var source: Dictionary = value
		var result: Dictionary = {}
		for key in source.keys():
			result[key] = _canonicalize(source.get(key, null))
		return result
	if value is Array:
		var source_array: Array = value
		var result_array: Array = []
		for item in source_array:
			result_array.append(_canonicalize(item))
		return result_array
	return value


# ---------------------------------------------------------------------------
# Construcción del estado inicial
# ---------------------------------------------------------------------------

func _build_characters(start_year: int) -> void:
	var characters_state: Dictionary = {}
	for character_id in DataLoader.get_character_ids():
		var source: Dictionary = DataLoader.get_character(character_id)
		var entry: Dictionary = source.duplicate(true)
		var born: int = SafeDict.as_int(source.get("born"), start_year)
		var died_value: Variant = source.get("died", null)
		var died: int = 0
		var has_died: bool = died_value != null
		if has_died:
			died = SafeDict.as_int(died_value, start_year)
		# Fase 3 D-058: vivo en el año de inicio si ya nació y no ha muerto antes.
		var alive: bool = born <= start_year and (not has_died or died >= start_year)
		entry["alive"] = alive
		entry["age"] = start_year - born
		characters_state[character_id] = entry
	state["characters"] = characters_state


func _build_factions(scenario: Dictionary, start_year: int) -> void:
	var factions_state: Dictionary = {}
	var faction_ids: Array = SafeDict.as_array(scenario.get("factions", null))
	var initial_state: Dictionary = SafeDict.as_dict(scenario.get("initial_state", null))
	var treasuries: Dictionary = SafeDict.as_dict(initial_state.get("treasuries", null))
	var characters_state: Dictionary = SafeDict.as_dict(state.get("characters", null))
	for faction_value in faction_ids:
		var faction_id: String = str(faction_value)
		var definition: Dictionary = DataLoader.get_faction(faction_id)
		var ruler_id: String = _find_ruler_character(characters_state, faction_id, start_year)
		var heir_id: String = _find_heir(characters_state, faction_id, ruler_id, start_year)
		var ruler_character: Dictionary = SafeDict.as_dict(characters_state.get(ruler_id, null))
		factions_state[faction_id] = {
			"gold": SafeDict.as_int(treasuries.get(faction_id), 500),
			"prestige": 50,
			"pg": 0,
			"tax_rate": Constants.TAX_RATE_DEFAULT,
			"profile": SafeDict.as_string(definition.get("profile"), "balanced"),
			"is_player": faction_id == current_faction_id,
			"ruler_id": ruler_id,
			"heir_id": heir_id,
			# Casa dinástica gobernante (Fase 2, D-031): base de la extinción.
			"house": SafeDict.as_string(ruler_character.get("house"), ""),
			"relations": {},
			"allies": [],
			"at_war": [],
			"trade_pacts": [],
			"casus_belli": {},
			"techs": [],
			# Informes de espionaje por facción espiada (D-030, serializable).
			"intel": {},
			"eliminated": false,
			"regent_id": "",
			"regency_until": 0,
			"interregnum_until": 0,
			"prestige_since_year": 0,
		}
	state["factions"] = factions_state
	# Guardar el año de inicio para la lógica de regencia/victoria.
	state["start_year"] = start_year


func _build_regions(scenario: Dictionary) -> void:
	var initial_state: Dictionary = SafeDict.as_dict(scenario.get("initial_state", null))
	var year_key: String = SafeDict.as_string(initial_state.get("regions"), "1337")
	var regions_state: Dictionary = {}
	for region_id in DataLoader.get_region_ids():
		var definition: Dictionary = DataLoader.get_region(region_id)
		var year_data_map: Dictionary = SafeDict.as_dict(definition.get("year_data", null))
		var year_data: Dictionary = SafeDict.as_dict(year_data_map.get(year_key, null))
		if year_data.is_empty() and not year_data_map.is_empty():
			var first_key: String = str(SafeDict.sorted_keys(year_data_map)[0])
			year_data = SafeDict.as_dict(year_data_map.get(first_key, null))
		var population: int = SafeDict.as_int(year_data.get("population"), 100000)
		var workers_total: int = maxi(4, int(roundf(float(population) / float(Constants.WORKER_POPULATION_PER_UNIT))))
		var workers: Dictionary = _initial_workers(workers_total)
		var buildings: Array = SafeDict.as_array(year_data.get("buildings", null))
		regions_state[region_id] = {
			"name": SafeDict.as_string(definition.get("name"), region_id),
			"owner": SafeDict.as_string(year_data.get("owner"), ""),
			"support": Constants.SUPPORT_DEFAULT,
			"workers": workers,
			"recruit_pool": SafeDict.as_int(workers.get("recruits"), 0) * Constants.WORKER_POPULATION_PER_UNIT,
			"buildings": buildings.duplicate(),
			"population": population,
			"base_wealth": SafeDict.as_int(year_data.get("base_wealth"), 50),
			"terrain": SafeDict.as_string(definition.get("terrain"), "plains"),
			"has_city": SafeDict.as_bool(definition.get("has_city"), false),
			"harvest_modifier": 1.0,
		}
	state["regions"] = regions_state


func _build_armies(scenario: Dictionary) -> void:
	var initial_state: Dictionary = SafeDict.as_dict(scenario.get("initial_state", null))
	var army_definitions: Dictionary = SafeDict.as_dict(initial_state.get("armies", null))
	var factions_state: Dictionary = SafeDict.as_dict(state.get("factions", null))
	var armies: Dictionary = {}
	var first_army_by_faction: Dictionary = {}
	for faction_id in SafeDict.sorted_keys(factions_state):
		var faction: Dictionary = factions_state[faction_id]
		var faction_definition: Dictionary = DataLoader.get_faction(faction_id)
		var capital_id: String = SafeDict.as_string(faction_definition.get("capital"), "")
		var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
		var entries: Array = SafeDict.as_array(army_definitions.get(faction_id, null))
		var entries_by_region: Dictionary = {}
		for entry_value in entries:
			var entry: Dictionary = SafeDict.as_dict(entry_value)
			var region_id: String = SafeDict.as_string(entry.get("region"), "")
			if region_id == "":
				continue
			var region_entries: Array = SafeDict.as_array(entries_by_region.get(region_id, null))
			region_entries.append(entry)
			entries_by_region[region_id] = region_entries
		var army_index: int = 0
		var leader_assigned: bool = false
		for region_id in SafeDict.sorted_keys(entries_by_region):
			var region_entries: Array = SafeDict.as_array(entries_by_region.get(region_id, null))
			var units: Array = []
			var speed: int = 2
			var first_unit: bool = true
			for entry_value in region_entries:
				var entry: Dictionary = SafeDict.as_dict(entry_value)
				var unit_id: String = SafeDict.as_string(entry.get("unit"), "")
				var count: int = SafeDict.as_int(entry.get("count"), 0)
				var unit_definition: Dictionary = DataLoader.get_unit(unit_id)
				if unit_definition.is_empty() or count <= 0:
					continue
				units.append({
					"id": "%s_u%d" % ["pending", units.size() + 1],
					"unit_id": unit_id,
					"size": count,
					"strength": SafeDict.as_int(unit_definition.get("strength"), 1),
					"morale": 1.0,
					"experience": 0,
				})
				if first_unit:
					speed = SafeDict.as_int(unit_definition.get("move"), 2)
					first_unit = false
				else:
					speed = mini(speed, SafeDict.as_int(unit_definition.get("move"), 2))
			if units.is_empty():
				continue
			army_index += 1
			var army_id := "army_%s_%d" % [faction_id, army_index]
			var unit_index: int = 0
			for unit_value in units:
				var unit: Dictionary = SafeDict.as_dict(unit_value)
				unit_index += 1
				unit["id"] = "%s_u%d" % [army_id, unit_index]
			var leader_id: String = ""
			if ruler_id != "" and region_id == capital_id and not leader_assigned:
				leader_id = ruler_id
				leader_assigned = true
			armies[army_id] = {
				"id": army_id,
				"faction_id": faction_id,
				"region_id": region_id,
				"leader_id": leader_id,
				"morale": 1.0,
				"movement_left": speed,
				"units": units,
			}
			if not first_army_by_faction.has(faction_id):
				first_army_by_faction[faction_id] = army_id
		# Si la capital no tenía ejército, el gobernante lidera el primer ejército.
		if ruler_id != "" and not leader_assigned and first_army_by_faction.has(faction_id):
			var first_id: String = str(first_army_by_faction[faction_id])
			var first_army: Dictionary = SafeDict.as_dict(armies.get(first_id, null))
			if not first_army.is_empty() and SafeDict.as_string(first_army.get("leader_id"), "") == "":
				first_army["leader_id"] = ruler_id
	state["armies"] = armies


func _apply_initial_regency(start_year: int) -> void:
	var factions_state: Dictionary = SafeDict.as_dict(state.get("factions", null))
	var characters_state: Dictionary = SafeDict.as_dict(state.get("characters", null))
	for faction_id in SafeDict.sorted_keys(factions_state):
		var faction: Dictionary = SafeDict.as_dict(factions_state.get(faction_id, null))
		var ruler_id: String = SafeDict.as_string(faction.get("ruler_id"), "")
		if ruler_id == "":
			continue
		var ruler: Dictionary = SafeDict.as_dict(characters_state.get(ruler_id, null))
		var born: int = SafeDict.as_int(ruler.get("born"), start_year)
		var age: int = start_year - born
		if age < Constants.REGENCY_AGE:
			var regent_id: String = _pick_regent(characters_state, faction_id, ruler_id, start_year)
			faction["regent_id"] = regent_id
			faction["regency_until"] = born + Constants.REGENCY_AGE


func _initial_workers(total: int) -> Dictionary:
	var workers: Dictionary = {"farmers": 0, "artisans": 0, "merchants": 0, "recruits": 0}
	var assigned: int = 0
	for worker_class in ["farmers", "artisans", "merchants"]:
		var share: float = float(Constants.WORKER_INITIAL_SPLIT.get(worker_class, 0.0))
		var amount: int = int(roundf(float(total) * share))
		workers[worker_class] = amount
		assigned += amount
	workers["recruits"] = maxi(0, total - assigned)
	return workers


func _find_role_character(characters_state: Dictionary, faction_id: String, role: String, start_year: int) -> String:
	for character_id in SafeDict.sorted_keys(characters_state):
		var character: Dictionary = SafeDict.as_dict(characters_state.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if SafeDict.as_string(character.get("role"), "") != role:
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		if SafeDict.as_int(character.get("born"), start_year) > start_year:
			continue
		return character_id
	return ""


## Gobernante de la facción en `start_year` (D-058): filtra vivos y, si hay
## `reign_start`/`reign_end`, exige que el reinado cubra el año; si varios,
## elige el reinado más reciente. Sin ventanas, primer gobernante vivo (legado).
func _find_ruler_character(characters_state: Dictionary, faction_id: String, start_year: int) -> String:
	var best_id: String = ""
	var best_reign_start: int = -1
	var fallback_id: String = ""
	for character_id in SafeDict.sorted_keys(characters_state):
		var character: Dictionary = SafeDict.as_dict(characters_state.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if SafeDict.as_string(character.get("role"), "") != "ruler":
			continue
		if not SafeDict.as_bool(character.get("alive"), false):
			continue
		if SafeDict.as_int(character.get("born"), start_year) > start_year:
			continue
		var has_window: bool = character.has("reign_start") or character.has("reign_end")
		if has_window:
			var reign_start: int = SafeDict.as_int(character.get("reign_start"),
				SafeDict.as_int(character.get("born"), start_year))
			var reign_end: int = SafeDict.as_int(character.get("reign_end"), 9999)
			if start_year < reign_start or start_year > reign_end:
				continue
			if reign_start > best_reign_start:
				best_reign_start = reign_start
				best_id = character_id
		elif fallback_id == "":
			fallback_id = character_id
	if best_id != "":
		return best_id
	return fallback_id


func _find_heir(characters_state: Dictionary, faction_id: String, ruler_id: String, start_year: int) -> String:
	var explicit_heir: String = _find_role_character(characters_state, faction_id, "heir", start_year)
	if explicit_heir != "" and explicit_heir != ruler_id:
		return explicit_heir
	var ruler: Dictionary = SafeDict.as_dict(characters_state.get(ruler_id, null))
	var family: Dictionary = SafeDict.as_dict(ruler.get("family", null))
	var children: Array = SafeDict.as_array(family.get("children", null))
	var best_child: String = ""
	var best_born: int = 9999
	for child_value in children:
		var child_id: String = str(child_value)
		var child: Dictionary = SafeDict.as_dict(characters_state.get(child_id, null))
		if child.is_empty() or not SafeDict.as_bool(child.get("alive"), false):
			continue
		if SafeDict.as_int(child.get("born"), start_year) > start_year:
			continue
		if SafeDict.as_int(child.get("born"), 9999) < best_born:
			best_born = SafeDict.as_int(child.get("born"), 9999)
			best_child = child_id
	if best_child != "":
		return best_child
	# Último recurso: el pariente vivo más joven de la misma facción.
	var best_relative: String = ""
	var best_relative_born: int = -1
	for character_id in SafeDict.sorted_keys(characters_state):
		var character: Dictionary = SafeDict.as_dict(characters_state.get(character_id, null))
		if SafeDict.as_string(character.get("faction"), "") != faction_id:
			continue
		if character_id == ruler_id or not SafeDict.as_bool(character.get("alive"), false):
			continue
		# D-067: un cónyuge no es heredero de la casa (Polonia/Aldona).
		if SafeDict.as_string(character.get("role"), "") == "spouse":
			continue
		if SafeDict.as_int(character.get("born"), 0) <= start_year \
				and SafeDict.as_int(character.get("born"), 0) > best_relative_born:
			best_relative_born = SafeDict.as_int(character.get("born"), 0)
			best_relative = character_id
	return best_relative


func _pick_regent(characters_state: Dictionary, faction_id: String, ruler_id: String, start_year: int) -> String:
	var preferred_roles: Array = ["heir", "spouse", "relative", "general", "advisor"]
	for role in preferred_roles:
		for character_id in SafeDict.sorted_keys(characters_state):
			var character: Dictionary = SafeDict.as_dict(characters_state.get(character_id, null))
			if character_id == ruler_id:
				continue
			if SafeDict.as_string(character.get("faction"), "") != faction_id:
				continue
			if SafeDict.as_string(character.get("role"), "") != str(role):
				continue
			if not SafeDict.as_bool(character.get("alive"), false):
				continue
			var age: int = start_year - SafeDict.as_int(character.get("born"), start_year)
			if age >= Constants.REGENCY_AGE:
				return character_id
	return ""
