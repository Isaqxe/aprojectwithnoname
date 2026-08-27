extends Node

## Fear behavior prototype.
## Compares the total biological power of two cells.
## The stronger cell may hunt while the weaker one flees.

@export var fear_threshold: float = 1.0

func get_cell_power(cell) -> float:
	if cell == null:
		return 0.0

	var power = 0.0

	if "health" in cell:
		power += cell.health

	if "damage" in cell:
		power += cell.damage

	if "speed" in cell:
		power += cell.speed

	if "size" in cell:
		power += cell.size

	return power


func evaluate(cell, other_cell) -> String:
	if cell == null or other_cell == null:
		return "WANDER"

	var cell_power = get_cell_power(cell)
	var other_power = get_cell_power(other_cell)

	if other_power > cell_power * fear_threshold:
		return "FLEE"

	return "HUNT"
