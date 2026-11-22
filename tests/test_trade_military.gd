extends RefCounted
## Tests Fase 4 D-069/D-070: mercancías/comercio y gestión global de ejércitos.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const PLAYER: String = "england"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_trade_data(runner, h)
	_check_production(runner, h)
	_check_merchants_and_prices(runner, h)
	_check_buy_sell_expedition(runner, h)
	_check_recruitment_goods(runner, h)
	_check_army_management(runner, h)
	_check_determinism_and_balance(runner, h)


func _check_trade_data(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_data")
	var goods: Array[String] = h.trade_goods_ids()
	runner.check_eq("10 mercancías en trade_goods.json", 10, goods.size())
	for good_id in ["especias", "pieles", "lana", "vino", "sal", "grano", "armas", "caballos", "hierro", "madera"]:
		runner.check("mercancía %s" % good_id, goods.has(good_id))
	h.new_game(PLAYER)
	var inventory: Dictionary = h.trade_inventory(PLAYER)
	runner.check_eq("inventario con 10 bienes", 10, inventory.size())
	for good_id in goods:
		runner.check("inventario inicial de %s >= 0" % good_id,
			SafeDict.as_float(inventory.get(good_id), -1.0) >= 0.0)
	runner.check("estado trade serializable", JSON.stringify(h.state().get("trade", null)).length() > 50)
	runner.check("comercio inicial requiere comerciantes", not h.can_trade(PLAYER))


func _check_production(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_production")
	h.new_game(PLAYER)
	var before: Dictionary = h.trade_inventory(PLAYER)
	var result: Dictionary = h.produce_trade(PLAYER)
	runner.check("produce_quarter devuelve ok", bool(result.get("ok")), str(result))
	var after: Dictionary = h.trade_inventory(PLAYER)
	var produced_any: bool = false
	for good_id in h.trade_goods_ids():
		if SafeDict.as_float(after.get(good_id), 0.0) > SafeDict.as_float(before.get(good_id), 0.0):
			produced_any = true
	runner.check("la producción trimestral aumenta inventario", produced_any, str(after))
	# Inglaterra tiene regiones de llanura/bosque/ciudad: grano o madera/especias.
	runner.check("Inglaterra produce grano y/o madera",
		SafeDict.as_float(after.get("grano"), 0.0) > SafeDict.as_float(before.get("grano"), 0.0)
		or SafeDict.as_float(after.get("madera"), 0.0) > SafeDict.as_float(before.get("madera"), 0.0))
	runner.check("los precios regionales se calculan", h.good_price(PLAYER, "grano") > 0.0)


func _check_merchants_and_prices(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_merchants_prices")
	h.new_game(PLAYER)
	runner.check("sin comerciantes no hay precio de compra válido",
		not h.can_trade(PLAYER), str(h.trade_error()))
	h.set_merchants(PLAYER, 8)
	runner.check("asignar comerciantes", h.trade_merchants(PLAYER) == 8)
	runner.check("con comerciantes se puede comerciar", h.can_trade(PLAYER))
	h.produce_trade(PLAYER)
	var price_a: float = h.good_price(PLAYER, "grano")
	var price_b: float = h.good_price(PLAYER, "grano")
	runner.check("precio consultable y positivo", price_a > 0.0)
	runner.check("mismo estado → mismo precio", is_equal_approx(price_a, price_b))
	# Determinismo de precios con la misma semilla y producción.
	h.new_game(PLAYER, 1337)
	h.set_merchants(PLAYER, 8)
	h.produce_trade(PLAYER)
	var first_prices: Array[float] = []
	for good_id in h.trade_goods_ids():
		first_prices.append(h.good_price(PLAYER, good_id))
	h.new_game(PLAYER, 1337)
	h.set_merchants(PLAYER, 8)
	h.produce_trade(PLAYER)
	var stable: bool = true
	var index: int = 0
	for good_id in h.trade_goods_ids():
		if not is_equal_approx(first_prices[index], h.good_price(PLAYER, good_id)):
			stable = false
		index += 1
	runner.check("precios deterministas con la misma semilla", stable)


func _check_buy_sell_expedition(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_buy_sell")
	h.new_game(PLAYER)
	var region: String = _first_owned_region(h, PLAYER)
	h.set_merchants(PLAYER, 5)
	var gold_before: int = h.treasury(PLAYER)
	var inv_before: float = SafeDict.as_float(h.trade_inventory(PLAYER).get("grano"), 0.0)
	runner.check("comprar grano", h.buy_good(PLAYER, region, "grano", 5), h.trade_error())
	runner.check("la compra sube inventario", SafeDict.as_float(h.trade_inventory(PLAYER).get("grano"), 0.0) >= inv_before + 5.0)
	runner.check("la compra baja oro", h.treasury(PLAYER) < gold_before)
	var gold_after_buy: int = h.treasury(PLAYER)
	runner.check("vender grano", h.sell_good(PLAYER, region, "grano", 2), h.trade_error())
	runner.check("la venta sube oro", h.treasury(PLAYER) > gold_after_buy)
	runner.check("volumen limitado por comerciantes", not h.buy_good(PLAYER, region, "grano", 999))
	# Expedición: 2 PG y retorno a 2 trimestres.
	h.set_merchants(PLAYER, 5)
	var pg_before: int = h.remaining_pg()
	var gold_exp_before: int = h.treasury(PLAYER)
	runner.check("enviar expedición", h.send_expedition(PLAYER, "grano", 3), h.trade_error())
	runner.check_eq("expedición cuesta 2 PG", pg_before - 2, h.remaining_pg())
	var return_turn: int = 0
	for expedition_value in h.trade.call("get_expeditions"):
		var expedition: Dictionary = SafeDict.as_dict(expedition_value)
		return_turn = SafeDict.as_int(expedition.get("return_turn"), 0)
	runner.check("expedición programada a +2 turnos", return_turn == SafeDict.as_int(h.state().get("turn"), 0) + 2)
	h.state()["turn"] = return_turn
	runner.check_eq("expedición resuelta al volver", 1, h.process_expeditions())
	runner.check("la expedición devuelve oro", h.treasury(PLAYER) > gold_exp_before)


func _check_recruitment_goods(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_recruitment")
	h.new_game(PLAYER)
	var region: String = "region_londres"
	var caballos_before: float = SafeDict.as_float(h.trade_inventory(PLAYER).get("caballos"), 0.0)
	runner.check("reclutar caballería con mercancías", h.recruit(PLAYER, region, "men_at_arms", 400),
		h.recruit_reason())
	var caballos_after: float = SafeDict.as_float(h.trade_inventory(PLAYER).get("caballos"), 0.0)
	runner.check("el reclutamiento consume caballos (2 bloques × 2)",
		caballos_before - caballos_after >= 4.0, "%f → %f" % [caballos_before, caballos_after])
	# Sin mercancías falla con motivo y no cambia el oro.
	h.state()["trade"]["inventory"][PLAYER]["caballos"] = 0.0
	var gold_before: int = h.treasury(PLAYER)
	runner.check("reclutar sin caballos falla", not h.recruit(PLAYER, region, "men_at_arms", 200))
	runner.check("motivo de reclutamiento por mercancías",
		h.recruit_reason().to_lower().contains("mercancías"), h.recruit_reason())
	runner.check_eq("el fallo no gasta oro", gold_before, h.treasury(PLAYER))


func _check_army_management(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("army_management")
	h.new_game(PLAYER)
	var summary: Array[Dictionary] = h.army_summary(PLAYER)
	runner.check("resumen global de ejércitos no vacío", not summary.is_empty())
	var first: Dictionary = summary[0] if not summary.is_empty() else {}
	if not first.is_empty():
		runner.check("el resumen trae count/men/strength",
			first.has("count") and first.has("men") and first.has("strength"))
		runner.check("el resumen trae sprite march_1",
			SafeDict.as_string(first.get("sprite_path"), "").ends_with("_march_1.png"),
			str(first.get("sprite_path")))
		runner.check("el resumen trae moral/experiencia medias",
			first.has("avg_morale") and first.has("avg_experience"))
	# Entrenar una unidad: sube experiencia, cuesta oro + 1 PG.
	var unit_id: String = "men_at_arms"
	var exp_before: int = _experience_of(h, PLAYER, unit_id)
	var gold_before: int = h.treasury(PLAYER)
	var pg_before: int = h.remaining_pg()
	runner.check("entrenar unidad", h.train_unit(PLAYER, unit_id, 10), h.train_reason())
	runner.check("la experiencia sube", _experience_of(h, PLAYER, unit_id) > exp_before)
	runner.check("entrenar cuesta oro", h.treasury(PLAYER) < gold_before)
	runner.check_eq("entrenar cuesta 1 PG", pg_before - 1, h.remaining_pg())
	# Disolver unidad: libera pool y devuelve oro.
	var men_before: int = _men_of(h, PLAYER, unit_id)
	var pool_before: int = _pool_total(h)
	var gold_disband_before: int = h.treasury(PLAYER)
	runner.check("disolver unidad", h.disband_unit(PLAYER, unit_id, 200))
	runner.check("disolver reduce hombres", _men_of(h, PLAYER, unit_id) < men_before)
	runner.check("disolver libera pool", _pool_total(h) > pool_before)
	runner.check("disolver devuelve oro", h.treasury(PLAYER) > gold_disband_before)
	# Disolver ejército completo sin dejar huérfanos.
	var created: Dictionary = h.create_army(PLAYER, "region_londres")
	var army_id: String = SafeDict.as_string(created.get("id"), "")
	runner.check("crear ejército para disolver", army_id != "")
	if army_id != "":
		runner.check("disolver ejército", h.disband_army(army_id))
		runner.check("el ejército disuelto desaparece", h.army(army_id).is_empty())
	for check_army_id in SafeDict.sorted_keys(h.armies()):
		runner.check("ejército %s sin unidades huérfanas" % check_army_id,
			not SafeDict.as_array(h.army(check_army_id).get("units", null)).is_empty())


func _check_determinism_and_balance(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("trade_balance")
	# Determinismo de una secuencia comercio completa.
	h.new_game(PLAYER, 1337)
	h.set_merchants(PLAYER, 5)
	h.produce_trade(PLAYER)
	h.buy_good(PLAYER, _first_owned_region(h, PLAYER), "grano", 2)
	var hash_a: int = h.state_hash()
	h.new_game(PLAYER, 1337)
	h.set_merchants(PLAYER, 5)
	h.produce_trade(PLAYER)
	h.buy_good(PLAYER, _first_owned_region(h, PLAYER), "grano", 2)
	runner.check_eq("comercio determinista con la misma semilla", hash_a, h.state_hash())
	# 10 años × 8 facciones con comercio activo: sin NaN/negativos ni crash.
	var playable: Array[String] = h.playable_factions("scenario_1337")
	var started_ms: int = Time.get_ticks_msec()
	var min_gold_ratio: float = 999.0
	var max_gold_ratio: float = 0.0
	for faction_id in playable:
		h.new_game(faction_id)
		var start_gold: int = maxi(1, h.treasury(faction_id))
		for _year in 10:
			for _quarter in 4:
				if h.is_game_over():
					break
				h.end_turn()
			if h.is_game_over():
				break
		var inventory: Dictionary = h.trade_inventory(faction_id)
		for good_id in inventory.keys():
			var amount: float = SafeDict.as_float(inventory.get(good_id), -1.0)
			if amount < 0.0:
				runner.check("inventario válido %s/%s" % [faction_id, good_id], false, str(amount))
		var ratio: float = float(h.treasury(faction_id)) / float(start_gold)
		min_gold_ratio = minf(min_gold_ratio, ratio)
		max_gold_ratio = maxf(max_gold_ratio, ratio)
		runner.check("estado de %s serializable tras 10 años" % faction_id,
			JSON.stringify(h.state()).length() > 1000)
		runner.check("oro de %s sin espiral" % faction_id, ratio <= 3.0, "x%.2f" % ratio)
	var elapsed: int = Time.get_ticks_msec() - started_ms
	print("  [INFO] comercio 10 años x %d: %d ms; ratio oro %.2f–%.2f" % [
		playable.size(), elapsed, min_gold_ratio, max_gold_ratio,
	])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _first_owned_region(h: HarnessScript, faction_id: String) -> String:
	for region_id in SafeDict.sorted_keys(h.regions()):
		if SafeDict.as_string(h.region(region_id).get("owner"), "") == faction_id:
			return region_id
	return ""


func _experience_of(h: HarnessScript, faction_id: String, unit_id: String) -> int:
	var total: int = 0
	var count: int = 0
	for army_id in SafeDict.sorted_keys(h.armies()):
		var army: Dictionary = h.army(army_id)
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			if SafeDict.as_string(unit.get("unit_id"), "") == unit_id:
				total += SafeDict.as_int(unit.get("experience"), 0)
				count += 1
	return total / maxi(1, count)


func _pool_total(h: HarnessScript) -> int:
	var total: int = 0
	for region_id in SafeDict.sorted_keys(h.regions()):
		total += h.recruitment_pool(region_id)
	return total


func _men_of(h: HarnessScript, faction_id: String, unit_id: String) -> int:
	var total: int = 0
	for army_id in SafeDict.sorted_keys(h.armies()):
		var army: Dictionary = h.army(army_id)
		if SafeDict.as_string(army.get("faction_id"), "") != faction_id:
			continue
		for unit_value in SafeDict.as_array(army.get("units", null)):
			var unit: Dictionary = SafeDict.as_dict(unit_value)
			if SafeDict.as_string(unit.get("unit_id"), "") == unit_id:
				total += SafeDict.as_int(unit.get("size"), 0)
	return total
