extends SceneTree
## Sonda de integracion AG-2/AG-3 (headless): arranca partida, ejecuta acciones
## de la API desde la UI, avanza un ano completo y prueba save/load.
## Solo desarrollo; no forma parte del juego.

func _initialize() -> void:
	await process_frame
	var TSBGame: GDScript = load("res://scripts/ui/tsb_game.gd")
	print("== nueva partida ==")
	var started: bool = TSBGame.start_new_game("england", 1337)
	print("start_new_game -> ", started, " has_game=", TSBGame.has_game(), " year=", TSBGame.current_year(), " q=", TSBGame.current_quarter())
	print("gold=", TSBGame.gold("england"), " pg=", TSBGame.pg_remaining(), "/", TSBGame.pg_max(), " prestige=", TSBGame.prestige("england"))
	print("regions_owned=", TSBGame.regions_owned_by("england").size(), " armies=", TSBGame.armies().size())

	var world: Node = load("res://scenes/map/world_map.tscn").instantiate()
	root.add_child(world)
	await _frames(3)
	print("world nodes=", (world.get("_region_nodes") as Dictionary).size())

	# Panel de region + accion de mano de obra via UI.
	world.call("_on_region_clicked", "region_londres")
	await _frames(2)
	var panel: Node = world.get("_region_panel")
	var before_workers: Variant = TSBGame.region("region_londres").get("workers", {})
	print("workers antes=", before_workers, " pg=", TSBGame.pg_remaining())
	panel.call("_allocate", "farmers", 25)
	await _frames(2)
	var after_workers: Variant = TSBGame.region("region_londres").get("workers", {})
	print("workers despues=", after_workers, " pg=", TSBGame.pg_remaining())
	panel.call("_allocate", "artisans", 25)
	await _frames(1)
	print("workers final=", TSBGame.region("region_londres").get("workers", {}), " pg=", TSBGame.pg_remaining())

	# Reclutamiento via API (el panel usa la misma llamada).
	var unit_list: Array = TSBGame.units_for_faction("england")
	var unit_id := str((unit_list[0] as Dictionary).get("id", "")) if not unit_list.is_empty() else ""
	var recruit_ok: bool = TSBGame.recruit("england", "region_londres", unit_id, 200)
	print("recruit(", unit_id, ",200) -> ", recruit_ok)
	world.call("_refresh_all")
	await _frames(1)

	# Movimiento de ejercito.
	var moved := false
	for army: Variant in TSBGame.armies().values():
		if moved or not (army is Dictionary):
			continue
		if str((army as Dictionary).get("faction_id", "")) != "england":
			continue
		var from_region := str((army as Dictionary).get("region_id", ""))
		var adjacent: Array = TSBGame.region_adjacency(from_region)
		if adjacent.is_empty():
			continue
		var army_id := str((army as Dictionary).get("id", ""))
		print("mover ", army_id, " ", TSBGame.region_name(from_region), " -> ", TSBGame.region_name(str(adjacent[0])), " coste=", TSBGame.move_cost(army_id, str(adjacent[0])))
		print("move_army -> ", TSBGame.move_army(army_id, str(adjacent[0])))
		moved = true
	world.call("_refresh_all")

	# Diplomacia via API.
	var proposal: Dictionary = TSBGame.propose("england", "france", {"type": "trade_pact"})
	print("propose trade_pact france -> ", proposal)
	print("relacion inglaterra-francia=", TSBGame.relation("england", "france"), " guerra=", TSBGame.are_at_war("england", "france"))

	# Paneles con estado real (instanciacion/refresh).
	for scene_info: Array in [
		["res://scenes/ui/court_overview.tscn", "court"],
		["res://scenes/family/family_tree.tscn", "family"],
		["res://scenes/diplomacy/diplomacy_screen.tscn", "diplomacy"],
		["res://scenes/military/military_screen.tscn", "military"],
		["res://scenes/economy/economy_screen.tscn", "economy"],
	]:
		world.call("_open_overlay", str(scene_info[0]), str(scene_info[1]), null)
		await _frames(2)
		print("overlay ", scene_info[1], " abierto=", world.get("_overlay_kind"))
		var overlay: Variant = world.get("_overlay")
		if overlay is Node and is_instance_valid(overlay):
			(overlay as Node).call("close_overlay")
		await _frames(2)

	# Pantalla de victoria/derrota (senal EventBus.game_over).
	world.call("_on_game_over_bus", "england", true, "Victoria de prueba de la UI")
	await _frames(2)
	print("overlay game_over=", world.get("_overlay_kind"))
	var victory_overlay: Variant = world.get("_overlay")
	if victory_overlay is Node and is_instance_valid(victory_overlay):
		(victory_overlay as Node).call("close_overlay")
	await _frames(2)

	# Menu de pausa/opciones en partida (Guardar / Cargar / Menu).
	world.call("_open_options")
	await _frames(2)
	var options_overlay: Variant = world.get("_overlay")
	var options_buttons := -1
	if options_overlay is Node:
		options_buttons = (options_overlay as Node).find_children("*", "Button", true, false).size()
	print("overlay options=", world.get("_overlay_kind"), " botones=", options_buttons)
	if options_overlay is Node and is_instance_valid(options_overlay):
		(options_overlay as Node).call("_on_save")
		await _frames(1)
		print("save desde opciones -> has_save autosave=", TSBGame.has_save("autosave"))
		(options_overlay as Node).call("close_overlay")
		await _frames(2)

	# Guardado/carga via API (boton Guardar / Cargar del menu de opciones).
	var saved: bool = TSBGame.save_game("uitest")
	print("save uitest -> ", saved, " has_save=", TSBGame.has_save("uitest"))
	var year_before: int = TSBGame.current_year()
	var quarter_before: int = TSBGame.current_quarter()
	var loaded: bool = TSBGame.load_game("uitest")
	print("load uitest -> ", loaded, " year=", TSBGame.current_year(), " (antes ", year_before, ") q=", TSBGame.current_quarter(), " (antes ", quarter_before, ")")

	# Ano completo: 4 trimestres (fin de ano -> evento + autosave).
	for i in range(8):
		print("-- end_turn ", i + 1, " --")
		world.call("_on_end_turn_requested")
		await create_timer(0.2).timeout
		await _frames(3)
		print("year=", TSBGame.current_year(), " q=", TSBGame.current_quarter(), " overlay=", world.get("_overlay_kind"), " battles=", TSBGame.battle_reports().size())
		var overlay2: Variant = world.get("_overlay")
		if overlay2 is Node and is_instance_valid(overlay2):
			print("   cerrando overlay: ", world.get("_overlay_kind"))
			(overlay2 as Node).call("close_overlay")
			await _frames(2)
		if TSBGame.current_year() >= 1338 and TSBGame.current_quarter() >= 2:
			break
	print("event_log=", TSBGame.event_log().size())
	var last_report: Dictionary = TSBGame.last_battle_report()
	print("ultimo informe keys=", last_report.keys(), " region=", last_report.get("region_id", ""), " winner=", last_report.get("winner_faction", ""))

	print("== autoguardado de fin de ano ==")
	print("has_save autosave=", TSBGame.has_save("autosave"))
	TSBGame.reset_game()
	print("tras reset has_game=", TSBGame.has_game(), " year=", TSBGame.current_year())
	var autosave_ok: bool = TSBGame.load_game("autosave")
	print("load autosave -> ", autosave_ok, " has_game=", TSBGame.has_game(), " year=", TSBGame.current_year(), " q=", TSBGame.current_quarter(), " gold=", TSBGame.gold("england"), " pg=", TSBGame.pg_remaining())

	world.queue_free()
	await _frames(2)
	quit(0)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
