extends Node2D

## Protótipo experimental — mundo procedural determinístico baseado em chunks.
## Gera somente os chunks próximos do Player e remove os distantes.

@export_category("World")
@export var world_seed: int = 123456
@export var chunk_size: int = 512
@export_range(0, 8) var load_radius: int = 2
@export_range(0, 12) var unload_radius: int = 3
@export var noise_scale: float = 0.0007

@export_category("Biome Thresholds")
@export_range(0.0, 1.0) var void_threshold: float = 0.62
@export_range(0.0, 1.0) var cold_threshold: float = 0.75
@export_range(0.0, 1.0) var hot_threshold: float = 0.90

@export_category("Chunk Visual")
@export var samples_per_chunk: int = 24
@export var show_chunk_borders: bool = false

var _player: Node2D
var _loaded_chunks: Dictionary = {}
var _biome_noise := FastNoiseLite.new()


func _ready() -> void:
	_setup_noise()
	_find_player.call_deferred()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return

	_update_chunks()


func _setup_noise() -> void:
	_biome_noise.seed = world_seed
	_biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_biome_noise.frequency = noise_scale


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D


func _update_chunks() -> void:
	var player_chunk := world_to_chunk(_player.global_position)

	for y in range(player_chunk.y - load_radius, player_chunk.y + load_radius + 1):
		for x in range(player_chunk.x - load_radius, player_chunk.x + load_radius + 1):
			var coord := Vector2i(x, y)
			if not _loaded_chunks.has(coord):
				_generate_chunk(coord)

	var chunks_to_remove: Array[Vector2i] = []
	for coord: Vector2i in _loaded_chunks.keys():
		if abs(coord.x - player_chunk.x) > unload_radius or abs(coord.y - player_chunk.y) > unload_radius:
			chunks_to_remove.append(coord)

	for coord in chunks_to_remove:
		_unload_chunk(coord)


func world_to_chunk(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / float(chunk_size)),
		floori(world_position.y / float(chunk_size))
	)


func _generate_chunk(coord: Vector2i) -> void:
	var chunk := Node2D.new()
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector2(coord * chunk_size)
	chunk.z_index = -100
	add_child(chunk)

	var visual := ChunkVisual.new()
	visual.chunk_size = float(chunk_size) + 0.5
	visual.chunk_coord = coord
	visual.biome_noise = _biome_noise
	visual.void_threshold = void_threshold
	visual.cold_threshold = cold_threshold
	visual.hot_threshold = hot_threshold
	visual.samples_per_chunk = samples_per_chunk
	visual.show_chunk_borders = show_chunk_borders
	chunk.add_child(visual)

	_loaded_chunks[coord] = chunk


func _unload_chunk(coord: Vector2i) -> void:
	var chunk: Node = _loaded_chunks.get(coord)
	if chunk != null and is_instance_valid(chunk):
		chunk.queue_free()
	_loaded_chunks.erase(coord)


class ChunkVisual extends Node2D:
	var chunk_size: float = 512.0
	var chunk_coord := Vector2i.ZERO
	var biome_noise: FastNoiseLite
	var void_threshold: float = 0.62
	var cold_threshold: float = 0.75
	var hot_threshold: float = 0.90
	var samples_per_chunk: int = 24
	var show_chunk_borders: bool = false

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var samples := max(samples_per_chunk, 1)
		var cell_size := chunk_size / float(samples)

		for y in range(samples):
			for x in range(samples):
				var center := Vector2((x + 0.5) * cell_size, (y + 0.5) * cell_size)
				var global_position := Vector2(chunk_coord * 512) + center
				var sample := (biome_noise.get_noise_2d(global_position.x, global_position.y) + 1.0) * 0.5
				var biome_color := _get_biome_color(sample)
				draw_rect(Rect2(Vector2(x, y) * cell_size, Vector2.ONE * (cell_size + 0.5)), biome_color)

		if show_chunk_borders:
			draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * 512), Color(0.08, 0.08, 0.08, 0.35), false, 2.0)

	func _get_biome_color(sample: float) -> Color:
		# The void is the dominant macroregion. The remaining values form rarer biome bands.
		if sample < void_threshold:
			return Color(0.42, 0.42, 0.42, 1.0)
		if sample < cold_threshold:
			return Color(0.48, 0.72, 0.95, 1.0)
		if sample > hot_threshold:
			return Color(0.95, 0.55, 0.28, 1.0)
		return Color(0.42, 0.82, 0.46, 1.0)
