extends CanvasLayer

## Global end-credits overlay. It exists on every scene through an autoload.
## Trigger: the bottom-right button or F10.

const MUSIC_PATH := "res://Assets/Audio/its_been_a_long_long_time.ogg"

var _panel: Control
var _scroll: ScrollContainer
var _credits_column: VBoxContainer
var _music: AudioStreamPlayer
var _button: Button
var _credits_visible := false

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_trigger_button()
	_build_overlay()
	_build_music()
	set_process_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		toggle_credits()

func _build_trigger_button() -> void:
	_button = Button.new()
	_button.text = "CRÉDITOS"
	_button.tooltip_text = "Encerrar o Alive Cells"
	_button.custom_minimum_size = Vector2(130, 42)
	_button.anchor_left = 1.0
	_button.anchor_top = 1.0
	_button.anchor_right = 1.0
	_button.anchor_bottom = 1.0
	_button.offset_left = -150.0
	_button.offset_top = -58.0
	_button.offset_right = -20.0
	_button.offset_bottom = -16.0
	_button.z_index = 5
	_button.pressed.connect(toggle_credits)
	add_child(_button)

func _build_overlay() -> void:
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	_panel.z_index = 10
	add_child(_panel)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.0, 0.0, 0.0, 1.0)
	_panel.add_child(background)

	var title := Label.new()
	title.text = "ALIVE CELLS"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-400, 70)
	title.size = Vector2(800, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "O ciclo chegou ao fim."
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-400, 150)
	subtitle.size = Vector2(800, 50)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	_panel.add_child(subtitle)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_CENTER)
	_scroll.position = Vector2(-500, -250)
	_scroll.size = Vector2(1000, 500)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(_scroll)

	_credits_column = VBoxContainer.new()
	_credits_column.custom_minimum_size = Vector2(1000, 900)
	_credits_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	_credits_column.add_theme_constant_override("separation", 18)
	_scroll.add_child(_credits_column)

	_add_credit("ALIVE CELLS", 36)
	_add_spacer(22)
	_add_credit("Direção de Jogo: DOM", 24)
	_add_credit("Programação e todo o trabalho pesado: GPT", 24)
	_add_credit("Conceito, desenvolvimento e supervisão: Isaque", 24)
	_add_credit("Pesquisa e conteúdo científico: Equipe Alive Cells", 20)
	_add_credit("Arte, interface e apresentação: Equipe Alive Cells", 20)
	_add_spacer(16)
	_add_credit("Genética • Hereditariedade • Mutação • Seleção Natural", 18)
	_add_credit("Construído em Godot", 18)
	_add_spacer(28)
	_add_credit("Obrigado por jogar.", 28)
	_add_credit("E obrigado por nos dar células para observar.", 20)
	_add_spacer(36)
	_add_credit("FIM", 46)
	_add_credit("2026", 18)

	var close_button := Button.new()
	close_button.text = "FECHAR"
	close_button.custom_minimum_size = Vector2(150, 45)
	close_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close_button.position = Vector2(-75, -65)
	close_button.pressed.connect(toggle_credits)
	_panel.add_child(close_button)

func _add_credit(text: String, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(1000, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	_credits_column.add_child(label)

func _add_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	_credits_column.add_child(spacer)

func _build_music() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	add_child(_music)

func toggle_credits() -> void:
	_credits_visible = not _credits_visible
	_panel.visible = _credits_visible
	_button.visible = not _credits_visible

	if _credits_visible:
		_scroll.scroll_vertical = 0
		_play_music()
		_start_scroll()
	else:
		_music.stop()

func _play_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var stream = load(MUSIC_PATH)
	if stream is AudioStream:
		_music.stream = stream
		_music.play()

func _start_scroll() -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = 0
	var max_scroll := max(0, _scroll.get_v_scroll_bar().max_value - _scroll.size.y)
	if max_scroll <= 0:
		return
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_scroll, "scroll_vertical", max_scroll, 28.0)
