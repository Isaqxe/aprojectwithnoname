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

@export var debug_update_interval: float = 0.25
var _debug_timer: float = 0.0

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	_debug_timer -= delta
	if _debug_timer > 0.0:
		return
	_debug_timer = maxf(debug_update_interval, 0.05)

	var environment: Dictionary = {}
	if experimental_domain.has_method("get_environment_at"):
		environment = experimental_domain.get_environment_at(simulation_camera.global_position)

	var telemetry: Dictionary = {}
	if cell_manager.has_method("get_telemetry_snapshot"):
		telemetry = cell_manager.get_telemetry_snapshot()

	var species_stats: Dictionary = {}
	if cell_manager.has_method("get_species_statistics"):
		species_stats = cell_manager.get_species_statistics()

	var dominant_species: String = String(telemetry.get("dominant_species", "none"))
	var dominant_population: int = 0
	if not dominant_species.is_empty() and species_stats.has(dominant_species):
		dominant_population = int(species_stats[dominant_species].get("population", 0))

	debug_label.text = "CellSystem Simulation\n" + \
		"Population: %d | Peak: %d\n" % [int(telemetry.get("population", 0)), int(telemetry.get("peak_population", 0))] + \
		"Births: %d | Deaths: %d | Mutations: %d\n" % [int(telemetry.get("total_births", 0)), int(telemetry.get("total_deaths", 0)), int(telemetry.get("total_mutations", 0))] + \
		"Generation: %d | Species: %d\n" % [int(telemetry.get("highest_generation", 0)), int(telemetry.get("species_count", species_stats.size()))] + \
		"Dominant: %s (%d)\n" % [dominant_species if not dominant_species.is_empty() else "none", dominant_population] + \
		"Player: %s\n" % ["Spawned" if cell_manager.get_player() != null else "Not spawned"] + \
		"Camera: (%.0f, %.0f) | Domain R: %.0f\n" % [simulation_camera.global_position.x, simulation_camera.global_position.y, float(experimental_domain.get("radius"))] + \
		"Temp: %.2f | Humidity: %.2f | Food: %.2f" % [float(environment.get("temperature", 0.5)), float(environment.get("humidity", 0.5)), float(environment.get("food_density", 1.0))]
