extends Node

## CellManager coordinates cell creation, registration, spawning and cleanup.
## It does not make individual behavioral or combat decisions.

@export var cell_factory: Node
@export var cell_container: Node2D

@export_category("Spawning")
@export var auto_spawn: bool = true
@export var spawn_interval: float = 2.0
@export var initial_population: int = 12
@export var max_population: int = 30
@export var spawn_area: Rect2 = Rect2(60.0, 60.0, 900.0, 500.0)

var spawn_timer: float = 0.0
var registered_cells: Array[Node] = []

func _ready() -> void:
	randomize()
	spawn_timer = spawn_interval
	for _i in range(initial_population):
		spawn_cell()

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

func spawn_cell(is_player: bool = false) -> Node:
	if get_population() >= max_population:
		return null

	var spawn_position: Vector2 = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)

	return create_cell(spawn_position, is_player)

func _process(delta: float) -> void:
	_cleanup_invalid_cells()

	if not auto_spawn:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_cell()
		spawn_timer = spawn_interval

func _cleanup_invalid_cells() -> void:
	for cell in registered_cells.duplicate():
		if not is_instance_valid(cell):
			registered_cells.erase(cell)
