extends Node

## Interactive cell inspector.
## Right mouse button selects a cell and shows its data in a fixed top-right UI panel.
## Genetics are displayed directly in the primary panel, with genotype details on demand.

@export var collision_mask: int = 1
@export var panel_width: float = 360.0
@export var panel_margin: float = 20.0
@export var refresh_interval: float = 0.10
@export var genotype_hover_delay: float = 2.0

var _selected_cell: Node = null
var _refresh_timer: float = 0.0
var _presentation_mode: bool = false
var _panel: PanelContainer
var _title_label: Label
var _details_label: Label
var _genetics_container: VBoxContainer
var _tail_details_label: Label
var _health_bar: ProgressBar
var _health_text: Label

var _genotype_popup: PanelContainer
var _genotype_popup_label: Label
var _hover_gene_name: String = ""
var _hover_value_label: Label = null
var _hover_elapsed: float = 0.0

var _gene_value_labels: Dictionary = {}

func _ready() -> void:
	_create_ui()

func _process(delta: float) -> void:
	if _presentation_mode:
		_hide_genotype_popup()
		return
	if not is_instance_valid(_selected_cell):
		_selected_cell = null
		_set_panel_visible(false)
		return

	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = refresh_interval
		_update_ui_from_selected()

	_update_genotype_hover(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _presentation_mode or not event is InputEventMouseButton:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT or not mouse_event.pressed:
		return
	inspect_at_mouse()

func set_presentation_mode(enabled: bool) -> void:
	_presentation_mode = enabled
	if enabled:
		_hide_genotype_popup()
	_set_panel_visible(not enabled and is_instance_valid(_selected_cell))

func get_selected_cell() -> Node:
	if not is_instance_valid(_selected_cell):
		return null
	return _selected_cell

func inspect_at_mouse() -> void:
	var viewport: Viewport = get_viewport()
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return

	var world_position: Vector2 = camera.get_global_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hits: Array[Dictionary] = viewport.get_world_2d().direct_space_state.intersect_point(query, 16)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or not collider is Node:
			continue
		var candidate: Node = collider as Node
		if candidate.is_in_group("SimCells") and candidate.has_method("get_inspection_data"):
			_select_cell(candidate)
			return

func _select_cell(cell: Node) -> void:
	_selected_cell = cell
	_hide_genotype_popup()
	_set_panel_visible(true)
	_refresh_timer = 0.0
	_update_ui_from_selected()
	_print_information(cell.get_inspection_data())
	_focus_camera(cell as Node2D)

func _create_ui() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "InspectorUILayer"
	add_child(canvas)

	_panel = PanelContainer.new()
	_panel.name = "InspectorPanel"
	_panel.visible = false
	_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-panel_width - panel_margin, panel_margin)
	canvas.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	_title_label = Label.new()
	_title_label.text = "Cell Inspector"
	_title_label.add_theme_font_size_override("font_size", 22)
	column.add_child(_title_label)

	var separator: HSeparator = HSeparator.new()
	column.add_child(separator)

	_health_text = Label.new()
	_health_text.visible = false
	column.add_child(_health_text)

	_health_bar = ProgressBar.new()
	_health_bar.visible = false
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(0.0, 12.0)
	column.add_child(_health_bar)

	_details_label = Label.new()
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_details_label)

	var genetics_title: Label = Label.new()
	genetics_title.text = "\nGENETICS"
	genetics_title.add_theme_font_size_override("font_size", 14)
	column.add_child(genetics_title)

	_genetics_container = VBoxContainer.new()
	_genetics_container.add_theme_constant_override("separation", 2)
	column.add_child(_genetics_container)
	_create_gene_rows()

	_tail_details_label = Label.new()
	_tail_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tail_details_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_tail_details_label)

	_genotype_popup = PanelContainer.new()
	_genotype_popup.name = "GenotypePopup"
	_genotype_popup.visible = false
	_genotype_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_genotype_popup.custom_minimum_size = Vector2(180.0, 0.0)
	canvas.add_child(_genotype_popup)

	var popup_margin: MarginContainer = MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_left", 10)
	popup_margin.add_theme_constant_override("margin_top", 8)
	popup_margin.add_theme_constant_override("margin_right", 10)
	popup_margin.add_theme_constant_override("margin_bottom", 8)
	_genotype_popup.add_child(popup_margin)

	_genotype_popup_label = Label.new()
	_genotype_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_genotype_popup_label.add_theme_font_size_override("font_size", 13)
	popup_margin.add_child(_genotype_popup_label)

