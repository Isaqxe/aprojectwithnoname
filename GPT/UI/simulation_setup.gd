extends Control

## Modular simulation setup screen.
## Controls live in the .tscn; this script only transfers values to SimulationConfig.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")
const DEFAULT_MENU_TIME_SCALE: float = 1.0

@onready var auto_spawn: CheckBox = $Center/Panel/Margin/VBox/AutoSpawn
@onready var population: SpinBox = $Center/Panel/Margin/VBox/Population/Value
@onready var max_population: SpinBox = $Center/Panel/Margin/VBox/MaxPopulation/Value
@onready var resources: SpinBox = $Center/Panel/Margin/VBox/Resources/Value
@onready var max_resources: SpinBox = $Center/Panel/Margin/VBox/MaxResources/Value
@onready var radius: SpinBox = $Center/Panel/Margin/VBox/Radius/Value
@onready var initial_time_scale: SpinBox = $Center/Panel/Margin/VBox/InitialTimeScale/Value
@onready var presentation_mode: CheckBox = $Center/Panel/Margin/VBox/PresentationMode
@onready var start_button: Button = $Center/Panel/Margin/VBox/Buttons/Start
@onready var back_button: Button = $Center/Panel/Margin/VBox/Buttons/Back

func _ready() -> void:
	Engine.time_scale = DEFAULT_MENU_TIME_SCALE
	var config: Node = _get_config()
	if config != null:
		auto_spawn.button_pressed = bool(config.get("auto_spawn_cells"))
		population.value = int(config.get("initial_population"))
		max_population.value = maxi(int(config.get("max_population")), int(population.value))
		resources.value = int(config.get("initial_resources"))
		max_resources.value = maxi(int(config.get("max_resources")), int(resources.value))
		radius.value = float(config.get("domain_radius"))
		initial_time_scale.value = clampf(float(config.get("initial_time_scale")), 0.25, 32.0)
		presentation_mode.button_pressed = bool(config.get("presentation_mode_on_start"))

	start_button.pressed.connect(_start_simulation)
	back_button.pressed.connect(_back_to_main_menu)

func _start_simulation() -> void:
	var config: Node = _get_config()
	if config == null:
		return

	var initial_population: int = maxi(int(population.value), 1)
	var configured_max_population: int = maxi(int(max_population.value), initial_population)
	var initial_resources: int = maxi(int(resources.value), 0)
	var configured_max_resources: int = maxi(int(max_resources.value), initial_resources)

	max_population.value = configured_max_population
	max_resources.value = configured_max_resources

	config.set("auto_spawn_cells", auto_spawn.button_pressed)
	config.set("initial_population", initial_population)
	config.set("max_population", configured_max_population)
	config.set("initial_resources", initial_resources)
	config.set("max_resources", configured_max_resources)
	config.set("domain_radius", maxf(float(radius.value), 500.0))
	config.set("initial_time_scale", clampf(float(initial_time_scale.value), 0.25, 32.0))
	config.set("presentation_mode_on_start", presentation_mode.button_pressed)
	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _back_to_main_menu() -> void:
	Engine.time_scale = DEFAULT_MENU_TIME_SCALE
	get_tree().change_scene_to_file("res://GPT/UI/MainMenu.tscn")

func _get_config() -> Node:
	return get_node_or_null("/root/SimulationConfig")
