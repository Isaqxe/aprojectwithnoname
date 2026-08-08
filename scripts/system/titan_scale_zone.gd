extends Area2D

@export var titan_scale: float = 0.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_meta("titan_scaled"):
		return

	body.scale *= titan_scale
	body.set_meta("titan_scaled", true)
