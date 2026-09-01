extends Window

const PORTRAIT_SCRIPT := preload("res://GPT/UI/cell_portrait.gd")
const GENETICS_POPUP_SCRIPT := preload("res://GPT/UI/genetics_popup.gd")

var record: Dictionary = {}

func setup(data: Dictionary) -> void:
	record = data.duplicate(true)
	title = "Célula %s" % _short_id(String(record.get("cell_id", "unknown")))
	size = Vector2i(360, 430)
	position = Vector2i(250, 150)
	transient = true
	close_requested.connect(_on_close_requested)
	_build_ui()
	popup_centered()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var portrait := PORTRAIT_SCRIPT.new()
	portrait.setup(record)
	portrait.custom_minimum_size = Vector2(100, 100)
	column.add_child(portrait)

	var title_label := Label.new()
	title_label.text = "%s • Gen %d" % [String(record.get("species_id", "unknown")), int(record.get("generation", 0))]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 19)
	column.add_child(title_label)

	var status := Label.new()
	status.text = "Estado: %s" % ("Vivo" if bool(record.get("alive", true)) else "Morto")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)

	var id_label := Label.new()
	id_label.text = "ID: %s\nParent: %s" % [_short_id(String(record.get("cell_id", "unknown"))), _short_id(String(record.get("parent_id", "none")))]
	column.add_child(id_label)

	var location := Label.new()
	var pos: Vector2 = record.get("position", Vector2.ZERO)
	location.text = "Localização: (%.0f, %.0f)" % [pos.x, pos.y]
	column.add_child(location)

	column.add_child(HSeparator.new())

	var genetics_button := Button.new()
	genetics_button.text = "Ver genética"
	genetics_button.pressed.connect(_open_genetics)
	column.add_child(genetics_button)

	var locate_button := Button.new()
	locate_button.text = "Ir para localização"
	locate_button.visible = bool(record.get("alive", false))
	locate_button.pressed.connect(_go_to_location)
	column.add_child(locate_button)

func _open_genetics() -> void:
	var popup := GENETICS_POPUP_SCRIPT.new()
	get_tree().root.add_child(popup)
	popup.setup(record)

func _go_to_location() -> void:
	var target_id: String = String(record.get("cell_id", "")).strip_edges()
	for cell in get_tree().get_nodes_in_group("SimCells"):
		if not is_instance_valid(cell):
			continue
		if not cell.has_method("get_inspection_data"):
			continue
		var data: Dictionary = cell.get_inspection_data()
		if String(data.get("cell_id", "")).strip_edges() != target_id:
			continue
		var camera: Node = get_tree().get_first_node_in_group("SimulationCameras")
		if camera != null and is_instance_valid(camera) and camera.has_method("set_follow_target"):
			camera.set_follow_target(cell)
		queue_free()
		return

	var camera_fallback: Node = get_tree().get_first_node_in_group("SimulationCameras")
	if camera_fallback != null and camera_fallback is Camera2D:
		camera_fallback.global_position = record.get("position", Vector2.ZERO)

func _short_id(value: String) -> String:
	var digits := value.trim_prefix("cell_")
	if digits.is_valid_int():
		return "#%d" % int(digits)
	return value

func _on_close_requested() -> void:
	queue_free()
