extends CharacterBody2D

## Prototype: sistema de combate por contato + comportamento base para Fear.

@export var speed: float = 100.0
@export var vision_radius: float = 180.0
@export var lifetime: float = 120.0

@export var base_health: float = 50.0
@export var base_damage: float = 5.0
@export var damage_cooldown: float = 0.5

var health: float
var damage: float
var _damage_timer: float = 0.0
var _life_timer: float = 0.0


func _ready() -> void:
	add_to_group("EnemyCharacter")
	health = base_health
	damage = base_damage


func _physics_process(delta: float) -> void:
	_life_timer += delta
	_damage_timer = maxf(_damage_timer - delta, 0.0)

	if _life_timer >= lifetime:
		queue_free()
		return

	var target := get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
	if target != null:
		var distance := global_position.distance_to(target.global_position)
		if distance <= vision_radius:
			velocity = global_position.direction_to(target.global_position) * speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()

	_check_contact_damage()


func _check_contact_damage() -> void:
	if _damage_timer > 0.0:
		return

	for i in range(get_slide_collision_count()):
		var collider := get_slide_collision(i).get_collider()
		if collider is Node and collider.has_method("take_damage"):
			collider.take_damage(damage)
			_damage_timer = damage_cooldown
			return


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
