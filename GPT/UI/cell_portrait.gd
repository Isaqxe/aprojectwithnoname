extends Control

## Lightweight portrait used by the Inspector and lineage tree.
## It draws from a stored snapshot and never references the live cell node.

var cell_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	cell_data = data.duplicate(true)
	custom_minimum_size = Vector2(86.0, 86.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var cell_size: float = clampf(float(cell_data.get("size", 18.0)), 10.0, 28.0)
	var radius: float = minf(minf(size.x, size.y) * 0.34, cell_size * 1.7)
	var color_value: Variant = cell_data.get("species_color", Color(0.8, 0.9, 1.0))
	var cell_color: Color = color_value if color_value is Color else Color.WHITE
	if not bool(cell_data.get("alive", true)):
		cell_color = cell_color.darkened(0.55)

	draw_circle(center, radius + 4.0, Color(0.05, 0.08, 0.12, 0.55))
	draw_circle(center, radius, cell_color)
	draw_circle(center, radius * 0.72, cell_color.lightened(0.08))
	draw_circle(center + Vector2(-radius * 0.18, -radius * 0.18), maxf(radius * 0.18, 2.0), cell_color.lightened(0.28))
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.35), 1.5)
