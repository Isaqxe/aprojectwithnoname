extends Node

## Fear system for Alive Cells.
## Compares weighted biological power between two cells.

@export_category("Fear Weights")
@export var health_weight: float = 1.0
@export var damage_weight: float = 1.0
@export var speed_weight: float = 1.0
@export var size_weight: float = 1.0

@export_category("Decision")
@export var fear_threshold: float = 1.15

func get_cell_power(cell) -> float:
	if cell == null:
		return 0.0

	var power: float = 0.0

	if "health" in cell:
		power += cell.health * health_weight

	if "damage" in cell:
		power += cell.damage * damage_weight

	if "speed" in cell:
		power += cell.speed * speed_weight

	if "size" in cell:
		power += cell.size * size_weight

	return power

func evaluate(cell, other_cell) -> String:
	if cell == null or other_cell == null:
		return "WANDER"

	var cell_power: float = get_cell_power(cell)
	var other_power: float = get_cell_power(other_cell)

	if other_power > cell_power * fear_threshold:
		return "FLEE"

	return "HUNT"
