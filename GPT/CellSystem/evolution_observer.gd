extends Node

## Scientific observation mode for the CellSystem laboratory.
## F5 toggles the overlay and makes the camera follow a representative of
## the currently dominant living species.
class_name EvolutionObserver

const TOGGLE_KEY: Key = KEY_F5
const UPDATE_INTERVAL: float = 0.50
const HISTORY_LIMIT: int = 10
const TRACKED_GENES: Array[String] = ["health", "speed", "damage", "regeneration_rate", "mitosis_cost"]
const SIMULATION_CONFIG_PATH := "/root/SimulationConfig"
const DEATH_LOG_PATH := "/root/SimulationDeathLog"

var cell_manager: Node
var simulation_camera: Camera2D
var _canvas: CanvasLayer
var _panel: PanelContainer
var _content: VBoxContainer
var _status_label: Label
var _dominant_label: Label
var _genes_label: Label
var _history_label: Label
var _deaths_label: Label
var _close_button: Button
var _active: bool = false
var _timer: float = 0.0
var _history: Array[Dictionary] = []
var _last_death_serial: int = 0
var _death_toast: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_nodes()
	_create_ui()
	_set_active(false)

func _process(delta: float) -> void:
	if not _active:
		_update_death_toast(delta)
		return

	_timer -= delta
	if _timer > 0.0:
		_update_death_toast(delta)
		return
	_timer = UPDATE_INTERVAL
	_update_observation()
	_update_death_toast(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == TOGGLE_KEY:
		_set_active(not _active)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_ESCAPE and _active:
		_set_active(false)
		get_viewport().set_input_as_handled()

func _resolve_nodes() -> void:
	cell_manager = get_tree().get_first_node_in_group("CellManagers")
	simulation_camera = get_tree().get_first_node_in_group("SimulationCameras") as Camera2D

func _create_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "EvolutionObserverLayer"
	_canvas.layer = 42
	add_child(_canvas)

	_panel = PanelContainer.new()
	_panel.name = "EvolutionObserverPanel"
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_left = 24.0
	_panel.offset_top = 24.0
	_panel.offset_right = -24.0
	_panel.offset_bottom = 430.0
	_panel.visible = false
	_canvas.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	margin.add_child(_content)

	var header := HBoxContainer.new()
	_content.add_child(header)

	var title := Label.new()
	title.text = "CÂMERA DA SELEÇÃO NATURAL"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_button = Button.new()
	_close_button.text = "Sair [F5]"
	_close_button.pressed.connect(func(): _set_active(false))
	header.add_child(_close_button)

	_status_label = Label.new()
	_status_label.text = "Observação desativada"
	_content.add_child(_status_label)

	_dominant_label = Label.new()
	_content.add_child(_dominant_label)

	_genes_label = Label.new()
	_genes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_genes_label)

	_history_label = Label.new()
	_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_history_label)

	_deaths_label = Label.new()
	_deaths_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_deaths_label)

	_death_toast = Label.new()
	_death_toast.position = Vector2(28.0, 448.0)
	_death_toast.add_theme_font_size_override("font_size", 16)
	_death_toast.visible = false
	_canvas.add_child(_death_toast)

func _set_active(enabled: bool) -> void:
	_active = enabled
	if _panel != null:
		_panel.visible = enabled

	if enabled:
		_timer = 0.0
		_history.clear()
		_status_label.text = "Observando a espécie dominante e seguindo uma célula representativa."
		_update_observation()
	else:
		_status_label.text = "Observação desativada"
		if simulation_camera != null and is_instance_valid(simulation_camera) and simulation_camera.has_method("clear_selected_target"):
			simulation_camera.clear_selected_target()

