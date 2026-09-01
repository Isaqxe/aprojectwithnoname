extends RefCounted

## Small NEO helper for attribute genotypes.
## Four loci: A/a, B/b, C/c, D/d.
## Each chromosome is a four-character haplotype.

const LOCUS_COUNT := 4

static func random_haplotype() -> String:
	var result := ""
	for i in range(LOCUS_COUNT):
		var symbol := char(65 + i)
		result += symbol if randf() < 0.5 else symbol.to_lower()
	return result

static func random_genotype() -> Array:
	return [random_haplotype(), random_haplotype()]

static func mutate_haplotype(haplotype: String) -> String:
	if haplotype.is_empty():
		return haplotype
	var chars := haplotype.split("")
	var index := randi_range(0, chars.size() - 1)
	var symbol := String(chars[index])
	chars[index] = symbol.to_lower() if symbol == symbol.to_upper() else symbol.to_upper()
	return "".join(chars)

static func combined_genotype(haplotype_a: String, haplotype_b: String) -> String:
	var result := ""
	for i in range(mini(haplotype_a.length(), haplotype_b.length())):
		result += haplotype_a.substr(i, 1)
		result += haplotype_b.substr(i, 1)
	return result
