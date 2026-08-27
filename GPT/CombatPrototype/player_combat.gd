extends CharacterBody2D

## Prototype: Player usando o mesmo sistema de célula dos inimigos.

@export var base_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_speed: float = 150.0
@export var damage_cooldown: float = 0.5

var health: float
var damage: float
var speed: float
var _damage_timer: float = 0.0


func _ready() -> void:
	add_to_group("PlayerCharacter")
	health = base_health
	damage = base_damage
	speed = base_speed


func _physics_process(delta: float) -> void:
	_damage_timer = maxf(_damage_timer - delta, 0.0)

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction.normalized() * speed
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
		_die()


func _die() -> void:
	print("Célula do jogador destruída")
	set_physics_process(false)
