extends Node
## TradeSystem — mercancías, comercio y expediciones (Fase 4, D-069).
##
## Estado serializable en `GameState.state.trade`:
##   inventory {faction → {good → float}}, prices {region → {good → float}},
##   merchants_assigned {faction → int}, trade_pacts [], expeditions [].
##
## Datos: `data/trade_goods.json` (envelope D-009, AG-1). Sin comerciantes
## asignados no se puede comprar/vender; el volumen depende de ellos. Los
## precios parten del `base_price` y se ajustan por inventario (escasez) con un
## pequeño jitter del RNG central, por lo que son deterministas con la semilla.
## El comercio exterior usa pactos o expediciones (2 PG, retorno a 2 trimestres).

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const Constants = preload("res://scripts/utils/game_constants.gd")
const TRADE_GOODS_PATH: String = "res://data/trade_goods.json"

## Campos mínimos de estado; se crean/migran de forma perezosa.
const DEFAULT_STATE: Dictionary = {
	"inventory": {},
	"prices": {},
	"merchants_assigned": {},
	"trade_pacts": [],
	"expeditions": [],
	"last_production_turn": {},
}

var _goods: Dictionary = {}
var _loaded: bool = false
var last_error: String = ""


func _ready() -> void:
	load_goods()


## Carga/recarga definiciones de `trade_goods.json`.
func load_goods() -> bool:
	_goods.clear()
	_loaded = true
	if not FileAccess.file_exists(TRADE_GOODS_PATH):
		last_error = "no existe %s" % TRADE_GOODS_PATH
		return false
	var file := FileAccess.open(TRADE_GOODS_PATH, FileAccess.READ)
	if file == null:
		last_error = "no se puede abrir %s" % TRADE_GOODS_PATH
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		last_error = "JSON inválido %s" % TRADE_GOODS_PATH
		return false
	var data: Dictionary = SafeDict.as_dict(json.data)
	var goods_value: Variant = data.get("trade_goods", null)
	if goods_value is Dictionary:
		for good_id in SafeDict.sorted_keys(goods_value as Dictionary):
			_goods[str(good_id)] = SafeDict.as_dict((goods_value as Dictionary).get(good_id, null))
	return not _goods.is_empty()


func reload_goods() -> bool:
	return load_goods()


func get_goods_ids() -> Array[String]:
	var result: Array[String] = []
	for good_id in SafeDict.sorted_keys(_goods):
		result.append(good_id)
	return result


func get_good_definition(good_id: String) -> Dictionary:
	return SafeDict.as_dict(_goods.get(good_id, null))


func get_base_price(good_id: String) -> float:
	return SafeDict.as_float(get_good_definition(good_id).get("base_price"), 1.0)


func get_goods_count() -> int:
	return _goods.size()


# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

## Garantiza `GameState.state.trade` completo y con todas las facciones/bienes.
func ensure_state() -> Dictionary:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return {}
	if not _loaded:
		load_goods()
	var trade_value: Variant = st.get("trade", null)
	var trade: Dictionary = SafeDict.as_dict(trade_value)
	if trade.is_empty():
		trade = DEFAULT_STATE.duplicate(true)
		for faction_id in SafeDict.sorted_keys(SafeDict.as_dict(st.get("factions", null))):
			trade["inventory"][str(faction_id)] = {}
			trade["merchants_assigned"][str(faction_id)] = 0
			trade["last_production_turn"][str(faction_id)] = 0
		st["trade"] = trade
	for key in ["inventory", "prices", "merchants_assigned", "trade_pacts", "expeditions", "last_production_turn"]:
		if not trade.has(key):
			trade[key] = DEFAULT_STATE[key].duplicate(true)
	var factions: Dictionary = SafeDict.as_dict(st.get("factions", null))
	for faction_id in SafeDict.sorted_keys(factions):
		var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
		if inventory.is_empty():
			inventory = {}
		for good_id in SafeDict.sorted_keys(_goods):
			if not inventory.has(good_id):
				inventory[good_id] = float(Constants.TRADE_INITIAL_STOCK)
		trade["inventory"][faction_id] = inventory
		if not trade["merchants_assigned"].has(faction_id):
			trade["merchants_assigned"][faction_id] = 0
		if not trade["last_production_turn"].has(faction_id):
			trade["last_production_turn"][faction_id] = 0
	# Sincroniza pactos comerciales existentes de DiplomacySystem/facciones.
	var pacts: Array = SafeDict.as_array(trade.get("trade_pacts", null))
	for faction_id in SafeDict.sorted_keys(factions):
		var faction: Dictionary = SafeDict.as_dict(factions.get(faction_id, null))
		for target_value in SafeDict.as_array(faction.get("trade_pacts", null)):
			var target: String = str(target_value)
			if target == "" or target == faction_id:
				continue
			var pair: Array = [faction_id, target]
			if not _pair_in(pacts, faction_id, target):
				pacts.append(pair)
	trade["trade_pacts"] = pacts
	return trade


