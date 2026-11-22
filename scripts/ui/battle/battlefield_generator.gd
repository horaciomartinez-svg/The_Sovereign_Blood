extends RefCounted
## Generador determinista de campos N3 (GDD v1.7 §10.4 / contrato tiles §C).
##
## Deriva la composición del campo del terreno de la región estratégica:
##   plains -> pastizal/pradera; forest -> bosque; mountain -> montana;
##   coast -> río continuo (banda vertical); city -> villa/calle.
## El río cruza de orilla a orilla y se sustituyen 1-2 casillas por puentes;
## si el asentamiento está sitiado se usa puente_villa. Los caminos conectan
## las zonas de despliegue con el puente/villa. No usa el RNG de combate: el
## campo solo depende de (terreno, has_city, semilla, region_id).

const COLS := 8
const ROWS := 3
const TILE_SIZE := 128

const TILE_PASTIZAL := "pastizal"
const TILE_PASTIZAL_ARBUSTOS := "pastizal_arbustos"
const TILE_PRADERA := "pradera"
const TILE_RIO := "rio"
const TILE_PUENTE := "puente"
const TILE_PUENTE_VILLA := "puente_villa"
const TILE_COLINA := "colina"
const TILE_BOSQUE := "bosque"
const TILE_MONTANA := "montana"
const TILE_VILLA := "villa"
const TILE_VILLA_CALLE := "villa_calle"
const TILE_CAMINO := "camino"

const ROTATED_WHEN_VERTICAL := ["rio", "puente", "puente_villa", "camino"]


