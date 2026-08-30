extends CharacterBody2D

## Base organism prototype for Alive Cells.
## This script represents a generic cell, independent of player/enemy roles.

@export_category("Identity")
@export var cell_id: String = "cell"
@export var species_id: String = ""
@export var is_player_controlled: bool = false

@export_category("Biology")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var speed: float = 100.0
@export var size: float = 24.0
@export var regeneration_rate: float = 4.0

@export_category("Energy / Hunger")
@export var use_resource_capacity: bool = true
@export var resource_capacity: float = 100.0
@export var starting_energy_ratio: float = 0.60
@export var base_energy_drain: float = 0.35
@export var movement_energy_drain: float = 0.18
@export var size_energy_drain: float = 0.008
@export var hungry_threshold: float = 0.45
@export var starving_threshold: float = 0.20
@export var critical_energy_threshold: float = 0.05
@export var starvation_damage_per_second: float = 3.0

var resources: float = 0.0
var health: float
var alive: bool = true

func _ready() -> void:
	health = max_health
	resources = clampf(resource_capacity * starting_energy_ratio, 0.0, resource_capacity)

func take_damage(amount: float, attacker: Node = null) -> bool:
	if not alive or amount <= 0.0:
		return false

	if attacker != null and is_instance_valid(attacker):
		var attacker_species: String = String(attacker.get("species_id"))
		if not species_id.is_empty() and species_id == attacker_species:
			return false

	health -= amount

	if health <= 0.0:
		die()

	return true

func regenerate(delta: float) -> void:
	if not alive or delta <= 0.0 or regeneration_rate <= 0.0:
		return

	var energy_ratio: float = get_energy_ratio()
	var regeneration_multiplier: float = 1.0
	if energy_ratio <= critical_energy_threshold:
		regeneration_multiplier = 0.0
	elif energy_ratio <= starving_threshold:
		regeneration_multiplier = 0.25
	elif energy_ratio <= hungry_threshold:
		regeneration_multiplier = 0.65

	health = minf(health + regeneration_rate * regeneration_multiplier * delta, max_health)

func process_metabolism(delta: float, activity: float = 0.0) -> void:
	if not alive or delta <= 0.0:
		return

	var safe_activity: float = clampf(activity, 0.0, 1.0)
	var speed_factor: float = maxf(speed / 75.0, 0.25)
	var size_cost: float = maxf(size, 1.0) * size_energy_drain
	var movement_cost: float = movement_energy_drain * speed_factor * safe_activity
	var drain: float = base_energy_drain + size_cost + movement_cost
	resources = maxf(resources - drain * delta, 0.0)

	if resources <= critical_energy_threshold * resource_capacity:
		take_environmental_damage(starvation_damage_per_second * delta)

func get_energy_ratio() -> float:
	if resource_capacity <= 0.0:
		return 0.0
	return clampf(resources / resource_capacity, 0.0, 1.0)

func get_hunger_state() -> String:
	var ratio: float = get_energy_ratio()
	if ratio <= critical_energy_threshold:
		return "CRITICAL"
	if ratio <= starving_threshold:
		return "STARVING"
	if ratio <= hungry_threshold:
		return "HUNGRY"
	return "SATIATED"

func needs_food() -> bool:
	return get_energy_ratio() <= hungry_threshold

func can_accept_resources() -> bool:
	if not alive:
		return false
	return resources < resource_capacity

func add_resources(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	resources = minf(resources + amount, resource_capacity)

func consume_resources(amount: float) -> bool:
	if not alive or amount <= 0.0 or resources < amount:
		return false
	resources -= amount
	return true

func take_environmental_damage(amount: float) -> bool:
	if not alive or amount <= 0.0:
		return false
	health -= amount
	if health <= 0.0:
		die()
	return true

func attack(target: Node) -> void:
	if not alive:
		return

	if target != null and target.has_method("take_damage"):
		target.take_damage(damage, self)

func die() -> void:
	alive = false
	queue_free()
