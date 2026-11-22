extends SceneTree
## Capturas de pantalla Fase 2 (AG-3): mapa por capas, retratos (§10.2),
## tactico N2, combate cerrado N3 y flujo real de juego. Herramienta de
## desarrollo; las copias finales las versiona AG-0 en docs/screenshots.
##
## Uso (requiere render, sin --headless):
##   godot --path <repo> --script scripts/ui/dev/ui_screenshots.gd

const OUT_DIR := "C:/Proyectos/TSB/.ui_check_f2"
const Palette = preload("res://scripts/ui/theme/tsb_palette.gd")
const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ThemeBuilder = preload("res://scripts/ui/theme/tsb_theme.gd")
const TSBGame = preload("res://scripts/ui/tsb_game.gd")
const PortraitFrame = preload("res://scripts/ui/widgets/portrait_frame.gd")

var _shots: Array[String] = []


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await process_frame
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await process_frame

	change_scene_to_file("res://scenes/main/main_menu.tscn")
	await _settle(8)
	await _capture("f2_01_main_menu")
	if current_scene != null:
		current_scene.call("_on_new_game")
	await _settle(8)
	await _capture("f2_02_scenario_select")
	if current_scene != null:
		current_scene.call("_on_start")
	await _settle(14)
	var world := current_scene
	await _capture("f2_03_world_map_1337")

	if world != null:
		# Mapa limpio (sin HUD) para la comparativa con el atlas de referencia.
		var hud_layer: Variant = world.get("_hud_layer")
		if hud_layer is CanvasLayer:
			(hud_layer as CanvasLayer).visible = false
			await _settle(2)
			await _capture("f2_03b_map_clean")
			(hud_layer as CanvasLayer).visible = true
			await _settle(2)

	if world != null:
		# Tooltip e interaccion.
		world.call("_set_hover_region", "region_londres")
		var tooltip: Variant = world.get("_tooltip")
		if tooltip != null:
			tooltip.call("show_text", world.call("_region_tooltip_bbcode", "region_londres"))
			tooltip.call("follow", Vector2(760, 420))
		await _settle(2)
		await _capture("f2_04_tooltip")
		if tooltip != null:
			tooltip.call("hide_tip")

		# Niveles de zoom: pais (<0.9), region (0.9-1.5), detalle (>1.5).
		world.call("_set_zoom", 1.25)
		await _settle(2)
		await _capture("f2_04b_zoom_region")
		world.call("_set_zoom", 2.0)
		await _settle(2)
		await _capture("f2_04c_zoom_detail")
		world.call("_set_zoom", 0.7)
		await _settle(2)

		# Vistas politicas 1402 / 1453 (solo capa politica).
		world.call("_set_view_year", 1402)
		await _settle(3)
		await _capture("f2_05_view_1402")
		world.call("_set_view_year", 1453)
		await _settle(3)
		await _capture("f2_06_view_1453")
		world.call("_set_view_year", 1337)
		await _settle(2)

		# Panel de region.
		world.call("_on_region_clicked", "region_londres")
		await _settle(3)
		await _capture("f2_07_region_panel")
		world.call("_on_region_panel_closed")

		# Retratos §10.2 en los 5 slots.
		await _overlay(world, "res://scenes/ui/court_overview.tscn", "court", null, "f2_08_court_portrait")
		await _overlay(world, "res://scenes/family/family_tree.tscn", "family", null, "f2_09_family_portraits")
		await _overlay(world, "res://scenes/diplomacy/diplomacy_screen.tscn", "diplomacy", null, "f2_10_diplomacy_portrait")
		await _overlay(world, "res://scenes/battle/battle_report.tscn", "battle", {
			"attacker_faction": "england",
			"defender_faction": "france",
			"region_id": "region_normandia",
			"winner_faction": "england",
			"attacker_losses": 420,
			"defender_losses": 1150,
			"rounds": [
				{"round": 1, "attacker_damage": 60, "defender_damage": 210},
				{"round": 2, "attacker_damage": 95, "defender_damage": 320},
				{"round": 3, "attacker_damage": 130, "defender_damage": 410},
			],
			"region_captured": true,
			"loot_gold": 1200,
			"prisoners": 34,
			"notes": "Los arqueros largos rompen la linea francesa al tercer asalto.",
		}, "f2_11_battle_report_portraits")

		# Contact sheet de retratos (fallback heraldico, nunca vacio).
		await _portrait_sheet()

		# Tactico Nivel 2 y combate cerrado Nivel 3 con una batalla real.
		var battle_context := _find_battle_context()
		if not battle_context.is_empty():
			world.call("_open_tactical_battle", str(battle_context.get("attacker", "")), str(battle_context.get("defender", "")), str(battle_context.get("region", "")))
			await _settle(4)
			await _capture("f2_12_battle_level_choice")
			var tactical: Variant = world.get("_overlay")
			if tactical != null and is_instance_valid(tactical) and tactical.has_method("_begin_level2"):
				tactical.call("_begin_level2")
				await _settle(6)
				await _capture("f2_13_tactical_n2")
				if tactical.has_method("_abandon"):
					tactical.call("_abandon")
				await _settle(3)
			# Combate cerrado independiente.
			var close_scene: Node = load("res://scenes/battle/close_combat.tscn").instantiate()
			root.add_child(close_scene)
			var attacker_unit := TSBGame.first_unit_of_army(str(battle_context.get("attacker", "")))
			var defender_unit := TSBGame.first_unit_of_army(str(battle_context.get("defender", "")))
			if attacker_unit.is_empty():
				attacker_unit = {"id": "demo_1", "faction": "england", "unit_id": "longbowman", "size": 800, "strength": 9, "morale": 1.0, "experience": 0}
			if defender_unit.is_empty():
				defender_unit = {"id": "demo_2", "faction": "france", "unit_id": "men_at_arms", "size": 600, "strength": 12, "morale": 1.0, "experience": 0}
			close_scene.call("setup", attacker_unit, defender_unit)
			await _settle(4)
			await _capture("f2_14_close_combat")
			if close_scene.has_method("_play_card"):
				var controller: Variant = close_scene.get("_cc")
				if controller != null:
					var state: Dictionary = controller.call("get_state")
					var attacker_hand: Array = (state.get("hands", {}) as Dictionary).get("attacker", [])
					if not attacker_hand.is_empty():
						close_scene.call("_play_card", str(attacker_hand[0]))
						await _settle(3)
						await _capture("f2_15_close_combat_round")
			if is_instance_valid(close_scene):
				close_scene.queue_free()
			await _settle(3)

		# N3 en contexto de campaña (D-033): aplica resultado y abre informe.
		if not battle_context.is_empty():
			world.call("_open_tactical_battle", str(battle_context.get("attacker", "")), str(battle_context.get("defender", "")), str(battle_context.get("region", "")))
			await _settle(3)
			var tactical_campaign: Variant = world.get("_overlay")
			if tactical_campaign != null:
				tactical_campaign.call("_begin_level3")
				await _settle(3)
				var campaign_close: Node = tactical_campaign.get_child(tactical_campaign.get_child_count() - 1)
				var campaign_cc: Variant = campaign_close.get("_cc") if campaign_close != null else null
				if campaign_cc != null:
					campaign_cc.call("auto_resolve")
					campaign_close.call("_rebuild")
					await _settle(3)
					await _capture("f2_15b_close_combat_campaign_applied")
					campaign_close.call("_close")
					await _settle(3)
					var report_overlay: Variant = world.get("_overlay")
					if report_overlay is Node and is_instance_valid(report_overlay):
						await _capture("f2_15c_n3_battle_report")
						(report_overlay as Node).call("close_overlay")
						await _settle(3)
			var leftover: Variant = world.get("_overlay")
			if leftover is Node and is_instance_valid(leftover):
				(leftover as Node).call("close_overlay")
				await _settle(2)

		# Terminar turno real (IA + resoluciones + informe si aplica).
		world.call("_on_end_turn_requested")
		await create_timer(3.0).timeout
		await _settle(6)
		await _capture("f2_16_after_end_turn")
		var live_overlay: Variant = world.get("_overlay")
		if live_overlay is Node and is_instance_valid(live_overlay):
			await _capture("f2_17_live_" + str(world.get("_overlay_kind")))
			(live_overlay as Node).call("close_overlay")
			await _settle(3)
			await _capture("f2_18_after_overlay")

	print("CAPTURAS F2: %d imagenes en %s" % [_shots.size(), OUT_DIR])
	quit(0)


