extends Area2D

@export var radius: float = 7.0
@export var core_color: Color = Color(0.35, 0.9, 1.0, 1.0)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("PlayerCharacter"):
		return

	body.resources_collected += 1
	queue_free()

func _draw() -> void:
	# Outer halo: deliberately soft-looking circles that react nicely to WorldEnvironment glow.
	draw_circle(Vector2.ZERO, radius * 2.4, Color(core_color.r, core_color.g, core_color.b, 0.08))
	draw_circle(Vector2.ZERO, radius * 1.65, Color(core_color.r, core_color.g, core_color.b, 0.16))
	draw_circle(Vector2.ZERO, radius, core_color)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 1.0, 1.0, 0.85))
