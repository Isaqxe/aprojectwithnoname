extends CharacterBody2D

@export var speed: float = 100.0
@export var player_group: StringName = &"PlayerCharacter"
@export var stop_distance: float = 32.0
@export var lifetime: float = 120.0
@export var damage: float = 4.0

var _lifetime_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("EnemyCharacter")


func _physics_process(delta: float) -> void:
	_lifetime_elapsed += delta

	if _lifetime_elapsed >= lifetime:
		queue_free()
		return

	var player := get_tree().get_first_node_in_group(player_group) as Node2D

	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player > stop_distance:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
