extends RefCounted
## D-082: carga de ayuda contextual (AG-1) y apertura del overlay.

const DATA_PATH := "res://data/context_help.json"
const HELP_SCENE := "res://scenes/ui/context_help_overlay.tscn"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

static var _contexts: Dictionary = {}
static var _loaded := false


static func load_contexts() -> Dictionary:
	if _loaded:
		return _contexts
	_loaded = true
	if not FileAccess.file_exists(DATA_PATH):
		return _contexts
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return _contexts
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var root: Dictionary = parsed as Dictionary
		# Contrato Fase 5A §2: claves planas en raíz. Se mantiene compatibilidad
		# temporal con el envoltorio {"contexts": ...} de la primera entrega.
		if root.has("contexts") and root.get("contexts") is Dictionary:
			_contexts = root.get("contexts", {})
		else:
			_contexts = root.duplicate(true)
	return _contexts


static func context_for(screen: String) -> Dictionary:
	var from_loader := TSBGame.context_help(screen)
	if not from_loader.is_empty():
		return from_loader
	var contexts := load_contexts()
	var entry: Variant = contexts.get(screen, {})
	if entry is Dictionary:
		return (entry as Dictionary).duplicate(true)
	return {}


static func open_help(parent: Node, screen: String) -> void:
	if parent == null or parent.get_tree() == null:
		return
	var resource: Resource = load(HELP_SCENE)
	if resource == null:
		return
	var overlay: Node = (resource as PackedScene).instantiate()
	var layer := CanvasLayer.new()
	layer.layer = 100
	parent.get_tree().root.add_child(layer)
	layer.add_child(overlay)
	if overlay.has_method("setup"):
		overlay.call("setup", screen)
	if overlay.has_signal("closed"):
		overlay.connect("closed", func() -> void:
			if is_instance_valid(layer):
				layer.queue_free()
		)


static func add_button(parent: Control, screen: String) -> Button:
	if parent == null:
		return null
	var button := Button.new()
	button.text = "?"
	button.tooltip_text = "Ayuda contextual (D-082)"
	button.custom_minimum_size = Vector2(42, 42)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -60
	button.offset_right = -18
	button.offset_top = 18
	button.offset_bottom = 60
	button.z_index = 120
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func() -> void: open_help(parent, screen))
	parent.add_child(button)
	return button

