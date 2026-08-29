extends Node

## Genetic identity and lineage data for a single cell.
## Mutation is intentionally not implemented here yet.

@export var species_id: String = "default"
var cell_id: String = ""
var parent_id: String = ""
var generation: int = 0

var genes: Dictionary = {}

static var _next_id: int = 1

func initialize_random() -> void:
	cell_id = _generate_id()
	generation = 0
	parent_id = ""

func initialize_from_parent(parent_genetics: Node, inherited_genes: Dictionary) -> void:
	cell_id = _generate_id()
	if parent_genetics != null:
		parent_id = String(parent_genetics.get("cell_id"))
		generation = int(parent_genetics.get("generation")) + 1
		species_id = String(parent_genetics.get("species_id"))
	genes = inherited_genes.duplicate(true)

func set_gene(name: String, value: float) -> void:
	genes[name] = value

func get_gene(name: String, fallback: float = 0.0) -> float:
	return float(genes.get(name, fallback))

func get_lineage_data() -> Dictionary:
	return {
		"cell_id": cell_id,
		"parent_id": parent_id,
		"generation": generation,
		"species_id": species_id,
		"genes": genes.duplicate(true)
	}

func _generate_id() -> String:
	var new_id: String = "cell_%08d" % _next_id
	_next_id += 1
	return new_id
