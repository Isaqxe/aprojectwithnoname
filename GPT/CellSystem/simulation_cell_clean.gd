extends CharacterBody2D

## Clean integrated cell organism.
## Keeps movement cheap by refreshing perception on a timer instead of every physics frame.

const CELL_SCRIPT := preload("res://GPT/CellSystem/cell.gd")
const BEHAVIOR_SCRIPT := preload("res://GPT/CellSystem/cell_behavior.gd")
const SOCIAL_SCRIPT := preload("res://GPT/CellSystem/cell_behavior_social.gd")
const FEAR_SCRIPT := preload("res://GPT/CellSystem/cell_fear.gd")
const COMBAT_SCRIPT := preload("res://GPT/CellSystem/cell_combat.gd")
const MITOSIS_SCRIPT := preload("res://GPT/CellSystem/cell_mitosis.gd")
const GENETICS_SCRIPT := preload("res://GPT/CellSystem/cell_genetics.gd")
const ADAPTATION_SCRIPT := preload("res://GPT/CellSystem/cell_adaptation.gd")

@export var is_player_controlled: bool = false
@export var species_id: String = ""
@export var elimination_resource_reward: float = 35.0
@export var perception_radius: float = 180.0
@export var resource_perception_radius: float = 220.0
@export var resource_collect_radius: float = 18.0
@export var combat_contact_margin: float = 2.0

@export_category("Behavior")
@export var perception_interval: float = 0.25
@export var group_perception_radius: float = 150.0
@export var defense_radius: float = 180.0

@export_category("Health Bar")
@export var health_bar_width: float = 42.0
@export var health_bar_height: float = 5.0
@export var health_bar_offset: float = 8.0

var inherited_data: Dictionary = {}
var species_color: Color = Color.WHITE
var cell_data: CharacterBody2D
var behavior: CellBehavior
var social_behavior: CellBehaviorSocial
var fear_system: Node
var combat: Node
var mitosis: Node
var genetics: Node
var adaptation: Node

var _target: CharacterBody2D
var _resource_target: Area2D
var _cached_allies: Array = []
var _cached_ally_positions: Array[Vector2] = []
var _cached_ally_velocities: Array[Vector2] = []
var _perception_timer: float = 0.0
var _wander_time: float = 0.0
var _wander_direction_timer: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _base_color: Color = Color.WHITE
var _flash_timer: float = 0.0
var _collision_shape: CollisionShape2D
var _cell_manager: Node

func _ready() -> void:
	cell_data = CELL_SCRIPT.new()
	_apply_initial_biology()
	add_child(cell_data)

	behavior = BEHAVIOR_SCRIPT.new()
	add_child(behavior)

	social_behavior = SOCIAL_SCRIPT.new()
	social_behavior.cohesion_radius = group_perception_radius
	add_child(social_behavior)

	fear_system = FEAR_SCRIPT.new()
	add_child(fear_system)

	mitosis = MITOSIS_SCRIPT.new()
	if inherited_data.has("mitosis_count"):
		mitosis.mitosis_count = int(inherited_data["mitosis_count"])
	add_child(mitosis)

	genetics = GENETICS_SCRIPT.new()
	add_child(genetics)
	if inherited_data.is_empty():
		genetics.species_id = cell_data.species_id
		genetics.initialize_random()
		_register_biology_genes()
	else:
		genetics.species_id = cell_data.species_id
		var inherited_genes: Dictionary = inherited_data.get("genes", {})
		genetics.initialize_from_parent(null, inherited_genes)
		genetics.parent_id = String(inherited_data.get("parent_id", ""))
		genetics.generation = int(inherited_data.get("generation", 0))
		if genetics.genes.is_empty():
			_register_biology_genes()
		else:
			genetics.mutate_genes()
			_apply_genes_to_biology()

	if genetics != null and is_instance_valid(genetics) and mitosis != null and is_instance_valid(mitosis):
		mitosis.set_genetic_base_cost(genetics.get_gene("mitosis_cost", mitosis.base_resource_cost))

	_apply_behavior_genes()

	adaptation = ADAPTATION_SCRIPT.new()
	adaptation.setup(self)
	add_child(adaptation)

func _register_biology_genes() -> void:
	genetics.set_gene("health", cell_data.max_health)
	genetics.set_gene("damage", cell_data.damage)
	genetics.set_gene("speed", cell_data.speed)
	genetics.set_gene("size", cell_data.size)
	genetics.set_gene("regeneration_rate", cell_data.regeneration_rate)

