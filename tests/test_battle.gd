extends RefCounted
## Tests de BattleManager Nivel 1 (GDD §6.1): poder, comandante, terreno,
## asaltos, retirada, captura, botín y determinismo.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const ArmyScript = preload("res://scripts/model/army.gd")
const RegionScript = preload("res://scripts/model/region_state.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("battle")
	_check_power(runner, h)
	_check_delegated(runner, h)
	_check_determinism(runner, h)


func _check_power(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var attacker: ArmyScript = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: ArmyScript = _make_army("france", "region_normandia", "", "crossbowmen", 600, 8)
	var plains: RegionScript = _make_region("region_normandia", "plains", 60, 60)
	var city: RegionScript = _make_region("region_ile_de_france", "city", 60, 85)
	var power_attacker: float = float(h.battle.call("estimate_power", attacker, plains, true))
	var power_plains: float = float(h.battle.call("estimate_power", defender, plains, false))
	var power_city: float = float(h.battle.call("estimate_power", defender, city, false))
	runner.check("el poder del atacante es positivo", power_attacker > 0.0, str(power_attacker))
	runner.check("el terreno urbano multiplica la defensa (×1.4)", power_city > power_plains,
		"%.2f vs %.2f" % [power_city, power_plains])
	var no_leader: ArmyScript = _make_army("england", "region_normandia", "", "longbowman", 1200, 9)
	var power_no_leader: float = float(h.battle.call("estimate_power", no_leader, plains, true))
	runner.check("un ejército con comandante supera al mismo sin comandante", power_attacker > power_no_leader,
		"%.2f vs %.2f" % [power_attacker, power_no_leader])
	# Moral del apoyo: apoyo 100 da más poder que apoyo 0.
	var low_support: RegionScript = _make_region("region_normandia", "plains", 0, 60)
	var high_support: RegionScript = _make_region("region_normandia", "plains", 100, 60)
	var power_low: float = float(h.battle.call("estimate_power", defender, low_support, false))
	var power_high: float = float(h.battle.call("estimate_power", defender, high_support, false))
	runner.check("más apoyo popular → más moral y poder", power_high > power_low,
		"%.2f vs %.2f" % [power_high, power_low])
	runner.check("la fase táctica (Nivel 2) sigue en stub", h.battle.call("launch_tactical", attacker, defender, plains) == null)


func _check_delegated(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var attacker: ArmyScript = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 1200, 9)
	var defender: ArmyScript = _make_army("france", "region_normandia", "", "crossbowmen", 600, 8)
	var region: RegionScript = _make_region("region_normandia", "plains", 60, 60)
	var report = h.battle.call("resolve_delegated", attacker, defender, region, 1)
	runner.check("resolve_delegated devuelve informe", report != null)
	if report == null:
		return
	var data: Dictionary = report.call("to_dict")
	runner.check_eq("gana el atacante fuerte", "england", str(data.get("winner_faction")))
	runner.check("la región se captura al vencer", SafeDict.as_bool(data.get("region_captured"), false))
	runner.check("botín = riqueza × 5", SafeDict.as_int(data.get("loot_gold"), 0) == 300, str(data.get("loot_gold")))
	runner.check("bajas del defensor > 0", SafeDict.as_int(data.get("defender_losses"), 0) > 0, str(data.get("defender_losses")))
	runner.check("bajas del atacante >= 0", SafeDict.as_int(data.get("attacker_losses"), 0) >= 0)
	var rounds: Array = SafeDict.as_array(data.get("rounds", null))
	runner.check("asaltos entre 1 y 5", rounds.size() >= 1 and rounds.size() <= 5, str(rounds.size()))
	if not rounds.is_empty():
		var round_data: Dictionary = SafeDict.as_dict(rounds[0])
		runner.check("la ronda registra poderes y bajas",
			round_data.has("attacker_power") and round_data.has("defender_power")
			and round_data.has("attacker_losses") and round_data.has("defender_losses"))
	runner.check("el defensor sufre bajas en los asaltos", _men(defender) < 600, str(_men(defender)))
	# Defensor mucho más fuerte: gana el defensor y no hay captura.
	h.new_game("england", 1337)
	var weak_attacker: ArmyScript = _make_army("england", "region_ile_de_france", "", "militia_spearman", 200, 4)
	var strong_defender: ArmyScript = _make_army("france", "region_ile_de_france", "philippe_vi_de_valois", "men_at_arms", 5000, 12)
	var city_region: RegionScript = _make_region("region_ile_de_france", "city", 60, 85)
	var defense_report = h.battle.call("resolve_delegated", weak_attacker, strong_defender, city_region, 2)
	runner.check("un atacante débil pierde", defense_report != null
		and str((defense_report.call("to_dict") as Dictionary).get("winner_faction")) == "france")
	if defense_report != null:
		var defense_data: Dictionary = defense_report.call("to_dict")
		runner.check("sin captura al perder el atacante", not SafeDict.as_bool(defense_data.get("region_captured"), false))


func _check_determinism(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	var attacker_a: ArmyScript = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 900, 9)
	var defender_a: ArmyScript = _make_army("france", "region_normandia", "", "men_at_arms", 700, 12)
	var region_a: RegionScript = _make_region("region_normandia", "plains", 60, 60)
	var report_a = h.battle.call("resolve_delegated", attacker_a, defender_a, region_a, 0)
	var data_a: Dictionary = report_a.call("to_dict")
	h.new_game("england", 1337)
	var attacker_b: ArmyScript = _make_army("england", "region_normandia", "edward_iii_plantagenet", "longbowman", 900, 9)
	var defender_b: ArmyScript = _make_army("france", "region_normandia", "", "men_at_arms", 700, 12)
	var region_b: RegionScript = _make_region("region_normandia", "plains", 60, 60)
	var report_b = h.battle.call("resolve_delegated", attacker_b, defender_b, region_b, 0)
	var data_b: Dictionary = report_b.call("to_dict")
	runner.check_eq("batalla determinista con la misma semilla y postura",
		JSON.stringify(data_a), JSON.stringify(data_b))
	runner.check("el informe describe la postura", str(data_a.get("notes", "")).contains("defensiva"),
		str(data_a.get("notes")))


# --- helpers -------------------------------------------------------------

func _make_army(faction_id: String, region_id: String, leader_id: String, unit_id: String, size: int, strength: int) -> ArmyScript:
	var army: ArmyScript = ArmyScript.new()
	army.id = "test_%s_%s" % [faction_id, unit_id]
	army.faction_id = faction_id
	army.region_id = region_id
	army.leader_id = leader_id
	army.morale = 1.0
	army.units = [{
		"id": "u1",
		"unit_id": unit_id,
		"size": size,
		"strength": strength,
		"morale": 1.0,
		"experience": 50,
	}]
	return army


func _make_region(region_id: String, terrain: String, support: int, wealth: int) -> RegionScript:
	var region: RegionScript = RegionScript.new()
	region.id = region_id
	region.terrain = terrain
	region.support = support
	region.base_wealth = wealth
	region.has_city = terrain == "city"
	return region


func _men(army: ArmyScript) -> int:
	var total: int = 0
	for unit_value in army.units:
		var unit: Dictionary = SafeDict.as_dict(unit_value)
		total += SafeDict.as_int(unit.get("size"), 0)
	return total
