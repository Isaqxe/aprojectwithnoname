extends CanvasLayer

## Alive Cells end credits.
##
## CONTENT EDITING:
## All visible credits text lives in CREDIT_BLOCKS below.
## Each block can be edited, reordered, added, or removed without touching the UI code.
##
## TRIGGER:
## F10 toggles the credits screen from any scene.

const MUSIC_PATH := "res://Assets/its.mp3"
const SCROLL_DURATION := 34.0
const START_DELAY := 1.5

# ============================================================
# CREDIT CONTENT — EDIT THIS SECTION
# ============================================================
const CREDIT_BLOCKS: Array[Dictionary] = [
	{"text": "ALIVE CELLS", "size": 46, "space_after": 18.0},
	{"text": "Um projeto de pesquisa, simulação e desenvolvimento experimental", "size": 18, "space_after": 34.0},

	{"text": "DIREÇÃO DE JOGO", "size": 25, "space_after": 4.0},
	{"text": "DOM", "size": 22, "space_after": 22.0},

	{"text": "CONCEPÇÃO E DESENVOLVIMENTO", "size": 25, "space_after": 4.0},
	{"text": "Isaque", "size": 22, "space_after": 22.0},

	{"text": "PROGRAMAÇÃO", "size": 25, "space_after": 4.0},
	{"text": "GPT", "size": 22, "space_after": 22.0},

	{"text": "ARTE E IDENTIDADE VISUAL", "size": 25, "space_after": 4.0},
	{"text": "Equipe Alive Cells", "size": 22, "space_after": 22.0},

	{"text": "PESQUISA E CONTEÚDO CIENTÍFICO", "size": 25, "space_after": 4.0},
	{"text": "Equipe Alive Cells", "size": 22, "space_after": 22.0},

	{"text": "APRESENTAÇÃO E DOCUMENTAÇÃO", "size": 25, "space_after": 4.0},
	{"text": "Equipe Alive Cells", "size": 22, "space_after": 34.0},

	{"text": "SISTEMAS", "size": 32, "space_after": 12.0},
	{"text": "Simulação de População", "size": 19, "space_after": 3.0},
	{"text": "Genética e Hereditariedade", "size": 19, "space_after": 3.0},
	{"text": "Genes e Alelos", "size": 19, "space_after": 3.0},
	{"text": "Mutações", "size": 19, "space_after": 3.0},
	{"text": "Herança de Características", "size": 19, "space_after": 3.0},
	{"text": "Seleção Natural", "size": 19, "space_after": 3.0},
	{"text": "Adaptação ao Ambiente", "size": 19, "space_after": 3.0},
	{"text": "Recursos e Sobrevivência", "size": 19, "space_after": 3.0},
	{"text": "Mitose", "size": 19, "space_after": 3.0},
	{"text": "Sistema de Evolução", "size": 19, "space_after": 3.0},
	{"text": "Inspeção Genética", "size": 19, "space_after": 3.0},
	{"text": "Monitoramento da População", "size": 19, "space_after": 32.0},

	{"text": "TECNOLOGIA", "size": 32, "space_after": 12.0},
	{"text": "Desenvolvido em Godot Engine", "size": 19, "space_after": 8.0},
	{"text": "Projeto criado para a Feira de Ciências", "size": 19, "space_after": 8.0},
	{"text": "Tema: Genética e Hereditariedade", "size": 19, "space_after": 32.0},

	{"text": "UM AGRADECIMENTO ESPECIAL", "size": 30, "space_after": 18.0},
	{"text": "À equipe que tornou este projeto possível.", "size": 20, "space_after": 15.0},
	{"text": "Aos que programaram.\nAos que desenharam.\nAos que pesquisaram.\nAos que testaram.\nAos que apresentaram.", "size": 19, "space_after": 20.0},
	{"text": "E aos que, em algum momento,\nperguntaram:\n\n\"Isso ainda está funcionando?\"", "size": 21, "space_after": 38.0},

	{"text": "DESENVOLVIDO DURANTE 2026", "size": 30, "space_after": 18.0},
	{"text": "Após inúmeras ideias,\nmudanças de escopo,\nbugs,\nrefatorações,\ntestes\ne algumas decisões questionáveis.", "size": 19, "space_after": 42.0},

	{"text": "E, POR FIM...", "size": 30, "space_after": 20.0},
	{"text": "Ao pequeno organismo que começou como um protótipo\ne acabou virando uma simulação inteira.", "size": 20, "space_after": 18.0},
	{"text": "Você sobreviveu.\n\nVocê evoluiu.\n\nVocê sofreu alguns bugs.\n\nMas chegou até aqui.", "size": 22, "space_after": 52.0},

	{"text": "OBRIGADO POR JOGAR", "size": 34, "space_after": 18.0},
	{"text": "ALIVE CELLS", "size": 42, "space_after": 48.0},
	{"text": "FIM", "size": 48, "space_after": 8.0},
	{"text": "2026", "size": 18, "space_after": 0.0}
]

var _overlay: Control
var _credits_container: VBoxContainer
var _music: AudioStreamPlayer
var _visible := false
var _scroll_tween: Tween

func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_build_music()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		toggle_credits()
		get_viewport().set_input_as_handled()

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	_overlay.add_child(background)

	var viewport_height := get_viewport().get_visible_rect().size.y

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(scroll)

	_credits_container = VBoxContainer.new()
	_credits_container.custom_minimum_size = Vector2(0.0, viewport_height * 2.7)
	_credits_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_credits_container.add_theme_constant_override("separation", 0)
	scroll.add_child(_credits_container)

	# Large blank area places the first real credit below the screen edge.
	_add_spacer(viewport_height * 1.05)
	for block in CREDIT_BLOCKS:
		_add_credit_block(block)
	_add_spacer(viewport_height * 0.85)

func _add_credit_block(block: Dictionary) -> void:
	var label := Label.new()
	label.text = str(block.get("text", ""))
	label.custom_minimum_size = Vector2(0.0, 48.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", int(block.get("size", 20)))
	_credits_container.add_child(label)
	_add_spacer(float(block.get("space_after", 0.0)))

func _add_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	_credits_container.add_child(spacer)

func _build_music() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = &"Master"
	add_child(_music)
	if ResourceLoader.exists(MUSIC_PATH):
		var stream = load(MUSIC_PATH)
		if stream is AudioStream:
			_music.stream = stream
	_music.finished.connect(_on_music_finished)

func toggle_credits() -> void:
	_visible = not _visible
	_overlay.visible = _visible

	if _visible:
		_start_credits()
	else:
		_stop_credits()

func _start_credits() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_credits_container.position.y = 0.0
	await get_tree().process_frame
	var viewport_height := get_viewport().get_visible_rect().size.y
	var total_height := _credits_container.get_minimum_size().y
	var target_y := -max(0.0, total_height - viewport_height)
	_credits_container.position.y = viewport_height * 1.05

	if _music.stream:
		_music.play()

	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_LINEAR)
	_scroll_tween.set_ease(Tween.EASE_IN_OUT)
	_scroll_tween.tween_interval(START_DELAY)
	_scroll_tween.tween_property(_credits_container, "position:y", target_y, SCROLL_DURATION)

func _stop_credits() -> void:
	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_music.stop()

func _on_music_finished() -> void:
	# Keep the credits visible after the song ends.
	if _visible:
		return
