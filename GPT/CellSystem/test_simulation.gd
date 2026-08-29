extends Node2D

## Integrated CellSystem validation scene.
## CellManager and ResourceSpawner use SimulationCamera as their spatial center.
## Space spawns the player at world position (0, 0) for debugging.

@onready var cell_manager: Node = $CellManager
@onready var resource_spawner: Node2D = $ResourceSpawner
@onready var simulation_camera: Camera2D = $SimulationCamera
@onready var debug_label: Label = $DebugLayer/Debug

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	debug_label.text = "CellSystem Simulation\nPopulation: %d\nPlayer: %s\nCamera: (%.0f, %.0f)" % [
		cell_manager.get_population(),
		"Spawned" if cell_manager.get_player() != null else "Not spawned",
		simulation_camera.global_position.x,
		simulation_camera.global_position.y
	]
