extends RefCounted

## NEO formula layer.
## Attribute genes are represented by two haplotypes.
## Example:
##   haplotype A = "ABCD"
##   haplotype B = "ABCD"
##   combined genotype = "AABBCCDD"
## A mutation can change a single position without changing the rest.
## This file calculates phenotype only; it does not perform inheritance.

const MODE_MEAN := "mean"
const MODE_PRESENCE := "presence"
const MODE_ATTRIBUTE_SEQUENCE := "attribute_sequence"

static func evaluate(allele_a: Variant, allele_b: Variant, mode: String = MODE_MEAN, contribution_table: Dictionary = {}) -> Variant:
	match mode:
		MODE_PRESENCE:
			return bool(allele_a) or bool(allele_b)
		MODE_ATTRIBUTE_SEQUENCE:
			return evaluate_attribute_sequence(String(allele_a), String(allele_b), contribution_table)
		_:
			return _mean(allele_a, allele_b)

static func genotype(allele_a: Variant, allele_b: Variant) -> Array:
	return [allele_a, allele_b]

static func combined_sequence(haplotype_a: String, haplotype_b: String) -> String:
	var result: String = ""
	var locus_count: int = mini(haplotype_a.length(), haplotype_b.length())
	for i in range(locus_count):
		result += haplotype_a.substr(i, 1)
		result += haplotype_b.substr(i, 1)
	return result

static func evaluate_attribute_sequence(haplotype_a: String, haplotype_b: String, contribution_table: Dictionary = {}) -> float:
	if haplotype_a.is_empty() or haplotype_b.is_empty():
		return 0.0

	var total: float = 0.0
	var locus_count: int = mini(haplotype_a.length(), haplotype_b.length())
	for i in range(locus_count):
		var symbol_a: String = haplotype_a.substr(i, 1)
		var symbol_b: String = haplotype_b.substr(i, 1)
		total += _allele_contribution(contribution_table, i, symbol_a)
		total += _allele_contribution(contribution_table, i, symbol_b)
	return total

static func _allele_contribution(table: Dictionary, locus: int, symbol: String) -> float:
	var locus_key: String = str(locus)
	if table.has(locus_key):
		var locus_data: Variant = table[locus_key]
		if locus_data is Dictionary:
			return float(locus_data.get(symbol, 0.0))

	if table.has(locus):
		var numeric_locus_data: Variant = table[locus]
		if numeric_locus_data is Dictionary:
			return float(numeric_locus_data.get(symbol, 0.0))

	return 0.0

static func _mean(allele_a: Variant, allele_b: Variant) -> Variant:
	if allele_a is bool or allele_b is bool:
		return bool(allele_a) or bool(allele_b)
	return (float(allele_a) + float(allele_b)) * 0.5
