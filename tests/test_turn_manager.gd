extends RefCounted
## Tests de TurnManager (GDD §5.1, contrato Fase 1 §3): PG, reloj, señales y
## flujo completo del turno con IA.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")

var _turn_started_count: int = 0
var _turn_ended_count: int = 0
var _pg_changed_count: int = 0
var _year_advanced_count: int = 0


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("turn_manager")
	_check_pg_formula(runner, h)
	_check_pg_spending(runner, h)
	_check_clock(runner, h)
	_check_signals(runner, h)
	_check_end_turn(runner, h)


func _check_pg_formula(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	# 30 + Prestigio(50)/10 + bonus_líder(charisma 84 → 3) − penalización(0)
	runner.check_eq("PG de Inglaterra = 38", 38, h.calculate_pg("england"))
	runner.check_eq("PG del jugador al empezar", 38, h.remaining_pg())
	# Francia: carisma de Felipe VI = 70 → bonus 2 → 37.
	runner.check_eq("PG de Francia = 37", 37, h.calculate_pg("france"))
	# Penalización por descontento: 4 regiones de Inglaterra con apoyo 10 → −8.
	for region_id in h.regions().keys():
		var region: Dictionary = h.region(str(region_id))
		if str(region.get("owner", "")) == "england":
			region["support"] = 10
	runner.check_eq("penalización por 4 regiones descontentas", 30, h.calculate_pg("england"))
	# Regencia: Escocia tiene regente → −3 extra.
	var scotland_base: int = h.calculate_pg("scotland")
	runner.check("Escocia en regencia calcula PG", scotland_base >= 0 and scotland_base <= 38, str(scotland_base))
	# Prestigio alto sube PG: 30 + 50 (prestigio 500/10) + 2 (carisma 70) = 82.
	h.faction("france")["prestige"] = 500
	runner.check_eq("prestigio 500 → +50 PG", 82, h.calculate_pg("france"))


func _check_pg_spending(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	runner.check("spend_pg(5)", h.spend_pg(5))
	runner.check_eq("PG restantes tras gastar 5", 33, h.remaining_pg())
	runner.check_eq("facción espeja los PG", 33, int(h.faction("england")["pg"]))
	runner.check("can_spend_pg(33)", bool(h.tm.call("can_spend_pg", 33)))
	runner.check("can_spend_pg(34) es false", not bool(h.tm.call("can_spend_pg", 34)))
	runner.check("no se puede gastar más que el saldo", not h.spend_pg(100))
	runner.check_eq("el saldo no cambia tras un gasto inválido", 33, h.remaining_pg())
	runner.check("no se puede gastar negativo", not h.spend_pg(-1))


func _check_clock(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.advance_quarter()
	runner.check_eq("advance_quarter → trimestre 2", 2, h.quarter())
	runner.check_eq("el año no cambia en el trimestre 2", 1337, h.year())
	h.advance_quarter()
	h.advance_quarter()
	runner.check_eq("trimestre 4", 4, h.quarter())
	h.advance_quarter()
	runner.check_eq("cuarto trimestre → año 1338", 1338, h.year())
	runner.check_eq("nuevo año empieza en trimestre 1", 1, h.quarter())
	runner.check_eq("turno absoluto incrementado", 5, int(h.state().get("turn")))
	runner.check("el jugador sigue activo", h.player() == "england")
	runner.check_eq("PG refrescados al empezar el año", h.calculate_pg("england"), h.remaining_pg())


func _check_signals(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	_turn_started_count = 0
	_turn_ended_count = 0
	_pg_changed_count = 0
	_year_advanced_count = 0
	var on_turn_started := Callable(self, "_on_turn_started")
	var on_turn_ended := Callable(self, "_on_turn_ended")
	var on_pg_changed := Callable(self, "_on_pg_changed")
	var on_year_advanced := Callable(self, "_on_year_advanced")
	h.tm.connect("turn_started", on_turn_started)
	h.tm.connect("turn_ended", on_turn_ended)
	h.tm.connect("pg_changed", on_pg_changed)
	h.tm.connect("year_advanced", on_year_advanced)
	h.begin_turn("england")
	runner.check_eq("begin_turn emite turn_started", 1, _turn_started_count)
	runner.check("begin_turn emite pg_changed", _pg_changed_count >= 1, str(_pg_changed_count))
	h.spend_pg(2)
	runner.check("gastar PG emite pg_changed", _pg_changed_count >= 2, str(_pg_changed_count))
	h.end_turn()
	runner.check_eq("end_turn emite turn_ended", 1, _turn_ended_count)
	h.advance_quarter()
	h.advance_quarter()
	h.advance_quarter()
	runner.check_eq("el cuarto advance_quarter emite year_advanced", 1, _year_advanced_count)
	h.tm.disconnect("turn_started", on_turn_started)
	h.tm.disconnect("turn_ended", on_turn_ended)
	h.tm.disconnect("pg_changed", on_pg_changed)
	h.tm.disconnect("year_advanced", on_year_advanced)


func _on_turn_started(_quarter: int, _year: int) -> void:
	_turn_started_count += 1


func _on_turn_ended(_quarter: int, _year: int) -> void:
	_turn_ended_count += 1


func _on_pg_changed(_remaining: int) -> void:
	_pg_changed_count += 1


func _on_year_advanced(_year: int) -> void:
	_year_advanced_count += 1


func _check_end_turn(runner: TestRunnerScript, h: HarnessScript) -> void:
	h.new_game("england", 1337)
	h.end_turn()
	runner.check_eq("end_turn avanza al trimestre 2", 2, h.quarter())
	runner.check("end_turn ejecuta a las 13 facciones IA", h.ai_last_orders().size() == 13, str(h.ai_last_orders().size()))
	runner.check_eq("end_turn refresca los PG del jugador", h.calculate_pg("england"), h.remaining_pg())
	runner.check("la partida no termina en el primer turno", not bool(h.state().get("game_over", false)))
	# Un año completo (4 end_turn) avanza el reloj a 1338.
	h.new_game("england", 1337)
	h.end_turn()
	h.end_turn()
	h.end_turn()
	h.end_turn()
	runner.check_eq("4 end_turn completan el año", 1338, h.year())
	runner.check_eq("trimestre 1 del nuevo año", 1, h.quarter())
