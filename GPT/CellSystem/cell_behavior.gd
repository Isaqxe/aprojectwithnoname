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

func evaluate_threat(my_strength: float, other_strength: float) -> void:
	if other_strength > my_strength:
		state = BehaviorState.FLEE
	else:
		state = BehaviorState.HUNT
