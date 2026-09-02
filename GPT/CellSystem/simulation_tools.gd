extends Node

## Developer-facing controls for the integrated CellSystem laboratory.
## Tools orchestrate existing simulation systems; they do not own biology or genetics.
class_name SimulationTools

const TICK_DURATION: float = 0.1
const TOOL_TOGGLE_KEY: Key = KEY_F4
const DEFAULT_TIME_SCALE: float = 1.0

@export var panel_width: float = 360.0
@export var panel_margin: float = 20.0
@export var default_spawn_burst: int = 1

var cell_manager: Node
var resource_spawner: Node2D
var experimental_domain: Node
var simulation_camera: Camera2D
var cell_inspector: Node

var _canvas: CanvasLayer
var _panel: PanelContainer
var _feedback_label: Label
var _target_label: Label
var _pause_button: Button
var _speed_label: Label
var _temperature_slider: HSlider
var _humidity_slider: HSlider
var _food_slider: HSlider
var _temperature_value: Label
var _humidity_value: Label
var _food_value: Label
var _visible: bool = true
var _feedback_timer: float = 0.0
var _selected_cell: Node = null
var _saved_time_scale: float = DEFAULT_TIME_SCALE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	_create_ui()
	_sync_selected_cell()
	_sync_environment_controls()
	_set_visible(true)

func _process(delta: float) -> void:
	_feedback_timer = maxf(_feedback_timer - delta, 0.0)
	if _feedback_timer <= 0.0 and _feedback_label != null:
		_feedback_label.text = "Ready"
	_sync_selected_cell()
	_update_target_label()
	if _temperature_slider != null:
		_sync_environment_values_only()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == TOOL_TOGGLE_KEY:
		_set_visible(not _visible)
		get_viewport().set_input_as_handled()
		return
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE and _visible:
		_set_visible(false)
		get_viewport().set_input_as_handled()

func _resolve_nodes() -> void:
	var root: Node = get_parent()
	if root == null:
		return
	cell_manager = root.get_node_or_null("CellManager")
	resource_spawner = root.get_node_or_null("ResourceSpawner") as Node2D
	experimental_domain = root.get_node_or_null("ExperimentalDomain")
	simulation_camera = root.get_node_or_null("SimulationCamera") as Camera2D
	cell_inspector = root.get_node_or_null("CellInspector")

func _sync_selected_cell() -> void:
	if cell_inspector == null or not is_instance_valid(cell_inspector):
		_selected_cell = null
		return
	if not cell_inspector.has_method("get_selected_cell"):
		_selected_cell = null
		return
	var selected: Variant = cell_inspector.get_selected_cell()
	if selected is Node and is_instance_valid(selected):
		_selected_cell = selected
	else:
		_selected_cell = null

func _create_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "SimulationToolsUILayer"
	_canvas.layer = 30
	add_child(_canvas)

	_panel = PanelContainer.new()
	_panel.name = "SimulationToolsPanel"
	_panel.custom_minimum_size = Vector2(panel_width, 0.0)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(panel_margin, panel_margin)
	_canvas.add_child(_panel)

	var margin: MarginContainer = MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var title: Label = Label.new()
	title.text = "SIMULATION TOOLS  [F4]"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)

	var separator: HSeparator = HSeparator.new()
	column.add_child(separator)

	_add_section_title(column, "POPULATION")
	var spawn_row: HBoxContainer = HBoxContainer.new()
	column.add_child(spawn_row)
	_add_button(spawn_row, "Spawn Cell", _on_spawn_cell)
	_add_button(spawn_row, "+10", _on_spawn_ten_cells)

	var resource_row: HBoxContainer = HBoxContainer.new()
	column.add_child(resource_row)
	_add_button(resource_row, "Spawn Resource", _on_spawn_resource)
	_add_button(resource_row, "+10", _on_spawn_ten_resources)

	_add_section_title(column, "GENETICS")
	_target_label = Label.new()
	_target_label.text = "Target: none"
	_target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_target_label)

	var mutation_row: HBoxContainer = HBoxContainer.new()
	column.add_child(mutation_row)
	_add_button(mutation_row, "Mutate", _on_mutate_selected)
	_add_button(mutation_row, "Mutate ×5", _on_mutate_selected_five)

	var select_hint: Label = Label.new()
	select_hint.text = "Right-click a cell to select it."
	select_hint.add_theme_font_size_override("font_size", 12)
	column.add_child(select_hint)

	_add_section_title(column, "TIME")
	var time_row: HBoxContainer = HBoxContainer.new()
	column.add_child(time_row)
	_pause_button = _add_button(time_row, "Pause", _on_toggle_pause)
	_add_button(time_row, "1×", func(): _set_time_scale(1.0))
	_add_button(time_row, "2×", func(): _set_time_scale(2.0))
	_add_button(time_row, "4×", func(): _set_time_scale(4.0))
	_add_button(time_row, "8×", func(): _set_time_scale(8.0))
	_speed_label = Label.new()
	_speed_label.text = "Speed: 1×"
	column.add_child(_speed_label)

	var tick_info: Label = Label.new()
	tick_info.text = "1 Tick = %.1f s of simulation time" % TICK_DURATION
	tick_info.add_theme_font_size_override("font_size", 12)
	column.add_child(tick_info)

	_add_section_title(column, "ENVIRONMENT")
	_temperature_slider = _add_environment_slider(column, "Temperature", _on_temperature_changed)
	_temperature_value = _last_value_label(column)
	_humidity_slider = _add_environment_slider(column, "Humidity", _on_humidity_changed)
	_humidity_value = _last_value_label(column)
	_food_slider = _add_environment_slider(column, "Food density", _on_food_changed)
	_food_value = _last_value_label(column)

	_add_button(column, "Reset Environment", _on_reset_environment)

	_feedback_label = Label.new()
	_feedback_label.text = "Ready"
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_feedback_label)

