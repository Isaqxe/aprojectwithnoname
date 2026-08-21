extends Node2D

## Protótipo experimental de mapa procedural por regiões.
## Gera três faixas simples: Fria → Transição → Quente.
## Ainda não substitui o mapa principal.

@export var map_size := Vector2i(1800, 900)
@export var region_count: int = 3
@export var seed_value: int = 20260821
@export var transition_width: int = 140

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = seed_value
	queue_redraw()

func _draw() -> void:
	var width := float(map_size.x)
	var height := float(map_size.y)
	var region_width := width / float(maxi(region_count, 1))

	# Base das três regiões.
	draw_rect(Rect2(0.0, 0.0, region_width, height), Color(0.17, 0.34, 0.55))
	draw_rect(Rect2(region_width, 0.0, region_width, height), Color(0.24, 0.48, 0.28))
	draw_rect(Rect2(region_width * 2.0, 0.0, region_width, height), Color(0.58, 0.27, 0.13))

	# Faixas de transição com pequenas ondulações para evitar fronteiras perfeitamente retas.
	_draw_transition(region_width, height, -1.0)
	_draw_transition(region_width * 2.0, height, 1.0)

	# Recursos representativos de cada região.
	_draw_resources(Rect2(0.0, 0.0, region_width, height), Color(0.62, 0.82, 1.0), 18)
	_draw_resources(Rect2(region_width, 0.0, region_width, height), Color(0.55, 0.95, 0.62), 16)
	_draw_resources(Rect2(region_width * 2.0, 0.0, region_width, height), Color(1.0, 0.68, 0.35), 14)

	# Limite do protótipo.
	draw_rect(Rect2(0.0, 0.0, width, height), Color(0.85, 0.92, 1.0, 0.35), false, 4.0)

func _draw_transition(center_x: float, height: float, direction: float) -> void:
	var half := float(transition_width) * 0.5
	var points := PackedVector2Array()
	var segments := 18

	for i in range(segments + 1):
		var y := height * float(i) / float(segments)
		var wave := sin(float(i) * 0.85 + seed_value * 0.01) * 34.0
		points.append(Vector2(center_x - half + wave * direction, y))

	for i in range(segments, -1, -1):
		var y := height * float(i) / float(segments)
		var wave := sin(float(i) * 0.85 + seed_value * 0.01) * 34.0
		points.append(Vector2(center_x + half + wave * direction, y))

	draw_colored_polygon(points, Color(0.47, 0.5, 0.32, 0.55))

func _draw_resources(region: Rect2, color: Color, count: int) -> void:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = _rng.randi()

	for i in range(count):
		var position := Vector2(
			local_rng.randf_range(region.position.x + 40.0, region.end.x - 40.0),
			local_rng.randf_range(region.position.y + 40.0, region.end.y - 40.0)
		)
		draw_circle(position, local_rng.randf_range(3.0, 7.0), color)
