extends "res://GPT/CellSystem/simulation_cell_clean.gd"

## Optimized cell organism using CellSpatialIndex for local perception.

const SPATIAL_INDEX_GROUP := "CellSpatialIndexes"
const SPATIAL_BEHAVIOR_SCRIPT := preload("res://GPT/CellSystem/cell_behavior_spatial.gd")
var _spatial_index: Node = null

func _ready() -> void:
	if not inherited_data.is_empty():
		var inherited_species: String = String(inherited_data.get("species_id", ""))
		if not inherited_species.is_empty() and inherited_species != "default":
			species_id = inherited_species

	super._ready()

	# Replace the generic behavior node with the spatial-aware variant after
	# the parent has initialized genetics and all other organism systems.
	var old_behavior: Node = behavior
	behavior = SPATIAL_BEHAVIOR_SCRIPT.new()
	behavior.cohesion_radius = group_perception_radius
	add_child(behavior)
	_apply_behavior_genes()
	if old_behavior != null and is_instance_valid(old_behavior):
		old_behavior.queue_free()

	_spatial_index = get_tree().get_first_node_in_group(SPATIAL_INDEX_GROUP)

func _refresh_perception() -> void:
	_apply_behavior_genes()
	_target = _find_best_target()
	_resource_target = null if is_instance_valid(_target) else _find_nearest_resource()
	_cached_allies.clear()
	_cached_ally_positions.clear()
	_cached_ally_velocities.clear()
	var nearby: Array = _query_cells(group_perception_radius)
	var radius_squared: float = group_perception_radius * group_perception_radius
	for candidate in nearby:
		if candidate == self or not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		if String(candidate.get("species_id")) != String(species_id):
			continue
		var ally: CharacterBody2D = candidate as CharacterBody2D
		if global_position.distance_squared_to(ally.global_position) > radius_squared:
			continue
		_cached_allies.append(ally)
		_cached_ally_positions.append(ally.global_position)
		_cached_ally_velocities.append(ally.velocity)

func _find_best_target() -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_score: float = -INF
	for candidate in _query_cells(perception_radius):
		if candidate == self or not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		var enemy: CharacterBody2D = candidate as CharacterBody2D
		if not behavior.is_valid_enemy(self, enemy):
			continue
		if not enemy.has_method("get_cell_power"):
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > perception_radius:
			continue
		var proximity: float = 1.0 - clampf(distance / maxf(perception_radius, 0.001), 0.0, 1.0)
		var score: float = proximity * 100.0
		if score > best_score:
			best = enemy
			best_score = score
	return best

func _calculate_collective_flee_direction() -> Vector2:
	var weighted_away := Vector2.ZERO
	for candidate in _query_cells(defense_radius):
		if not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		var enemy: CharacterBody2D = candidate as CharacterBody2D
		if not behavior.is_valid_enemy(self, enemy):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance_squared: float = offset.length_squared()
		if distance_squared <= 0.001:
			continue
		var distance: float = sqrt(distance_squared)
		if distance > defense_radius:
			continue
		var proximity: float = 1.0 - clampf(distance / defense_radius, 0.0, 1.0)
		weighted_away -= offset.normalized() * proximity
	if weighted_away.length_squared() > 0.0001:
		return weighted_away.normalized()
	return _direction.normalized()

func _query_cells(radius: float) -> Array:
	if _spatial_index == null or not is_instance_valid(_spatial_index):
		_spatial_index = get_tree().get_first_node_in_group(SPATIAL_INDEX_GROUP)
	if _spatial_index != null and _spatial_index.has_method("query_circle"):
		return _spatial_index.query_circle(global_position, radius)
	return get_tree().get_nodes_in_group("SimCells")
