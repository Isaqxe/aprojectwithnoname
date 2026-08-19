extends Control

## Protótipo da tela de criação da célula.
## A interface é provisória e o sistema visual será refinado junto do gerador procedural.

var selected_type := "eukaryote"
var shape_seed := 12345
var cell_color := Color(0.35, 0.8, 1.0)
var cell_size := 100.0

var preview: CellPreview
var type_label: Label
var description_label: Label
var size_label: Label

func _ready() -> void:
	_build_ui()
	_update_preview()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.065, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title := Label.new()
	title.text = "CRIE SUA CÉLULA"
	title.position = Vector2(70, 45)
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var type_title := Label.new()
	type_title.text = "TIPO CELULAR"
	type_title.position = Vector2(70, 125)
	type_title.add_theme_font_size_override("font_size", 20)
	add_child(type_title)

	var prok_button := Button.new()
	prok_button.text = "PROCARIOTE"
	prok_button.position = Vector2(70, 170)
	prok_button.size = Vector2(190, 55)
	prok_button.pressed.connect(func(): _select_type("prokaryote"))
	add_child(prok_button)

	var euk_button := Button.new()
	euk_button.text = "EUCARIOTE"
	euk_button.position = Vector2(280, 170)
	euk_button.size = Vector2(190, 55)
	euk_button.pressed.connect(func(): _select_type("eukaryote"))
	add_child(euk_button)

	type_label = Label.new()
	type_label.position = Vector2(70, 245)
	type_label.add_theme_font_size_override("font_size", 22)
	add_child(type_label)

	description_label = Label.new()
	description_label.position = Vector2(70, 285)
	description_label.size = Vector2(400, 100)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description_label)

	var appearance_title := Label.new()
	appearance_title.text = "APARÊNCIA"
	appearance_title.position = Vector2(70, 410)
	appearance_title.add_theme_font_size_override("font_size", 20)
	add_child(appearance_title)

	var size_slider := HSlider.new()
	size_slider.position = Vector2(70, 470)
	size_slider.size = Vector2(400, 30)
	size_slider.min_value = 70.0
	size_slider.max_value = 140.0
	size_slider.value = cell_size
	size_slider.value_changed.connect(_set_size)
	add_child(size_slider)

	size_label = Label.new()
	size_label.position = Vector2(70, 505)
	add_child(size_label)

	var confirm := Button.new()
	confirm.text = "CONFIRMAR CÉLULA"
	confirm.position = Vector2(70, 570)
	confirm.size = Vector2(400, 60)
	confirm.pressed.connect(_confirm)
	add_child(confirm)

	preview = CellPreview.new()
	preview.position = Vector2(760, 390)
	add_child(preview)

	var preview_label := Label.new()
	preview_label.text = "PRÉ-VISUALIZAÇÃO"
	preview_label.position = Vector2(665, 250)
	preview_label.add_theme_font_size_override("font_size", 24)
	add_child(preview_label)

func _select_type(type: String) -> void:
	selected_type = type
	_update_preview()

func _set_size(value: float) -> void:
	cell_size = value
	_update_preview()

func _update_preview() -> void:
	if preview == null:
		return
	preview.cell_type = selected_type
	preview.radius = cell_size
	preview.visual_seed = shape_seed
	preview.queue_redraw()

	if selected_type == "prokaryote":
		type_label.text = "PROCARIOTE"
		description_label.text = "Estrutura mais simples, sem núcleo delimitado."
	else:
		type_label.text = "EUCARIOTE"
		description_label.text = "Estrutura mais complexa, com núcleo delimitado."

	size_label.text = "Tamanho: %.0f" % cell_size

func _confirm() -> void:
	print("Célula criada: ", selected_type, " | tamanho: ", cell_size, " | seed: ", shape_seed)

class CellPreview extends Node2D:
	var radius := 100.0
	var cell_type := "eukaryote"
	var visual_seed := 12345

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = visual_seed
		var points := PackedVector2Array()
		var count := 11
		for i in count:
			var angle := TAU * float(i) / count
			var variation := rng.randf_range(0.84, 1.16)
			points.append(Vector2.from_angle(angle) * radius * variation)

		var base_color := Color(0.35, 0.8, 1.0)
		draw_colored_polygon(points, base_color)
		draw_arc(Vector2.ZERO, radius * 0.98, 0.0, TAU, 48, Color(0.7, 0.95, 1.0), 3.0)

		if cell_type == "eukaryote":
			draw_circle(Vector2.ZERO, radius * 0.34, Color(0.15, 0.28, 0.55))
			draw_circle(Vector2.ZERO, radius * 0.18, Color(0.25, 0.45, 0.8))
		else:
			for i in 4:
				var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(radius * 0.25, radius * 0.55)
				draw_circle(p, radius * 0.045, Color(0.2, 0.35, 0.6))
