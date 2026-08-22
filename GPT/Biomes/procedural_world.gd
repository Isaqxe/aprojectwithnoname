extends Node2D

## Protótipo experimental — mundo procedural determinístico baseado em chunks.
## Gera somente os chunks próximos do Player e remove os distantes.

@export_category("World")
@export var world_seed: int = 123456
@export var chunk_size: int = 512
@export_range(0, 8) var load_radius: int = 2
@export_range(0, 12) var unload_radius: int = 3

@export_category("Noise Scale")
@export var noise_scale: float = 0.0004
@export var climate_noise_scale: float = 0.0007
@export var humidity_noise_scale: float = 0.0009
@export var fertility_noise_scale: float = 0.0011
@export var warp_scale: float = 0.0012
@export var warp_strength: float = 150.0

@export_category("Macroregion")
@export_range(0.0, 1.0) var void_threshold: float = 0.60

@export_category("Climate")
@export_range(0.0, 1.0) var cold_temperature: float = 0.34
@export_range(0.0, 1.0) var hot_temperature: float = 0.68
@export_range(0.0, 1.0) var green_humidity: float = 0.45
@export_range(0.0, 1.0) var lush_fertility: float = 0.60

@export_category("Chunk Visual")
@export var samples_per_chunk: int = 64
@export var show_chunk_borders: bool = false

var _player: Node2D
var _loaded_chunks: Dictionary = {}

var _biome_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()
var _humidity_noise := FastNoiseLite.new()
var _fertility_noise := FastNoiseLite.new()
var _warp_x_noise := FastNoiseLite.new()
var _warp_y_noise := FastNoiseLite.new()


func _ready() -> void:
	_setup_noise()
	_find_player.call_deferred()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return

	_update_chunks()


func _setup_noise() -> void:
	_setup_noise_layer(_biome_noise, world_seed, noise_scale)
	_setup_noise_layer(_temperature_noise, world_seed + 101, climate_noise_scale)
	_setup_noise_layer(_humidity_noise, world_seed + 202, humidity_noise_scale)
	_setup_noise_layer(_fertility_noise, world_seed + 303, fertility_noise_scale)
	_setup_noise_layer(_warp_x_noise, world_seed + 404, warp_scale)
	_setup_noise_layer(_warp_y_noise, world_seed + 505, warp_scale)


func _setup_noise_layer(noise: FastNoiseLite, seed_value: int, frequency: float) -> void:
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D


func _update_chunks() -> void:
	var player_chunk: Vector2i = world_to_chunk(_player.global_position)

	for y in range(player_chunk.y - load_radius, player_chunk.y + load_radius + 1):
		for x in range(player_chunk.x - load_radius, player_chunk.x + load_radius + 1):
			var coord := Vector2i(x, y)
			if not _loaded_chunks.has(coord):
				_generate_chunk(coord)

	var chunks_to_remove: Array[Vector2i] = []
	for key in _loaded_chunks.keys():
		var coord: Vector2i = key
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
	visual.world_seed = world_seed
	visual.biome_noise = _biome_noise
	visual.temperature_noise = _temperature_noise
	visual.humidity_noise = _humidity_noise
	visual.fertility_noise = _fertility_noise
	visual.warp_x_noise = _warp_x_noise
	visual.warp_y_noise = _warp_y_noise
	visual.void_threshold = void_threshold
	visual.cold_temperature = cold_temperature
	visual.hot_temperature = hot_temperature
	visual.green_humidity = green_humidity
	visual.lush_fertility = lush_fertility
	visual.warp_strength = warp_strength
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
	var world_seed: int = 123456

	var biome_noise: FastNoiseLite
	var temperature_noise: FastNoiseLite
	var humidity_noise: FastNoiseLite
	var fertility_noise: FastNoiseLite
	var warp_x_noise: FastNoiseLite
	var warp_y_noise: FastNoiseLite

	var void_threshold: float = 0.60
	var cold_temperature: float = 0.34
	var hot_temperature: float = 0.68
	var green_humidity: float = 0.45
	var lush_fertility: float = 0.60
	var warp_strength: float = 150.0
	var samples_per_chunk: int = 64
	var show_chunk_borders: bool = false

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var samples: int = maxi(samples_per_chunk, 1)
		var cell_size: float = chunk_size / float(samples)

		for y in range(samples):
			for x in range(samples):
				var center := Vector2((x + 0.5) * cell_size, (y + 0.5) * cell_size)
				var global_position: Vector2 = Vector2(chunk_coord) * (chunk_size - 0.5) + center

				# Domain warping mantém a continuidade entre chunks, mas quebra
				# bordas excessivamente uniformes.
				var warp_offset := Vector2(
					warp_x_noise.get_noise_2d(global_position.x, global_position.y),
					warp_y_noise.get_noise_2d(global_position.x, global_position.y)
				) * warp_strength
				var warped_position: Vector2 = global_position + warp_offset

				var macro_value: float = _sample_noise(biome_noise, warped_position)
				var temperature: float = _sample_noise(temperature_noise, warped_position)
				var humidity: float = _sample_noise(humidity_noise, warped_position)
				var fertility: float = _sample_noise(fertility_noise, warped_position)
				var biome_color: Color = _get_biome_color(macro_value, temperature, humidity, fertility)

				draw_rect(
					Rect2(Vector2(x, y) * cell_size, Vector2.ONE * (cell_size + 0.5)),
					biome_color
				)

		if show_chunk_borders:
			draw_rect(
				Rect2(Vector2.ZERO, Vector2.ONE * 512),
				Color(0.08, 0.08, 0.08, 0.35),
				false,
				2.0
			)

	func _sample_noise(noise: FastNoiseLite, position: Vector2) -> float:
		return (noise.get_noise_2d(position.x, position.y) + 1.0) * 0.5

	func _get_biome_color(macro_value: float, temperature: float, humidity: float, fertility: float) -> Color:
		# A macro noise decides where substantial regions exist.
		if macro_value < void_threshold:
			return Color(0.42, 0.42, 0.42, 1.0)

		# Temperature establishes the broad climatic family.
		if temperature < cold_temperature:
			var cold_light: float = 0.88 + humidity * 0.12
			return Color(0.48 * cold_light, 0.72 * cold_light, 0.95 * cold_light, 1.0)

		if temperature > hot_temperature:
			var hot_light: float = 0.88 + (1.0 - humidity) * 0.12
			return Color(0.95 * hot_light, 0.55 * hot_light, 0.28 * hot_light, 1.0)

		# Within the temperate band, humidity and fertility now matter.
		if humidity >= green_humidity:
			var green_light: float = 0.88 + fertility * 0.12
			if fertility >= lush_fertility:
				return Color(0.30 * green_light, 0.92 * green_light, 0.38 * green_light, 1.0)
			return Color(0.42 * green_light, 0.82 * green_light, 0.46 * green_light, 1.0)

		# Dry temperate zones become a transitional biome tone.
		var transition_factor: float = clamp(
			(temperature - cold_temperature) / max(hot_temperature - cold_temperature, 0.001),
			0.0,
			1.0
		)
		var dry_factor: float = 1.0 - humidity
		return Color(
			0.50 + dry_factor * 0.08,
			0.68 - dry_factor * 0.08 + transition_factor * 0.04,
			0.45 - transition_factor * 0.08,
			1.0
		)
