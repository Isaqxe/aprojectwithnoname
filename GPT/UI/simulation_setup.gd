extends Control

## Compact, parser-safe simulation setup screen.
## The scene contains only the root Control; all UI is created here.
## Presets configure the same controls as manual editing, so there is only one source of truth.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")
const DEFAULT_MENU_TIME_SCALE: float = 1.0

var auto_spawn: CheckBox
var population: SpinBox
var max_population: SpinBox
var resources: SpinBox
var max_resources: SpinBox
var radius: SpinBox
var initial_time_scale: SpinBox
var simulation_time_limit: SpinBox
var resource_spawn_interval: SpinBox
var resource_respawn_fraction: SpinBox
var resource_emergency_fraction: SpinBox
var resource_emergency_interval: SpinBox
var base_temperature: SpinBox
var base_humidity: SpinBox
var base_food_density: SpinBox
var temperature_variation: SpinBox
var humidity_variation: SpinBox
var food_edge_penalty: SpinBox
var mutation_chance: SpinBox
var mutation_strength: SpinBox
var presentation_mode: CheckBox
var start_button: Button
var back_button: Button

const PRESETS: Dictionary = {
	"Equilibrada": {
		"auto_spawn": false,
		"population": 500,
		"max_population": 10000,
		"resources": 1000,
		"max_resources": 2302,
		"radius": 3000.0,
		"resource_spawn_interval": 0.75,
		"resource_respawn_fraction": 60.0,
		"resource_emergency_fraction": 25.0,
		"resource_emergency_interval": 0.30,
		"base_temperature": 50.0,
		"base_humidity": 50.0,
		"base_food_density": 100.0,
		"temperature_variation": 35.0,
		"humidity_variation": 30.0,
		"food_edge_penalty": 45.0,
		"mutation_chance": 10.0,
		"mutation_strength": 5.0,
		"initial_time_scale": 1.0,
		"simulation_time_limit": 0.0,
		"presentation_mode": true
	},
	"Crescimento": {
		"auto_spawn": true,
		"population": 800,
		"max_population": 12000,
		"resources": 5000,
		"max_resources": 12000,
		"radius": 4500.0,
		"resource_spawn_interval": 0.45,
		"resource_respawn_fraction": 70.0,
		"resource_emergency_fraction": 35.0,
		"resource_emergency_interval": 0.20,
		"base_temperature": 50.0,
		"base_humidity": 50.0,
		"base_food_density": 100.0,
		"temperature_variation": 25.0,
		"humidity_variation": 25.0,
		"food_edge_penalty": 25.0,
		"mutation_chance": 8.0,
		"mutation_strength": 4.0,
		"initial_time_scale": 1.0,
		"simulation_time_limit": 0.0,
		"presentation_mode": true
	},
	"Evolução rápida": {
		"auto_spawn": false,
		"population": 300,
		"max_population": 8000,
		"resources": 3500,
		"max_resources": 10000,
		"radius": 3500.0,
		"resource_spawn_interval": 0.70,
		"resource_respawn_fraction": 60.0,
		"resource_emergency_fraction": 20.0,
		"resource_emergency_interval": 0.30,
		"base_temperature": 50.0,
		"base_humidity": 50.0,
		"base_food_density": 90.0,
		"temperature_variation": 40.0,
		"humidity_variation": 35.0,
		"food_edge_penalty": 45.0,
		"mutation_chance": 35.0,
		"mutation_strength": 12.0,
		"initial_time_scale": 2.0,
		"simulation_time_limit": 600.0,
		"presentation_mode": false
	},
	"Ambiente extremo": {
		"auto_spawn": false,
		"population": 500,
		"max_population": 10000,
		"resources": 1200,
		"max_resources": 5000,
		"radius": 5000.0,
		"resource_spawn_interval": 1.10,
		"resource_respawn_fraction": 55.0,
		"resource_emergency_fraction": 15.0,
		"resource_emergency_interval": 0.50,
		"base_temperature": 20.0,
		"base_humidity": 80.0,
		"base_food_density": 60.0,
		"temperature_variation": 80.0,
		"humidity_variation": 80.0,
		"food_edge_penalty": 75.0,
		"mutation_chance": 15.0,
		"mutation_strength": 7.0,
		"initial_time_scale": 1.0,
		"simulation_time_limit": 0.0,
		"presentation_mode": false
	},
	"Demonstração": {
		"auto_spawn": false,
		"population": 120,
		"max_population": 2000,
		"resources": 8000,
		"max_resources": 12000,
		"radius": 5000.0,
		"resource_spawn_interval": 0.65,
		"resource_respawn_fraction": 65.0,
		"resource_emergency_fraction": 30.0,
		"resource_emergency_interval": 0.25,
		"base_temperature": 50.0,
		"base_humidity": 50.0,
		"base_food_density": 100.0,
		"temperature_variation": 20.0,
		"humidity_variation": 20.0,
		"food_edge_penalty": 20.0,
		"mutation_chance": 18.0,
		"mutation_strength": 6.0,
		"initial_time_scale": 1.0,
		"simulation_time_limit": 0.0,
		"presentation_mode": true
	}
}

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
	panel.custom_minimum_size = Vector2(700.0, 680.0)
	center.add_child(panel)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700.0, 680.0)
	panel.add_child(scroll)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title: Label = Label.new()
	title.text = "Configurar Simulação"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	column.add_child(HSeparator.new())

	var preset_title: Label = _section_label("Presets")
	column.add_child(preset_title)

	var preset_row: HBoxContainer = HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	preset_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(preset_row)

	for preset_name in PRESETS.keys():
		var preset_button: Button = Button.new()
		preset_button.text = String(preset_name)
		preset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_button.custom_minimum_size = Vector2(0.0, 36.0)
		preset_button.tooltip_text = "Aplicar preset: %s" % String(preset_name)
		preset_button.pressed.connect(_apply_preset.bind(String(preset_name)))
		preset_row.add_child(preset_button)

	var preset_hint: Label = Label.new()
	preset_hint.text = "Um preset apenas preenche os mesmos controles abaixo; você pode ajustá-los manualmente depois."
	preset_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preset_hint.add_theme_font_size_override("font_size", 11)
	column.add_child(preset_hint)

	auto_spawn = CheckBox.new()
	auto_spawn.text = "Gerar novas células automaticamente"
	column.add_child(auto_spawn)

	column.add_child(_section_label("População e domínio"))
	population = _add_spin_row(column, "População inicial", 500.0, 1.0, 10000.0, 1.0)
	max_population = _add_spin_row(column, "População máxima", 10000.0, 10.0, 50000.0, 10.0)
	resources = _add_spin_row(column, "Recursos iniciais", 1000.0, 0.0, 50000.0, 50.0)
	max_resources = _add_spin_row(column, "Recursos máximos", 2302.0, 1.0, 100000.0, 50.0)
	radius = _add_spin_row(column, "Raio do domínio", 3000.0, 500.0, 30000.0, 100.0)

	column.add_child(_section_label("Recursos"))
	resource_spawn_interval = _add_spin_row(column, "Intervalo de reposição (s)", 0.75, 0.05, 30.0, 0.05)
	resource_respawn_fraction = _add_spin_row(column, "Reposição abaixo de (%)", 60.0, 0.0, 100.0, 1.0)
	resource_emergency_fraction = _add_spin_row(column, "Emergência abaixo de (%)", 25.0, 0.0, 100.0, 1.0)
	resource_emergency_interval = _add_spin_row(column, "Intervalo de emergência (s)", 0.30, 0.05, 30.0, 0.05)

	column.add_child(_section_label("Ambiente"))
	base_temperature = _add_spin_row(column, "Temperatura base (%)", 50.0, 0.0, 100.0, 1.0)
	base_humidity = _add_spin_row(column, "Umidade base (%)", 50.0, 0.0, 100.0, 1.0)
	base_food_density = _add_spin_row(column, "Densidade de alimento (%)", 100.0, 0.0, 100.0, 1.0)
	temperature_variation = _add_spin_row(column, "Variação térmica (%)", 35.0, 0.0, 100.0, 1.0)
	humidity_variation = _add_spin_row(column, "Variação de umidade (%)", 30.0, 0.0, 100.0, 1.0)
	food_edge_penalty = _add_spin_row(column, "Penalidade de alimento na borda (%)", 45.0, 0.0, 100.0, 1.0)

	column.add_child(_section_label("Genética"))
	mutation_chance = _add_spin_row(column, "Chance de mutação por gene (%)", 10.0, 0.0, 100.0, 1.0)
	mutation_strength = _add_spin_row(column, "Força da mutação (%)", 5.0, 0.0, 100.0, 1.0)

	column.add_child(_section_label("Execução"))
	initial_time_scale = _add_spin_row(column, "Velocidade inicial", 1.0, 0.25, 32.0, 0.25)
	simulation_time_limit = _add_spin_row(column, "Limite de simulação (s; 0 = infinito)", 0.0, 0.0, 36000.0, 10.0)

	presentation_mode = CheckBox.new()
	presentation_mode.text = "Iniciar em Presentation Mode"
	presentation_mode.button_pressed = true
	column.add_child(presentation_mode)

	var hint: Label = Label.new()
	hint.text = "Valores em porcentagem variam de 0 a 100. As mudanças valem para uma nova simulação."
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

