extends Node

## Shared configuration for the next simulation run.
## Also keeps lightweight historical lineage records without retaining freed cell nodes.

var auto_spawn_cells: bool = false
var initial_population: int = 500
var max_population: int = 10000
var initial_resources: int = 1000
var max_resources: int = 2302
var domain_radius: float = 3000.0
var simulation_time_limit: float = 0.0

## Historical cell snapshots keyed by genetic cell_id.
## Records contain only dictionaries, never live Node references.
var lineage_records: Dictionary = {}

func reset_defaults() -> void:
	auto_spawn_cells = false
	initial_population = 500
	max_population = 10000
	initial_resources = 1000
	max_resources = 2302
	domain_radius = 3000.0
	simulation_time_limit = 0.0
	lineage_records.clear()

func begin_simulation() -> void:
	lineage_records.clear()

func record_lineage(snapshot: Dictionary) -> void:
	var cell_id: String = String(snapshot.get("cell_id", "")).strip_edges()
	if cell_id.is_empty():
		return
	lineage_records[cell_id] = snapshot.duplicate(true)

func mark_lineage_dead(cell_id: String, snapshot: Dictionary = {}) -> void:
	var normalized_id: String = cell_id.strip_edges()
	if normalized_id.is_empty():
		return
	var record: Dictionary = lineage_records.get(normalized_id, {}).duplicate(true)
	for key in snapshot.keys():
		record[key] = snapshot[key]
	record["cell_id"] = normalized_id
	record["alive"] = false
	lineage_records[normalized_id] = record

func get_lineage_record(cell_id: String) -> Dictionary:
	var normalized_id: String = cell_id.strip_edges()
	if normalized_id.is_empty() or not lineage_records.has(normalized_id):
		return {}
	return lineage_records[normalized_id].duplicate(true)

func get_lineage_family(cell_id: String, max_children: int = 4) -> Dictionary:
	var normalized_id: String = cell_id.strip_edges()
	var current: Dictionary = get_lineage_record(normalized_id)
	if current.is_empty():
		return {}

	var parent: Dictionary = {}
	var parent_id: String = String(current.get("parent_id", "")).strip_edges()
	if not parent_id.is_empty():
		parent = get_lineage_record(parent_id)

	var children: Array[Dictionary] = []
	for key in lineage_records.keys():
		var candidate: Dictionary = lineage_records[key]
		if String(candidate.get("parent_id", "")).strip_edges() != normalized_id:
			continue
		children.append(candidate.duplicate(true))

	children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("generation", 0)) < int(b.get("generation", 0))
	)

	var total_children: int = children.size()
	if children.size() > max_children:
		children = children.slice(0, max_children)

	return {
		"parent": parent,
		"current": current,
		"children": children,
		"total_children": total_children
	}
