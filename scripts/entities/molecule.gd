extends Area2D

@export var molecule_color: Color = Color(0.3, 0.9, 1.0)
@export var min_scale: float = 0.7
@export var max_scale: float = 1.25

func _ready() -> void:
	var random_scale := randf_range(min_scale, max_scale)
	scale = Vector2.ONE * random_scale
	$Core.modulate = molecule_color
	$Glow.modulate = Color(molecule_color.r, molecule_color.g, molecule_color.b, 0.45)
