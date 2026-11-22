extends RefCounted
## Resolutor de eventos históricos (`data/events_*.json`, GDD §7.6 y §5).
##
## Sin autoload propio (el contrato de Fase 1 congela 10 autoloads): lo invocan
## `TurnManager` (eventos de año) y `DiplomacySystem` (eventos de guerra). Lee y
## muta `GameState.state` y emite en `EventBus`.
##
## Tipos de trigger soportados:
##   - `year_reached`: dispara al alcanzarse `event.year`.
##   - `war`: dispara si las facciones listadas están en guerra (al declararse la
##     guerra o al resolverse el año con la guerra activa).
## Efectos soportados: population_modifier, gold_modifier, stability_modifier,
## prestige_modifier, relation_modifier, casus_belli, peace, tech_unlock,
## army_loss, recruit_pool_modifier. `duration` se ignora en Fase 1.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")


## Procesa los eventos del año. Devuelve las entradas de evento disparadas.
func resolve_year(year: int) -> Array[Dictionary]:
	var fired: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	if st.is_empty():
		return fired
	var candidates: Array[Dictionary] = DataLoader.get_events_for_year(year)
	for event in candidates:
		var event_id: String = SafeDict.as_string(event.get("id"), "")
		if event_id == "" or _already_fired(st, event_id):
			continue
		if not _trigger_ok(event, st):
			continue
		var entry: Dictionary = _fire(event, st, year)
		if not entry.is_empty():
			fired.append(entry)
	return fired


## Procesa eventos de guerra al declararse una guerra (mismo año del evento).
func resolve_war(faction_a: String, faction_b: String, year: int) -> Array[Dictionary]:
	var fired: Array[Dictionary] = []
	var st: Dictionary = GameState.state
	if st.is_empty():
		return fired
	var candidates: Array[Dictionary] = DataLoader.get_events_for_year(year)
	for event in candidates:
		var event_id: String = SafeDict.as_string(event.get("id"), "")
		if event_id == "" or _already_fired(st, event_id):
			continue
		var trigger: Dictionary = SafeDict.as_dict(event.get("trigger", null))
		if SafeDict.as_string(trigger.get("type"), "") != "war":
			continue
		if not _pair_matches(trigger, faction_a, faction_b):
			continue
		var entry: Dictionary = _fire(event, st, year)
		if not entry.is_empty():
			fired.append(entry)
	return fired


## Aplica un evento ya decidido (útil para tests y depuración).
func fire_event_by_id(event_id: String, year: int) -> Dictionary:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return {}
	var event: Dictionary = DataLoader.get_event(event_id)
	if event.is_empty() or _already_fired(st, event_id):
		return {}
	return _fire(event, st, year)


func _already_fired(st: Dictionary, event_id: String) -> bool:
	var fired_events: Array = SafeDict.as_array(st.get("fired_events", null))
	return fired_events.has(event_id)


func _trigger_ok(event: Dictionary, st: Dictionary) -> bool:
	var trigger: Dictionary = SafeDict.as_dict(event.get("trigger", null))
	var trigger_type: String = SafeDict.as_string(trigger.get("type"), "")
	if trigger_type == "year_reached":
		return true
	if trigger_type == "war":
		var factions: Array = SafeDict.as_array(trigger.get("factions", null))
		if factions.size() < 2:
			return false
		return _at_war(st, str(factions[0]), str(factions[1]))
	return false


func _pair_matches(trigger: Dictionary, faction_a: String, faction_b: String) -> bool:
	var factions: Array = SafeDict.as_array(trigger.get("factions", null))
	if factions.size() < 2:
		return false
	var first: String = str(factions[0])
	var second: String = str(factions[1])
	return (first == faction_a and second == faction_b) \
		or (first == faction_b and second == faction_a)


func _at_war(st: Dictionary, faction_a: String, faction_b: String) -> bool:
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	var data_a: Dictionary = SafeDict.as_dict(factions.get(faction_a, null))
	var at_war_a: Array = SafeDict.as_array(data_a.get("at_war", null))
	return at_war_a.has(faction_b)