func _pair_in(pacts: Array, a: String, b: String) -> bool:
	for pair_value in pacts:
		var pair: Array = SafeDict.as_array(pair_value)
		if pair.size() < 2:
			continue
		if (str(pair[0]) == a and str(pair[1]) == b) or (str(pair[0]) == b and str(pair[1]) == a):
			return true
	return false


# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

func get_inventory(faction_id: String) -> Dictionary:
	var trade: Dictionary = ensure_state()
	var inventory: Dictionary = SafeDict.as_dict(SafeDict.as_dict(trade.get("inventory", null)).get(faction_id, null))
	return inventory.duplicate(true)


func get_good_amount(faction_id: String, good_id: String) -> float:
	return SafeDict.as_float(get_inventory(faction_id).get(good_id), 0.0)


func get_merchants(faction_id: String) -> int:
	var trade: Dictionary = ensure_state()
	return SafeDict.as_int(SafeDict.as_dict(trade.get("merchants_assigned", null)).get(faction_id), 0)


## Comerciantes disponibles en las regiones de la facción (tope de asignación).
func get_available_merchants(faction_id: String) -> int:
	var st: Dictionary = GameState.state
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var total: int = 0
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var workers: Dictionary = SafeDict.as_dict(region.get("workers", null))
		total += SafeDict.as_int(workers.get("merchants"), 0)
	return total


## Asigna comerciantes al comercio (sin gastar PG; la UI decide). 0..disponibles.
func set_merchants(faction_id: String, amount: int) -> bool:
	var trade: Dictionary = ensure_state()
	if not trade.has("merchants_assigned"):
		return false
	var available: int = get_available_merchants(faction_id)
	trade["merchants_assigned"][faction_id] = clampi(amount, 0, available)
	return true


func assign_merchants(faction_id: String, amount: int) -> bool:
	return set_merchants(faction_id, amount)


func can_trade(faction_id: String) -> bool:
	if GameState.get_faction_state(faction_id).is_empty():
		return false
	return get_merchants(faction_id) > 0


func has_trade_pact(faction_a: String, faction_b: String) -> bool:
	var trade: Dictionary = ensure_state()
	if _pair_in(SafeDict.as_array(trade.get("trade_pacts", null)), faction_a, faction_b):
		return true
	var faction: Dictionary = GameState.get_faction_state(faction_a)
	return SafeDict.as_array(faction.get("trade_pacts", null)).has(faction_b)


func get_trade_pacts() -> Array:
	return SafeDict.as_array(ensure_state().get("trade_pacts", null)).duplicate(true)


func get_expeditions() -> Array:
	return SafeDict.as_array(ensure_state().get("expeditions", null)).duplicate(true)


func get_last_error() -> String:
	return last_error


# ---------------------------------------------------------------------------
# Producción y precios
# ---------------------------------------------------------------------------

