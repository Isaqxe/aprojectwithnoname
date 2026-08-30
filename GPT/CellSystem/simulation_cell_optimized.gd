extends "res://GPT/CellSystem/simulation_cell_clean.gd"

## Optimized cell organism using spatial indexes for local perception.
## Genetics remains the source of species identity.

const SPATIAL_INDEX_GROUP := "CellSpatialIndexes"
const RESOURCE_INDEX_GROUP := "ResourceSpatialIndexes"
const SPATIAL_BEHAVIOR_SCRIPT := preload("res://GPT/CellSystem/cell_behavior_spatial.gd")

var initial_species_id: String = ""
var _spatial_index: Node = null
var _resource_spatial_index: Node = null

func _ready() -> void:
	if not inherited_data.is_empty():
		var inherited_species: String = String(inherited_data.get("species_id", "")).strip_edges()
		if not inherited_species.is_empty() and inherited_species != "default":
			initial_species_id = inherited_species
			species_id = inherited_species
	elif species_id.strip_edges() != "":
		initial_species_id = species_id.strip_edges()

	super._ready()

	if initial_species_id.is_empty():
		initial_species_id = species_id.strip_edges()

	if behavior != null:
		remove_child(behavior)
		behavior.free()
		behavior = SPATIAL_BEHAVIOR_SCRIPT.new()
		add_child(behavior)

	_spatial_index = get_tree().get_first_node_in_group(SPATIAL_INDEX_GROUP)
	_resource_spatial_index = get_tree().get_first_node_in_group(RESOURCE_INDEX_GROUP)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if cell_data != null and is_instance_valid(cell_data) and not cell_data.alive:
		_die_as_organism()

func get_species_id() -> String:
	if genetics != null and is_instance_valid(genetics):
		var genetic_species: String = String(genetics.get("species_id")).strip_edges()
		if not genetic_species.is_empty() and genetic_species != "default":
			return genetic_species
	var current_species: String = species_id.strip_edges()
	if not current_species.is_empty() and current_species != "default":
		return current_species
	return initial_species_id

func set_species_id(value: String) -> void:
	var resolved: String = value.strip_edges()
	if resolved.is_empty() or resolved == "default":
		return
	species_id = resolved
	initial_species_id = resolved
	if cell_data != null and is_instance_valid(cell_data):
		cell_data.species_id = resolved
	if genetics != null and is_instance_valid(genetics):
		genetics.species_id = resolved

func _refresh_perception() -> void:
	_apply_behavior_genes()
	_target = _find_best_target()
	_resource_target = null if is_instance_valid(_target) else _find_nearest_resource()

	_cached_allies.clear()
	_cached_ally_positions.clear()
	_cached_ally_velocities.clear()

	var radius_squared: float = group_perception_radius * group_perception_radius
	for candidate in _query_cells(group_perception_radius):
		if candidate == self or not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		if not candidate.has_method("get_species_id"):
			continue
		var ally: CharacterBody2D = candidate as CharacterBody2D
		if ally.get_species_id() != get_species_id():
			continue
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
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > perception_radius:
			continue
		var proximity: float = 1.0 - clampf(distance / maxf(perception_radius, 0.001), 0.0, 1.0)
		var score: float = proximity * 100.0
		if score > best_score:
			best = enemy
			best_score = score
	return best

func _find_nearest_resource() -> Area2D:
	if _resource_spatial_index == null or not is_instance_valid(_resource_spatial_index):
		_resource_spatial_index = get_tree().get_first_node_in_group(RESOURCE_INDEX_GROUP)
	if _resource_spatial_index == null or not _resource_spatial_index.has_method("query_circle"):
		return super._find_nearest_resource()

	var nearest: Area2D = null
	var nearest_distance: float = resource_perception_radius
	for candidate in _resource_spatial_index.query_circle(global_position, resource_perception_radius):
		if not is_instance_valid(candidate) or not candidate is Area2D:
			continue
		var resource: Area2D = candidate as Area2D
		var distance: float = global_position.distance_to(resource.global_position)
		if distance < nearest_distance:
			nearest = resource
			nearest_distance = distance
	return nearest

func _query_cells(radius: float) -> Array:
	if _spatial_index == null or not is_instance_valid(_spatial_index):
		_spatial_index = get_tree().get_first_node_in_group(SPATIAL_INDEX_GROUP)
	if _spatial_index != null and _spatial_index.has_method("query_circle"):
		return _spatial_index.query_circle(global_position, radius)
	return get_tree().get_nodes_in_group("SimCells")

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
