extends Node

## CellManager coordinates cell creation, registration, cleanup and spatial streaming.
## The ExperimentalDomain defines the valid laboratory-slide area.

@export var cell_factory: Node
@export var cell_container: Node2D
@export var experimental_domain: Node

@export_category("Player")
@export var spawn_player_on_ready: bool = false
@export var player_spawn_position: Vector2 = Vector2(0.0, 0.0)

@export_category("Spawning")
@export var auto_spawn: bool = true
@export var spawn_interval: float = 2.0
@export var initial_population: int = 12
@export var max_population: int = 200
@export var initial_species_count: int = 6
@export var spawn_area: Rect2 = Rect2(-425.0, -425.0, 850.0, 850.0)

@export_category("Simulation Streaming")
@export var simulation_camera: Node
@export var stream_cells_from_camera: bool = true

var spawn_timer: float = 0.0
var registered_cells: Array[Node] = []
var player_cell: Node = null
var known_species: Dictionary = {}
var species_colors: Dictionary = {}

const SPECIES_PREFIXES: Array[String] = [
	"Vel", "Zor", "Kry", "Ari", "Nex", "Vor", "Syl", "Lum", "Drav", "Qor", "Myr", "Tav"
]
const SPECIES_MIDDLES: Array[String] = [
	"a", "e", "i", "o", "u", "ae", "ia", "or", "en", "ur"
]
const SPECIES_SUFFIXES: Array[String] = [
	"is", "a", "on", "um", "ar", "en", "yx", "is", "or"
]

func _ready() -> void:
	randomize()
	add_to_group("CellManagers")
	_resolve_scene_nodes()
	_initialize_species()
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

func _process(delta: float) -> void:
	_cleanup_invalid_cells()
	_update_simulation_area()
	_update_cell_processing()
	_enforce_domain_bounds()

	if not auto_spawn or cell_factory == null or cell_container == null:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_cell()
		spawn_timer = spawn_interval

func _resolve_scene_nodes() -> void:
	if cell_factory == null:
		cell_factory = get_node_or_null("CellFactory")

	if cell_container == null:
		var parent_node: Node = get_parent()
		if parent_node != null:
			cell_container = parent_node.get_node_or_null("Cells") as Node2D

	if experimental_domain == null:
		experimental_domain = get_tree().get_first_node_in_group("ExperimentalDomains")

	if simulation_camera == null:
		simulation_camera = get_tree().get_first_node_in_group("SimulationCameras")

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
	if not known_species.has(species_id):
		known_species[species_id] = true
		species_colors[species_id] = _generate_species_color()

func get_species_ids() -> Array[String]:
	var species_ids: Array[String] = []
	for species_id in known_species.keys():
		species_ids.append(String(species_id))
	return species_ids

func get_species_color(species_id: String) -> Color:
	if species_id.is_empty():
		return Color.WHITE
	if not species_colors.has(species_id):
		register_species(species_id)
	return species_colors.get(species_id, Color.WHITE)

func _generate_species_color() -> Color:
	return Color.from_hsv(randf(), 0.60, 0.95)

func _initialize_species() -> void:
	var desired_count: int = max(initial_species_count, 1)
	for _i in range(desired_count):
		register_species(_generate_species_name())

func _generate_species_name() -> String:
	var generated_name: String = ""
	var attempts: int = 0

	while attempts < 20:
		generated_name = SPECIES_PREFIXES.pick_random() + SPECIES_MIDDLES.pick_random() + SPECIES_SUFFIXES.pick_random()
		if not known_species.has(generated_name):
			return generated_name
		attempts += 1

	return "Species_%d" % (known_species.size() + 1)

func _get_random_species_id() -> String:
	var species_ids: Array[String] = get_species_ids()
	if species_ids.is_empty():
		_initialize_species()
		species_ids = get_species_ids()
	return species_ids.pick_random()

func get_cell_count() -> int:
	_cleanup_invalid_cells()
	return registered_cells.size()

func get_population() -> int:
	return get_cell_count()

func get_player() -> Node:
	if not is_instance_valid(player_cell):
		player_cell = null
	return player_cell

