extends RefCounted
## TSBGame — fachada de SOLO LECTURA + acciones de la API de sistemas.
##
## Regla de oro GDD §8.2 y contrato Fase 1 §7: la UI nunca muta
## `GameState.state`, `DataLoader` ni diccionarios de sistemas. Todo el acceso
## a autoloads pasa por este unico punto:
##   - Lecturas: getters del estado canonico + getters de los sistemas.
##   - Acciones: SIEMPRE llamadas a la API publica (nunca escritura directa).
## Si un sistema aun es un stub de Fase 0, se ofrece una vista previa de solo
## lectura a partir de `res://data/*.json` para poder validar la UI (se elimina
## automaticamente en cuanto `DataLoader.load_all()` devuelve datos reales).

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const GameConstants = preload("res://scripts/utils/game_constants.gd")
const SCENARIO_ID := "scenario_1337"

static var _initialized := false
static var _data_fallback := false
static var _factions: Dictionary = {}
static var _regions: Dictionary = {}
static var _characters: Dictionary = {}
static var _units: Dictionary = {}
static var _scenarios: Dictionary = {}
static var _events: Dictionary = {}
static var _preview_armies: Dictionary = {}
static var _preview_ready := false


# ==========================================================================
# Infraestructura
# ==========================================================================
static func _autoload(node_name: String) -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tree := loop as SceneTree
		if tree.root != null:
			return tree.root.get_node_or_null(NodePath(node_name))
	return null


static func ensure_data() -> void:
	if _initialized:
		return
	_initialized = true
	var loader := _autoload("DataLoader")
	if loader != null and loader.has_method("load_all"):
		loader.call("load_all")
		var raw_factions: Variant = loader.get("factions")
		if raw_factions is Dictionary and not (raw_factions as Dictionary).is_empty():
			_factions = raw_factions
			var raw_regions: Variant = loader.get("regions")
			if raw_regions is Dictionary:
				_regions = raw_regions
			var raw_characters: Variant = loader.get("characters")
			if raw_characters is Dictionary:
				_characters = raw_characters
			var raw_units: Variant = loader.get("units")
			if raw_units is Dictionary:
				_units = raw_units
			var raw_scenarios: Variant = loader.get("scenarios")
			if raw_scenarios is Dictionary:
				_scenarios = raw_scenarios
			var raw_events: Variant = loader.get("events")
			if raw_events is Dictionary:
				_events = raw_events
	if _factions.is_empty():
		# AG-2 aun no implementa DataLoader: vista previa de presentacion.
		_data_fallback = true
		_factions = _read_dataset("res://data/factions.json", "factions", "id")
		_regions = _read_dataset("res://data/regions.json", "regions", "id")
		_characters = _read_dataset("res://data/characters.json", "characters", "id")
		_units = _read_dataset("res://data/units.json", "units", "id")
		_events = _read_dataset("res://data/events_1337.json", "events", "id")
		var scenario := _read_json("res://data/scenarios/scenario_1337.json")
		if scenario is Dictionary and not (scenario as Dictionary).is_empty():
			_scenarios = {"scenario_1337": scenario}


static func using_data_fallback() -> bool:
	ensure_data()
	return _data_fallback


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


static func _read_dataset(path: String, key: String, id_key: String) -> Dictionary:
	var out: Dictionary = {}
	var root := _read_json(path)
	var items: Variant = root.get(key)
	if items is Array:
		for item: Variant in (items as Array):
			if item is Dictionary and (item as Dictionary).has(id_key):
				out[str((item as Dictionary)[id_key])] = item
	return out


static func _prop(node_name: String, property_name: String) -> Variant:
	var node := _autoload(node_name)
	if node == null:
		return null
	return node.get(property_name)


static func _call(node_name: String, method_name: String, args: Array = []) -> Variant:
	var node := _autoload(node_name)
	if node == null or not node.has_method(method_name):
		return null
	return node.callv(method_name, args)


# ==========================================================================
# Estado canonico (solo lectura)
# ==========================================================================
static func state() -> Dictionary:
	# Copia defensiva (D-022): la UI nunca recibe la referencia viva del estado.
	return _state_raw().duplicate(true)


## Acceso interno de la fachada al estado vivo (solo lecturas; nunca exponer).
static func _state_raw() -> Dictionary:
	var raw: Variant = _prop("GameState", "state")
	if raw is Dictionary:
		return raw
	return {}


static func has_game() -> bool:
	var s := _state_raw()
	if s.is_empty():
		return false
	return s.has("regions") and s.has("factions")


static func is_preview_mode() -> bool:
	return not has_game()


static func player_faction() -> String:
	var s := _state_raw()
	var fid := str(s.get("player_faction", ""))
	if fid.is_empty():
		fid = str(_prop("GameState", "current_faction_id"))
	if fid.is_empty():
		fid = str(_prop("TurnManager", "current_faction_id"))
	if fid.is_empty():
		# Vista previa (sin partida): faccion de presentacion para que el mapa,
		# la corte y los paneles muestren datos reales. Las acciones quedan
		# desactivadas porque has_game() es false.
		var playable := playable_factions()
		if not playable.is_empty():
			fid = str(playable[0])
	return fid


static func faction_state(faction_id: String) -> Dictionary:
	var s := _state_raw()
	var factions: Variant = s.get("factions")
	if factions is Dictionary:
		var entry: Variant = (factions as Dictionary).get(faction_id, {})
		if entry is Dictionary:
			return (entry as Dictionary).duplicate(true)
	return {}


static func current_year() -> int:
	var s := _state_raw()
	var year := int(s.get("year", 0))
	if year <= 0:
		year = int(_prop("TurnManager", "current_year"))
	if year <= 0:
		year = int(scenario().get("start_year", 1337))
	return year


static func current_quarter() -> int:
	var s := _state_raw()
	var quarter := int(s.get("quarter", 0))
	if quarter <= 0:
		quarter = int(_prop("TurnManager", "current_quarter"))
	if quarter <= 0:
		quarter = 1
	return clampi(quarter, 1, 4)


static func current_turn() -> int:
	var s := _state_raw()
	var turn := int(s.get("turn", 0))
	if turn <= 0:
		turn = (current_year() - start_year()) * 4 + current_quarter()
	return turn


static func start_year() -> int:
	return int(scenario().get("start_year", 1337))


static func scenario_id() -> String:
	var s := _state_raw()
	var sid := str(s.get("scenario_id", ""))
	return sid if not sid.is_empty() else SCENARIO_ID


