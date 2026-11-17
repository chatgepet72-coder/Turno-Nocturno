class_name TransicionPuerta
extends CanvasLayer
## Transición al estilo de los primeros Resident Evil: todo en negro, la puerta se abre lento
## rechinando, y se oyen los pasos de Lalo al entrar. El cambio de cuarto ocurre mientras todo está negro.

const CUADROS: int = 4

var _negro: ColorRect
var _puerta: TextureRect
var _texturas: Array[Texture2D] = []
var _audio: AudioStreamPlayer
var _pasos: Array[AudioStream] = []


func _ready() -> void:
	layer = 22
	visible = false
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.size = Vector2(640, 360)
	add_child(_negro)
	for i in range(1, CUADROS + 1):
		_texturas.append(load("res://assets/sprites/ui/puerta_%d.png" % i) as Texture2D)
	_puerta = TextureRect.new()
	_puerta.texture = _texturas[0]
	_puerta.position = (Vector2(640, 360) - _texturas[0].get_size()) / 2.0
	add_child(_puerta)
	var vineta := TextureRect.new()   # oscurece las orillas
	vineta.texture = load("res://assets/sprites/ui/vineta.png") as Texture2D
	add_child(vineta)
	for i in range(4):
		_pasos.append(load("res://assets/audio/pasos/footstep_concrete_00%d.ogg" % i) as AudioStream)
	_audio = AudioStreamPlayer.new()
	add_child(_audio)


## Pone la pantalla en negro, abre la puerta, llama a `cambiar` (para mover a Lalo) y vuelve a mostrar el juego.
func cruzar(cambiar: Callable) -> void:
	visible = true
	_negro.modulate.a = 0.0
	_puerta.modulate.a = 0.0
	_puerta.texture = _texturas[0]
	await _tween(_negro, "modulate:a", 1.0, 0.35)
	await _tween(_puerta, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.3).timeout
	_sonar(load("res://assets/audio/efectos/puerta_rechina.wav") as AudioStream, 0.95)
	for i in range(1, CUADROS):   # se abre lento, cuadro por cuadro
		await get_tree().create_timer(0.38).timeout
		_puerta.texture = _texturas[i]
	await get_tree().create_timer(0.45).timeout
	await _tween(_puerta, "modulate:a", 0.0, 0.35)
	cambiar.call()
	for i in range(3):   # los pasos de Lalo al entrar, todavía a oscuras
		_sonar(_pasos.pick_random(), randf_range(0.9, 1.05))
		await get_tree().create_timer(0.32).timeout
	await _tween(_negro, "modulate:a", 0.0, 0.5)
	visible = false


## Para puertas que llevan a otra escena: toda la transición se reproduce antes de cambiar,
## porque al cambiar de escena esta transición deja de existir. La escena nueva llama a aparecer().
func cruzar_a_escena(escena: String, punto: String) -> void:
	visible = true
	_negro.modulate.a = 0.0
	_puerta.modulate.a = 0.0
	_puerta.texture = _texturas[0]
	await _tween(_negro, "modulate:a", 1.0, 0.35)
	await _tween(_puerta, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.3).timeout
	_sonar(load("res://assets/audio/efectos/puerta_rechina.wav") as AudioStream, 0.95)
	for i in range(1, CUADROS):
		await get_tree().create_timer(0.38).timeout
		_puerta.texture = _texturas[i]
	await get_tree().create_timer(0.45).timeout
	await _tween(_puerta, "modulate:a", 0.0, 0.35)
	for i in range(3):
		_sonar(_pasos.pick_random(), randf_range(0.9, 1.05))
		await get_tree().create_timer(0.32).timeout
	GameState.ir_a(escena, punto)


## Al cargar una escena: empieza en negro y se aclara.
func aparecer() -> void:
	visible = true
	_puerta.modulate.a = 0.0
	_negro.modulate.a = 1.0
	await get_tree().create_timer(0.2).timeout
	await _tween(_negro, "modulate:a", 0.0, 0.6)
	visible = false


func _sonar(stream: AudioStream, tono: float) -> void:
	_audio.stream = stream
	_audio.pitch_scale = tono
	_audio.play()


func _tween(nodo: Object, propiedad: String, valor: Variant, duracion: float) -> void:
	var t := create_tween()
	t.tween_property(nodo, propiedad, valor, duracion)
	await t.finished
