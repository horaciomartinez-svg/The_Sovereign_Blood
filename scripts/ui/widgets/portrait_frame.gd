extends Control
## Retrato de personaje (GDD v1.4 §10.2, contrato fase2 §3).
##
## Fallback SIEMPRE visible: si el personaje define `portrait` y el asset existe
## en assets/art/portraits/<id>.png se dibuja la textura; si no, se compone por
## codigo: fondo pergamino, heraldica generativa de su casa (escudo), silueta
## generica por sexo/edad y marco dorado. Nunca queda un hueco vacio.
##
## API de test: get_portrait_character_id() e is_fallback().
## Uso: var p = PortraitFrame.new(); add_child(p); p.setup("edward_iii_plantagenet", Vector2(120,140))

const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const Heraldry = preload("res://scripts/ui/heraldry.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

const PORTRAIT_DIR := "res://assets/art/portraits"
const DEFAULT_SIZE := Vector2(120, 140)

var character_id: String = ""
var show_frame: bool = true
var show_heraldry: bool = true
var portrait_size: Vector2 = DEFAULT_SIZE

var _character: Dictionary = {}
var _texture: Texture2D = null
var _texture_checked: bool = false
var _is_fallback: bool = true
var _stain_seed: int = 0
var _sex: String = "male"
var _age: int = 30
var _is_ruler: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = portrait_size
	if not character_id.is_empty():
		_reload()


## Configura el retrato. `char_data` es opcional: si se omite se lee de TSBGame.
func setup(new_character_id: String, char_data: Dictionary = {}) -> void:
	character_id = new_character_id
	if char_data.is_empty():
		_character = {}
	else:
		_character = char_data.duplicate(true)
	_texture = null
	_texture_checked = false
	_reload()
	queue_redraw()


## Vuelve a leer el personaje desde el estado (p. ej. tras una sucesion).
func refresh() -> void:
	_reload()
	queue_redraw()


func get_portrait_character_id() -> String:
	return character_id


func is_fallback() -> bool:
	if not _texture_checked:
		_resolve_texture()
	return _is_fallback


## Fuerza un tamano (el Control ya puede venir dimensionado por su contenedor).
func set_portrait_size(new_size: Vector2) -> void:
	portrait_size = new_size
	custom_minimum_size = new_size
	queue_redraw()


func _reload() -> void:
	if character_id.is_empty():
		# Mantiene un dict de respaldo (faccion/casa) si el llamador lo aporto,
		# para que el fallback nunca quede vacio.
		_is_fallback = true
		_texture_checked = false
		_texture = null
		if _character.is_empty():
			_age = 30
			_sex = "male"
			_is_ruler = false
			_stain_seed = absi(hash("fallback"))
		else:
			_age = TSBGame.character_age(_character)
			_sex = _infer_sex(_character)
			_is_ruler = bool(_character.get("is_ruler", false)) or str(_character.get("role", "")) == "ruler"
			_stain_seed = absi(hash(str(_character.get("house", "")) + str(_character.get("faction", ""))))
		_resolve_texture()
		return
	if _character.is_empty():
		_character = TSBGame.character(character_id)
	else:
		# Mantiene el dict pero completa campos que hayan cambiado en el estado.
		var latest := TSBGame.character(character_id)
		if not latest.is_empty():
			for key: Variant in latest.keys():
				if not _character.has(key):
					_character[key] = latest[key]
	_is_ruler = bool(_character.get("is_ruler", false)) or str(_character.get("role", "")) == "ruler"
	_age = TSBGame.character_age(_character)
	_sex = _infer_sex(_character)
	_stain_seed = absi(hash(character_id + str(_character.get("house", ""))))
	_texture_checked = false
	_texture = null
	_resolve_texture()


func _resolve_texture() -> void:
	_texture_checked = true
	_is_fallback = true
	if _character.is_empty():
		return
	var portrait_id := str(_character.get("portrait", ""))
	if portrait_id.is_empty():
		return
	var path := "%s/%s.png" % [PORTRAIT_DIR, portrait_id]
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			_texture = loaded as Texture2D
			_is_fallback = false


## Heuristica determinista de sexo: campo opcional `sex`/`gender` y, si no
## existe (datos Fase 2 aun sin assets finales), terminacion/nombre conocido.
func _infer_sex(character: Dictionary) -> String:
	var explicit := str(character.get("sex", character.get("gender", ""))).to_lower()
	if explicit in ["female", "f", "mujer", "femenino"]:
		return "female"
	if explicit in ["male", "m", "hombre", "masculino"]:
		return "male"
	var name_text := str(character.get("name", "")).to_lower()
	var female_names := [
		"isabel", "felipa", "juana", "blanca", "maria", "maría", "catalina", "constanza",
		"leonor", "elionor", "beatriz", "urraca", "berenguela", "mafalda", "sancha",
		"teresa", "aldonza", "violante", "ana", "agnes", "agnes", "cecilia", "margarita",
		"pedro", "petronila", "elvira", "estefania", "estefanía", "sofia", "sofía",
		"ines", "inés", "johanna", "katharina", "elisabeth", "anne", "mary", "philippa",
		"joan", "eleanor", "blanche", "isabella", "catherine", "constance", "agnes",
		"margaret", "cecily", "alice", "maud", "rohese",
	]
	for female: String in female_names:
		if name_text.begins_with(female):
			return "female"
	if name_text.ends_with("a") or name_text.ends_with("ia"):
		return "female"
	return "male"


# ==========================================================================
# Dibujo
# ==========================================================================
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return
	if not _texture_checked:
		_resolve_texture()
	var inner := rect.grow(-4.0)
	# Fondo pergamino (siempre, tambien bajo la textura para never-empty).
	_draw_parchment(inner)
	if _texture != null:
		_draw_texture(inner)
	else:
		_draw_fallback(inner)
	if show_frame:
		_draw_frame(rect)


func _draw_parchment(inner: Rect2) -> void:
	draw_rect(inner, Palette.PARCHMENT)
	# Bandas de acuarela y manchas deterministas.
	var band_count := 7
	for i in range(band_count):
		var t := float(i) / float(band_count)
		var color := Palette.PARCHMENT_LIGHT.lerp(Palette.PARCHMENT_DARK, t * 0.35)
		color.a = 0.45
		draw_rect(Rect2(inner.position.x, inner.position.y + inner.size.y * t, inner.size.x, inner.size.y / float(band_count) + 1.0), color)
	var rng := RandomNumberGenerator.new()
	rng.seed = _stain_seed
	for i in range(7):
		var pos := inner.position + Vector2(rng.randf_range(0.05, 0.95) * inner.size.x, rng.randf_range(0.05, 0.95) * inner.size.y)
		var radius := rng.randf_range(0.03, 0.12) * minf(inner.size.x, inner.size.y)
		draw_circle(pos, radius, Color(0.42, 0.30, 0.14, rng.randf_range(0.02, 0.05)))
	# Vineta.
	draw_rect(Rect2(inner.position, inner.size), Color(0.10, 0.07, 0.03, 0.10), false, maxf(inner.size.x * 0.04, 2.0))


func _draw_texture(inner: Rect2) -> void:
	var side := minf(inner.size.x, inner.size.y)
	var target := Rect2(inner.position + (inner.size - Vector2(side, side)) * 0.5, Vector2(side, side))
	draw_texture_rect(_texture, target, false)


func _draw_fallback(inner: Rect2) -> void:
	var center := inner.position + inner.size * 0.5
	var side := minf(inner.size.x, inner.size.y)
	var faction_id := str(_character.get("faction", ""))
	var house := str(_character.get("house", ""))
	var faction_color := TSBGame.faction_color(faction_id) if not faction_id.is_empty() else Palette.CRIMSON
	var clothing := faction_color.darkened(0.05)
	var skin := Palette.PARCHMENT_LIGHT.lerp(Color(0.85, 0.68, 0.52), 0.35)

	# Escudo heraldico de la casa (detras, arriba).
	if show_heraldry:
		var shield_size := Vector2(side * 0.52, side * 0.56)
		var shield_rect := Rect2(center + Vector2(-shield_size.x * 0.5, -side * 0.43), shield_size)
		draw_rect(shield_rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.10))
		Heraldry.draw_shield(self, shield_rect, faction_color, house, maxf(side * 0.018, 1.5))

	# Silueta generica por sexo/edad (busto de miniatura).
	var child := _age > 0 and _age < 14
	var elder := _age >= 55
	var head_radius := side * (0.20 if child else (0.18 if not elder else 0.175))
	var shoulder_width := side * (0.46 if child else 0.56)
	var shoulder_height := side * (0.32 if child else 0.38)
	var bust_top := center.y + side * (0.10 if child else 0.12)
	var head_center := Vector2(center.x, bust_top - head_radius * 0.45)

	# Cabello/velo (mujer) o gorro (hombre) detras de la cabeza.
	if _sex == "female":
		var hair_color := Color(0.23, 0.16, 0.10)
		draw_circle(head_center + Vector2(0, -head_radius * 0.12), head_radius * 1.20, hair_color)
		draw_colored_polygon(PackedVector2Array([
			head_center + Vector2(-head_radius * 1.1, head_radius * 0.2),
			head_center + Vector2(head_radius * 1.1, head_radius * 0.2),
			head_center + Vector2(head_radius * 1.4, head_radius * 2.4),
			head_center + Vector2(-head_radius * 1.4, head_radius * 2.4),
		]), hair_color)
	else:
		draw_circle(head_center + Vector2(0, -head_radius * 0.55), head_radius * 0.95, Color(0.20, 0.14, 0.09))

	# Hombros / ropaje.
	var shoulders := PackedVector2Array([
		Vector2(center.x - shoulder_width * 0.5, inner.position.y + inner.size.y),
		Vector2(center.x - shoulder_width * 0.42, bust_top + shoulder_height * 0.30),
		Vector2(center.x - shoulder_width * 0.22, bust_top + shoulder_height * 0.10),
		Vector2(center.x + shoulder_width * 0.22, bust_top + shoulder_height * 0.10),
		Vector2(center.x + shoulder_width * 0.42, bust_top + shoulder_height * 0.30),
		Vector2(center.x + shoulder_width * 0.5, inner.position.y + inner.size.y),
	])
	draw_colored_polygon(shoulders, clothing)
	draw_polyline(PackedVector2Array([shoulders[1], shoulders[2], shoulders[3], shoulders[4]]), clothing.darkened(0.3), maxf(side * 0.012, 1.0), true)

	# Cuello y cabeza.
	draw_rect(Rect2(Vector2(center.x - head_radius * 0.28, bust_top - head_radius * 0.05), Vector2(head_radius * 0.56, head_radius * 0.55)), skin.darkened(0.08))
	draw_circle(head_center, head_radius, skin)
	draw_circle(head_center + Vector2(0, -head_radius * 0.38), head_radius * 0.92, skin)
	# Rasgos minimalistas (miniatura).
	var eye_y := head_center.y - head_radius * 0.02
	draw_circle(Vector2(head_center.x - head_radius * 0.32, eye_y), maxf(head_radius * 0.06, 1.0), Color(0.16, 0.11, 0.07))
	draw_circle(Vector2(head_center.x + head_radius * 0.32, eye_y), maxf(head_radius * 0.06, 1.0), Color(0.16, 0.11, 0.07))
	draw_line(Vector2(head_center.x - head_radius * 0.18, head_center.y + head_radius * 0.34), Vector2(head_center.x + head_radius * 0.18, head_center.y + head_radius * 0.34), Color(0.35, 0.18, 0.14), maxf(head_radius * 0.06, 1.0), true)
	if elder:
		# Barba/canas indicativas.
		draw_colored_polygon(PackedVector2Array([
			head_center + Vector2(-head_radius * 0.62, head_radius * 0.22),
			head_center + Vector2(head_radius * 0.62, head_radius * 0.22),
			head_center + Vector2(head_radius * 0.40, head_radius * 1.28),
			head_center + Vector2(-head_radius * 0.40, head_radius * 1.28),
		]), Color(0.72, 0.70, 0.66, 0.85))
	# Corona para gobernante.
	if _is_ruler:
		_draw_crown(Vector2(center.x, head_center.y - head_radius * 1.10), head_radius * 1.05)

	# Alianza de casa en el pecho (pequeno escudo) si hay sitio.
	if show_heraldry:
		var chest_size := Vector2(side * 0.16, side * 0.18)
		Heraldry.draw_shield(self, Rect2(Vector2(center.x - chest_size.x * 0.5, bust_top + shoulder_height * 0.52), chest_size), wardrobe_secondary(faction_color, house), house, maxf(side * 0.01, 1.0))


