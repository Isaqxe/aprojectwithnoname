extends Node

## Behavior state machine for Alive Cells.
## Decisions stay separate from movement, resources, combat and reproduction.

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

func evaluate_cell(my_cell, other_cell) -> BehaviorState:
	if my_cell == null or other_cell == null:
		state = BehaviorState.WANDER
		fear = 0.0
		return state

	var my_strength: float = calculate_strength(my_cell)
	var other_strength: float = calculate_strength(other_cell)

	fear = other_strength - my_strength

	if other_strength > my_strength:
		state = BehaviorState.FLEE
	else:
		state = BehaviorState.HUNT

	return state

func evaluate_resource(my_cell) -> BehaviorState:
	if my_cell == null:
		state = BehaviorState.WANDER
		return state

	if my_cell.has_method("can_accept_resources"):
		if my_cell.can_accept_resources():
			state = BehaviorState.SEEK_RESOURCE
		else:
			state = BehaviorState.WANDER
		return state

	var current_resources: float = float(my_cell.resources)
	var capacity: float = maxf(float(my_cell.resource_capacity), 0.001)

	if current_resources < capacity:
		state = BehaviorState.SEEK_RESOURCE
	else:
		state = BehaviorState.WANDER

	return state
