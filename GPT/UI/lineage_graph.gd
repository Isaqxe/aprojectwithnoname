extends Control

## Draws lightweight connectors behind lineage cards.

var parent_card: Control
var current_card: Control
var child_cards: Array[Control] = []

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	var connector_color := Color(0.7, 0.8, 0.9, 0.65)
	var width := 2.0

	if is_instance_valid(parent_card) and is_instance_valid(current_card):
		var parent_point := Vector2(parent_card.position.x + parent_card.size.x * 0.5, parent_card.position.y + parent_card.size.y)
		var current_point := Vector2(current_card.position.x + current_card.size.x * 0.5, current_card.position.y)
		draw_line(parent_point, current_point, connector_color, width)

	if not is_instance_valid(current_card) or child_cards.is_empty():
		return

	var current_bottom := Vector2(current_card.position.x + current_card.size.x * 0.5, current_card.position.y + current_card.size.y)
	var junction_y: float = current_bottom.y + 22.0
	draw_line(current_bottom, Vector2(current_bottom.x, junction_y), connector_color, width)

	var child_points: Array[Vector2] = []
	for card in child_cards:
		if not is_instance_valid(card):
			continue
		child_points.append(Vector2(card.position.x + card.size.x * 0.5, card.position.y))

	if child_points.is_empty():
		return

	draw_line(Vector2(child_points[0].x, junction_y), Vector2(child_points[-1].x, junction_y), connector_color, width)
	for point in child_points:
		draw_line(Vector2(point.x, junction_y), point, connector_color, width)
