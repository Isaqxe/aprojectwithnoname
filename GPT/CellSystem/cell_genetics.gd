extends Node

## NEO genetic system foundation.
## Genes are loci with two alleles and an explicit expression rule.
## Reproduction is intentionally independent from this layer for now.

const GENE_SCRIPT := preload("res://GPT/CellSystem/gene_data.gd")

@export var species_id: String = ""
@export_range(0.0, 1.0) var mutation_chance: float = 0.10
@export_range(0.0, 1.0) var mutation_strength: float = 0.05

var cell_id: String = ""
var parent_id: String = ""
var generation: int = 0
var genes: Dictionary = {}
var last_mutation_count: int = 0

static var _next_id: int = 1

const ATTRIBUTE_GENES: Array[String] = ["health", "damage", "speed", "size", "regeneration_rate", "efficiency"]
const ADAPTATION_GENES: Array[String] = ["cold_adaptation", "temperate_adaptation", "heat_adaptation", "void_adaptation", "humidity_adaptation"]
const CHARACTERISTIC_GENES: Array[String] = ["territorial", "cooperative_hunter", "camouflage", "armor", "toxin", "specialized_feeding"]
const BEHAVIOR_GENES: Array[String] = ["sociality", "aggression", "caution", "group_response"]

func initialize_random() -> void:
	cell_id = _generate_id()
	generation = 0
	parent_id = ""
	last_mutation_count = 0
	genes.clear()
	for gene_name in ATTRIBUTE_GENES:
		_create_numeric_gene(gene_name, randf_range(0.25, 0.75), GENE_SCRIPT.CATEGORY_ATTRIBUTE)
	for gene_name in ADAPTATION_GENES:
		_create_numeric_gene(gene_name, randf_range(0.25, 0.75), GENE_SCRIPT.CATEGORY_ADAPTATION)
	for gene_name in BEHAVIOR_GENES:
		_create_numeric_gene(gene_name, randf_range(0.20, 0.80), GENE_SCRIPT.CATEGORY_CHARACTERISTIC)
	for gene_name in CHARACTERISTIC_GENES:
		_create_boolean_gene(gene_name, false)

func initialize_from_parent(parent_genetics: Node, inherited_genes: Dictionary) -> void:
	cell_id = _generate_id()
	parent_id = ""
	generation = 0
	last_mutation_count = 0
	species_id = ""
	genes.clear()

	if parent_genetics != null:
		parent_id = String(parent_genetics.get("cell_id"))
		generation = int(parent_genetics.get("generation")) + 1
		species_id = String(parent_genetics.get("species_id"))

	if inherited_genes.has("attribute") or inherited_genes.has("adaptation") or inherited_genes.has("characteristic"):
		genes = _normalize_neo_genes(inherited_genes)
	else:
		for gene_name in inherited_genes.keys():
			var value: Variant = inherited_genes[gene_name]
			var name: String = String(gene_name)
			if value is bool:
				_create_boolean_gene(name, bool(value))
			else:
				var category: String = GENE_SCRIPT.CATEGORY_ADAPTATION
				if name in ATTRIBUTE_GENES:
					category = GENE_SCRIPT.CATEGORY_ATTRIBUTE
				elif name in BEHAVIOR_GENES:
					category = GENE_SCRIPT.CATEGORY_CHARACTERISTIC
				_create_numeric_gene(name, float(value), category)

	_ensure_all_genes()

func set_gene(gene_name: String, value: float) -> void:
	var category: String = GENE_SCRIPT.CATEGORY_ADAPTATION
	if gene_name in ATTRIBUTE_GENES:
		category = GENE_SCRIPT.CATEGORY_ATTRIBUTE
	elif gene_name in BEHAVIOR_GENES or gene_name in CHARACTERISTIC_GENES:
		category = GENE_SCRIPT.CATEGORY_CHARACTERISTIC
	_create_numeric_gene(gene_name, value, category)

func set_characteristic(gene_name: String, present: bool) -> void:
	_create_boolean_gene(gene_name, present)

func get_gene(gene_name: String, fallback: float = 0.0) -> float:
	var phenotype: Variant = get_phenotype(gene_name, fallback)
	if phenotype is bool:
		return 1.0 if bool(phenotype) else 0.0
	if phenotype is Array:
		return fallback
	return float(phenotype)

func get_genotype(gene_name: String) -> Array:
	var gene: RefCounted = _find_gene(gene_name)
	if gene == null:
		return []
	var result: Variant = gene.call("genotype")
	return result if result is Array else []

func get_phenotype(gene_name: String, fallback: Variant = 0.0) -> Variant:
	var gene: RefCounted = _find_gene(gene_name)
	if gene == null:
		return fallback
	return gene.call("phenotype")

func has_characteristic(gene_name: String) -> bool:
	var value: Variant = get_phenotype(gene_name, false)
	return bool(value) if value is bool else float(value) >= 0.5

func get_gene_data(gene_name: String) -> Dictionary:
	var gene: RefCounted = _find_gene(gene_name)
	if gene == null:
		return {}
	return gene.call("to_dictionary")

