extends Node

## Small global history of organism deaths for scientific feedback.
## It stores only recent events; biology remains owned by each cell.
class_name SimulationDeathLog

@export var history_limit: int = 12

var _events: Array[Dictionary] = []
var _serial: int = 0

func record_death(cell_id: String, species_id: String, reason: String, position: Vector2) -> void:
	_serial += 1
	_events.append({
		"serial": _serial,
		"cell_id": cell_id,
		"species_id": species_id,
		"reason": reason,
		"position": position,
		"time_ms": Time.get_ticks_msec()
	})
	var limit: int = maxi(history_limit, 1)
	while _events.size() > limit:
		_events.pop_front()

func get_recent_events() -> Array[Dictionary]:
	return _events.duplicate(true)

func get_latest() -> Dictionary:
	if _events.is_empty():
		return {}
	return (_events.back() as Dictionary).duplicate(true)

func clear() -> void:
	_events.clear()
	_serial = 0