static func scenario_ids() -> Array:
	ensure_data()
	var ids: Array = []
	var dir := DirAccess.open("res://data/scenarios")
	if dir != null:
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.begins_with("scenario_") and entry.ends_with(".json"):
				ids.append(entry.get_basename())
			entry = dir.get_next()
		dir.list_dir_end()
	if ids.is_empty():
		for id: Variant in _scenarios.keys():
			ids.append(str(id))
	ids.sort()
	if not ids.has(SCENARIO_ID):
		ids.insert(0, SCENARIO_ID)
	return ids


static func scenario_available(scenario_id_value: String) -> bool:
	var sc := scenario(scenario_id_value)
	return not sc.is_empty() and int(sc.get("start_year", 0)) > 0


static func scenario_start_year(scenario_id_value: String) -> int:
	return int(scenario(scenario_id_value).get("start_year", 1337))


static func scenario_end_year_for(scenario_id_value: String) -> int:
	return int(scenario(scenario_id_value).get("end_year", 1399))


## Era I (<1350), II (1350-1399), III (>=1400) según D-059. La UI solo la pinta.
static func era_for_year(year_value: int) -> String:
	if year_value < 1350:
		return "I"
	if year_value < 1400:
		return "II"
	return "III"


static func current_era() -> String:
	var from_state: Variant = _call("GameState", "get_era", [])
	if from_state is String and not str(from_state).is_empty():
		return str(from_state)
	var raw: Variant = _prop("GameState", "era")
	if raw is String and not str(raw).is_empty():
		return str(raw)
	return era_for_year(current_year())


static func game_over_reason() -> String:
	var raw: Variant = _state_raw().get("game_over_reason", "")
	if raw is String and not str(raw).is_empty():
		return str(raw)
	var from_state: Variant = _call("GameState", "get_game_over_reason", [])
	return str(from_state) if from_state is String else ""


