extends SceneTree
## Verificacion headless de tiles N3 §10.4 (AG-3): 12 assets, generador
## determinista, río continuo con puentes/villa y campo de llanura.

const BattlefieldGenerator = preload("res://scripts/ui/battle/battlefield_generator.gd")

const TILE_KEYS: Array[String] = [
	"pastizal", "pastizal_arbustos", "pradera", "rio", "puente", "puente_villa",
	"colina", "bosque", "montana", "villa", "villa_calle", "camino",
]

var _failures: Array[String] = []


func _initialize() -> void:
	await process_frame
	var loaded := 0
	for key: String in TILE_KEYS:
		var path := "res://assets/art/battle/tiles/tile_%s.png" % key
		if not FileAccess.file_exists(path):
			_check(false, "tile existe %s" % key)
			continue
		var resource: Variant = load(path)
		if not (resource is Texture2D):
			_check(false, "tile carga %s" % key)
			continue
		var texture := resource as Texture2D
		if texture.get_size() != Vector2(512, 512):
			_check(false, "tile 512×512 %s (%s)" % [key, str(texture.get_size())])
			continue
		loaded += 1
	_check(loaded == 12, "12/12 tiles 512×512 cargan (hay %d)" % loaded)
	_check(FileAccess.file_exists("res://assets/art/battle/tiles/src/.gdignore"), "src/.gdignore existe")
	for key: String in TILE_KEYS:
		_check(FileAccess.file_exists("res://assets/art/battle/tiles/src/tile_%s.png" % key), "raw existe %s" % key)

	var river := BattlefieldGenerator.generate("coast", true, 1337, "region_flandes")
	_check(int(river.get("cols", 0)) == 8 and int(river.get("rows", 0)) == 3, "rejilla 8×3")
	_check(str(river.get("axis", "")) == "vertical", "costa genera río vertical")
	var tiles: Array = river.get("tiles", [])
	_check(tiles.size() == 24, "24 casillas")
	var river_col := 4
	var water_cells := 0
	for row in range(3):
		var key := str(tiles[row * 8 + river_col])
		if key == "rio" or key == "puente" or key == "puente_villa":
			water_cells += 1
	_check(water_cells == 3, "río continuo de orilla a orilla (3/3)")
	var bridges: Array = river.get("bridges", [])
	_check(bridges.size() >= 1 and bridges.size() <= 2, "1-2 puentes (%d)" % bridges.size())
	_check(str(river.get("villa", Vector2i(-1, -1))) != str(Vector2i(-1, -1)), "villa en el asentamiento")
	_check(BattlefieldGenerator.needs_vertical_rotation(river, river_col, 0), "rotación vertical de rio")
	_check(BattlefieldGenerator.needs_vertical_rotation(river, river_col, 1), "rotación vertical de puente")
	var repeated := BattlefieldGenerator.generate("coast", true, 1337, "region_flandes")
	_check(str(river.get("tiles", [])) == str(repeated.get("tiles", [])), "generador determinista")
	var roads := 0
	for key_value: Variant in tiles:
		if str(key_value) == "camino" or str(key_value) == "villa_calle":
			roads += 1
	_check(roads > 0, "caminos de despliegue presentes")

	var forest := BattlefieldGenerator.generate("forest", false, 99, "region_inglaterra_norte")
	var forest_count := 0
	for key_value: Variant in (forest.get("tiles", []) as Array):
		if str(key_value) == "bosque":
			forest_count += 1
	_check(forest_count > 0, "bosque deriva de terrain=forest")
	var mountain := BattlefieldGenerator.generate("mountain", false, 99, "region_baviera")
	var mountain_count := 0
	for key_value: Variant in (mountain.get("tiles", []) as Array):
		if str(key_value) == "montana":
			mountain_count += 1
	_check(mountain_count > 0, "montaña deriva de terrain=mountain")

	var plain := BattlefieldGenerator.generate("plains", true, 77, "region_normandia")
	var plain_tiles: Array = plain.get("tiles", [])
	var plain_water := 0
	for key_value: Variant in plain_tiles:
		if str(key_value) == "rio" or str(key_value) == "puente" or str(key_value) == "puente_villa":
			plain_water += 1
	_check(plain_water == 0, "llanura sin río")
	_check(str(plain.get("villa", Vector2i(-1, -1))) != str(Vector2i(-1, -1)), "llanura con villa si hay asentamiento")
	_check(FileAccess.file_exists("C:/Proyectos/TSB/.ui_check_f3/tiles_contact_sheet.png"), "hoja de contacto de tiles")

	print("--------------------------------------------------------------")
	if _failures.is_empty():
		print("TILES PROBE: OK")
		quit(0)
	else:
		print("TILES PROBE: FAIL (%d)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  [OK] " + label)
	else:
		_failures.append(label)
		print("  [FAIL] " + label)
