extends Node2D
## Capa de proyectiles de batalla (Fase 3 §4). Vive en un Node2D separado y
## por encima de las unidades (z_index > capa de sprites). Interpola la
## trayectoria balística a partir de `get_projectiles()` del nodo de batalla:
##   y = lerp(y0, y1, t) - arc_height * sin(pi * t)
## N2 usa los centros de hex del lienzo (q/r); N3 usa coordenadas normalizadas
## 0..1 sobre el campo de duelo. No consume RNG ni muta la batalla.

const DEFAULT_PROJECTILE_SIZE := Vector2(16, 16)

var battle_node: Node = null
var mode: String = "tactical"       # "tactical" (q/r) | "normalized" (0..1)
var point_provider: Callable = Callable()
var arena_size: Vector2 = Vector2(800, 220)
var arc_scale: float = 1.0
var _textures: Dictionary = {}


func setup(new_battle_node: Node, new_mode: String = "tactical") -> void:
	battle_node = new_battle_node
	mode = new_mode
	z_index = 10
	set_process(false)
	queue_redraw()


func set_point_provider(provider: Callable) -> void:
	point_provider = provider
	queue_redraw()


func set_arena_size(new_size: Vector2) -> void:
	arena_size = new_size
	queue_redraw()


func set_arc_scale(new_scale: float) -> void:
	arc_scale = maxf(new_scale, 0.05)
	queue_redraw()


func _draw() -> void:
	if battle_node == null or not is_instance_valid(battle_node):
		return
	var projectiles: Variant = battle_node.call("get_projectiles")
	if not (projectiles is Array):
		return
	for projectile_value: Variant in (projectiles as Array):
		if not (projectile_value is Dictionary):
			continue
		var projectile := projectile_value as Dictionary
		var start := _start_point(projectile)
		var finish := _end_point(projectile)
		if start == finish and start == Vector2.ZERO:
			continue
		var t := clampf(float(projectile.get("t", 0.0)), 0.0, 1.0)
		var position := start.lerp(finish, t)
		var ballistic := bool(projectile.get("ballistic", true))
		if ballistic:
			var arc := float(projectile.get("arc_height", 0.0)) * arc_scale
			position.y -= arc * sin(PI * t)
		var projectile_type := str(projectile.get("type", ""))
		var size := _size_for_type(projectile_type)
		var texture := _texture_for_path(str(projectile.get("sprite", "")))
		# Halo/sombra para que el proyectil se lea sobre el campo a 64 px.
		draw_circle(position, size.x * 0.75, Color(0.08, 0.06, 0.04, 0.35))
		draw_circle(position, size.x * 0.58, Color(0.98, 0.87, 0.48, 0.28))
		# Estela tenue para que el proyectil se lea sobre el mapa a zoom bajo.
		draw_line(start, position, Color(0.92, 0.80, 0.45, 0.5), 2.0, true)
		if texture != null:
			draw_texture_rect(texture, Rect2(position - size * 0.5, size), false)
		else:
			draw_circle(position, size.x * 0.45, Color(0.12, 0.10, 0.07, 0.9))
			draw_circle(position, size.x * 0.45, Color(0.85, 0.72, 0.40, 0.9), false, 1.0)


func _start_point(projectile: Dictionary) -> Vector2:
	var from_value: Variant = projectile.get("from", {})
	var from_point := from_value as Dictionary if from_value is Dictionary else {}
	return _point_of(from_point)


func _end_point(projectile: Dictionary) -> Vector2:
	var to_value: Variant = projectile.get("to", {})
	var to_point := to_value as Dictionary if to_value is Dictionary else {}
	return _point_of(to_point)


func _point_of(point: Dictionary) -> Vector2:
	if mode == "normalized":
		return Vector2(float(point.get("x", 0.0)) * arena_size.x, float(point.get("y", 0.0)) * arena_size.y)
	var q := int(float(point.get("q", 0)))
	var r := int(float(point.get("r", 0)))
	if point_provider.is_valid():
		var result: Variant = point_provider.call(q, r)
		if result is Vector2:
			return result as Vector2
	return Vector2(float(point.get("x", 0.0)), float(point.get("y", 0.0)))


func _size_for_type(projectile_type: String) -> Vector2:
	match projectile_type:
		"piedra":
			return Vector2(10, 10)
		"virote":
			return Vector2(20, 20)
		"flecha":
			return Vector2(20, 20)
		_:
			return DEFAULT_PROJECTILE_SIZE


func _texture_for_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _textures.has(path):
		return _textures[path] as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			texture = loaded as Texture2D
	_textures[path] = texture
	return texture
