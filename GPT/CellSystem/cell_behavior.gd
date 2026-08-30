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
var threat_count: int = 0
var total_threat_strength: float = 0.0

@export_category("Social Steering")
@export var cohesion_weight: float = 0.38
@export var alignment_weight: float = 0.14
@export var separation_weight: float = 1.10
@export var cohesion_radius: float = 150.0
@export var separation_radius: float = 46.0
@export var max_cohesion_allies: int = 8

@export_category("Neutrality")
@export var neutral_aggression_threshold: float = 0.30

@export_category("Collective Defense")
@export var defense_advantage: float = 1.10
@export var minimum_defenders: int = 2

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

func _get_behavior_gene(gene_name: String, fallback: float) -> float:
	var owner_cell: Node = get_parent()
	if owner_cell == null or not is_instance_valid(owner_cell):
		return fallback
	var genetics: Node = owner_cell.get("genetics") as Node
	if genetics != null and genetics.has_method("get_gene"):
		return clampf(float(genetics.get_gene(gene_name, fallback)), 0.0, 1.0)
	return fallback

func _get_species_id(cell: Node) -> String:
	if cell == null or not is_instance_valid(cell):
		return ""
	if cell.has_method("get_species_id"):
		return String(cell.get_species_id())
	return String(cell.get("species_id"))

func is_same_species(my_cell, other_cell) -> bool:
	var my_species: String = _get_species_id(my_cell)
	var other_species: String = _get_species_id(other_cell)
	return not my_species.is_empty() and my_species == other_species

func is_neutral(my_cell) -> bool:
	return _get_behavior_gene("aggression", 0.5) < neutral_aggression_threshold

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

	if my_cell.has_method("needs_food") and my_cell.needs_food():
		state = BehaviorState.SEEK_RESOURCE
		return state

	var my_strength: float = calculate_strength(my_cell)
	var other_strength: float = calculate_strength(other_cell)
	fear = other_strength - my_strength
	threat_level = clampf(fear / maxf(my_strength, 0.001), 0.0, 10.0)

	var caution: float = _get_behavior_gene("caution", 0.5)
	var aggression_gene: float = _get_behavior_gene("aggression", 0.5)
	aggression = aggression_gene
	if aggression_gene < neutral_aggression_threshold:
		state = BehaviorState.FLEE
		return state

	var flee_threshold: float = 1.0 + caution * 0.35
	var hunt_threshold: float = 1.0 - aggression_gene * 0.25

	if other_strength > my_strength * flee_threshold:
		state = BehaviorState.FLEE
	elif other_strength <= my_strength * hunt_threshold:
		state = BehaviorState.HUNT
	else:
		state = BehaviorState.FLEE
	return state

