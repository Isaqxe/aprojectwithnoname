extends CharacterBody2D

## Base organism prototype for Alive Cells.
## This script represents a generic cell, independent of player/enemy roles.

@export_category("Identity")
@export var cell_id: String = "cell"
@export var is_player_controlled: bool = false

@export_category("Biology")
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var speed: float = 100.0
@export var size: float = 24.0

var health: float


func _ready() -> void:
	health = max_health


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	health -= amount

	if health <= 0.0:
		die()


func attack(target: Node) -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(damage)


func die() -> void:
	queue_free()
