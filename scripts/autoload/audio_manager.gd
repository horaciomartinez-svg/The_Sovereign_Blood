extends Node
## AudioManager — audio del MVP-1337 (D-015 / D-066 / D-067).
##
## SFX: tonos generados por código (PCM16, sin assets externos):
##   · `play_ui_click()`  — click breve de UI (AG-3).
##   · `play_year_bell()` — campana de fin de año (TurnManager).
##   · `play_sword()`     — golpe/espada N3 (CloseCombat).
##
## Música (D-067 §2.5): pistas OGG descritas en `data/audio_tracks.json` y
## cargadas como `AudioStreamOggVorbis`; loop por contexto, crossfade de ~1,8 s
## al cambiar mapa→batalla→resultado→mapa. Volúmenes Music/SFX, mute y crossfade
## se persisten en `user://audio_config.json`.
##
## Buses: Master / Music (−6 dB por defecto) / SFX. En headless no se llama a
## `play()` (no hay dispositivo): se simula el estado para tests/CI sin ERROR.

const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const SAMPLE_RATE: int = 22050
const TRACKS_PATH: String = "res://data/audio_tracks.json"
const CONFIG_PATH: String = "user://audio_config.json"

const TONE_CLICK: String = "click"
const TONE_BELL: String = "bell"
const TONE_SWORD: String = "sword"
const TONE_NAMES: Array[String] = [TONE_CLICK, TONE_BELL, TONE_SWORD]

const DEFAULT_MUSIC_VOLUME_DB: float = -6.0
const DEFAULT_SFX_VOLUME_DB: float = 0.0
const DEFAULT_MASTER_VOLUME_DB: float = 0.0
const DEFAULT_CROSSFADE_SECONDS: float = 1.8
const MIN_CROSSFADE_SECONDS: float = 1.5
const MAX_CROSSFADE_SECONDS: float = 2.0
const MUSIC_CONTEXTS: Array[String] = ["menu", "map", "battle_n2", "battle_n3", "year_end", "end"]

var muted: bool = false
var master_volume_db: float = DEFAULT_MASTER_VOLUME_DB
var music_volume_db: float = DEFAULT_MUSIC_VOLUME_DB
var sfx_volume_db: float = DEFAULT_SFX_VOLUME_DB
var crossfade_seconds: float = DEFAULT_CROSSFADE_SECONDS

## Contadores SFX (tests/QA) y de música por contexto.
var play_counts: Dictionary = {TONE_CLICK: 0, TONE_BELL: 0, TONE_SWORD: 0}
var music_play_counts: Dictionary = {}

var _streams: Dictionary = {}
var _players: Dictionary = {}
var _built: bool = false

var _tracks: Dictionary = {}
var _track_streams: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_index: int = -1
var _music_context: String = ""
var _music_started_ms: int = 0
var _last_music_error: String = ""
var music_paused: bool = false


func _ready() -> void:
	_load_settings()
	_ensure_ready()
	_apply_buses()


func _ensure_ready() -> void:
	if _built:
		return
	_built = true
	_build_streams()
	for tone_name in TONE_NAMES:
		var player := AudioStreamPlayer.new()
		player.name = "Player_" + tone_name
		player.stream = _streams.get(tone_name)
		player.volume_db = 0.0
		player.bus = "SFX"
		add_child(player)
		_players[tone_name] = player
	_create_music_players()
	_load_tracks()


func _create_music_players() -> void:
	if not _music_players.is_empty():
		return
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer_%d" % index
		player.bus = "Music"
		player.volume_db = -60.0
		player.finished.connect(_on_music_finished.bind(index))
		add_child(player)
		_music_players.append(player)


# ---------------------------------------------------------------------------
# Buses y persistencia (D-067)
# ---------------------------------------------------------------------------

func _ensure_bus(bus_name: String, send: String, volume_db: float) -> int:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, send)
	AudioServer.set_bus_volume_db(index, volume_db)
	return index


func _apply_buses() -> void:
	var master_index: int = _ensure_bus("Master", "", master_volume_db)
	_ensure_bus("Music", "Master", music_volume_db)
	_ensure_bus("SFX", "Master", sfx_volume_db)
	AudioServer.set_bus_mute(master_index, muted)


func get_music_bus_index() -> int:
	return AudioServer.get_bus_index("Music")


