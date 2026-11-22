extends SceneTree
## Capturas Fase 4 (AG-3): Mercado y Gestión de ejércitos, 1920×1080.
## Requiere render; usa una partida real 1337 y APIs de AG-2.

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f3"
const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _shots := 0
var _world: Node = null


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame
	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _frames(6)
	if current_scene != null:
		current_scene.call("_on_new_game")
	await _frames(6)
	if current_scene != null:
		current_scene.call("_on_start")
	await _frames(12)
	_world = current_scene
	if _world == null:
		print("[WARN] sin mapa")
		_finish()
		return
	# Asigna comerciantes para que el mercado esté operativo en la captura.
	var fid := TSBGame.player_faction()
	var available := TSBGame.trade_available_merchants(fid)
	if available > 0:
		TSBGame.set_trade_merchants(fid, mini(available, 12))
	await _frames(2)
	await _overlay_capture("market_screen", "res://scenes/economy/market_screen.tscn", "market")
	# Variante de estado sin comerciantes: controles visibles pero deshabilitados.
	if available > 0:
		TSBGame.set_trade_merchants(fid, 0)
		await _frames(2)
		await _overlay_capture("market_no_merchants", "res://scenes/economy/market_screen.tscn", "market")
		TSBGame.set_trade_merchants(fid, mini(available, 12))
		await _frames(2)
	# Añade artillería para que la captura de costes muestre también un 4º tipo.
	var owned_regions := TSBGame.regions_owned_by(fid)
	if not owned_regions.is_empty():
		TSBGame.recruit(fid, str(owned_regions[0]), "bombarda", 40)
		await _frames(2)
	await _overlay_capture("army_management", "res://scenes/military/army_management.tscn", "army")
	# Captura específica de costes visibles (misma pantalla, nombre pedido).
	_copy_capture("army_management", "army_costs")
	# Acción diplomática ya usada: el botón debe aparecer deshabilitado.
	_world.call("_open_overlay", "res://scenes/diplomacy/diplomacy_screen.tscn", "diplomacy", null)
	await _frames(5)
	var diplomacy: Variant = _world.get("_overlay")
	if diplomacy is Node:
		var target := str(diplomacy.get("_target_id"))
		if not target.is_empty():
			TSBGame.mark_action_used("diplomacy:trade_pact:%s" % target)
			if diplomacy.has_method("refresh"):
				diplomacy.call("refresh")
			await _frames(3)
	await _capture("action_used_diplomacy")
	if diplomacy is Node and is_instance_valid(diplomacy):
		(diplomacy as Node).call("close_overlay")
	await _frames(2)
	_finish()


func _copy_capture(source_name: String, target_name: String) -> void:
	var source := OUT_DIR.path_join(source_name + ".png")
	if not FileAccess.file_exists(source):
		return
	var image := Image.load_from_file(source)
	if image != null:
		image.save_png(OUT_DIR.path_join(target_name + ".png"))
		print("  [OK] ", target_name, " (copia de ", source_name, ")")


func _overlay_capture(file_name: String, scene_path: String, kind: String) -> void:
	_world.call("_open_overlay", scene_path, kind, null)
	await _frames(6)
	await _capture(file_name)
	var overlay: Variant = _world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _frames(3)


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("[WARN] sin imagen ", file_name)
		return
	image.save_png(OUT_DIR.path_join(file_name + ".png"))
	_shots += 1
	print("  [OK] ", file_name, " ", image.get_size())


func _finish() -> void:
	print("CAPTURAS FASE 4: %d en %s" % [_shots, OUT_DIR])
	TSBGame.reset_game()
	quit(0)
