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

func attack(target: Node) -> bool:
	if not can_attack():
		return false
	if target == null or not target.has_method("take_damage"):
		return false

	var attacker: Node = get_parent()
	if attacker == null or not is_instance_valid(attacker):
		return false
	if not attacker.is_in_group("SimCells"):
		return false

	var attacker_species: String = String(attacker.get("species_id"))
	var target_species: String = String(target.get("species_id"))
	if not attacker_species.is_empty() and attacker_species == target_species:
		return false

	var damage_dealt: bool = bool(target.call("take_damage", damage, attacker))
	if damage_dealt:
		current_cooldown = cooldown
	return damage_dealt
