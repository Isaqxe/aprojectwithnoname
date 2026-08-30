extends Node

## Genetic identity and lineage data for a single cell.
## Mutations happen during reproduction and alter inherited genes slightly.
## Behavioral traits are ordinary heritable genes just like biological traits.

@export var species_id: String = ""
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
	genes = {
		"cold_adaptation": randf_range(0.25, 0.75),
		"temperate_adaptation": randf_range(0.25, 0.75),
		"heat_adaptation": randf_range(0.25, 0.75),
		"void_adaptation": randf_range(0.25, 0.75),
		"sociality": randf_range(0.20, 0.80),
		"aggression": randf_range(0.20, 0.80),
		"caution": randf_range(0.20, 0.80),
		"group_response": randf_range(0.20, 0.80)
	}

func initialize_from_parent(parent_genetics: Node, inherited_genes: Dictionary) -> void:
	cell_id = _generate_id()
	parent_id = ""
	generation = 0
	species_id = ""
	genes = inherited_genes.duplicate(true)

	if parent_genetics != null:
		parent_id = String(parent_genetics.get("cell_id"))
		generation = int(parent_genetics.get("generation")) + 1
		species_id = String(parent_genetics.get("species_id"))

	_ensure_behavior_genes()

func set_gene(gene_name: String, value: float) -> void:
	genes[gene_name] = clampf(value, 0.0, 1.0)

func get_gene(gene_name: String, fallback: float = 0.0) -> float:
	return clampf(float(genes.get(gene_name, fallback)), 0.0, 1.0)

func mutate_genes() -> Array[String]:
	var mutated_genes: Array[String] = []

	for gene_name in genes.keys():
		if randf() > mutation_chance:
			continue

		var current_value: float = float(genes[gene_name])
		var variation: float = randf_range(-mutation_strength, mutation_strength)
		genes[gene_name] = clampf(current_value * (1.0 + variation), 0.0, 1.0)
		mutated_genes.append(String(gene_name))

	_ensure_behavior_genes()
	return mutated_genes

func get_lineage_data() -> Dictionary:
	return {
		"cell_id": cell_id,
		"parent_id": parent_id,
		"generation": generation,
		"species_id": species_id,
		"genes": genes.duplicate(true)
	}

func _ensure_behavior_genes() -> void:
	if not genes.has("sociality"):
		genes["sociality"] = 0.5
	if not genes.has("aggression"):
		genes["aggression"] = 0.5
	if not genes.has("caution"):
		genes["caution"] = 0.5
	if not genes.has("group_response"):
		genes["group_response"] = 0.5

func _generate_id() -> String:
	var new_id: String = "cell_%08d" % _next_id
	_next_id += 1
	return new_id