func _fire(event: Dictionary, st: Dictionary, year: int) -> Dictionary:
	var event_id: String = SafeDict.as_string(event.get("id"), "")
	var news: String = SafeDict.as_string(event.get("news"), event_id)
	var effects: Array = SafeDict.as_array(event.get("effects", null))
	for effect_value in effects:
		var effect: Dictionary = SafeDict.as_dict(effect_value)
		_apply_effect(effect, st)
	# D-067: la Peste Negra también golpea a las casas dinásticas (hook acotado:
	# no mata al gobernante ni al heredero, para no romper la sucesión jugable).
	if event_id.begins_with("peste_negra"):
		DynastySystem.apply_plague_mortality(year)

	var fired_events: Array = SafeDict.as_array(st.get("fired_events", null))
	fired_events.append(event_id)
	st["fired_events"] = fired_events

	var quarter: int = SafeDict.as_int(st.get("quarter"), 1)
	var entry: Dictionary = {
		"year": year,
		"quarter": quarter,
		"event_id": event_id,
		"text": news,
	}
	var event_log: Array = SafeDict.as_array(st.get("event_log", null))
	event_log.append(entry)
	st["event_log"] = event_log

	EventBus.emit_signal("game_event_triggered", event_id, {
		"year": year,
		"quarter": quarter,
		"news": news,
	})
	EventBus.emit_signal("ui_notification", news, 1)
	return entry


# ---------------------------------------------------------------------------
# Efectos
# ---------------------------------------------------------------------------

func _apply_effect(effect: Dictionary, st: Dictionary) -> void:
	var effect_type: String = SafeDict.as_string(effect.get("type"), "")
	var value: float = SafeDict.as_float(effect.get("value"), 0.0)
	match effect_type:
		"population_modifier":
			for region_id in _target_region_ids(effect, st):
				var region: Dictionary = _region(st, region_id)
				if region.is_empty():
					continue
				_scale_population(region, 1.0 + value)
		"gold_modifier":
			for faction_id in _target_faction_ids(effect, st):
				var faction: Dictionary = _faction(st, faction_id)
				if faction.is_empty():
					continue
				faction["gold"] = maxi(0, SafeDict.as_int(faction.get("gold"), 0) + int(roundf(value)))
		"stability_modifier":
			for region_id in _target_region_ids(effect, st):
				var region: Dictionary = _region(st, region_id)
				if region.is_empty():
					continue
				region["support"] = clampi(
					SafeDict.as_int(region.get("support"), Constants.SUPPORT_DEFAULT) + int(roundf(value)),
					Constants.SUPPORT_MIN, Constants.SUPPORT_MAX
				)
		"prestige_modifier":
			for faction_id in _target_faction_ids(effect, st):
				var faction: Dictionary = _faction(st, faction_id)
				if faction.is_empty():
					continue
				faction["prestige"] = maxi(0, SafeDict.as_int(faction.get("prestige"), 0) + int(roundf(value)))
		"relation_modifier":
			_apply_relation_effect(effect, value, st)
		"casus_belli":
			_apply_casus_belli(effect, st)
		"peace":
			_apply_peace(effect, st)
		"tech_unlock":
			_apply_tech_unlock(effect, st)
		"army_loss":
			_apply_army_loss(effect, value, st)
		"recruit_pool_modifier":
			for region_id in _target_region_ids(effect, st):
				var region: Dictionary = _region(st, region_id)
				if region.is_empty():
					continue
				var pool: int = SafeDict.as_int(region.get("recruit_pool"), 0)
				region["recruit_pool"] = maxi(0, int(roundf(float(pool) * (1.0 + value))))
		_:
			pass