func _find_battle_context() -> Dictionary:
	var player := TSBGame.player_faction()
	for army: Variant in TSBGame.armies().values():
		if not (army is Dictionary):
			continue
		if str((army as Dictionary).get("faction_id", "")) != player:
			continue
		var from_region := str((army as Dictionary).get("region_id", ""))
		for adjacent: Variant in TSBGame.region_adjacency(from_region):
			var target := str(adjacent)
			var defender := TSBGame.defender_army_in(target, player)
			if not defender.is_empty():
				return {
					"attacker": str((army as Dictionary).get("id", "")),
					"defender": str(defender.get("id", "")),
					"region": target,
				}
	return {}


func _portrait_sheet() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	root.add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.04, 0.05, 0.08, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.theme = ThemeBuilder.get_theme()
	panel.custom_minimum_size = Vector2(1500, 900)
	center.add_child(panel)
	var margin := UIKit.margin(panel, 20, 18, 20, 16)
	var column := UIKit.vbox(margin, 10)
	var title := UIKit.label(column, "RETRATOS §10.2 · FALLBACK HERÁLDICO + SILUETA", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var grid := UIKit.grid(column, 6, 12, 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var count := 0
	for character: Variant in TSBGame.all_characters():
		if not (character is Dictionary):
			continue
		if not TSBGame.character_is_alive(character):
			continue
		if TSBGame.character_age(character) < 14:
			continue
		var data := character as Dictionary
		var box := UIKit.vbox(grid, 3)
		var portrait: Control = PortraitFrame.make(str(data.get("id", "")), Vector2(140, 168))
		if portrait != null:
			box.add_child(portrait)
		var name_label := UIKit.label(box, str(data.get("name", "")), "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Palette.INK_TEXT)
		var role_label := UIKit.label(box, "%s · %d años" % [str(data.get("role", "")), TSBGame.character_age(data)], "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
		role_label.add_theme_font_size_override("font_size", 11)
		role_label.add_theme_color_override("font_color", Palette.MUTED)
		count += 1
		if count >= 18:
			break
	var footer := UIKit.label(column, "Los 5 slots (mapa, árbol, diplomacia, batalla, corte) usan este mismo widget; el asset PNG sustituye el fallback en Fase 3.", "InkLabel", HORIZONTAL_ALIGNMENT_CENTER)
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Palette.MUTED)
	await _settle(4)
	await _capture("f2_11b_portraits_contact_sheet")
	layer.queue_free()
	await _settle(2)


func _overlay(world: Node, scene_path: String, kind: String, setup_arg: Variant, capture_name: String) -> void:
	world.call("_open_overlay", scene_path, kind, setup_arg)
	await _settle(3)
	await _capture(capture_name)
	var overlay: Variant = world.get("_overlay")
	if overlay is Node and is_instance_valid(overlay):
		(overlay as Node).call("close_overlay")
	await _settle(3)


func _settle(frames: int) -> void:
	for i in range(frames):
		await process_frame


func _capture(capture_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null:
		print("  [WARN] sin imagen para ", capture_name)
		return
	image.save_png(OUT_DIR.path_join(capture_name + ".png"))
	_shots.append(capture_name)
	print("  [OK] ", capture_name, " ", image.get_size())
