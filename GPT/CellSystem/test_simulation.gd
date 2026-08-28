extends Node2D

## Integrated CellSystem validation scene.
## Spawns organisms through CellManager and lets them hunt, flee and fight.

@export var cell_count: int = 12
@export var spawn_area := Rect2(60.0, 60.0, 900.0, 500.0)

@onready var cell_manager = $CellManager

func _ready() -> void:
	randomize()
	for _i in range(cell_count):
		cell_manager.create_cell(_random_spawn_position())

func _random_spawn_position() -> Vector2:
	return Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
