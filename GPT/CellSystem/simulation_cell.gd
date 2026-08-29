extends CharacterBody2D

## Integrated organism used by the CellSystem simulation.
## Combines generic cell data, behavior, fear, combat, mitosis, genetics and adaptation.

const CELL_SCRIPT := preload("res://GPT/CellSystem/cell.gd")
const BEHAVIOR_SCRIPT := preload("res://GPT/CellSystem/cell_behavior.gd")
const FEAR_SCRIPT := preload("res://GPT/CellSystem/cell_fear.gd")
const COMBAT_SCRIPT := preload("res://GPT/CellSystem/cell_combat.gd")
const MITOSIS_SCRIPT := preload("res://GPT/CellSystem/cell_mitosis.gd")
const GENETICS_SCRIPT := preload("res://GPT/CellSystem/cell_genetics.gd")
const ADAPTATION_SCRIPT := preload("res://GPT/CellSystem/cell_adaptation.gd")

@export var is_player_controlled: bool = false
@export var species_id: String = "default"
@export var elimination_resource_reward: float = 35.0
@export var wander_speed_factor: float = 0.35
@export var perception_radius: float = 180.0
@export var resource_perception_radius: float = 220.0
@export var resource_collect_radius: float = 18.0
@export var combat_contact_margin: float = 2.0

var inherited_data: Dictionary = {}
var species_color: Color = Color.WHITE
var cell_data: CharacterBody2D
var behavior: CellBehavior
var fear_system: Node
var combat: Node
var mitosis: Node
var genetics: Node
var adaptation: Node
var _target: CharacterBody2D
var _resource_target: Area2D
var _direction := Vector2.ZERO
var _retarget_timer := 0.0
var _wander_time: float = 0.0
var _base_color := Color.WHITE
var _flash_timer := 0.0
var _collision_shape: CollisionShape2D
var _cell_manager: Node

func _ready() -> void:
	cell_data = CELL_SCRIPT.new()
	_apply_initial_biology()
	add_child(cell_data)

	behavior = BEHAVIOR_SCRIPT.new()
	add_child(behavior)

	fear_system = FEAR_SCRIPT.new()
	add_child(fear_system)

	mitosis = MITOSIS_SCRIPT.new()
	if inherited_data.has("mitosis_count"):
		mitosis.mitosis_count = int(inherited_data["mitosis_count"])
	add_child(mitosis)

	genetics = GENETICS_SCRIPT.new()
	if inherited_data.is_empty():
		genetics.species_id = cell_data.species_id
		genetics.initialize_random()
		genetics.set_gene("health", cell_data.max_health)
		genetics.set_gene("damage", cell_data.damage)
		genetics.set_gene("speed", cell_data.speed)
		genetics.set_gene("size", cell_data.size)
		genetics.set_gene("regeneration_rate", cell_data.regeneration_rate)
	else:
		genetics.species_id = cell_data.species_id
		var inherited_genes: Dictionary = inherited_data.get("genes", {})
		genetics.initialize_from_parent(null, inherited_genes)
		genetics.parent_id = String(inherited_data.get("parent_id", ""))
		genetics.generation = int(inherited_data.get("generation", 0))
		if genetics.genes.is_empty():
			genetics.set_gene("health", cell_data.max_health)
			genetics.set_gene("damage", cell_data.damage)
			genetics.set_gene("speed", cell_data.speed)
			genetics.set_gene("size", cell_data.size)
			genetics.set_gene("regeneration_rate", cell_data.regeneration_rate)
		else:
			genetics.mutate_genes()
			_apply_genes_to_biology()

	add_child(genetics)

	adaptation = ADAPTATION_SCRIPT.new()
	adaptation.setup(self)
	add_child(adaptation)

	combat = COMBAT_SCRIPT.new()
	combat.damage = cell_data.damage
	combat.cooldown = randf_range(0.35, 0.65)
	add_child(combat)

	_collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_update_collision_shape()

	_cell_manager = get_tree().get_first_node_in_group("CellManagers")

	add_to_group("SimCells")
	if is_player_controlled:
		add_to_group("PlayerCharacter")

	if _cell_manager != null and _cell_manager.has_method("get_species_color"):
		set_species_color(_cell_manager.get_species_color(String(species_id)))
	else:
		_base_color = Color.from_hsv(randf(), 0.55, 0.95)
	queue_redraw()