func _apply_relation_effect(effect: Dictionary, value: float, st: Dictionary) -> void:
	var faction_id: String = SafeDict.as_string(effect.get("faction"), "")
	var target_id: String = SafeDict.as_string(effect.get("target"), "")
	if faction_id == "" or target_id == "" or faction_id == target_id:
		return
	_add_relation(st, faction_id, target_id, int(roundf(value)))


func _apply_casus_belli(effect: Dictionary, st: Dictionary) -> void:
	var faction_id: String = SafeDict.as_string(effect.get("faction"), "")
	var target_id: String = SafeDict.as_string(effect.get("target"), "")
	if faction_id == "" or target_id == "":
		return
	var faction: Dictionary = _faction(st, faction_id)
	if faction.is_empty():
		return
	var casus_belli: Dictionary = SafeDict.as_dict(faction.get("casus_belli", null))
	casus_belli[target_id] = true
	faction["casus_belli"] = casus_belli


func _apply_peace(effect: Dictionary, st: Dictionary) -> void:
	var faction_id: String = SafeDict.as_string(effect.get("faction"), "")
	var target_id: String = SafeDict.as_string(effect.get("target"), "")
	if faction_id == "" or target_id == "":
		return
	var faction_a: Dictionary = _faction(st, faction_id)
	var faction_b: Dictionary = _faction(st, target_id)
	if faction_a.is_empty() or faction_b.is_empty():
		return
	_remove_from_array(faction_a, "at_war", target_id)
	_remove_from_array(faction_b, "at_war", faction_id)
	EventBus.emit_signal("peace_made", faction_id, target_id)


func _apply_tech_unlock(effect: Dictionary, st: Dictionary) -> void:
	var faction_id: String = SafeDict.as_string(effect.get("faction"), "")
	if faction_id == "":
		return
	var faction: Dictionary = _faction(st, faction_id)
	if faction.is_empty():
		return
	var tech: String = SafeDict.as_string(effect.get("scope"), "")
	if tech == "":
		tech = SafeDict.as_string(effect.get("target"), "")
	if tech == "":
		return
	var techs: Array = SafeDict.as_array(faction.get("techs", null))
	if not techs.has(tech):
		techs.append(tech)
	faction["techs"] = techs


func _apply_army_loss(effect: Dictionary, value: float, st: Dictionary) -> void:
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	var armies: Dictionary = SafeDict.as_dict(st.get("armies", null))
	var faction_ids: Array = _target_faction_ids(effect, st)
	var loss_fraction: float = clampf(value, 0.0, 0.9)
	if loss_fraction <= 0.0:
		return
	for faction_id_v in faction_ids:
		var faction_id: String = str(faction_id_v)
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		if faction.is_empty():
			continue
		var army_ids: Array = SafeDict.sorted_keys(armies)
		for army_id in army_ids:
			var army: Dictionary = SafeDict.as_dict(armies.get(army_id, null))
			if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
				continue
			var units: Array = SafeDict.as_array(army.get("units", null))
			var surviving: Array = []
			for unit_value in units:
				var unit: Dictionary = SafeDict.as_dict(unit_value)
				var size: int = SafeDict.as_int(unit.get("size"), 0)
				var new_size: int = int(roundf(float(size) * (1.0 - loss_fraction)))
				if new_size <= 0:
					continue
				unit["size"] = new_size
				unit["morale"] = maxf(Constants.BATTLE_MIN_MORALE, SafeDict.as_float(unit.get("morale"), 1.0) - 0.1)
				surviving.append(unit)
			army["units"] = surviving
			army["morale"] = maxf(Constants.BATTLE_MIN_MORALE, SafeDict.as_float(army.get("morale"), 1.0) - 0.1)
			if surviving.is_empty():
				armies.erase(army_id)