func get_sfx_bus_index() -> int:
	return AudioServer.get_bus_index("SFX")


func get_master_bus_index() -> int:
	return AudioServer.get_bus_index("Master")


func _load_settings() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = SafeDict.as_dict(json.data)
	master_volume_db = clampf(SafeDict.as_float(data.get("master_volume_db"), DEFAULT_MASTER_VOLUME_DB), -60.0, 6.0)
	music_volume_db = clampf(SafeDict.as_float(data.get("music_volume_db"), DEFAULT_MUSIC_VOLUME_DB), -60.0, 6.0)
	sfx_volume_db = clampf(SafeDict.as_float(data.get("sfx_volume_db"), DEFAULT_SFX_VOLUME_DB), -60.0, 6.0)
	muted = SafeDict.as_bool(data.get("muted"), false)
	crossfade_seconds = clampf(SafeDict.as_float(data.get("crossfade_seconds"), DEFAULT_CROSSFADE_SECONDS),
		MIN_CROSSFADE_SECONDS, MAX_CROSSFADE_SECONDS)


func save_settings() -> bool:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return false
	var data: Dictionary = {
		"schema_version": 1,
		"master_volume_db": master_volume_db,
		"music_volume_db": music_volume_db,
		"sfx_volume_db": sfx_volume_db,
		"muted": muted,
		"crossfade_seconds": crossfade_seconds,
	}
	file.store_string(JSON.stringify(data, "\t", true))
	file.close()
	return true


func load_settings() -> bool:
	_load_settings()
	_apply_buses()
	return true


func reset_settings() -> void:
	master_volume_db = DEFAULT_MASTER_VOLUME_DB
	music_volume_db = DEFAULT_MUSIC_VOLUME_DB
	sfx_volume_db = DEFAULT_SFX_VOLUME_DB
	muted = false
	crossfade_seconds = DEFAULT_CROSSFADE_SECONDS
	_apply_buses()
	save_settings()


# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------

func play_ui_click(volume_offset_db: float = 0.0) -> bool:
	return _play(TONE_CLICK, volume_offset_db)


func play_year_bell(volume_offset_db: float = 0.0) -> bool:
	return _play(TONE_BELL, volume_offset_db)


func play_sword(volume_offset_db: float = 0.0) -> bool:
	return _play(TONE_SWORD, volume_offset_db)


func _play(tone_name: String, volume_offset_db: float) -> bool:
	_ensure_ready()
	if muted:
		return false
	var player_value: Variant = _players.get(tone_name)
	if player_value == null:
		return false
	var player: AudioStreamPlayer = player_value
	if player.stream == null:
		return false
	play_counts[tone_name] = SafeDict.as_int(play_counts.get(tone_name), 0) + 1
	if _simulate_only():
		return true
	player.volume_db = clampf(volume_offset_db, -60.0, 6.0)
	player.play()
	return true


func _simulate_only() -> bool:
	if not is_inside_tree():
		return true
	if DisplayServer.get_name() == "headless":
		return true
	return false


func set_muted(value: bool) -> void:
	muted = value
	var master_index: int = get_master_bus_index()
	if master_index >= 0:
		AudioServer.set_bus_mute(master_index, muted)
	save_settings()


func is_muted() -> bool:
	return muted


func toggle_muted() -> bool:
	set_muted(not muted)
	return muted


## Compatibilidad con la API SFX anterior: volumen maestro en dB.
func set_volume_db(value: float) -> void:
	set_master_volume_db(value)


func get_volume_db() -> float:
	return master_volume_db


func set_master_volume_db(value: float) -> void:
	master_volume_db = clampf(value, -60.0, 6.0)
	var index: int = get_master_bus_index()
	if index >= 0:
		AudioServer.set_bus_volume_db(index, master_volume_db)
	save_settings()


func set_music_volume_db(value: float) -> void:
	music_volume_db = clampf(value, -60.0, 6.0)
	var index: int = get_music_bus_index()
	if index >= 0:
		AudioServer.set_bus_volume_db(index, music_volume_db)
	save_settings()


func get_music_volume_db() -> float:
	return music_volume_db


func set_sfx_volume_db(value: float) -> void:
	sfx_volume_db = clampf(value, -60.0, 6.0)
	var index: int = get_sfx_bus_index()
	if index >= 0:
		AudioServer.set_bus_volume_db(index, sfx_volume_db)
	save_settings()