## Produce mercancías de todas las facciones (llamado una vez por trimestre).
func produce_quarter_all() -> Dictionary:
	var st: Dictionary = GameState.state
	var result: Dictionary = {"ok": true, "factions": 0, "expeditions_resolved": 0}
	if st.is_empty():
		return result
	for faction_id in SafeDict.sorted_keys(SafeDict.as_dict(st.get("factions", null))):
		produce_quarter(str(faction_id))
	result["expeditions_resolved"] = process_expeditions()
	result["factions"] = SafeDict.as_dict(st.get("factions", null)).size()
	return result


## Producción trimestral de una facción según terreno/edificios de sus regiones.
func produce_quarter(faction_id: String) -> Dictionary:
	var trade: Dictionary = ensure_state()
	var st: Dictionary = GameState.state
	var payload: Dictionary = {"ok": false, "faction_id": faction_id, "goods": {}, "support_gain": 0}
	if st.is_empty() or GameState.get_faction_state(faction_id).is_empty():
		last_error = "facción inválida"
		return payload
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var owned_regions: Array[Dictionary] = []
	for region_id in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(region_id, null))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			owned_regions.append(region)
	var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
	if inventory.is_empty():
		for good_id in SafeDict.sorted_keys(_goods):
			inventory[good_id] = float(Constants.TRADE_INITIAL_STOCK)
	for good_id in SafeDict.sorted_keys(_goods):
		var produced: float = 0.0
		for region in owned_regions:
			produced += _production_for_region(good_id, region)
		if produced > 0.0:
			inventory[good_id] = SafeDict.as_float(inventory.get(good_id), 0.0) + produced
			payload["goods"][good_id] = produced
	trade["inventory"][faction_id] = inventory
	# Precios por región (base × escasez + jitter determinista del RNG central).
	for region in owned_regions:
		var region_id: String = SafeDict.as_string(region.get("id"), "")
		if region_id == "":
			continue
		var region_prices: Dictionary = {}
		for good_id in SafeDict.sorted_keys(_goods):
			region_prices[good_id] = _price_for(faction_id, good_id, inventory)
		(trade["prices"] as Dictionary)[region_id] = region_prices
	# Consumo de grano/sal → apoyo.
	var support_gain: int = _consume_support_goods(faction_id, owned_regions, inventory)
	payload["support_gain"] = support_gain
	payload["ok"] = true
	last_error = ""
	return payload


func _production_for_region(good_id: String, region: Dictionary) -> float:
	var definition: Dictionary = get_good_definition(good_id)
	if definition.is_empty():
		return 0.0
	var produced_by: Dictionary = SafeDict.as_dict(definition.get("produced_by", null))
	var terrains: Array = SafeDict.as_array(produced_by.get("terrain", null))
	var buildings: Array = SafeDict.as_array(produced_by.get("buildings", null))
	var terrain_match: bool = terrains.is_empty() or terrains.has(SafeDict.as_string(region.get("terrain"), ""))
	var building_match: bool = buildings.is_empty()
	var region_buildings: Array = SafeDict.as_array(region.get("buildings", null))
	for building_value in buildings:
		if region_buildings.has(str(building_value)):
			building_match = true
			break
	# `produced_by` combina terreno y/o edificios: se produce si coincide
	# cualquiera de las condiciones declaradas (OR), y el listado vacío no aplica.
	if terrains.is_empty() and buildings.is_empty():
		return 0.0
	if not terrains.is_empty() and not buildings.is_empty():
		return 1.0 if (terrain_match or building_match) else 0.0
	if not terrains.is_empty():
		return 1.0 if terrain_match else 0.0
	return 1.0 if building_match else 0.0


