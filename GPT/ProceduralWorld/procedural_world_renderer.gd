extends Node2D
class_name ProceduralWorldRenderer

## Lightweight renderer for the new ProceduralWorld prototype.
## It displays the same GPU EnvironmentMap used by gameplay queries.

@export var world_provider: ProceduralWorld
@export var display_scale: float = 1.0
@export var z_index_value: int = -100

var _display: Sprite2D

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
	_display.scale = Vector2.ONE * display_scale
	_display.z_index = z_index_value

func _create_display() -> void:
	_display = Sprite2D.new()
	_display.name = "EnvironmentDisplay"
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_display.centered = true
	_display.z_index = z_index_value
	add_child(_display)
