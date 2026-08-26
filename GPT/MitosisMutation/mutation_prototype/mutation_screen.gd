extends Control

## Experimental mutation-screen prototype.
## The DNA is drawn as pixel-style geometry rather than imported artwork.
## This is intentionally self-contained so it can later be replaced by proper UI scenes.

const VIRTUAL_SIZE := Vector2(160, 90)
const PIXEL := 2.0
const DNA_CENTER := Vector2(80, 43)
const PAIR_COUNT := 10
const PAIR_SPACING := 6.0
const HELIX_RADIUS := 16.0

var selected_gene := -1
var mutated_genes: Dictionary = {}
var mutation_cost := 5
var resources := 37

var genes := [
	{"name": "Resistência", "effect": "HP +15% / Velocidade -5%"},
	{"name": "Mobilidade", "effect": "Velocidade +15% / HP -5%"},
	{"name": "Metabolismo", "effect": "Coleta +15% / HP -5%"},
	{"name": "Crescimento", "effect": "Tamanho +10% / Velocidade -5%"}
]

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse := get_local_mouse_position()
		var gene := _gene_at_position(mouse)
		if gene >= 0:
			selected_gene = gene
			queue_redraw()
		elif selected_gene >= 0 and resources >= mutation_cost:
			mutated_genes[selected_gene] = true
			resources -= mutation_cost
			queue_redraw()

func _draw() -> void:
	# Pixel-art-like presentation: all geometry is aligned to a coarse grid.
	draw_rect(Rect2(Vector2.ZERO, size), Color("10131a"))
	_draw_panel(Rect2(7, 5, size.x - 14, size.y - 10))
	_draw_title()
	_draw_dna()
	_draw_gene_panel()
	_draw_footer()

func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, Color("171c27"))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("566078"), 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color("566078"), 2.0)

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(18, 18), "MUTACAO GENETICA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("e9edf7"))
	draw_string(ThemeDB.fallback_font, Vector2(18, 27), "Altere uma regiao do material genetico", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("929caf"))

func _draw_dna() -> void:
	var top := Vector2(DNA_CENTER.x, 30)
	for i in range(PAIR_COUNT):
		var y := top.y + i * PAIR_SPACING
		var phase := float(i) * 0.65
		var left_x := DNA_CENTER.x - HELIX_RADIUS + sin(phase) * 7.0
		var right_x := DNA_CENTER.x + HELIX_RADIUS + sin(phase + PI) * 7.0
		var left := Vector2(left_x, y)
		var right := Vector2(right_x, y)
		var gene := i % genes.size()
		var altered := mutated_genes.has(gene)
		var pair_color := Color("f0c75e") if altered else Color("8fd3ff")
		var bond_color := Color("e7f1ff") if i == selected_gene else Color("566078")

		# Base nodes.
		draw_rect(Rect2(left - Vector2(2, 2), Vector2(4, 4)), pair_color)
		draw_rect(Rect2(right - Vector2(2, 2), Vector2(4, 4)), pair_color)

		# Base-pair connection, representing the editable segment.
		var a := Vector2(left.x + 2, y)
		var b := Vector2(right.x - 2, y)
		draw_line(a, b, bond_color, 2.0)

		# Sugar-phosphate backbone indication.
		if i < PAIR_COUNT - 1:
			var next_y := y + PAIR_SPACING
			var next_phase := float(i + 1) * 0.65
			var next_left := Vector2(DNA_CENTER.x - HELIX_RADIUS + sin(next_phase) * 7.0, next_y)
			var next_right := Vector2(DNA_CENTER.x + HELIX_RADIUS + sin(next_phase + PI) * 7.0, next_y)
			draw_line(left, next_left, Color("7a8295"), 2.0)
			draw_line(right, next_right, Color("7a8295"), 2.0)

	# Selected segment highlight.
	if selected_gene >= 0:
		var sy := top.y + selected_gene * PAIR_SPACING
		draw_rect(Rect2(DNA_CENTER.x - 32, sy - 3, 64, 6), Color(0.4, 0.8, 1.0, 0.12))

func _draw_gene_panel() -> void:
	var x := 112.0
	var y := 31.0
	draw_string(ThemeDB.fallback_font, Vector2(x, 26), "GENES", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("dfe6f5"))
	for i in range(genes.size()):
		var gene: Dictionary = genes[i]
		var rect := Rect2(x, y + i * 12, 39, 9)
		var active := i == selected_gene
		draw_rect(rect, Color("263244") if not active else Color("36536b"))
		draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(3, 5)), Color("f0c75e") if mutated_genes.has(i) else Color("8fd3ff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 7), str(gene["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("ffffff"))

	if selected_gene >= 0:
		var gene: Dictionary = genes[selected_gene]
		draw_string(ThemeDB.fallback_font, Vector2(x, 82), str(gene["effect"]), HORIZONTAL_ALIGNMENT_LEFT, 42, 4, Color("c2cada"))

func _draw_footer() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(12, size.y - 12), "RECURSOS: %02d" % resources, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("dfe6f5"))
	var button := Rect2(size.x - 66, size.y - 21, 54, 12)
	draw_rect(button, Color("2d6a56") if selected_gene >= 0 and resources >= mutation_cost else Color("303643"))
	draw_string(ThemeDB.fallback_font, button.position + Vector2(7, 8), "MUTAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("ffffff"))
	draw_string(ThemeDB.fallback_font, Vector2(12, size.y - 23), "Clique num segmento do DNA para seleciona-lo.", HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color("7f899d"))

func _gene_at_position(mouse: Vector2) -> int:
	var top_y := 30.0
	for i in range(PAIR_COUNT):
		var y := top_y + i * PAIR_SPACING
		if abs(mouse.y - y) <= 3.0 and abs(mouse.x - DNA_CENTER.x) <= HELIX_RADIUS + 10.0:
			return i % genes.size()
	return -1
