extends Camera2D

## Central spatial controller for the CellSystem simulation.
## Follows the Player through CellManager or a selected cell.

@export_category("Following")
@export var follow_player: bool = true
@export var follow_smoothing: float = 8.0

@export_category("Simulation Streaming")
@export var load_radius: float = 450.0
@export var unload_radius: float = 650.0
@export var spawn_radius: float = 425.0

var follow_target: Node2D = null
var selected_target: Node2D = null

func _ready() -> void:
	add_to_group("SimulationCameras")
	position_smoothing_enabled = false
	_find_player()

func _process(delta: float) -> void:
	if not is_instance_valid(selected_target):
		selected_target = null

	if selected_target != null:
		_set_target(selected_target)
	elif follow_player:
		_find_player()

	if is_instance_valid(follow_target):
		if follow_smoothing <= 0.0:
			global_position = follow_target.global_position
		else:
			var weight: float = clampf(follow_smoothing * delta, 0.0, 1.0)
			global_position = global_position.lerp(follow_target.global_position, weight)

func set_follow_target(target: Node2D) -> void:
	selected_target = target
	_set_target(target)

func clear_selected_target() -> void:
	selected_target = null
	_find_player()

func get_simulation_center() -> Vector2:
	return global_position

func get_load_radius() -> float:
	return maxf(load_radius, 0.0)

func get_unload_radius() -> float:
	return maxf(unload_radius, get_load_radius())

func get_spawn_radius() -> float:
	return maxf(spawn_radius, 0.0)

func get_spawn_bounds() -> Rect2:
	var radius: float = get_spawn_radius()
	return Rect2(global_position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)

func _set_target(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		follow_target = null
		return
	follow_target = target

func _find_player() -> void:
	var manager: Node = get_tree().get_first_node_in_group("CellManagers")
	if manager != null and is_instance_valid(manager) and manager.has_method("get_player"):
		var player: Node = manager.get_player()
		if player is Node2D and is_instance_valid(player):
			_set_target(player as Node2D)