func _price_for(faction_id: String, good_id: String, inventory: Dictionary) -> float:
	var base: float = get_base_price(good_id)
	var amount: float = SafeDict.as_float(inventory.get(good_id), 0.0)
	# Más inventario → precio menor; escasez → mayor. Determinista y acotado.
	var factor: float = clampf(1.0 + (20.0 - amount) / 200.0, 0.7, 1.6)
	if GameState.rng != null:
		factor += GameState.rng.next_float_range(-0.04, 0.04)
	return maxf(0.1, roundf(base * factor * 100.0) / 100.0)


## Precio actual (por región si se indica; media de regiones propias si no).
func get_good_price(faction_id: String, good_id: String, region_id: String = "") -> float:
	var trade: Dictionary = ensure_state()
	if region_id != "":
		var region_prices: Dictionary = SafeDict.as_dict(SafeDict.as_dict(trade.get("prices", null)).get(region_id, null))
		if region_prices.has(good_id):
			return SafeDict.as_float(region_prices.get(good_id), get_base_price(good_id))
	var st: Dictionary = GameState.state
	var regions: Dictionary = SafeDict.as_dict(st.get("regions", null))
	var total: float = 0.0
	var count: int = 0
	var prices: Dictionary = SafeDict.as_dict(trade.get("prices", null))
	for rid in SafeDict.sorted_keys(regions):
		var region: Dictionary = SafeDict.as_dict(regions.get(rid, null))
		if SafeDict.as_string(region.get("owner"), "") != faction_id:
			continue
		var rp: Dictionary = SafeDict.as_dict(prices.get(rid, null))
		if rp.has(good_id):
			total += SafeDict.as_float(rp.get(good_id), get_base_price(good_id))
			count += 1
	if count > 0:
		return roundf(total / float(count) * 100.0) / 100.0
	return get_base_price(good_id)


func _consume_support_goods(faction_id: String, owned_regions: Array[Dictionary], inventory: Dictionary) -> int:
	if owned_regions.is_empty():
		return 0
	var regions_count: int = owned_regions.size()
	var grain_need: float = float(regions_count) * 0.5
	var salt_need: float = float(regions_count) * 0.25
	var gain: int = 0
	if SafeDict.as_float(inventory.get("grano"), 0.0) >= grain_need:
		inventory["grano"] = SafeDict.as_float(inventory.get("grano"), 0.0) - grain_need
		gain += 1
	if SafeDict.as_float(inventory.get("sal"), 0.0) >= salt_need:
		inventory["sal"] = SafeDict.as_float(inventory.get("sal"), 0.0) - salt_need
		gain += 1
	if gain > 0:
		var st: Dictionary = GameState.state
		for region in owned_regions:
			var region_id: String = SafeDict.as_string(region.get("id"), "")
			var region_state: Dictionary = SafeDict.as_dict(SafeDict.as_dict(st.get("regions", null)).get(region_id, null))
			if not region_state.is_empty():
				region_state["support"] = clampi(SafeDict.as_int(region_state.get("support"), Constants.SUPPORT_DEFAULT) + gain,
					Constants.SUPPORT_MIN, Constants.SUPPORT_MAX)
	return gain


# ---------------------------------------------------------------------------
# Compra/venta y comercio exterior
# ---------------------------------------------------------------------------

func _trade_volume(faction_id: String) -> int:
	return maxi(0, get_merchants(faction_id) * Constants.TRADE_VOLUME_PER_MERCHANT)


