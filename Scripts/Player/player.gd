extends CharacterBody2D

@export var speed: float = 200.0

func _ready() -> void:
	add_to_group("PlayerCharacter")

func _physics_process(_delta):
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	).normalized() 

	velocity = direction * speed

	move_and_slide()
