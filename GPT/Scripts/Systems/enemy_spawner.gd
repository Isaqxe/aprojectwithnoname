extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 20

var _player: Node2D
var _timer: Timer


func _ready() -> void:
	_find_player.call_deferred()

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.timeout.connect(spawn_enemy)
	add_child(_timer)
	_timer.start()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D ## Aqui é onde o player é encontrado pelo código. Nota-se que essa linha busca o primeiro objeto no grupo PlayerCharacter, como um Node2D

	if _player == null: ## Se player não existe [...]
		print("PlayerCharacter não encontrado.")
	else:
		print("Player encontrado: ", _player.name) ## Player Encontrado!


func spawn_enemy() -> void: ## Spawna o inimigo
	if _player == null or not is_instance_valid(_player): ##Se o player não for válido, executa _find_player
		_find_player()

	if _player == null: ## Se realmente não tiver player, só dá return e começa tudo de novo
		return

	if enemy_scene == null:
		print("Cena do inimigo não encontrada.")
		return

	if get_tree().get_nodes_in_group("Enemy1Character").size() >= max_enemies:
		print("Número máximo de inimigos atingido.")
		return

	var enemy = enemy_scene.instantiate()

	var angle := randf() * TAU
	var distance := randf_range(spawn_radius * 0.8, spawn_radius)
	var offset := Vector2.RIGHT.rotated(angle) * distance

	enemy.global_position = _player.global_position + offset
	get_tree().current_scene.add_child(enemy)

	print("Spawn! ", enemy.global_position)
