extends Node

## Lightweight registry for future genetics/species systems.
## Species are identified by a stable string; cells will carry species_id later.

var species_population: Dictionary = {}

func register_cell_species(species_id: String) -> void:
	if species_id.is_empty():
		return
	species_population[species_id] = int(species_population.get(species_id, 0)) + 1

func unregister_cell_species(species_id: String) -> void:
	if not species_population.has(species_id):
		return
	species_population[species_id] -= 1
	if species_population[species_id] <= 0:
		species_population.erase(species_id)

func get_species_population(species_id: String) -> int:
	return int(species_population.get(species_id, 0))

func get_species_ids() -> Array[String]:
	var ids: Array[String] = []
	for species_id in species_population.keys():
		ids.append(String(species_id))
	return ids
