extends SceneTree
## Benchmark headless del MVP-1337 (D-066, prompt §2.2):
##   · IA de 13 rivales < 2000 ms/turno.
##   · Capa de mapa (fronteras) < 8 ms CPU/frame.
##
## Uso:
##   godot --headless --path <repo> --script tools/benchmark_mvp_1337.gd
## Exit 0 si ambas métricas cumplen; 1 si alguna falla o faltan autoloads.

const MvpBench = preload("res://tools/mvp_bench.gd")

const AI_BUDGET_MS: int = 2000
const MAP_FRAME_BUDGET_MS: float = 8.0


func _initialize() -> void:
	var root_node: Node = root
	var game_state: Node = root_node.get_node_or_null("GameState") if root_node != null else null
	var ai: Node = root_node.get_node_or_null("AIManager") if root_node != null else null
	if game_state == null or ai == null:
		print("BENCHMARK MVP-1337: faltan autoloads GameState/AIManager")
		quit(1)
		return
	game_state.call("new_game", "scenario_1337", "england", 1337)
	var ai_ms: int = MvpBench.measure_ai_ms(ai)
	var map_ms: float = MvpBench.measure_map_frame_ms(200)
	var ai_ok: bool = ai_ms >= 0 and ai_ms < AI_BUDGET_MS
	var map_ok: bool = map_ms >= 0.0 and map_ms < MAP_FRAME_BUDGET_MS
	print("BENCHMARK MVP-1337")
	print("  IA 13 rivales: %d ms (presupuesto <%d ms) -> %s" % [ai_ms, AI_BUDGET_MS, "OK" if ai_ok else "FAIL"])
	print("  Mapa (capa fronteras): %.3f ms/frame (presupuesto <%.1f ms) -> %s" % [
		map_ms, MAP_FRAME_BUDGET_MS, "OK" if map_ok else "FAIL",
	])
	print("  rivales con orden: %d" % int(ai.call("get", "last_turn_count")))
	quit(0 if ai_ok and map_ok else 1)
