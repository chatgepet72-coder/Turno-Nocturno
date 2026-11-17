class_name TransicionEscalera
extends CanvasLayer
## Transición al estilo de las puertas de los primeros Resident Evil: todo en negro y,
## en el centro, solo la escalera bajando (o subiendo) peldaño por peldaño, con pasos sobre metal.

const PASOS: int = 9
const PELDANO: float = 30.0   # distancia entre peldaños en la imagen de la escalera

var _escalera: TextureRect
var _audio: AudioStreamPlayer
var _pasos_metal: Array[AudioStream] = []


func _ready() -> void:
	layer = 21
	visible = false
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.size = Vector2(640, 360)
	add_child(negro)
	_escalera = TextureRect.new()
	_escalera.texture = load("res://assets/sprites/ui/escalera_transicion.png") as Texture2D
	_escalera.position.x = (640.0 - _escalera.texture.get_width()) / 2.0
	add_child(_escalera)
	var vineta := TextureRect.new()   # oscurece las orillas: solo se ve lo que alumbra la linterna
	vineta.texture = load("res://assets/sprites/ui/vineta.png") as Texture2D
	add_child(vineta)
	for i in range(1, 4):
		_pasos_metal.append(load("res://assets/audio/efectos/paso_metal_%d.wav" % i) as AudioStream)
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -6.0
	add_child(_audio)


## bajando = true: la escalera sube en pantalla (Lalo baja). false: al revés.
func reproducir(bajando: bool) -> void:
	var alto: float = _escalera.texture.get_height() / 3.0
	var direccion: float = -1.0 if bajando else 1.0
	_escalera.position.y = -alto * (0.5 if bajando else 1.25)
	_escalera.modulate.a = 0.0
	visible = true
	await _tween(_escalera, "modulate:a", 1.0, 0.5)
	for i in PASOS:
		var t := create_tween()
		t.tween_property(_escalera, "position:y", _escalera.position.y + direccion * PELDANO, 0.22) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		sonar_paso()
		await t.finished
		await get_tree().create_timer(0.12).timeout
	await _tween(_escalera, "modulate:a", 0.0, 0.5)
	visible = false


func sonar_paso() -> void:
	_audio.stream = _pasos_metal.pick_random()
	_audio.pitch_scale = randf_range(0.9, 1.1)
	_audio.play()


func _tween(nodo: Object, propiedad: String, valor: Variant, duracion: float) -> void:
	var t := create_tween()
	t.tween_property(nodo, propiedad, valor, duracion)
	await t.finished
