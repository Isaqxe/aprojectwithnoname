extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_spawn_interval: float = 2.0

var _timer := 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		spawn_enemy()
		spawn_interval = max_spawn_interval

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = global_position + offset
	get_tree().current_scene.add_child(enemy)