func _apply_initial_biology() -> void:
	if inherited_data.is_empty():
		cell_data.max_health = randf_range(40.0, 120.0)
		cell_data.damage = randf_range(5.0, 25.0)
		cell_data.speed = randf_range(45.0, 100.0)
		cell_data.size = randf_range(10.0, 24.0)
		cell_data.regeneration_rate = randf_range(2.0, 6.0)
		cell_data.species_id = species_id
	else:
		cell_data.max_health = float(inherited_data.get("max_health", 100.0))
		cell_data.damage = float(inherited_data.get("damage", 10.0))
		cell_data.speed = float(inherited_data.get("speed", 75.0))
		cell_data.size = float(inherited_data.get("size", 16.0))
		cell_data.regeneration_rate = float(inherited_data.get("regeneration_rate", 4.0))
		cell_data.species_id = String(inherited_data.get("species_id", species_id))

	cell_data.is_player_controlled = is_player_controlled
	cell_data.health = cell_data.max_health
	cell_data.resources = 0.0

func _apply_genes_to_biology() -> void:
	cell_data.max_health = maxf(genetics.get_gene("health", cell_data.max_health), 1.0)
	cell_data.damage = maxf(genetics.get_gene("damage", cell_data.damage), 0.1)
	cell_data.speed = maxf(genetics.get_gene("speed", cell_data.speed), 1.0)
	cell_data.size = clampf(genetics.get_gene("size", cell_data.size), 4.0, 80.0)
	cell_data.regeneration_rate = maxf(genetics.get_gene("regeneration_rate", cell_data.regeneration_rate), 0.0)
	cell_data.health = cell_data.max_health

func _apply_behavior_genes() -> void:
	if genetics == null or behavior == null:
		return
	behavior.aggression = genetics.get_gene("aggression", 0.5)

func _process_player(delta: float) -> void:
	behavior.set_state(CellBehavior.BehaviorState.WANDER)
	_wander_time += delta
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_direction = input_direction.normalized()
	if input_direction.length_squared() > 0.01:
		_wander_time = 0.0

func _process_ai(delta: float) -> void:
	if is_instance_valid(_target):
		var target_data: Node = _target.get("cell_data") as Node
		if target_data == null or not bool(target_data.get("alive")) or not behavior.is_valid_enemy(self, _target):
			_target = null

	if is_instance_valid(_target):
		var decision: CellBehavior.BehaviorState = behavior.evaluate_collective_cell(cell_data, _target.get("cell_data") as Node, _cached_allies)
		if decision == CellBehavior.BehaviorState.FLEE:
			_direction = _calculate_collective_flee_direction()
		else:
			_direction = social_behavior.calculate_social_steering(global_position, global_position.direction_to(_target.global_position), _cached_ally_positions, _cached_ally_velocities)
		_wander_time = 0.0
		return

	if is_instance_valid(_resource_target) and cell_data.can_accept_resources():
		behavior.evaluate_resource(cell_data)
		_direction = social_behavior.calculate_social_steering(global_position, global_position.direction_to(_resource_target.global_position), _cached_ally_positions, _cached_ally_velocities)
		_wander_time = 0.0
		return

	_resource_target = null
	behavior.set_state(CellBehavior.BehaviorState.WANDER)
	_wander(delta)
	_wander_time += delta

func _refresh_perception() -> void:
	_apply_behavior_genes()
	_target = _find_best_target()
	_resource_target = null if is_instance_valid(_target) else _find_nearest_resource()

	_cached_allies.clear()
	_cached_ally_positions.clear()
	_cached_ally_velocities.clear()
	var radius_squared: float = group_perception_radius * group_perception_radius
	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if candidate == self or not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		if String(candidate.get("species_id")) != String(species_id):
			continue
		var ally: CharacterBody2D = candidate as CharacterBody2D
		if global_position.distance_squared_to(ally.global_position) > radius_squared:
			continue
		_cached_allies.append(ally)
		_cached_ally_positions.append(ally.global_position)
		_cached_ally_velocities.append(ally.velocity)

func _find_best_target() -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_score: float = -INF
	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if candidate == self or not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		var enemy: CharacterBody2D = candidate as CharacterBody2D
		if not behavior.is_valid_enemy(self, enemy):
			continue
		if not enemy.has_method("get_cell_power"):
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > perception_radius:
			continue
		var proximity: float = 1.0 - clampf(distance / maxf(perception_radius, 0.001), 0.0, 1.0)
		var score: float = proximity * 100.0
		if score > best_score:
			best = enemy
			best_score = score
	return best

func _find_nearest_resource() -> Area2D:
	var nearest: Area2D = null
	var nearest_distance: float = resource_perception_radius
	for candidate in get_tree().get_nodes_in_group("WorldResources"):
		if not is_instance_valid(candidate) or not candidate is Area2D:
			continue
		var resource: Area2D = candidate as Area2D
		var distance: float = global_position.distance_to(resource.global_position)
		if distance < nearest_distance:
			nearest = resource
			nearest_distance = distance
	return nearest

func _calculate_collective_flee_direction() -> Vector2:
	var weighted_away := Vector2.ZERO
	var radius_squared: float = defense_radius * defense_radius
	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if not is_instance_valid(candidate) or not candidate is CharacterBody2D:
			continue
		var enemy: CharacterBody2D = candidate as CharacterBody2D
		if not behavior.is_valid_enemy(self, enemy):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance_squared: float = offset.length_squared()
		if distance_squared <= 0.001 or distance_squared > radius_squared:
			continue
		var distance: float = sqrt(distance_squared)
		var proximity: float = 1.0 - clampf(distance / defense_radius, 0.0, 1.0)
		weighted_away -= offset.normalized() * proximity
	if weighted_away.length_squared() > 0.0001:
		return weighted_away.normalized()
	return _direction.normalized()