## Atajos 0..100 % para los sliders de AG-3 (0 % = silencio, 100 % = 0 dB).
func set_music_volume_percent(value: float) -> void:
	set_music_volume_db(linear_to_db(clampf(value / 100.0, 0.001, 1.0)))


func get_music_volume_percent() -> float:
	return clampf(db_to_linear(music_volume_db) * 100.0, 0.0, 100.0)


func set_sfx_volume_percent(value: float) -> void:
	set_sfx_volume_db(linear_to_db(clampf(value / 100.0, 0.001, 1.0)))


func get_sfx_volume_percent() -> float:
	return clampf(db_to_linear(sfx_volume_db) * 100.0, 0.0, 100.0)


func get_sfx_volume_db() -> float:
	return sfx_volume_db


func set_crossfade_seconds(value: float) -> void:
	crossfade_seconds = clampf(value, MIN_CROSSFADE_SECONDS, MAX_CROSSFADE_SECONDS)
	save_settings()


func get_crossfade_seconds() -> float:
	return crossfade_seconds


func stop_all() -> void:
	for tone_name in TONE_NAMES:
		var player_value: Variant = _players.get(tone_name)
		if player_value != null:
			(player_value as AudioStreamPlayer).stop()
	stop_music(0.0)


# ---------------------------------------------------------------------------
# Música (D-067)
# ---------------------------------------------------------------------------

func _load_tracks() -> void:
	_tracks.clear()
	_track_streams.clear()
	if not FileAccess.file_exists(TRACKS_PATH):
		_last_music_error = "no existe %s" % TRACKS_PATH
		return
	var file := FileAccess.open(TRACKS_PATH, FileAccess.READ)
	if file == null:
		_last_music_error = "no se puede abrir %s" % TRACKS_PATH
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		_last_music_error = "JSON inválido %s" % TRACKS_PATH
		return
	var data: Dictionary = SafeDict.as_dict(json.data)
	var contexts: Dictionary = SafeDict.as_dict(data.get("contexts", null))
	# D-067: formato canónico `tracks` (contexto → pista); `contexts` se acepta por compatibilidad.
	if contexts.is_empty():
		contexts = SafeDict.as_dict(data.get("tracks", null))
	for context in SafeDict.sorted_keys(contexts):
		var entry: Dictionary = SafeDict.as_dict(contexts.get(context, null))
		if SafeDict.as_string(entry.get("track"), "") == "":
			entry["track"] = SafeDict.as_string(entry.get("path"), "")
		_tracks[context] = entry


func reload_tracks() -> bool:
	_load_tracks()
	return not _tracks.is_empty()


func get_track_contexts() -> Array[String]:
	_ensure_tracks_loaded()
	var result: Array[String] = []
	for context in SafeDict.sorted_keys(_tracks):
		result.append(context)
	return result


func _ensure_tracks_loaded() -> void:
	if _tracks.is_empty():
		_load_tracks()


func has_track(context: String) -> bool:
	_ensure_tracks_loaded()
	return _tracks.has(context)


func get_track_info(context: String) -> Dictionary:
	_ensure_tracks_loaded()
	return SafeDict.as_dict(_tracks.get(context, null)).duplicate(true)


func get_track_path(context: String) -> String:
	return SafeDict.as_string(get_track_info(context).get("track"), "")


