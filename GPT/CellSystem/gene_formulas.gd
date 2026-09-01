extends RefCounted

## NEO formula layer.
## Attribute genes use a finite allele palette; characteristic genes are binary.
## This file defines phenotype math only. It does not perform inheritance.

const MODE_MEAN := "mean"
const MODE_PRESENCE := "presence"

static func evaluate(allele_a: Variant, allele_b: Variant, mode: String = MODE_MEAN) -> Variant:
	match mode:
		MODE_PRESENCE:
			return bool(allele_a) or bool(allele_b)
		_:
			return _mean(allele_a, allele_b)

static func genotype(allele_a: Variant, allele_b: Variant) -> Array:
	return [allele_a, allele_b]

static func _mean(allele_a: Variant, allele_b: Variant) -> Variant:
	if allele_a is bool or allele_b is bool:
		return bool(allele_a) or bool(allele_b)
	return (float(allele_a) + float(allele_b)) * 0.5
