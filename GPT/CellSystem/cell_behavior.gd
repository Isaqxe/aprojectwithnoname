extends Node

## Behavior state machine for Alive Cells.
## Decisions stay separate from movement, resources, combat and reproduction.
## Group behavior is represented as steering influences instead of extra states.

class_name CellBehavior

enum BehaviorState {
	WANDER,
	SEEK_RESOURCE,
	HUNT,
	FLEE,
	MITOSIS
}

var state: BehaviorState = BehaviorState.WANDER
var fear: float = 0.0
var aggression: float = 0.0
var threat_level: float = 0.0
var group_strength: float = 0.0
var ally_count: int = 0

@export_category("Social Steering")
@export var cohesion_weight: float = 0.55
@export var alignment_weight: float = 0.20
@export var separation_weight: float = 0.70
@export var cohesion_radius: float = 150.0
@export var separation_radius: float = 42.0

@export_category("Collective Defense")
@export var defense_advantage: float = 1.10
@export var minimum_defenders: int = 2
@export var threat_memory: float = 0.75

func set_state(new_state: BehaviorState) -> void:
	state = new_state

func calculate_strength(cell) -> float:
	if cell == null:
		return 0.0

	var strength: float = 0.0
	if "health" in cell:
		strength += cell.health
	if "damage" in cell:
		strength += cell.damage
	if "speed" in cell:
		strength += cell.speed
	if "size" in cell:
		strength += cell.size
	return strength

func is_same_species(my_cell, other_cell) -> bool:
	if my_cell == null or other_cell == null:
		return false
	return String(my_cell.get("species_id")) == String(other_cell.get("species_id"))

func is_valid_enemy(my_cell, other_cell) -> bool:
	if my_cell == null or other_cell == null or my_cell == other_cell:
		return false
	if is_same_species(my_cell, other_cell):
		return false
	if "alive" in other_cell and not other_cell.alive:
		return false
	return true

func evaluate_cell(my_cell, other_cell) -> BehaviorState:
	if not is_valid_enemy(my_cell, other_cell):
		state = BehaviorState.WANDER
		fear = 0.0
		threat_level = 0.0
		return state

	var my_strength: float = calculate_strength(my_cell)
	var other_strength: float = calculate_strength(other_cell)
	fear = other_strength - my_strength
	threat_level = clampf(fear / maxf(my_strength, 0.001), 0.0, 10.0)

	if other_strength > my_strength:
		state = BehaviorState.FLEE
	else:
		state = BehaviorState.HUNT
	return state

func evaluate_collective_cell(my_cell, other_cell, ally_cells: Array) -> BehaviorState:
	if not is_valid_enemy(my_cell, other_cell):
		state = BehaviorState.WANDER
		fear = 0.0
		threat_level = 0.0
		group_strength = calculate_strength(my_cell)
		ally_count = 0
		return state

	var individual_strength: float = calculate_strength(my_cell)
	var threat_strength: float = calculate_strength(other_cell)
	group_strength = individual_strength
	ally_count = 0

	for ally in ally_cells:
		if ally == null or ally == my_cell or not is_instance_valid(ally):
			continue
		if not is_same_species(my_cell, ally):
			continue
		if "alive" in ally and not ally.alive:
			continue
		group_strength += calculate_strength(ally)
		ally_count += 1

	fear = threat_strength - individual_strength
	threat_level = clampf(fear / maxf(individual_strength, 0.001), 0.0, 10.0)

	var enough_defenders: bool = ally_count + 1 >= minimum_defenders
	var collective_advantage: bool = group_strength >= threat_strength * defense_advantage

	if threat_strength > individual_strength and not (enough_defenders and collective_advantage):
		state = BehaviorState.FLEE
	else:
		state = BehaviorState.HUNT

	return state

func evaluate_resource(my_cell) -> BehaviorState:
	if my_cell == null:
		state = BehaviorState.WANDER
		return state

	if my_cell.has_method("can_accept_resources"):
		state = BehaviorState.SEEK_RESOURCE if my_cell.can_accept_resources() else BehaviorState.WANDER
		return state

	var current_resources: float = float(my_cell.resources)
	var capacity: float = maxf(float(my_cell.resource_capacity), 0.001)
	state = BehaviorState.SEEK_RESOURCE if current_resources < capacity else BehaviorState.WANDER
	return state

func calculate_social_steering(origin: Vector2, desired_direction: Vector2, ally_positions: Array[Vector2], ally_velocities: Array[Vector2]) -> Vector2:
	var result: Vector2 = desired_direction
	if ally_positions.is_empty():
		return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO

	var cohesion_vector := Vector2.ZERO
	var separation_vector := Vector2.ZERO
	var alignment_vector := Vector2.ZERO
	var nearby_count: int = 0
	var alignment_count: int = 0

	for index in range(ally_positions.size()):
		var offset: Vector2 = ally_positions[index] - origin
		var distance: float = offset.length()
		if distance <= 0.001 or distance > cohesion_radius:
			continue

		cohesion_vector += offset
		nearby_count += 1

		if distance < separation_radius:
			var normalized_offset: Vector2 = offset / distance
			var closeness: float = 1.0 - clampf(distance / separation_radius, 0.0, 1.0)
			separation_vector -= normalized_offset * closeness

		if index < ally_velocities.size():
			alignment_vector += ally_velocities[index]
			alignment_count += 1

	if nearby_count > 0:
		cohesion_vector /= float(nearby_count)
		if cohesion_vector.length_squared() > 0.0001:
			result += cohesion_vector.normalized() * cohesion_weight

	if separation_vector.length_squared() > 0.0001:
		result += separation_vector * separation_weight

	if alignment_count > 0 and alignment_vector.length_squared() > 0.001:
		alignment_vector /= float(alignment_count)
		result += alignment_vector.normalized() * alignment_weight

	return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO
