extends SceneTree
## Smoke test de UI (AG-3): compila todos los scripts de scripts/ui/** y
## instancia todas las escenas de res://scenes/** en headless.
##
## Uso:
##   godot --headless --path <repo> --script scripts/ui/dev/ui_smoke.gd
## Exit code 0 = todo compila/instancia; 1 = algun fallo.

var _failures: Array[String] = []
var _scenes_checked := 0
var _scripts_checked := 0


func _initialize() -> void:
	await process_frame
	print("==============================================================")
	print(" The Sovereign's Blood - UI smoke test (headless)")
	print("==============================================================")
	print("-- Scripts (scripts/ui/**) --")
	var scripts := _collect_files("res://scripts/ui", ".gd")
	scripts.sort()
	for path: String in scripts:
		if path.ends_with("dev/ui_smoke.gd"):
			continue
		_scripts_checked += 1
		var resource: Variant = load(path)
		if resource is GDScript and (resource as GDScript).can_instantiate():
			print("  [OK] %s" % path)
		else:
			_failures.append("script no compila: %s" % path)

	print("-- Escenas (res://scenes/**) --")
	var scenes := _collect_files("res://scenes", ".tscn")
	scenes.sort()
	for path: String in scenes:
		await _check_scene(path)

	print("--------------------------------------------------------------")
	print("Comprobados: %d script(s), %d escena(s)" % [_scripts_checked, _scenes_checked])
	if _failures.is_empty():
		print("UI SMOKE: OK - sin errores")
		quit(0)
	else:
		print("UI SMOKE: FAIL - %d fallo(s)" % _failures.size())
		for failure: String in _failures:
			print("  - " + failure)
		quit(1)


func _collect_files(root_path: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := root_path.path_join(name)
		if dir.current_is_dir():
			found.append_array(_collect_files(full, extension))
		elif name.ends_with(extension):
			found.append(full)
		name = dir.get_next()
	dir.list_dir_end()
	return found


func _check_scene(path: String) -> void:
	_scenes_checked += 1
	var resource: Variant = load(path)
	if not (resource is PackedScene):
		_failures.append("%s: no carga como PackedScene" % path)
		return
	var node: Node = (resource as PackedScene).instantiate()
	if node == null:
		_failures.append("%s: instantiate() devolvio null" % path)
		return
	root.add_child(node)
	await process_frame
	await process_frame
	if not is_instance_valid(node):
		_failures.append("%s: el nodo raiz dejo de ser valido" % path)
		return
	_validate_scene(path, node)
	node.queue_free()
	await process_frame
	print("  [OK] %s" % path)


func _validate_scene(path: String, node: Node) -> void:
	var button_count := node.find_children("*", "Button", true, false).size()
	var label_count := node.find_children("*", "Label", true, false).size()
	if path.ends_with("main_menu.tscn") and button_count < 4:
		_failures.append("%s: se esperaban >=4 botones, hay %d" % [path, button_count])
	if path.ends_with("scenario_select.tscn"):
		if button_count < 9:
			_failures.append("%s: se esperaban >=9 botones de faccion, hay %d" % [path, button_count])
		if label_count < 15:
			_failures.append("%s: detalle de faccion sin construir (labels=%d)" % [path, label_count])
		node.call("_select_faction", "france")
	if path.ends_with("options_menu.tscn") and button_count < 1:
		_failures.append("%s: sin botones de opciones" % path)
	if path.ends_with("world_map.tscn"):
		var region_nodes: Variant = node.get("_region_nodes")
		if not (region_nodes is Dictionary) or (region_nodes as Dictionary).size() < 47:
			_failures.append("%s: se esperaban 47 nodos de region, hay %s" % [path, "no dict" if not (region_nodes is Dictionary) else str((region_nodes as Dictionary).size())])
		else:
			node.call("_on_region_clicked", "region_londres")
			var region_panel: Variant = node.get("_region_panel")
			if region_panel is Control and not (region_panel as Control).visible:
				_failures.append("%s: el panel de region no se abrio" % path)
			node.call("_on_region_panel_closed")
		if node.find_children("*", "VBoxContainer", true, false).size() < 1:
			_failures.append("%s: sin contenedores construidos" % path)
	if path.ends_with("battle_report.tscn"):
		node.call("setup", {
			"attacker_faction": "england",
			"defender_faction": "france",
			"region_id": "region_normandia",
			"winner_faction": "england",
			"attacker_losses": 120,
			"defender_losses": 300,
			"rounds": [{"round": 1, "attacker_damage": 40, "defender_damage": 90}],
			"region_captured": true,
			"notes": "Prueba de humo.",
		})
	if path.ends_with("year_end_report.tscn"):
		node.call("setup", 1338)
	if path.ends_with("victory_screen.tscn"):
		node.call("setup", {"faction_id": "england", "victory": true, "reason": "Prueba de humo"})
	if path.ends_with("family_tree.tscn"):
		node.call("setup", "england")
		node.call("_on_character_selected", "eduardo_el_principe_negro")
		if node.find_children("*", "OptionButton", true, false).is_empty():
			_failures.append("%s: sin acciones de matrimonio" % path)
	if path.ends_with("diplomacy_screen.tscn"):
		node.call("_select_target", "papacy")
		if node.find_children("*", "OptionButton", true, false).is_empty():
			_failures.append("%s: sin selectores de matrimonio" % path)
	if path.ends_with("military_screen.tscn") or path.ends_with("economy_screen.tscn") or path.ends_with("court_overview.tscn"):
		node.call("refresh")
	if path.ends_with("region_panel.tscn"):
		node.call("open", "region_londres")
		node.call("refresh")
		if node.find_children("*", "Label", true, false).size() < 8:
			_failures.append("%s: panel de region sin contenido" % path)

