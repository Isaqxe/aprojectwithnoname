extends Node2D

@export var molecule_scene: PackedScene
@export var molecule_count: int = 80
@export var spawn_bounds := Rect2(-1700.0, -1400.0, 2700.0, 2200.0)

var molecule_colors := [
	Color(0.25, 0.85, 1.0),
	Color(0.55, 1.0, 0.35),
	Color(1.0, 0.45, 0.75),
	Color(1.0, 0.75, 0.25),
	Color(0.65, 0.45, 1.0)
]

func _ready() -> void:
	if molecule_scene == null:
		return

	randomize()

	for i in molecule_count:
		_spawn_molecule()

func _spawn_molecule() -> void:
	var molecule := molecule_scene.instantiate() as Node2D
	if molecule == null:
		return

	molecule.position = Vector2(
		randf_range(spawn_bounds.position.x, spawn_bounds.end.x),
		randf_range(spawn_bounds.position.y, spawn_bounds.end.y)
	)

	if molecule.has_method("set"):
		molecule.set("molecule_color", molecule_colors.pick_random())

	add_child(molecule)
