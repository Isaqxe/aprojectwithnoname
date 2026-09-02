extends SimulationTools

## Small compatibility layer for the first tools build.
## Reuses CellInspector's existing selection before falling back to the mouse.
class_name SimulationToolsV2

func _select_target_from_mouse() -> void:
	_selected_cell = null
	if cell_inspector != null and is_instance_valid(cell_inspector):
		var inspected: Variant = cell_inspector.get("_selected_cell")
		if inspected is Node and is_instance_valid(inspected):
			_selected_cell = inspected as Node
	if not is_instance_valid(_selected_cell):
		_selected_cell = _query_cell_at_mouse()

func _exit_tree() -> void:
	Engine.time_scale = DEFAULT_TIME_SCALE
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = false
