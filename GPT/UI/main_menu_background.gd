extends Control

## Static procedural background for the Alive Cells main menu.
## Generated once on startup; no simulation or per-frame animation.

@export var min_cells: int = 1
@export var max_cells: int = 7
@export var resource_count: int = 10
@export var background_seed: int = 48302

var _rng := RandomNumberGenerator.new()
var _cell_positions: Array[Vector2] = []
var _cell_scales: Array[float] = []
var _cell_colors: Array[Color] = []
var _resource_positions: Array[Vector2] = []
var _resource_scales: Array[float] = []

func _ready() -> void:
	_rng.seed = background_seed
	_build_background()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _build_background() -> void:
	_cell_positions.clear()
	_cell_scales.clear()
	_cell_colors.clear()
	_resource_positions.clear()
	_resource_scales.clear()

	var screen_size: Vector2 = get_viewport_rect().size
	var left_reserved: float = screen_size.x * 0.43
	var cell_count: int = _rng.randi_range(min_cells, max_cells)

	for _i in range(cell_count):
		_cell_positions.append(Vector2(
			_rng.randf_range(left_reserved + 50.0, screen_size.x - 100.0),
			_rng.randf_range(90.0, screen_size.y - 90.0)
		))
		_cell_scales.append(_rng.randf_range(0.72, 1.35))
		_cell_colors.append(Color.from_hsv(_rng.randf(), 0.48, 0.93))

	for _i in range(resource_count):
		_resource_positions.append(Vector2(
			_rng.randf_range(left_reserved + 30.0, screen_size.x - 50.0),
			_rng.randf_range(55.0, screen_size.y - 55.0)
		))
		_resource_scales.append(_rng.randf_range(0.65, 1.25))

func _draw() -> void:
	var size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.055, 0.075, 1.0), true)

	var glow_center := Vector2(size.x * 0.76, size.y * 0.46)
	draw_circle(glow_center, 420.0, Color(0.12, 0.42, 0.38, 0.018))
	draw_circle(glow_center, 300.0, Color(0.12, 0.42, 0.38, 0.028))
	draw_circle(glow_center, 190.0, Color(0.12, 0.42, 0.38, 0.028))

	for i in range(_resource_positions.size()):
		var p := _resource_positions[i]
		var s := _resource_scales[i]
		draw_circle(p, 7.0 * s, Color(0.35, 0.95, 0.55, 0.22))
		draw_circle(p, 4.0 * s, Color(0.50, 1.0, 0.70, 0.82))
		draw_circle(p, 1.5 * s, Color(0.88, 1.0, 0.93, 0.95))

	for i in range(_cell_positions.size()):
		var p := _cell_positions[i]
		var s := _cell_scales[i]
		var c := _cell_colors[i]
		var r := 54.0 * s
		draw_circle(p, r * 1.10, Color(c.r, c.g, c.b, 0.07))
		draw_circle(p, r, Color(c.r, c.g, c.b, 0.92))
		draw_circle(p, r * 0.42, c.darkened(0.22))
		draw_circle(p + Vector2(-r * 0.18, -r * 0.18), r * 0.11, Color(1.0, 1.0, 1.0, 0.28))

	var divider_x := size.x * 0.39
	draw_line(Vector2(divider_x, 70.0), Vector2(divider_x, size.y - 70.0), Color(0.70, 0.85, 0.90, 0.08), 2.0)
