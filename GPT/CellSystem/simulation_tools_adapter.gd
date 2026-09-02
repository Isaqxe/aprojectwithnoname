extends Node

## Bootstraps the existing SimulationTools controller at the scene root.
## Also bridges CellInspector selection into the tools controller.

const TOOLS_SCRIPT := preload("res://GPT/CellSystem/simulation_tools.gd")
const DEFAULT_TIME_SCALE: float = 1.0

var _tools: Node = null
var _inspector: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Node = get_parent()
	if root == null:
		return
	_inspector = root.get_node_or_null("CellInspector")
	_tools = Node.new()
	_tools.name = "SimulationToolsController"
	_tools.set_script(TOOLS_SCRIPT)
	root.add_child(_tools)
	_sync_selection()

func _process(_delta: float) -> void:
	_sync_selection()

func _sync_selection() -> void:
	if _tools == null or not is_instance_valid(_tools):
		return
	if _inspector == null or not is_instance_valid(_inspector):
		return
	var selected: Variant = _inspector.get("_selected_cell")
	if selected is Node and is_instance_valid(selected):
		_tools.set("_selected_cell", selected)
	else:
		_tools.set("_selected_cell", null)

func _exit_tree() -> void:
	Engine.time_scale = DEFAULT_TIME_SCALE
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = false
	if _tools != null and is_instance_valid(_tools):
		_tools.queue_free()
