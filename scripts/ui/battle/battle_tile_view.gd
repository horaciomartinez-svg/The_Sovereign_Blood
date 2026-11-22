extends Control
## Vista del campo de batalla N3 con tiles 512→128 (GDD v1.7 §10.4).
## Dibuja la rejilla determinista del BattlefieldGenerator; tile_rio/puente/
## puente_villa/camino se rotan 90° cuando la banda del río es vertical.
## Es un Control separado de la capa de proyectiles (Node2D z superior).

const TILE_DIR := "res://assets/art/battle/tiles"
const BattlefieldGenerator = preload("res://scripts/ui/battle/battlefield_generator.gd")
const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")

var field_data: Dictionary = {}
var _textures: Dictionary = {}
var _fallback_colors := {
	"rio": Color("4d6f86"),
	"montana": Color("6e675b"),
	"bosque": Color("4d5f3b"),
	"puente": Color("9b8a66"),
	"puente_villa": Color("a48c62"),
	"villa": Color("b09a6f"),
	"villa_calle": Color("a89570"),
	"camino": Color("a08b63"),
}


func setup(data: Dictionary) -> void:
	field_data = data.duplicate(true)
	var cols := int(field_data.get("cols", 8))
	var rows := int(field_data.get("rows", 3))
	var tile_size := int(field_data.get("tile_size", 128))
	custom_minimum_size = Vector2(cols * tile_size, rows * tile_size)
	queue_redraw()


func get_grid_size_px() -> Vector2:
	var cols := int(field_data.get("cols", 8))
	var rows := int(field_data.get("rows", 3))
	var tile_size := int(field_data.get("tile_size", 128))
	return Vector2(cols * tile_size, rows * tile_size)


func _grid_offset() -> Vector2:
	return (size - get_grid_size_px()) * 0.5


func cell_foot(cell: Vector2i) -> Vector2:
	var tile_size := float(field_data.get("tile_size", 128))
	var offset := _grid_offset()
	return offset + Vector2((float(cell.x) + 0.5) * tile_size, (float(cell.y) + 1.0) * tile_size - 8.0)


func cell_center(cell: Vector2i) -> Vector2:
	var tile_size := float(field_data.get("tile_size", 128))
	var offset := _grid_offset()
	return offset + Vector2((float(cell.x) + 0.5) * tile_size, (float(cell.y) + 0.5) * tile_size)


func attacker_foot() -> Vector2:
	return cell_foot(_spawn_cell("attacker_spawn"))


func defender_foot() -> Vector2:
	return cell_foot(_spawn_cell("defender_spawn"))


func _spawn_cell(key: String) -> Vector2i:
	var value: Variant = field_data.get(key, Vector2i(0, 1))
	if value is Vector2i:
		return value as Vector2i
	return Vector2i(0, 1)


func _draw() -> void:
	if field_data.is_empty():
		return
	var cols := int(field_data.get("cols", 8))
	var rows := int(field_data.get("rows", 3))
	var tile_size := float(field_data.get("tile_size", 128))
	var offset := _grid_offset()
	draw_rect(Rect2(offset, get_grid_size_px()), Color("2f3528"), true)
	for row in range(rows):
		for col in range(cols):
			var key := BattlefieldGenerator.get_tile(field_data, col, row)
			var texture := _texture_for(key)
			var dest := Rect2(offset + Vector2(float(col) * tile_size, float(row) * tile_size), Vector2(tile_size, tile_size))
			if texture != null:
				if BattlefieldGenerator.needs_vertical_rotation(field_data, col, row):
					var center := dest.position + dest.size * 0.5
					draw_set_transform(center, PI * 0.5, Vector2.ONE)
					draw_texture_rect(texture, Rect2(-dest.size * 0.5, dest.size), false)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				else:
					draw_texture_rect(texture, dest, false)
			else:
				draw_rect(dest, _fallback_colors.get(key, Palette.LAND), true)
			draw_rect(dest, Palette.with_alpha(Palette.INK, 0.22), false, 1.0)
	draw_rect(Rect2(offset, get_grid_size_px()), Palette.with_alpha(Palette.INK, 0.55), false, 2.0)


func _texture_for(key: String) -> Texture2D:
	if key.is_empty():
		return null
	if _textures.has(key):
		return _textures[key] as Texture2D
	var path := "%s/tile_%s.png" % [TILE_DIR, key]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		var loaded: Variant = load(path)
		if loaded is Texture2D:
			texture = loaded as Texture2D
	_textures[key] = texture
	return texture
