extends SceneTree
## Simulación headless de balance 1337 (D-066 §2.4 / D-067):
## 10 años (40 trimestres) por cada facción jugable, sin órdenes del jugador.
## Imprime tesoro inicial/final, ingresos/mantenimiento iniciales, regiones,
## apoyo mínimo y motivo de fin si la partida termina antes.
##
## Uso: godot --headless --path <repo> --script tools/simulate_balance_1337.gd

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const YEARS: int = 10


func _initialize() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	var dl: Node = root.get_node_or_null("DataLoader")
	var eco: Node = root.get_node_or_null("EconomySystem")
	var tm: Node = root.get_node_or_null("TurnManager")
	if gs == null or dl == null or eco == null or tm == null:
		print("SIMULACIÓN: faltan autoloads")
		quit(1)
		return
	var playable: Array = []
	dl.call("load_all")
	var value: Variant = gs.call("get_playable_factions", "scenario_1337")
	if value is Array:
		playable = value
	print("SIMULACIÓN BALANCE 1337 — %d facciones x %d años" % [playable.size(), YEARS])
	print("faction             start_gold  gross/q  upkeep/q  final_gold  regions  min_support  end")
	for faction_id_value in playable:
		var faction_id: String = str(faction_id_value)
		gs.call("new_game", "scenario_1337", faction_id, 1337)
		var faction: Dictionary = gs.call("get_faction_state", faction_id)
		var start_gold: int = SafeDict.as_int(faction.get("gold"), 0)
		var gross: float = _gross_income(gs, eco, faction_id)
		var upkeep: int = SafeDict.as_int(eco.call("_army_upkeep", faction_id), 0)
		var min_support: int = 100
		var over_reason: String = ""
		for _year_index in YEARS:
			for _quarter in 4:
				if SafeDict.as_bool((gs.get("state") as Dictionary).get("game_over"), false):
					break
				tm.call("end_turn")
			var st: Dictionary = gs.get("state")
			if SafeDict.as_bool(st.get("game_over"), false):
				over_reason = SafeDict.as_string(st.get("game_over_reason"), "")
				break
			for region_id_value in (SafeDict.as_dict(st.get("regions", null)) as Dictionary).keys():
				var region: Dictionary = SafeDict.as_dict(SafeDict.as_dict(st.get("regions", null)).get(region_id_value, null))
				if SafeDict.as_string(region.get("owner"), "") == faction_id:
					min_support = mini(min_support, SafeDict.as_int(region.get("support"), 60))
		var final_st: Dictionary = gs.get("state")
		var final_faction: Dictionary = gs.call("get_faction_state", faction_id)
		var final_gold: int = SafeDict.as_int(final_faction.get("gold"), 0)
		var regions_count: int = _owned_regions(final_st, faction_id)
		print("%-20s %10d %8.1f %9d %11d %8d %12d  %s" % [
			faction_id, start_gold, gross, upkeep, final_gold, regions_count, min_support,
			over_reason if over_reason != "" else "ok",
		])
	quit(0)


func _gross_income(gs: Node, eco: Node, faction_id: String) -> float:
	var st: Dictionary = gs.get("state")
	var faction: Dictionary = gs.call("get_faction_state", faction_id)
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var total: float = 0.0
	for region_id_value in regions.keys():
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id_value, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var output: Dictionary = eco.call("get_region_output", str(region_id_value))
		total += SafeDict.as_float(output.get("gold_income"), 0.0)
	return total


func _owned_regions(st: Dictionary, faction_id: String) -> int:
	var count: int = 0
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	for region_id_value in regions.keys():
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id_value, null))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			count += 1
	return count
