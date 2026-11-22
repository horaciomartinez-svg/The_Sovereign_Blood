extends RefCounted
## D-080: textos de legibilidad de AG-1 y sustitución determinista de tokens.

const DATA_PATH := "res://data/legibility_texts.json"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

static var _data: Dictionary = {}
static var _loaded := false


static func _lazy_load() -> void:
	if _loaded:
		return
	_loaded = true
	var from_loader := TSBGame.legibility_texts()
	if not from_loader.is_empty():
		_data = from_loader
		return
	if not FileAccess.file_exists(DATA_PATH):
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_data = parsed


static func text(path: String, fallback: String = "") -> String:
	_lazy_load()
	var current: Variant = _data
	for part: String in path.split("."):
		if not (current is Dictionary) or not (current as Dictionary).has(part):
			return fallback
		current = (current as Dictionary)[part]
	return str(current) if current != null else fallback


static func format(template: String, tokens: Dictionary) -> String:
	var result := template
	for key: Variant in tokens.keys():
		result = result.replace("{%s}" % str(key), str(tokens[key]))
	return result


static func season_name(index: int) -> String:
	_lazy_load()
	var seasons: Variant = _data.get("seasons", [])
	if seasons is Array and index >= 1 and index <= (seasons as Array).size():
		return str((seasons as Array)[index - 1])
	const FALLBACK := ["Primavera", "Verano", "Otoño", "Invierno"]
	return FALLBACK[clampi(index - 1, 0, 3)]