func _create_gene_rows() -> void:
	var genes: Array[Dictionary] = [
		{"name": "health", "display": "Health"},
		{"name": "damage", "display": "Damage"},
		{"name": "speed", "display": "Speed"},
		{"name": "size", "display": "Size"},
		{"name": "regeneration_rate", "display": "Regeneration"},
		{"name": "mitosis_cost", "display": "Mitosis cost"},
		{"name": "cold_adaptation", "display": "Cold adaptation"},
		{"name": "heat_adaptation", "display": "Heat adaptation"},
		{"name": "humidity_adaptation", "display": "Humidity adaptation"}
	]

	for gene_info in genes:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_genetics_container.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = String(gene_info["display"]) + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 13)
		row.add_child(name_label)

		var value_label: Label = Label.new()
		value_label.name = "Phenotype_%s" % String(gene_info["name"])
		value_label.text = "n/a"
		value_label.mouse_filter = Control.MOUSE_FILTER_STOP
		value_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		value_label.add_theme_font_size_override("font_size", 13)
		row.add_child(value_label)

		var gene_name: String = String(gene_info["name"])
		_gene_value_labels[gene_name] = value_label
		value_label.mouse_entered.connect(_on_gene_value_mouse_entered.bind(gene_name, value_label))
		value_label.mouse_exited.connect(_on_gene_value_mouse_exited.bind(value_label))

func _update_ui_from_selected() -> void:
	if not is_instance_valid(_selected_cell) or not _selected_cell.has_method("get_inspection_data"):
		_set_panel_visible(false)
		return

	var data: Dictionary = _selected_cell.get_inspection_data()
	if data.is_empty():
		_set_panel_visible(false)
		return

	var species: String = String(data.get("species_id", "unknown"))
	var generation: int = int(data.get("generation", 0))
	var health: float = float(data.get("health", 0.0))
	var max_health: float = maxf(float(data.get("max_health", 0.0)), 0.001)
	var resources: float = float(data.get("resources", 0.0))
	var resource_capacity: float = maxf(float(data.get("resource_capacity", 0.0)), 0.001)
	var hunger_state: String = String(data.get("hunger_state", "UNKNOWN"))
	var energy_ratio: float = float(data.get("energy_ratio", resources / resource_capacity))
	var environment_stress: float = float(data.get("environment_stress", 0.0))

	_title_label.text = "%s  •  Gen %d" % [species, generation]
	_details_label.text = (
		"ID: %s\n" % String(data.get("cell_id", "unknown")) +
		"Parent: %s\n" % String(data.get("parent_id", "none")) +
		"State: %s\n" % String(data.get("state", "unknown")) +
		"\nBIOLOGY\n" +
		"Damage: %.1f\n" % float(data.get("damage", 0.0)) +
		"Speed: %.1f\n" % float(data.get("speed", 0.0)) +
		"Size: %.1f\n" % float(data.get("size", 0.0)) +
		"Regeneration: %.1f\n" % float(data.get("regeneration_rate", 0.0)) +
		"\nENERGY\n" +
		"Energy: %.1f / %.1f  (%d%%)\n" % [resources, resource_capacity, roundi(energy_ratio * 100.0)] +
		"Hunger: %s" % hunger_state
	)

	_update_genetics_ui(data)

	_tail_details_label.text = (
		"\nMITOSIS\n" +
		"Mitoses: %d  |  Next cost: %.1f\n" % [int(data.get("mitosis_count", 0)), float(data.get("next_mitosis_cost", 0.0))] +
		"\nENVIRONMENT\n" +
		"Env. stress: %.2f" % environment_stress
	)

	if health < max_health - 0.01:
		_health_bar.visible = true
		_health_text.visible = true
		_health_bar.max_value = max_health
		_health_bar.value = clampf(health, 0.0, max_health)
		_health_text.text = "Health: %.1f / %.1f" % [health, max_health]
	else:
		_health_bar.visible = false
		_health_text.visible = false

func _update_genetics_ui(data: Dictionary) -> void:
	for gene_name in _gene_value_labels.keys():
		var value_label: Label = _gene_value_labels[gene_name] as Label
		if value_label == null:
			continue

		var raw: Dictionary = _get_gene_data(data, String(gene_name))
		if raw.is_empty():
			value_label.text = "n/a"
			continue

		var phenotype: Variant = raw.get("phenotype", 0.0)
		if phenotype is bool:
			value_label.text = "YES" if bool(phenotype) else "NO"
		else:
			value_label.text = "%.2f" % float(phenotype)

func _get_gene_data(data: Dictionary, gene_name: String) -> Dictionary:
	var genes: Dictionary = data.get("genes", {})
	for category_key in genes.keys():
		var category_data: Variant = genes[category_key]
		if not category_data is Dictionary:
			continue
		var raw: Variant = category_data.get(gene_name, {})
		if raw is Dictionary:
			return raw
	return {}

func _on_gene_value_mouse_entered(gene_name: String, value_label: Label) -> void:
	if _presentation_mode or not is_instance_valid(_selected_cell):
		return
	_hover_gene_name = gene_name
	_hover_value_label = value_label
	_hover_elapsed = 0.0
	_hide_genotype_popup()

