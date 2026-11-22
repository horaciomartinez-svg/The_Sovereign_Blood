extends RefCounted
## Hooks de audio de la UI (D-066 §2.3). AG-2 expone `AudioManager` como
## autoload; si aún no existe o no tiene el método, el hook es silencioso.
## Sin assets: los tonos los genera AudioManager.

static func play_click() -> void:
	_call_first(["play_ui_click", "play_click"])


static func play_year_bell() -> void:
	_call_first(["play_year_bell", "play_bell", "play_year_end"])


static func play_sword() -> void:
	_call_first(["play_sword", "play_impact", "play_battle_hit"])


static func _audio() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		var root := (main_loop as SceneTree).root
		if root != null:
			return root.get_node_or_null("AudioManager")
	return null


static func _call_first(methods: Array[String]) -> void:
	var audio := _audio()
	if audio == null:
		return
	for method_name: String in methods:
		if audio.has_method(method_name):
			audio.call(method_name)
			return
