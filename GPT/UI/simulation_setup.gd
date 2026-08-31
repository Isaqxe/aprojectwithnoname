extends Control

## Modular simulation setup screen.
## Controls live in the .tscn; this script only transfers values to SimulationConfig.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")

@onready var auto_spawn: CheckBox = $Center/Panel/Margin/VBox/AutoSpawn
@onready var population: SpinBox = $Center/Panel/Margin/VBox/Population/Value
@onready var max_population: SpinBox = $Center/Panel/Margin/VBox/MaxPopulation/Value
@onready var resources: SpinBox = $Center/Panel/Margin/VBox/Resources/Value
@onready var max_resources: SpinBox = $Center/Panel/Margin/VBox/MaxResources/Value
@onready var radius: SpinBox = $Center/Panel/Margin/VBox/Radius/Value
@onready var start_button: Button = $Center/Panel/Margin/VBox/Buttons/Start
@onready var back_button: Button = $Center/Panel/Margin/VBox/Buttons/Back

func _ready() -> void:
	var config: Node = _get_config()
	if config != null:
		auto_spawn.button_pressed = bool(config.get("auto_spawn_cells"))
		population.value = int(config.get("initial_population"))
		max_population.value = int(config.get("max_population"))
		resources.value = int(config.get("initial_resources"))
		max_resources.value = int(config.get("max_resources"))
		radius.value = float(config.get("domain_radius"))

	start_button.pressed.connect(_start_simulation)
	back_button.pressed.connect(_back_to_main_menu)

func _start_simulation() -> void:
	var config: Node = _get_config()
	if config == null:
		return

	config.set("auto_spawn_cells", auto_spawn.button_pressed)
	config.set("initial_population", int(population.value))
	config.set("max_population", int(max_population.value))
	config.set("initial_resources", int(resources.value))
	config.set("max_resources", int(max_resources.value))
	config.set("domain_radius", float(radius.value))
	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _back_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://GPT/UI/MainMenu.tscn")

func _get_config() -> Node:
	return get_node_or_null("/root/SimulationConfig")
