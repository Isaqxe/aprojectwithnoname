extends Node2D

## Standalone test harness for the new GPU-first ProceduralWorld.

@onready var world: ProceduralWorld = $ProceduralWorld
@onready var camera: Camera2D = $SimulationCamera
@onready var debug_label: Label = $DebugLayer/Debug

func _ready() -> void:
	world.stream_center = camera
	camera.enabled = true

func _process(_delta: float) -> void:
	debug_label.text = "ProceduralWorld Prototype\nSeed: %d\nCamera: (%.0f, %.0f)\nCenter biome: %s\nMacro: %.3f  Temp: %.3f  Humidity: %.3f" % [
		world.world_seed,
		camera.global_position.x,
		camera.global_position.y,
		world.get_biome_at(camera.global_position),
		float(world.get_environment_at(camera.global_position).get("macro", 0.0)),
		float(world.get_environment_at(camera.global_position).get("temperature", 0.0)),
		float(world.get_environment_at(camera.global_position).get("humidity", 0.0))
	]

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length_squared() > 0.0:
		camera.position += input_direction.normalized() * 250.0 * _delta
