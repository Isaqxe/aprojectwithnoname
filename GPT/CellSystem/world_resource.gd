extends Area2D

## Lightweight procedural visual for a collectible resource.
## Gameplay remains unchanged: the node still exposes amount, collect() and the WorldResources group.

@export var amount: float = 25.0
@export var radius: float = 6.0
@export var pulse_speed: float = 2.0
@export var pulse_amount: float = 0.08

var _time: float = 0.0
var _visual_seed: int = 1
var _orbit_angles: Array[float] = []
var _orbit_distances: Array[float] = []

func _ready() -> void:
	add_to_group("WorldResources")
	_visual_seed = abs(int(get_instance_id())) + 1
	_build_visual_variation()
	queue_redraw()

func _build_visual_variation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _visual_seed
	_orbit_angles.clear()
	_orbit_distances.clear()
	for index in range(3):
		_orbit_angles.append(rng.randf_range(0.0, TAU))
		_orbit_distances.append(rng.randf_range(0.75, 1.15))

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func collect() -> float:
	var collected: float = amount
	amount = 0.0
	queue_free()
	return collected

func _draw() -> void:
	var pulse: float = 1.0 + sin(_time * pulse_speed + float(_visual_seed % 31)) * pulse_amount
	var outer_radius: float = radius * pulse

	# Soft visual halo. Kept small so a dense resource field remains readable.
	draw_circle(Vector2.ZERO, outer_radius * 1.85, Color(0.30, 0.95, 0.62, 0.08))
	draw_circle(Vector2.ZERO, outer_radius * 1.35, Color(0.35, 0.98, 0.68, 0.15))

	# Organic-looking core with two layers instead of a flat dot.
	draw_circle(Vector2.ZERO, outer_radius, Color(0.20, 0.82, 0.48, 1.0))
	draw_circle(Vector2(-outer_radius * 0.18, -outer_radius * 0.18), outer_radius * 0.58, Color(0.58, 1.0, 0.76, 0.95))
	draw_circle(Vector2(-outer_radius * 0.30, -outer_radius * 0.34), outer_radius * 0.20, Color(0.90, 1.0, 0.94, 0.92))

	# Three tiny internal/orbital accents provide individual variation without sprites.
	for index in range(_orbit_angles.size()):
		var angle: float = _orbit_angles[index] + _time * (0.25 + index * 0.08)
		var distance: float = outer_radius * _orbit_distances[index]
		var point: Vector2 = Vector2.from_angle(angle) * distance
		draw_circle(point, maxf(outer_radius * 0.11, 0.8), Color(0.76, 1.0, 0.86, 0.80))
