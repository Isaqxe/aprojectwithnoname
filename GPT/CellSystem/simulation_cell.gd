extends Node2D

## Simple visual cell used by the simulation prototype.

var health: float
var damage: float
var speed: float
var size: float
var fear: float
var is_player: bool = false

func setup(data: Dictionary) -> void:
	health = data.get("health", randf_range(20.0, 100.0))
	damage = data.get("damage", randf_range(5.0, 20.0))
	speed = data.get("speed", randf_range(30.0, 90.0))
	size = data.get("size", randf_range(8.0, 20.0))
	fear = data.get("fear", randf_range(0.0, 1.0))
	is_player = data.get("is_player", false)

func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, size, Color.WHITE)
