extends Node2D

## PROTÓTIPO — gerador procedural de células inimigas.
## Cada célula é construída e configurada diretamente pelo spawner.

@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 20
@export var enemy_lifetime: float = 120.0

@export_category("Common Cell")
@export_range(0.0, 1.0) var white_blood_chance: float = 0.0833333
@export var common_min_size: float = 12.0
@export var common_max_size: float = 22.0
@export var common_min_strength: float = 1.0
@export var common_max_strength: float = 2.0
@export var common_vision_radius: float = 180.0
@export var common_speed: float = 55.0

@export_category("White Blood Cell")
@export var white_blood_min_size: float = 28.0
@export var white_blood_max_size: float = 40.0
@export var white_blood_min_strength: float = 4.0
@export var white_blood_max_strength: float = 7.0
@export var white_blood_vision_radius: float = 230.0
@export var white_blood_speed: float = 45.0

@export_category("Seed-based Stats")
@export var common_min_health: float = 30.0
@export var common_max_health: float = 60.0
@export var common_min_damage: float = 5.0
@export var common_max_damage: float = 10.0
@export var white_blood_min_health: float = 90.0
@export var white_blood_max_health: float = 140.0
@export var white_blood_min_damage: float = 12.0
@export var white_blood_max_damage: float = 20.0
@export_range(0.0, 1.0) var seed_stat_variation: float = 0.15

var _player: Node2D
var _timer: Timer


func _ready() -> void:
	_find_player.call_deferred()

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.timeout.connect(spawn_enemy)
	add_child(_timer)
	_timer.start()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
	if _player == null:
		print("PlayerCharacter não encontrado.")


func spawn_enemy() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	if _player == null:
		return

	if get_tree().get_nodes_in_group("EnemyCharacter").size() >= max_enemies:
		return

	var is_white_blood_cell := randf() <= white_blood_chance
	var size: float
	var strength: float
	var vision_radius: float
	var speed: float
	var cell_type: String
	var base_health: float
	var base_damage: float

	if is_white_blood_cell:
		size = randf_range(white_blood_min_size, white_blood_max_size)
		strength = randf_range(white_blood_min_strength, white_blood_max_strength)
		vision_radius = white_blood_vision_radius
		speed = white_blood_speed
		cell_type = "white_blood_cell"
		base_health = randf_range(white_blood_min_health, white_blood_max_health)
		base_damage = randf_range(white_blood_min_damage, white_blood_max_damage)
	else:
		size = randf_range(common_min_size, common_max_size)
		strength = randf_range(common_min_strength, common_max_strength)
		vision_radius = common_vision_radius
		speed = common_speed
		cell_type = "common_cell"
		base_health = randf_range(common_min_health, common_max_health)
		base_damage = randf_range(common_min_damage, common_max_damage)

	var visual_seed := randi()
	var enemy := CellEnemy.new()
	enemy.configure(
		_player,
		cell_type,
		size,
		strength,
		vision_radius,
		speed,
		enemy_lifetime,
		visual_seed,
		base_health,
		base_damage,
		seed_stat_variation
	)
	enemy.add_to_group("EnemyCharacter")

	var angle := randf() * TAU
	var distance := randf_range(spawn_radius * 0.8, spawn_radius)
	var offset := Vector2.RIGHT.rotated(angle) * distance
	enemy.global_position = _player.global_position + offset

	get_tree().current_scene.add_child(enemy)


