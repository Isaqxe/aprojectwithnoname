extends Node2D

## Spawns collectible resources across the ExperimentalDomain.
## The camera affects processing/visibility, not the total spawn domain.

@export var resource_scene: PackedScene
@export var experimental_domain: Node
@export var simulation_camera: Node
@export var spawn_area: Rect2 = Rect2(-425.0, -425.0, 850.0, 850.0)
@export var initial_resources: int = 75
@export var max_resources: int = 500
@export var spawn_interval: float = 1.5
@export var minimum_spacing: float = 28.0
@export var max_spawn_attempts: int = 12

@export_category("Resource Distribution")
@export var base_spawn_multiplier: float = 1.0
@export var min_spawn_amount_multiplier: float = 0.50
@export var max_spawn_amount_multiplier: float = 1.35
@export var respawn_when_below_fraction: float = 0.70

var spawn_timer: float = 0.0
var resources: Array[Node] = []

func _ready() -> void:
	randomize()
	_resolve_nodes()
	_update_spawn_area()
	spawn_timer = spawn_interval
	for _i in range(initial_resources):
		spawn_resource()

func _process(delta: float) -> void:
	_cleanup()
	_resolve_nodes()
	_update_spawn_area()
	spawn_timer -= delta

	if spawn_timer <= 0.0 and get_resource_count() < int(float(max_resources) * 0.95):
		spawn_resource()
		spawn_timer = spawn_interval

func _resolve_nodes() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		experimental_domain = get_tree().get_first_node_in_group("ExperimentalDomains")
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		simulation_camera = get_tree().get_first_node_in_group("SimulationCameras")

func _update_spawn_area() -> void:
	if simulation_camera != null and is_instance_valid(simulation_camera) and simulation_camera.has_method("get_spawn_bounds"):
		spawn_area = simulation_camera.get_spawn_bounds()

func spawn_resource() -> Node:
	if resource_scene == null or get_resource_count() >= max_resources:
		return null

	var spawn_position: Vector2 = Vector2.INF
	var chosen_environment: Dictionary = {}

	for _attempt in range(max_spawn_attempts):
		var candidate: Vector2 = _random_domain_position()
		if not _is_position_clear(candidate):
			continue
		spawn_position = candidate
		chosen_environment = _get_environment(candidate)
		break

	if spawn_position == Vector2.INF:
		return null

	var resource_node: Node = resource_scene.instantiate()
	resource_node.global_position = spawn_position

	var food_density: float = clampf(float(chosen_environment.get("food_density", 1.0)), 0.0, 1.0)
	var amount_multiplier: float = lerpf(min_spawn_amount_multiplier, max_spawn_amount_multiplier, food_density)
	amount_multiplier *= maxf(base_spawn_multiplier, 0.0)

	if resource_node.has_method("set_amount_multiplier"):
		resource_node.set_amount_multiplier(amount_multiplier)
	elif resource_node.get("amount") != null:
		resource_node.amount = float(resource_node.get("amount")) * amount_multiplier

	add_child(resource_node)
	resources.append(resource_node)
	return resource_node

func _random_domain_position() -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("random_position"):
		return experimental_domain.random_position(8.0)
	return Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)

func _get_environment(position: Vector2) -> Dictionary:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("get_environment_at"):
		return experimental_domain.get_environment_at(position)
	return {"food_density": 1.0}

func get_resource_count() -> int:
	_cleanup()
	return resources.size()

func _is_position_clear(spawn_position: Vector2) -> bool:
	var spacing_squared: float = minimum_spacing * minimum_spacing
	for resource_node in resources:
		if not is_instance_valid(resource_node):
			continue
		if spawn_position.distance_squared_to(resource_node.global_position) < spacing_squared:
			return false
	return true

func _cleanup() -> void:
	var valid_resources: Array[Node] = []
	for resource_node in resources:
		if is_instance_valid(resource_node):
			valid_resources.append(resource_node)
	resources = valid_resources
