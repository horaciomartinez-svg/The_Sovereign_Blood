extends Node2D
## Capa 4 del mapa §10.1: entidades (banderas, ciudades, ejercitos, nombres con
## elision anti-solape en 3 niveles de zoom y etiquetas de mar).
##
## Todo el dibujo es por codigo en un unico Node2D: se redibuja solo al cambiar
## zoom/ano/estado (nunca por frame), manteniendo el coste CPU del mapa bajo.

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const Heraldry = preload("res://scripts/ui/heraldry.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

const ZOOM_COUNTRY := 0.9
const ZOOM_DETAIL := 1.5

const SEA_LABELS: Array[Dictionary] = [
	{"text": "MARE SEPTENTRIONALE", "pos": Vector2(0.24, 0.09), "size": 24},
	{"text": "OCEANUS OCCIDENTALIS", "pos": Vector2(0.07, 0.42), "size": 22},
	{"text": "MARE NOSTRUM", "pos": Vector2(0.41, 0.74), "size": 24},
	{"text": "MARE BALTICUM", "pos": Vector2(0.45, 0.13), "size": 18},
	{"text": "PONTUS EUXINUS", "pos": Vector2(0.66, 0.48), "size": 18},
	{"text": "LEGUES", "pos": Vector2(0.90, 0.94), "size": 14},
]

var year: int = 0
var map_size: Vector2 = Vector2(2048, 1536)
var zoom: float = 0.7
var in_game: bool = false
var show_armies: bool = true

var _font: Font = null
var _candidates: Array[Dictionary] = []
var _visible_labels: Array[Dictionary] = []
var _entries: Dictionary = {}          # region_id -> entrada de map_borders
var _centers: Dictionary = {}          # region_id -> Vector2 (normalizado)
var _region_data: Dictionary = {}      # region_id -> dict de region (terreno, ciudad, poblacion)
var _capitals: Dictionary = {}         # faction_id -> region_id capital
var _faction_anchors: Dictionary = {}  # faction_id -> region donde dibujar bandera (capital o primera posesion)
var _faction_house: Dictionary = {}    # faction_id -> house del gobernante


func _ready() -> void:
	z_index = 2
	_font = ThemeBuilder.get_font()


func configure(new_year: int, new_map_size: Vector2, new_zoom: float, game_mode: bool) -> void:
	year = new_year
	map_size = new_map_size
	zoom = new_zoom
	in_game = game_mode
	_load_data()
	_rebuild_labels()
	queue_redraw()


func set_zoom(new_zoom: float) -> void:
	if is_equal_approx(zoom, new_zoom):
		return
	zoom = new_zoom
	_rebuild_labels()
	queue_redraw()


func refresh() -> void:
	_load_data()
	_rebuild_labels()
	queue_redraw()


func _zoom_level() -> int:
	if zoom < ZOOM_COUNTRY:
		return 0
	if zoom < ZOOM_DETAIL:
		return 1
	return 2


func _screen_font_size() -> int:
	match _zoom_level():
		0:
			return 13
		1:
			return 14
	return 15


func _load_data() -> void:
	_entries.clear()
	_centers.clear()
	_region_data.clear()
	_capitals.clear()
	_faction_house.clear()
	for entry: Variant in TSBGame.map_borders_for_year(year):
		if entry is Dictionary:
			var entry_dict := entry as Dictionary
			_entries[str(entry_dict.get("region_id", ""))] = entry_dict
	for region_id: Variant in TSBGame.region_ids():
		var rid := str(region_id)
		var entry: Dictionary = _entries.get(rid, {})
		var center := Vector2(0.5, 0.5)
		var raw_center: Variant = entry.get("center", null)
		if raw_center is Array and (raw_center as Array).size() >= 2:
			center = Vector2(float((raw_center as Array)[0]), float((raw_center as Array)[1]))
		else:
			center = TSBGame.map_center(rid, year)
		_centers[rid] = center
		_region_data[rid] = TSBGame.region(rid)
	for faction_id: Variant in TSBGame.faction_ids():
		var fid := str(faction_id)
		_capitals[fid] = TSBGame.faction_capital(fid)
		var ruler := TSBGame.ruler(fid)
		_faction_house[fid] = str(ruler.get("house", fid))
	# Ancla de bandera: la capital si la posee en esta vista; si no, su primera
	# region poseida (asi las 14 potencias tienen bandera incluso en 1402/1453).
	var first_owned: Dictionary = {}
	for rid: Variant in _entries.keys():
		var entry: Dictionary = _entries[rid]
		var owner := str(entry.get("owner", ""))
		if not owner.is_empty() and not first_owned.has(owner):
			first_owned[owner] = str(rid)
	_faction_anchors.clear()
	for fid: Variant in _capitals.keys():
		var faction_id := str(fid)
		var capital := str(_capitals[faction_id])
		var anchor := ""
		if not capital.is_empty():
			var capital_entry: Dictionary = _entries.get(capital, {})
			if str(capital_entry.get("owner", "")) == faction_id:
				anchor = capital
		if anchor.is_empty():
			anchor = str(first_owned.get(faction_id, ""))
		_faction_anchors[faction_id] = anchor


func _rebuild_labels() -> void:
	_visible_labels.clear()
	if not _entries.is_empty():
		var level := _zoom_level()
		var candidates: Array[Dictionary] = []
		for region_id: Variant in _entries.keys():
			var rid := str(region_id)
			if not _centers.has(rid):
				continue
			var entry: Dictionary = _entries[rid]
			var owner := str(entry.get("owner", ""))
			var data: Dictionary = _region_data.get(rid, {})
			var is_capital := _is_capital_of(rid, owner)
			var has_city := bool(data.get("has_city", false))
			var population := int(data.get("population", 0))
			var text := TSBGame.map_label_for(rid, year)
			if level == 0 and is_capital:
				text = _short_faction_name(owner)
			var rank := 0 if is_capital else (1 if has_city else 2)
			candidates.append({
				"region_id": rid,
				"text": text,
				"center": _centers[rid],
				"rank": rank,
				"population": population,
				"owner": owner,
				"is_capital": is_capital,
				"has_city": has_city,
			})
		# En el nivel pais, las potencias sin capital propia muestran su nombre
		# y bandera en su primera region poseida.
		if level == 0:
			for fid: Variant in _faction_anchors.keys():
				var faction_id := str(fid)
				var anchor := str(_faction_anchors[faction_id])
				if anchor.is_empty() or not _centers.has(anchor):
					continue
				if _is_capital_of(anchor, faction_id):
					continue
				candidates.append({
					"region_id": anchor,
					"text": _short_faction_name(faction_id),
					"center": _centers[anchor],
					"rank": 0,
					"population": 0,
					"owner": faction_id,
					"is_capital": true,
					"has_city": false,
				})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("rank", 9)) != int(b.get("rank", 9)):
				return int(a.get("rank", 9)) < int(b.get("rank", 9))
			return int(a.get("population", 0)) > int(b.get("population", 0)))
		var placed: Array[Rect2] = []
		var font_size := int(round(float(_screen_font_size()) / maxf(zoom, 0.01)))
		for candidate: Dictionary in candidates:
			if level == 0 and not bool(candidate.get("is_capital", false)):
				continue
			var text := str(candidate.get("text", ""))
			if text.is_empty():
				continue
			var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var world_size := text_size / maxf(zoom, 0.01)
			var center: Vector2 = candidate.get("center", Vector2.ZERO) * map_size
			var rect := Rect2(center + Vector2(-world_size.x * 0.5, -world_size.y * 0.5), world_size)
			if level < 2:
				var overlaps := false
				for prior: Rect2 in placed:
					if prior.intersects(rect.grow(world_size.y * 0.18)):
						overlaps = true
						break
				if overlaps:
					continue
				placed.append(rect)
			_visible_labels.append({
				"text": text,
				"center": center,
				"rect": rect,
				"font_size": font_size,
				"capital": bool(candidate.get("is_capital", false)),
				"owner": str(candidate.get("owner", "")),
				"city": bool(candidate.get("has_city", false)),
			})


