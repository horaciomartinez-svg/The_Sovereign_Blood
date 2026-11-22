extends SceneTree
## Sonda MVP-1337 de música/opciones (D-067): pistas OGG, contextos, crossfade,
## volumen Music/SFX persistente y mute. Sin tocar archivos de usuario al final.

const CONTEXTS: Array[String] = ["menu", "map", "battle_n2", "battle_n3", "year_end", "end"]

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio == null:
		print("AUDIO UI PROBE: FAIL sin AudioManager")
		quit(1)
		return

	for context: String in CONTEXTS:
		_check(bool(audio.call("has_track", context)), "pista registrada %s" % context)
		var stream: Variant = audio.call("get_track_stream", context)
		_check(stream is AudioStream, "stream %s" % context)
		_check(float(audio.call("get_track_duration_ms", context)) > 0.0, "duración %s" % context)

	_check(bool(audio.call("play_music", "menu")), "play_music menu")
	_check(str(audio.call("get_music_context")) == "menu", "contexto menu")
	_check(bool(audio.call("play_music", "map")), "play_music map")
	_check(str(audio.call("get_music_context")) == "map", "contexto map")
	var fade: float = float(audio.call("get_crossfade_seconds"))
	_check(fade >= 1.5 and fade <= 2.0, "crossfade 1,5-2 s (%.2f)" % fade)

	audio.call("set_music_volume_db", -12.0)
	_check(is_equal_approx(float(audio.call("get_music_volume_db")), -12.0), "set/get música dB")
	audio.call("set_sfx_volume_db", -3.0)
	_check(is_equal_approx(float(audio.call("get_sfx_volume_db")), -3.0), "set/get SFX dB")
	audio.call("set_muted", true)
	_check(bool(audio.call("is_muted")), "mute global")
	audio.call("set_muted", false)
	audio.call("reset_settings")
	_check(is_equal_approx(float(audio.call("get_music_volume_db")), -6.0), "default música -6 dB")
	_check(is_equal_approx(float(audio.call("get_sfx_volume_db")), 0.0), "default SFX 0 dB")

	print("--------------------------------------------------------------")
	if _failures.is_empty():
		print("AUDIO UI PROBE: OK")
		quit(0)
	else:
		print("AUDIO UI PROBE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  [OK] " + label)
	else:
		_failures.append(label)
		print("  [FAIL] " + label)
