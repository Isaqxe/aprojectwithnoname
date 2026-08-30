extends "res://GPT/CellSystem/cell_behavior.gd"

const SPATIAL_INDEX_GROUP := "CellSpatialIndexes"

func _query_cells(radius: float) -> Array:
	var index_node: Node = get_tree().get_first_node_in_group(SPATIAL_INDEX_GROUP)
	if index_node != null and index_node.has_method("query_circle"):
		var owner_cell: Node = get_parent()
		if owner_cell is Node2D:
			return index_node.query_circle((owner_cell as Node2D).global_position, radius)
	return get_tree().get_nodes_in_group("SimCells")

func evaluate_collective_cell(my_cell, other_cell, ally_cells: Array) -> BehaviorState:
	if my_cell == null:
		state = BehaviorState.WANDER
		return state
	var individual_strength: float = calculate_strength(my_cell)
	group_strength = individual_strength
	ally_count = 0
	for ally in ally_cells:
		if ally == null or ally == my_cell or not is_instance_valid(ally):
			continue
		if not is_same_species(my_cell, ally) or not bool(ally.get("alive")):
			continue
		group_strength += calculate_strength(ally)
		ally_count += 1

	var perception: float = 180.0
	var owner_cell: Node = get_parent()
	if owner_cell != null:
		perception = maxf(float(owner_cell.get("perception_radius")), 1.0)

	threat_count = 0
	total_threat_strength = 0.0
	for candidate in _query_cells(perception):
		if not is_valid_enemy(my_cell, candidate) or not candidate is Node2D:
			continue
		var distance: float = (owner_cell as Node2D).global_position.distance_to((candidate as Node2D).global_position)
		var proximity: float = 1.0 - clampf(distance / perception, 0.0, 1.0)
		total_threat_strength += calculate_strength(candidate) * maxf(proximity, 0.20)
		threat_count += 1

	if threat_count == 0 and is_valid_enemy(my_cell, other_cell):
		total_threat_strength = calculate_strength(other_cell)
		threat_count = 1

	fear = total_threat_strength - individual_strength
	threat_level = clampf(fear / maxf(individual_strength, 0.001), 0.0, 10.0)
	var caution: float = _get_behavior_gene("caution", 0.5)
	var aggression_gene: float = _get_behavior_gene("aggression", 0.5)
	var group_response: float = _get_behavior_gene("group_response", 0.5)
	aggression = aggression_gene
	if threat_count == 0:
		state = BehaviorState.WANDER
		return state

	var flee_multiplier: float = 1.0 + caution * 0.35
	var defense_multiplier: float = maxf(1.10 - group_response * 0.20, 0.85)
	var enough_defenders: bool = ally_count + 1 >= 2
	var has_advantage: bool = group_strength >= total_threat_strength * defense_multiplier
	if total_threat_strength > individual_strength * flee_multiplier:
		state = BehaviorState.HUNT if enough_defenders and has_advantage and group_response >= 0.45 else BehaviorState.FLEE
	else:
		var hunt_multiplier: float = 1.0 - aggression_gene * 0.25
		state = BehaviorState.HUNT if total_threat_strength <= individual_strength * hunt_multiplier else BehaviorState.FLEE
	return state
