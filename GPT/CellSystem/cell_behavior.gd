extends Node

## Prototype behavior layer for Alive Cells.
## Keeps decisions separate from the organism itself.

class_name CellBehavior

enum BehaviorState {
	WANDER,
	HUNT,
	FLEE
}

var state: BehaviorState = BehaviorState.WANDER

var fear: float = 0.0
var aggression: float = 0.0

func set_state(new_state: BehaviorState) -> void:
	state = new_state

func calculate_strength(cell) -> float:
	if cell == null:
		return 0.0

	return cell.health + cell.damage + cell.speed + cell.size

func evaluate_cell(my_cell, other_cell) -> void:
	if my_cell == null or other_cell == null:
		state = BehaviorState.WANDER
		return

	var my_strength = calculate_strength(my_cell)
	var other_strength = calculate_strength(other_cell)

	fear = other_strength - my_strength

	if other_strength > my_strength:
		state = BehaviorState.FLEE
	else:
		state = BehaviorState.HUNT
