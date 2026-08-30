extends Node

## Social behavior extension for Alive Cells.
## Provides ally/enemy validation, group steering and collective escape vectors.
class_name CellBehaviorSocial

@export var cohesion_weight: float = 0.35
@export var alignment_weight: float = 0.15
@export var separation_weight: float = 0.55
@export var cohesion_radius: float = 150.0
@export var separation_radius: float = 42.0
@export var target_social_damp: float = 0.20
@export var collective_flee_strength: float = 0.85

func is_same_species(my_cell: Node, other_cell: Node) -> bool:
	if my_cell == null or other_cell == null:
		return false
	return String(my_cell.get("species_id")) == String(other_cell.get("species_id"))

func is_valid_enemy(my_cell: Node, other_cell: Node) -> bool:
	if my_cell == null or other_cell == null or my_cell == other_cell:
		return false
	if is_same_species(my_cell, other_cell):
		return false
	var other_data: Node = other_cell.get("cell_data") as Node
	if other_data != null and not bool(other_data.get("alive")):
		return false
	return true

func evaluate_target(my_cell: Node, other_cell: Node, fear_system: Node) -> String:
	if not is_valid_enemy(my_cell, other_cell):
		return "ALLY"
	if fear_system == null:
		return "FLEE"
	return String(fear_system.evaluate(my_cell.get("cell_data"), other_cell.get("cell_data")))

func _get_behavior_gene(gene_name: String, fallback: float) -> float:
	var owner_cell: Node = get_parent()
	if owner_cell == null or not is_instance_valid(owner_cell):
		return fallback
	var genetics: Node = owner_cell.get("genetics") as Node
	if genetics != null and genetics.has_method("get_gene"):
		return clampf(float(genetics.get_gene(gene_name, fallback)), 0.0, 1.0)
	return fallback

func calculate_social_steering(origin: Vector2, desired_direction: Vector2, ally_positions: Array[Vector2], ally_velocities: Array[Vector2], has_external_target: bool = false) -> Vector2:
	var result: Vector2 = desired_direction
	var sociality: float = _get_behavior_gene("sociality", 0.5)
	var aggression: float = _get_behavior_gene("aggression", 0.5)
	var caution: float = _get_behavior_gene("caution", 0.5)

	if has_external_target and caution > 0.5:
		var collective_flee: Vector2 = _get_collective_flee_vector(origin)
		if collective_flee.length_squared() > 0.0001:
			var flee_blend: float = lerpf(collective_flee_strength, 1.0, (caution - 0.5) * 2.0)
			result = result.lerp(collective_flee, flee_blend) if _parent_is_fleeing() else result

	if ally_positions.is_empty():
		return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO

	var cohesion_factor: float = cohesion_weight * (0.25 + sociality * 0.75)
	var alignment_factor: float = alignment_weight * (0.25 + sociality * 0.75)
	var target_damp: float = target_social_damp * (0.50 + aggression * 0.50)
	if has_external_target:
		cohesion_factor *= target_damp
		alignment_factor *= target_damp

	var cohesion := Vector2.ZERO
	var separation := Vector2.ZERO
	var alignment := Vector2.ZERO
	var nearby_count: int = 0
	var alignment_count: int = 0

	for index in range(ally_positions.size()):
		var offset: Vector2 = ally_positions[index] - origin
		var distance: float = offset.length()
		if distance <= 0.001 or distance > cohesion_radius:
			continue

		cohesion += offset
		nearby_count += 1

		if distance < separation_radius:
			var closeness: float = 1.0 - clampf(distance / separation_radius, 0.0, 1.0)
			separation -= (offset / distance) * closeness

		if index < ally_velocities.size():
			alignment += ally_velocities[index]
			alignment_count += 1

	if nearby_count > 0:
		cohesion /= float(nearby_count)
		if cohesion.length_squared() > 0.0001:
			result += cohesion.normalized() * cohesion_factor

	if separation.length_squared() > 0.0001:
		result += separation * separation_weight

	if alignment_count > 0:
		alignment /= float(alignment_count)
		if alignment.length_squared() > 0.0001:
			result += alignment.normalized() * alignment_factor

	return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO

func _parent_is_fleeing() -> bool:
	var owner_cell: Node = get_parent()
	if owner_cell == null or not is_instance_valid(owner_cell):
		return false
	var parent_behavior: Node = owner_cell.get("behavior") as Node
	if parent_behavior == null:
		return false
	return int(parent_behavior.get("state")) == 3

func _get_collective_flee_vector(origin: Vector2) -> Vector2:
	var owner_cell: Node = get_parent()
	if owner_cell == null or not is_instance_valid(owner_cell):
		return Vector2.ZERO

	var perception_radius: float = maxf(float(owner_cell.get("perception_radius")), 1.0)
	var escape_vector := Vector2.ZERO

	for candidate in owner_cell.get_tree().get_nodes_in_group("SimCells"):
		if candidate == owner_cell or not is_instance_valid(candidate):
			continue
		if not is_valid_enemy(owner_cell, candidate):
			continue
		if not candidate is Node2D:
			continue

		var offset: Vector2 = (candidate as Node2D).global_position - origin
		var distance: float = offset.length()
		if distance <= 0.001 or distance > perception_radius:
			continue

		var proximity: float = 1.0 - clampf(distance / perception_radius, 0.0, 1.0)
		escape_vector -= (offset / distance) * proximity

	if escape_vector.length_squared() <= 0.0001:
		return Vector2.ZERO
	return escape_vector.normalized()