## Carga (y cachea) el OGG del contexto; null si falta/ilegible.
func get_track_stream(context: String) -> Variant:
	_ensure_tracks_loaded()
	if _track_streams.has(context):
		return _track_streams.get(context)
	var info: Dictionary = get_track_info(context)
	var path: String = SafeDict.as_string(info.get("track"), "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var stream: Variant = load(path)
	if stream == null:
		return null
	if stream is AudioStreamOggVorbis:
		var ogg: AudioStreamOggVorbis = stream
		ogg.loop = SafeDict.as_bool(info.get("loop"), true)
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if SafeDict.as_bool(info.get("loop"), true) else AudioStreamWAV.LOOP_DISABLED
	_track_streams[context] = stream
	return stream


func get_track_duration_ms(context: String) -> float:
	var stream_value: Variant = get_track_stream(context)
	if stream_value is AudioStream:
		return roundf((stream_value as AudioStream).get_length() * 1000.0 * 10.0) / 10.0
	return 0.0


func is_music_playing() -> bool:
	return _music_context != ""


func get_music_context() -> String:
	return _music_context


func get_music_started_ms() -> int:
	return _music_started_ms


func get_music_position_ms() -> int:
	if _active_music_index < 0 or _active_music_index >= _music_players.size():
		return 0
	var player: AudioStreamPlayer = _music_players[_active_music_index]
	if player == null or not player.playing:
		return 0
	return int(player.get_playback_position() * 1000.0)


func get_music_play_count(context: String) -> int:
	return SafeDict.as_int(music_play_counts.get(context), 0)


func get_last_music_error() -> String:
	return _last_music_error


## Reproduce el contexto musical con crossfade (≈1,8 s por defecto).
func play_music(context: String, fade_seconds: float = -1.0) -> bool:
	_ensure_ready()
	_ensure_tracks_loaded()
	if context == "" or not _tracks.has(context):
		_last_music_error = "contexto musical desconocido: %s" % context
		return false
	if _music_context == context and _active_music_index >= 0:
		var current: AudioStreamPlayer = _music_players[_active_music_index]
		if current.stream != null and (current.playing or _simulate_only()):
			return true
	var stream_value: Variant = get_track_stream(context)
	if stream_value == null:
		_last_music_error = "pista no disponible: %s" % get_track_path(context)
		return false
	var info: Dictionary = get_track_info(context)
	var target_db: float = SafeDict.as_float(info.get("volume_db"), 0.0)
	var fade: float = fade_seconds
	if fade < 0.0:
		fade = crossfade_seconds
	fade = clampf(fade, 0.0, 5.0)
	var old_index: int = _active_music_index
	var new_index: int = 1 if old_index == 0 else 0
	var new_player: AudioStreamPlayer = _music_players[new_index]
	new_player.stream = stream_value
	new_player.volume_db = target_db if old_index < 0 or _simulate_only() else -60.0
	if not _simulate_only():
		new_player.play()
	if _simulate_only():
		if old_index >= 0:
			_music_players[old_index].stop()
			_music_players[old_index].volume_db = -60.0
		_active_music_index = new_index
	elif old_index >= 0:
		var old_player: AudioStreamPlayer = _music_players[old_index]
		if fade <= 0.0:
			old_player.stop()
			old_player.volume_db = -60.0
		else:
			var out_tween: Tween = create_tween()
			out_tween.tween_property(old_player, "volume_db", -60.0, fade)
			out_tween.tween_callback(old_player.stop)
		if fade > 0.0:
			var in_tween: Tween = create_tween()
			in_tween.tween_property(new_player, "volume_db", target_db, fade)
	_active_music_index = new_index
	_music_context = context
	_music_started_ms = Time.get_ticks_msec()
	music_play_counts[context] = SafeDict.as_int(music_play_counts.get(context), 0) + 1
	if music_paused:
		for player in _music_players:
			if player != null:
				player.stream_paused = true
	return true


## Alias para AG-3/UI.
func play_context(context: String, fade_seconds: float = -1.0) -> bool:
	return play_music(context, fade_seconds)


## Alias con crossfade en milisegundos (firma pedida por AG-3).
func set_music_context(context: String, crossfade_ms: int = 1800) -> bool:
	return play_music(context, clampf(float(crossfade_ms) / 1000.0, 0.0, 5.0))


## Alias usados por el harness QA C11/AG-3.
func play_music_context(context: String, crossfade_ms: int = 1800) -> bool:
	return set_music_context(context, crossfade_ms)


func crossfade(context: String, crossfade_ms: int = 1800) -> bool:
	return set_music_context(context, crossfade_ms)


func set_music_volume(value_db: float) -> void:
	set_music_volume_db(value_db)


func get_music_volume() -> float:
	return get_music_volume_db()


## Pausa/atenúa la música sin perder el contexto (opciones de pausa).
func set_paused(value: bool) -> void:
	music_paused = value
	for player in _music_players:
		if player != null:
			player.stream_paused = value


func is_paused() -> bool:
	return music_paused


func set_music_paused(value: bool) -> void:
	set_paused(value)


## Detiene la música con fade (0 = inmediato).
func stop_music(fade_seconds: float = 1.0) -> bool:
	if _active_music_index >= 0:
		var player: AudioStreamPlayer = _music_players[_active_music_index]
		var fade: float = clampf(fade_seconds, 0.0, 5.0)
		if _simulate_only() or fade <= 0.0:
			player.stop()
			player.volume_db = -60.0
		else:
			var tween: Tween = create_tween()
			tween.tween_property(player, "volume_db", -60.0, fade)
			tween.tween_callback(player.stop)
	_music_context = ""
	_active_music_index = -1
	return true


func _on_music_finished(index: int) -> void:
	if index != _active_music_index:
		return
	var info: Dictionary = get_track_info(_music_context)
	if SafeDict.as_bool(info.get("loop"), false):
		return
	_music_context = ""
	_active_music_index = -1


# ---------------------------------------------------------------------------
# Generación de SFX (sin assets, determinista)
# ---------------------------------------------------------------------------

func _build_streams() -> void:
	_streams[TONE_CLICK] = _make_click()
	_streams[TONE_BELL] = _make_bell()
	_streams[TONE_SWORD] = _make_sword()


func _make_click() -> AudioStreamWAV:
	var duration: float = 0.045
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = exp(-t * 70.0) * minf(1.0, t * 400.0)
		var value: float = sin(TAU * 1200.0 * t) * 0.55 + sin(TAU * 2400.0 * t) * 0.20
		_write_sample(data, i, value * envelope * 0.55)
	return _make_wav(data)


func _make_bell() -> AudioStreamWAV:
	var duration: float = 0.9
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var attack: float = minf(1.0, t / 0.008)
		var envelope: float = attack * exp(-t * 3.2)
		var value: float = sin(TAU * 440.0 * t) * 0.50
		value += sin(TAU * 660.0 * t) * 0.30
		value += sin(TAU * 880.0 * t) * 0.20
		value += sin(TAU * 1320.0 * t) * 0.08
		_write_sample(data, i, value * envelope * 0.55)
	return _make_wav(data)


func _make_sword() -> AudioStreamWAV:
	var duration: float = 0.18
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t: float = float(i) / float(SAMPLE_RATE)
		var noise: float = _local_noise(i)
		var metallic: float = sin(TAU * 1700.0 * t) * 0.45 + sin(TAU * 2600.0 * t) * 0.25
		var thud: float = sin(TAU * 120.0 * t) * exp(-t * 20.0) * 0.55
		var envelope: float = exp(-t * 16.0) * minf(1.0, t * 500.0)
		_write_sample(data, i, (noise * 0.35 + metallic) * envelope + thud * 0.35)
	return _make_wav(data)


func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav


func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var clamped: float = clampf(value, -1.0, 1.0)
	var sample: int = int(roundf(clamped * 32767.0))
	if sample < 0:
		sample = 65536 + sample
	data[index * 2] = sample & 0xFF
	data[index * 2 + 1] = (sample >> 8) & 0xFF


## Ruido determinista local (LCG), independiente de GameState.rng.
static func _local_noise(index: int) -> float:
	var state: int = (index * 1103515245 + 12345) & 0x7FFFFFFF
	var normalized: float = float((state >> 16) & 0x7FFF) / 16384.5
	return normalized - 1.0


# ---------------------------------------------------------------------------
# Contadores/reset
# ---------------------------------------------------------------------------

func reset_counts() -> void:
	for tone_name in TONE_NAMES:
		play_counts[tone_name] = 0
	music_play_counts.clear()


func get_play_count(tone_name: String) -> int:
	return SafeDict.as_int(play_counts.get(tone_name), 0)


func get_play_counts() -> Dictionary:
	return play_counts.duplicate(true)


func has_tone(tone_name: String) -> bool:
	var stream_value: Variant = _streams.get(tone_name)
	return stream_value is AudioStreamWAV


func get_tone_duration_ms(tone_name: String) -> float:
	var stream_value: Variant = _streams.get(tone_name)
	if stream_value is AudioStreamWAV:
		var wav: AudioStreamWAV = stream_value
		var bytes_per_sample: int = 2
		var channels: int = 2 if wav.stereo else 1
		var frames: int = wav.data.size() / (bytes_per_sample * channels)
		return roundf(float(frames) / float(wav.mix_rate) * 1000.0 * 10.0) / 10.0
	return 0.0
