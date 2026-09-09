extends CanvasLayer

## ALIVE CELLS — END CREDITS
##
## This script is intentionally self-contained and modular.
##
## EDITING GUIDE:
## 1. Change CREDIT_BLOCKS to edit the visible text, order, font sizes,
##    and spacing. No other section needs to be touched for text changes.
## 2. Change the constants below to change audio or scroll timing.
## 3. The overlay is global through the AliveCellsCredits autoload.
## 4. F10 starts/stops the credits from any scene.

# ============================================================
# CONFIGURATION — SAFE TO EDIT
# ============================================================
const MUSIC_PATH := "res://assets/audio/its.mp3"
const SCROLL_DURATION := 50.0
const START_DELAY := 1.5
const START_OFFSET_MULTIPLIER := 1.0
const END_OFFSET_MULTIPLIER := 1.0

# ============================================================
# CREDIT CONTENT — EDIT THIS SECTION ONLY FOR TEXT CHANGES
# ============================================================
# Each block supports:
#   text        -> visible text (use \n for line breaks)
#   size        -> font size in pixels
#   space_after -> vertical spacing after this block
const CREDIT_BLOCKS: Array[Dictionary] = [
	{"text": "ALIVE CELLS", "size": 46, "space_after": 18.0},
	{"text": "Um projeto de pesquisa, simulação e desenvolvimento experimental", "size": 18, "space_after": 34.0},

	{"text": "DIREÇÃO DE JOGO", "size": 25, "space_after": 4.0},
	{"text": "ISAQUE", "size": 22, "space_after": 22.0},

	{"text": "CONCEPÇÃO E DESENVOLVIMENTO", "size": 25, "space_after": 4.0},
	{"text": "ISAQUE + UM CARA QUE NÃO VOU CITAR O NOME", "size": 22, "space_after": 22.0},

	{"text": "PROGRAMAÇÃO", "size": 25, "space_after": 4.0},
	{"text": "CHATGPT", "size": 22, "space_after": 22.0},

	{"text": "ARTE E IDENTIDADE VISUAL", "size": 25, "space_after": 4.0},
	{"text": "IS-EQUIPE ALIVE CELLS", "size": 22, "space_after": 22.0},

	{"text": "PESQUISA E CONTEÚDO CIENTÍFICO", "size": 25, "space_after": 4.0},
	{"text": "EQUIPE ALIVE CELLS", "size": 22, "space_after": 22.0},

	{"text": "APRESENTAÇÃO E DOCUMENTAÇÃO", "size": 25, "space_after": 4.0},
	{"text": "EQUIPE ALIVE CELLS", "size": 22, "space_after": 34.0},

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
	{"text": "Aos que programaram (CHATGPT).\nAos que desenharam (MATEMÁTICA).\nAos que pesquisaram.\nAos que testaram.\nAos que apresentaram.", "size": 19, "space_after": 20.0},
	{"text": "E aos que, em algum momento,\nperguntaram:\n\n\"Tá, mas e aí?\"", "size": 21, "space_after": 38.0},

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

# ============================================================
# RUNTIME STATE — DO NOT EDIT FOR NORMAL CONTENT CHANGES
# ============================================================
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
	set_process_input(true)

func _input(event: InputEvent) -> void:
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
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(background)

	_credits_container = VBoxContainer.new()
	_credits_container.position = Vector2.ZERO
	_credits_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credits_container.add_theme_constant_override("separation", 0)
	_overlay.add_child(_credits_container)

	var viewport_size := get_viewport().get_visible_rect().size
	for block in CREDIT_BLOCKS:
		_add_credit_block(block, viewport_size.x)

func _add_credit_block(block: Dictionary, width: float) -> void:
	var label := Label.new()
	label.text = str(block.get("text", ""))
	label.custom_minimum_size = Vector2(width, 48.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", int(block.get("size", 20)))
	_credits_container.add_child(label)
	_add_spacer(float(block.get("space_after", 0.0)))

func _add_spacer(height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	_credits_container.add_child(spacer)

func _build_music() -> void:
	_music = AudioStreamPlayer.new()
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.bus = &"Master"
	_music.volume_db = 0.0
	add_child(_music)

	# The file is part of the project and is intentionally preloaded so
	# a wrong path becomes an immediate Godot error instead of silent failure.
	_music.stream = preload("res://assets/audio/its.mp3")

func toggle_credits() -> void:
	if _visible:
		_stop_credits()
	else:
		_start_credits()

func _start_credits() -> void:
	_visible = true
	_overlay.visible = true

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null

	# Every activation starts from exactly the same state.
	_music.stop()
	_credits_container.position = Vector2.ZERO

	await get_tree().process_frame

	var viewport_size := get_viewport().get_visible_rect().size
	var total_height := _credits_container.get_combined_minimum_size().y
	var start_y := viewport_size.y * START_OFFSET_MULTIPLIER
	var end_y := -total_height * END_OFFSET_MULTIPLIER
	_credits_container.position = Vector2(0.0, start_y)

	_music.play(0.0)

	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_LINEAR)
	_scroll_tween.set_ease(Tween.EASE_IN_OUT)
	_scroll_tween.tween_interval(START_DELAY)
	_scroll_tween.tween_property(_credits_container, "position:y", end_y, SCROLL_DURATION)

func _stop_credits() -> void:
	_visible = false
	_overlay.visible = false

	if _scroll_tween and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null

	_music.stop()
	_credits_container.position = Vector2.ZERO
