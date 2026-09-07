extends Control

## Compact, parser-safe simulation setup screen.
## The scene contains only the root Control; all UI is created here.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")
const DEFAULT_MENU_TIME_SCALE: float = 1.0

var auto_spawn: CheckBox
var population: SpinBox
var max_population: SpinBox
var resources: SpinBox
var max_resources: SpinBox
var radius: SpinBox
var initial_time_scale: SpinBox
var presentation_mode: CheckBox
var start_button: Button
var back_button: Button

func _ready() -> void:
	Engine.time_scale = DEFAULT_MENU_TIME_SCALE
	_build_ui()
	_load_config()

func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.025, 0.055, 0.075, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 0.0)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title: Label = Label.new()
	title.text = "Configurar Simulação"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var separator: HSeparator = HSeparator.new()
	column.add_child(separator)

	auto_spawn = CheckBox.new()
	auto_spawn.text = "Gerar novas células automaticamente"
	column.add_child(auto_spawn)

	population = _add_spin_row(column, "População inicial", 500.0, 1.0, 10000.0, 1.0)
	max_population = _add_spin_row(column, "População máxima", 10000.0, 10.0, 50000.0, 10.0)
	resources = _add_spin_row(column, "Recursos iniciais", 1000.0, 0.0, 50000.0, 50.0)
	max_resources = _add_spin_row(column, "Recursos máximos", 2302.0, 1.0, 100000.0, 50.0)
	radius = _add_spin_row(column, "Raio do domínio", 3000.0, 500.0, 30000.0, 100.0)
	initial_time_scale = _add_spin_row(column, "Velocidade inicial", 1.0, 0.25, 32.0, 0.25)

	presentation_mode = CheckBox.new()
	presentation_mode.text = "Iniciar em Presentation Mode"
	presentation_mode.button_pressed = true
	column.add_child(presentation_mode)

	var hint: Label = Label.new()
	hint.text = "Os valores são aplicados ao iniciar uma nova simulação."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	column.add_child(buttons)

	back_button = Button.new()
	back_button.text = "Voltar"
	back_button.custom_minimum_size = Vector2(220.0, 50.0)
	buttons.add_child(back_button)

	start_button = Button.new()
	start_button.text = "Iniciar Simulação"
	start_button.custom_minimum_size = Vector2(300.0, 50.0)
	buttons.add_child(start_button)

	start_button.pressed.connect(_start_simulation)
	back_button.pressed.connect(_back_to_main_menu)

func _add_spin_row(column: VBoxContainer, label_text: String, default_value: float, min_value: float, max_value: float, step_value: float) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(280.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var value: SpinBox = SpinBox.new()
	value.value = default_value
	value.min_value = min_value
	value.max_value = max_value
	value.step = step_value
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	return value

func _load_config() -> void:
	var config: Node = _get_config()
	if config == null:
		return

	auto_spawn.button_pressed = bool(config.get("auto_spawn_cells"))
	population.value = clampf(float(config.get("initial_population")), population.min_value, population.max_value)
	max_population.value = clampf(float(config.get("max_population")), max_population.min_value, max_population.max_value)
	resources.value = clampf(float(config.get("initial_resources")), resources.min_value, resources.max_value)
	max_resources.value = clampf(float(config.get("max_resources")), max_resources.min_value, max_resources.max_value)
	radius.value = clampf(float(config.get("domain_radius")), radius.min_value, radius.max_value)
	initial_time_scale.value = clampf(float(config.get("initial_time_scale")), initial_time_scale.min_value, initial_time_scale.max_value)
	presentation_mode.button_pressed = bool(config.get("presentation_mode_on_start"))

	population.value = minf(population.value, max_population.value)
	resources.value = minf(resources.value, max_resources.value)

func _start_simulation() -> void:
	var config: Node = _get_config()
	if config == null:
		return

	var initial_population: int = maxi(int(population.value), 1)
	var configured_max_population: int = maxi(int(max_population.value), initial_population)
	var initial_resources: int = maxi(int(resources.value), 0)
	var configured_max_resources: int = maxi(int(max_resources.value), initial_resources)
	var configured_radius: float = maxf(float(radius.value), 500.0)
	var configured_time_scale: float = clampf(float(initial_time_scale.value), 0.25, 32.0)

	max_population.value = configured_max_population
	max_resources.value = configured_max_resources

	config.set("auto_spawn_cells", auto_spawn.button_pressed)
	config.set("initial_population", initial_population)
	config.set("max_population", configured_max_population)
	config.set("initial_resources", initial_resources)
	config.set("max_resources", configured_max_resources)
	config.set("domain_radius", configured_radius)
	config.set("initial_time_scale", configured_time_scale)
	config.set("presentation_mode_on_start", presentation_mode.button_pressed)

	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _back_to_main_menu() -> void:
	Engine.time_scale = DEFAULT_MENU_TIME_SCALE
	get_tree().change_scene_to_file("res://GPT/UI/MainMenu.tscn")

func _get_config() -> Node:
	return get_node_or_null("/root/SimulationConfig")
