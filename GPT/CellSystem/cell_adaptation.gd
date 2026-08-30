extends Node

## Environmental adaptation layer for a single cell.
## The science-fair laboratory provides continuous temperature, humidity and
## food-density variation instead of discrete procedural biomes.

@export var damage_per_second: float = 4.0
@export var tolerance_margin: float = 0.20
@export var world_provider: Node

var cell: Node = null
var last_environment: Dictionary = {}
var last_stress: float = 0.0

func setup(target_cell: Node) -> void:
	cell = target_cell
	if world_provider == null:
		world_provider = _find_world_provider()

func evaluate(environment: Dictionary, genetics: Node) -> float:
	last_environment = environment
	if genetics == null:
		last_stress = 0.0
		return 0.0

	if not bool(environment.get("inside_domain", false)):
		last_stress = 1.0
		return last_stress

	var temperature: float = clampf(float(environment.get("temperature", 0.5)), 0.0, 1.0)
	var humidity: float = clampf(float(environment.get("humidity", 0.5)), 0.0, 1.0)

	var cold_adaptation: float = clampf(genetics.get_gene("cold_adaptation", 0.5), 0.0, 1.0)
	var temperate_adaptation: float = clampf(genetics.get_gene("temperate_adaptation", 0.5), 0.0, 1.0)
	var heat_adaptation: float = clampf(genetics.get_gene("heat_adaptation", 0.5), 0.0, 1.0)
	var humidity_adaptation: float = clampf(genetics.get_gene("humidity_adaptation", 0.5), 0.0, 1.0)

	var cold_weight: float = smoothstep(0.55, 0.0, temperature)
	var heat_weight: float = smoothstep(0.45, 1.0, temperature)
	var temperate_weight: float = 1.0 - clampf(cold_weight + heat_weight, 0.0, 1.0)

	var temperature_fitness: float = (
		cold_adaptation * cold_weight +
		temperate_adaptation * temperate_weight +
		heat_adaptation * heat_weight
	)
	var humidity_extremeness: float = absf(humidity - 0.5) * 2.0
	var humidity_fitness: float = humidity_adaptation * (1.0 - humidity_extremeness) + 0.5 * humidity_extremeness
	var overall_fitness: float = clampf(temperature_fitness * 0.75 + humidity_fitness * 0.25, 0.0, 1.0)

	last_stress = clampf(1.0 - overall_fitness, 0.0, 1.0)
	return last_stress

func apply_stress(delta: float, genetics: Node) -> void:
	if cell == null or not is_instance_valid(cell) or delta <= 0.0 or genetics == null:
		return

	var environment: Dictionary = get_environment()
	var stress: float = evaluate(environment, genetics)
	if stress <= tolerance_margin:
		return

	var excess_stress: float = (stress - tolerance_margin) / maxf(1.0 - tolerance_margin, 0.001)
	if cell.has_method("take_environmental_damage"):
		cell.take_environmental_damage(damage_per_second * excess_stress * delta)

func get_environment() -> Dictionary:
	if world_provider == null or not is_instance_valid(world_provider):
		world_provider = _find_world_provider()

	if world_provider != null and is_instance_valid(world_provider) and world_provider.has_method("get_environment_at"):
		if cell != null and cell is Node2D:
			return world_provider.get_environment_at((cell as Node2D).global_position)

	return {"biome": "laboratory", "temperature": 0.5, "humidity": 0.5, "food_density": 1.0, "inside_domain": true}

func get_stress() -> float:
	return last_stress

func get_adaptation_for_biome(biome: String, genetics: Node) -> float:
	return _get_adaptation_for_biome(biome, genetics)

func _get_adaptation_for_biome(biome: String, genetics: Node) -> float:
	match biome:
		"cold":
			return clampf(genetics.get_gene("cold_adaptation", 0.5), 0.0, 1.0)
		"green":
			return clampf(genetics.get_gene("temperate_adaptation", 0.5), 0.0, 1.0)
		"hot":
			return clampf(genetics.get_gene("heat_adaptation", 0.5), 0.0, 1.0)
		"void":
			return clampf(genetics.get_gene("void_adaptation", 0.5), 0.0, 1.0)
		"laboratory":
			return 1.0
		_:
			return 0.5

func _find_world_provider() -> Node:
	if cell == null or not is_instance_valid(cell):
		return null
	var scene_root: Node = cell.get_tree().current_scene
	if scene_root == null:
		return null
	return _find_provider_recursive(scene_root)

func _find_provider_recursive(start_node: Node) -> Node:
	if start_node == null:
		return null
	if start_node.has_method("get_environment_at"):
		return start_node
	for child in start_node.get_children():
		var provider: Node = _find_provider_recursive(child)
		if provider != null:
			return provider
	return null
