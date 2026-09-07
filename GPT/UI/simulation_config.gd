extends Node

## Shared configuration for the next simulation run.
## Keeps menu controls independent from the simulation scene.

var auto_spawn_cells: bool = false
var initial_population: int = 500
var max_population: int = 10000
var initial_resources: int = 1000
var max_resources: int = 2302
var domain_radius: float = 3000.0
var simulation_time_limit: float = 0.0
var initial_time_scale: float = 1.0
var presentation_mode_on_start: bool = true

var resource_spawn_interval: float = 0.75
var resource_respawn_fraction: float = 0.60
var resource_emergency_fraction: float = 0.25
var resource_emergency_interval: float = 0.30

var base_temperature: float = 0.50
var base_humidity: float = 0.50
var base_food_density: float = 1.00
var temperature_variation: float = 0.35
var humidity_variation: float = 0.30
var food_edge_penalty: float = 0.45

var mutation_chance: float = 0.10
var mutation_strength: float = 0.05

func reset_defaults() -> void:
	auto_spawn_cells = false
	initial_population = 500
	max_population = 10000
	initial_resources = 1000
	max_resources = 2302
	domain_radius = 3000.0
	simulation_time_limit = 0.0
	initial_time_scale = 1.0
	presentation_mode_on_start = true
	resource_spawn_interval = 0.75
	resource_respawn_fraction = 0.60
	resource_emergency_fraction = 0.25
	resource_emergency_interval = 0.30
	base_temperature = 0.50
	base_humidity = 0.50
	base_food_density = 1.00
	temperature_variation = 0.35
	humidity_variation = 0.30
	food_edge_penalty = 0.45
	mutation_chance = 0.10
	mutation_strength = 0.05