func set_species_color(color: Color) -> void:
	species_color = color
	_base_color = color
	queue_redraw()

func _physics_process(delta: float) -> void:
	if cell_data == null or not cell_data.alive:
		return

	combat.update(delta)
	_flash_timer = maxf(_flash_timer - delta, 0.0)

	if mitosis.active:
		velocity = Vector2.ZERO
		if mitosis.update(delta):
			_finish_mitosis()
		queue_redraw()
		return

	_retarget_timer -= delta
	if is_player_controlled:
		_process_player(delta)
	else:
		_process_ai(delta)

	velocity = _direction * cell_data.speed
	move_and_slide()
	_process_collisions()
	_process_resources()
	_process_mitosis()
	_process_environment(delta)

	if behavior.state == CellBehavior.BehaviorState.WANDER:
		cell_data.regenerate(delta)

	queue_redraw()

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

func _process_player(delta: float) -> void:
	behavior.set_state(CellBehavior.BehaviorState.WANDER)
	_wander_time += delta
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_direction = input_direction.normalized()
	if input_direction.length_squared() > 0.01:
		_wander_time = 0.0

func _process_ai(delta: float) -> void:
	if _retarget_timer <= 0.0 or (not is_instance_valid(_target) and not is_instance_valid(_resource_target)):
		_target = _find_best_target()
		_resource_target = _find_nearest_resource() if not is_instance_valid(_target) else null
		_retarget_timer = 0.15

	if is_instance_valid(_target):
		_wander_time = 0.0
		var target_data = _target.get("cell_data")
		if target_data == null or not target_data.alive:
			_target = null
			behavior.set_state(CellBehavior.BehaviorState.WANDER)
			return

		var decision: String = String(fear_system.evaluate(cell_data, target_data))
		behavior.evaluate_cell(cell_data, target_data)

		if decision == "FLEE":
			_direction = _target.global_position.direction_to(global_position)
		else:
			_direction = global_position.direction_to(_target.global_position)
		return

	if is_instance_valid(_resource_target) and cell_data.can_accept_resources():
		behavior.evaluate_resource(cell_data)
		_direction = global_position.direction_to(_resource_target.global_position)
		_wander_time = 0.0
	else:
		_resource_target = null
		behavior.set_state(CellBehavior.BehaviorState.WANDER)
		_wander()
		_wander_time += delta

func _find_best_target() -> CharacterBody2D:
	var best: CharacterBody2D = null
	var best_distance: float = perception_radius

	for candidate in get_tree().get_nodes_in_group("SimCells"):
		if candidate == self or not is_instance_valid(candidate):
			continue
		if not candidate.has_method("get_cell_power"):
			continue
		if String(candidate.get("species_id")) == cell_data.species_id:
			continue

		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance

	return best

func _find_nearest_resource() -> Area2D:
	var nearest: Area2D = null
	var nearest_distance: float = resource_perception_radius

	for candidate in get_tree().get_nodes_in_group("WorldResources"):
		if not is_instance_valid(candidate) or not candidate is Area2D:
			continue

		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance

	return nearest

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
		"mitosis_count": mitosis.mitosis_count,
		"next_mitosis_cost": mitosis.get_resource_cost(),
		"genes": lineage.get("genes", {}),
		"environment": adaptation.last_environment if adaptation != null else {},
		"environment_stress": adaptation.get_stress() if adaptation != null else 0.0
	}

func _process_collisions() -> void:
	for index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		var collider: Object = collision.get_collider()
		if collider == null or collider == self:
			continue
		if not collider is CharacterBody2D:
			continue
		if not collider.is_in_group("SimCells"):
			continue
		if not collider.has_method("take_damage"):
			continue
		if String(collider.get("species_id")) == cell_data.species_id:
			continue

		var target_data = collider.get("cell_data")
		var was_alive: bool = target_data != null and target_data.alive
		var attack_succeeded: bool = combat.attack(collider)

		if attack_succeeded and was_alive and target_data != null and not target_data.alive:
			cell_data.add_resources(elimination_resource_reward)
			if _target == collider:
				_target = null

