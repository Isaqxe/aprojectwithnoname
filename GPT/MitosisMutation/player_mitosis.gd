extends CharacterBody2D

## Cópia experimental do Player dedicada ao sistema de Mitose e Mutação.
## A versão principal do Player não é alterada por este protótipo.
##
## Arquitetura inicial:
## NORMAL -> MITOSIS -> NORMAL
##
## A primeira versão da mitose é propositalmente simples: ao atingir o
## requisito de recursos, o Player entra em estado de mitose, interrompe
## temporariamente sua movimentação e emite partículas. A divisão real e a
## mutação genética serão integradas em etapas posteriores.

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

@export_category("Mitosis")
@export var mitosis_resource_cost: int = 50
@export var mitosis_pause_duration: float = 1.5
@export var can_mitosis: bool = true

@export_category("Mitosis Visual")
@export var emit_mitosis_particles: bool = true
@export var particle_count: int = 48
@export var particle_lifetime: float = 1.0
@export var particle_spread: float = 360.0
@export var particle_speed_min: float = 20.0
@export var particle_speed_max: float = 80.0

var health: float
var damage: float
var speed: float
var generation: int = 1

var _damage_cooldown_timer: float = 0.0
var _mitosis_timer: float = 0.0
var _mitosis_particles: GPUParticles2D
var _visual: ProceduralCellVisual

var _mitosis_state: MitosisState = MitosisState.NORMAL

enum MitosisState {
	NORMAL,
	MITOSIS
}


func _ready() -> void:
	_generate_stats_from_seed()
	_create_visual()
	_create_mitosis_particles()


func _generate_stats_from_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed

	var health_factor: float = rng.randf_range(0.90, 1.10)
	var damage_factor: float = rng.randf_range(0.90, 1.10)
	var speed_factor: float = rng.randf_range(0.90, 1.10)

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


func _create_mitosis_particles() -> void:
	_mitosis_particles = GPUParticles2D.new()
	_mitosis_particles.name = "MitosisParticles"
	_mitosis_particles.emitting = false
	_mitosis_particles.amount = particle_count
	_mitosis_particles.lifetime = particle_lifetime
	_mitosis_particles.explosiveness = 1.0
	_mitosis_particles.local_coords = false

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = cell_size * 0.7
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = particle_spread
	material.initial_velocity_min = particle_speed_min
	material.initial_velocity_max = particle_speed_max
	material.gravity = Vector3.ZERO
	material.scale_min = 0.5
	material.scale_max = 1.2
	material.color = Color(0.35, 0.8, 1.0, 0.9)

	_mitosis_particles.process_material = material
	add_child(_mitosis_particles)

	var particle_texture := GradientTexture2D.new()
	particle_texture.width = 8
	particle_texture.height = 8
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(1.0, 0.5)

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(0.35, 0.8, 1.0, 0.0)
	])
	particle_texture.gradient = gradient
	_mitosis_particles.texture = particle_texture


func _physics_process(delta: float) -> void:
	_update_damage_cooldown(delta)
	_update_mitosis(delta)

	if _mitosis_state == MitosisState.MITOSIS:
		velocity = Vector2.ZERO
		if _visual != null:
			_visual.set_mitosis_state(true, delta)
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	).normalized()

	if Input.is_action_just_pressed("ui_up"):
		print(
			"HP: ", health,
			" | Dano: ", damage,
			" | Velocidade: ", speed,
			" | Recursos: ", resources_collected,
			" | Geração: ", generation,
			" | Posição: ", global_position
		)

	velocity = direction * speed
	move_and_slide()
	_check_enemy_collisions()

	if Input.is_action_just_pressed("ui_mitosis"):
		try_start_mitosis()

	if _visual != null:
		_visual.set_motion(velocity, delta)


func _update_damage_cooldown(delta: float) -> void:
	if _damage_cooldown_timer > 0.0:
		_damage_cooldown_timer = maxf(_damage_cooldown_timer - delta, 0.0)


func _update_mitosis(delta: float) -> void:
	if _mitosis_state != MitosisState.MITOSIS:
		return

	_mitosis_timer -= delta
	if _mitosis_timer <= 0.0:
		_finish_mitosis()


func try_start_mitosis() -> bool:
	if not can_mitosis:
		return false
	if _mitosis_state != MitosisState.NORMAL:
		return false
	if resources_collected < mitosis_resource_cost:
		return false

	_start_mitosis()
	return true


func _start_mitosis() -> void:
	_mitosis_state = MitosisState.MITOSIS
	_mitosis_timer = mitosis_pause_duration
	resources_collected -= mitosis_resource_cost
	velocity = Vector2.ZERO

	if _mitosis_particles != null and emit_mitosis_particles:
		_mitosis_particles.restart()
		_mitosis_particles.emitting = true

	print("Mitose iniciada. Geração atual: ", generation)


func _finish_mitosis() -> void:
	_mitosis_state = MitosisState.NORMAL
	generation += 1

	if _mitosis_particles != null:
		_mitosis_particles.emitting = false

	if _visual != null:
		_visual.set_mitosis_state(false, 0.0)

	print("Mitose concluída. Nova geração: ", generation)


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
	if amount <= 0.0 or _mitosis_state == MitosisState.MITOSIS:
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
	var _in_mitosis: bool = false

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

	func set_mitosis_state(active: bool, delta: float) -> void:
		_in_mitosis = active
		if active:
			_pulse += delta * 2.0
		queue_redraw()

	func _draw() -> void:
		if _points.is_empty():
			return

		var base_color := Color(0.35, 0.8, 1.0, 1.0)
		var pulse := 1.0 + sin(_pulse * (6.0 if _in_mitosis else 3.0)) * (0.05 if _in_mitosis else 0.025)
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
