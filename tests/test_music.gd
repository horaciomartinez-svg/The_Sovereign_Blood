extends RefCounted
## Tests del motor de música (D-067 §2.5): 6 pistas OGG, buses Master/Music/SFX,
## contexto/crossfade, persistencia de volumen/mute y continuidad en save/load.

const HarnessScript = preload("res://tests/harness.gd")
const TestRunnerScript = preload("res://tests/test_runner.gd")
const SafeDict = preload("res://scripts/utils/safe_dict.gd")

const CONTEXTS: Array[String] = ["menu", "map", "battle_n2", "battle_n3", "year_end", "end"]
const BUS_LAYOUT: String = "res://default_bus_layout.tres"
const AUDIO_DATA: String = "res://data/audio_tracks.json"


func run(runner: TestRunnerScript, h: HarnessScript) -> void:
	_check_audio_data(runner, h)
	_check_buses(runner, h)
	_check_tracks_load(runner, h)
	_check_contexts_and_crossfade(runner, h)
	_check_persistence(runner, h)
	_check_save_load_and_mute(runner, h)


func _am(h: HarnessScript) -> Node:
	return h.audio


func _check_audio_data(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("music_data")
	runner.check("existe default_bus_layout.tres", FileAccess.file_exists(BUS_LAYOUT))
	runner.check("existe data/audio_tracks.json", FileAccess.file_exists(AUDIO_DATA))
	var am: Node = _am(h)
	runner.check("AudioManager tiene pistas cargadas", am != null)
	if am == null:
		return
	var contexts: Array = am.call("get_track_contexts")
	runner.check_eq("6 contextos musicales", 6, contexts.size())
	for context in CONTEXTS:
		runner.check("contexto musical %s" % context, contexts.has(context))
		var info: Dictionary = SafeDict.as_dict(am.call("get_track_info", context))
		runner.check("info de pista %s" % context, not info.is_empty())
		var path: String = SafeDict.as_string(info.get("track"), "")
		runner.check("ruta OGG válida en %s" % context,
			path.begins_with("res://assets/audio/music/") and path.ends_with(".ogg"), path)
		runner.check("loop declarado en %s" % context, info.has("loop"))
		runner.check("volume_db declarado en %s" % context, info.has("volume_db"))


func _check_buses(runner: TestRunnerScript, _h: HarnessScript) -> void:
	runner.begin_suite("music_buses")
	var master: int = AudioServer.get_bus_index("Master")
	var music: int = AudioServer.get_bus_index("Music")
	var sfx: int = AudioServer.get_bus_index("SFX")
	runner.check("bus Master existe", master >= 0)
	runner.check("bus Music existe", music >= 0)
	runner.check("bus SFX existe", sfx >= 0)
	if music >= 0:
		runner.check("Music envía a Master", AudioServer.get_bus_send(music) == "Master")
		runner.check("Music por defecto −6 dB", absf(AudioServer.get_bus_volume_db(music) - (-6.0)) < 0.01,
			str(AudioServer.get_bus_volume_db(music)))
	if sfx >= 0:
		runner.check("SFX envía a Master", AudioServer.get_bus_send(sfx) == "Master")


func _check_tracks_load(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("music_tracks")
	var am: Node = _am(h)
	if am == null:
		runner.check("AudioManager para cargar pistas", false)
		return
	for context in CONTEXTS:
		var stream_value: Variant = am.call("get_track_stream", context)
		runner.check("pista %s carga" % context, stream_value != null)
		if stream_value is AudioStreamOggVorbis:
			runner.check("pista %s es AudioStreamOggVorbis" % context, true)
			var ogg: AudioStreamOggVorbis = stream_value
			runner.check("pista %s tiene duración >0" % context, ogg.get_length() > 0.0,
				str(ogg.get_length()))
			var expected_loop: bool = SafeDict.as_bool(SafeDict.as_dict(am.call("get_track_info", context)).get("loop"), true)
			runner.check("loop %s coincide con datos" % context, ogg.loop == expected_loop,
				"loop=%s esperado=%s" % [str(ogg.loop), str(expected_loop)])
		else:
			runner.check("pista %s es AudioStreamOggVorbis" % context, false,
				"tipo inesperado: %s" % str(typeof(stream_value)))
		var duration: float = float(am.call("get_track_duration_ms", context))
		runner.check("duración %s > 0 ms" % context, duration > 0.0, str(duration))


func _check_contexts_and_crossfade(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("music_contexts")
	var am: Node = _am(h)
	if am == null:
		return
	am.call("reset_settings")
	am.call("reset_counts")
	am.call("stop_music", 0.0)
	runner.check("crossfade por defecto 1,8 s",
		absf(float(am.call("get_crossfade_seconds")) - 1.8) < 0.01,
		str(am.call("get_crossfade_seconds")))
	for context in CONTEXTS:
		var ok: bool = bool(am.call("play_music", context))
		runner.check("play_music(%s)" % context, ok)
		runner.check_eq("contexto activo %s" % context, context,
			SafeDict.as_string(am.call("get_music_context"), ""))
		runner.check_eq("contador de %s" % context, 1,
			SafeDict.as_int(am.call("get_music_play_count", context), 0))
	# Cambio mapa → batalla → resultado → mapa sin errores.
	runner.check("mapa tras batalla", bool(am.call("play_music", "map")))
	runner.check("crossfade configurables 1,5-2 s", _crossfade_clamped(am))
	am.call("stop_music", 0.1)
	runner.check_eq("stop_music limpia el contexto", "", SafeDict.as_string(am.call("get_music_context"), ""))


func _crossfade_clamped(am: Node) -> bool:
	am.call("set_crossfade_seconds", 2.5)
	var high: float = float(am.call("get_crossfade_seconds"))
	am.call("set_crossfade_seconds", 0.1)
	var low: float = float(am.call("get_crossfade_seconds"))
	am.call("set_crossfade_seconds", 1.8)
	return absf(high - 2.0) < 0.01 and absf(low - 1.5) < 0.01


func _check_persistence(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("music_persistence")
	var am: Node = _am(h)
	if am == null:
		return
	am.call("reset_settings")
	am.call("set_music_volume_db", -12.0)
	am.call("set_sfx_volume_db", -3.0)
	am.call("set_muted", true)
	runner.check("guardar configuración de audio", bool(am.call("save_settings")))
	# Simula reinicio de valores y recarga desde user://.
	am.set("music_volume_db", 0.0)
	am.set("sfx_volume_db", 0.0)
	am.set("muted", false)
	runner.check("cargar configuración de audio", bool(am.call("load_settings")))
	runner.check_eq("música persistida −12 dB", -12.0, float(am.call("get_music_volume_db")))
	runner.check_eq("SFX persistido −3 dB", -3.0, float(am.call("get_sfx_volume_db")))
	runner.check("mute persistido", bool(am.call("is_muted")))
	am.call("set_muted", false)
	am.call("reset_settings")


func _check_save_load_and_mute(runner: TestRunnerScript, h: HarnessScript) -> void:
	runner.begin_suite("music_save_load")
	var am: Node = _am(h)
	if am == null:
		return
	am.call("reset_settings")
	h.new_game("england")
	am.call("play_music", "map")
	runner.check_eq("música de mapa antes de guardar", "map",
		SafeDict.as_string(am.call("get_music_context"), ""))
	runner.check("guardar partida con música", h.save_game("music_save"))
	runner.check("cargar partida con música", h.load_game("music_save"))
	runner.check_eq("la música no se interrumpe al cargar", "map",
		SafeDict.as_string(am.call("get_music_context"), ""))
	# Mute global: SFX no reproduce, la música mantiene contexto.
	am.call("set_muted", true)
	runner.check("mute bloquea SFX", not bool(am.call("play_ui_click")))
	runner.check_eq("mute mantiene contexto musical", "map",
		SafeDict.as_string(am.call("get_music_context"), ""))
	am.call("set_muted", false)
	runner.check("unmute permite SFX", bool(am.call("play_ui_click")))
	am.call("stop_music", 0.0)
	am.call("reset_settings")