func _on_gene_value_mouse_exited(value_label: Label) -> void:
	if _hover_value_label != value_label:
		return
	_hover_gene_name = ""
	_hover_value_label = null
	_hover_elapsed = 0.0
	_hide_genotype_popup()

func _update_genotype_hover(delta: float) -> void:
	if _hover_gene_name.is_empty() or not is_instance_valid(_hover_value_label):
		_hide_genotype_popup()
		return
	if not is_instance_valid(_selected_cell):
		_hide_genotype_popup()
		return

	_hover_elapsed += delta
	if _hover_elapsed < genotype_hover_delay:
		return
	if not _genotype_popup.visible:
		_show_genotype_popup()

func _show_genotype_popup() -> void:
	if _genotype_popup == null or _genotype_popup_label == null:
		return
	if not is_instance_valid(_hover_value_label):
		return

	var data: Dictionary = _selected_cell.get_inspection_data()
	var raw: Dictionary = _get_gene_data(data, _hover_gene_name)
	if raw.is_empty():
		return

	var display_name: String = _display_name_for_gene(_hover_gene_name)
	_genotype_popup_label.text = (
		"%s\n" % display_name +
		"Genotype\n" +
		"Allele A: %s\n" % _format_allele(raw.get("allele_a", "n/a")) +
		"Allele B: %s" % _format_allele(raw.get("allele_b", "n/a"))
	)

	_genotype_popup.reset_size()
	var target_rect: Rect2 = _hover_value_label.get_global_rect()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var popup_size: Vector2 = _genotype_popup.size
	var popup_position: Vector2 = target_rect.position + Vector2(target_rect.size.x + 8.0, -2.0)

	if popup_position.x + popup_size.x > viewport_size.x - 8.0:
		popup_position.x = maxf(8.0, target_rect.position.x - popup_size.x - 8.0)
	if popup_position.y + popup_size.y > viewport_size.y - 8.0:
		popup_position.y = maxf(8.0, viewport_size.y - popup_size.y - 8.0)
	if popup_position.y < 8.0:
		popup_position.y = 8.0

	_genotype_popup.position = popup_position
	_genotype_popup.visible = true

func _hide_genotype_popup() -> void:
	if _genotype_popup != null:
		_genotype_popup.visible = false

func _display_name_for_gene(gene_name: String) -> String:
	match gene_name:
		"health":
			return "Health"
		"damage":
			return "Damage"
		"speed":
			return "Speed"
		"size":
			return "Size"
		"regeneration_rate":
			return "Regeneration"
		"mitosis_cost":
			return "Mitosis cost"
		"cold_adaptation":
			return "Cold adaptation"
		"heat_adaptation":
			return "Heat adaptation"
		"humidity_adaptation":
			return "Humidity adaptation"
		_:
			return gene_name

func _format_allele(value: Variant) -> String:
	if value is float or value is int:
		return "%.3f" % float(value)
	return String(value)

func _set_panel_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible
	if not visible:
		_hide_genotype_popup()

func _focus_camera(selected_cell: Node2D) -> void:
	if selected_cell == null:
		return
	var camera: Node = get_tree().get_first_node_in_group("SimulationCameras")
	if camera != null and is_instance_valid(camera) and camera.has_method("set_follow_target"):
		camera.set_follow_target(selected_cell)

func _print_information(data: Dictionary) -> void:
	print("========== CELL INFORMATION ==========")
	print("ID: ", data.get("cell_id", "unknown"))
	print("Species: ", data.get("species_id", "unknown"))
	print("Generation: ", data.get("generation", 0))
	print("Parent ID: ", data.get("parent_id", "none"))
	print("Player: ", data.get("player", false))
	print("State: ", data.get("state", "unknown"))
	print("Health: %.2f / %.2f" % [data.get("health", 0.0), data.get("max_health", 0.0)])
	print("Energy: %.2f / %.2f" % [data.get("resources", 0.0), data.get("resource_capacity", 0.0)])
	print("Hunger: ", data.get("hunger_state", "UNKNOWN"))
	print("Damage: %.2f" % data.get("damage", 0.0))
	print("Speed: %.2f" % data.get("speed", 0.0))
	print("Size: %.2f" % data.get("size", 0.0))
	print("Regeneration: %.2f" % data.get("regeneration_rate", 0.0))
	print("Mitosis count: ", data.get("mitosis_count", 0))
	print("Next mitosis cost: %.2f" % data.get("next_mitosis_cost", 0.0))
	print("Genes: ", data.get("genes", {}))
	print("Environment: ", data.get("environment", {}))
	print("Environment stress: %.3f" % data.get("environment_stress", 0.0))
	print("=====================================")
