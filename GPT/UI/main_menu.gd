extends Control

## Lightweight main menu for Alive Cells.
## The background is procedurally composed once and remains static.

const SIMULATION_SCENE := preload("res://GPT/CellSystem/CellSystemTest.tscn")

@export var min_cells: int = 1
@export var max_cells: int = 7
@export var background_seed: int = 48302

var _rng := RandomNumberGenerator.new()
var _cell_positions: Array[Vector2] = []
var _cell_scales: Array[float] = []
var _cell_colors: Array[Color] = []
var _resource_positions: Array[Vector2] = []
var _resource_scales: Array[float] = []

var _simulation_button: Button
var _options_button: Button
var _quit_button: Button
var _status_label: Label

func _ready() -> void:
	_rng.seed = background_seed
	_build_static_background()
	_build_menu_ui()
	queue_redraw()

func _build_static_background() -> void:
	_cell_positions.clear()
	_cell_scales.clear()
	_cell_colors.clear()
	_resource_positions.clear()
	_resource_scales.clear()

	var cell_count: int = _rng.randi_range(min_cells, max_cells)
	var screen_size: Vector2 = get_viewport_rect().size
	var left_reserved: float = screen_size.x * 0.43

	for _i in range(cell_count):
		var p := Vector2(
			_rng.randf_range(left_reserved + 40.0, screen_size.x - 90.0),
			_rng.randf_range(70.0, screen_size.y - 70.0)
		)
		_cell_positions.append(p)
		_cell_scales.append(_rng.randf_range(0.72, 1.35))
		_cell_colors.append(Color.from_hsv(_rng.randf(), 0.48, 0.93))

	var resource_count: int = _rng.randi_range(7, 13)
	for _i in range(resource_count):
		var p := Vector2(
			_rng.randf_range(left_reserved + 25.0, screen_size.x - 45.0),
			_rng.randf_range(45.0, screen_size.y - 45.0)
		)
		_resource_positions.append(p)
		_resource_scales.append(_rng.randf_range(0.65, 1.25))

func _build_menu_ui() -> void:
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 84)
	root_margin.add_theme_constant_override("margin_top", 70)
	root_margin.add_theme_constant_override("margin_bottom", 70)
	add_child(root_margin)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(430, 0)
	column.add_theme_constant_override("separation", 18)
	root_margin.add_child(column)

	var title := Label.new()
	title.text = "Alive Cells"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Um pequeno ecossistema, infinitas histórias."
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.86, 0.90, 1.0))
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	column.add_child(spacer)

	_simulation_button = _create_menu_button("Simular")
	_simulation_button.pressed.connect(_on_simulate_pressed)
	column.add_child(_simulation_button)

	_options_button = _create_menu_button("Opções")
	_options_button.pressed.connect(_on_options_pressed)
	column.add_child(_options_button)

	_quit_button = _create_menu_button("Sair")
	_quit_button.pressed.connect(_on_quit_pressed)
	column.add_child(_quit_button)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.68, 0.76, 0.80, 1.0))
	column.add_child(_status_label)

func _create_menu_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(390, 62)
	button.add_theme_font_size_override("font_size", 24)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("h_separation", 12)
	return button

func _draw() -> void:
	var size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.055, 0.075, 1.0), true)

	var glow_center := Vector2(size.x * 0.76, size.y * 0.46)
	for radius in [420.0, 300.0, 190.0]:
		var alpha := 0.018 if radius > 300.0 else 0.028
		draw_circle(glow_center, radius, Color(0.12, 0.42, 0.38, alpha))

	for i in range(_resource_positions.size()):
		var p := _resource_positions[i]
		var s := _resource_scales[i]
		draw_circle(p, 10.0 * s, Color(0.22, 0.88, 0.60, 0.16))
		draw_circle(p, 6.0 * s, Color(0.38, 1.0, 0.72, 0.75))
		draw_circle(p, 2.2 * s, Color(0.84, 1.0, 0.92, 0.95))

	for i in range(_cell_positions.size()):
		var p := _cell_positions[i]
		var s := _cell_scales[i]
		var c := _cell_colors[i]
		var r := 54.0 * s
		draw_circle(p, r * 1.22, Color(c.r, c.g, c.b, 0.08))
		draw_circle(p, r, Color(c.r, c.g, c.b, 0.92))
		draw_circle(p, r * 0.42, c.darkened(0.22))
		draw_circle(p + Vector2(-r * 0.18, -r * 0.18), r * 0.11, Color(1.0, 1.0, 1.0, 0.30))

	var divider_x := size.x * 0.39
	draw_line(Vector2(divider_x, 70.0), Vector2(divider_x, size.y - 70.0), Color(0.70, 0.85, 0.90, 0.08), 2.0)

func _on_simulate_pressed() -> void:
	get_tree().change_scene_to_packed(SIMULATION_SCENE)

func _on_options_pressed() -> void:
	_status_label.text = "Configurações da simulação chegarão em breve."

func _on_quit_pressed() -> void:
	get_tree().quit()
