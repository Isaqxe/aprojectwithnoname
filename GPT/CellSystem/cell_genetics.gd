extends Node

## Genetic identity and lineage data for a single cell.
## Mutations happen during reproduction and alter inherited genes slightly.

@export var species_id: String = "default"
@export_range(0.0, 1.0) var mutation_chance: float = 0.10
@export_range(0.0, 1.0) var mutation_strength: float = 0.05

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

func mutate_genes() -> Array[String]:
	var mutated_genes: Array[String] = []

	for gene_name in genes.keys():
		if randf() > mutation_chance:
			continue

		var current_value: float = float(genes[gene_name])
		var variation: float = randf_range(-mutation_strength, mutation_strength)
		genes[gene_name] = maxf(0.0, current_value * (1.0 + variation))
		mutated_genes.append(String(gene_name))

	return mutated_genes

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
