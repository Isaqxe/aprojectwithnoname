extends Node

## CellManager coordinates all cell creation, registration, spawning and cleanup.
## The player is still a normal cell; this manager only keeps a reference to it.

@export var cell_factory: Node
@export var cell_container: Node2D

@export_category("Player")
@export var spawn_player_on_ready: bool = false
@export var player_spawn_position: Vector2 = Vector2(500.0, 300.0)

@export_category("Spawning")
@export var auto_spawn: bool = true
@export var spawn_interval: float = 2.0
@export var initial_population: int = 12
@export var max_population: int = 30
@export var spawn_area: Rect2 = Rect2(60.0, 60.0, 900.0, 500.0)

var spawn_timer: float = 0.0
var registered_cells: Array[Node] = []
var player_cell: Node = null
var known_species: Dictionary = {}

func _ready() -> void:
	randomize()
	add_to_group("CellManagers")

	if cell_factory == null:
		cell_factory = get_node_or_null("CellFactory")

	if cell_container == null:
		var parent_node: Node = get_parent()
		if parent_node != null:
			cell_container = parent_node.get_node_or_null("Cells") as Node2D

	spawn_timer = spawn_interval

	if cell_factory == null:
		push_error("CellManager: CellFactory not found. Cells cannot spawn.")
		return

	if cell_container == null:
		push_error("CellManager: Cells container not found. Cells cannot spawn.")
		return

	for _i in range(initial_population):
		spawn_cell()

	if spawn_player_on_ready:
		spawn_player(player_spawn_position)

func register_cell(cell: Node) -> void:
	if cell == null or not is_instance_valid(cell):
		return
	if not registered_cells.has(cell):
		registered_cells.append(cell)

func unregister_cell(cell: Node) -> void:
	if is_instance_valid(cell):
		registered_cells.erase(cell)

	if player_cell == cell:
		player_cell = null

func register_species(species_id: String) -> void:
	if species_id.is_empty():
		return
	known_species[species_id] = true

func get_species_ids() -> Array[String]:
	var species_ids: Array[String] = []
	for species_id in known_species.keys():
		species_ids.append(String(species_id))
	return species_ids

func get_cell_count() -> int:
	_cleanup_invalid_cells()
	return registered_cells.size()

func get_population() -> int:
	return get_cell_count()

func get_player() -> Node:
	if not is_instance_valid(player_cell):
		player_cell = null
	return player_cell

func create_cell(position: Vector2, is_player: bool = false) -> Node:
	if cell_factory == null or not is_instance_valid(cell_factory):
		return null

	var new_cell: Node = cell_factory.create_cell(position, is_player)
	if new_cell == null:
		return null

	cell_container.add_child(new_cell)
	register_cell(new_cell)

	var species_id: String = String(new_cell.get("species_id"))
	if species_id.is_empty():
		species_id = "default"
	register_species(species_id)

	if is_player:
		player_cell = new_cell

	return new_cell

func create_cell_from_parent(parent_cell: Node, position: Vector2 = Vector2.ZERO) -> Node:
	if parent_cell == null or not is_instance_valid(parent_cell):
		return null
	if not parent_cell.has_method("get_heredity_data"):
		return null
	if get_population() >= max_population:
		return null

	var inherited_data: Dictionary = parent_cell.get_heredity_data()
	var new_cell: Node = cell_factory.create_cell(position, false, inherited_data)
	if new_cell == null:
		return null

	cell_container.add_child(new_cell)
	register_cell(new_cell)

	var species_id: String = String(new_cell.get("species_id"))
	if species_id.is_empty():
		species_id = "default"
	register_species(species_id)

	return new_cell

func spawn_cell(is_player: bool = false) -> Node:
	if get_population() >= max_population:
		return null

	var spawn_position: Vector2 = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)

	return create_cell(spawn_position, is_player)

func spawn_player(position: Vector2) -> Node:
	if is_instance_valid(player_cell):
		return player_cell

	if get_population() >= max_population:
		return null

	return create_cell(position, true)

func spawn_mitosis_child(parent_cell: Node) -> Node:
	if parent_cell == null or not is_instance_valid(parent_cell):
		return null
	if get_population() >= max_population:
		return null

	var parent_data = parent_cell.get("cell_data")
	if parent_data == null:
		return null

	var parent_position: Vector2 = parent_cell.global_position
	var parent_size: float = float(parent_data.size)
	var spawn_angle: float = randf_range(0.0, TAU)
	var spawn_distance: float = parent_size + 30.0
	var child_position: Vector2 = parent_position + Vector2.from_angle(spawn_angle) * spawn_distance

	return create_cell_from_parent(parent_cell, child_position)

func _process(delta: float) -> void:
	_cleanup_invalid_cells()

	if not auto_spawn or cell_factory == null or cell_container == null:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_cell()
		spawn_timer = spawn_interval

func _cleanup_invalid_cells() -> void:
	var valid_cells: Array[Node] = []

	for cell in registered_cells:
		if is_instance_valid(cell):
			valid_cells.append(cell)
		elif cell == player_cell:
			player_cell = null

	registered_cells = valid_cells
