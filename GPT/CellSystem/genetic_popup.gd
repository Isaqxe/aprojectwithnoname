extends PanelContainer
class_name GeneticPopup

## Persistent genetic profile window.
## The Inspector owns the lifetime of each popup and may provide a comparison profile.

signal close_requested(popup: GeneticPopup)

var _cell: Node = null
var _data: Dictionary = {}
var _comparison_data: Dictionary = {}

var _species_label: Label
var _generation_label: Label
var _mutation_label: Label
var _body: VBoxContainer
var _drag_origin: Vector2 = Vector2.ZERO
var _dragging: bool = false

const POPUP_SIZE := Vector2(390.0, 0.0)

const GENE_GROUPS: Array[Dictionary] = [
	{"title": "ATRIBUTOS", "genes": [
		{"name": "health", "label": "Vida"},
		{"name": "damage", "label": "Dano"},
		{"name": "speed", "label": "Velocidade"},
		{"name": "size", "label": "Tamanho"},
		{"name": "regeneration_rate", "label": "Regeneração"},
		{"name": "efficiency", "label": "Eficiência"},
		{"name": "mitosis_cost", "label": "Custo de mitose"}
	]},
	{"title": "ADAPTAÇÕES", "genes": [
		{"name": "cold_adaptation", "label": "Frio"},
		{"name": "temperate_adaptation", "label": "Temperado"},
		{"name": "heat_adaptation", "label": "Calor"},
		{"name": "void_adaptation", "label": "Vazio"},
		{"name": "humidity_adaptation", "label": "Umidade"}
	]},
	{"title": "CARACTERÍSTICAS", "genes": [
		{"name": "territorial", "label": "Territorial"},
		{"name": "cooperative_hunter", "label": "Caçador cooperativo"},
		{"name": "camouflage", "label": "Camuflagem"},
		{"name": "armor", "label": "Armadura"},
		{"name": "toxin", "label": "Toxina"},
		{"name": "specialized_feeding", "label": "Alimentação especializada"},
		{"name": "sociality", "label": "Sociabilidade"},
		{"name": "aggression", "label": "Agressividade"},
		{"name": "caution", "label": "Cautela"},
		{"name": "group_response", "label": "Resposta de grupo"}
	]}
]

func _ready() -> void:
	custom_minimum_size = POPUP_SIZE
	size = Vector2(390.0, 420.0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()

func set_cell(cell: Node) -> void:
	_cell = cell
	_refresh_data()

func set_comparison_data(other_data: Dictionary) -> void:
	_comparison_data = other_data.duplicate(true)
	_render()

func clear_comparison() -> void:
	_comparison_data.clear()
	_render()

func get_profile_data() -> Dictionary:
	return _data.duplicate(true)

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 34.0)
	header.gui_input.connect(_on_header_input)
	column.add_child(header)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_column)

	_species_label = Label.new()
	_species_label.add_theme_font_size_override("font_size", 19)
	title_column.add_child(_species_label)

	_generation_label = Label.new()
	_generation_label.add_theme_font_size_override("font_size", 12)
	title_column.add_child(_generation_label)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Fechar"
	close_button.custom_minimum_size = Vector2(32.0, 32.0)
	close_button.pressed.connect(_request_close)
	header.add_child(close_button)

	var separator := HSeparator.new()
	column.add_child(separator)

	_mutation_label = Label.new()
	_mutation_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_mutation_label)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 5)
	column.add_child(_body)

func _refresh_data() -> void:
	if not is_instance_valid(_cell) or not _cell.has_method("get_inspection_data"):
		_data = {}
	else:
		_data = _cell.get_inspection_data()
	_render()