# ==========================================================================
# Datos historicos (DataLoader o vista previa)
# ==========================================================================
static func scenario(id: String = "") -> Dictionary:
	ensure_data()
	var scenario_key := id
	if scenario_key.is_empty():
		scenario_key = scenario_id()
	var from_loader: Variant = _call("DataLoader", "get_scenario", [scenario_key])
	if from_loader is Dictionary and not (from_loader as Dictionary).is_empty():
		return (from_loader as Dictionary).duplicate(true)
	var cached: Variant = _scenarios.get(scenario_key, {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		return (cached as Dictionary).duplicate(true)
	var direct := _read_json("res://data/scenarios/%s.json" % scenario_key)
	if not direct.is_empty():
		_scenarios[scenario_key] = direct
	return direct.duplicate(true)


static func all_factions() -> Array:
	ensure_data()
	var ids: Array = _factions.keys()
	ids.sort()
	var out: Array = []
	for id: Variant in ids:
		var entry: Variant = _factions[id]
		if entry is Dictionary:
			out.append((entry as Dictionary).duplicate(true))
	return out


static func faction_ids() -> Array:
	ensure_data()
	var ids: Array = _factions.keys()
	ids.sort()
	return ids


static func faction(faction_id: String) -> Dictionary:
	ensure_data()
	var from_loader: Variant = _call("DataLoader", "get_faction", [faction_id])
	if from_loader is Dictionary and not (from_loader as Dictionary).is_empty():
		return (from_loader as Dictionary).duplicate(true)
	var entry: Variant = _factions.get(faction_id, {})
	return (entry as Dictionary).duplicate(true) if entry is Dictionary else {}


static func faction_name(faction_id: String) -> String:
	var data := faction(faction_id)
	var name_text := str(data.get("name", faction_id))
	if data.is_empty():
		return faction_id.capitalize()
	return name_text


static func faction_color(faction_id: String) -> Color:
	var data := faction(faction_id)
	var html := str(data.get("color", ""))
	if Color.html_is_valid(html):
		return Color.html(html)
	var h := absi(hash(faction_id))
	return Color.from_hsv(float(h % 360) / 360.0, 0.45, 0.55)


static func faction_profile(faction_id: String) -> String:
	return str(faction(faction_id).get("profile", "balanced"))


static func faction_capital(faction_id: String) -> String:
	return str(faction(faction_id).get("capital", ""))


static func is_playable(faction_id: String) -> bool:
	return bool(faction(faction_id).get("playable", false))


static func playable_factions(scenario_id_value: String = SCENARIO_ID) -> Array:
	var sc := scenario(scenario_id_value)
	var configured: Variant = sc.get("playable_factions", null)
	if configured is Array and not (configured as Array).is_empty():
		var out: Array = []
		for id: Variant in (configured as Array):
			var fid := str(id)
			if not fid.is_empty() and not out.has(fid):
				out.append(fid)
		return out
	var listed: Variant = sc.get("factions")
	var out: Array = []
	if listed is Array and not (listed as Array).is_empty():
		for id: Variant in (listed as Array):
			if is_playable(str(id)):
				out.append(str(id))
	else:
		for entry: Variant in all_factions():
			if entry is Dictionary and bool((entry as Dictionary).get("playable", false)):
				out.append(str((entry as Dictionary).get("id", "")))
	return out


static func region_ids() -> Array:
	ensure_data()
	var ids: Array = _regions.keys()
	ids.sort()
	return ids


static func region(region_id: String) -> Dictionary:
	ensure_data()
	var raw: Variant = _regions.get(region_id, {})
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		var from_loader: Variant = _call("DataLoader", "get_region", [region_id])
		raw = from_loader if from_loader is Dictionary else {}
	var data: Dictionary = (raw as Dictionary).duplicate(true)
	var year := current_year()
	var entry: Dictionary = {}
	var years: Variant = data.get("year_data")
	if years is Dictionary:
		var year_data := years as Dictionary
		var by_year: Variant = year_data.get(str(year), null)
		if by_year is Dictionary:
			entry = (by_year as Dictionary).duplicate(true)
		elif year_data.has("1337"):
			entry = (year_data["1337"] as Dictionary).duplicate(true)
	var out := {
		"id": region_id,
		"name": str(data.get("name", region_id)),
		"terrain": str(data.get("terrain", "plains")),
		"has_city": bool(data.get("has_city", false)),
		"adjacency": data.get("adjacency", []),
		"owner": str(entry.get("owner", "")),
		"population": int(entry.get("population", 0)),
		"base_wealth": int(entry.get("base_wealth", 0)),
		"buildings": entry.get("buildings", []),
		"support": 50,
		"workers": {},
	}
	# El estado canonico manda sobre el dato historico cuando hay partida.
	var s := _state_raw()
	var live_regions: Variant = s.get("regions")
	if live_regions is Dictionary:
		var live: Variant = (live_regions as Dictionary).get(region_id, {})
		if live is Dictionary and not (live as Dictionary).is_empty():
			var live_state := live as Dictionary
			for key in ["owner", "support", "population", "base_wealth"]:
				if live_state.has(key):
					out[key] = live_state[key]
			if live_state.has("buildings"):
				out["buildings"] = live_state["buildings"]
			if live_state.has("workers"):
				out["workers"] = live_state["workers"]
			if live_state.has("terrain"):
				out["terrain"] = live_state["terrain"]
			if live_state.has("has_city"):
				out["has_city"] = live_state["has_city"]
	return out.duplicate(true)


static func region_name(region_id: String) -> String:
	return str(region(region_id).get("name", region_id))


static func region_owner(region_id: String) -> String:
	return str(region(region_id).get("owner", ""))


static func region_adjacency(region_id: String) -> Array:
	var adj: Variant = region(region_id).get("adjacency", [])
	return adj if adj is Array else []


static func regions_owned_by(faction_id: String) -> Array:
	var out: Array = []
	for id: Variant in region_ids():
		if region_owner(str(id)) == faction_id:
			out.append(str(id))
	return out


static func character(character_id: String) -> Dictionary:
	ensure_data()
	var from_loader: Variant = _call("DataLoader", "get_character", [character_id])
	if from_loader is Dictionary and not (from_loader as Dictionary).is_empty():
		return (from_loader as Dictionary).duplicate(true)
	var entry: Variant = _characters.get(character_id, {})
	return (entry as Dictionary).duplicate(true) if entry is Dictionary else {}


static func characters_of(faction_id: String) -> Array:
	ensure_data()
	var out: Array = []
	var source: Dictionary = _characters
	for id: Variant in source.keys():
		var entry: Variant = source[id]
		if entry is Dictionary and str((entry as Dictionary).get("faction", "")) == faction_id:
			out.append((entry as Dictionary).duplicate(true))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")) < str(b.get("name", "")))
	return out


static func all_characters() -> Array:
	ensure_data()
	var out: Array = []
	for id: Variant in _characters.keys():
		var entry: Variant = _characters[id]
		if entry is Dictionary:
			out.append((entry as Dictionary).duplicate(true))
	return out


static func character_age(entry: Dictionary) -> int:
	var born := int(entry.get("born", 0))
	if born <= 0:
		return 0
	var died: Variant = entry.get("died", null)
	if died != null:
		return maxi(int(died) - born, 0)
	return maxi(current_year() - born, 0)


static func character_is_alive(entry: Dictionary) -> bool:
	var died: Variant = entry.get("died", null)
	if died == null:
		return true
	return current_year() < int(died)


## Esposo/a declarado en `family.spouse` ("" si no hay, JSON null incluido).
static func character_spouse(entry: Dictionary) -> String:
	var family: Variant = entry.get("family", {})
	if family is Dictionary:
		var spouse: Variant = (family as Dictionary).get("spouse", null)
		if spouse != null and not str(spouse).is_empty():
			return str(spouse)
	return ""


static func ruler(faction_id: String) -> Dictionary:
	if has_game():
		var from_system: Variant = _call("DynastySystem", "get_ruler", [faction_id])
		if from_system is Dictionary and not (from_system as Dictionary).is_empty():
			return (from_system as Dictionary).duplicate(true)
	for entry: Variant in characters_of(faction_id):
		if entry is Dictionary and str((entry as Dictionary).get("role", "")) == "ruler" and character_is_alive(entry):
			return (entry as Dictionary).duplicate(true)
	return {}


static func heir(faction_id: String) -> Dictionary:
	if has_game():
		var from_system: Variant = _call("DynastySystem", "get_heir", [faction_id])
		if from_system is Dictionary and not (from_system as Dictionary).is_empty():
			return (from_system as Dictionary).duplicate(true)
	for entry: Variant in characters_of(faction_id):
		if entry is Dictionary and str((entry as Dictionary).get("role", "")) == "heir" and character_is_alive(entry):
			return (entry as Dictionary).duplicate(true)
	return {}


static func family_members(faction_id: String) -> Array:
	var out: Array = []
	var ruler_id := str(ruler(faction_id).get("id", ""))
	var heir_entry := heir(faction_id)
	var heir_id := str(heir_entry.get("id", ""))
	for entry: Variant in characters_of(faction_id):
		if not (entry is Dictionary):
			continue
		var member: Dictionary = (entry as Dictionary).duplicate(true)
		member["age"] = character_age(entry)
		member["alive"] = character_is_alive(entry)
		member["is_ruler"] = str(member.get("id", "")) == ruler_id
		member["is_heir"] = str(member.get("id", "")) == heir_id
		out.append(member)
	return out


static func unit(unit_id: String) -> Dictionary:
	ensure_data()
	var from_loader: Variant = _call("DataLoader", "get_unit", [unit_id])
	if from_loader is Dictionary and not (from_loader as Dictionary).is_empty():
		return (from_loader as Dictionary).duplicate(true)
	var entry: Variant = _units.get(unit_id, {})
	return (entry as Dictionary).duplicate(true) if entry is Dictionary else {}


static func unit_name(unit_id: String) -> String:
	var data := unit(unit_id)
	var name_text := str(data.get("name", ""))
	return name_text if not name_text.is_empty() else unit_id.capitalize()


static func all_units() -> Array:
	ensure_data()
	var out: Array = []
	for id: Variant in _units.keys():
		var entry: Variant = _units[id]
		if entry is Dictionary:
			out.append((entry as Dictionary).duplicate(true))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", "")))
	return out


static func units_for_faction(faction_id: String) -> Array:
	ensure_data()
	var source: Dictionary = _units
	var out: Array = []
	var era := 1
	var start := start_year()
	if start >= 1402:
		era = 2
	if start >= 1453:
		era = 3
	for id: Variant in source.keys():
		var entry: Variant = source[id]
		if not (entry is Dictionary):
			continue
		var tags: Variant = (entry as Dictionary).get("faction_tags", [])
		if tags is Array and not (tags as Array).is_empty():
			var tag_ok := false
			for tag: Variant in (tags as Array):
				if str(tag) == faction_id:
					tag_ok = true
					break
			if not tag_ok:
				continue
		var eras: Variant = (entry as Dictionary).get("era", [])
		if eras is Array and not (eras as Array).is_empty():
			var era_ok := false
			for era_key: Variant in (eras as Array):
				if int(era_key) == era:
					era_ok = true
					break
			if not era_ok:
				continue
		out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("strength", 0)) > int(b.get("strength", 0)))
	return out


# ==========================================================================
# Economia (lecturas + una accion)
# ==========================================================================
static func gold(faction_id: String = "") -> int:
	var fid := faction_id if not faction_id.is_empty() else player_faction()
	var fs := faction_state(fid)
	if fs.has("gold"):
		return int(fs.get("gold", 0))
	if has_game():
		var treasury: Variant = _call("EconomySystem", "get_treasury", [fid])
		if treasury != null:
			return int(treasury)
	var treasuries: Variant = scenario().get("initial_state", {})
	if treasuries is Dictionary:
		var t: Variant = (treasuries as Dictionary).get("treasuries", {})
		if t is Dictionary:
			return int((t as Dictionary).get(fid, 0))
	return 0


