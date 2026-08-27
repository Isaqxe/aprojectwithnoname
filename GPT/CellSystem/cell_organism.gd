extends Node

## Prototype organism wrapper.
## Connects a cell with behavior and combat modules.

class_name CellOrganism

var cell_data
var behavior
var combat

func initialize(cell, behavior_module, combat_module) -> void:
	cell_data = cell
	behavior = behavior_module
	combat = combat_module

func evaluate_interaction(other_cell) -> String:
	if behavior == null or cell_data == null or other_cell == null:
		return "WANDER"

	var my_power = cell_data.health + cell_data.damage + cell_data.speed + cell_data.size
	var other_power = other_cell.health + other_cell.damage + other_cell.speed + other_cell.size

	behavior.evaluate_threat(my_power, other_power)
	return str(behavior.state)
