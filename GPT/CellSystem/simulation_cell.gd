extends CharacterBody2D

## Integrated organism used by the CellSystem simulation.
## Combines the generic cell data, behavior and combat prototypes.

const CELL_SCRIPT := preload("res://GPT/CellSystem/cell.gd")
const BEHAVIOR_SCRIPT := preload("res://GPT/CellSystem/cell_behavior.gd")
const FEAR_SCRIPT := preload("res://GPT/CellSystem/cell_fear.gd")
const COMBAT_SCRIPT := preload("res://GPT/CellSystem/cell_combat.gd")

@export var is_player_controlled: bool = false
@export var wander_speed_factor: float = 0.35
@export var perception_radius: float = 180.0
@export var contact_margin: float = 2.0

var cell_data: CharacterBody2D
var behavior: CellBehavior
var fear_system: Node
var combat: Node
var _target: CharacterBody2D
var _direction := Vector2.ZERO
var _retarget_timer := 0.0
var _base_color := Color.WHITE
var _flash_timer := 0.0

func _ready() -> void:
	cell_data = CELL_SCRIPT.new()
	cell_data.max_health = randf_range(40.0, 120.0)
	cell_data.damage = randf_range(5.0, 25.0)
	cell_data.speed = randf_range(45.0, 100.0)
	cell_data.size = randf_range(10.0, 24.0)
	cell_data.health = cell_data.max_health
	add_child(cell_data)

	behavior = BEHAVIOR_SCRIPT.new()
	add_child(behavior)

	fear_system = FEAR_SCRIPT.new()
	add_child(fear_system)

	combat = COMBAT_SCRIPT.new()
	combat.damage = cell_data.damage
	combat.cooldown = randf_range(0.35, 0.65)
	add_child(combat)

	add_to_group("SimCells")
	_base_color = Color.from_hsv(randf(), 0.55, 0.95)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if cell_data == null or not cell_data.alive:
		return

	combat.update(delta)
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	_retarget_timer -= delta

	if is_player_controlled:
		_process_player()
	else:
		_process_ai()

	velocity = _direction * cell_data.speed
	move_and_slide()
	_process_contacts()
	queue_redraw()

func _process_player() -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_direction = input_direction.normalized()

func _process_ai() -> void:
	if _retarget_timer <= 0.0 or not is_instance_valid(_target):
		_target = _find_best_target()
		_retarget_timer = 0.15

	if not is_instance_valid(_target):
		_wander()
		return

	var target_data = _target.get("cell_data")
	if target_data == null or not target_data.alive:
		_target = null
		return

	var decision: String = fear_system.evaluate(cell_data, target_data)
	behavior.evaluate_cell(cell_data, target_data)

	if decision == "FLEE":
		_direction = _target.global_position.direction_to(global_position)
	else:
		_direction = global_position.direction_to(_target.global_position)

func _find_best_target() -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_distance: float = perception_radius

	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if candidate == self or not is_instance_valid(candidate):
			continue
		if not candidate.has_method("get_cell_power"):
			continue

		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance

	return best

func get_cell_power() -> float:
	return cell_data.health + cell_data.damage + cell_data.speed + cell_data.size

func _process_contacts() -> void:
	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if candidate == self or not is_instance_valid(candidate):
			continue
		if not candidate.has_method("get_cell_power"):
			continue

		var other_data = candidate.get("cell_data")
		if other_data == null or not other_data.alive:
			continue

		var contact_distance: float = cell_data.size + other_data.size + contact_margin
		if global_position.distance_to(candidate.global_position) <= contact_distance:
			if get_cell_power() >= candidate.get_cell_power():
				combat.attack(candidate)
				if not other_data.alive:
					_target = null
				candidate.queue_redraw()

func take_damage(amount: float) -> void:
	if cell_data == null:
		return
	cell_data.take_damage(amount)
	_flash_timer = 0.08
	if not cell_data.alive:
		queue_free()

func _wander() -> void:
	if _retarget_timer <= -0.5 or _direction.length_squared() < 0.01:
		_direction = Vector2.from_angle(randf_range(0.0, TAU))
		_retarget_timer = 0.5
	else:
		_direction = _direction.lerp(Vector2.from_angle(randf_range(0.0, TAU)), 0.03).normalized()
	_direction *= wander_speed_factor

func _draw() -> void:
	if cell_data == null:
		return

	var radius: float = cell_data.size
	var color := Color.WHITE if _flash_timer > 0.0 else _base_color
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius * 0.35, color.darkened(0.55))
