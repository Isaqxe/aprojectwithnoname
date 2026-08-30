extends Node

## Records milestones that happen for the first time during a simulation run.
## Pure event bookkeeping; it does not change simulation behavior.
class_name FirstTimeEvents

signal first_time_event(event_id: String, message: String)

var seen: Dictionary = {}
var history: Array[String] = []
var _last_event_count: int = 0
var _last_mutation_total: int = 0
var _known_living_species: Dictionary = {}

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	var manager: Node = get_tree().get_first_node_in_group("CellManagers")
	if manager == null or not is_instance_valid(manager):
		return

	if manager.has_method("get_recent_events"):
		var events: Array = manager.get_recent_events()
		if events.size() > _last_event_count:
			for index in range(_last_event_count, events.size()):
				_process_manager_event(String(events[index]))
			_last_event_count = events.size()

	if manager.has_method("get_telemetry_snapshot"):
		var telemetry: Dictionary = manager.get_telemetry_snapshot()
		var mutation_total: int = int(telemetry.get("total_mutations", 0))
		if mutation_total > _last_mutation_total:
			record_mutation(String(telemetry.get("dominant_species", "unknown")))
			_last_mutation_total = mutation_total

	if manager.has_method("get_species_statistics"):
		var species_stats: Dictionary = manager.get_species_statistics()
		var current_living: Dictionary = {}
		for species_key in species_stats.keys():
			var species_id: String = String(species_key)
			var stats: Dictionary = species_stats.get(species_key, {})
			if int(stats.get("population", 0)) > 0:
				current_living[species_id] = true
			elif _known_living_species.has(species_id):
				record_species_extinction(species_id)
		_known_living_species = current_living

func _process_manager_event(message: String) -> void:
	if message.find("Birth:") >= 0:
		var marker: int = message.find("Birth:") + 6
		var payload: String = message.substr(marker).strip_edges()
		var generation: int = 0
		var gen_marker: int = payload.find("(gen ")
		if gen_marker >= 0:
			var gen_text: String = payload.substr(gen_marker + 5).trim_suffix(")").strip_edges()
			if gen_text.is_valid_int():
				generation = int(gen_text)
			payload = payload.substr(0, gen_marker).strip_edges()
		record_birth(payload, generation)
	elif message.find("Death:") >= 0:
		var death_payload: String = message.substr(message.find("Death:") + 6).strip_edges()
		var species_id: String = death_payload
		var gen_marker: int = death_payload.find("(gen ")
		if gen_marker >= 0:
			species_id = death_payload.substr(0, gen_marker).strip_edges()
		record_death(species_id)
	elif message.find("Population peak:") >= 0:
		var peak_text: String = message.substr(message.find("Population peak:") + 16).strip_edges()
		if peak_text.is_valid_int():
			record_population_peak(int(peak_text))

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
