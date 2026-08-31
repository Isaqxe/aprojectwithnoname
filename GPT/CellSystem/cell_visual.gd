extends Node2D

## Lightweight procedural visual for a simulation cell.
## Gameplay physics remains on the simulation cell; this node only renders the cell.

@export var point_count: int = 20
@export var idle_wobble: float = 0.018
@export var visual_update_hz: float = 20.0
@export var health_bar_width: float = 42.0
@export var health_bar_height: float = 5.0
@export var health_bar_offset: float = 8.0

var _points: Array[Vector2] = []
var _radii: Array[float] = []
var _seed: int = 1
var _time: float = 0.0
var _visual_timer: float = 0.0
var _elongation: Vector2 = Vector2.ONE
var _asymmetry: Vector2 = Vector2.ZERO

func _ready() -> void:
	var parent_cell: Node = get_parent()
	_seed = 1
	if parent_cell != null:
		var identity_node: Node = parent_cell.get("genetics") as Node
		if identity_node != null and is_instance_valid(identity_node):
			_seed = abs(String(identity_node.get("cell_id")).hash()) + 1
		else:
			_seed = abs(int(parent_cell.get_instance_id())) + 1
	_build_shape()
	set_process(visual_update_hz > 0.0)
	queue_redraw()

func _build_shape() -> void:
	_points.clear()
	_radii.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_elongation = Vector2(rng.randf_range(0.97, 1.03), rng.randf_range(0.97, 1.03))
	_asymmetry = Vector2(rng.randf_range(-0.025, 0.025), rng.randf_range(-0.025, 0.025))
	for i in range(point_count):
		var angle: float = TAU * float(i) / float(point_count)
		var radius_factor: float = rng.randf_range(0.95, 1.05)
		_radii.append(radius_factor)
		_points.append(Vector2.from_angle(angle) * radius_factor)

func _process(delta: float) -> void:
	_time += delta
	_visual_timer += delta
	var update_interval: float = 1.0 / maxf(visual_update_hz, 1.0)
	if _visual_timer < update_interval:
		return
	_visual_timer = 0.0

	var parent_cell: Node2D = get_parent() as Node2D
	if parent_cell == null or not is_instance_valid(parent_cell):
		return
	var cell_data: Node = parent_cell.get("cell_data") as Node
	if cell_data == null or not is_instance_valid(cell_data):
		return

	var radius: float = maxf(float(cell_data.get("size")), 4.0)
	for i in range(_points.size()):
		var angle: float = TAU * float(i) / float(_points.size())
		var direction: Vector2 = Vector2.from_angle(angle)
		var local_wobble: float = sin(_time * 2.0 + float(i) * 0.73 + float(_seed % 97)) * idle_wobble
		var morphology_factor: float = 1.0 + direction.x * _asymmetry.x + direction.y * _asymmetry.y
		var target_radius: float = radius * (_radii[i] + local_wobble) * morphology_factor
		_points[i] = Vector2(direction.x * _elongation.x, direction.y * _elongation.y) * target_radius

	queue_redraw()

func _is_presentation_mode() -> bool:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return false
	var mode_value: Variant = scene.get("presentation_mode")
	return bool(mode_value) if mode_value != null else false

func _draw() -> void:
	var parent_cell: Node = get_parent()
	if parent_cell == null or not is_instance_valid(parent_cell):
		return
	var cell_data: Node = parent_cell.get("cell_data") as Node
	if cell_data == null or not is_instance_valid(cell_data):
		return

	var base_color: Color = Color.WHITE
	var parent_color: Variant = parent_cell.get("species_color")
	if parent_color is Color:
		base_color = parent_color

	if float(cell_data.get("health")) < float(cell_data.get("max_health")):
		var flash_timer: float = float(parent_cell.get("_flash_timer"))
		if flash_timer > 0.0:
			base_color = Color(0.9, 0.95, 1.0, 1.0)

	var membrane_points := PackedVector2Array(_points)
	if membrane_points.size() >= 3:
		draw_colored_polygon(membrane_points, base_color)
		draw_polyline(membrane_points, base_color.darkened(0.20), 1.5, true)

	var radius: float = maxf(float(cell_data.get("size")), 4.0)
	var nucleus_radius: float = radius * 0.34
	var nucleus_color: Color = base_color.darkened(0.22)
	draw_circle(Vector2.ZERO, nucleus_radius, nucleus_color)

	var organelle_color: Color = base_color.lightened(0.12)
	var organelle_distance: float = radius * 0.48
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0 + float(_seed % 31) * 0.01
		var p: Vector2 = Vector2.from_angle(angle) * organelle_distance
		draw_circle(p, maxf(radius * 0.055, 1.0), organelle_color)

	var health: float = float(cell_data.get("health"))
	var max_health: float = maxf(float(cell_data.get("max_health")), 0.001)
	if not _is_presentation_mode() and health < max_health - 0.01 and bool(cell_data.get("alive")):
		var ratio: float = clampf(health / max_health, 0.0, 1.0)
		var bar_width: float = maxf(health_bar_width, radius * 1.6)
		var bar_height: float = maxf(health_bar_height, 2.0)
		var bar_top: float = -radius - health_bar_offset - bar_height
		var bar_left: float = -bar_width * 0.5
		draw_rect(Rect2(bar_left, bar_top, bar_width, bar_height), Color(0.08, 0.08, 0.08, 0.85), true)
		draw_rect(Rect2(bar_left, bar_top, bar_width * ratio, bar_height), Color(0.35, 0.9, 0.35, 1.0), true)
