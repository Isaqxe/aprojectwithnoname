extends Node

## Prototype factory used by CellManager.
## Responsible only for creating cell instances.

@export var cell_scene: PackedScene

func create_cell(position: Vector2, player_controlled: bool = false, inherited_data: Dictionary = {}, species_id: String = "") -> Node:
	if cell_scene == null:
		return null

	var new_cell := cell_scene.instantiate()
	new_cell.global_position = position
	new_cell.is_player_controlled = player_controlled

	if not inherited_data.is_empty():
		new_cell.inherited_data = inherited_data

	if not species_id.strip_edges().is_empty() and species_id.strip_edges() != "default":
		if new_cell.has_method("set_species_id"):
			new_cell.set_species_id(species_id)
		else:
			new_cell.species_id = species_id.strip_edges()

	return new_cell
