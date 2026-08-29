extends Node2D

## Spawns collectible resources for the CellSystem test ecosystem.
## Keeps resources spatially distributed instead of allowing dense piles.

@export var resource_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(60.0, 60.0, 900.0, 500.0)
@export var initial_resources: int = 25
@export var max_resources: int = 50
@export var spawn_interval: float = 1.5
@export var minimum_spacing: float = 28.0
@export var max_spawn_attempts: int = 12

var spawn_timer: float = 0.0
var resources: Array[Node] = []

func _ready() -> void:
	randomize()
	spawn_timer = spawn_interval
	for _i in range(initial_resources):
		spawn_resource()

func _process(delta: float) -> void:
	_cleanup()
	spawn_timer -= delta

	if spawn_timer <= 0.0:
		spawn_resource()
		spawn_timer = spawn_interval

func spawn_resource() -> Node:
	if resource_scene == null or get_resource_count() >= max_resources:
		return null

	var spawn_position: Vector2 = _find_spawn_position()
	if spawn_position == Vector2.INF:
		return null

	var resource_node: Node = resource_scene.instantiate()
	resource_node.global_position = spawn_position
	add_child(resource_node)
	resources.append(resource_node)
	return resource_node

func get_resource_count() -> int:
	_cleanup()
	return resources.size()

func _find_spawn_position() -> Vector2:
	for _attempt in range(max_spawn_attempts):
		var candidate: Vector2 = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)

		if _is_position_clear(candidate):
			return candidate

	return Vector2.INF

func _is_position_clear(spawn_position: Vector2) -> bool:
	for resource_node in resources:
		if not is_instance_valid(resource_node):
			continue

		if spawn_position.distance_to(resource_node.global_position) < minimum_spacing:
			return false

	return true

func _cleanup() -> void:
	var valid_resources: Array[Node] = []
	for resource_node in resources:
		if is_instance_valid(resource_node):
			valid_resources.append(resource_node)
	resources = valid_resources
