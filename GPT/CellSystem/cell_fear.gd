extends Node

## Simple Fear behavior prototype.
## Decides whether a cell should flee or hunt based on relative strength.

@export var fear_threshold: float = 1.0

func evaluate(cell, other_cell) -> String:
	if cell == null or other_cell == null:
		return "WANDER"

	var danger = other_cell.damage + other_cell.health
	var power = cell.damage + cell.health

	if danger > power * fear_threshold:
		return "FLEE"

	return "HUNT"