func wardrobe_secondary(faction_color: Color, house: String) -> Color:
	return faction_color.lightened(0.25).lerp(Palette.heraldic_metal(house), 0.35)


func _draw_crown(center: Vector2, radius: float) -> void:
	var color := Palette.GOLD_BRIGHT
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius, radius * 0.4),
		center + Vector2(-radius, -radius * 0.2),
		center + Vector2(-radius * 0.45, radius * 0.12),
		center + Vector2(0, -radius * 0.45),
		center + Vector2(radius * 0.45, radius * 0.12),
		center + Vector2(radius, -radius * 0.2),
		center + Vector2(radius, radius * 0.4),
	]), color)
	draw_rect(Rect2(center + Vector2(-radius, radius * 0.4), Vector2(radius * 2.0, radius * 0.18)), color.darkened(0.25))


func _draw_frame(rect: Rect2) -> void:
	var gold := Palette.GOLD
	var inner := rect.grow(-3.0)
	draw_rect(rect.grow(-1.0), Palette.GOLD_DIM, false, 2.0)
	draw_rect(inner, gold, false, maxf(rect.size.x * 0.012, 1.5))
	draw_rect(inner.grow(-3.0), Palette.with_alpha(gold, 0.55), false, 1.0)
	# Esquinas ornamentadas.
	var corner := minf(rect.size.x, rect.size.y) * 0.12
	for c: Vector2 in [
		rect.position + Vector2(4, 4),
		rect.position + Vector2(rect.size.x - 4, 4),
		rect.position + Vector2(4, rect.size.y - 4),
		rect.position + Vector2(rect.size.x - 4, rect.size.y - 4),
	]:
		draw_circle(c, maxf(corner * 0.16, 1.5), gold)
		draw_arc(c, maxf(corner * 0.42, 2.0), 0.0, TAU, 12, Palette.with_alpha(gold, 0.65), 1.0, true)
	# Pequena divisa inferior.
	if rect.size.y > 40.0:
		var mid := rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 5.0)
		draw_line(mid - Vector2(corner * 0.5, 0), mid + Vector2(corner * 0.5, 0), Palette.with_alpha(gold, 0.8), 1.0)
		draw_circle(mid, maxf(corner * 0.10, 1.2), Palette.with_alpha(gold, 0.9))


## Helper estatico para crear un retrato ya configurado.
static func make(character_id_value: String, min_size: Vector2 = DEFAULT_SIZE) -> Control:
	var script_resource: Variant = load("res://scripts/ui/widgets/portrait_frame.gd")
	if not (script_resource is GDScript):
		return null
	var portrait: Control = (script_resource as GDScript).new()
	portrait.custom_minimum_size = min_size
	portrait.call("setup", character_id_value)
	return portrait
