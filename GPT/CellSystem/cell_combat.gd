extends Node

## Combat layer prototype for Alive Cells.
## Keeps combat logic separated from the organism itself.

var damage: float = 10.0
var cooldown: float = 0.5
var current_cooldown: float = 0.0


func update(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta


func can_attack() -> bool:
	return current_cooldown <= 0.0


func attack(target: Node) -> void:
	if not can_attack():
		return

	if target != null and target.has_method("take_damage"):
		target.take_damage(damage)
		current_cooldown = cooldown