func _render() -> void:
	if _species_label == null or _generation_label == null or _body == null:
		return

	_species_label.text = String(_data.get("species_id", "Organismo"))
	_generation_label.text = "Geração %d  •  ID %s" % [int(_data.get("generation", 0)), String(_data.get("cell_id", "unknown"))]

	var mutation_count: int = int(_data.get("mutation_count", 0))
	if mutation_count > 0:
		_mutation_label.text = "MUTAÇÕES NESTA CÉLULA: %d" % mutation_count
	else:
		_mutation_label.text = "Nenhuma mutação registrada no último evento"

	for child in _body.get_children():
		child.queue_free()

	for group in GENE_GROUPS:
		var title := Label.new()
		title.text = String(group["title"])
		title.add_theme_font_size_override("font_size", 12)
		_body.add_child(title)

		for gene_info in group["genes"]:
			var gene_name: String = String(gene_info["name"])
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_body.add_child(row)

			var label := Label.new()
			label.text = String(gene_info["label"])
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.add_theme_font_size_override("font_size", 12)
			row.add_child(label)

			var phenotype_label := Label.new()
			phenotype_label.text = _format_phenotype(_get_gene_data(_data, gene_name).get("phenotype", 0.0))
			phenotype_label.custom_minimum_size = Vector2(70.0, 0.0)
			phenotype_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			phenotype_label.add_theme_font_size_override("font_size", 12)
			row.add_child(phenotype_label)

			var genotype_label := Label.new()
			genotype_label.text = _format_genotype(_get_gene_data(_data, gene_name))
			genotype_label.custom_minimum_size = Vector2(88.0, 0.0)
			genotype_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			genotype_label.add_theme_font_size_override("font_size", 11)
			row.add_child(genotype_label)

			if not _comparison_data.is_empty():
				var differs: bool = _gene_differs(gene_name)
				if differs:
					label.text += "  ≠"
					genotype_label.text += "  DIF."

		var footer := Label.new()
		footer.text = "Fenótipo   |   Genótipo (A / B)" if _comparison_data.is_empty() else "Fenótipo   |   Genótipo (A / B)   •   ≠ = diferença"
		footer.add_theme_font_size_override("font_size", 10)
		_body.add_child(footer)

func _get_gene_data(data: Dictionary, gene_name: String) -> Dictionary:
	var genes: Dictionary = data.get("genes", {})
	for category_key in genes.keys():
		var category_data: Variant = genes[category_key]
		if not category_data is Dictionary:
			continue
		var raw: Variant = category_data.get(gene_name, {})
		if raw is Dictionary:
			return raw
	return {}

func _gene_differs(gene_name: String) -> bool:
	var current: Dictionary = _get_gene_data(_data, gene_name)
	var other: Dictionary = _get_gene_data(_comparison_data, gene_name)
	if current.is_empty() or other.is_empty():
		return false
	return _normalize_value(current.get("phenotype")) != _normalize_value(other.get("phenotype")) or _format_allele(current.get("allele_a")) != _format_allele(other.get("allele_a")) or _format_allele(current.get("allele_b")) != _format_allele(other.get("allele_b"))

func _normalize_value(value: Variant) -> String:
	if value is bool:
		return "true" if bool(value) else "false"
	if value is float or value is int:
		return "%.5f" % float(value)
	return String(value)

func _format_phenotype(value: Variant) -> String:
	if value is bool:
		return "SIM" if bool(value) else "NÃO"
	if value is float or value is int:
		return "%.2f" % float(value)
	return String(value)

func _format_genotype(data: Dictionary) -> String:
	if data.is_empty():
		return "n/a"
	return "%s / %s" % [_format_allele(data.get("allele_a", "n/a")), _format_allele(data.get("allele_b", "n/a"))]

func _format_allele(value: Variant) -> String:
	if value is float or value is int:
		return "%.3f" % float(value)
	return String(value)

func _request_close() -> void:
	close_requested.emit(self)

func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse_event.pressed
			if _dragging:
				_drag_origin = get_global_mouse_position() - global_position
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		global_position = motion.global_position - _drag_origin
		_clamp_to_viewport()

func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_dragging = false

func _clamp_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var max_x: float = maxf(8.0, viewport_size.x - size.x - 8.0)
	var max_y: float = maxf(8.0, viewport_size.y - size.y - 8.0)
	position.x = clampf(position.x, 8.0, max_x)
	position.y = clampf(position.y, 8.0, max_y)