func _is_capital_of(region_id: String, owner: String) -> bool:
	if owner.is_empty():
		return false
	return str(_capitals.get(owner, "")) == region_id


const SHORT_FACTION_NAMES := {
	"england": "Inglaterra",
	"france": "Francia",
	"hre": "Sacro Imperio",
	"bohemia": "Bohemia",
	"hungary": "Hungría",
	"castile": "Castilla",
	"aragon": "Aragón",
	"poland": "Polonia",
	"scotland": "Escocia",
	"papacy": "Papado",
	"granada": "Granada",
	"mamluks": "Mamelucos",
	"byzantium": "Bizancio",
	"golden_horde": "Horda de Oro",
}


func _short_faction_name(faction_id: String) -> String:
	if SHORT_FACTION_NAMES.has(faction_id):
		return str(SHORT_FACTION_NAMES[faction_id])
	var full := TSBGame.faction_name(faction_id)
	for prefix: String in ["Reino de ", "Corona de ", "Sacro Imperio Romano Germánico", "Sultanato Nazarí de ", "Sultanato ", "Papado de ", "Imperio ", "Horda de Oro", "Kanato de "]:
		if full.begins_with(prefix):
			var stripped := full.substr(prefix.length()).strip_edges()
			if not stripped.is_empty():
				full = stripped
			break
	if full.length() > 16:
		full = full.substr(0, 15) + "."
	return full