func _process_resources() -> void:
	if not cell_data.can_accept_resources():
		_resource_target = null
		return

	if is_player_controlled:
		_collect_nearby_resource()
		return

	if not is_instance_valid(_resource_target):
		return

	if global_position.distance_to(_resource_target.global_position) <= cell_data.size + resource_collect_radius:
		_collect_resource(_resource_target)

func _collect_nearby_resource() -> void:
	for candidate in get_tree().get_nodes_in_group("WorldResources"):
		if not is_instance_valid(candidate) or not candidate is Area2D:
			continue
		if global_position.distance_to(candidate.global_position) <= cell_data.size + resource_collect_radius:
			_collect_resource(candidate)
			return

func _collect_resource(resource_node: Area2D) -> void:
	if not resource_node.has_method("collect"):
		return

	var collected: float = resource_node.collect()
	if collected > 0.0:
		cell_data.add_resources(collected)
	_resource_target = null

func _process_environment(delta: float) -> void:
	if adaptation == null or not is_instance_valid(adaptation):
		return
	adaptation.apply_stress(delta, genetics)

func _process_mitosis() -> void:
	if mitosis.active:
		return
	if behavior.state != CellBehavior.BehaviorState.WANDER:
		return
	if _wander_time < mitosis.required_wander_time:
		return
	if cell_data.resources < mitosis.get_resource_cost():
		return
	if _cell_manager == null or not is_instance_valid(_cell_manager):
		_cell_manager = get_tree().get_first_node_in_group("CellManagers")
	if _cell_manager == null or not _cell_manager.has_method("spawn_mitosis_child"):
		return
	if _cell_manager.get_population() >= _cell_manager.max_population:
		return

	_start_mitosis()

func _start_mitosis() -> void:
	if mitosis.active:
		return
	var cost: float = mitosis.get_resource_cost()
	if not cell_data.consume_resources(cost):
		return

	_wander_time = 0.0
	_direction = Vector2.ZERO
	behavior.set_state(CellBehavior.BehaviorState.MITOSIS)
	mitosis.start()

func _finish_mitosis() -> void:
	var child: Node = null
	if _cell_manager != null and is_instance_valid(_cell_manager):
		child = _cell_manager.spawn_mitosis_child(self)

	if child != null:
		mitosis.complete_generation()
	else:
		cell_data.add_resources(mitosis.get_resource_cost())

	behavior.set_state(CellBehavior.BehaviorState.WANDER)
	_wander_time = 0.0
	mitosis.reset()

func take_damage(amount: float, attacker: Node = null) -> bool:
	if cell_data == null:
		return false

	if attacker != null and is_instance_valid(attacker):
		var attacker_species: String = String(attacker.get("species_id"))
		if not species_id.is_empty() and species_id == attacker_species:
			return false

	var was_alive: bool = cell_data.alive
	var damage_applied: bool = cell_data.take_damage(amount, attacker)
	if not damage_applied:
		return false
	if cell_data.alive:
		_flash_timer = 0.08
		return true

	queue_free()
	return true

func _update_collision_shape() -> void:
	if _collision_shape == null or _collision_shape.shape == null or cell_data == null:
		return
	var circle_shape: CircleShape2D = _collision_shape.shape as CircleShape2D
	if circle_shape == null:
		return
	circle_shape.radius = cell_data.size + combat_contact_margin

func _wander() -> void:
	if _retarget_timer <= -0.5 or _direction.length_squared() < 0.01:
		_direction = Vector2.from_angle(randf_range(0.0, TAU))
		_retarget_timer = 0.5
	else:
		_direction = _direction.lerp(Vector2.from_angle(randf_range(0.0, TAU)), 0.03).normalized()

func _draw() -> void:
	var visible_color: Color = _base_color
	if _flash_timer > 0.0:
		visible_color = Color(0.9, 0.95, 1.0, 1.0)
	draw_circle(Vector2.ZERO, cell_data.size if cell_data != null else 16.0, visible_color)
