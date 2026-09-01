extends Node

## Debug inspector for the CellSystem test scene.
## Uses a physics point query so cells do not need to process mouse events themselves.

@export var collision_mask: int = 1

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	inspect_at_mouse()

func inspect_at_mouse() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		print("CellInspector: no Camera2D found.")
		return

	var world_position: Vector2 = camera.get_global_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_point(query, 16)
	var selected_cell: Node = null

	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or not collider is Node:
			continue
		var candidate: Node = collider as Node
		if candidate.is_in_group("SimCells") and candidate.has_method("get_inspection_data"):
			selected_cell = candidate
			break

	if selected_cell == null:
		return

	_print_information(selected_cell.get_inspection_data())

func _print_information(data: Dictionary) -> void:
	print("========== CELL INFORMATION ==========")
	print("ID: ", data.get("cell_id", "unknown"))
	print("Species: ", data.get("species_id", "unknown"))
	print("Generation: ", data.get("generation", 0))
	print("Parent ID: ", data.get("parent_id", "none"))
	print("Player: ", data.get("player", false))
	print("State: ", data.get("state", "unknown"))
	print("Health: %.2f / %.2f" % [data.get("health", 0.0), data.get("max_health", 0.0)])
	print("Damage: %.2f" % data.get("damage", 0.0))
	print("Speed: %.2f" % data.get("speed", 0.0))
	print("Size: %.2f" % data.get("size", 0.0))
	print("Regeneration: %.2f" % data.get("regeneration_rate", 0.0))
	print("Resources: %.2f / %.2f" % [data.get("resources", 0.0), data.get("resource_capacity", 0.0)])
	print("Mitosis count: ", data.get("mitosis_count", 0))
	print("Next mitosis cost: %.2f" % data.get("next_mitosis_cost", 0.0))
	print("Genes: ", data.get("genes", {}))
	print("=====================================")
