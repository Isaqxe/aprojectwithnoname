extends Area2D

## Simple collectible resource node for the CellSystem test ecosystem.

@export var amount: float = 25.0
@export var radius: float = 6.0

func _ready() -> void:
	queue_redraw()

func collect() -> float:
	var collected: float = amount
	amount = 0.0
	queue_free()
	return collected

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.35, 0.95, 0.55, 1.0))
	draw_circle(Vector2.ZERO, radius * 0.4, Color(0.8, 1.0, 0.85, 1.0))
