extends CharacterBody2D

@export_category("Base")
@export var resources_collected: int = 0
@export var visual_seed: int = 12345
@export var cell_type: String = "eukaryote"
@export var cell_size: float = 24.0

@export_category("Stats")
@export var base_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_speed: float = 150.0
@export var damage_cooldown: float = 0.5

var health: float
var damage: float
var speed: float
var _damage_cooldown_timer: float = 0.0

var _visual: ProceduralCellVisual


func _ready() -> void:
	_generate_stats_from_seed()
	_create_visual()


func _generate_stats_from_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed

	var health_factor := rng.randf_range(0.90, 1.10)
	var damage_factor := rng.randf_range(0.90, 1.10)
	var speed_factor := rng.randf_range(0.90, 1.10)

	if cell_type == "prokaryote":
		health_factor *= 0.90
		damage_factor *= 0.95
		speed_factor *= 1.10
	else:
		health_factor *= 1.10
		damage_factor *= 1.05
		speed_factor *= 0.95

	health = base_health * health_factor
	damage = base_damage * damage_factor
	speed = base_speed * speed_factor


func _create_visual() -> void:
	_visual = ProceduralCellVisual.new()
	_visual.radius = cell_size
	_visual.cell_type = cell_type
	_visual.visual_seed = visual_seed
	add_child(_visual)


func _physics_process(delta: float) -> void:
	if _damage_cooldown_timer > 0.0:
		_damage_cooldown_timer -= delta

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	).normalized()

	if Input.is_action_just_pressed("ui_up"):
		print("HP: ", health, " | Dano: ", damage, " | Velocidade: ", speed, " | Recursos: ", resources_collected)

	velocity = direction * speed
	move_and_slide()
	_check_enemy_collisions()

	if _visual != null:
		_visual.set_motion(velocity, delta)


func _check_enemy_collisions() -> void:
	if _damage_cooldown_timer > 0.0:
		return

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider is Node and collider.is_in_group("EnemyCharacter"):
			var incoming_damage: float = collider.get("damage") if "damage" in collider else 1.0
			take_damage(incoming_damage)
			return


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	_damage_cooldown_timer = damage_cooldown

	print("Player recebeu ", amount, " de dano. HP restante: ", health)

	if health <= 0.0:
		_die()


func _die() -> void:
	print("Player morreu.")
	set_physics_process(false)


class ProceduralCellVisual extends Node2D:
	var radius: float = 24.0
	var cell_type: String = "eukaryote"
	var visual_seed: int = 12345
	var _points := PackedVector2Array()
	var _pulse: float = 0.0

	func _ready() -> void:
		_generate_shape()
		queue_redraw()

	func _generate_shape() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = visual_seed
		_points.clear()

		var point_count := 11
		for i in range(point_count):
			var angle := TAU * float(i) / float(point_count)
			var variation := rng.randf_range(0.84, 1.16)
			_points.append(Vector2.from_angle(angle) * radius * variation)

	func set_motion(_current_velocity: Vector2, delta: float) -> void:
		_pulse += delta
		queue_redraw()

	func _draw() -> void:
		if _points.is_empty():
			return

		var base_color := Color(0.35, 0.8, 1.0, 1.0)
		var pulse := 1.0 + sin(_pulse * 3.0) * 0.025

		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_colored_polygon(_points, base_color)

		if cell_type == "eukaryote":
			draw_circle(Vector2.ZERO, radius * 0.34, Color(0.15, 0.28, 0.55, 1.0))
			draw_circle(Vector2.ZERO, radius * 0.18, Color(0.25, 0.45, 0.8, 1.0))
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = visual_seed + 1
			for i in range(4):
				var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(radius * 0.25, radius * 0.55)
				draw_circle(p, radius * 0.045, Color(0.2, 0.35, 0.6, 1.0))

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