class CellEnemy extends CharacterBody2D:
	var player: Node2D
	var cell_type: String = "common_cell"
	var cell_size: float = 20.0
	var strength: float = 1.0
	var vision_radius: float = 180.0
	var move_speed: float = 55.0
	var lifetime: float = 120.0
	var visual_seed: int = 0
	var max_health: float = 50.0
	var health: float = 50.0
	var damage: float = 5.0

	var _age: float = 0.0
	var _wander_direction := Vector2.RIGHT
	var _wander_time: float = 0.0
	var _rng := RandomNumberGenerator.new()
	var _visual: ProceduralCellVisual

	func configure(
		target: Node2D,
		type: String,
		size: float,
		power: float,
		vision: float,
		speed: float,
		life: float,
		seed_value: int,
		base_health: float,
		base_damage: float,
		stat_variation: float
	) -> void:
		player = target
		cell_type = type
		cell_size = size
		strength = power
		vision_radius = vision
		move_speed = speed
		lifetime = life
		visual_seed = seed_value
		_rng.seed = visual_seed

		var health_factor := _rng.randf_range(1.0 - stat_variation, 1.0 + stat_variation)
		var damage_factor := _rng.randf_range(1.0 - stat_variation, 1.0 + stat_variation)
		var speed_factor := _rng.randf_range(1.0 - stat_variation, 1.0 + stat_variation)

		max_health = base_health * health_factor
		health = max_health
		damage = base_damage * damage_factor
		move_speed *= speed_factor

	func _ready() -> void:
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = cell_size
		collision.shape = shape
		add_child(collision)

		_visual = ProceduralCellVisual.new()
		_visual.radius = cell_size
		_visual.cell_type = cell_type
		_visual.visual_seed = visual_seed
		add_child(_visual)

		_wander_direction = Vector2.from_angle(_rng.randf_range(0.0, TAU))
		_wander_time = _rng.randf_range(0.8, 2.5)

	func _physics_process(delta: float) -> void:
		_age += delta
		if _age >= lifetime:
			queue_free()
			return

		if player == null or not is_instance_valid(player):
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * 2.0 * delta)
			move_and_slide()
			return

		var distance_to_player := global_position.distance_to(player.global_position)
		var desired_velocity := Vector2.ZERO

		if distance_to_player <= vision_radius:
			var direction := global_position.direction_to(player.global_position)
			desired_velocity = direction * move_speed
		else:
			_wander_time -= delta
			if _wander_time <= 0.0:
				_wander_direction = _wander_direction.rotated(_rng.randf_range(-1.0, 1.0)).normalized()
				_wander_time = _rng.randf_range(1.0, 3.0)
			desired_velocity = _wander_direction * move_speed * _rng.randf_range(0.55, 1.0)

		velocity = velocity.move_toward(desired_velocity, move_speed * 3.0 * delta)
		move_and_slide()

		if _visual != null:
			_visual.set_motion(velocity, delta)


class ProceduralCellVisual extends Node2D:
	var radius: float = 20.0
	var cell_type: String = "common_cell"
	var visual_seed: int = 0
	var _points := PackedVector2Array()
	var _motion := Vector2.ZERO
	var _pulse := 0.0

	func _ready() -> void:
		_generate_shape()
		queue_redraw()

	func _generate_shape() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = visual_seed
		_points.clear()
		var point_count := rng.randi_range(9, 13)
		for i in range(point_count):
			var angle := TAU * float(i) / float(point_count)
			var variation := rng.randf_range(0.82, 1.18)
			_points.append(Vector2.from_angle(angle) * radius * variation)

	func set_motion(_current_velocity: Vector2, delta: float) -> void:
		_pulse += delta
		queue_redraw()

	func _draw() -> void:
		if _points.is_empty():
			return

		var base_color: Color
		if cell_type == "white_blood_cell":
			base_color = Color(0.82, 0.9, 1.0, 1.0)
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = visual_seed + 1
			base_color = Color.from_hsv(rng.randf(), 0.65, 0.9)

		var pulse := 1.0 + sin(_pulse * 3.0) * 0.025
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_colored_polygon(_points, base_color)

		if cell_type == "white_blood_cell":
			draw_circle(Vector2.ZERO, radius * 0.34, base_color.darkened(0.35))
		else:
			var nucleus_rng := RandomNumberGenerator.new()
			nucleus_rng.seed = visual_seed + 2
			var nucleus_position := Vector2.from_angle(nucleus_rng.randf_range(0.0, TAU)) * radius * 0.12
			draw_circle(nucleus_position, radius * 0.30, base_color.darkened(0.35))

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
