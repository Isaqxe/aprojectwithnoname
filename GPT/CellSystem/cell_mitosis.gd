extends Node

## Mitosis process state holder.
## This prototype only tracks the reproduction timer and configuration.

@export var required_resources: float = 100.0
@export var required_wander_time: float = 5.0
@export var duration: float = 3.0
@export var resource_cost: float = 100.0
@export var spawn_offset: float = 30.0

var elapsed: float = 0.0
var active: bool = false

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

func reset() -> void:
	elapsed = 0.0
	active = false
