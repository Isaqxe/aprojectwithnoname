class_name GeneFormulas
extends RefCounted

## NEO formula layer.
## Keeps allele-combination rules isolated from reproduction.
## This file defines the current mathematical contract only;
## it does not perform inheritance or mitosis.

const MODE_MEAN := "mean"
const MODE_PRESENCE := "presence"
const MODE_DOMINANT := "dominant"
const MODE_RECESSIVE := "recessive"
const MODE_CODOMINANT := "codominant"

static func evaluate(allele_a: Variant, allele_b: Variant, mode: String = MODE_MEAN) -> Variant:
	match mode:
		MODE_PRESENCE:
			return bool(allele_a) or bool(allele_b)
		MODE_DOMINANT:
			return _dominant(allele_a, allele_b)
		MODE_RECESSIVE:
			return _recessive(allele_a, allele_b)
		MODE_CODOMINANT:
			return [allele_a, allele_b]
		_:
			return _mean(allele_a, allele_b)

static func genotype(allele_a: Variant, allele_b: Variant) -> Array:
	return [allele_a, allele_b]

static func _mean(allele_a: Variant, allele_b: Variant) -> Variant:
	if allele_a is bool or allele_b is bool:
		return bool(allele_a) or bool(allele_b)
	return (float(allele_a) + float(allele_b)) * 0.5

static func _dominant(allele_a: Variant, allele_b: Variant) -> Variant:
	if allele_a is bool and allele_b is bool:
		return bool(allele_a) or bool(allele_b)
	return allele_a if float(allele_a) >= float(allele_b) else allele_b

static func _recessive(allele_a: Variant, allele_b: Variant) -> Variant:
	if allele_a is bool and allele_b is bool:
		return bool(allele_a) and bool(allele_b)
	if allele_a == allele_b:
		return allele_a
	return minf(float(allele_a), float(allele_b))
