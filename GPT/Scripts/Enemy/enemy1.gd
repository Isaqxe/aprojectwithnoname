extends CharacterBody2D

@export var speed: float = 100.0
@export var player_group: StringName = &"PlayerCharacter"


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(player_group) as Node2D

	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	print("Player encontrado em: ", player.global_position)

	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
