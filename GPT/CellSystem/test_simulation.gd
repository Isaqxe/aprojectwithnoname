extends Node2D

## Integrated CellSystem validation scene.
## CellManager owns initial and continuous spawning.
## Space spawns the player cell at world position (0, 0) for debugging.

@export var spawn_area: Rect2 = Rect2(60.0, 60.0, 900.0, 500.0)

@onready var cell_manager: Node = $CellManager
@onready var debug_label: Label = $Debug

func _ready() -> void:
	cell_manager.spawn_area = spawn_area

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	debug_label.text = "CellSystem Simulation\nPopulation: %d\nPlayer: %s" % [cell_manager.get_population(), "Spawned" if cell_manager.get_player() != null else "Not spawned"]
