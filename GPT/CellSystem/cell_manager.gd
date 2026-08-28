extends Node

## CellManager coordinates cell creation, registration and cleanup.
## It does not make individual behavioral or combat decisions.

@export var cell_factory: Node
@export var cell_container: Node2D
@export var spawn_timer: float = 5.0
var random_position: Vector2 = randf_range(Vector2(0, 0), Vector2(200, 200))

var registered_cells: Array[Node] = []

func register_cell(cell: Node) -> void:
	if cell == null or not is_instance_valid(cell):
		return
	if not registered_cells.has(cell):
		registered_cells.append(cell)

func unregister_cell(cell: Node) -> void:
	registered_cells.erase(cell)

func get_cell_count() -> int:
	_cleanup_invalid_cells()
	return registered_cells.size()

func get_population() -> int:
	return get_cell_count()

func create_cell(position: Vector2, is_player: bool = false) -> Node:
	if cell_factory == null:
		return null

	var new_cell: Node = cell_factory.create_cell(position, is_player)
	if new_cell == null:
		return null

	var parent_node: Node = cell_container if cell_container != null else self
	parent_node.add_child(new_cell)
	register_cell(new_cell)
	return new_cell

func _process(_delta: float) -> void:
	_cleanup_invalid_cells()
	spawn_timer -= 1
	if spawn_timer <= 0:
		create_cell(random_position, false)

func _cleanup_invalid_cells() -> void:
	for cell in registered_cells.duplicate():
		if not is_instance_valid(cell):
			registered_cells.erase(cell)