static func prestige(faction_id: String = "") -> int:
	var fid := faction_id if not faction_id.is_empty() else player_faction()
	var fs := faction_state(fid)
	return int(fs.get("prestige", 50))


static func pg_remaining() -> int:
	var fid := player_faction()
	var fs := faction_state(fid)
	if fs.has("pg"):
		return maxi(int(fs.get("pg", 0)), 0)
	var pg := int(_prop("TurnManager", "remaining_pg"))
	return maxi(pg, 0)


static func pg_max() -> int:
	var fid := player_faction()
	var calculated: Variant = _call("TurnManager", "calculate_pg", [fid])
	if calculated != null and int(calculated) > 0:
		return int(calculated)
	return 30 + int(prestige(fid) / 10.0)


static func support(region_id: String) -> int:
	var data := region(region_id)
	var support_value := int(data.get("support", 50))
	if has_game():
		var from_system: Variant = _call("EconomySystem", "get_support", [region_id])
		if from_system != null:
			return clampi(int(from_system), 0, 100)
	return clampi(support_value, 0, 100)


static func region_output(region_id: String) -> Dictionary:
	if not has_game():
		return {}
	var output: Variant = _call("EconomySystem", "get_region_output", [region_id])
	if output is Dictionary:
		return output
	return {}


static func allocate(region_id: String, worker_class: String, amount: int) -> bool:
	var result: Variant = _call("EconomySystem", "allocate", [region_id, worker_class, amount])
	return bool(result) if result != null else false


static func recalculate_economy(faction_id: String = "") -> void:
	var fid := faction_id if not faction_id.is_empty() else player_faction()
	_call("EconomySystem", "recalculate", [fid])


# ==========================================================================
# Dinastia (lectura + matrimonio/sucesion via API)
# ==========================================================================
static func marry(character_id: String, target_character_id: String) -> Dictionary:
	var result: Variant = _call("DynastySystem", "marry", [character_id, target_character_id])
	return result if result is Dictionary else {}


static func resolve_succession(faction_id: String) -> Dictionary:
	var result: Variant = _call("DynastySystem", "resolve_succession", [faction_id])
	return result if result is Dictionary else {}


# ==========================================================================
# Diplomacia
# ==========================================================================
static func relation(faction_a: String, faction_b: String) -> int:
	if has_game():
		var from_system: Variant = _call("DiplomacySystem", "get_relation", [faction_a, faction_b])
		if from_system != null:
			var value := int(from_system)
			if value != 0:
				return clampi(value, -100, 100)
		var fs := faction_state(faction_a)
		var relations: Variant = fs.get("relations")
		if relations is Dictionary:
			return clampi(int((relations as Dictionary).get(faction_b, 0)), -100, 100)
	return int(_preview_relations().get(_relation_key(faction_a, faction_b), 0))


static func _relation_key(faction_a: String, faction_b: String) -> String:
	var pair: Array[String] = [faction_a, faction_b]
	pair.sort()
	return "%s|%s" % [pair[0], pair[1]]


static func _preview_relations() -> Dictionary:
	return {
		"england|france": -60,
		"england|scotland": -70,
		"england|papacy": 20,
		"france|papacy": 30,
		"france|hre": -10,
		"castile|granada": -50,
		"aragon|castile": 10,
		"byzantium|mamluks": -20,
		"golden_horde|byzantium": -40,
	}


static func are_at_war(faction_a: String, faction_b: String) -> bool:
	if has_game():
		var from_system: Variant = _call("DiplomacySystem", "are_at_war", [faction_a, faction_b])
		if from_system != null:
			return bool(from_system)
		var wars: Variant = faction_state(faction_a).get("at_war", [])
		if wars is Array and (wars as Array).has(faction_b):
			return true
	return _preview_relations().get(_relation_key(faction_a, faction_b), 0) <= -60 \
		and _relation_key(faction_a, faction_b) == "england|france"


static func are_allied(faction_a: String, faction_b: String) -> bool:
	if has_game():
		var from_system: Variant = _call("DiplomacySystem", "are_allied", [faction_a, faction_b])
		if from_system != null:
			return bool(from_system)
		var allies: Variant = faction_state(faction_a).get("allies", [])
		if allies is Array and (allies as Array).has(faction_b):
			return true
	return false


static func action_cost(action_id: String) -> int:
	var cost: Variant = _call("DiplomacySystem", "get_action_cost", [action_id])
	if cost != null:
		return int(cost)
	return -1


static func propose(actor: String, target: String, action: Dictionary) -> Dictionary:
	var result: Variant = _call("DiplomacySystem", "propose", [actor, target, action])
	return result if result is Dictionary else {}


# ==========================================================================
# Militar y batalla
# ==========================================================================
static func armies() -> Dictionary:
	var s := _state_raw()
	var raw: Variant = s.get("armies")
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		return (raw as Dictionary).duplicate(true)
	if not has_game():
		return _build_preview_armies().duplicate(true)
	return {}


static func _build_preview_armies() -> Dictionary:
	if _preview_ready:
		return _preview_armies
	_preview_ready = true
	var sc := scenario()
	var initial: Variant = sc.get("initial_state", {})
	if not (initial is Dictionary):
		return {}
	var by_faction: Variant = (initial as Dictionary).get("armies", {})
	if not (by_faction is Dictionary):
		return {}
	var ruler_id := ""
	for faction_id: Variant in (by_faction as Dictionary).keys():
		var fid := str(faction_id)
		ruler_id = str(ruler(fid).get("id", ""))
		var list: Variant = (by_faction as Dictionary)[faction_id]
		if not (list is Array):
			continue
		var index := 0
		for item: Variant in (list as Array):
			if not (item is Dictionary):
				continue
			index += 1
			var item_dict := item as Dictionary
			var army_id := "preview_army_%s_%d" % [fid, index]
			_preview_armies[army_id] = {
				"id": army_id,
				"faction_id": fid,
				"region_id": str(item_dict.get("region", "")),
				"leader_id": ruler_id,
				"morale": 1.0,
				"movement_left": 2,
				"units": [{
					"id": "%s_u1" % army_id,
					"unit_id": str(item_dict.get("unit", "militia_spearman")),
					"size": int(item_dict.get("count", 0)),
					"strength": 0,
					"morale": 1.0,
					"experience": 0,
				}],
				"_preview": true,
			}
	return _preview_armies