func _scale_population(region: Dictionary, factor: float) -> void:
	var old_population: int = SafeDict.as_int(region.get("population"), 1000)
	var new_population: int = maxi(1000, int(roundf(float(old_population) * factor)))
	if new_population == old_population:
		region["population"] = new_population
		return
	var ratio: float = float(new_population) / float(maxi(1, old_population))
	var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
	var total: int = 0
	for worker_class in ["farmers", "artisans", "merchants", "recruits"]:
		workers[worker_class] = maxi(0, int(roundf(float(SafeDict.as_int(workers.get(worker_class), 0)) * ratio)))
		total += SafeDict.as_int(workers.get(worker_class), 0)
	if total < 4:
		workers["farmers"] = SafeDict.as_int(workers.get("farmers"), 0) + (4 - total)
	region["workers"] = workers
	region["recruit_pool"] = maxi(0, int(roundf(float(SafeDict.as_int(region.get("recruit_pool"), 0)) * ratio)))
	region["population"] = new_population


# ---------------------------------------------------------------------------
# Resolución de objetivos (región / facción / ámbito)
# ---------------------------------------------------------------------------

func _target_region_ids(effect: Dictionary, st: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var region_id: String = SafeDict.as_string(effect.get("region"), "")
	if region_id != "":
		if regions.has(region_id):
			result.append(region_id)
		return result
	var faction_ids: Array = _target_faction_ids(effect, st)
	for faction_id_v in faction_ids:
		var faction_id: String = str(faction_id_v)
		for region_key in SafeDict.sorted_keys(regions):
			var region: Dictionary = SafeDict.as_dict(regions.get(region_key, null))
			if SafeDict.as_string(region.get("owner"), "") == faction_id:
				result.append(region_key)
	return result


func _target_faction_ids(effect: Dictionary, st: Dictionary) -> Array:
	var result: Array = []
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	var faction_id: String = SafeDict.as_string(effect.get("faction"), "")
	if faction_id != "":
		if factions.has(faction_id):
			result.append(faction_id)
		return result
	var region_id: String = SafeDict.as_string(effect.get("region"), "")
	if region_id != "":
		var region: Dictionary = _region(st, region_id)
		var owner: String = SafeDict.as_string(region.get("owner"), "")
		if owner != "" and factions.has(owner):
			result.append(owner)
		return result
	var scope: String = SafeDict.as_string(effect.get("scope"), "europe")
	var scope_factions: Array = SafeDict.as_array(Constants.SCOPE_FACTIONS.get(scope, null))
	for scope_faction in scope_factions:
		if factions.has(str(scope_faction)):
			result.append(str(scope_faction))
	return result


func _region(st: Dictionary, region_id: String) -> Dictionary:
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	return SafeDict.as_dict(regions.get(region_id, null))


func _faction(st: Dictionary, faction_id: String) -> Dictionary:
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	return SafeDict.as_dict(factions.get(faction_id, null))


func _add_relation(st: Dictionary, faction_a: String, faction_b: String, delta: int) -> void:
	for pair in [[faction_a, faction_b], [faction_b, faction_a]]:
		var faction: Dictionary = _faction(st, str(pair[0]))
		if faction.is_empty():
			continue
		var relations: Dictionary = SafeDict.as_dict(faction.get("relations", null))
		var current: int = SafeDict.as_int(relations.get(str(pair[1])), 0)
		relations[str(pair[1])] = clampi(current + delta, Constants.RELATION_MIN, Constants.RELATION_MAX)
		faction["relations"] = relations
	EventBus.emit_signal("relation_changed", faction_a, faction_b,
		_get_relation(st, faction_a, faction_b))


func _get_relation(st: Dictionary, faction_a: String, faction_b: String) -> int:
	var faction: Dictionary = _faction(st, faction_a)
	if faction.is_empty():
		return 0
	var relations: Dictionary = SafeDict.as_dict(faction.get("relations", null))
	return SafeDict.as_int(relations.get(faction_b), 0)


func _remove_from_array(owner: Dictionary, key: String, value: String) -> void:
	var items: Array = SafeDict.as_array(owner.get(key, null))
	var filtered: Array = []
	for item in items:
		if str(item) != value:
			filtered.append(item)
	owner[key] = filtered