func _update_observation() -> void:
	if cell_manager == null or not is_instance_valid(cell_manager):
		_resolve_nodes()
		if cell_manager == null:
			return

	var counts: Dictionary = {}
	var living_cells: Array[Node] = []
	for cell in cell_manager.registered_cells:
		if not is_instance_valid(cell):
			continue
		var data: Node = cell.get("cell_data") as Node
		if data == null or not is_instance_valid(data) or not bool(data.get("alive")):
			continue
		var species: String = get_cell_species(cell)
		if species.is_empty() or species == "default":
			continue
		counts[species] = int(counts.get(species, 0)) + 1
		living_cells.append(cell)

	if counts.is_empty():
		_dominant_label.text = "População viva: 0\nNenhuma espécie viva no momento."
		_genes_label.text = ""
		_history_label.text = ""
		return

	var dominant_species: String = ""
	var dominant_count: int = 0
	for species_key in counts.keys():
		var species_count: int = int(counts[species_key])
		if species_count > dominant_count:
			dominant_count = species_count
			dominant_species = String(species_key)

	var representative: Node = null
	var generation_peak: int = 0
	for cell in living_cells:
		if get_cell_species(cell) != dominant_species:
			continue
		var generation: int = get_cell_generation(cell)
		generation_peak = maxi(generation_peak, generation)
		if representative == null:
			representative = cell

	if representative != null and simulation_camera != null and is_instance_valid(simulation_camera) and simulation_camera.has_method("set_follow_target"):
		simulation_camera.set_follow_target(representative as Node2D)

	var percentages: float = 100.0 * float(dominant_count) / float(maxi(living_cells.size(), 1))
	var simulation_time: float = float(cell_manager.get("simulation_time")) if cell_manager != null else 0.0
	_dominant_label.text = "Dominante: %s — %d/%d células vivas (%.1f%%)\nGeração máxima observada: %d\nTempo de simulação: %.1fs" % [dominant_species, dominant_count, living_cells.size(), percentages, generation_peak, simulation_time]

	var averages: Dictionary = {}
	for gene_name in TRACKED_GENES:
		var total: float = 0.0
		var samples: int = 0
		for cell in living_cells:
			if get_cell_species(cell) != dominant_species:
				continue
			var genetics: Node = cell.get("genetics") as Node
			if genetics == null or not is_instance_valid(genetics) or not genetics.has_method("get_gene"):
				continue
			total += float(genetics.get_gene(gene_name, 0.0))
			samples += 1
		if samples > 0:
			averages[gene_name] = total / float(samples)

	_genes_label.text = "Fenótipos médios da espécie dominante:\n" + _format_gene_averages(averages)

	_history.append({
		"time": simulation_time,
		"population": dominant_count,
		"generation": generation_peak,
		"species": dominant_species
	})
	while _history.size() > HISTORY_LIMIT:
		_history.pop_front()
	_history_label.text = "Linha do tempo:\n" + _format_history()
	_deaths_label.text = "Últimas mortes:\n" + _format_deaths()

func _format_gene_averages(values: Dictionary) -> String:
	if values.is_empty():
		return "Dados genéticos indisponíveis."
	var lines: Array[String] = []
	for gene_name in TRACKED_GENES:
		if not values.has(gene_name):
			continue
		lines.append("  %s: %.2f" % [gene_name, float(values[gene_name])])
	return "\n".join(lines)

func _format_history() -> String:
	if _history.is_empty():
		return "Sem amostras ainda."
	var lines: Array[String] = []
	for entry in _history:
		lines.append("  %.1fs  %s  pop=%d  gen=%d" % [float(entry["time"]), String(entry["species"]), int(entry["population"]), int(entry["generation"])])
	return "\n".join(lines)

func _format_deaths() -> String:
	var log: Node = get_node_or_null(DEATH_LOG_PATH)
	if log == null or not is_instance_valid(log) or not log.has_method("get_recent_events"):
		return "Histórico indisponível."
	var events: Array = log.get_recent_events()
	if events.is_empty():
		return "Nenhuma morte registrada."
	var start: int = maxi(events.size() - 4, 0)
	var lines: Array[String] = []
	for index in range(start, events.size()):
		var event: Dictionary = events[index]
		lines.append("  %s — %s [%s]" % [String(event.get("cell_id", "cell")), String(event.get("reason", "Desconhecida")), String(event.get("species_id", "unknown"))])
	return "\n".join(lines)

func _update_death_toast(_delta: float) -> void:
	var log: Node = get_node_or_null(DEATH_LOG_PATH)
	if log == null or not is_instance_valid(log) or not log.has_method("get_latest"):
		return
	var latest: Dictionary = log.get_latest()
	if latest.is_empty():
		return
	var serial: int = int(latest.get("serial", 0))
	if serial == _last_death_serial:
		return
	_last_death_serial = serial
	if _death_toast != null:
		_death_toast.text = "Morte: %s — %s" % [String(latest.get("cell_id", "cell")), String(latest.get("reason", "Desconhecida"))]
		_death_toast.visible = true
		var timer := get_tree().create_timer(2.5)
		timer.timeout.connect(func():
			if _death_toast != null and is_instance_valid(_death_toast):
				_death_toast.visible = false
		)

func get_cell_species(cell: Node) -> String:
	if cell == null or not is_instance_valid(cell):
		return ""
	if cell.has_method("get_species_id"):
		return String(cell.get_species_id()).strip_edges()
	return String(cell.get("species_id")).strip_edges()

func get_cell_generation(cell: Node) -> int:
	if cell == null or not is_instance_valid(cell):
		return 0
	var genetics: Node = cell.get("genetics") as Node
	if genetics == null or not is_instance_valid(genetics):
		return 0
	return int(genetics.get("generation"))
