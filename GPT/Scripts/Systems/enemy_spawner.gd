extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 20
@export var min_timer: float = 0.0

var _timer := 0.0
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
	print("Funcionando")
	print(enemy_scene)
	print(get_tree().get_nodes_in_group("PlayerCharacter"))

func _process(delta: float):
	if _player == null:
		_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
		return

	_timer += delta
	if _timer >= spawn_interval:
		spawn_enemy()
		print("timer bateu")
		reset_timer(min_timer)

func reset_timer(to):
	_timer = to

func spawn_enemy() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D
	if enemy_scene == null:
		print("cena do inimigo não encontrada")
		return

	if get_tree().get_nodes_in_group("Enemy1Character").size() >= max_enemies:
		print("número máximo de inimigos atingido")
		return

	var enemy = enemy_scene.instantiate()
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius * 0.8, spawn_radius)
	var offset = Vector2.RIGHT.rotated(angle) * distance
	enemy.global_position = _player.global_position + offset
	get_tree().current_scene.add_child(enemy)
	print("Spawn!")
	print(enemy.global_position)