func _wander(_delta: float) -> void:
	if _wander_direction_timer <= 0.0 or _direction.length_squared() < 0.01:
		_direction = Vector2.from_angle(randf_range(0.0, TAU))
		_wander_direction_timer = randf_range(0.8, 1.8)
	else:
		var random_direction: Vector2 = Vector2.from_angle(randf_range(0.0, TAU))
		_direction = _direction.lerp(random_direction, 0.025).normalized()
	if not _cached_ally_positions.is_empty():
		_direction = social_behavior.calculate_social_steering(global_position, _direction, _cached_ally_positions, _cached_ally_velocities)

func get_cell_power() -> float:
	if cell_data == null:
		return 0.0
	return fear_system.get_cell_power(cell_data)

func get_heredity_data() -> Dictionary:
	if cell_data == null or genetics == null:
		return {}
	return {
		"max_health": cell_data.max_health,
		"damage": cell_data.damage,
		"speed": cell_data.speed,
		"size": cell_data.size,
		"regeneration_rate": cell_data.regeneration_rate,
		"species_id": genetics.species_id,
		"genes": genetics.genes.duplicate(true),
		"parent_id": genetics.cell_id,
		"generation": genetics.generation + 1,
		"mitosis_count": mitosis.mitosis_count + 1
	}

func get_inspection_data() -> Dictionary:
	if cell_data == null or genetics == null or mitosis == null or behavior == null:
		return {}
	var lineage: Dictionary = genetics.get_lineage_data()
	return {
		"cell_id": lineage.get("cell_id", "unknown"),
		"species_id": lineage.get("species_id", "unknown"),
		"generation": lineage.get("generation", 0),
		"parent_id": lineage.get("parent_id", "none"),
		"player": is_player_controlled,
		"state": CellBehavior.BehaviorState.keys()[behavior.state],
		"health": cell_data.health,
		"max_health": cell_data.max_health,
		"damage": cell_data.damage,
		"speed": cell_data.speed,
		"size": cell_data.size,
		"regeneration_rate": cell_data.regeneration_rate,
		"resources": cell_data.resources,
		"resource_capacity": cell_data.resource_capacity,
		"hunger_state": cell_data.get_hunger_state() if cell_data.has_method("get_hunger_state") else "UNKNOWN",
		"energy_ratio": cell_data.get_energy_ratio() if cell_data.has_method("get_energy_ratio") else 0.0,
		"mitosis_count": mitosis.mitosis_count,
		"next_mitosis_cost": mitosis.get_resource_cost(),
		"genes": genetics.get_all_gene_data(),
		"environment": adaptation.get_environment_data() if adaptation != null and is_instance_valid(adaptation) and adaptation.has_method("get_environment_data") else {},
		"environment_stress": adaptation.get_stress_level() if adaptation != null and is_instance_valid(adaptation) and adaptation.has_method("get_stress_level") else 0.0
	}

func _finish_mitosis() -> void:
	var child: Node = _cell_manager.spawn_mitosis_child(self) if _cell_manager != null and is_instance_valid(_cell_manager) and _cell_manager.has_method("spawn_mitosis_child") else null
	if child != null:
		mitosis.complete_generation()
	else:
		mitosis.reset()

func _process_collisions() -> void:
	var slide_velocity: Vector2 = velocity
	if slide_velocity.length_squared() <= 0.01:
		return
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider: Object = collision.get_collider()
		if collider == null or not collider is Node:
			continue
		var other: Node = collider as Node
		if other.has_method("take_damage") and other != self:
			combat.try_attack(other)

func _process_resources() -> void:
	if not is_instance_valid(_resource_target):
		return
	if global_position.distance_to(_resource_target.global_position) > resource_collect_radius:
		return
	if not _resource_target.has_method("consume"):
		_resource_target = null
		return
	var amount: float = float(_resource_target.get("amount"))
	if cell_data.can_accept_resources():
		_resource_target.consume(self)
		cell_data.add_resources(amount)
		_resource_target = null

func _process_mitosis() -> void:
	if not is_instance_valid(mitosis):
		return
	if cell_data.is_in_mitosis_grace():
		return
	if mitosis.active:
		return
	if cell_data.resources < mitosis.get_resource_cost():
		return
	if behavior.state != CellBehavior.BehaviorState.MITOSIS:
		return
	cell_data.consume_resources(mitosis.get_resource_cost())
	mitosis.start()

func _process_environment(_delta: float) -> void:
	if adaptation != null and is_instance_valid(adaptation) and adaptation.has_method("update_environment"):
		adaptation.update_environment()
