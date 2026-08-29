extends Node

## Mitosis process state holder.
## The resource cost grows exponentially with the organism's mitosis count.

@export var required_wander_time: float = 5.0
@export var duration: float = 3.0
@export var base_resource_cost: float = 100.0
@export var cost_growth_multiplier: float = 2.0
@export var spawn_offset: float = 30.0

var elapsed: float = 0.0
var active: bool = false
var mitosis_count: int = 0

func get_resource_cost() -> float:
	return base_resource_cost * pow(cost_growth_multiplier, float(mitosis_count))

func start() -> void:
	elapsed = 0.0
	active = true

func update(delta: float) -> bool:
	if not active:
		return false

	elapsed += delta
	if elapsed >= duration:
		active = false
		return true

	return false

func complete_generation() -> void:
	mitosis_count += 1
	reset()

func reset() -> void:
	elapsed = 0.0
	active = false
