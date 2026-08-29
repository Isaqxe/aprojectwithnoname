extends CharacterBody2D

## Base organism prototype for Alive Cells.
## This script represents a generic cell, independent of player/enemy roles.

@export_category("Identity")
@export var cell_id: String = "cell"
@export var species_id: String = "default"
@export var is_player_controlled: bool = false

@export_category("Biology")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var speed: float = 100.0
@export var size: float = 24.0
@export var regeneration_rate: float = 4.0

@export_category("Resources")
@export var use_resource_capacity: bool = false
@export var resource_capacity: float = 100.0
var resources: float = 0.0

var health: float
var alive: bool = true

func _ready() -> void:
	health = max_health

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
	health = minf(health + regeneration_rate * delta, max_health)

func attack(target: Node) -> void:
	if not alive:
		return

	if target != null and target.has_method("take_damage"):
		target.take_damage(damage, self)

func can_accept_resources() -> bool:
	if not alive:
		return false
	if not use_resource_capacity:
		return true
	return resources < resource_capacity

func add_resources(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	if use_resource_capacity:
		resources = minf(resources + amount, resource_capacity)
	else:
		resources += amount

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

func die() -> void:
	alive = false
	queue_free()
