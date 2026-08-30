extends Node

## Combat layer prototype for Alive Cells.
## Combat resolves species identity through the organism API rather than duplicating identity rules.

var damage: float = 10.0
var cooldown: float = 0.5
var current_cooldown: float = 0.0

func update(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown -= delta

func can_attack() -> bool:
	return current_cooldown <= 0.0

func _get_species_id(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	if node.has_method("get_species_id"):
		return String(node.get_species_id()).strip_edges()
	return String(node.get("species_id")).strip_edges()

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

	var attacker_species: String = _get_species_id(attacker)
	var target_species: String = _get_species_id(target)
	if not attacker_species.is_empty() and attacker_species == target_species:
		return false

	var damage_dealt: bool = bool(target.call("take_damage", damage, attacker))
	if damage_dealt:
		current_cooldown = cooldown
	return damage_dealt
