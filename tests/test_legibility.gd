extends RefCounted
## Tests Fase 5A (D-079…D-083): acciones del turno, crónica, estaciones,
## consejo comercial determinista y conmutador del Consejero.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const PLAYER: String = "england"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_turn_actions(runner, h)
	_check_chronicle(runner, h)
	_check_seasons(runner, h)
	_check_trade_advice(runner, h)
	_check_advisor(runner, h)
	_check_data_texts(runner, h)


func _check_turn_actions(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_turn_actions")
	h.new_game(PLAYER)
	runner.check("turn_actions empieza vacío", h.turn_actions().is_empty())
	h.record_turn_action("diplomacy:alliance", "france", 8)
	h.record_turn_action("build", "region_londres:granary", 2)
	var entries: Array[Dictionary] = h.turn_actions()
	runner.check_eq("se registran 2 órdenes", 2, entries.size())
	runner.check_eq("la orden guarda acción/target/PG", "diplomacy:alliance",
		SafeDict.as_string(entries[0].get("action"), ""))
	runner.check_eq("target de la orden", "france", SafeDict.as_string(entries[0].get("target"), ""))
	runner.check_eq("PG de la orden", 8, SafeDict.as_int(entries[0].get("pg"), 0))
	# No se serializa (D-081): el hash no cambia al registrar órdenes.
	var hash_before: int = h.state_hash()
	h.record_turn_action("test", "x", 0)
	runner.check_eq("turn_actions no altera el hash serializado", hash_before, h.state_hash())
	runner.check("to_dict no incluye turn_actions", not h.gs.call("to_dict").has("turn_actions"))
	runner.check("guardar con turn_actions", h.save_game("legibility_actions"))
	h.clear_turn_actions()
	runner.check("cargar con turn_actions", h.load_game("legibility_actions"))
	runner.check("turn_actions no se restaura del save", h.turn_actions().is_empty())
	# Reset al empezar turno.
	h.record_turn_action("test", "y", 1)
	h.begin_turn(PLAYER)
	runner.check("begin_turn limpia turn_actions", h.turn_actions().is_empty())
	# Sistemas que gastan PG registran órdenes.
	h.new_game(PLAYER)
	h.faction(PLAYER)["pg"] = 80
	h.propose(PLAYER, "scotland", {"type": "declare_war"})
	runner.check("diplomacia registra orden", not h.turn_actions().is_empty())
	var found_diplomacy: bool = false
	for entry in h.turn_actions():
		if SafeDict.as_string(entry.get("action"), "").begins_with("diplomacy:"):
			found_diplomacy = true
	runner.check("acción de diplomacia presente", found_diplomacy)


func _check_chronicle(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_chronicle")
	h.new_game(PLAYER)
	runner.check("crónica empieza vacía", h.chronicle().is_empty())
	var entry: Dictionary = h.append_chronicle({
		"year": 1340,
		"season_or_year": "Primavera 1340",
		"kind": "quarter",
		"text": "La corte prospera.",
	})
	runner.check("append_chronicle devuelve entrada", not entry.is_empty())
	runner.check_eq("crónica con 1 entrada", 1, h.chronicle().size())
	runner.check("get_chronicle_text contiene el texto", h.chronicle_text().contains("La corte prospera."))
	h.append_chronicle({"year": 1341, "season_or_year": "Invierno 1341", "kind": "year", "text": "Fin de año."})
	runner.check_eq("filtro por año", 1, h.chronicle(1340).size())
	# Round-trip: la crónica se serializa y el hash se conserva.
	var hash_before: int = h.state_hash()
	runner.check("guardar con crónica", h.save_game("legibility_chronicle"))
	runner.check("cargar con crónica", h.load_game("legibility_chronicle"))
	runner.check_eq("hash exacto con crónica", hash_before, h.state_hash())
	runner.check_eq("crónica persiste", 2, h.chronicle().size())
	# Save antiguo sin chronicle/turn_actions/advisor: defaults, sin subir versión.
	var old_save: Dictionary = SafeDict.as_dict(h.gs.call("to_dict"))
	old_save.erase("chronicle")
	old_save.erase("turn_actions")
	old_save.erase("advisor_enabled")
	old_save["save_version"] = 1
	runner.check("from_dict acepta save antiguo", bool(h.gs.call("from_dict", old_save)))
	runner.check("default chronicle []", h.chronicle().is_empty())
	runner.check("default turn_actions []", h.turn_actions().is_empty())
	runner.check("default advisor_enabled bool", typeof(h.gs.get("state").get("advisor_enabled", null)) == TYPE_BOOL)


func _check_seasons(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_seasons")
	h.new_game(PLAYER)
	h.state()["quarter"] = 1
	runner.check_eq("trimestre 1 = Primavera", "Primavera", h.season_name())
	runner.check_eq("trimestre 2 = Verano", "Verano", h.season_name(2))
	runner.check_eq("trimestre 3 = Otoño", "Otoño", h.season_name(3))
	runner.check_eq("trimestre 4 = Invierno", "Invierno", h.season_name(4))
	h.state()["quarter"] = 4
	runner.check_eq("season_index = trimestre", 4, h.season_index())
	var label: String = h.season_label()
	runner.check("season_label incluye estación y año", label.contains("Invierno") and label.contains("1337"), label)


func _check_trade_advice(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_trade_advice")
	h.new_game(PLAYER)
	h.set_merchants(PLAYER, 10)
	h.produce_trade(PLAYER)
	var advice_a: Dictionary = h.trade_advice(PLAYER)
	var advice_b: Dictionary = h.trade_advice(PLAYER)
	runner.check("consejo comercial ok", bool(advice_a.get("ok")), str(advice_a))
	runner.check("consejo incluye good/kind/margin/text",
		advice_a.has("good_id") and advice_a.has("kind") and advice_a.has("margin") and advice_a.has("text"))
	runner.check("consejo determinista", JSON.stringify(advice_a) == JSON.stringify(advice_b))
	# Construye precios alto/bajo explícitos y elige el mayor margen de venta.
	var region: String = _first_owned_region(h, PLAYER)
	h.produce_trade(PLAYER)
	var base: float = float(h.trade.call("get_base_price", "grano"))
	h.state()["trade"]["prices"][region] = {
		"grano": base * 2.0,
		"madera": float(h.trade.call("get_base_price", "madera")) * 0.5,
	}
	h.state()["trade"]["inventory"][PLAYER]["grano"] = 10.0
	h.state()["trade"]["inventory"][PLAYER]["madera"] = 10.0
	var high: Dictionary = h.trade_advice(PLAYER, region)
	runner.check("elige el bien con mayor margen", SafeDict.as_string(high.get("good_id"), "") == "grano", str(high))
	runner.check_eq("consejo de venta", "sell", SafeDict.as_string(high.get("kind"), ""))
	runner.check("margen alto positivo", SafeDict.as_float(high.get("margin"), 0.0) > 0.5, str(high.get("margin")))
	# Sin inventario → consejo de compra (si hay comerciantes).
	for good_id in h.trade_goods_ids():
		h.state()["trade"]["inventory"][PLAYER][good_id] = 0.0
	var buy_advice: Dictionary = h.trade_advice(PLAYER, region)
	runner.check("sin inventario sugiere comprar", SafeDict.as_string(buy_advice.get("kind"), "") == "buy", str(buy_advice))
	# Sin comerciantes el consejo sigue calculando una recomendación, marcando can_trade=false.
	h.set_merchants(PLAYER, 0)
	var no_trade: Dictionary = h.trade_advice(PLAYER)
	runner.check("sin comerciantes el consejo sigue siendo determinista y marca can_trade=false",
		not bool(no_trade.get("can_trade", true)), str(no_trade))


func _check_advisor(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_advisor")
	h.new_game(PLAYER)
	runner.check("normal: consejero desactivado", not h.advisor_enabled())
	h.new_game_with_difficulty(PLAYER, "beginner")
	runner.check("beginner: consejero activado", h.advisor_enabled())
	h.set_advisor_enabled(false)
	runner.check("conmutar consejero", not h.advisor_enabled())
	runner.check("guardar con advisor", h.save_game("legibility_advisor"))
	h.set_advisor_enabled(true)
	h.load_game("legibility_advisor")
	runner.check("advisor persistido", not h.advisor_enabled())
	h.new_game(PLAYER)
	var old_save: Dictionary = SafeDict.as_dict(h.gs.call("to_dict"))
	old_save.erase("advisor_enabled")
	old_save["save_version"] = 1
	runner.check("from_dict viejo con advisor", bool(h.gs.call("from_dict", old_save)))
	runner.check("default advisor según dificultad", h.advisor_enabled() == (h.difficulty() == "beginner"))


func _check_data_texts(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("legibility_data")
	if FileAccess.file_exists("res://data/context_help.json"):
		var help: Dictionary = h.context_help("world_map")
		runner.check("context_help world_map tiene título/líneas",
			not help.is_empty() and help.has("title") and help.has("lines"))
		var screens: Array = h.dl.call("get_context_help_screens")
		runner.check_eq("18 contextos de ayuda", 18, screens.size())
	else:
		runner.check("context_help opcional (no presente)", true)
	if FileAccess.file_exists("res://data/legibility_texts.json"):
		var texts: Dictionary = h.legibility_texts()
		runner.check("legibility_texts tiene seasons/hud/bulletin",
			texts.has("seasons") and texts.has("hud") and texts.has("quarterly_bulletin"))
		var seasons: Array = SafeDict.as_array(texts.get("seasons", null))
		runner.check_eq("4 estaciones en legibility_texts", 4, seasons.size())
	else:
		runner.check("legibility_texts opcional (no presente)", true)


func _first_owned_region(h: HarnessScript, faction_id: String) -> String:
	for region_id in SafeDict.sorted_keys(h.regions()):
		if SafeDict.as_string(h.region(region_id).get("owner"), "") == faction_id:
			return region_id
	return ""
