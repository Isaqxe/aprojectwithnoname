extends Node

## Lightweight spatial hash for nearby-cell queries.
## Rebuilt periodically so cells do not scan the complete population.
class_name CellSpatialIndex

@export var cell_size: float = 256.0
@export var rebuild_interval: float = 0.15

var _timer: float = 0.0
var _buckets: Dictionary = {}

func _ready() -> void:
	add_to_group("CellSpatialIndexes")
	rebuild()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		rebuild()
		_timer = rebuild_interval

func rebuild() -> void:
	_buckets.clear()
	for node in get_tree().get_nodes_in_group("SimCells"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		var cell: Node2D = node as Node2D
		var key: Vector2i = _cell_key(cell.global_position)
		if not _buckets.has(key):
			_buckets[key] = []
		(_buckets[key] as Array).append(node)

func query_circle(origin: Vector2, radius: float) -> Array:
	var result: Array = []
	var safe_radius: float = maxf(radius, 0.0)
	var min_key: Vector2i = _cell_key(origin - Vector2(safe_radius, safe_radius))
	var max_key: Vector2i = _cell_key(origin + Vector2(safe_radius, safe_radius))
	var radius_squared: float = safe_radius * safe_radius

	for y in range(min_key.y, max_key.y + 1):
		for x in range(min_key.x, max_key.x + 1):
			var key := Vector2i(x, y)
			if not _buckets.has(key):
				continue
			for node in _buckets[key] as Array:
				if not is_instance_valid(node) or not node is Node2D:
					continue
				var cell: Node2D = node as Node2D
				if origin.distance_squared_to(cell.global_position) <= radius_squared:
					result.append(node)

	return result

func _cell_key(position: Vector2) -> Vector2i:
	var safe_size: float = maxf(cell_size, 1.0)
	return Vector2i(floori(position.x / safe_size), floori(position.y / safe_size))
