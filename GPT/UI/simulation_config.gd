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

func reset_defaults() -> void:
	auto_spawn_cells = false
	initial_population = 500
	max_population = 10000
	initial_resources = 1000
	max_resources = 2302
	domain_radius = 3000.0
	simulation_time_limit = 0.0
