extends Node2D

## Mundo procedural experimental renderizado por GPU.
## A CPU mantém somente os chunks; a aparência de cada chunk é produzida por shader.

@export_category("World")
@export var world_seed: int = 123456
@export var chunk_size: int = 512
@export_range(0, 6) var load_radius: int = 2
@export_range(0, 8) var unload_radius: int = 3
@export var generate_without_player: bool = true

@export_category("GPU Resolution")
@export var visual_scale: float = 1.0
@export var samples_hint: int = 256

@export_category("Macroregion")
@export_range(0.0, 1.0) var void_threshold: float = 0.60
@export var macro_frequency: float = 0.0004

@export_category("Climate")
@export var temperature_frequency: float = 0.0007
@export var humidity_frequency: float = 0.0009
@export var cold_temperature: float = 0.34
@export var hot_temperature: float = 0.68
@export var green_humidity: float = 0.45

@export_category("Border Shape")
@export var warp_frequency: float = 0.0012
@export var warp_strength: float = 150.0
@export var border_detail_frequency: float = 0.0025
@export var border_detail_strength: float = 0.18

var _player: Node2D
var _loaded_chunks: Dictionary = {}
var _shader: Shader
var _shader_template: ShaderMaterial
var _last_generation_center := Vector2i(999999, 999999)

func _ready() -> void:
	_setup_material()
	_find_player.call_deferred()
	if generate_without_player:
		_update_chunks(Vector2i.ZERO)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		if not generate_without_player:
			return
		return
	_update_chunks(_world_to_chunk(_player.global_position))

func _setup_material() -> void:
	var shader_source := load("res://GPT/Biomes/gpu_biome.gdshader") as Shader
	if shader_source == null:
		push_error("gpu_biome.gdshader não encontrado.")
		return
	_shader = shader_source
	_shader_template = ShaderMaterial.new()
	_shader_template.shader = _shader
	_shader_template.set_shader_parameter("world_seed", float(world_seed))
	_shader_template.set_shader_parameter("macro_frequency", macro_frequency)
	_shader_template.set_shader_parameter("temperature_frequency", temperature_frequency)
	_shader_template.set_shader_parameter("humidity_frequency", humidity_frequency)
	_shader_template.set_shader_parameter("warp_frequency", warp_frequency)
	_shader_template.set_shader_parameter("border_detail_frequency", border_detail_frequency)
	_shader_template.set_shader_parameter("void_threshold", void_threshold)
	_shader_template.set_shader_parameter("cold_temperature", cold_temperature)
	_shader_template.set_shader_parameter("hot_temperature", hot_temperature)
	_shader_template.set_shader_parameter("green_humidity", green_humidity)
	_shader_template.set_shader_parameter("warp_strength", warp_strength)
	_shader_template.set_shader_parameter("border_detail_strength", border_detail_strength)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D

func _update_chunks(center_chunk: Vector2i) -> void:
	if center_chunk == _last_generation_center and not _loaded_chunks.is_empty():
		return
	_last_generation_center = center_chunk

	for y in range(center_chunk.y - load_radius, center_chunk.y + load_radius + 1):
		for x in range(center_chunk.x - load_radius, center_chunk.x + load_radius + 1):
			var coord := Vector2i(x, y)
			if not _loaded_chunks.has(coord):
				_generate_chunk(coord)

	var chunks_to_remove: Array[Vector2i] = []
	for key in _loaded_chunks.keys():
		var coord: Vector2i = key
		if abs(coord.x - center_chunk.x) > unload_radius or abs(coord.y - center_chunk.y) > unload_radius:
			chunks_to_remove.append(coord)

	for coord in chunks_to_remove:
		_unload_chunk(coord)

func _world_to_chunk(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / float(chunk_size)),
		floori(world_position.y / float(chunk_size))
	)

func _generate_chunk(coord: Vector2i) -> void:
	if _shader_template == null:
		return

	var chunk := ColorRect.new()
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector2(coord) * float(chunk_size)
	chunk.size = Vector2.ONE * float(chunk_size) * visual_scale
	chunk.color = Color.WHITE
	chunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chunk.z_index = -100

	var material := _shader_template.duplicate() as ShaderMaterial
	material.set_shader_parameter("world_origin", Vector2(coord) * float(chunk_size))
	material.set_shader_parameter("world_scale", float(chunk_size) / max(visual_scale, 0.001))
	chunk.material = material
	add_child(chunk)
	_loaded_chunks[coord] = chunk

func _unload_chunk(coord: Vector2i) -> void:
	var chunk: Node = _loaded_chunks.get(coord)
	if chunk != null and is_instance_valid(chunk):
		chunk.queue_free()
	_loaded_chunks.erase(coord)
