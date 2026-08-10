extends Node2D

## PROTÓTIPO — gerador procedural de células inimigas.
## Esta versão substitui a dependência de enemy1.tscn por inimigos
## construídos diretamente pelo spawner.

@export var enemy_script: Script
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 500.0
@export var max_enemies: int = 20

@export_category("Common Cell")
@export var common_chance: float = 0.8
@export var common_min_size: float = 12.0
@export var common_max_size: float = 22.0
@export var common_min_strength: float = 1.0
@export var common_max_strength: float = 2.0

@export_category("White Blood Cell")
@export var white_blood_min_size: float = 28.0
@export var white_blood_max_size: float = 40.0
@export var white_blood_min_strength: float = 4.0
@export var white_blood_max_strength: float = 7.0

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
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D

	if _player == null:
		print("PlayerCharacter não encontrado.")


func spawn_enemy() -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()

	if _player == null:
		return

	if enemy_script == null:
		print("Script do inimigo não configurado.")
		return

	if get_tree().get_nodes_in_group("EnemyCharacter").size() >= max_enemies:
		return

	var enemy := CharacterBody2D.new()
	enemy.set_script(enemy_script)
	enemy.add_to_group("EnemyCharacter")

	var is_white_blood_cell := randf() > common_chance
	var size: float
	var strength: float

	if is_white_blood_cell:
		size = randf_range(white_blood_min_size, white_blood_max_size)
		strength = randf_range(white_blood_min_strength, white_blood_max_strength)
		enemy.set_meta("cell_type", "white_blood_cell")
	else:
		size = randf_range(common_min_size, common_max_size)
		strength = randf_range(common_min_strength, common_max_strength)
		enemy.set_meta("cell_type", "common_cell")

	enemy.set_meta("strength", strength)
	enemy.set_meta("visual_seed", randi())

	_setup_collision(enemy, size)
	_setup_visual(enemy, size, is_white_blood_cell)

	var angle := randf() * TAU
	var distance := randf_range(spawn_radius * 0.8, spawn_radius)
	var offset := Vector2.RIGHT.rotated(angle) * distance
	enemy.global_position = _player.global_position + offset

	get_tree().current_scene.add_child(enemy)


func _setup_collision(enemy: CharacterBody2D, size: float) -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = size
	collision.shape = shape
	enemy.add_child(collision)


func _setup_visual(enemy: CharacterBody2D, size: float, is_white_blood_cell: bool) -> void:
	var visual := ProceduralCellVisual.new()
	visual.radius = size
	visual.cell_type = "white_blood_cell" if is_white_blood_cell else "common_cell"
	visual.visual_seed = randi()
	enemy.add_child(visual)


class ProceduralCellVisual extends Node2D:
	var radius: float = 20.0
	var cell_type: String = "common_cell"
	var visual_seed: int = 0

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		seed(visual_seed)

		var points := PackedVector2Array()
		var point_count := randi_range(8, 12)

		for i in point_count:
			var angle := TAU * float(i) / float(point_count)
			var variation := randf_range(0.85, 1.15)
			points.append(Vector2.from_angle(angle) * radius * variation)

		var base_color: Color
		if cell_type == "white_blood_cell":
			base_color = Color(0.82, 0.9, 1.0, 1.0)
		else:
			base_color = Color.from_hsv(randf(), 0.65, 0.9)

		draw_colored_polygon(points, base_color)
		draw_circle(Vector2.ZERO, radius * 0.38, base_color.darkened(0.35))
