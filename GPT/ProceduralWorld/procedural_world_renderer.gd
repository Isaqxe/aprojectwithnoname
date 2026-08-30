extends Node2D
class_name ProceduralWorldRenderer

## Visual layer for the new ProceduralWorld prototype.
## It samples the GPU-generated environment data and turns it into a smooth biome image.

@export var world_provider: ProceduralWorld
@export var z_index_value: int = -100
@export var edge_softness: float = 0.16
@export var edge_detail_frequency: float = 0.018
@export var edge_detail_strength: float = 0.035
@export var surface_variation_strength: float = 0.04

var _display: Sprite2D
var _visual_material: ShaderMaterial

func _ready() -> void:
	if world_provider == null:
		world_provider = get_parent() as ProceduralWorld
	_create_display()

func _process(_delta: float) -> void:
	if _display == null or not is_instance_valid(_display):
		return
	if world_provider == null or not is_instance_valid(world_provider):
		return

	var map_texture: Texture2D = world_provider.get_environment_texture()
	if map_texture == null:
		return

	if _display.texture != map_texture:
		_display.texture = map_texture

	_display.position = world_provider.get_environment_center()
	var texture_size: Vector2 = Vector2(map_texture.get_width(), map_texture.get_height())
	var extent: Vector2 = world_provider.get_environment_extent()
	_display.scale = extent / texture_size
	_display.z_index = z_index_value

	_visual_material.set_shader_parameter("environment_map", map_texture)
	_visual_material.set_shader_parameter("void_threshold", world_provider.void_threshold)
	_visual_material.set_shader_parameter("cold_temperature", world_provider.cold_temperature)
	_visual_material.set_shader_parameter("hot_temperature", world_provider.hot_temperature)
	_visual_material.set_shader_parameter("green_humidity", world_provider.green_humidity)
	_visual_material.set_shader_parameter("edge_softness", edge_softness)
	_visual_material.set_shader_parameter("edge_detail_frequency", edge_detail_frequency)
	_visual_material.set_shader_parameter("edge_detail_strength", edge_detail_strength)
	_visual_material.set_shader_parameter("surface_variation_strength", surface_variation_strength)

func _create_display() -> void:
	_display = Sprite2D.new()
	_display.name = "EnvironmentDisplay"
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_display.centered = true
	_display.z_index = z_index_value

	_visual_material = ShaderMaterial.new()
	var visual_shader := load("res://GPT/ProceduralWorld/procedural_world_visual.gdshader") as Shader
	if visual_shader == null:
		push_error("ProceduralWorldRenderer: procedural_world_visual.gdshader not found.")
		return
	_visual_material.shader = visual_shader
	_display.material = _visual_material
	add_child(_display)