static func army(army_id: String) -> Dictionary:
	if has_game():
		var from_system: Variant = _call("MilitarySystem", "get_army", [army_id])
		if from_system is Dictionary and not (from_system as Dictionary).is_empty():
			return from_system
	var entry: Variant = armies().get(army_id, {})
	return entry if entry is Dictionary else {}


static func armies_in(region_id: String) -> Array:
	var out: Array = []
	var all := armies()
	for id: Variant in all.keys():
		var entry: Variant = all[id]
		if entry is Dictionary and str((entry as Dictionary).get("region_id", "")) == region_id:
			out.append(entry)
	return out


static func army_soldiers(army_entry: Dictionary) -> int:
	var total := 0
	var units: Variant = army_entry.get("units", [])
	if units is Array:
		for unit_entry: Variant in (units as Array):
			if unit_entry is Dictionary:
				total += int((unit_entry as Dictionary).get("size", 0))
	return total


static func create_army(faction_id: String, region_id: String) -> Dictionary:
	var result: Variant = _call("MilitarySystem", "create_army", [faction_id, region_id])
	return result if result is Dictionary else {}


static func recruit(faction_id: String, region_id: String, unit_id: String, amount: int) -> bool:
	var result: Variant = _call("MilitarySystem", "recruit", [faction_id, region_id, unit_id, amount])
	return bool(result) if result != null else false


static func move_army(army_id: String, to_region: String) -> bool:
	var result: Variant = _call("MilitarySystem", "move_army", [army_id, to_region])
	return bool(result) if result != null else false


static func disband_army(army_id: String) -> bool:
	var result: Variant = _call("MilitarySystem", "disband_army", [army_id])
	return bool(result) if result != null else false


## D-070: resumen global por tipo de unidad (API de AG-2 o agregación local).
static func faction_army_summary(faction_id: String) -> Array:
	var from_system: Variant = _call("MilitarySystem", "get_faction_army_summary", [faction_id])
	if from_system is Array:
		return (from_system as Array).duplicate(true)
	var grouped: Dictionary = {}
	for army_value: Variant in armies().values():
		if not (army_value is Dictionary):
			continue
		var army_dict := army_value as Dictionary
		if str(army_dict.get("faction_id", "")) != faction_id:
			continue
		for unit_value: Variant in (army_dict.get("units", []) as Array):
			if not (unit_value is Dictionary):
				continue
			var unit_entry := unit_value as Dictionary
			var unit_id := str(unit_entry.get("unit_id", ""))
			if unit_id.is_empty():
				continue
			var aggregate: Dictionary = grouped.get(unit_id, {
				"unit_id": unit_id, "count": 0, "men": 0, "strength": 0.0,
				"morale": 0.0, "experience": 0.0, "samples": 0,
			})
			aggregate["count"] = int(aggregate.get("count", 0)) + 1
			aggregate["men"] = int(aggregate.get("men", 0)) + int(unit_entry.get("size", 0))
			aggregate["strength"] = float(aggregate.get("strength", 0.0)) + float(unit_entry.get("strength", 0))
			aggregate["morale"] = float(aggregate.get("morale", 0.0)) + float(unit_entry.get("morale", 1.0))
			aggregate["experience"] = float(aggregate.get("experience", 0.0)) + float(unit_entry.get("experience", 0))
			aggregate["samples"] = int(aggregate.get("samples", 0)) + 1
			grouped[unit_id] = aggregate
	var out: Array = []
	for unit_id: Variant in grouped.keys():
		var aggregate: Dictionary = grouped[unit_id]
		var samples := maxi(1, int(aggregate.get("samples", 1)))
		var definition := unit(str(unit_id))
		var frames: Array = []
		var sheet: Variant = definition.get("sprite_sheet", {})
		if sheet is Dictionary:
			frames = (sheet as Dictionary).get("frames", [])
		out.append({
			"unit_id": str(unit_id),
			"unit_name": str(definition.get("name", str(unit_id))),
			"count": int(aggregate.get("count", 0)),
			"men": int(aggregate.get("men", 0)),
			"strength": float(aggregate.get("strength", 0.0)) / float(samples),
			"morale": float(aggregate.get("morale", 1.0)) / float(samples),
			"experience": float(aggregate.get("experience", 0.0)) / float(samples),
			"sprite_path": str(frames[0]) if not frames.is_empty() else "",
			"is_fallback": frames.is_empty(),
		})
	out.sort_custom(func(a: Variant, b: Variant) -> bool: return str((a as Dictionary).get("unit_id", "")) < str((b as Dictionary).get("unit_id", "")))
	return out


static func train_unit(faction_id: String, unit_id: String, amount: int = 100) -> bool:
	var result: Variant = _call("MilitarySystem", "train_unit", [faction_id, unit_id, amount])
	return bool(result) if result != null else false


static func disband_unit(faction_id: String, unit_id: String, amount: int = 100) -> bool:
	var result: Variant = _call("MilitarySystem", "disband_unit", [faction_id, unit_id, amount])
	return bool(result) if result != null else false


static func military_last_error() -> String:
	var result: Variant = _call("MilitarySystem", "get_last_error", [])
	return str(result) if result != null else ""


static func train_last_error() -> String:
	var result: Variant = _call("MilitarySystem", "get_last_train_reason", [])
	return str(result) if result != null else ""


static func disband_last_error() -> String:
	var result: Variant = _call("MilitarySystem", "get_last_disband_reason", [])
	return str(result) if result != null else ""


static func recruit_last_error() -> String:
	var result: Variant = _call("MilitarySystem", "get_last_recruit_reason", [])
	return str(result) if result != null else ""


static func unit_recruit_goods(unit_id: String) -> Dictionary:
	var sheet: Variant = unit(unit_id).get("recruit_goods", {})
	return (sheet as Dictionary).duplicate(true) if sheet is Dictionary else {}


