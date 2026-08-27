extends Node2D

## First visual validation layer.
## Currently validates creation and attributes only.
## AI, hunting, fear and combat loops are not connected yet.

@export var cell_count := 10

func _ready() -> void:
	for i in range(cell_count):
		spawn_test_cell()

func spawn_test_cell() -> void:
	var cell = preload("res://GPT/CellSystem/simulation_cell.gd").new()
	$Cells.add_child(cell)
	cell.position = Vector2(randf_range(50, 500), randf_range(50, 300))
	cell.setup({})
	cell.queue_redraw()