func mutate_genes() -> Array[String]:
	var mutated_genes: Array[String] = []
	for category_key in genes.keys():
		var category_data: Dictionary = genes[category_key]
		if not category_data is Dictionary:
			continue
		for gene_name in category_data.keys():
			if randf() > mutation_chance:
				continue
			var gene: Variant = category_data[gene_name]
			if gene == null or not gene is RefCounted:
				continue
			var allele_a: Variant = gene.get("allele_a")
			var allele_b: Variant = gene.get("allele_b")
			if allele_a is bool or allele_b is bool:
				if randf() < 0.5:
					gene.set("allele_a", not bool(allele_a))
				else:
					gene.set("allele_b", not bool(allele_b))
			elif String(category_key) == GENE_SCRIPT.CATEGORY_ATTRIBUTE:
				gene.set("allele_a", _mutate_numeric_allele(float(allele_a)))
				gene.set("allele_b", _mutate_numeric_allele(float(allele_b)))
			else:
				gene.set("allele_a", _mutate_normalized_allele(float(allele_a)))
				gene.set("allele_b", _mutate_normalized_allele(float(allele_b)))
			mutated_genes.append(String(gene_name))
	last_mutation_count = mutated_genes.size()
	return mutated_genes

func get_lineage_data() -> Dictionary:
	return {
		"cell_id": cell_id,
		"parent_id": parent_id,
		"generation": generation,
		"species_id": species_id,
		"genes": _serialize_genes()
	}

func get_all_gene_data() -> Dictionary:
	return _serialize_genes()

func _create_numeric_gene(gene_name: String, value: float, category: String) -> void:
	if not genes.has(category):
		genes[category] = {}
	genes[category][gene_name] = GENE_SCRIPT.new(gene_name, category, value, value, GENE_SCRIPT.EXPRESSION_AVERAGE)

func _create_boolean_gene(gene_name: String, present: bool) -> void:
	if not genes.has(GENE_SCRIPT.CATEGORY_CHARACTERISTIC):
		genes[GENE_SCRIPT.CATEGORY_CHARACTERISTIC] = {}
	genes[GENE_SCRIPT.CATEGORY_CHARACTERISTIC][gene_name] = GENE_SCRIPT.new(gene_name, GENE_SCRIPT.CATEGORY_CHARACTERISTIC, present, present, GENE_SCRIPT.EXPRESSION_PRESENCE)

func _find_gene(gene_name: String) -> RefCounted:
	for category_key in genes.keys():
		var category_data: Dictionary = genes[category_key]
		if category_data is Dictionary and category_data.has(gene_name):
			var gene: Variant = category_data[gene_name]
			if gene is RefCounted:
				return gene
	return null

func _serialize_genes() -> Dictionary:
	var result: Dictionary = {}
	for category_key in genes.keys():
		result[category_key] = {}
		var category_data: Dictionary = genes[category_key]
		if not category_data is Dictionary:
			continue
		for gene_name in category_data.keys():
			var gene: Variant = category_data[gene_name]
			if gene is RefCounted:
				result[category_key][gene_name] = gene.call("to_dictionary")
	return result

func _normalize_neo_genes(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for category_key in [GENE_SCRIPT.CATEGORY_ATTRIBUTE, GENE_SCRIPT.CATEGORY_ADAPTATION, GENE_SCRIPT.CATEGORY_CHARACTERISTIC]:
		result[category_key] = {}
		var category_data: Dictionary = source.get(category_key, {})
		if not category_data is Dictionary:
			continue
		for gene_name in category_data.keys():
			var raw: Variant = category_data[gene_name]
			if raw is RefCounted:
				result[category_key][gene_name] = raw
			elif raw is Dictionary:
				result[category_key][gene_name] = GENE_SCRIPT.from_dictionary(raw)
	return result

func _ensure_all_genes() -> void:
	for gene_name in ATTRIBUTE_GENES:
		if _find_gene(gene_name) == null:
			_create_numeric_gene(gene_name, 0.5, GENE_SCRIPT.CATEGORY_ATTRIBUTE)
	for gene_name in ADAPTATION_GENES:
		if _find_gene(gene_name) == null:
			_create_numeric_gene(gene_name, 0.5, GENE_SCRIPT.CATEGORY_ADAPTATION)
	for gene_name in BEHAVIOR_GENES:
		if _find_gene(gene_name) == null:
			_create_numeric_gene(gene_name, 0.5, GENE_SCRIPT.CATEGORY_CHARACTERISTIC)
	for gene_name in CHARACTERISTIC_GENES:
		if _find_gene(gene_name) == null:
			_create_boolean_gene(gene_name, false)

func _mutate_numeric_allele(value: float) -> float:
	var variation: float = randf_range(-mutation_strength, mutation_strength)
	return maxf(value * (1.0 + variation), 0.0)

func _mutate_normalized_allele(value: float) -> float:
	var variation: float = randf_range(-mutation_strength, mutation_strength)
	return clampf(value * (1.0 + variation), 0.0, 1.0)

func _generate_id() -> String:
	var new_id: String = "cell_%08d" % _next_id
	_next_id += 1
	return new_id