func _draw() -> void:
	if _font == null:
		return
	_draw_sea_labels()
	if _entries.is_empty():
		return
	_draw_faction_flags()
	_draw_city_icons()
	_draw_region_labels()
	if in_game and show_armies and year == TSBGame.start_year():
		_draw_armies()


func _draw_sea_labels() -> void:
	for label: Dictionary in SEA_LABELS:
		var font_size := int(round(float(label.get("size", 20)) / maxf(zoom, 0.01)))
		var pos: Vector2 = label.get("pos", Vector2.ZERO) * map_size
		var text := str(label.get("text", ""))
		var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(_font, pos - Vector2(size.x * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.with_alpha(Palette.PARCHMENT, 0.38))


func _draw_faction_flags() -> void:
	for faction_id: Variant in _faction_anchors.keys():
		var fid := str(faction_id)
		var anchor := str(_faction_anchors.get(fid, ""))
		if anchor.is_empty() or not _centers.has(anchor):
			continue
		var center: Vector2 = _centers[anchor] * map_size
		var flag_size := Vector2(24.0, 28.0) / maxf(zoom, 0.01)
		var rect := Rect2(center + Vector2(-flag_size.x * 0.5, -flag_size.y - 4.0 / zoom), flag_size)
		Heraldry.draw_shield(self, rect, TSBGame.faction_color(fid), str(_faction_house.get(fid, fid)), maxf(1.4 / zoom, 0.8))


func _draw_city_icons() -> void:
	var level := _zoom_level()
	if level == 0:
		return
	var icon_scale := 10.0 / maxf(zoom, 0.01)
	for region_id: Variant in _centers.keys():
		var data: Dictionary = _region_data.get(str(region_id), {})
		if not bool(data.get("has_city", false)):
			continue
		var center: Vector2 = _centers[str(region_id)] * map_size
		var base := center + Vector2(icon_scale * 0.9, -icon_scale * 0.5)
		draw_rect(Rect2(base, Vector2(icon_scale, icon_scale * 1.1)), Palette.with_alpha(Palette.INK, 0.75))
		draw_rect(Rect2(base + Vector2(-icon_scale * 0.18, -icon_scale * 0.5), Vector2(icon_scale * 0.28, icon_scale * 0.5)), Palette.with_alpha(Palette.INK, 0.75))
		draw_rect(Rect2(base + Vector2(icon_scale * 0.54, -icon_scale * 0.5), Vector2(icon_scale * 0.28, icon_scale * 0.5)), Palette.with_alpha(Palette.INK, 0.75))


func _draw_region_labels() -> void:
	for label: Dictionary in _visible_labels:
		var text := str(label.get("text", ""))
		var center: Vector2 = label.get("center", Vector2.ZERO)
		var font_size := int(label.get("font_size", 16))
		var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var pos := center + Vector2(-size.x * 0.5, size.y * 0.22)
		var ink := Palette.INK_TEXT if bool(label.get("capital", false)) else Palette.INK
		var halo := Palette.with_alpha(Palette.PARCHMENT_LIGHT, 0.82)
		draw_string(_font, pos + Vector2(1.2 / zoom, 1.2 / zoom), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, halo)
		draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)


func _draw_armies() -> void:
	for region_id: Variant in _centers.keys():
		var rid := str(region_id)
		var armies := TSBGame.armies_in(rid)
		if armies.is_empty():
			continue
		var center: Vector2 = _centers[rid] * map_size
		var soldiers := 0
		var colors: Array[Color] = []
		for army: Variant in armies:
			if army is Dictionary:
				soldiers += TSBGame.army_soldiers(army)
				colors.append(TSBGame.faction_color(str((army as Dictionary).get("faction_id", ""))))
		if colors.is_empty():
			continue
		var flag_w := 7.0 / maxf(zoom, 0.01)
		var flag_h := 12.0 / maxf(zoom, 0.01)
		var origin := center + Vector2(-flag_w * 1.4, flag_h * 1.4)
		for i in range(mini(colors.size(), 3)):
			var o := origin + Vector2(i * flag_w * 1.6, 0)
			draw_line(o, o + Vector2(0, -flag_h), Palette.INK, maxf(1.2 / zoom, 0.7), true)
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(0.6 / zoom, -flag_h),
				o + Vector2(flag_w, -flag_h * 0.72),
				o + Vector2(0.6 / zoom, -flag_h * 0.45),
			]), colors[i].lightened(0.12))
		var text_size := str(soldiers)
		var font_size := int(round(11.0 / maxf(zoom, 0.01)))
		var count_text := TSBGame.short_number(soldiers)
		var text_px := _font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos := center + Vector2(-text_px.x * 0.5, flag_h * 2.0)
		draw_string(_font, text_pos + Vector2(1.0 / zoom, 1.0 / zoom), count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.with_alpha(Palette.INK_DEEP, 0.85))
		draw_string(_font, text_pos, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.GOLD_BRIGHT)
