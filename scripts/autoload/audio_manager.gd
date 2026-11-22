extends Node
## AudioManager — audio mínimo del MVP-1337 (D-015 / D-066).
##
## Tonos **generados por código** (PCM 16 bits mono en `AudioStreamWAV`), sin
## assets externos ni dependencias. Cubre los tres avisos del MVP:
##   · `play_ui_click()`  — click breve de UI (AG-3 lo llama en sus botones).
##   · `play_year_bell()` — campana de fin de año (TurnManager.advance_year).
##   · `play_sword()`     — golpe/espada al resolver una ronda N3 (CloseCombat).
##
## API estable para tests/UI: volumen maestro, mute y contadores de reproducción.
## La generación es determinista (LCG local con semilla fija; NO consume
## `GameState.rng`, por tanto no altera el determinismo de la partida).

const SAMPLE_RATE: int = 22050
const SafeDict = preload("res://scripts/utils/safe_dict.gd")
const TONE_CLICK: String = "click"
const TONE_BELL: String = "bell"
const TONE_SWORD: String = "sword"
const TONE_NAMES: Array[String] = [TONE_CLICK, TONE_BELL, TONE_SWORD]

var muted: bool = false
var master_volume_db: float = 0.0
## Reproducciones efectivas por tono (para tests/QA y diagnóstico).
var play_counts: Dictionary = {TONE_CLICK: 0, TONE_BELL: 0, TONE_SWORD: 0}
var _streams: Dictionary = {}
var _players: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	_ensure_ready()


func _ensure_ready() -> void:
	if _built:
		return
	_built = true
	_build_streams()
	for tone_name in TONE_NAMES:
		var player := AudioStreamPlayer.new()
		player.name = "Player_" + tone_name
		player.stream = _streams.get(tone_name)
		player.volume_db = master_volume_db
		player.bus = "Master"
		add_child(player)
		_players[tone_name] = player


## Click de UI (≈45 ms, 1.2 kHz). Devuelve true si se reprodujo.
func play_ui_click(volume_offset_db: float = 0.0) -> bool:
	return _play(TONE_CLICK, volume_offset_db)


## Campana de fin de año (≈900 ms, parciales 440/660/880 Hz).
func play_year_bell(volume_offset_db: float = 0.0) -> bool:
	return _play(TONE_BELL, volume_offset_db)


## Golpe/espada en combate cerrado N3 (≈180 ms, ruido metálico + cuerpo).
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
	# Headless/CI: no hay dispositivo de audio ni árbol de escena listo. Se cuenta
	# la reproducción (hooks testables) pero no se llama a play() (evita ERROR).
	if _simulate_only():
		return true
	player.volume_db = clampf(master_volume_db + volume_offset_db, -60.0, 6.0)
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
	if muted:
		stop_all()


func is_muted() -> bool:
	return muted


func toggle_muted() -> bool:
	set_muted(not muted)
	return muted


## Volumen maestro en dB (-60..6); se aplica a los reproductores existentes.
func set_volume_db(value: float) -> void:
	master_volume_db = clampf(value, -60.0, 6.0)
	for tone_name in TONE_NAMES:
		var player_value: Variant = _players.get(tone_name)
		if player_value != null:
			(player_value as AudioStreamPlayer).volume_db = master_volume_db


func get_volume_db() -> float:
	return master_volume_db


func stop_all() -> void:
	if _simulate_only():
		return
	for tone_name in TONE_NAMES:
		var player_value: Variant = _players.get(tone_name)
		if player_value != null:
			(player_value as AudioStreamPlayer).stop()


func reset_counts() -> void:
	for tone_name in TONE_NAMES:
		play_counts[tone_name] = 0


func get_play_count(tone_name: String) -> int:
	return SafeDict.as_int(play_counts.get(tone_name), 0)


func get_play_counts() -> Dictionary:
	return play_counts.duplicate(true)


## True si el tono está generado y listo para reproducirse.
func has_tone(tone_name: String) -> bool:
	var stream_value: Variant = _streams.get(tone_name)
	return stream_value is AudioStreamWAV


## Duración en ms del tono generado (0 si no existe).
func get_tone_duration_ms(tone_name: String) -> float:
	var stream_value: Variant = _streams.get(tone_name)
	if stream_value is AudioStreamWAV:
		var wav: AudioStreamWAV = stream_value
		var bytes_per_sample: int = 2
		var channels: int = 2 if wav.stereo else 1
		var frames: int = wav.data.size() / (bytes_per_sample * channels)
		return roundf(float(frames) / float(wav.mix_rate) * 1000.0 * 10.0) / 10.0
	return 0.0


# ---------------------------------------------------------------------------
# Generación de tonos (sin assets, determinista)
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
