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

	debug_label.text = "CellSystem Simulation\nPopulation: %d\nPlayer: %s\nCamera: (%.0f, %.0f)\nDomain: R %.0f\nEnvironment: %s" % [
		cell_manager.get_population(),
		"Spawned" if cell_manager.get_player() != null else "Not spawned",
		simulation_camera.global_position.x,
		simulation_camera.global_position.y,
		float(experimental_domain.get("radius")),
		String(environment.get("biome", "unknown"))
	]
