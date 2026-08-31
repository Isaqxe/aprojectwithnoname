extends Node

## Genetic identity and lineage data for a single cell.
## Mutations happen during reproduction and alter inherited genes slightly.
## Behavioral traits are ordinary heritable genes with normalized 0..1 values.

@export var species_id: String = ""
@export_range(0.0, 1.0) var mutation_chance: float = 0.10
@export_range(0.0, 1.0) var mutation_strength: float = 0.05

var cell_id: String = ""
var parent_id: String = ""
var generation: int = 0
var genes: Dictionary = {}
var last_mutation_count: int = 0

static var _next_id: int = 1

const BEHAVIOR_GENES: Array[String] = [
	"sociality",
	"aggression",
	"caution",
	"group_response"
]

func initialize_random() -> void:
	cell_id = _generate_id()
	generation = 0
	parent_id = ""
	last_mutation_count = 0
	genes = {
		"cold_adaptation": randf_range(0.25, 0.75),
		"temperate_adaptation": randf_range(0.25, 0.75),
		"heat_adaptation": randf_range(0.25, 0.75),
		"void_adaptation": randf_range(0.25, 0.75),
		"humidity_adaptation": randf_range(0.25, 0.75),
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
	last_mutation_count = 0
	genes = inherited_genes.duplicate(true)

	if parent_genetics != null:
		parent_id = String(parent_genetics.get("cell_id"))
		generation = int(parent_genetics.get("generation")) + 1
		species_id = String(parent_genetics.get("species_id"))

	_ensure_behavior_genes()
	_ensure_environment_genes()

func set_gene(gene_name: String, value: float) -> void:
	genes[gene_name] = clampf(value, 0.0, 1.0) if gene_name in BEHAVIOR_GENES else value

func get_gene(gene_name: String, fallback: float = 0.0) -> float:
	var value: float = float(genes.get(gene_name, fallback))
	if gene_name in BEHAVIOR_GENES or gene_name == "humidity_adaptation":
		return clampf(value, 0.0, 1.0)
	return value

func mutate_genes() -> Array[String]:
	var mutated_genes: Array[String] = []

	for gene_name in genes.keys():
		if randf() > mutation_chance:
			continue

		var current_value: float = float(genes[gene_name])
		var variation: float = randf_range(-mutation_strength, mutation_strength)
		var mutated_value: float = current_value * (1.0 + variation)
		if String(gene_name) in BEHAVIOR_GENES or String(gene_name) == "humidity_adaptation":
			mutated_value = clampf(mutated_value, 0.0, 1.0)
		else:
			mutated_value = maxf(mutated_value, 0.0)
		genes[gene_name] = mutated_value
		mutated_genes.append(String(gene_name))

	last_mutation_count = mutated_genes.size()
	_ensure_behavior_genes()
	_ensure_environment_genes()
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
	for gene_name in BEHAVIOR_GENES:
		if not genes.has(gene_name):
			genes[gene_name] = 0.5

func _ensure_environment_genes() -> void:
	if not genes.has("humidity_adaptation"):
		genes["humidity_adaptation"] = 0.5

func _generate_id() -> String:
	var new_id: String = "cell_%08d" % _next_id
	_next_id += 1
	return new_id
