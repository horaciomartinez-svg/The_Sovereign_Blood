extends "res://scripts/ui/widgets/overlay_base.gd"
## D-085: Guardar/Cargar con autoguardado + 3 ranuras manuales.
## La UI solo usa GameState vía TSBGame; no toca archivos directamente.

signal loaded(slot: String)

const TSBGame = preload("res://scripts/ui/tsb_game.gd")

var _body: VBoxContainer = null
var _status: Label = null
var _confirm: ConfirmationDialog = null
var _pending_slot := ""


func _build_content() -> void:
	dialog.custom_minimum_size = Vector2(1080, 720)
	add_title("GUARDAR / CARGAR", "Autoguardado tras cada turno resuelto y tres ranuras manuales")
	_body = add_body_scroll()
	var footer := add_footer("CERRAR")
	_status = UIKit.label(content, "", "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Palette.CRIMSON)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Confirmar sobrescritura"
	_confirm.confirmed.connect(_on_overwrite_confirmed)
	add_child(_confirm)
	_rebuild()


func _rebuild() -> void:
	if _body == null:
		return
	UIKit.clear(_body)
	var entries: Dictionary = {}
	for raw: Variant in TSBGame.list_saves():
		if raw is Dictionary:
			entries[str((raw as Dictionary).get("slot", ""))] = raw
	var slots: Array[String] = ["autosave", "slot_1", "slot_2", "slot_3"]
	for slot in slots:
		var entry: Dictionary = entries.get(slot, {})
		_build_slot_row(slot, entry)


func _build_slot_row(slot: String, entry: Dictionary) -> void:
	var exists := bool(entry.get("exists", TSBGame.has_save(slot)))
	var is_auto := slot == "autosave"
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palette.stylebox(
		Palette.with_alpha(Palette.GOLD_DIM, 0.14 if exists else 0.05),
		Palette.with_alpha(Palette.GOLD_DIM, 0.6), 1, 5, 10, 8))
	_body.add_child(panel)
	var row := UIKit.hbox(panel, 10)
	var text := UIKit.vbox(row, 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(text, "Autoguardado" if is_auto else "Ranura %s" % slot.trim_prefix("slot_"), "InkLabel")
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Palette.INK_TEXT)
	var meta := _metadata_text(entry, exists)
	var meta_label := UIKit.label(text, meta, "InkLabel")
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_label.add_theme_font_size_override("font_size", 14)
	meta_label.add_theme_color_override("font_color", Palette.MUTED)
	var actions := UIKit.hbox(row, 6)
	if not is_auto and TSBGame.has_game():
		var save_button := UIKit.button(actions, "SOBRESCRIBIR" if exists else "GUARDAR", "SmallButton", "Guardar en %s" % slot)
		save_button.name = "save_button"
		save_button.pressed.connect(func() -> void: _on_save_pressed(slot, exists))
	if exists:
		var load_button := UIKit.button(actions, "CARGAR", "SmallButton", "Cargar %s" % slot)
		load_button.pressed.connect(func() -> void: _on_load_pressed(slot))
	else:
		var empty := UIKit.label(actions, "Vacía", "InkLabel")
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Palette.MUTED)
	if is_auto:
		var note := UIKit.label(actions, "No sobrescribe ranuras", "InkLabel")
		note.add_theme_font_size_override("font_size", 12)
		note.add_theme_color_override("font_color", Palette.GOLD_DIM)


func _metadata_text(entry: Dictionary, exists: bool) -> String:
	if not exists:
		return "Sin partida guardada."
	var year := int(entry.get("year", 0))
	var quarter := int(entry.get("quarter", 0))
	var season := TSBGame.season_name(quarter) if quarter > 0 else "—"
	var faction := str(entry.get("faction", ""))
	var faction_name := TSBGame.faction_name(faction) if not faction.is_empty() else "—"
	var saved_at := str(entry.get("saved_at", ""))
	if not saved_at.is_empty() and saved_at.is_valid_int():
		saved_at = Time.get_datetime_string_from_unix_time(int(saved_at))
	return "%s · %s %s · %s%s" % [
		"Año %d" % year if year > 0 else "Año —",
		season,
		"Turno %d" % quarter if quarter > 0 else "",
		faction_name,
		(" · " + saved_at) if not saved_at.is_empty() else "",
	]


func _on_save_pressed(slot: String, overwrite: bool) -> void:
	if not TSBGame.has_game():
		_set_status("Inicia una partida antes de guardar.")
		return
	if overwrite:
		_pending_slot = slot
		_confirm.dialog_text = "La ranura %s ya contiene una partida. ¿Sobrescribirla?" % slot.trim_prefix("slot_")
		_confirm.popup_centered(Vector2i(480, 180))
		return
	_do_save(slot)


func _on_overwrite_confirmed() -> void:
	if not _pending_slot.is_empty():
		_do_save(_pending_slot)
		_pending_slot = ""


func _do_save(slot: String) -> void:
	if TSBGame.save_game(slot):
		_set_status("Partida guardada en %s." % slot)
		_rebuild()
	else:
		_set_status("No se pudo guardar la partida.")


func _on_load_pressed(slot: String) -> void:
	if TSBGame.load_game(slot):
		_set_status("Partida cargada desde %s." % slot)
		loaded.emit(slot)
		close_overlay()
	else:
		_set_status("No se pudo cargar %s." % slot)


func _set_status(text: String) -> void:
	if _status != null:
		_status.text = text
