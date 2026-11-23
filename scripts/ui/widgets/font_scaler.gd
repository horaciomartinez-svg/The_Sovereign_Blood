extends Node
## D-090: +2 pt de legibilidad para todo el texto de juego, sin tocar el menú
## principal. Se aplica una sola vez por nodo y también a nodos creados después
## (rebuilds de paneles, overlays y listas).

const BOOST := 2


static func attach(root: Node) -> void:
	if root == null or root.has_node("ReadabilityFontScaler"):
		return
	var scaler_script: Script = load("res://scripts/ui/widgets/font_scaler.gd")
	var scaler: Node = scaler_script.new()
	scaler.name = "ReadabilityFontScaler"
	root.add_child(scaler)


func _ready() -> void:
	var root := get_parent()
	if root == null:
		return
	_scan(root)


func _on_child_entered(node: Node) -> void:
	# Diferido: muchas pantallas llaman a add_theme_font_size_override justo
	# después de add_child; el escalado debe aplicarse sobre el tamaño final.
	if is_instance_valid(node):
		call_deferred("_scan", node)


func _scan(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_hook(node)
	_scale_node(node)
	for child: Node in node.get_children():
		_scan(child)


func _hook(node: Node) -> void:
	if node == null or node.has_meta("_tsb_font_hooked"):
		return
	node.set_meta("_tsb_font_hooked", true)
	node.child_entered_tree.connect(_on_child_entered)


func _scale_node(node: Node) -> void:
	if node == null or node == self or node.has_meta("_tsb_font_boosted"):
		return
	if node is Label or node is Button or node is LineEdit or node is TextEdit:
		var current := int(node.get_theme_font_size("font_size"))
		if current > 0:
			(node as Control).add_theme_font_size_override("font_size", current + BOOST)
		node.set_meta("_tsb_font_boosted", true)
	elif node is RichTextLabel:
		var rich := node as RichTextLabel
		var normal_size := int(rich.get_theme_font_size("normal_font_size"))
		if normal_size > 0:
			rich.add_theme_font_size_override("normal_font_size", normal_size + BOOST)
		rich.set_meta("_tsb_font_boosted", true)
	else:
		return