func _section_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 4)
	return label

func _add_spin_row(column: VBoxContainer, label_text: String, default_value: float, min_value: float, max_value: float, step_value: float) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(330.0, 0.0)
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

func _apply_preset(preset_name: String) -> void:
	if not PRESETS.has(preset_name):
		return
	var preset: Dictionary = PRESETS[preset_name]

	auto_spawn.button_pressed = bool(preset.get("auto_spawn"))
	population.value = float(preset.get("population"))
	max_population.value = float(preset.get("max_population"))
	resources.value = float(preset.get("resources"))
	max_resources.value = float(preset.get("max_resources"))
	radius.value = float(preset.get("radius"))
	resource_spawn_interval.value = float(preset.get("resource_spawn_interval"))
	resource_respawn_fraction.value = float(preset.get("resource_respawn_fraction"))
	resource_emergency_fraction.value = float(preset.get("resource_emergency_fraction"))
	resource_emergency_interval.value = float(preset.get("resource_emergency_interval"))
	base_temperature.value = float(preset.get("base_temperature"))
	base_humidity.value = float(preset.get("base_humidity"))
	base_food_density.value = float(preset.get("base_food_density"))
	temperature_variation.value = float(preset.get("temperature_variation"))
	humidity_variation.value = float(preset.get("humidity_variation"))
	food_edge_penalty.value = float(preset.get("food_edge_penalty"))
	mutation_chance.value = float(preset.get("mutation_chance"))
	mutation_strength.value = float(preset.get("mutation_strength"))
	initial_time_scale.value = float(preset.get("initial_time_scale"))
	simulation_time_limit.value = float(preset.get("simulation_time_limit"))
	presentation_mode.button_pressed = bool(preset.get("presentation_mode"))

	population.value = minf(population.value, max_population.value)
	resources.value = minf(resources.value, max_resources.value)
	resource_emergency_fraction.value = minf(resource_emergency_fraction.value, resource_respawn_fraction.value)

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
	simulation_time_limit.value = clampf(float(config.get("simulation_time_limit")), simulation_time_limit.min_value, simulation_time_limit.max_value)
	resource_spawn_interval.value = clampf(float(config.get("resource_spawn_interval")), resource_spawn_interval.min_value, resource_spawn_interval.max_value)
	resource_respawn_fraction.value = clampf(float(config.get("resource_respawn_fraction")) * 100.0, resource_respawn_fraction.min_value, resource_respawn_fraction.max_value)
	resource_emergency_fraction.value = clampf(float(config.get("resource_emergency_fraction")) * 100.0, resource_emergency_fraction.min_value, resource_emergency_fraction.max_value)
	resource_emergency_interval.value = clampf(float(config.get("resource_emergency_interval")), resource_emergency_interval.min_value, resource_emergency_interval.max_value)
	base_temperature.value = clampf(float(config.get("base_temperature")) * 100.0, base_temperature.min_value, base_temperature.max_value)
	base_humidity.value = clampf(float(config.get("base_humidity")) * 100.0, base_humidity.min_value, base_humidity.max_value)
	base_food_density.value = clampf(float(config.get("base_food_density")) * 100.0, base_food_density.min_value, base_food_density.max_value)
	temperature_variation.value = clampf(float(config.get("temperature_variation")) * 100.0, temperature_variation.min_value, temperature_variation.max_value)
	humidity_variation.value = clampf(float(config.get("humidity_variation")) * 100.0, humidity_variation.min_value, humidity_variation.max_value)
	food_edge_penalty.value = clampf(float(config.get("food_edge_penalty")) * 100.0, food_edge_penalty.min_value, food_edge_penalty.max_value)
	mutation_chance.value = clampf(float(config.get("mutation_chance")) * 100.0, mutation_chance.min_value, mutation_chance.max_value)
	mutation_strength.value = clampf(float(config.get("mutation_strength")) * 100.0, mutation_strength.min_value, mutation_strength.max_value)
	presentation_mode.button_pressed = bool(config.get("presentation_mode_on_start"))

	population.value = minf(population.value, max_population.value)
	resources.value = minf(resources.value, max_resources.value)
	resource_emergency_fraction.value = minf(resource_emergency_fraction.value, resource_respawn_fraction.value)

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
	var configured_time_limit: float = maxf(float(simulation_time_limit.value), 0.0)
	var configured_resource_respawn_fraction: float = clampf(float(resource_respawn_fraction.value) / 100.0, 0.0, 1.0)
	var configured_resource_emergency_fraction: float = clampf(float(resource_emergency_fraction.value) / 100.0, 0.0, configured_resource_respawn_fraction)

	max_population.value = configured_max_population
	max_resources.value = configured_max_resources
	resource_respawn_fraction.value = configured_resource_respawn_fraction * 100.0
	resource_emergency_fraction.value = configured_resource_emergency_fraction * 100.0

	config.set("auto_spawn_cells", auto_spawn.button_pressed)
	config.set("initial_population", initial_population)
	config.set("max_population", configured_max_population)
	config.set("initial_resources", initial_resources)
	config.set("max_resources", configured_max_resources)
	config.set("domain_radius", configured_radius)
	config.set("initial_time_scale", configured_time_scale)
	config.set("simulation_time_limit", configured_time_limit)
	config.set("resource_spawn_interval", maxf(float(resource_spawn_interval.value), 0.05))
	config.set("resource_respawn_fraction", configured_resource_respawn_fraction)
	config.set("resource_emergency_fraction", configured_resource_emergency_fraction)
	config.set("resource_emergency_interval", maxf(float(resource_emergency_interval.value), 0.05))
	config.set("base_temperature", clampf(float(base_temperature.value) / 100.0, 0.0, 1.0))
	config.set("base_humidity", clampf(float(base_humidity.value) / 100.0, 0.0, 1.0))
	config.set("base_food_density", clampf(float(base_food_density.value) / 100.0, 0.0, 1.0))
	config.set("temperature_variation", clampf(float(temperature_variation.value) / 100.0, 0.0, 1.0))
	config.set("humidity_variation", clampf(float(humidity_variation.value) / 100.0, 0.0, 1.0))
	config.set("food_edge_penalty", clampf(float(food_edge_penalty.value) / 100.0, 0.0, 1.0))
	config.set("mutation_chance", clampf(float(mutation_chance.value) / 100.0, 0.0, 1.0))
	config.set("mutation_strength", clampf(float(mutation_strength.value) / 100.0, 0.0, 1.0))
	config.set("presentation_mode_on_start", presentation_mode.button_pressed)

	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _back_to_main_menu() -> void:
	Engine.time_scale = DEFAULT_MENU_TIME_SCALE
	get_tree().change_scene_to_file("res://GPT/UI/MainMenu.tscn")

func _get_config() -> Node:
	return get_node_or_null("/root/SimulationConfig")
