extends Node

## Mitosis process state holder.
## The base resource cost is supplied by the organism's hereditary NEO gene.
## Repeated mitosis increases the current cost linearly.

@export var required_wander_time: float = 5.0
@export var duration: float = 3.0
@export var base_resource_cost: float = 1000.0
@export var spawn_offset: float = 30.0

var elapsed: float = 0.0
var active: bool = false
var mitosis_count: int = 0

func set_genetic_base_cost(value: float) -> void:
	base_resource_cost = maxf(value, 1.0)

func get_resource_cost() -> float:
	return base_resource_cost * float(mitosis_count + 1)

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
	var parent: Node = get_parent()
	if parent != null and is_instance_valid(parent):
		var cell_data: Node = parent.get("cell_data") as Node
		if cell_data != null and is_instance_valid(cell_data) and cell_data.has_method("start_mitosis_grace_period"):
			cell_data.start_mitosis_grace_period()
	reset()

func reset() -> void:
	elapsed = 0.0
	active = false