static func generate(terrain: String, has_city: bool, seed_value: int, region_id: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tiles: Array[String] = []
	for i in range(COLS * ROWS):
		tiles.append(_base_tile(terrain, rng))
	var river_axis := ""
	if terrain == "coast" or terrain == "river":
		river_axis = "vertical" if terrain == "coast" else "horizontal"
		_place_river(tiles, river_axis, has_city, rng)
	elif terrain == "mountain":
		_place_mountain_band(tiles, rng)
	elif terrain == "forest":
		_scatter_forest(tiles, rng)
	if has_city or terrain == "city":
		_place_village(tiles, river_axis, rng)
	_place_roads(tiles, river_axis)
	var attacker_spawn := _first_passable(tiles, 0, 1)
	var defender_spawn := _first_passable(tiles, COLS - 1, 1)
	if attacker_spawn == Vector2i(-1, -1):
		attacker_spawn = Vector2i(0, 0)
	if defender_spawn == Vector2i(-1, -1):
		defender_spawn = Vector2i(COLS - 1, ROWS - 1)
	var bridges: Array[Vector2i] = []
	var villa_cell := Vector2i(-1, -1)
	for row in range(ROWS):
		for col in range(COLS):
			var key := tiles[row * COLS + col]
			if key == TILE_PUENTE or key == TILE_PUENTE_VILLA:
				bridges.append(Vector2i(col, row))
			elif key == TILE_VILLA and villa_cell.x < 0:
				villa_cell = Vector2i(col, row)
	return {
		"cols": COLS,
		"rows": ROWS,
		"tile_size": TILE_SIZE,
		"terrain": terrain,
		"region_id": region_id,
		"seed": seed_value,
		"axis": river_axis,
		"tiles": tiles,
		"bridges": bridges,
		"villa": villa_cell,
		"attacker_spawn": attacker_spawn,
		"defender_spawn": defender_spawn,
	}


static func get_tile(field_data: Dictionary, col: int, row: int) -> String:
	if col < 0 or row < 0 or col >= int(field_data.get("cols", COLS)) or row >= int(field_data.get("rows", ROWS)):
		return ""
	var tiles: Variant = field_data.get("tiles", [])
	if not (tiles is Array):
		return ""
	var index := row * int(field_data.get("cols", COLS)) + col
	return str((tiles as Array)[index]) if index >= 0 and index < (tiles as Array).size() else ""


static func needs_vertical_rotation(field_data: Dictionary, col: int, row: int) -> bool:
	if str(field_data.get("axis", "")) != "vertical":
		return false
	return ROTATED_WHEN_VERTICAL.has(get_tile(field_data, col, row))


static func _base_tile(terrain: String, rng: RandomNumberGenerator) -> String:
	match terrain:
		"forest":
			return TILE_BOSQUE if rng.randf() < 0.45 else _grass_tile(rng)
		"mountain":
			return TILE_COLINA if rng.randf() < 0.20 else _grass_tile(rng)
		"city":
			return TILE_PASTIZAL if rng.randf() < 0.65 else TILE_PRADERA
		"coast":
			return _grass_tile(rng)
		_:
			return _grass_tile(rng)


static func _grass_tile(rng: RandomNumberGenerator) -> String:
	var value := rng.randf()
	if value < 0.62:
		return TILE_PASTIZAL
	if value < 0.82:
		return TILE_PRADERA
	if value < 0.93:
		return TILE_PASTIZAL_ARBUSTOS
	return TILE_COLINA


static func _place_river(tiles: Array[String], axis: String, has_city: bool, rng: RandomNumberGenerator) -> void:
	if axis == "vertical":
		var river_col := 4
		for row in range(ROWS):
			tiles[row * COLS + river_col] = TILE_RIO
		# Dos cruces, uno de ellos villa si el asentamiento está sitiado.
		var bridge_rows: Array[int] = [1]
		var second_row := 0 if rng.randf() < 0.5 else 2
		if second_row != 1:
			bridge_rows.append(second_row)
		for bridge_index in range(bridge_rows.size()):
			var row := bridge_rows[bridge_index]
			var key := TILE_PUENTE_VILLA if (has_city and bridge_index == 0) else TILE_PUENTE
			tiles[row * COLS + river_col] = key
		# El camino de despliegue cruza por el puente principal (fila 1).
	else:
		var river_row := 1
		for col in range(COLS):
			tiles[river_row * COLS + col] = TILE_RIO
		var bridge_cols: Array[int] = [2, 5]
		for bridge_index in range(bridge_cols.size()):
			var col := bridge_cols[bridge_index]
			var key := TILE_PUENTE_VILLA if (has_city and bridge_index == 0) else TILE_PUENTE
			tiles[river_row * COLS + col] = key


static func _place_mountain_band(tiles: Array[String], rng: RandomNumberGenerator) -> void:
	# Franja de montaña intransitable, con un paso libre para que el campo tenga
	# dos zonas de despliegue conectadas.
	var band_col := 5
	for row in range(ROWS):
		if row != 1:
			tiles[row * COLS + band_col] = TILE_MONTANA
	for i in range(2):
		var col := rng.randi_range(1, COLS - 2)
		var row := rng.randi_range(0, ROWS - 1)
		if col != band_col:
			tiles[row * COLS + col] = TILE_MONTANA


static func _scatter_forest(tiles: Array[String], rng: RandomNumberGenerator) -> void:
	for i in range(3):
		var col := rng.randi_range(0, COLS - 1)
		var row := rng.randi_range(0, ROWS - 1)
		tiles[row * COLS + col] = TILE_BOSQUE


static func _place_village(tiles: Array[String], river_axis: String, rng: RandomNumberGenerator) -> void:
	var villa_cell := Vector2i(COLS - 2, 1)
	if river_axis == "vertical":
		villa_cell = Vector2i(5, 0 if rng.randf() < 0.5 else 2)
	elif river_axis == "horizontal":
		villa_cell = Vector2i(COLS - 2, 0)
	if get_cell(tiles, villa_cell) == TILE_RIO or get_cell(tiles, villa_cell) == TILE_MONTANA:
		villa_cell = Vector2i(COLS - 1, 1)
	set_cell(tiles, villa_cell, TILE_VILLA)
	var street := Vector2i(villa_cell.x - 1, villa_cell.y)
	var street_key := get_cell(tiles, street)
	if is_passable_key(street_key) and street_key != TILE_PUENTE and street_key != TILE_PUENTE_VILLA:
		set_cell(tiles, street, TILE_VILLA_CALLE)


static func _place_roads(tiles: Array[String], river_axis: String) -> void:
	var road_row := 1
	if river_axis == "horizontal":
		road_row = 0
	for col in range(COLS):
		var cell := Vector2i(col, road_row)
		var key := get_cell(tiles, cell)
		if is_passable_key(key) and key != TILE_VILLA and key != TILE_VILLA_CALLE and key != TILE_PUENTE and key != TILE_PUENTE_VILLA:
			set_cell(tiles, cell, TILE_CAMINO)
	# Acceso vertical desde el camino hasta la villa/puente.
	if not _has_key(tiles, TILE_VILLA):
		return
	for row in range(ROWS):
		for col in range(COLS):
			if get_cell(tiles, Vector2i(col, row)) == TILE_VILLA:
				if row > 0 and is_passable_key(get_cell(tiles, Vector2i(col, row - 1))):
					set_cell(tiles, Vector2i(col, row - 1), TILE_CAMINO)
				return


static func _first_passable(tiles: Array[String], preferred_col: int, preferred_row: int) -> Vector2i:
	for attempt in range(ROWS):
		var row := (preferred_row + attempt) % ROWS
		if is_passable_key(get_cell(tiles, Vector2i(preferred_col, row))):
			return Vector2i(preferred_col, row)
	for row in range(ROWS):
		for col in range(COLS):
			if is_passable_key(get_cell(tiles, Vector2i(col, row))):
				return Vector2i(col, row)
	return Vector2i(-1, -1)


static func _has_key(tiles: Array[String], key: String) -> bool:
	for tile in tiles:
		if tile == key:
			return true
	return false


static func get_cell(tiles: Array[String], cell: Vector2i) -> String:
	var index := cell.y * COLS + cell.x
	if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
		return ""
	return tiles[index]


static func set_cell(tiles: Array[String], cell: Vector2i, key: String) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
		return
	tiles[cell.y * COLS + cell.x] = key


static func is_passable_key(key: String) -> bool:
	return key != "" and key != TILE_RIO and key != TILE_MONTANA
