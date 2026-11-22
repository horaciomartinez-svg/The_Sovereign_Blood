extends RefCounted
## Preferencias de presentación de Fase 5A (no afectan a la simulación).
## Se guardan en user://ui_preferences.cfg para sobrevivir entre partidas.

const CONFIG_PATH := "user://ui_preferences.cfg"

static var _loaded := false
static var _season_tint := true


static func season_tint_enabled() -> bool:
	_load()
	return _season_tint


static func set_season_tint_enabled(value: bool) -> void:
	_load()
	_season_tint = value
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("visual", "season_tint", value)
	config.save(CONFIG_PATH)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		_season_tint = bool(config.get_value("visual", "season_tint", true))