func create_cell(position: Vector2, is_player: bool = false, species_id_override: String = "") -> Node:
	if cell_factory == null or not is_instance_valid(cell_factory):
		return null

	var spawn_position: Vector2 = _clamp_to_domain(position)
	var new_cell: Node = cell_factory.create_cell(spawn_position, is_player)
	if new_cell == null:
		return null

	if not species_id_override.is_empty():
		new_cell.species_id = species_id_override

	cell_container.add_child(new_cell)
	register_cell(new_cell)

	var resolved_species_id: String = String(new_cell.get("species_id"))
	if resolved_species_id.is_empty() or resolved_species_id == "default":
		resolved_species_id = _get_random_species_id()
		new_cell.species_id = resolved_species_id
	register_species(resolved_species_id)

	if new_cell.has_method("set_species_color"):
		new_cell.set_species_color(get_species_color(resolved_species_id))

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
	var child_position: Vector2 = _clamp_to_domain(position)
	var new_cell: Node = cell_factory.create_cell(child_position, false, inherited_data)
	if new_cell == null:
		return null

	cell_container.add_child(new_cell)
	register_cell(new_cell)

	var child_species_id: String = String(new_cell.get("species_id"))
	if child_species_id.is_empty():
		child_species_id = _get_random_species_id()
		new_cell.species_id = child_species_id
	register_species(child_species_id)

	if new_cell.has_method("set_species_color"):
		new_cell.set_species_color(get_species_color(child_species_id))

	return new_cell

func spawn_cell(is_player: bool = false) -> Node:
	if get_population() >= max_population:
		return null

	var spawn_position: Vector2 = _get_domain_random_position()
	if simulation_camera != null and is_instance_valid(simulation_camera) and simulation_camera.has_method("get_spawn_bounds"):
		var camera_area: Rect2 = simulation_camera.get_spawn_bounds()
		spawn_position = Vector2(
			randf_range(camera_area.position.x, camera_area.end.x),
			randf_range(camera_area.position.y, camera_area.end.y)
		)
		spawn_position = _clamp_to_domain(spawn_position, 8.0)

	return create_cell(spawn_position, is_player, _get_random_species_id())

func spawn_player(position: Vector2) -> Node:
	if is_instance_valid(player_cell):
		return player_cell
	if get_population() >= max_population:
		return null
	return create_cell(_clamp_to_domain(position, 8.0), true, _get_random_species_id())

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
	var child_position: Vector2 = _clamp_to_domain(parent_position + Vector2.from_angle(spawn_angle) * spawn_distance, parent_size)

	return create_cell_from_parent(parent_cell, child_position)

func _get_domain_random_position() -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("random_position"):
		return experimental_domain.random_position(8.0)
	return Vector2.ZERO

func _clamp_to_domain(position: Vector2, margin: float = 0.0) -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("clamp_position"):
		return experimental_domain.clamp_position(position, margin)
	return position

func _update_simulation_area() -> void:
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		simulation_camera = get_tree().get_first_node_in_group("SimulationCameras")
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		return
	if simulation_camera.has_method("get_spawn_bounds"):
		spawn_area = simulation_camera.get_spawn_bounds()

func _update_cell_processing() -> void:
	if not stream_cells_from_camera:
		return
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		return
	if not simulation_camera.has_method("get_simulation_center"):
		return

	var center: Vector2 = simulation_camera.get_simulation_center()
	var load_radius: float = simulation_camera.get_load_radius() if simulation_camera.has_method("get_load_radius") else INF
	var load_radius_squared: float = load_radius * load_radius

	for cell in registered_cells:
		if not is_instance_valid(cell):
			continue
		if cell == player_cell:
			cell.process_mode = Node.PROCESS_MODE_INHERIT
			continue
		if not cell is Node2D:
			continue

		var distance_squared: float = center.distance_squared_to((cell as Node2D).global_position)
		cell.process_mode = Node.PROCESS_MODE_INHERIT if distance_squared <= load_radius_squared else Node.PROCESS_MODE_DISABLED

func _enforce_domain_bounds() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		return
	if not experimental_domain.has_method("clamp_position"):
		return

	for cell in registered_cells:
		if not is_instance_valid(cell) or not cell is Node2D:
			continue
		var cell_node: Node2D = cell as Node2D
		cell_node.global_position = experimental_domain.clamp_position(cell_node.global_position, 4.0)

func _cleanup_invalid_cells() -> void:
	var valid_cells: Array[Node] = []

	for cell in registered_cells:
		if is_instance_valid(cell):
			valid_cells.append(cell)
		elif cell == player_cell:
			player_cell = null

	registered_cells = valid_cells
