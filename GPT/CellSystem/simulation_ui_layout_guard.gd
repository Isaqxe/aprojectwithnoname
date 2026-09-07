extends Node

## Small runtime layout guard for the science-fair UI.
## Keeps the tools dock and contextual popup inside the viewport and
## allows the Inspector to keep updating while SceneTree is paused.

@export var toolbar_bottom_margin: float = 14.0
@export var popup_margin: float = 14.0

var tools: Node
var inspector: Node
var toolbar: Control
var popup: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tools = get_parent()
	if tools == null:
		return

	inspector = tools.get_parent().get_node_or_null("CellInspector")
	if inspector != null and is_instance_valid(inspector):
		inspector.process_mode = Node.PROCESS_MODE_ALWAYS

	call_deferred("_sync_layout")

func _process(_delta: float) -> void:
	_sync_layout()

func _sync_layout() -> void:
	if tools == null or not is_instance_valid(tools):
		return

	toolbar = tools.get("_toolbar") as Control
	popup = tools.get("_popup") as Control

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if toolbar != null and is_instance_valid(toolbar):
		toolbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		toolbar.position = Vector2(0.0, 0.0)
		toolbar.offset_left = 12.0
		toolbar.offset_right = -12.0
		toolbar.offset_top = -70.0
		toolbar.offset_bottom = -12.0

	if popup != null and is_instance_valid(popup) and popup.visible:
		popup.set_anchors_preset(Control.PRESET_TOP_LEFT)
		var popup_size: Vector2 = popup.size
		var max_position: Vector2 = Vector2(
			maxf(popup_margin, viewport_size.x - popup_size.x - popup_margin),
			maxf(popup_margin, viewport_size.y - popup_size.y - toolbar_size_with_margin())
		)
		var current_position: Vector2 = popup.position
		popup.position = Vector2(
			clampf(current_position.x, popup_margin, max_position.x),
			clampf(current_position.y, popup_margin, max_position.y)
		)

func toolbar_size_with_margin() -> float:
	if toolbar == null or not is_instance_valid(toolbar):
		return 78.0
	return toolbar.size.y + toolbar_bottom_margin + 6.0