func buy(faction_id: String, region_id: String, good_id: String, qty: int) -> bool:
	last_error = ""
	var trade: Dictionary = ensure_state()
	if qty <= 0:
		last_error = "cantidad inválida"
		return false
	if not can_trade(faction_id):
		last_error = "sin comerciantes asignados"
		return false
	var good: Dictionary = get_good_definition(good_id)
	if good.is_empty():
		last_error = "mercancía desconocida"
		return false
	if get_good_amount(faction_id, good_id) + float(qty) > 1.0e9:
		last_error = "inventario fuera de rango"
		return false
	if qty > _trade_volume(faction_id):
		last_error = "volumen supera comerciantes"
		return false
	var region: Dictionary = GameState.get_region_state(region_id)
	if region.is_empty() or SafeDict.as_string(region.get("owner"), "") != faction_id:
		last_error = "región no propia"
		return false
	var price: float = get_good_price(faction_id, good_id, region_id)
	var cost: int = int(ceilf(price * float(qty)))
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	var gold: int = SafeDict.as_int(faction.get("gold"), 0)
	if gold < cost:
		last_error = "oro insuficiente"
		return false
	faction["gold"] = gold - cost
	var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
	inventory[good_id] = SafeDict.as_float(inventory.get(good_id), 0.0) + float(qty)
	trade["inventory"][faction_id] = inventory
	# El precio sube al aumentar la demanda (determinista, sin RNG).
	_update_price_after_trade(trade, region_id, good_id, price, qty, _trade_volume(faction_id), true)
	EventBus.emit_signal("trade_completed", faction_id, good_id, qty, cost, "buy")
	return true


func sell(faction_id: String, region_id: String, good_id: String, qty: int) -> bool:
	last_error = ""
	var trade: Dictionary = ensure_state()
	if qty <= 0:
		last_error = "cantidad inválida"
		return false
	if not can_trade(faction_id):
		last_error = "sin comerciantes asignados"
		return false
	if get_good_definition(good_id).is_empty():
		last_error = "mercancía desconocida"
		return false
	if qty > _trade_volume(faction_id):
		last_error = "volumen supera comerciantes"
		return false
	var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
	if SafeDict.as_float(inventory.get(good_id), 0.0) < float(qty):
		last_error = "inventario insuficiente"
		return false
	var region: Dictionary = GameState.get_region_state(region_id)
	if region.is_empty() or SafeDict.as_string(region.get("owner"), "") != faction_id:
		last_error = "región no propia"
		return false
	var price: float = get_good_price(faction_id, good_id, region_id)
	var income: int = int(floorf(price * float(qty)))
	inventory[good_id] = SafeDict.as_float(inventory.get(good_id), 0.0) - float(qty)
	trade["inventory"][faction_id] = inventory
	var faction: Dictionary = GameState.get_faction_state(faction_id)
	faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) + income
	_update_price_after_trade(trade, region_id, good_id, price, qty, _trade_volume(faction_id), false)
	EventBus.emit_signal("trade_completed", faction_id, good_id, qty, income, "sell")
	return true


## Factor de oferta/demanda: comprar sube el precio, vender lo baja. Se aplica
## sobre el precio regional y se acota a [base×0.6, base×1.8] (determinista).
func _update_price_after_trade(trade: Dictionary, region_id: String, good_id: String,
		price: float, qty: int, volume: int, buying: bool) -> void:
	var base: float = get_base_price(good_id)
	var ratio: float = clampf(float(qty) / float(maxi(1, volume)), 0.0, 1.0)
	var factor: float = 1.0 + ratio * 0.35 if buying else 1.0 - ratio * 0.35
	var new_price: float = clampf(price * factor, base * 0.6, base * 1.8)
	var prices: Dictionary = SafeDict.as_dict(trade.get("prices", null))
	var region_prices: Dictionary = SafeDict.as_dict(prices.get(region_id, null))
	region_prices[good_id] = maxf(0.1, roundf(new_price * 100.0) / 100.0)
	prices[region_id] = region_prices


