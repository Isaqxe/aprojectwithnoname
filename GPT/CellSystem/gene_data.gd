class_name GeneData
extends RefCounted

## Lightweight representation of one genetic locus.
## This class defines the NEO Gene contract without depending on reproduction.

const CATEGORY_ATTRIBUTE := "attribute"
const CATEGORY_ADAPTATION := "adaptation"
const CATEGORY_CHARACTERISTIC := "characteristic"

const EXPRESSION_AVERAGE := "average"
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

func expressed_value() -> Variant:
	match expression_mode:
		EXPRESSION_DOMINANT:
			return allele_a if _is_dominant(allele_a, allele_b) else allele_b
		EXPRESSION_RECESSIVE:
			return allele_a if allele_a == allele_b else _recessive_fallback()
		EXPRESSION_CODOMINANT:
			return _codominant_value()
		_:
			return _average_value()

func _average_value() -> Variant:
	if allele_a is bool or allele_b is bool:
		return bool(allele_a) or bool(allele_b)
	return (float(allele_a) + float(allele_b)) * 0.5

func _codominant_value() -> Variant:
	if allele_a is bool or allele_b is bool:
		return [bool(allele_a), bool(allele_b)]
	return [float(allele_a), float(allele_b)]

func _recessive_fallback() -> Variant:
	if allele_a is bool or allele_b is bool:
		return false
	return minf(float(allele_a), float(allele_b))

func _is_dominant(a: Variant, b: Variant) -> bool:
	if a is bool and b is bool:
		return bool(a)
	return float(a) >= float(b)

func to_dictionary() -> Dictionary:
	return {
		"name": name,
		"category": category,
		"allele_a": allele_a,
		"allele_b": allele_b,
		"expression_mode": expression_mode,
		"phenotype": expressed_value()
	}

static func from_dictionary(data: Dictionary) -> GeneData:
	return GeneData.new(
		String(data.get("name", "")),
		String(data.get("category", CATEGORY_ATTRIBUTE)),
		data.get("allele_a", 0.5),
		data.get("allele_b", 0.5),
		String(data.get("expression_mode", EXPRESSION_AVERAGE))
	)
