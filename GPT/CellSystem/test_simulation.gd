extends Node2D

## Integrated CellSystem validation scene.
## CellManager owns initial and continuous spawning.
## Space spawns the player cell at world position (0, 0) for debugging.

@export var spawn_area: Rect2 = Rect2(-450.0, -300.0, 900.0, 600.0)

@onready var cell_manager: Node = $CellManager
@onready var resource_spawner: Node2D = $ResourceSpawner
@onready var debug_label: Label = $Debug

func _ready() -> void:
	cell_manager.spawn_area = spawn_area
	resource_spawner.spawn_area = spawn_area

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	debug_label.text = "CellSystem Simulation\nPopulation: %d\nPlayer: %s" % [cell_manager.get_population(), "Spawned" if cell_manager.get_player() != null else "Not spawned"]
