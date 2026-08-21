extends CharacterBody2D

@export var speed: float = 200.0
@export var resources_collected: int = 0
@export_category("Procedural Cell")
@export var cell_type: String = "eukaryote"
@export var cell_size: float = 24.0
@export var visual_seed: int = 12345

var _visual: ProceduralCellVisual

func _ready() -> void:
	_visual = ProceduralCellVisual.new()
	_visual.radius = cell_size
	_visual.cell_type = cell_type
	_visual.visual_seed = visual_seed
	add_child(_visual)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	).normalized()

	if Input.is_action_just_pressed("ui_up"):
		print(resources_collected)

	velocity = direction * speed
	move_and_slide()

	if _visual != null:
		_visual.set_motion(velocity, delta)


class ProceduralCellVisual extends Node2D:
	var radius: float = 24.0
	var cell_type: String = "eukaryote"
	var visual_seed: int = 12345
	var _points := PackedVector2Array()
	var _pulse: float = 0.0

	func _ready() -> void:
		_generate_shape()
		queue_redraw()

	func _generate_shape() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = visual_seed
		_points.clear()

		var point_count := 11
		for i in range(point_count):
			var angle := TAU * float(i) / float(point_count)
			var variation := rng.randf_range(0.84, 1.16)
			_points.append(Vector2.from_angle(angle) * radius * variation)

	func set_motion(_current_velocity: Vector2, delta: float) -> void:
		_pulse += delta
		queue_redraw()

	func _draw() -> void:
		if _points.is_empty():
			return

		var base_color := Color(0.35, 0.8, 1.0, 1.0)
		var pulse := 1.0 + sin(_pulse * 3.0) * 0.025

		draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
		draw_colored_polygon(_points, base_color)
		draw_arc(Vector2.ZERO, radius * 0.98, 0.0, TAU, 48, Color(0.7, 0.95, 1.0, 1.0), 2.0)

		if cell_type == "eukaryote":
			draw_circle(Vector2.ZERO, radius * 0.34, Color(0.15, 0.28, 0.55, 1.0))
			draw_circle(Vector2.ZERO, radius * 0.18, Color(0.25, 0.45, 0.8, 1.0))
		else:
			var rng := RandomNumberGenerator.new()
			rng.seed = visual_seed + 1
			for i in range(4):
				var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(radius * 0.25, radius * 0.55)
				draw_circle(p, radius * 0.045, Color(0.2, 0.35, 0.6, 1.0))

		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
