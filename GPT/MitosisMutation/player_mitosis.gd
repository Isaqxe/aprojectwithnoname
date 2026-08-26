extends CharacterBody2D

## Cópia experimental do Player dedicada ao sistema de Mitose e Mutação.
## A versão principal do Player não é alterada por este protótipo.
##
## Arquitetura atual:
## NORMAL -> MITOSIS -> cria descendente -> NORMAL
##
## A descendente herda o tipo celular, tamanho e cor, mas recebe uma nova
## visual_seed para representar variação entre gerações.

@export_category("Base")
@export var resources_collected: int = 0
@export var visual_seed: int = 12345
@export var cell_type: String = "eukaryote"
@export var cell_size: float = 24.0
@export var cell_color: Color = Color(0.35, 0.8, 1.0, 1.0)
@export var is_primary_player: bool = true

@export_category("Stats")
@export var base_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_speed: float = 150.0
@export var damage_cooldown: float = 0.5

@export_category("Mitosis")
@export var mitosis_resource_cost: int = 50
@export var mitosis_pause_duration: float = 1.5
@export var can_mitosis: bool = true
@export var child_offset_distance: float = 48.0

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
var _last_child: CharacterBody2D

var _mitosis_state: MitosisState = MitosisState.NORMAL

enum MitosisState {
	NORMAL,
	MITOSIS
}


func _ready() -> void:
	_generate_stats_from_seed()
	_create_visual()
	_create_mitosis_particles()

	if is_primary_player:
		add_to_group("PlayerCharacter")


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
	_visual.cell_color = cell_color
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
	material.color = cell_color

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
		Color(cell_color.r, cell_color.g, cell_color.b, 0.0)
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

	if not is_primary_player:
		velocity = Vector2.ZERO
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
			" | Seed: ", visual_seed,
			" | Cor: ", cell_color,
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
	_spawn_daughter_cell()

	_mitosis_state = MitosisState.NORMAL
	generation += 1

	if _mitosis_particles != null:
		_mitosis_particles.emitting = false

	if _visual != null:
		_visual.set_mitosis_state(false, 0.0)

	print("Mitose concluída. Nova geração: ", generation)


func _spawn_daughter_cell() -> void:
	var daughter := CharacterBody2D.new()
	daughter.set_script(get_script())
	daughter.name = "DaughterCell_G%d" % (generation + 1)
	daughter.global_position = global_position + Vector2.RIGHT * child_offset_distance

	# Herança: identidade biológica, tamanho e cor são mantidos.
	daughter.cell_type = cell_type
	daughter.cell_size = cell_size
	daughter.cell_color = cell_color
	daughter.base_health = base_health
	daughter.base_damage = base_damage
	daughter.base_speed = base_speed
	daughter.damage_cooldown = damage_cooldown

	# Variação entre gerações: a descendente recebe uma nova seed visual.
	# A cor permanece a mesma, representando a característica herdada.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	daughter.visual_seed = rng.randi()

	daughter.resources_collected = 0
	daughter.generation = generation + 1
	daughter.can_mitosis = false
	daughter.is_primary_player = false

	get_parent().add_child(daughter)
	_last_child = daughter

	print(
		"Descendente criada | geração: ", daughter.generation,
		" | seed: ", daughter.visual_seed,
		" | cor herdada: ", daughter.cell_color
	)


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
	var cell_color: Color = Color(0.35, 0.8, 1.0, 1.0)
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

		var pulse := 1.0 + sin(_pulse * (6.0 if _in_mitosis else 3.0)) * (0.05 if _in_mitosis else 0.025)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_colored_polygon(_points, cell_color)

		if cell_type == "eukaryote":
			draw_circle(Vector2.ZERO, radius * 0.34, cell_color.darkened(0.55))
			draw_circle(Vector2.ZERO, radius * 0.18, cell_color.darkened(0.30))
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = visual_seed + 1
			for i in range(4):
				var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(radius * 0.25, radius * 0.55)
				draw_circle(p, radius * 0.045, cell_color.darkened(0.45))

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
