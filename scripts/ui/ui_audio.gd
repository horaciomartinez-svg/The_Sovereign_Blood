extends RefCounted
## Hooks de audio de la UI (D-066 §2.3 / D-067 §2.5). AG-2 expone `AudioManager`
## como autoload; si aún no existe o no tiene un método, el hook es silencioso.
## Sin assets: SFX/música los genera/carga AudioManager.

const DEFAULT_MUSIC_DB := -6.0
const DEFAULT_SFX_DB := 0.0
const DEFAULT_CROSSFADE_SECONDS := 1.8


static func play_click() -> void:
	_call_first(["play_ui_click", "play_click"])


static func play_year_bell() -> void:
	_call_first(["play_year_bell", "play_bell", "play_year_end"])


static func play_sword() -> void:
	_call_first(["play_sword", "play_impact", "play_battle_hit"])


## Cambia de contexto musical con crossfade (no-op si AG-2 aún no lo expone).
static func play_music(context: String) -> void:
	if context.is_empty():
		return
	var audio := _audio()
	if audio == null:
		return
	for method_name: String in ["play_music", "set_music_context", "switch_music", "play_context"]:
		if audio.has_method(method_name):
			if method_name == "play_music":
				audio.call(method_name, context, DEFAULT_CROSSFADE_SECONDS)
			else:
				audio.call(method_name, context)
			return


static func music_context() -> String:
	var audio := _audio()
	if audio == null:
		return ""
	for method_name: String in ["get_music_context", "current_music_context"]:
		if audio.has_method(method_name):
			return str(audio.call(method_name))
	return ""


static func music_volume_db() -> float:
	var audio := _audio()
	if audio == null:
		return DEFAULT_MUSIC_DB
	for method_name: String in ["get_music_volume_db", "get_music_volume"]:
		if audio.has_method(method_name):
			return float(audio.call(method_name))
	return DEFAULT_MUSIC_DB


static func sfx_volume_db() -> float:
	var audio := _audio()
	if audio == null:
		return DEFAULT_SFX_DB
	for method_name: String in ["get_sfx_volume_db", "get_sfx_volume"]:
		if audio.has_method(method_name):
			return float(audio.call(method_name))
	return DEFAULT_SFX_DB


static func set_music_volume_db(value: float) -> void:
	var audio := _audio()
	if audio == null:
		return
	for method_name: String in ["set_music_volume_db", "set_music_volume"]:
		if audio.has_method(method_name):
			audio.call(method_name, clampf(value, -60.0, 6.0))
			return


static func set_sfx_volume_db(value: float) -> void:
	var audio := _audio()
	if audio == null:
		return
	for method_name: String in ["set_sfx_volume_db", "set_sfx_volume"]:
		if audio.has_method(method_name):
			audio.call(method_name, clampf(value, -60.0, 6.0))
			return


static func is_muted() -> bool:
	var audio := _audio()
	if audio == null:
		return false
	return bool(audio.call("is_muted")) if audio.has_method("is_muted") else false


static func set_muted(value: bool) -> void:
	var audio := _audio()
	if audio != null and audio.has_method("set_muted"):
		audio.call("set_muted", value)


static func set_music_paused(value: bool) -> void:
	var audio := _audio()
	if audio == null:
		return
	for method_name: String in ["set_music_paused", "set_paused"]:
		if audio.has_method(method_name):
			audio.call(method_name, value)
			return


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
