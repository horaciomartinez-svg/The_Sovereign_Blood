extends RefCounted
## Tests de EconomySystem (GDD §5.2, contrato Fase 1 §4): fórmulas, apoyo,
## asignación de mano de obra, revueltas y cosecha anual con RNG.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("economy")
	_check_region_output(runner, h)
	_check_recalculate(runner, h)
	_check_allocate(runner, h)
	_check_support(runner, h)
	_check_revolt(runner, h)
	_check_harvest(runner, h)


func _check_region_output(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var output: Dictionary = h.region_output("region_londres")
	runner.check_eq("mano de obra de Londres", 600, output.get("workers_total"))
	# 330 farmers × 0.7 (ciudad) × 1.0 (clima) = 231
	runner.check_eq("alimento de Londres", 231.0, output.get("food"))
	runner.check_eq("necesidad de alimento", 300.0, output.get("food_need"))
	runner.check_eq("superávit negativo en la ciudad", -69.0, output.get("surplus"))
	# 120 artesanos × 0.6 = 72
	runner.check_eq("bienes de Londres", 72.0, output.get("goods"))
	# 90 comerciantes × 0.4 × (1 + 75/100) = 63
	runner.check_eq("comercio de Londres", 63.0, output.get("commerce"))
	# 75 riqueza × 0.5 tasa × 120000/100000 = 45
	runner.check_eq("impuestos de Londres", 45.0, output.get("taxes"))
	runner.check_eq("ingreso total de Londres", 180.0, output.get("gold_income"))
	runner.check_eq("clima inicial neutro", 1.0, output.get("harvest_modifier"))
	runner.check_eq("tasa de impuestos por defecto", 0.5, output.get("tax_rate"))
	# Los talleres aumentan la producción de bienes (Flandes tiene workshops).
	var flandes: Dictionary = h.region_output("region_flandes")
	var flandes_workers: Dictionary = h.region("region_flandes")["workers"]
	var artisans: int = SafeDict.as_int(flandes_workers.get("artisans"), 0)
	var base_goods: float = float(artisans) * 0.6
	runner.check("talleres aumentan los bienes", SafeDict.as_float(flandes.get("goods"), 0.0) > base_goods,
		str(flandes.get("goods")))
	# Subir la tasa de impuestos sube la recaudación.
	h.faction("england")["tax_rate"] = 0.8
	var taxed: Dictionary = h.region_output("region_londres")
	runner.check("más tasa → más impuestos", SafeDict.as_float(taxed.get("taxes"), 0.0) > 45.0,
		str(taxed.get("taxes")))
	# Región inexistente devuelve {} sin romper.
	runner.check("región inexistente devuelve {}", h.region_output("region_nope").is_empty())


func _check_recalculate(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var gold_before: int = h.treasury("england")
	h.recalculate("england")
	var gold_after: int = h.treasury("england")
	runner.check("recalculate ingresa oro", gold_after > gold_before, "%d → %d" % [gold_before, gold_after])
	runner.check_eq("Londres mantiene apoyo estable con la tasa por defecto", 59, h.support("region_londres"))
	h.recalculate("faccion_inexistente")
	runner.check("recalculate de facción inexistente no rompe", true)
	# Los PG no se tocan al recalcular la economía.
	var pg_before: int = h.remaining_pg()
	h.recalculate("england")
	runner.check_eq("recalculate no gasta PG", pg_before, h.remaining_pg())


func _check_allocate(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var pg_before: int = h.remaining_pg()
	var workers_before: Dictionary = (h.region("region_londres")["workers"] as Dictionary).duplicate(true)
	var merchants_before: int = SafeDict.as_int(workers_before.get("merchants"), 0)
	runner.check("allocate reasigna mano de obra", h.allocate("region_londres", "merchants", merchants_before + 20))
	runner.check_eq("allocate cuesta 1 PG", pg_before - 1, h.remaining_pg())
	var workers_after: Dictionary = h.region("region_londres")["workers"]
	runner.check_eq("clase destino actualizada", merchants_before + 20, SafeDict.as_int(workers_after.get("merchants"), 0))
	runner.check_eq("los farmers ceden la mano de obra", SafeDict.as_int(workers_before.get("farmers"), 0) - 20, SafeDict.as_int(workers_after.get("farmers"), 0))
	var total_before: int = _workers_total(workers_before)
	var total_after: int = _workers_total(workers_after)
	runner.check_eq("el total de trabajadores no cambia", total_before, total_after)
	# Reclutas: aumentan el pool regional.
	var pool_before: int = h.recruitment_pool("region_londres")
	runner.check("allocate a reclutas", h.allocate("region_londres", "recruits", SafeDict.as_int(workers_after.get("recruits"), 0) + 10))
	runner.check_eq("el pool de reclutas aumenta", pool_before + 10 * 200, h.recruitment_pool("region_londres"))
	runner.check("clase de trabajo inválida rechazada", not h.allocate("region_londres", "wizards", 10))
	runner.check("más trabajadores que población rechazado", not h.allocate("region_londres", "farmers", 99999))
	runner.check("región inexistente rechazada", not h.allocate("region_nope", "farmers", 10))
	# Sin PG no hay orden.
	var pg_left: int = h.remaining_pg()
	for _i in pg_left:
		h.spend_pg(1)
	runner.check_eq("PG agotados", 0, h.remaining_pg())
	var merchants_now: int = SafeDict.as_int((h.region("region_londres")["workers"] as Dictionary).get("merchants"), 0)
	runner.check("allocate sin PG falla", not h.allocate("region_londres", "merchants", merchants_now + 1))
	# No se puede reasignar una región de otra facción sin PG de esa facción.
	h.new_game("england", 1337)
	runner.check("no se reasigna región enemiga", not h.allocate("region_ile_de_france", "farmers", 10))


func _check_support(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var support_before: int = h.support("region_inglaterra_sur")
	for _i in 3:
		h.recalculate("england")
	runner.check("apoyo sube con superávit de alimentos", h.support("region_inglaterra_sur") >= support_before,
		"%d → %d" % [support_before, h.support("region_inglaterra_sur")])
	h.region("region_inglaterra_sur")["support"] = 99
	h.recalculate("england")
	runner.check("apoyo clampeado a 100", h.support("region_inglaterra_sur") <= 100)
	h.region("region_inglaterra_sur")["support"] = 0
	h.recalculate("england")
	runner.check("apoyo clampeado a 0", h.support("region_inglaterra_sur") >= 0)


func _check_revolt(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var english_regions: Array[String] = []
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if SafeDict.as_string(region.get("owner"), "") == "england":
			region["support"] = 10
			english_regions.append(str(region_id))
	for _i in 40:
		h.recalculate("england")
	var event_log: Array = h.state().get("event_log", [])
	var revolt_found: bool = false
	for entry_value in event_log:
		var entry: Dictionary = SafeDict.as_dict(entry_value)
		if SafeDict.as_string(entry.get("event_id"), "").begins_with("revuelta_"):
			revolt_found = true
	runner.check("apoyo <20 provoca revuelta", revolt_found)
	runner.check("hay regiones inglesas en la prueba", not english_regions.is_empty())


func _check_harvest(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var result: Dictionary = h.harvest("england")
	runner.check_eq("cosecha cubre las 4 regiones inglesas", 4, result.get("regions"))
	runner.check("cosecha produce alimento", SafeDict.as_float(result.get("food"), 0.0) > 0.0)
	var modifiers_a: Array = _harvest_modifiers(h, "england")
	runner.check_eq("4 modificadores de clima", 4, modifiers_a.size())
	runner.check("clima dentro de 0.85-1.15", _all_in_range(modifiers_a, 0.85, 1.15), str(modifiers_a))
	# Determinismo: misma semilla → mismo clima.
	h.new_game("england", 1337)
	h.harvest("england")
	var modifiers_b: Array = _harvest_modifiers(h, "england")
	runner.check_eq("cosecha determinista con la misma semilla", modifiers_a, modifiers_b)
	# Semilla distinta → clima distinto (con 4 regiones la coincidencia es ínfima).
	h.new_game("england", 4242)
	h.harvest("england")
	var modifiers_c: Array = _harvest_modifiers(h, "england")
	runner.check("semilla distinta → clima distinto", modifiers_a != modifiers_c)


func _workers_total(workers: Dictionary) -> int:
	var total: int = 0
	for worker_class in ["farmers", "artisans", "merchants", "recruits"]:
		total += SafeDict.as_int(workers.get(worker_class), 0)
	return total


func _harvest_modifiers(h: HarnessScript, faction_id: String) -> Array:
	var result: Array = []
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if SafeDict.as_string(region.get("owner"), "") == faction_id:
			result.append(SafeDict.as_float(region.get("harvest_modifier"), 0.0))
	return result


func _all_in_range(values: Array, minimum: float, maximum: float) -> bool:
	for value in values:
		var number: float = SafeDict.as_float(value, -1.0)
		if number < minimum or number > maximum:
			return false
	return true
