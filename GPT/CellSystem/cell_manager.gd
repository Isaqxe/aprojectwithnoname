extends Node

## CellManager prototype.
## Controls the existence and lifecycle of cells.
## Does not control individual cell behavior.

@export var cell_factory: Node

var registered_cells: Array[Node] = []


func register_cell(cell: Node) -> void:
	if cell == null:
		return

	if not registered_cells.has(cell):
		registered_cells.append(cell)


func unregister_cell(cell: Node) -> void:
	registered_cells.erase(cell)


func get_cell_count() -> int:
	return registered_cells.size()


func create_cell(position: Vector2, is_player: bool = false):
	if cell_factory == null:
		return null

	var new_cell = cell_factory.create_cell(position, is_player)

	if new_cell != null:
		add_child(new_cell)
		register_cell(new_cell)

	return new_cell


func get_population() -> int:
	return registered_cells.size()


func _process(_delta: float) -> void:
	_cleanup_invalid_cells()


func _cleanup_invalid_cells() -> void:
	for cell in registered_cells.duplicate():
		if not is_instance_valid(cell):
			registered_cells.erase(cell)
