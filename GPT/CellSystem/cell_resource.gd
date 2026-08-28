extends Node

## Resource carried by a cell.
## The value is intentionally simple for now; future genetics may alter acquisition and capacity.

@export var amount: float = 0.0
@export var capacity: float = 100.0

func add_resource(value: float) -> void:
	if value <= 0.0:
		return
	amount = minf(amount + value, capacity)

func consume_resource(value: float) -> bool:
	if value <= 0.0 or amount < value:
		return false
	amount -= value
	return true
