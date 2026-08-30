extends Node

## Species population registry.
## Individual cell identity is owned by CellGenetics; this registry tracks
## species population metadata only.

var species_population: Dictionary = {}

func register_cell_species(species_id: String) -> void:
	var normalized_id: String = species_id.strip_edges()
	if normalized_id.is_empty() or normalized_id == "default":
		return
	species_population[normalized_id] = int(species_population.get(normalized_id, 0)) + 1

func unregister_cell_species(species_id: String) -> void:
	var normalized_id: String = species_id.strip_edges()
	if normalized_id.is_empty() or normalized_id == "default":
		return
	if not species_population.has(normalized_id):
		return
	species_population[normalized_id] -= 1
	if species_population[normalized_id] <= 0:
		species_population.erase(normalized_id)

func get_species_population(species_id: String) -> int:
	var normalized_id: String = species_id.strip_edges()
	if normalized_id.is_empty() or normalized_id == "default":
		return 0
	return int(species_population.get(normalized_id, 0))

func get_species_ids() -> Array[String]:
	var ids: Array[String] = []
	for species_id in species_population.keys():
		ids.append(String(species_id))
	return ids