func _add_section_title(column: VBoxContainer, text_value: String) -> void:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	column.add_child(label)

func _add_button(parent: Container, text_value: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _add_environment_slider(column: VBoxContainer, label_text: String, callback: Callable) -> HSlider:
	var label: Label = Label.new()
	label.text = label_text
	column.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	column.add_child(slider)
	var value_label: Label = Label.new()
	value_label.text = "0.00"
	value_label.add_theme_font_size_override("font_size", 12)
	column.add_child(value_label)
	return slider

func _last_value_label(column: VBoxContainer) -> Label:
	var child_count: int = column.get_child_count()
	return column.get_child(child_count - 1) as Label

func _set_visible(enabled: bool) -> void:
	_visible = enabled
	if _panel != null:
		_panel.visible = enabled

func _set_feedback(text_value: String) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text_value
	_feedback_timer = 2.5

func _update_target_label() -> void:
	if not is_instance_valid(_selected_cell):
		_selected_cell = null
		if _target_label != null:
			_target_label.text = "Target: none"
		return
	var cell_id_value: Variant = _selected_cell.get("cell_id")
	var species_id_value: Variant = _selected_cell.get("species_id")
	var cell_id: String = String(cell_id_value) if cell_id_value != null else "unknown"
	var species_id: String = String(species_id_value) if species_id_value != null else "unknown"
	if _target_label != null:
		_target_label.text = "Target: %s (%s)" % [cell_id, species_id]

func _mouse_world_position() -> Vector2:
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		return Vector2.ZERO
	return simulation_camera.get_global_mouse_position()

func _on_spawn_cell() -> void:
	if cell_manager == null or not is_instance_valid(cell_manager):
		_set_feedback("CellManager unavailable")
		return
	var spawned: Node = cell_manager.create_cell(_mouse_world_position(), false, "")
	_set_feedback("Cell spawned" if spawned != null else "Could not spawn cell")

func _on_spawn_ten_cells() -> void:
	var success_count: int = 0
	if cell_manager == null or not is_instance_valid(cell_manager):
		_set_feedback("CellManager unavailable")
		return
	for _i in range(10):
		var offset := Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		if cell_manager.create_cell(_mouse_world_position() + offset, false, "") != null:
			success_count += 1
	_set_feedback("Spawned %d cells" % success_count)

func _on_spawn_resource() -> void:
	if resource_spawner == null or not is_instance_valid(resource_spawner):
		_set_feedback("ResourceSpawner unavailable")
		return
	if not resource_spawner.has_method("spawn_resource"):
		_set_feedback("spawn_resource() unavailable")
		return
	var resource_node: Node = resource_spawner.spawn_resource()
	if resource_node == null:
		_set_feedback("Could not spawn resource")
		return
	resource_node.global_position = _clamp_to_domain(_mouse_world_position(), 8.0)
	_set_feedback("Resource spawned")

func _on_spawn_ten_resources() -> void:
	var success_count: int = 0
	if resource_spawner == null or not is_instance_valid(resource_spawner):
		_set_feedback("ResourceSpawner unavailable")
		return
	if not resource_spawner.has_method("spawn_resource"):
		_set_feedback("spawn_resource() unavailable")
		return
	for _i in range(10):
		var resource_node: Node = resource_spawner.spawn_resource()
		if resource_node == null:
			continue
		resource_node.global_position = _clamp_to_domain(_mouse_world_position() + Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0)), 8.0)
		success_count += 1
	_set_feedback("Spawned %d resources" % success_count)