## Expedición de mercaderes: 2 PG, retorno a 2 trimestres; solo con comerciantes.
func send_expedition(faction_id: String, good_id: String, qty: int) -> bool:
	last_error = ""
	var trade: Dictionary = ensure_state()
	if qty <= 0 or get_good_definition(good_id).is_empty():
		last_error = "expedición inválida"
		return false
	if not can_trade(faction_id):
		last_error = "sin comerciantes asignados"
		return false
	if qty > _trade_volume(faction_id):
		last_error = "volumen supera comerciantes"
		return false
	var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
	if SafeDict.as_float(inventory.get(good_id), 0.0) < float(qty):
		last_error = "inventario insuficiente"
		return false
	# task-71: expedición singular por turno y mercancía.
	var gate_key: String = "expedition:%s" % good_id
	if not GameState.can_use_action(faction_id, gate_key):
		last_error = "action_used"
		return false
	GameState.mark_action_used(faction_id, gate_key)
	if not TurnManager.spend_pg_for(faction_id, Constants.EXPEDITION_PG_COST):
		last_error = "PG insuficiente"
		return false
	inventory[good_id] = SafeDict.as_float(inventory.get(good_id), 0.0) - float(qty)
	trade["inventory"][faction_id] = inventory
	var expedition: Dictionary = {
		"faction": faction_id,
		"good": good_id,
		"qty": qty,
		"return_turn": SafeDict.as_int(GameState.state.get("turn"), 1) + Constants.EXPEDITION_RETURN_TURNS,
		"sent_turn": SafeDict.as_int(GameState.state.get("turn"), 1),
	}
	var expeditions: Array = SafeDict.as_array(trade.get("expeditions", null))
	expeditions.append(expedition)
	trade["expeditions"] = expeditions
	EventBus.emit_signal("expedition_sent", faction_id, good_id, qty, expedition["return_turn"])
	return true


## Resuelve expediciones cuyo retorno ya llegó. Devuelve cuántas se resolvieron.
func process_expeditions() -> int:
	var trade: Dictionary = ensure_state()
	var current_turn: int = SafeDict.as_int(GameState.state.get("turn"), 1)
	var pending: Array = SafeDict.as_array(trade.get("expeditions", null))
	var remaining: Array = []
	var resolved: int = 0
	for expedition_value in pending:
		var expedition: Dictionary = SafeDict.as_dict(expedition_value)
		if SafeDict.as_int(expedition.get("return_turn"), 0) > current_turn:
			remaining.append(expedition)
			continue
		var faction_id: String = SafeDict.as_string(expedition.get("faction"), "")
		var good_id: String = SafeDict.as_string(expedition.get("good"), "")
		var qty: int = SafeDict.as_int(expedition.get("qty"), 0)
		var faction: Dictionary = GameState.get_faction_state(faction_id)
		if faction.is_empty() or qty <= 0:
			continue
		var income: int = int(roundf(get_base_price(good_id) * float(qty) * Constants.EXPEDITION_PROFIT_FACTOR))
		faction["gold"] = SafeDict.as_int(faction.get("gold"), 0) + maxi(0, income)
		resolved += 1
		EventBus.emit_signal("expedition_returned", faction_id, good_id, qty, income)
	trade["expeditions"] = remaining
	return resolved


func consume_goods(faction_id: String, requirements: Dictionary) -> bool:
	var trade: Dictionary = ensure_state()
	var inventory: Dictionary = SafeDict.as_dict(trade["inventory"].get(faction_id, null))
	for good_id in requirements.keys():
		var amount: float = SafeDict.as_float(requirements.get(good_id), 0.0)
		if amount > 0.0 and SafeDict.as_float(inventory.get(good_id), 0.0) < amount:
			last_error = "faltan mercancías: %s" % str(good_id)
			return false
	for good_id in requirements.keys():
		var amount: float = SafeDict.as_float(requirements.get(good_id), 0.0)
		if amount > 0.0:
			inventory[good_id] = SafeDict.as_float(inventory.get(good_id), 0.0) - amount
	trade["inventory"][faction_id] = inventory
	return true


func can_consume_goods(faction_id: String, requirements: Dictionary) -> bool:
	var inventory: Dictionary = get_inventory(faction_id)
	for good_id in requirements.keys():
		if SafeDict.as_float(inventory.get(good_id), 0.0) < SafeDict.as_float(requirements.get(good_id), 0.0):
			return false
	return true
