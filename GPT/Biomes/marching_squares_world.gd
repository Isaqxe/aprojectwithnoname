extends Node2D

## Protótipo experimental — fronteiras de biomas com Marching Squares.
## Mantém geração determinística por chunks, mas troca a grade visual de quadrados
## por contornos poligonais reconstruídos a partir do campo de bioma.

@export_category("World")
@export var world_seed: int = 123456
@export var chunk_size: int = 512
@export_range(0, 6) var load_radius: int = 2
@export_range(0, 8) var unload_radius: int = 3

@export_category("Sampling")
@export_range(8, 128) var samples_per_chunk: int = 48
@export var climate_scale: float = 0.0007
@export var humidity_scale: float = 0.0009
@export var macro_scale: float = 0.00045

@export_category("Macroregion")
@export_range(0.0, 1.0) var void_threshold: float = 0.60

@export_category("Climate")
@export_range(0.0, 1.0) var cold_temperature: float = 0.34
@export_range(0.0, 1.0) var hot_temperature: float = 0.68
@export_range(0.0, 1.0) var green_humidity: float = 0.45

@export_category("Border Shape")
@export var warp_scale: float = 0.0012
@export var warp_strength: float = 130.0
@export_range(0.0, 1.0) var contour_jitter: float = 0.08
@export_range(0, 2) var smoothing_passes: int = 1

@export_category("Debug")
@export var show_chunk_borders: bool = false
@export var show_sample_grid: bool = false
@export var show_contours: bool = false

var _player: Node2D
var _loaded_chunks: Dictionary = {}

var _macro_noise := FastNoiseLite.new()
var _temperature_noise := FastNoiseLite.new()
var _humidity_noise := FastNoiseLite.new()
var _warp_x_noise := FastNoiseLite.new()
var _warp_y_noise := FastNoiseLite.new()

const BIOME_VOID: int = 0
const BIOME_COLD: int = 1
const BIOME_GREEN: int = 2
const BIOME_HOT: int = 3

const COLD_COLOR := Color(0.48, 0.72, 0.95, 1.0)
const GREEN_COLOR := Color(0.42, 0.82, 0.46, 1.0)
const HOT_COLOR := Color(0.95, 0.55, 0.28, 1.0)
const VOID_COLOR := Color(0.42, 0.42, 0.42, 1.0)


func _ready() -> void:
	_setup_noise()
	_find_player.call_deferred()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player()
		return

	_update_chunks()


func _setup_noise() -> void:
	_setup_noise_layer(_macro_noise, world_seed + 11, macro_scale)
	_setup_noise_layer(_temperature_noise, world_seed + 22, climate_scale)
	_setup_noise_layer(_humidity_noise, world_seed + 33, humidity_scale)
	_setup_noise_layer(_warp_x_noise, world_seed + 44, warp_scale)
	_setup_noise_layer(_warp_y_noise, world_seed + 55, warp_scale)


func _setup_noise_layer(noise: FastNoiseLite, seed_value: int, frequency: float) -> void:
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("PlayerCharacter") as Node2D


func _update_chunks() -> void:
	var player_chunk: Vector2i = _world_to_chunk(_player.global_position)

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


func _world_to_chunk(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / float(chunk_size)),
		floori(world_position.y / float(chunk_size))
	)


func _generate_chunk(coord: Vector2i) -> void:
	var chunk := Chunk.new()
	chunk.name = "Chunk_%d_%d" % [coord.x, coord.y]
	chunk.position = Vector2(coord) * float(chunk_size)
	chunk.z_index = -100
	chunk.configure(
		chunk_size,
		samples_per_chunk,
		coord,
		_macro_noise,
		_temperature_noise,
		_humidity_noise,
		_warp_x_noise,
		_warp_y_noise,
		void_threshold,
		cold_temperature,
		hot_temperature,
		green_humidity,
		warp_strength,
		contour_jitter,
		smoothing_passes,
		show_chunk_borders,
		show_sample_grid,
		show_contours
	)
	add_child(chunk)
	_loaded_chunks[coord] = chunk


func _unload_chunk(coord: Vector2i) -> void:
	var chunk: Node = _loaded_chunks.get(coord)
	if chunk != null and is_instance_valid(chunk):
		chunk.queue_free()
	_loaded_chunks.erase(coord)