## D-075: coste de reclutar `amount` hombres de `unit_id`. Usa la API de AG-2
## si está disponible y, mientras tanto, calcula desde units.json+constantes.
static func unit_recruit_cost(unit_id: String, amount: int) -> Dictionary:
	var definition := unit(unit_id)
	var cost_data: Variant = definition.get("cost", {})
	var cost: Dictionary = cost_data if cost_data is Dictionary else {}
	var block_size := maxi(1, int(GameConstants.UNIT_MEN_PER_BLOCK))
	var blocks := int(ceilf(float(maxi(0, amount)) / float(block_size)))
	var goods_block := unit_recruit_goods(unit_id)
	var goods_total: Dictionary = {}
	for good_id: Variant in goods_block.keys():
		goods_total[str(good_id)] = float(goods_block[good_id]) * float(blocks)
	var fallback := {
		"unit_id": unit_id,
		"amount": amount,
		"blocks": blocks,
		"block_size": block_size,
		"per_block_gold": int(cost.get("gold", 0)),
		"per_block_recruits": int(cost.get("recruits", 0)),
		"per_block_goods": goods_block,
		"gold": int(cost.get("gold", 0)) * blocks,
		"recruits": int(cost.get("recruits", 0)) * blocks,
		"goods": goods_total,
	}
	var from_system: Variant = _call("MilitarySystem", "get_unit_recruit_cost", [unit_id, amount])
	if not (from_system is Dictionary) or (from_system as Dictionary).is_empty():
		return fallback
	var out: Dictionary = (from_system as Dictionary).duplicate(true)
	# Normaliza la API de AG-2 al contrato que consume la pantalla.
	out["block_size"] = block_size
	out["per_block_gold"] = int(out.get("gold_per_block", fallback["per_block_gold"]))
	out["per_block_goods"] = out.get("goods_per_block", fallback["per_block_goods"])
	out["per_block_recruits"] = int(fallback["per_block_recruits"])
	out["recruits"] = int(fallback["recruits"])
	if not out.has("gold"):
		out["gold"] = fallback["gold"]
	if not out.has("goods"):
		out["goods"] = fallback["goods"]
	return out


# D-069: fachada de mercancías/comercio (TradeSystem).
static func trade_goods_ids() -> Array[String]:
	var result: Variant = _call("TradeSystem", "get_goods_ids", [])
	var out: Array[String] = []
	if result is Array:
		for value: Variant in (result as Array):
			out.append(str(value))
	return out


