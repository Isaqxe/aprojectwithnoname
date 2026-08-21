extends Control

## Controlador provisório da tela modular de criação.
## A interface deve ser montada na cena, não criada por código.

@onready var prokaryote_button: Button = %ProkaryoteButton
@onready var eukaryote_button: Button = %EukaryoteButton
@onready var type_label: Label = %TypeLabel
@onready var description_label: Label = %DescriptionLabel
@onready var size_slider: HSlider = %SizeSlider
@onready var size_label: Label = %SizeLabel
@onready var cell_preview: Node2D = %CellPreview
@onready var confirm_button: Button = %ConfirmButton

var selected_type: String = "eukaryote"
var cell_size: float = 100.0

func _ready() -> void:
	prokaryote_button.pressed.connect(_select_prokaryote)
	eukaryote_button.pressed.connect(_select_eukaryote)
	size_slider.value_changed.connect(_update_cell_size)
	confirm_button.pressed.connect(_confirm_cell)
	_update_type_info()
	_update_cell_size(size_slider.value)

func _select_prokaryote() -> void:
	selected_type = "prokaryote"
	_update_type_info()
	_update_preview()

func _select_eukaryote() -> void:
	selected_type = "eukaryote"
	_update_type_info()
	_update_preview()

func _update_type_info() -> void:
	if selected_type == "prokaryote":
		type_label.text = "PROCARIOTE"
		description_label.text = "Estrutura mais simples, sem núcleo delimitado."
	else:
		type_label.text = "EUCARIOTE"
		description_label.text = "Estrutura mais complexa, com núcleo delimitado."

func _update_cell_size(value: float) -> void:
	cell_size = value
	size_label.text = "Tamanho: %.0f" % cell_size
	_update_preview()

func _update_preview() -> void:
	if cell_preview == null:
		return
	if cell_preview.has_method("configure"):
		cell_preview.configure(selected_type, cell_size)

func _confirm_cell() -> void:
	print("Célula criada: ", selected_type, " | tamanho: ", cell_size)
