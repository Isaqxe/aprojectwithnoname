extends Node2D

## Integrated CellSystem validation scene.
## CellManager and ResourceSpawner use SimulationCamera as their spatial center.
## ExperimentalDomain defines the circular laboratory-slide simulation area.
## Space spawns the player at world position (0, 0) for debugging.

@onready var cell_manager: Node = $CellManager
@onready var resource_spawner: Node2D = $ResourceSpawner
@onready var simulation_camera: Camera2D = $SimulationCamera
@onready var experimental_domain: Node2D = $ExperimentalDomain
@onready var debug_label: Label = $DebugLayer/Debug

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	var environment: Dictionary = {}
	if experimental_domain.has_method("get_environment_at"):
		environment = experimental_domain.get_environment_at(simulation_camera.global_position)

	var dominant_species: String = "none"
	var dominant_population: int = 0
	var species_stats: Dictionary = cell_manager.get_species_statistics()
	for species_id in species_stats.keys():
		var population: int = int(species_stats[species_id].get("population", 0))
		if population > dominant_population:
			dominant_population = population
			dominant_species = String(species_id)

	debug_label.text = "CellSystem Simulation\n" + \
		"Population: %d | Peak: %d\n" % [cell_manager.get_population(), int(cell_manager.get("peak_population"))] + \
		"Births: %d | Deaths: %d | Mutations: %d\n" % [int(cell_manager.get("total_births")), int(cell_manager.get("total_deaths")), int(cell_manager.get("total_mutations"))] + \
		"Species: %d | Dominant: %s (%d)\n" % [species_stats.size(), dominant_species, dominant_population] + \
		"Player: %s\n" % ["Spawned" if cell_manager.get_player() != null else "Not spawned"] + \
		"Camera: (%.0f, %.0f) | Domain R: %.0f\n" % [simulation_camera.global_position.x, simulation_camera.global_position.y, float(experimental_domain.get("radius"))] + \
		"Temp: %.2f | Humidity: %.2f | Food: %.2f" % [float(environment.get("temperature", 0.5)), float(environment.get("humidity", 0.5)), float(environment.get("food_density", 1.0))]
