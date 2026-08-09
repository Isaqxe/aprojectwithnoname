extends CharacterBody2D

@export var speed: float = 200.0
@export var resources_collected: int = 0

func _ready() -> void:
	for molecule in get_tree().get_nodes_in_group("Molecule"):
		if molecule is Area2D:
			molecule.body_entered.connect(_on_molecule_body_entered.bind(molecule))

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	).normalized()

	velocity = direction * speed

	move_and_slide()

func _on_molecule_body_entered(body: Node2D, molecule: Area2D) -> void:
	if body != self or not is_instance_valid(molecule):
		return

	resources_collected += 1
	molecule.queue_free()
