extends Node2D
class_name ExperimentalDomain

## Closed experimental domain for the science-fair simulation.
## The circular area represents a laboratory slide; outside it is the void.

@export_category("Domain")
@export var radius: float = 30000.0
@export var domain_center: Vector2 = Vector2.ZERO
@export var use_node_position_as_center: bool = true

@export_category("Laboratory Environment")
@export_range(0.0, 1.0) var base_temperature: float = 0.50
@export_range(0.0, 1.0) var base_humidity: float = 0.50
@export_range(0.0, 1.0) var base_food_density: float = 1.00
@export_range(0.0, 1.0) var temperature_variation: float = 0.35
@export_range(0.0, 1.0) var humidity_variation: float = 0.30
@export_range(0.0, 1.0) var food_edge_penalty: float = 0.45

func _ready() -> void:
	add_to_group("ExperimentalDomains")
	queue_redraw()

func get_center() -> Vector2:
	return global_position if use_node_position_as_center else domain_center

func get_radius() -> float:
	return maxf(radius, 0.0)

func contains_position(world_position: Vector2) -> bool:
	return get_center().distance_squared_to(world_position) <= get_radius() * get_radius()

func clamp_position(world_position: Vector2, margin: float = 0.0) -> Vector2:
	var center: Vector2 = get_center()
	var maximum_radius: float = maxf(get_radius() - maxf(margin, 0.0), 0.0)
	var offset: Vector2 = world_position - center
	if offset.length_squared() <= maximum_radius * maximum_radius:
		return world_position
	if offset.length_squared() <= 0.000001:
		return center
	return center + offset.normalized() * maximum_radius

func random_position(margin: float = 0.0) -> Vector2:
	var center: Vector2 = get_center()
	var maximum_radius: float = maxf(get_radius() - maxf(margin, 0.0), 0.0)
	var angle: float = randf_range(0.0, TAU)
	var distance: float = sqrt(randf()) * maximum_radius
	return center + Vector2.from_angle(angle) * distance

## Continuous laboratory environment. No procedural biome map is required.
## Temperature changes vertically, humidity horizontally, and food density
## is slightly reduced toward the edge of the experimental slide.
func get_environment_at(world_position: Vector2) -> Dictionary:
	if not contains_position(world_position):
		return {
			"biome": "void",
			"temperature": 0.0,
			"humidity": 0.0,
			"food_density": 0.0,
			"inside_domain": false
		}

	var center: Vector2 = get_center()
	var safe_radius: float = maxf(get_radius(), 1.0)
	var relative: Vector2 = (world_position - center) / safe_radius
	var normalized_y: float = clampf(relative.y, -1.0, 1.0)
	var normalized_x: float = clampf(relative.x, -1.0, 1.0)
	var radial_distance: float = clampf(relative.length(), 0.0, 1.0)

	var vertical_factor: float = normalized_y * 0.5 + 0.5
	var horizontal_factor: float = normalized_x * 0.5 + 0.5
	var edge_factor: float = smoothstep(0.0, 1.0, radial_distance)

	var temperature: float = clampf(base_temperature + (vertical_factor - 0.5) * 2.0 * temperature_variation, 0.0, 1.0)
	var humidity: float = clampf(base_humidity + (horizontal_factor - 0.5) * 2.0 * humidity_variation, 0.0, 1.0)
	var food_density: float = clampf(base_food_density * (1.0 - edge_factor * food_edge_penalty), 0.0, 1.0)

	return {
		"biome": "laboratory",
		"temperature": temperature,
		"humidity": humidity,
		"food_density": food_density,
		"inside_domain": true
	}

func get_biome_at(world_position: Vector2) -> String:
	return String(get_environment_at(world_position).get("biome", "void"))

func is_inside(world_position: Vector2) -> bool:
	return contains_position(world_position)

func _draw() -> void:
	if radius <= 0.0:
		return
	draw_arc(to_local(get_center()), radius, 0.0, TAU, 256, Color(0.4, 0.4, 0.4, 0.15), 2.0)
