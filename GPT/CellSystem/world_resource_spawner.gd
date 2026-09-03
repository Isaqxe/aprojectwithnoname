extends Node2D

## Spawns collectible resources across the ExperimentalDomain.
## The camera affects processing/visibility, not the total spawn domain.

@export var resource_scene: PackedScene
@export var experimental_domain: Node
@export var simulation_camera: Node
@export var spawn_area: Rect2 = Rect2(-425.0, -425.0, 850.0, 850.0)
@export var initial_resources: int = 140
@export var max_resources: int = 500
@export var spawn_interval: float = 0.75
@export var minimum_spacing: float = 28.0
@export var max_spawn_attempts: int = 12

@export_category("Resource Distribution")
@export var base_spawn_multiplier: float = 1.15
@export var min_spawn_amount_multiplier: float = 0.75
@export var max_spawn_amount_multiplier: float = 1.60
@export var respawn_when_below_fraction: float = 0.60
@export var emergency_spawn_fraction: float = 0.25
@export var emergency_spawn_interval: float = 0.30

@export_category("Death Drops")
@export var death_drop_max_per_node: float = 1000.0
@export var death_drop_min_spacing: float = 28.0
@export var death_drop_max_attempts: int = 12

var spawn_timer: float = 0.0
var resources: Array[Node] = []

func _ready() -> void:
	randomize()
	add_to_group("ResourceSpawners")
	_resolve_nodes()
	_apply_simulation_config()
	_update_spawn_area()
	spawn_timer = spawn_interval
	for _i in range(initial_resources):
		spawn_resource()

func _process(delta: float) -> void:
	_cleanup()
	_resolve_nodes()
	_update_spawn_area()
	spawn_timer -= delta

	var count: int = resources.size()
	var emergency_threshold: int = maxi(1, int(float(max_resources) * emergency_spawn_fraction))
	var normal_threshold: int = maxi(emergency_threshold, int(float(max_resources) * respawn_when_below_fraction))

	if count < emergency_threshold:
		if spawn_timer <= 0.0:
			spawn_resource()
			spawn_timer = emergency_spawn_interval
		return

	if count < normal_threshold and spawn_timer <= 0.0:
		spawn_resource()
		spawn_timer = spawn_interval

func _resolve_nodes() -> void:
	if experimental_domain == null or not is_instance_valid(experimental_domain):
		experimental_domain = get_tree().get_first_node_in_group("ExperimentalDomains")
	if simulation_camera == null or not is_instance_valid(simulation_camera):
		simulation_camera = get_tree().get_first_node_in_group("SimulationCameras")

func _apply_simulation_config() -> void:
	var config: Node = get_node_or_null("/root/SimulationConfig")
	if config == null:
		return
	initial_resources = int(config.get("initial_resources"))
	max_resources = int(config.get("max_resources"))

func _update_spawn_area() -> void:
	## Intentionally does not copy camera bounds.
	## Resources belong to the whole experimental domain.
	return

func spawn_resource() -> Node:
	if resource_scene == null or resources.size() >= max_resources:
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

## Converts stored cellular energy into collectible resource piles after death.
## The first pile is placed at the death site, while overflow is redistributed
## across random valid positions in the experimental domain.
func spawn_death_drop(death_position: Vector2, stored_energy: float) -> int:
	var remaining_energy: float = maxf(stored_energy, 0.0)
	var pile_limit: float = maxf(death_drop_max_per_node, 1.0)
	if remaining_energy <= 0.0 or resource_scene == null:
		return 0

	var spawned_count: int = 0
	var first_pile: float = minf(remaining_energy, pile_limit)
	var death_site: Vector2 = _clamp_to_domain(death_position, 8.0)
	if _spawn_resource_pile(death_site, first_pile, death_drop_min_spacing):
		spawned_count += 1
		remaining_energy -= first_pile

	while remaining_energy > 0.0:
		var pile_amount: float = minf(remaining_energy, pile_limit)
		var random_position: Vector2 = Vector2.INF
		for _attempt in range(maxi(death_drop_max_attempts, 1)):
			var candidate: Vector2 = _random_domain_position()
			if _is_death_drop_position_clear(candidate):
				random_position = candidate
				break

		if random_position == Vector2.INF:
			## The domain is too crowded to find another separated pile safely.
			## Preserve the remaining energy instead of silently discarding it.
			break

		if not _spawn_resource_pile(random_position, pile_amount, death_drop_min_spacing):
			break
		spawned_count += 1
		remaining_energy -= pile_amount

	return spawned_count

func _spawn_resource_pile(spawn_position: Vector2, pile_amount: float, spacing: float) -> bool:
	if resource_scene == null or pile_amount <= 0.0:
		return false
	if not _is_death_drop_position_clear(spawn_position, spacing):
		return false

	var resource_node: Node = resource_scene.instantiate()
	resource_node.global_position = spawn_position
	if resource_node.get("amount") != null:
		resource_node.amount = pile_amount
	else:
		resource_node.queue_free()
		return false

	add_child(resource_node)
	resources.append(resource_node)
	return true

func _is_death_drop_position_clear(spawn_position: Vector2, spacing: float = -1.0) -> bool:
	var effective_spacing: float = death_drop_min_spacing if spacing <= 0.0 else spacing
	var spacing_squared: float = effective_spacing * effective_spacing
	for resource_node in resources:
		if not is_instance_valid(resource_node):
			continue
		if spawn_position.distance_squared_to(resource_node.global_position) < spacing_squared:
			return false
	return true

func _random_domain_position() -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("random_position"):
		return experimental_domain.random_position(8.0)
	return Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)

func _clamp_to_domain(world_position: Vector2, margin: float = 0.0) -> Vector2:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("clamp_position"):
		return experimental_domain.clamp_position(world_position, margin)
	return world_position

func _get_environment(environment_position: Vector2) -> Dictionary:
	if experimental_domain != null and is_instance_valid(experimental_domain) and experimental_domain.has_method("get_environment_at"):
		return experimental_domain.get_environment_at(environment_position)
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