class Chunk extends Node2D:
	var _chunk_size: float
	var _samples: int
	var _coord := Vector2i.ZERO
	var _macro_noise: FastNoiseLite
	var _temperature_noise: FastNoiseLite
	var _humidity_noise: FastNoiseLite
	var _warp_x_noise: FastNoiseLite
	var _warp_y_noise: FastNoiseLite
	var _void_threshold: float
	var _cold_temperature: float
	var _hot_temperature: float
	var _green_humidity: float
	var _warp_strength: float
	var _contour_jitter: float
	var _smoothing_passes: int
	var _show_chunk_borders: bool
	var _show_sample_grid: bool
	var _show_contours: bool

	func configure(
		chunk_size_value: float,
		samples_value: int,
		coord_value: Vector2i,
		macro_noise_value: FastNoiseLite,
		temperature_noise_value: FastNoiseLite,
		humidity_noise_value: FastNoiseLite,
		warp_x_noise_value: FastNoiseLite,
		warp_y_noise_value: FastNoiseLite,
		void_threshold_value: float,
		cold_temperature_value: float,
		hot_temperature_value: float,
		green_humidity_value: float,
		warp_strength_value: float,
		contour_jitter_value: float,
		smoothing_passes_value: int,
		show_chunk_borders_value: bool,
		show_sample_grid_value: bool,
		show_contours_value: bool
	) -> void:
		_chunk_size = chunk_size_value
		_samples = maxi(samples_value, 8)
		_coord = coord_value
		_macro_noise = macro_noise_value
		_temperature_noise = temperature_noise_value
		_humidity_noise = humidity_noise_value
		_warp_x_noise = warp_x_noise_value
		_warp_y_noise = warp_y_noise_value
		_void_threshold = void_threshold_value
		_cold_temperature = cold_temperature_value
		_hot_temperature = hot_temperature_value
		_green_humidity = green_humidity_value
		_warp_strength = warp_strength_value
		_contour_jitter = contour_jitter_value
		_smoothing_passes = smoothing_passes_value
		_show_chunk_borders = show_chunk_borders_value
		_show_sample_grid = show_sample_grid_value
		_show_contours = show_contours_value

	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		var cell_size: float = _chunk_size / float(_samples)
		var biome_grid: Array = _build_biome_grid()

		# Vazio é o fundo do chunk. As regiões ativas são desenhadas como
		# polígonos obtidos pelo Marching Squares.
		draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * _chunk_size), VOID_COLOR)

		for biome in [BIOME_COLD, BIOME_GREEN, BIOME_HOT]:
			var segments: Array[Vector2] = _marching_squares(biome_grid, biome, cell_size)
			var loops: Array[PackedVector2Array] = _stitch_segments(segments)

			for loop in loops:
				if loop.size() < 3:
					continue

				var simplified: PackedVector2Array = _simplify_loop(loop)
				var smoothed: PackedVector2Array = simplified
				for _i in range(_smoothing_passes):
					smoothed = _chaikin_closed(smoothed)

				var final_loop: PackedVector2Array = _jitter_loop(smoothed)
				draw_colored_polygon(final_loop, _biome_color(biome))

				if _show_contours:
					draw_polyline(final_loop, Color(0.06, 0.06, 0.06, 0.65), 2.0, true)

		if _show_sample_grid:
			for y in range(_samples + 1):
				var py := float(y) * cell_size
				draw_line(Vector2(0.0, py), Vector2(_chunk_size, py), Color(1, 1, 1, 0.07), 1.0)
			for x in range(_samples + 1):
				var px := float(x) * cell_size
				draw_line(Vector2(px, 0.0), Vector2(px, _chunk_size), Color(1, 1, 1, 0.07), 1.0)

		if _show_chunk_borders:
			draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * _chunk_size), Color(0.08, 0.08, 0.08, 0.35), false, 2.0)

	func _build_biome_grid() -> Array:
		var grid: Array = []
		for y in range(_samples + 1):
			var row: Array[int] = []
			for x in range(_samples + 1):
				var position := Vector2(float(x) * _chunk_size / float(_samples), float(y) * _chunk_size / float(_samples))
				var global_position: Vector2 = Vector2(_coord) * _chunk_size + position
				row.append(_sample_biome(global_position))
			grid.append(row)
		return grid

	func _sample_biome(global_position: Vector2) -> int:
		var warp_offset := Vector2(
			_warp_x_noise.get_noise_2d(global_position.x, global_position.y),
			_warp_y_noise.get_noise_2d(global_position.x, global_position.y)
		) * _warp_strength
		var p: Vector2 = global_position + warp_offset

		var macro: float = _sample_noise(_macro_noise, p)
		if macro < _void_threshold:
			return BIOME_VOID

		var temperature: float = _sample_noise(_temperature_noise, p)
		var humidity: float = _sample_noise(_humidity_noise, p)

		if temperature < _cold_temperature:
			return BIOME_COLD
		if temperature > _hot_temperature:
			return BIOME_HOT
		if humidity >= _green_humidity:
			return BIOME_GREEN

		# Dry temperate areas become green by default in this visual prototype.
		return BIOME_GREEN

	func _sample_noise(noise: FastNoiseLite, position: Vector2) -> float:
		return (noise.get_noise_2d(position.x, position.y) + 1.0) * 0.5

	func _marching_squares(grid: Array, target_biome: int, cell_size: float) -> Array[Vector2]:
		var segments: Array[Vector2] = []

		for y in range(_samples):
			for x in range(_samples):
				var a: bool = grid[y][x] == target_biome
				var b: bool = grid[y][x + 1] == target_biome
				var c: bool = grid[y + 1][x + 1] == target_biome
				var d: bool = grid[y + 1][x] == target_biome

				var case_id: int = int(a) | (int(b) << 1) | (int(c) << 2) | (int(d) << 3)
				if case_id == 0 or case_id == 15:
					continue

				var top := Vector2((x + 0.5) * cell_size, y * cell_size)
				var right := Vector2((x + 1.0) * cell_size, (y + 0.5) * cell_size)
				var bottom := Vector2((x + 0.5) * cell_size, (y + 1.0) * cell_size)
				var left := Vector2(x * cell_size, (y + 0.5) * cell_size)

				# Every line consists of two points in the segments array.
				match case_id:
					1, 14:
						_add_segment(segments, left, top)
					2, 13:
						_add_segment(segments, top, right)
					3, 12:
						_add_segment(segments, left, right)
					4, 11:
						_add_segment(segments, right, bottom)
					5:
						_add_segment(segments, left, top)
						_add_segment(segments, right, bottom)
					6, 9:
						_add_segment(segments, top, bottom)
					7, 8:
						_add_segment(segments, left, bottom)
					10:
						_add_segment(segments, top, right)
						_add_segment(segments, bottom, left)

		return segments

	func _add_segment(segments: Array[Vector2], start: Vector2, end: Vector2) -> void:
		segments.append(start)
		segments.append(end)

	func _stitch_segments(segments: Array[Vector2]) -> Array[PackedVector2Array]:
		var remaining: Array[Array] = []
		for i in range(0, segments.size(), 2):
			remaining.append([segments[i], segments[i + 1]])

		var loops: Array[PackedVector2Array] = []
		var epsilon := 0.01

		while not remaining.is_empty():
			var first: Array = remaining.pop_back()
			var loop := PackedVector2Array([first[0], first[1]])
			var current: Vector2 = first[1]

			while true:
				var found_index := -1
				var next_point := Vector2.ZERO

				for i in range(remaining.size()):
					var segment: Array = remaining[i]
					if current.distance_to(segment[0]) <= epsilon:
						found_index = i
						next_point = segment[1]
						break
					if current.distance_to(segment[1]) <= epsilon:
						found_index = i
						next_point = segment[0]
						break

				if found_index == -1:
					break

				remaining.remove_at(found_index)
				if next_point.distance_to(loop[0]) <= epsilon:
					break

				loop.append(next_point)
				current = next_point

			if loop.size() >= 3:
				loops.append(loop)

		return loops

	func _simplify_loop(loop: PackedVector2Array) -> PackedVector2Array:
		if loop.size() <= 4:
			return loop

		var result := PackedVector2Array()
		for i in range(loop.size()):
			var previous: Vector2 = loop[(i - 1 + loop.size()) % loop.size()]
			var current: Vector2 = loop[i]
			var next: Vector2 = loop[(i + 1) % loop.size()]

			var first_dir: Vector2 = (current - previous).normalized()
			var second_dir: Vector2 = (next - current).normalized()
			if abs(first_dir.dot(second_dir)) < 0.9995 or i % 3 == 0:
				result.append(current)

		if result.size() < 3:
			return loop
		return result

	func _chaikin_closed(loop: PackedVector2Array) -> PackedVector2Array:
		if loop.size() < 3:
			return loop

		var result := PackedVector2Array()
		for i in range(loop.size()):
			var current: Vector2 = loop[i]
			var next: Vector2 = loop[(i + 1) % loop.size()]
			result.append(current.lerp(next, 0.25))
			result.append(current.lerp(next, 0.75))
		return result

	func _jitter_loop(loop: PackedVector2Array) -> PackedVector2Array:
		if loop.is_empty() or _contour_jitter <= 0.0:
			return loop

		var result := PackedVector2Array()
		var amplitude: float = (_chunk_size / float(_samples)) * _contour_jitter
		for point in loop:
			var global_point: Vector2 = Vector2(_coord) * _chunk_size + point
			var n: float = _humidity_noise.get_noise_2d(global_point.x + 937.0, global_point.y - 421.0)
			result.append(point + Vector2(n, -n) * amplitude)
		return result

	func _biome_color(biome: int) -> Color:
		match biome:
			BIOME_COLD:
				return COLD_COLOR
			BIOME_GREEN:
				return GREEN_COLOR
			BIOME_HOT:
				return HOT_COLOR
		return VOID_COLOR