static func trade_good(good_id: String) -> Dictionary:
	var result: Variant = _call("TradeSystem", "get_good_definition", [good_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func trade_inventory(faction_id: String) -> Dictionary:
	var result: Variant = _call("TradeSystem", "get_inventory", [faction_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func trade_amount(faction_id: String, good_id: String) -> float:
	var result: Variant = _call("TradeSystem", "get_good_amount", [faction_id, good_id])
	return float(result) if result != null else 0.0


static func trade_price(faction_id: String, good_id: String, region_id: String = "") -> float:
	var result: Variant = _call("TradeSystem", "get_good_price", [faction_id, good_id, region_id])
	return float(result) if result != null else 0.0


static func trade_merchants(faction_id: String) -> int:
	var result: Variant = _call("TradeSystem", "get_merchants", [faction_id])
	return int(result) if result != null else 0


static func trade_available_merchants(faction_id: String) -> int:
	var result: Variant = _call("TradeSystem", "get_available_merchants", [faction_id])
	return int(result) if result != null else 0


static func set_trade_merchants(faction_id: String, amount: int) -> bool:
	var result: Variant = _call("TradeSystem", "set_merchants", [faction_id, amount])
	return bool(result) if result != null else false


static func can_trade(faction_id: String) -> bool:
	var result: Variant = _call("TradeSystem", "can_trade", [faction_id])
	return bool(result) if result != null else false


static func trade_volume(faction_id: String) -> int:
	return maxi(0, trade_merchants(faction_id) * 5)


static func buy_goods(faction_id: String, region_id: String, good_id: String, qty: int) -> bool:
	var result: Variant = _call("TradeSystem", "buy", [faction_id, region_id, good_id, qty])
	return bool(result) if result != null else false


static func sell_goods(faction_id: String, region_id: String, good_id: String, qty: int) -> bool:
	var result: Variant = _call("TradeSystem", "sell", [faction_id, region_id, good_id, qty])
	return bool(result) if result != null else false


static func send_expedition(faction_id: String, good_id: String, qty: int) -> bool:
	var result: Variant = _call("TradeSystem", "send_expedition", [faction_id, good_id, qty])
	return bool(result) if result != null else false


static func trade_expeditions() -> Array:
	var result: Variant = _call("TradeSystem", "get_expeditions", [])
	return (result as Array).duplicate(true) if result is Array else []


static func trade_last_error() -> String:
	var result: Variant = _call("TradeSystem", "get_last_error", [])
	return str(result) if result != null else ""


static func recruitment_pool(region_id: String) -> int:
	var pool: Variant = _call("MilitarySystem", "get_recruitment_pool", [region_id])
	if pool != null:
		return int(pool)
	return -1


static func move_cost(army_id: String, to_region: String) -> int:
	var cost: Variant = _call("MilitarySystem", "get_move_cost", [army_id, to_region])
	if cost != null:
		return int(cost)
	return -1


static func estimate_power(army_entry: Dictionary, region_id: String, is_attacker: bool) -> float:
	var army_script = load("res://scripts/model/army.gd")
	var region_script = load("res://scripts/model/region_state.gd")
	if army_script == null or region_script == null:
		return 0.0
	var army_obj: Variant = army_script.new()
	army_obj.apply_dict(army_entry)
	var region_obj: Variant = region_script.new()
	region_obj.apply_dict(region(region_id))
	var result: Variant = _call("BattleManager", "estimate_power", [army_obj, region_obj, is_attacker])
	if result == null:
		return 0.0
	return float(result)


static func battle_reports() -> Array:
	var s := _state_raw()
	var reports: Variant = s.get("battle_reports", [])
	return (reports as Array).duplicate(true) if reports is Array else []


static func last_battle_report() -> Dictionary:
	var reports := battle_reports()
	if reports.is_empty():
		return {}
	var last: Variant = reports[reports.size() - 1]
	return (last as Dictionary).duplicate(true) if last is Dictionary else {}


# ==========================================================================
# Turno, guardado y eventos
# ==========================================================================
static func start_new_game(faction_id: String, seed_value: int = 1337) -> bool:
	_call("GameState", "new_game", [SCENARIO_ID, faction_id, seed_value])
	_call("TurnManager", "begin_turn", [faction_id])
	return has_game()


## Arranque data-driven de cualquiera de los 3 escenarios (Fase 3 §3).
static func start_new_game_in_scenario(scenario_id_value: String, faction_id: String, seed_value: int = 1337, difficulty: String = "normal") -> bool:
	if not scenario_available(scenario_id_value):
		return false
	_call("GameState", "new_game", [scenario_id_value, faction_id, seed_value, difficulty])
	_call("TurnManager", "begin_turn", [faction_id])
	return has_game()


static func difficulty() -> String:
	var result: Variant = _call("GameState", "get_difficulty", [])
	return str(result) if result != null else "normal"


static func set_difficulty(value: String) -> bool:
	var result: Variant = _call("GameState", "set_difficulty", [value])
	return bool(result) if result != null else false


static func tutorial_active() -> bool:
	var result: Variant = _call("TutorialSystem", "is_tutorial_active", [])
	return bool(result) if result != null else false


static func tutorial_step() -> Dictionary:
	var result: Variant = _call("TutorialSystem", "get_current_step", [])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func tutorial_state() -> Dictionary:
	var result: Variant = _call("TutorialSystem", "get_tutorial_state", [])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func tutorial_advance(condition_id: String) -> Dictionary:
	var result: Variant = _call("TutorialSystem", "advance_tutorial", [condition_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func tutorial_skip() -> bool:
	var result: Variant = _call("TutorialSystem", "tutorial_skip", [])
	return bool(result) if result != null else false


static func tutorial_steps_count() -> int:
	var result: Variant = _call("TutorialSystem", "get_steps_count", [])
	return int(result) if result != null else 0


static func action_used(key: String) -> bool:
	var result: Variant = _call("GameState", "is_action_used", [player_faction(), key])
	return bool(result) if result != null else false


static func can_use_action(key: String) -> bool:
	var result: Variant = _call("GameState", "can_use_action", [player_faction(), key])
	return bool(result) if result != null else true


static func mark_action_used(key: String) -> bool:
	var result: Variant = _call("GameState", "mark_action_used", [player_faction(), key])
	return bool(result) if result != null else false


static func season_name(quarter_override: int = -1) -> String:
	var result: Variant = _call("GameState", "get_season_name", [quarter_override])
	if result != null and str(result) != "":
		return str(result)
	var fallback := ["Primavera", "Verano", "Otoño", "Invierno"]
	var index := current_quarter() - 1
	if quarter_override >= 1 and quarter_override <= 4:
		index = quarter_override - 1
	return fallback[clampi(index, 0, 3)]


static func season_label() -> String:
	var result: Variant = _call("GameState", "get_season_label", [])
	if result != null and str(result) != "":
		return str(result)
	return "%s %d" % [season_name(), current_year()]


static func turn_actions() -> Array:
	var result: Variant = _call("GameState", "get_turn_actions", [])
	return (result as Array).duplicate(true) if result is Array else []


static func chronicle(year: int = -1) -> Array:
	var result: Variant = _call("GameState", "get_chronicle", [])
	var entries: Array = (result as Array).duplicate(true) if result is Array else []
	if year < 0:
		return entries
	var filtered: Array = []
	for entry: Variant in entries:
		if entry is Dictionary and int((entry as Dictionary).get("year", -1)) == year:
			filtered.append(entry)
	return filtered


static func advisor_enabled() -> bool:
	var result: Variant = _call("GameState", "is_advisor_enabled", [])
	if result != null:
		return bool(result)
	return difficulty() == "beginner"


static func set_advisor_enabled(value: bool) -> bool:
	var result: Variant = _call("GameState", "set_advisor_enabled", [value])
	return bool(result) if result != null else false


static func trade_advice(faction_id: String, region_id: String = "") -> Dictionary:
	var result: Variant = _call("TradeSystem", "get_trade_advice", [faction_id, region_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func context_help(screen: String) -> Dictionary:
	var result: Variant = _call("DataLoader", "get_context_help", [screen])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func legibility_texts() -> Dictionary:
	var result: Variant = _call("DataLoader", "get_legibility_texts", [])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func consort_info(faction_id: String) -> Dictionary:
	var result: Variant = _call("DynastySystem", "get_consort_info", [faction_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


static func spend_time_with_consort(faction_id: String) -> Dictionary:
	var result: Variant = _call("DynastySystem", "spend_time_with_consort", [faction_id])
	return (result as Dictionary).duplicate(true) if result is Dictionary else {}


## Devuelve el estado a "sin partida" (usado por herramientas de prueba y el
## menu de carga; no forma parte del flujo normal de juego).
static func reset_game() -> void:
	_call("GameState", "reset", [])


static func end_turn() -> void:
	_call("TurnManager", "end_turn", [])


static func save_game(slot: String = "autosave") -> bool:
	var result: Variant = _call("GameState", "save_game", [slot])
	return bool(result) if result != null else false


static func load_game(slot: String = "autosave") -> bool:
	var result: Variant = _call("GameState", "load_game", [slot])
	return bool(result) if result != null else false


static func has_save(slot: String = "autosave") -> bool:
	var result: Variant = _call("GameState", "has_save", [slot])
	return bool(result) if result != null else false


static func event_log() -> Array:
	var s := _state_raw()
	var log_entries: Variant = s.get("event_log", [])
	return (log_entries as Array).duplicate(true) if log_entries is Array else []


static func events_for_year(year_value: int) -> Array:
	ensure_data()
	var out: Array = []
	var year_events: Variant = _call("DataLoader", "get_events_for_year", [year_value])
	if year_events is Array and not (year_events as Array).is_empty():
		return year_events
	var source: Dictionary = _events
	for id: Variant in source.keys():
		var entry: Variant = source[id]
		if entry is Dictionary and int((entry as Dictionary).get("year", 0)) == year_value:
			out.append(entry)
	return out


static func events_in_log_for_year(year_value: int) -> Array:
	var out: Array = []
	for entry: Variant in event_log():
		if entry is Dictionary:
			var entry_year := int((entry as Dictionary).get("year", 0))
			if entry_year == year_value:
				out.append(entry)
	return out


# ==========================================================================
# Mapa atlas §10.1: fronteras vectoriales por ano (data/map_borders.json)
# ==========================================================================
static var _map_borders: Dictionary = {}


static func map_borders() -> Dictionary:
	if _map_borders.is_empty():
		var raw := _read_json("res://data/map_borders.json")
		if not raw.is_empty():
			_map_borders = raw
	return _map_borders


static func has_map_borders() -> bool:
	return not map_borders().is_empty()


static func map_border_years() -> Array:
	var years: Variant = map_borders().get("years", {})
	var out: Array = []
	if years is Dictionary:
		for key: Variant in (years as Dictionary).keys():
			var year_value := int(str(key))
			if year_value > 0 and not out.has(year_value):
				out.append(year_value)
	out.sort()
	return out


static func map_borders_for_year(year_value: int) -> Array:
	var years: Variant = map_borders().get("years", {})
	if not (years is Dictionary):
		return []
	var entries: Variant = (years as Dictionary).get(str(year_value), [])
	if not (entries is Array):
		return []
	return (entries as Array).duplicate(true)


static var _map_entries_cache: Dictionary = {}


## Indice interno region_id -> entrada (referencias de datos de presentacion).
static func _map_entries_by_region(year_value: int) -> Dictionary:
	if _map_entries_cache.has(year_value):
		return _map_entries_cache[year_value]
	var by_region: Dictionary = {}
	var years: Variant = map_borders().get("years", {})
	if years is Dictionary:
		var entries: Variant = (years as Dictionary).get(str(year_value), [])
		if entries is Array:
			for entry: Variant in (entries as Array):
				if entry is Dictionary:
					by_region[str((entry as Dictionary).get("region_id", ""))] = entry
	_map_entries_cache[year_value] = by_region
	return by_region


static func map_border_entry(region_id: String, year_value: int) -> Dictionary:
	var entry: Variant = _map_entries_by_region(year_value).get(region_id, {})
	return (entry as Dictionary).duplicate(true) if entry is Dictionary else {}


static func map_owner_for(region_id: String, year_value: int) -> String:
	return str(map_border_entry(region_id, year_value).get("owner", ""))


## Centro de etiqueta/icono normalizado [0..1], desde map_borders.center
## (o centroide del anillo si faltara). Sin datos de presentacion duplicados.
static func map_center(region_id: String, year_value: int) -> Vector2:
	var entry: Variant = _map_entries_by_region(year_value).get(region_id, {})
	var center: Variant = (entry as Dictionary).get("center", null) if entry is Dictionary else null
	if center is Array and (center as Array).size() >= 2:
		return Vector2(float((center as Array)[0]), float((center as Array)[1]))
	if entry is Dictionary:
		var ring: Variant = (entry as Dictionary).get("ring", [])
		if ring is Array and (ring as Array).size() >= 1:
			var sum := Vector2.ZERO
			var count := 0
			for pair: Variant in (ring as Array):
				if pair is Array and (pair as Array).size() >= 2:
					sum += Vector2(float((pair as Array)[0]), float((pair as Array)[1]))
					count += 1
			if count > 0:
				return sum / float(count)
	return Vector2(0.5, 0.5)


static func map_centers(year_value: int) -> Dictionary:
	var out: Dictionary = {}
	for region_id: Variant in region_ids():
		out[str(region_id)] = map_center(str(region_id), year_value)
	return out


static func map_label_for(region_id: String, year_value: int) -> String:
	var entry: Variant = _map_entries_by_region(year_value).get(region_id, {})
	var label := str((entry as Dictionary).get("label", "")) if entry is Dictionary else ""
	if not label.is_empty():
		return label
	return region_name(region_id)


# ==========================================================================
# Batallas Nivel 2/3 (Fase 2): fachada de la API de AG-2
# ==========================================================================
static func get_army_model(army_id: String) -> Object:
	var result: Variant = _call("MilitarySystem", "get_army_model", [army_id])
	return result as Object if result is Object else null


static func get_region_model(region_id: String) -> Object:
	var result: Variant = _call("MilitarySystem", "get_region_model", [region_id])
	return result as Object if result is Object else null


## Crea el nodo TacticalBattle ya configurado (el llamador lo anade al arbol).
static func launch_tactical(attacker_army_id: String, defender_army_id: String, region_id: String) -> Node:
	var attacker_model := get_army_model(attacker_army_id)
	var defender_model := get_army_model(defender_army_id)
	var region_model := get_region_model(region_id)
	if attacker_model == null or defender_model == null or region_model == null:
		return null
	var result: Variant = _call("BattleManager", "launch_tactical", [attacker_model, defender_model, region_model])
	return result as Node if result is Node else null


## Crea el nodo CloseCombat ya configurado (el llamador lo anade al arbol).
static func launch_close_combat(attacker_unit: Dictionary, defender_unit: Dictionary) -> Node:
	var result: Variant = _call("BattleManager", "launch_close_combat", [attacker_unit, defender_unit])
	return result as Node if result is Node else null


## D-033: la API de campaña para Nivel 3 la implementa AG-2 (task-17). La UI
## comprueba su presencia y, si aun no existe, muestra el duelo como vista previa.
static func has_close_combat_apply() -> bool:
	var manager := _autoload("BattleManager")
	return manager != null and manager.has_method("apply_close_combat_outcome")


## Aplica el resultado del duelo (N3) a la campaña. Devuelve {} si la API aun
## no existe o no hay partida; nunca muta estado directamente. Se pasa el mismo
## dict outcome que devuelve CloseCombat para que la idempotencia de la API
## (outcome["_applied_report"]) funcione; la UI ademas guarda su propio flag.
static func apply_close_combat_outcome(
		attacker_army_id: String,
		defender_army_id: String,
		region_id: String,
		outcome: Dictionary
) -> Dictionary:
	if not has_game() or attacker_army_id.is_empty() or defender_army_id.is_empty() or region_id.is_empty():
		return {}
	var result: Variant = _call("BattleManager", "apply_close_combat_outcome", [
		attacker_army_id, defender_army_id, region_id, outcome,
	])
	return result if result is Dictionary else {}


## Nivel 1 desde la UI: delega en el movimiento/batalla ya probado de Fase 1.
## Devuelve el informe ({} si no hubo choque o el movimiento fue rechazado).
static func delegate_attack(attacker_army_id: String, region_id: String) -> Dictionary:
	var before := battle_reports().size()
	var moved := move_army(attacker_army_id, region_id)
	if not moved:
		return {}
	var reports := battle_reports()
	if reports.size() > before:
		var last: Variant = reports[reports.size() - 1]
		return (last as Dictionary).duplicate(true) if last is Dictionary else {}
	return {}


## Primer ejercito defensor (de otra faccion) en la region, {} si no hay.
static func defender_army_in(region_id: String, attacker_faction: String) -> Dictionary:
	for army: Variant in armies_in(region_id):
		if army is Dictionary and str((army as Dictionary).get("faction_id", "")) != attacker_faction:
			return (army as Dictionary).duplicate(true)
	return {}


## Convierte la primera unidad de un ejercito en dict apto para launch_close_combat.
static func first_unit_of_army(army_id: String) -> Dictionary:
	var army := army(army_id)
	var units: Variant = army.get("units", [])
	if units is Array and not (units as Array).is_empty():
		var unit: Variant = (units as Array)[0]
		if unit is Dictionary:
			var data := (unit as Dictionary).duplicate(true)
			data["faction"] = str(army.get("faction_id", data.get("faction", "")))
			data["id"] = str(data.get("id", "%s_u1" % army_id))
			return data
	return {}


## Traslada el ejercito vencedor a la region capturada (si aun no esta alli).
## Se hace por la API de movimiento para no mutar estado desde la UI.
static func relocate_after_capture(army_id: String, region_id: String) -> void:
	var army_data := army(army_id)
	if army_data.is_empty():
		return
	if str(army_data.get("region_id", "")) == region_id:
		return
	move_army(army_id, region_id)


# ==========================================================================
# Notificaciones internas (textos para la UI)
# ==========================================================================
static func scenario_title() -> String:
	return str(scenario().get("title", "Dos Coronas"))


static func scenario_end_year() -> int:
	return int(scenario().get("end_year", 1399))


## Helpers de formato reexportados para las pantallas.
static func short_number(value: int) -> String:
	return Palette.short_number(value)


static func signed_number(value: int) -> String:
	return Palette.signed_number(value)
