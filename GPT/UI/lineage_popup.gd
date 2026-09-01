extends Window

const PORTRAIT_SCRIPT := preload("res://GPT/UI/cell_portrait.gd")
const RECORD_POPUP_SCRIPT := preload("res://GPT/UI/cell_record_popup.gd")
const GRAPH_SCRIPT := preload("res://GPT/UI/lineage_graph.gd")

var cell_id: String = ""
var _graph: Control
var _family: Dictionary = {}

func setup(target_id: String) -> void:
	cell_id = target_id.strip_edges()
	title = "Árvore genealógica — %s" % _short_id(cell_id)
	size = Vector2i(820, 560)
	position = Vector2i(80, 90)
	transient = true
	close_requested.connect(_on_close_requested)
	_refresh_family()
	popup_centered()

func _refresh_family() -> void:
	var config: Node = get_tree().root.get_node_or_null("SimulationConfig")
	if config == null or not config.has_method("get_lineage_family"):
		_build_message("Memória genealógica indisponível.")
		return
	_family = config.get_lineage_family(cell_id, 4)
	if _family.is_empty():
		_build_message("Nenhum registro de linhagem encontrado.")
		return
	_build_tree()

func _build_message(message: String) -> void:
	for child in get_children():
		child.queue_free()
	var label := Label.new()
	label.text = message
	label.position = Vector2(24, 24)
	add_child(label)

func _build_tree() -> void:
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 14)
	margin.add_child(root_column)

	var title_label := Label.new()
	title_label.text = "LINHAGEM — %s" % _short_id(cell_id)
	title_label.add_theme_font_size_override("font_size", 20)
	root_column.add_child(title_label)

	_graph = GRAPH_SCRIPT.new()
	_graph.custom_minimum_size = Vector2(0, 430)
	_graph.mouse_filter = Control.MOUSE_FILTER_PASS
	root_column.add_child(_graph)

	var parent_card: Control = _create_branch_card(_family.get("parent", {}), Vector2(305, 10), "PARENT")
	var current_card: Control = _create_branch_card(_family.get("current", {}), Vector2(305, 165), "INDIVÍDUO")
	_graph.parent_card = parent_card
	_graph.current_card = current_card

	var children: Array = _family.get("children", [])
	var count := children.size()
	if count == 0:
		var none := Label.new()
		none.text = "Sem descendentes registrados."
		none.position = Vector2(305, 330)
		_graph.add_child(none)
	else:
		var spacing: float = 740.0 / float(maxi(count - 1, 1))
		for index in range(count):
			var x: float = 305.0 if count == 1 else 35.0 + spacing * float(index)
			var child_card: Control = _create_branch_card(children[index], Vector2(x, 330), "FILHO")
			_graph.child_cards.append(child_card)

		var total_children: int = int(_family.get("total_children", count))
		if total_children > count:
			var extra := Label.new()
			extra.text = "+%d descendente(s) não exibido(s)" % (total_children - count)
			extra.position = Vector2(280, 410)
			_graph.add_child(extra)

	_graph.refresh()

func _create_branch_card(record: Dictionary, pos: Vector2, kind: String) -> Control:
	if record.is_empty():
		var placeholder := Label.new()
		placeholder.text = "%s\n(não registrado)" % kind
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.position = pos
		placeholder.size = Vector2(170, 110)
		_graph.add_child(placeholder)
		return placeholder

	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = Vector2(170, 125)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_graph.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)

	var portrait := PORTRAIT_SCRIPT.new()
	portrait.setup(record)
	portrait.custom_minimum_size = Vector2(78, 70)
	column.add_child(portrait)

	var id: String = String(record.get("cell_id", "unknown"))
	var label := Label.new()
	label.text = "%s %s\n%s • G%d\n%s" % [kind, _short_id(id), String(record.get("species_id", "unknown")), int(record.get("generation", 0)), "Vivo" if bool(record.get("alive", true)) else "Morto"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)

	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
			_open_record(record)
	)
	return panel

func _open_record(record: Dictionary) -> void:
	var popup := RECORD_POPUP_SCRIPT.new()
	get_tree().root.add_child(popup)
	popup.setup(record)

func _short_id(value: String) -> String:
	var digits := value.trim_prefix("cell_")
	if digits.is_valid_int():
		return "#%d" % int(digits)
	return value

func _on_close_requested() -> void:
	queue_free()
