extends CanvasLayer

## In-simulation pause menu with the basic actions expected by a desktop game.
class_name SimulationPauseMenu

const MAIN_MENU_SCENE := "res://GPT/UI/MainMenu.tscn"

var _overlay: ColorRect
var _panel: PanelContainer
var _status_label: Label
var _saved_time_scale: float = 1.0
var _menu_visible: bool = false
var _closing_for_scene_change: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_create_ui()
	_set_menu_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _create_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.025, 0.04, 0.72)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -220.0
	_panel.offset_top = -260.0
	_panel.offset_right = 220.0
	_panel.offset_bottom = 260.0
	_overlay.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = "SIMULAÇÃO PAUSADA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)

	_status_label = Label.new()
	_status_label.text = "A simulação está congelada."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status_label)

	var separator := HSeparator.new()
	column.add_child(separator)

	_add_menu_button(column, "Retomar", _resume)
	_add_menu_button(column, "Reiniciar simulação", _restart_simulation)
	_add_menu_button(column, "Nova configuração", _open_setup)
	_add_menu_button(column, "Menu principal", _open_main_menu)
	_add_menu_button(column, "Sair", _quit_game)

	var hint := Label.new()
	hint.text = "ESC — fechar / abrir pausa"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)

func _add_menu_button(parent: VBoxContainer, text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _toggle_menu() -> void:
	_set_menu_visible(not _menu_visible)

func _set_menu_visible(enabled: bool) -> void:
	_menu_visible = enabled
	if _overlay == null:
		return

	_overlay.visible = enabled
	if enabled:
		_saved_time_scale = maxf(Engine.time_scale, 0.0)
		get_tree().paused = true
		_status_label.text = "A simulação está congelada. Velocidade anterior: %s×" % _format_speed(_saved_time_scale)
	else:
		get_tree().paused = false
		Engine.time_scale = _saved_time_scale if _saved_time_scale > 0.0 else 1.0

func _resume() -> void:
	_set_menu_visible(false)

func _restart_simulation() -> void:
	_closing_for_scene_change = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	var scene := get_tree().current_scene
	if scene != null and not scene.scene_file_path.is_empty():
		get_tree().change_scene_to_file(scene.scene_file_path)
	else:
		get_tree().reload_current_scene()

func _open_setup() -> void:
	_closing_for_scene_change = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://GPT/UI/SimulationSetup.tscn")

func _open_main_menu() -> void:
	_closing_for_scene_change = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _quit_game() -> void:
	_closing_for_scene_change = true
	get_tree().paused = false
	get_tree().quit()

func _format_speed(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return "%d" % int(round(value))
	return "%.2f" % value
