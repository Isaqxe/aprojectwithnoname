extends Node

## Protótipo inicial do CellManager.
## Este node será responsável pela existência das células no mundo.
## Não controla comportamento individual.

var registered_cells: Array[Node] = []


func register_cell(cell: Node) -> void:
	if cell == null:
		return

	if not registered_cells.has(cell):
		registered_cells.append(cell)


func unregister_cell(cell: Node) -> void:
	registered_cells.erase(cell)


func get_cell_count() -> int:
	return registered_cells.size()


func create_cell(position: Vector2) -> void:
	## Placeholder.
	## Futuramente:
	## - instanciar cena Cell
	## - aplicar genética
	## - definir tipo/comportamento
	## - registrar automaticamente
	pass


func _process(_delta: float) -> void:
	_cleanup_invalid_cells()


func _cleanup_invalid_cells() -> void:
	for cell in registered_cells.duplicate():
		if not is_instance_valid(cell):
			registered_cells.erase(cell)
