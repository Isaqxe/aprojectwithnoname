extends Node2D

## Integrated CellSystem validation scene.
## CellManager and ResourceSpawner use SimulationCamera as their spatial center.
## ExperimentalDomain defines the circular laboratory-slide simulation area.
## Space spawns the player at world position (0, 0) for debugging.

@onready var cell_manager: Node = $CellManager
@onready var resource_spawner: Node2D = $ResourceSpawner
@onready var simulation_camera: Camera2D = $SimulationCamera
@onready var experimental_domain: Node2D = $ExperimentalDomain
@onready var debug_layer: CanvasLayer = $DebugLayer
@onready var debug_label: Label = $DebugLayer/Debug
@onready var simulation_time_label: Label = $DebugLayer/SimulationTime
@onready var fps_label: Label = $DebugLayer/FPS
@onready var cell_inspector: Node = $CellInspector

@export var debug_update_interval: float = 0.25
@export var presentation_toggle_key: Key = KEY_P
@export var fps_toggle_key: Key = KEY_F3

var _debug_timer: float = 0.0
var presentation_mode: bool = false
var simulation_elapsed: float = 0.0
var fps_visible: bool = false

func _ready() -> void:
	var config: Node = get_node_or_null("/root/SimulationConfig")
	if config != null and config.has_method("begin_simulation"):
		config.begin_simulation()
	_apply_simulation_config()
	if simulation_time_label != null:
		simulation_time_label.text = "Tempo: 00:00"
	if fps_label != null:
		fps_label.text = "FPS: --"
		fps_label.visible = false

func _process(delta: float) -> void:
	simulation_elapsed += delta
	if simulation_time_label != null:
		var total_seconds: int = int(simulation_elapsed)
		var minutes: int = total_seconds / 60
		var seconds: int = total_seconds % 60
		simulation_time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]
	if fps_visible and fps_label != null:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if Input.is_key_pressed(KEY_SPACE):
		cell_manager.spawn_player(Vector2.ZERO)

	_debug_timer -= delta
	if _debug_timer > 0.0:
		return
	_debug_timer = maxf(debug_update_interval, 0.05)

	if presentation_mode:
		return

	var environment: Dictionary = {}
	if experimental_domain.has_method("get_environment_at"):
		environment = experimental_domain.get_environment_at(simulation_camera.global_position)

	var telemetry: Dictionary = {}
	if cell_manager.has_method("get_telemetry_snapshot"):
		telemetry = cell_manager.get_telemetry_snapshot()

	var current_population: int = int(telemetry.get("population", 0))
	var created_population: int = int(telemetry.get("total_births", 0))
	var configured_initial: int = int(telemetry.get("initial_population", 500))
	var new_births: int = maxi(created_population - configured_initial, 0)
	var derived_deaths: int = maxi(created_population - current_population, 0)

	var living_species: Dictionary = {}
	for cell in cell_manager.registered_cells:
		if not is_instance_valid(cell):
			continue
		var data: Node = cell.get("cell_data") as Node
		if data == null or not is_instance_valid(data) or not bool(data.get("alive")):
			continue
		var species_id: String = ""
		if cell.has_method("get_species_id"):
			species_id = String(cell.get_species_id()).strip_edges()
		else:
			species_id = String(cell.get("species_id")).strip_edges()
		if species_id.is_empty() or species_id == "default":
			continue
		living_species[species_id] = int(living_species.get(species_id, 0)) + 1

	var living_species_count: int = living_species.size()
	var dominant_species: String = "none"
	var dominant_population: int = 0
	for species_key in living_species.keys():
		var species_population: int = int(living_species[species_key])
		if species_population > dominant_population:
			dominant_population = species_population
			dominant_species = String(species_key)

	debug_label.text = "CellSystem Simulation\n" + \
		"Population: %d | Peak: %d\n" % [current_population, int(telemetry.get("peak_population", 0))] + \
		"Births: %d | Created: %d | Deaths: %d\n" % [new_births, created_population, derived_deaths] + \
		"Mutations: %d\n" % int(telemetry.get("total_mutations", 0)) + \
		"Generation: %d | Species alive: %d\n" % [int(telemetry.get("highest_generation", 0)), living_species_count] + \
		"Dominant: %s (%d)\n" % [dominant_species, dominant_population] + \
		"Player: %s\n" % ["Spawned" if cell_manager.get_player() != null else "Not spawned"] + \
		"Camera: (%.0f, %.0f) | Domain R: %.0f\n" % [simulation_camera.global_position.x, simulation_camera.global_position.y, float(experimental_domain.get("radius"))] + \
		"Temp: %.2f | Humidity: %.2f | Food: %.2f" % [float(environment.get("temperature", 0.5)), float(environment.get("humidity", 0.5)), float(environment.get("food_density", 1.0))]

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == presentation_toggle_key:
		_toggle_presentation_mode()
	elif key_event.keycode == fps_toggle_key:
		fps_visible = not fps_visible
		if fps_label != null:
			fps_label.visible = fps_visible and not presentation_mode

func _toggle_presentation_mode() -> void:
	presentation_mode = not presentation_mode
	debug_layer.visible = not presentation_mode
	if cell_inspector != null and is_instance_valid(cell_inspector) and cell_inspector.has_method("set_presentation_mode"):
		cell_inspector.set_presentation_mode(presentation_mode)
	if fps_label != null:
		fps_label.visible = fps_visible and not presentation_mode
	_debug_timer = 0.0

func _apply_simulation_config() -> void:
	var config: Node = get_node_or_null("/root/SimulationConfig")
	if config == null:
		return
	cell_manager.auto_spawn = bool(config.get("auto_spawn_cells"))
	cell_manager.initial_population = int(config.get("initial_population"))
	cell_manager.max_population = int(config.get("max_population"))
	resource_spawner.initial_resources = int(config.get("initial_resources"))
	resource_spawner.max_resources = int(config.get("max_resources"))
	experimental_domain.radius = float(config.get("domain_radius"))
