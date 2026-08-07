extends CharacterBody2D

@export var speed: float = 100.0

var _player: Node2D


func _ready() -> void:
	_find_player.call_deferred()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	if _player == null:
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(_player.global_position)
	velocity = direction * speed
	move_and_slide()
