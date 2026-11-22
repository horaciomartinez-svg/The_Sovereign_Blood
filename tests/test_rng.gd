extends RefCounted
## Tests del RNG sembrado (GDD §8.3, §13): determinismo, rangos,
## snapshot/restore y distribución gaussiana de la tirada de batalla.

const TestRunnerScript = preload("res://tests/test_runner.gd")
const SeededRNGScript = preload("res://scripts/utils/rng.gd")


func run(runner: TestRunnerScript, _tree: SceneTree) -> void:
	runner.begin_suite("rng")
	_check_determinism(runner)
	_check_ranges(runner)
	_check_snapshot_restore(runner)
	_check_gaussian(runner)


func _check_determinism(runner: TestRunnerScript) -> void:
	var first: SeededRNGScript = SeededRNGScript.new(42)
	var second: SeededRNGScript = SeededRNGScript.new(42)
	var first_sequence: Array = []
	var second_sequence: Array = []
	for _i in 25:
		first_sequence.append(first.next_int(1, 100))
		second_sequence.append(second.next_int(1, 100))
	runner.check("misma semilla → misma secuencia", first_sequence == second_sequence)

	var different: SeededRNGScript = SeededRNGScript.new(43)
	var different_sequence: Array = []
	for _i in 25:
		different_sequence.append(different.next_int(1, 100))
	runner.check("semilla distinta → secuencia distinta", first_sequence != different_sequence)

	var reset_rng: SeededRNGScript = SeededRNGScript.new(42)
	var reset_sequence: Array = []
	for _i in 25:
		reset_sequence.append(reset_rng.next_int(1, 100))
	runner.check("reset() reproduce la semilla inicial", reset_sequence == first_sequence)


func _check_ranges(runner: TestRunnerScript) -> void:
	var rng: SeededRNGScript = SeededRNGScript.new(7)
	var in_range := true
	var saw_limits := false
	var minimum_seen := 999
	var maximum_seen := -999
	for _i in 2000:
		var value: int = rng.next_int(5, 9)
		if value < 5 or value > 9:
			in_range = false
		minimum_seen = mini(minimum_seen, value)
		maximum_seen = maxi(maximum_seen, value)
	if minimum_seen <= 5 and maximum_seen >= 9:
		saw_limits = true
	runner.check("next_int respeta el rango [5, 9]", in_range, "min=%d max=%d" % [minimum_seen, maximum_seen])
	runner.check("next_int alcanza ambos extremos", saw_limits)

	var float_rng: SeededRNGScript = SeededRNGScript.new(11)
	var floats_in_range := true
	for _i in 500:
		var value: float = float_rng.next_float_range(2.0, 3.0)
		if value < 2.0 or value > 3.0:
			floats_in_range = false
	runner.check("next_float_range respeta el rango [2.0, 3.0]", floats_in_range)

	var d100_rng: SeededRNGScript = SeededRNGScript.new(13)
	var d100_in_range := true
	for _i in 500:
		var roll: int = d100_rng.roll_d100()
		if roll < 1 or roll > 100:
			d100_in_range = false
	runner.check("roll_d100 respeta [1, 100]", d100_in_range)

	runner.check("pick() sobre array vacío devuelve null", d100_rng.pick([]) == null)

	var items: Array = [10, 20, 30]
	var original: Array = [10, 20, 30]
	var shuffled: Array = d100_rng.shuffled(items)
	runner.check("shuffled() no muta el array original", items == original)
	runner.check("shuffled() conserva los elementos", shuffled.size() == 3 and shuffled.has(10) and shuffled.has(20) and shuffled.has(30))


func _check_snapshot_restore(runner: TestRunnerScript) -> void:
	var rng: SeededRNGScript = SeededRNGScript.new(99)
	for _i in 5:
		rng.next_int(0, 1000000)
	var snapshot: Dictionary = rng.snapshot()
	runner.check("snapshot() contiene seed y state", snapshot.has("seed") and snapshot.has("state"))

	var expected: Array = []
	for _i in 10:
		expected.append(rng.next_int(0, 1000000))

	rng.restore(snapshot)
	var duplicate: SeededRNGScript = rng.duplicate_rng()
	var actual: Array = []
	for _i in 10:
		actual.append(rng.next_int(0, 1000000))
	runner.check("snapshot/restore reproduce el flujo exacto", expected == actual)

	var from_copy: Array = []
	for _i in 10:
		from_copy.append(duplicate.next_int(0, 1000000))
	runner.check("duplicate_rng() continúa el mismo flujo", expected == from_copy)


func _check_gaussian(runner: TestRunnerScript) -> void:
	var rng: SeededRNGScript = SeededRNGScript.new(5)
	var samples := 4000
	var total := 0.0
	for _i in samples:
		total += rng.gaussian(1.0, 0.15)
	var mean := total / float(samples)
	runner.check("gaussian μ=1.0 (media muestral ≈ 1.0)", absf(mean - 1.0) < 0.02, "media=%.4f" % mean)

	var modifier := rng.commander_modifier(85)
	runner.check("commander_modifier(85) ≈ 1.175", absf(modifier - 1.175) < 0.0001, "valor=%.4f" % modifier)
	runner.check("commander_modifier(0) = 0.75", absf(rng.commander_modifier(0) - 0.75) < 0.0001)
	runner.check("commander_modifier(100) = 1.25", absf(rng.commander_modifier(100) - 1.25) < 0.0001)
