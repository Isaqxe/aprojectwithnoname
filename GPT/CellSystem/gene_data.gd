class_name GeneData
extends RefCounted

## Lightweight representation of one genetic locus.
## NEO separates genotype (two alleles) from phenotype (expressed value).
## This class intentionally does not know anything about reproduction.

const FORMULAS := preload("res://GPT/CellSystem/gene_formulas.gd")

const CATEGORY_ATTRIBUTE := "attribute"
const CATEGORY_ADAPTATION := "adaptation"
const CATEGORY_CHARACTERISTIC := "characteristic"

const EXPRESSION_AVERAGE := "mean"
const EXPRESSION_PRESENCE := "presence"
const EXPRESSION_DOMINANT := "dominant"
const EXPRESSION_RECESSIVE := "recessive"
const EXPRESSION_CODOMINANT := "codominant"

var name: String = ""
var category: String = CATEGORY_ATTRIBUTE
var allele_a: Variant = 0.5
var allele_b: Variant = 0.5
var expression_mode: String = EXPRESSION_AVERAGE

func _init(gene_name: String = "", gene_category: String = CATEGORY_ATTRIBUTE, a: Variant = 0.5, b: Variant = 0.5, mode: String = EXPRESSION_AVERAGE) -> void:
	name = gene_name
	category = gene_category
	allele_a = a
	allele_b = b
	expression_mode = mode

func genotype() -> Array:
	return FORMULAS.genotype(allele_a, allele_b)

func expressed_value() -> Variant:
	return FORMULAS.evaluate(allele_a, allele_b, expression_mode)

func phenotype() -> Variant:
	return expressed_value()

func to_dictionary() -> Dictionary:
	return {
		"name": name,
		"category": category,
		"allele_a": allele_a,
		"allele_b": allele_b,
		"genotype": genotype(),
		"expression_mode": expression_mode,
		"phenotype": phenotype()
	}

static func from_dictionary(data: Dictionary):
	var mode: String = String(data.get("expression_mode", EXPRESSION_AVERAGE))
	if mode == "average":
		mode = EXPRESSION_AVERAGE
	return GeneData.new(
		String(data.get("name", "")),
		String(data.get("category", CATEGORY_ATTRIBUTE)),
		data.get("allele_a", 0.5),
		data.get("allele_b", 0.5),
		mode
	)
