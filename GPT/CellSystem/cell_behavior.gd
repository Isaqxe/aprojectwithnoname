extends Node

## Behavior layer for simulation cells.
## Behavior genes influence aggression, caution, social response, and feeding decisions.

@export var neutral_aggression_threshold: float = 0.35

var behavior_genes: Dictionary = {}

func _ready() -> void:
	_ensure_behavior_defaults()

func _ensure_behavior_defaults() -> void:
	if not behavior_genes.has("aggression"):
		behavior_genes["aggression"] = 0.5
	if not behavior_genes.has("caution"):
		behavior_genes["caution"] = 0.5
	if not behavior_genes.has("sociality"):
		behavior_genes["sociality"] = 0.5
	if not behavior_genes.has("group_response"):
		behavior_genes["group_response"] = 0.5

func set_behavior_genes(values: Dictionary) -> void:
	for gene_name in values.keys():
		behavior_genes[String(gene_name)] = clampf(float(values[gene_name]), 0.0, 1.0)
	_ensure_behavior_defaults()

func _get_behavior_gene(gene_name: String, default_value: float = 0.5) -> float:
	return clampf(float(behavior_genes.get(gene_name, default_value)), 0.0, 1.0)

func get_aggression() -> float:
	return _get_behavior_gene("aggression")

func get_caution() -> float:
	return _get_behavior_gene("caution")

func get_sociality() -> float:
	return _get_behavior_gene("sociality")

func get_group_response() -> float:
	return _get_behavior_gene("group_response")

func _get_species_id(cell: Node) -> String:
	if cell == null or not is_instance_valid(cell):
		return ""
	if cell.has_method("get_species_id"):
		return String(cell.get_species_id())
	return String(cell.get("species_id"))

func is_same_species(my_cell, other_cell) -> bool:
	var my_species: String = _get_species_id(my_cell)
	var other_species: String = _get_species_id(other_cell)
	return not my_species.is_empty() and my_species == other_species

func is_neutral(_my_cell) -> bool:
	return _get_behavior_gene("aggression", 0.5) < neutral_aggression_threshold

func is_valid_enemy(my_cell, other_cell) -> bool:
	if my_cell == null or other_cell == null or my_cell == other_cell:
		return false
	if is_same_species(my_cell, other_cell):
		return false
	return true