func evaluate_collective_cell(my_cell, other_cell, ally_cells: Array) -> BehaviorState:
	if my_cell == null:
		state = BehaviorState.WANDER
		fear = 0.0
		threat_level = 0.0
		return state

	if my_cell.has_method("needs_food") and my_cell.needs_food():
		state = BehaviorState.SEEK_RESOURCE
		return state

	var individual_strength: float = calculate_strength(my_cell)
	group_strength = individual_strength
	ally_count = 0
	threat_count = 0
	total_threat_strength = 0.0

	for ally in ally_cells:
		if ally == null or ally == my_cell or not is_instance_valid(ally):
			continue
		if not is_same_species(my_cell, ally):
			continue
		if "alive" in ally and not ally.alive:
			continue
		group_strength += calculate_strength(ally)
		ally_count += 1

	var perception: float = 180.0
	var owner_cell: Node = get_parent()
	if owner_cell != null and is_instance_valid(owner_cell):
		perception = maxf(float(owner_cell.get("perception_radius")), 1.0)

	var enemies: Array = []
	if owner_cell != null and is_instance_valid(owner_cell):
		if owner_cell.has_method("_query_cells"):
			for candidate in owner_cell._query_cells(perception):
				if candidate == owner_cell or not is_instance_valid(candidate):
					continue
				if not is_valid_enemy(my_cell, candidate):
					continue
				if not candidate is Node2D:
					continue
				var distance: float = owner_cell.global_position.distance_to((candidate as Node2D).global_position)
				if distance > perception:
					continue
				var proximity: float = 1.0 - clampf(distance / perception, 0.0, 1.0)
				var weighted_strength: float = calculate_strength(candidate) * maxf(proximity, 0.20)
				if weighted_strength <= 0.0:
					continue
				enemies.append(candidate)
				total_threat_strength += weighted_strength
				threat_count += 1

	if enemies.is_empty() and is_valid_enemy(my_cell, other_cell):
		total_threat_strength = calculate_strength(other_cell)
		threat_count = 1

	fear = total_threat_strength - individual_strength
	threat_level = clampf(fear / maxf(individual_strength, 0.001), 0.0, 10.0)

	var caution: float = _get_behavior_gene("caution", 0.5)
	var aggression_gene: float = _get_behavior_gene("aggression", 0.5)
	var group_response: float = _get_behavior_gene("group_response", 0.5)
	aggression = aggression_gene

	var flee_multiplier: float = 1.0 + caution * 0.35
	var collective_defense_multiplier: float = defense_advantage - group_response * 0.20
	var enough_defenders: bool = ally_count + 1 >= minimum_defenders
	var has_collective_advantage: bool = group_strength >= total_threat_strength * maxf(collective_defense_multiplier, 0.85)

	if threat_count <= 0:
		state = BehaviorState.WANDER
		return state

	if total_threat_strength > individual_strength * flee_multiplier:
		if enough_defenders and has_collective_advantage and group_response >= 0.45 and aggression_gene >= neutral_aggression_threshold:
			state = BehaviorState.HUNT
		else:
			state = BehaviorState.FLEE
	else:
		if aggression_gene < neutral_aggression_threshold:
			state = BehaviorState.FLEE
		else:
			var hunt_multiplier: float = 1.0 - aggression_gene * 0.25
			state = BehaviorState.HUNT if total_threat_strength <= individual_strength * hunt_multiplier else BehaviorState.FLEE

	return state

func evaluate_resource(my_cell) -> BehaviorState:
	if my_cell == null:
		state = BehaviorState.WANDER
		return state

	if my_cell.has_method("needs_food") and my_cell.needs_food():
		state = BehaviorState.SEEK_RESOURCE
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

	var sociality: float = _get_behavior_gene("sociality", 0.5)
	var nearby_count: int = ally_positions.size()
	var crowd_factor: float = clampf(float(max_cohesion_allies) / maxf(float(nearby_count), 1.0), 0.20, 1.0)
	var cohesion_factor: float = cohesion_weight * (0.25 + sociality * 0.55) * crowd_factor
	var alignment_factor: float = alignment_weight * (0.35 + sociality * 0.65) * crowd_factor
	var separation_factor: float = separation_weight * (1.0 + minf(float(nearby_count), 12.0) * 0.05)

	var cohesion_vector: Vector2 = Vector2.ZERO
	var separation_vector: Vector2 = Vector2.ZERO
	var alignment_vector: Vector2 = Vector2.ZERO
	var nearby_in_radius: int = 0
	var alignment_count: int = 0

	for index in range(ally_positions.size()):
		var offset: Vector2 = ally_positions[index] - origin
		var distance: float = offset.length()
		if distance <= 0.001 or distance > cohesion_radius:
			continue
		cohesion_vector += offset
		nearby_in_radius += 1
		if distance < separation_radius:
			var normalized_offset: Vector2 = offset / distance
			var closeness: float = 1.0 - clampf(distance / separation_radius, 0.0, 1.0)
			separation_vector -= normalized_offset * closeness * (1.0 + closeness)
		if index < ally_velocities.size():
			alignment_vector += ally_velocities[index]
			alignment_count += 1

	if nearby_in_radius > 0:
		cohesion_vector /= float(nearby_in_radius)
		if cohesion_vector.length_squared() > 0.0001:
			result += cohesion_vector.normalized() * cohesion_factor

	if separation_vector.length_squared() > 0.0001:
		result += separation_vector * separation_factor

	if alignment_count > 0 and alignment_vector.length_squared() > 0.001:
		alignment_vector /= float(alignment_count)
		result += alignment_vector.normalized() * alignment_factor

	return result.normalized() if result.length_squared() > 0.0001 else Vector2.ZERO
