extends Node2D
class_name ProceduralWorld

## GPU-first procedural world prototype.
## The environment map is generated on the GPU and exposed to gameplay through
## cached, low-frequency CPU readback. Rendering and simulation remain separate.

@export_category("World")
@export var world_seed: int = 123456
@export var world_size: Vector2 = Vector2(1024.0, 1024.0)
@export var environment_resolution: Vector2i = Vector2i(256, 256)

@export_category("Streaming")
@export var stream_center: Node2D
@export var generate_without_center: bool = true
@export var load_radius: float = 700.0
@export var unload_radius: float = 900.0

@export_category("Environment")
@export var void_threshold: float = 0.60
@export var cold_temperature: float = 0.34
@export var hot_temperature: float = 0.68
@export var green_humidity: float = 0.45
@export var macro_frequency: float = 0.0004
@export var temperature_frequency: float = 0.0007
@export var humidity_frequency: float = 0.0009
@export var warp_frequency: float = 0.0012
@export var warp_strength: float = 150.0
@export var border_detail_frequency: float = 0.0025
@export var border_detail_strength: float = 0.18
@export var border_micro_frequency: float = 0.0065
@export var border_micro_strength: float = 0.08

@export_category("GPU Readback")
@export var readback_interval: float = 0.25
@export var enable_cpu_readback: bool = true

var _environment_viewport: SubViewport
var _cached_image: Image
var _readback_timer: float = 0.0
var _last_center := Vector2(0.0, 0.0)

func _ready() -> void:
	_resolve_stream_center()
	_create_environment_map()
	_apply_environment_parameters()
	_update_environment_transform()

	if enable_cpu_readback:
		_refresh_cpu_cache()

func _process(delta: float) -> void:
	_resolve_stream_center()
	_update_environment_transform()

	if not enable_cpu_readback:
		return

	_readback_timer -= delta
	if _readback_timer <= 0.0:
		_refresh_cpu_cache()
		_readback_timer = readback_interval

func _resolve_stream_center() -> void:
	if stream_center != null and is_instance_valid(stream_center):
		return

	stream_center = get_tree().get_first_node_in_group("SimulationCameras") as Node2D
	if stream_center != null:
		return

	if not generate_without_center:
		return

	stream_center = self

func _create_environment_map() -> void:
	if _environment_viewport != null:
		return

	_environment_viewport = SubViewport.new()
	_environment_viewport.name = "EnvironmentMap"
	_environment_viewport.size = environment_resolution
	_environment_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_environment_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_environment_viewport.transparent_bg = false
	_environment_viewport.disable_3d = true
	add_child(_environment_viewport)

	var map_rect := ColorRect.new()
	map_rect.name = "EnvironmentField"
	map_rect.position = Vector2.ZERO
	map_rect.size = Vector2(environment_resolution)
	map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var field_material := ShaderMaterial.new()
	var shader := load("res://GPT/ProceduralWorld/procedural_environment.gdshader") as Shader
	if shader == null:
		push_error("ProceduralWorld: procedural_environment.gdshader not found.")
		return
	field_material.shader = shader
	map_rect.material = field_material
	_environment_viewport.add_child(map_rect)

func _apply_environment_parameters() -> void:
	if _environment_viewport == null:
		return

	var field: ColorRect = _environment_viewport.get_node_or_null("EnvironmentField") as ColorRect
	if field == null or field.material == null:
		return

	var field_material: ShaderMaterial = field.material as ShaderMaterial
	field_material.set_shader_parameter("world_seed", float(world_seed))
	field_material.set_shader_parameter("world_size", world_size)
	field_material.set_shader_parameter("macro_frequency", macro_frequency)
	field_material.set_shader_parameter("temperature_frequency", temperature_frequency)
	field_material.set_shader_parameter("humidity_frequency", humidity_frequency)
	field_material.set_shader_parameter("warp_frequency", warp_frequency)
	field_material.set_shader_parameter("warp_strength", warp_strength)
	field_material.set_shader_parameter("border_detail_frequency", border_detail_frequency)
	field_material.set_shader_parameter("border_detail_strength", border_detail_strength)
	field_material.set_shader_parameter("border_micro_frequency", border_micro_frequency)
	field_material.set_shader_parameter("border_micro_strength", border_micro_strength)
	field_material.set_shader_parameter("void_threshold", void_threshold)
	field_material.set_shader_parameter("cold_temperature", cold_temperature)
	field_material.set_shader_parameter("hot_temperature", hot_temperature)
	field_material.set_shader_parameter("green_humidity", green_humidity)

func _update_environment_transform() -> void:
	if _environment_viewport == null or stream_center == null:
		return

	var center: Vector2 = stream_center.global_position
	if not generate_without_center and center == _last_center:
		return

	_last_center = center

	var field: ColorRect = _environment_viewport.get_node_or_null("EnvironmentField") as ColorRect
	if field == null or field.material == null:
		return

	var field_material: ShaderMaterial = field.material as ShaderMaterial
	field_material.set_shader_parameter("world_center", center)
	field_material.set_shader_parameter("world_extent", Vector2(load_radius * 2.0, load_radius * 2.0))

func _refresh_cpu_cache() -> void:
	if _environment_viewport == null:
		return

	var texture: ViewportTexture = _environment_viewport.get_texture()
	if texture == null:
		return

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return

	_cached_image = image

## Returns the latest cached environment sample for a world-space position.
## This is intentionally cached instead of reading the GPU every simulation tick.
func get_environment_at(world_position: Vector2) -> Dictionary:
	if _cached_image == null or _cached_image.is_empty():
		return {"biome": "unknown", "macro": 0.0, "temperature": 0.0, "humidity": 0.0}

	var center: Vector2 = _last_center
	var half_extent: Vector2 = Vector2(load_radius, load_radius)
	var relative: Vector2 = world_position - center
	var uv: Vector2 = Vector2(
		(relative.x / (half_extent.x * 2.0)) + 0.5,
		(relative.y / (half_extent.y * 2.0)) + 0.5
	)
	uv = uv.clamp(Vector2.ZERO, Vector2.ONE)

	var pixel_position := Vector2i(
		int(uv.x * float(_cached_image.get_width() - 1)),
		int(uv.y * float(_cached_image.get_height() - 1))
	)
	var encoded: Color = _cached_image.get_pixelv(pixel_position)

	var macro: float = encoded.r
	var temperature: float = encoded.g
	var humidity: float = encoded.b
	var biome_code: int = int(round(encoded.a * 3.0))

	return {
		"biome": _decode_biome(biome_code),
		"macro": macro,
		"temperature": temperature,
		"humidity": humidity
	}

func get_biome_at(world_position: Vector2) -> String:
	return String(get_environment_at(world_position).get("biome", "unknown"))

func get_environment_texture() -> Texture2D:
	if _environment_viewport == null:
		return null
	return _environment_viewport.get_texture()

func get_environment_center() -> Vector2:
	return _last_center

func get_environment_extent() -> Vector2:
	return Vector2(load_radius * 2.0, load_radius * 2.0)

func _decode_biome(code: int) -> String:
	match code:
		0:
			return "void"
		1:
			return "cold"
		2:
			return "hot"
		3:
			return "green"
		_:
			return "unknown"
