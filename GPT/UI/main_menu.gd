extends Control

## Main menu controller. UI is authored as scene nodes; this script only handles navigation.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")

@onready var simulation_button: Button = $MenuPanel/MenuColumn/SimulationButton
@onready var options_button: Button = $MenuPanel/MenuColumn/OptionsButton
@onready var quit_button: Button = $MenuPanel/MenuColumn/QuitButton
@onready var status_label: Label = $MenuPanel/MenuColumn/StatusLabel

func _ready() -> void:
	simulation_button.pressed.connect(_on_simulate_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_simulate_pressed() -> void:
	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _on_options_pressed() -> void:
	status_label.text = "Configurações da simulação chegarão em breve."

func _on_quit_pressed() -> void:
	get_tree().quit()
