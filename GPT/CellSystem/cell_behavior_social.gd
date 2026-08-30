extends Node

## Social behavior extension for Alive Cells.
## Keeps the existing CellBehavior state machine small while providing explicit
## ally/enemy validation and social steering helpers.
class_name CellBehaviorSocial

@export var cohesion_weight: float = 0.35
@export var alignment_weight: float = 0.15
@export var separation_weight: float = 0.55
@export var cohesion_radius: float = 150.0
@export var separation_radius: float = 42.0
@export var target_social_damp: float = 0.20

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

func calculate_social_steering(origin: Vector2, desired_direction: Vector2, ally_positions: Array[Vector2], ally_velocities: Array[Vector2], has_external_target: bool = false) -> Vector2:
	var result: Vector2 = desired_direction
	if ally_positions.is_empty():
		return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO

	var cohesion_factor: float = cohesion_weight
	var alignment_factor: float = alignment_weight
	if has_external_target:
		cohesion_factor *= target_social_damp
		alignment_factor *= target_social_damp

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
