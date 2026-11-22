extends Node
## TutorialSystem — Consejero del primer año (D-073).
##
## Lee `data/tutorial_script.json` (AG-1) y mantiene el estado serializable
## `GameState.state.tutorial = {active, step_index, completed_steps, skipped}`.
## Avanza SOLO cuando la acción del jugador coincide con la condición del paso
## actual; `tutorial_skip()` desactiva el Consejero. Dificultad Principiante
## arranca el tutorial; Normal lo deja inactivo.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const TUTORIAL_PATH: String = "res://data/tutorial_script.json"

var _steps: Array[Dictionary] = []
var _loaded: bool = false


func _ready() -> void:
	load_steps()
	EventBus.save_completed.connect(_on_save_completed)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.battle_resolved.connect(_on_battle_resolved)


func load_steps() -> bool:
	_loaded = true
	_steps.clear()
	if not FileAccess.file_exists(TUTORIAL_PATH):
		return false
	var file := FileAccess.open(TUTORIAL_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	var data: Dictionary = SafeDict.as_dict(json.data)
	var raw_steps: Array = SafeDict.as_array(data.get("steps", null))
	for step_value in raw_steps:
		_steps.append(SafeDict.as_dict(step_value))
	_steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return SafeDict.as_int(a.get("order"), 0) < SafeDict.as_int(b.get("order"), 0)
	)
	return not _steps.is_empty()


func reload_steps() -> bool:
	return load_steps()


func _ensure_steps_loaded() -> void:
	if not _loaded:
		load_steps()


func get_steps() -> Array[Dictionary]:
	_ensure_steps_loaded()
	return _steps.duplicate(true)


func get_steps_count() -> int:
	_ensure_steps_loaded()
	return _steps.size()


func get_conditions() -> Array[String]:
	_ensure_steps_loaded()
	var result: Array[String] = []
	for step in _steps:
		var condition: String = SafeDict.as_string(step.get("condition"), "")
		if condition != "" and not result.has(condition):
			result.append(condition)
	return result


# ---------------------------------------------------------------------------
# Estado
# ---------------------------------------------------------------------------

func ensure_state() -> Dictionary:
	var st: Dictionary = GameState.state
	if st.is_empty():
		return {}
	var tutorial_value: Variant = st.get("tutorial", null)
	var tutorial: Dictionary = SafeDict.as_dict(tutorial_value)
	if tutorial.is_empty():
		tutorial = {
			"active": SafeDict.as_string(st.get("difficulty"), "normal") == "beginner",
			"step_index": 0,
			"completed_steps": [],
			"skipped": false,
		}
		st["tutorial"] = tutorial
	for key in ["active", "step_index", "completed_steps", "skipped"]:
		if not tutorial.has(key):
			tutorial[key] = {"active": false, "step_index": 0, "completed_steps": [], "skipped": false}[key]
	return tutorial


## Activa el tutorial desde el principio (beginner al iniciar partida).
func start_tutorial() -> void:
	var tutorial: Dictionary = ensure_state()
	if tutorial.is_empty():
		return
	tutorial["active"] = true
	tutorial["step_index"] = 0
	tutorial["completed_steps"] = []
	tutorial["skipped"] = false
	EventBus.emit_signal("tutorial_started", get_current_step())


func start_for_new_game(difficulty: String) -> void:
	if difficulty == "beginner":
		start_tutorial()
	else:
		var tutorial: Dictionary = ensure_state()
		tutorial["active"] = false
		tutorial["step_index"] = 0
		tutorial["completed_steps"] = []
		tutorial["skipped"] = false


func is_tutorial_active() -> bool:
	return SafeDict.as_bool(ensure_state().get("active"), false)


func skip_tutorial() -> bool:
	var tutorial: Dictionary = ensure_state()
	if tutorial.is_empty():
		return false
	tutorial["active"] = false
	tutorial["skipped"] = true
	EventBus.emit_signal("tutorial_skipped")
	return true


func get_current_step() -> Dictionary:
	_ensure_steps_loaded()
	var tutorial: Dictionary = ensure_state()
	if tutorial.is_empty() or not SafeDict.as_bool(tutorial.get("active"), false):
		return {}
	var index: int = SafeDict.as_int(tutorial.get("step_index"), 0)
	if _steps.is_empty() or index < 0 or index >= _steps.size():
		return {}
	return _steps[index].duplicate(true)


func get_tutorial_state() -> Dictionary:
	return ensure_state().duplicate(true)


## Avanza si `condition_id` es la condición del paso actual.
func advance_tutorial(condition_id: String) -> Dictionary:
	var tutorial: Dictionary = ensure_state()
	var result: Dictionary = {"ok": false, "advanced": false, "completed": false, "reason": ""}
	if tutorial.is_empty():
		result["reason"] = "sin partida"
		return result
	if not SafeDict.as_bool(tutorial.get("active"), false):
		result["reason"] = "tutorial inactivo"
		return result
	var step: Dictionary = get_current_step()
	if step.is_empty():
		result["reason"] = "sin paso actual"
		return result
	var expected: String = SafeDict.as_string(step.get("condition"), "")
	if expected == "" or expected != condition_id:
		result["reason"] = "condición no coincide"
		return result
	var completed: Array = SafeDict.as_array(tutorial.get("completed_steps", null))
	var step_id: String = SafeDict.as_string(step.get("id"), "")
	if step_id != "" and not completed.has(step_id):
		completed.append(step_id)
	tutorial["completed_steps"] = completed
	var next_index: int = SafeDict.as_int(tutorial.get("step_index"), 0) + 1
	tutorial["step_index"] = next_index
	result["ok"] = true
	result["advanced"] = true
	if next_index >= _steps.size():
		tutorial["active"] = false
		result["completed"] = true
		EventBus.emit_signal("tutorial_completed")
	else:
		EventBus.emit_signal("tutorial_step_changed", get_current_step())
	return result


## Alias corto usado por la UI.
func tutorial_advance(condition_id: String) -> Dictionary:
	return advance_tutorial(condition_id)


func tutorial_skip() -> bool:
	return skip_tutorial()


func get_tutorial_step() -> Dictionary:
	return get_current_step()


func _on_save_completed(_slot: String) -> void:
	advance_tutorial("saved")


func _on_turn_ended(_quarter: int, _year: int) -> void:
	advance_tutorial("end_turn")


func _on_battle_resolved(_report: Dictionary) -> void:
	advance_tutorial("battle_played")
