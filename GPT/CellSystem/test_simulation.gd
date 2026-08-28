extends Node2D

## Integrated CellSystem validation scene.
## Uses CellManager for both initial population and continuous spawning.

@export var initial_cell_count: int = 12
@export var spawn_area := Rect2(60.0, 60.0, 900.0, 500.0)

@onready var cell_manager: Node = $CellManager
@onready var debug_label: Label = $Debug

func _ready() -> void:
	randomize()
	cell_manager.spawn_area = spawn_area

	for _i in range(initial_cell_count):
		cell_manager.spawn_cell()

func _process(_delta: float) -> void:
	debug_label.text = "CellSystem Simulation\nPopulation: %d" % cell_manager.get_population()

	if Input.is_action_just_pressed("ui_mitosis"):
		print("Registered cells: ", cell_manager.registered_cells.size())