func _on_mutate_selected() -> void:
	if not is_instance_valid(_selected_cell):
		_set_feedback("Select a cell with right-click first")
		return
	var genetics: Node = _selected_cell.get("genetics") as Node
	if genetics == null or not is_instance_valid(genetics) or not genetics.has_method("mutate_genes"):
		_set_feedback("Selected cell has no genetics")
		return
	var mutated: Array = genetics.mutate_genes()
	_selected_cell.call("_apply_genes_to_biology")
	_selected_cell.call("_apply_behavior_genes")
	if cell_manager != null and is_instance_valid(cell_manager) and cell_manager.has_method("record_mutations"):
		cell_manager.record_mutations(String(genetics.get("species_id")), mutated.size())
	_set_feedback("Mutation: %s" % (", ".join(mutated) if not mutated.is_empty() else "none"))

func _on_mutate_selected_five() -> void:
	if not is_instance_valid(_selected_cell):
		_set_feedback("Select a cell with right-click first")
		return
	var total: Array[String] = []
	for _i in range(5):
		var genetics: Node = _selected_cell.get("genetics") as Node
		if genetics == null or not is_instance_valid(genetics) or not genetics.has_method("mutate_genes"):
			break
		var mutated: Array = genetics.mutate_genes()
		for gene_name in mutated:
			total.append(String(gene_name))
		_selected_cell.call("_apply_genes_to_biology")
		_selected_cell.call("_apply_behavior_genes")
	if cell_manager != null and is_instance_valid(cell_manager) and cell_manager.has_method("record_mutations") and not total.is_empty():
		var genetics: Node = _selected_cell.get("genetics") as Node
		cell_manager.record_mutations(String(genetics.get("species_id")), total.size())
	_set_feedback("5 mutation passes; %d genes changed" % total.size())

func _on_toggle_pause() -> void:
	var tree: SceneTree = get_tree()
	if tree.paused:
		tree.paused = false
		_pause_button.text = "Pause"
		_set_feedback("Simulation resumed")
	else:
		tree.paused = true
		_pause_button.text = "Resume"
		_set_feedback("Simulation paused")

func _set_time_scale(value: float) -> void:
	Engine.time_scale = maxf(value, 0.0)
	_speed_label.text = "Speed: %.1f×" % Engine.time_scale
	_saved_time_scale = Engine.time_scale
	_set_feedback("Speed set to %.1f×" % Engine.time_scale)

func _on_temperature_changed(value: float) -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	experimental_domain.set("base_temperature", clampf(value, 0.0, 1.0))
	if _temperature_value != null:
		_temperature_value.text = "%.2f" % value

func _on_humidity_changed(value: float) -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	experimental_domain.set("base_humidity", clampf(value, 0.0, 1.0))
	if _humidity_value != null:
		_humidity_value.text = "%.2f" % value

func _on_food_changed(value: float) -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	experimental_domain.set("base_food_density", clampf(value, 0.0, 1.0))
	if _food_value != null:
		_food_value.text = "%.2f" % value

func _on_reset_environment() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	experimental_domain.set("base_temperature", 0.5)
	experimental_domain.set("base_humidity", 0.5)
	experimental_domain.set("base_food_density", 1.0)
	_sync_environment_controls()
	_set_feedback("Environment reset")

func _sync_environment_controls() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	_sync_environment_values_only()
	if _temperature_slider != null:
		_temperature_slider.value = float(experimental_domain.get("base_temperature"))
	if _humidity_slider != null:
		_humidity_slider.value = float(experimental_domain.get("base_humidity"))
	if _food_slider != null:
		_food_slider.value = float(experimental_domain.get("base_food_density"))

func _sync_environment_values_only() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	if _temperature_value != null:
		_temperature_value.text = "%.2f" % float(experimental_domain.get("base_temperature"))
	if _humidity_value != null:
		_humidity_value.text = "%.2f" % float(experimental_domain.get("base_humidity"))
	if _food_value != null:
		_food_value.text = "%.2f" % float(experimental_domain.get("base_food_density"))

func _clamp_to_domain(position: Vector2, margin: float) -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("clamp_position"):
		return experimental_domain.clamp_position(position, margin)
	return position

func _exit_tree() -> void:
	Engine.time_scale = DEFAULT_TIME_SCALE
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = false
