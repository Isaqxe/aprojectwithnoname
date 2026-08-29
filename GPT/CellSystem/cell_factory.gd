extends Node

## Prototype factory used by CellManager.
## Responsible only for creating cell instances.

@export var cell_scene: PackedScene

func create_cell(position: Vector2, player_controlled: bool = false, inherited_data: Dictionary = {}) -> Node:
	if cell_scene == null:
		return null

	var new_cell := cell_scene.instantiate()
	new_cell.global_position = position
	new_cell.is_player_controlled = player_controlled

	if not inherited_data.is_empty():
		new_cell.inherited_data = inherited_data

	return new_cell
