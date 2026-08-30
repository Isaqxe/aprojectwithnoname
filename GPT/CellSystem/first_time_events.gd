extends Node

## Records milestones that happen for the first time during a simulation run.
## Pure event bookkeeping; it does not change simulation behavior.
class_name FirstTimeEvents

signal first_time_event(event_id: String, message: String)

var seen: Dictionary = {}
var history: Array[String] = []

func try_record(event_id: String, message: String) -> bool:
	var key: String = event_id.strip_edges()
	if key.is_empty() or seen.has(key):
		return false
	seen[key] = true
	history.append(message)
	first_time_event.emit(key, message)
	return true

func has_seen(event_id: String) -> bool:
	return seen.has(event_id.strip_edges())

func get_history() -> Array[String]:
	return history.duplicate()

func record_birth(species_id: String, generation: int) -> void:
	try_record("first_birth", "Uma nova célula nasceu: %s (gen %d)." % [species_id, generation])
	if generation >= 2:
		try_record("first_generation_2", "Uma célula da segunda geração surgiu.")

func record_mutation(species_id: String) -> void:
	try_record("first_mutation", "A primeira mutação foi observada em %s." % species_id)

func record_death(species_id: String, cause: String = "unknown") -> void:
	try_record("first_death", "A primeira morte foi observada em %s." % species_id)
	if cause == "hunger":
		try_record("first_hunger_death", "Uma célula morreu de fome pela primeira vez.")

func record_species_extinction(species_id: String) -> void:
	try_record("first_extinction", "A espécie %s foi a primeira a desaparecer." % species_id)

func record_population_peak(population: int) -> void:
	try_record("first_population_peak", "A população atingiu um novo pico: %d células." % population)
