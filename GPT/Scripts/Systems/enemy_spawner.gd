extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 20

var _timer := 0.0
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
		return

	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	if get_tree().get_nodes_in_group("Enemy1Character").size() >= max_enemies:
		return

	var enemy = enemy_scene.instantiate()
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius * 0.8, spawn_radius)
	var offset = Vector2.RIGHT.rotated(angle) * distance
	enemy.global_position = _player.global_position + offset
	get_tree().current_scene.add_child(enemy)
