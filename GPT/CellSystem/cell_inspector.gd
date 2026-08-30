extends Node

## Interactive cell inspector.
## Select a cell with the left mouse button and show its data in a fixed
## top-right UI panel while the camera follows the selected organism.

@export var collision_mask: int = 1
@export var panel_width: float = 360.0
@export var panel_margin: float = 20.0
@export var refresh_interval: float = 0.10

var _selected_cell: Node = null
var _refresh_timer: float = 0.0
var _panel: PanelContainer
var _title_label: Label
var _details_label: Label
var _health_bar: ProgressBar
var _health_text: Label

func _ready() -> void:
	_create_ui()

func _process(delta: float) -> void:
	if not is_instance_valid(_selected_cell):
		_selected_cell = null
		_set_panel_visible(false)
		return

	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = refresh_interval
		_update_ui_from_selected()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	inspect_at_mouse()

func inspect_at_mouse() -> void:
	var viewport: Viewport = get_viewport()
	var world_position: Vector2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()

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
		"Energy: %.1f / %.1f  (%d%%)\n" % [resources, resource_capacity, roundi(energy_ratio * 100.0)] +
		"Hunger: %s\n" % hunger_state +
		"Damage: %.1f\n" % float(data.get("damage", 0.0)) +
		"Speed: %.1f\n" % float(data.get("speed", 0.0)) +
		"Size: %.1f\n" % float(data.get("size", 0.0)) +
		"Mitosis: %d  |  Next cost: %.1f\n" % [int(data.get("mitosis_count", 0)), float(data.get("next_mitosis_cost", 0.0))] +
		"Allies nearby: %d\n" % int(data.get("nearby_allies", 0)) +
		"Fear: %.2f  |  Env. stress: %.2f" % [float(data.get("fear", 0.0)), environment_stress]
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

func _set_panel_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible

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
