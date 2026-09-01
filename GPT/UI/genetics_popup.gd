extends Window

## Compact genetics popup for the selected cell or lineage record.

const PORTRAIT_SCRIPT := preload("res://GPT/UI/cell_portrait.gd")

func setup(data: Dictionary) -> void:
	title = "Genética — %s" % _short_id(String(data.get("cell_id", "unknown")))
	size = Vector2i(420, 520)
	position = Vector2i(180, 120)
	transient = true
	close_requested.connect(_on_close_requested)
	_build_ui(data)
	popup_centered()

func _build_ui(data: Dictionary) -> void:
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var portrait := PORTRAIT_SCRIPT.new()
	portrait.setup(data)
	portrait.custom_minimum_size = Vector2(110, 110)
	column.add_child(portrait)

	var title_label := Label.new()
	title_label.text = "%s • Gen %d" % [String(data.get("species_id", "unknown")), int(data.get("generation", 0))]
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	column.add_child(title_label)

	var status := Label.new()
	status.text = "Estado: %s" % ("Vivo" if bool(data.get("alive", true)) else "Morto")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)

	column.add_child(HSeparator.new())

	var genes: Dictionary = data.get("genes", {})
	var gene_names: Array[String] = []
	for key in genes.keys():
		gene_names.append(String(key))
	gene_names.sort()

	for gene_name in gene_names:
		var value := Label.new()
		value.text = "%s: %.3f" % [gene_name, float(genes[gene_name])]
		column.add_child(value)

func _short_id(value: String) -> String:
	var digits := value.trim_prefix("cell_")
	if digits.is_valid_int():
		return "#%d" % int(digits)
	return value

func _on_close_requested() -> void:
	queue_free()
