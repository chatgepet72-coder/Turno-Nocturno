class_name Lalo
extends CharacterBody2D
## Lalo: movimiento desde arriba, animación en 4 direcciones, linterna que apunta al ratón y pasos.

const RUTA_CAMINAR: String = "res://assets/sprites/personajes/lalo/caminar/"
const DIRECCIONES: Array[String] = ["down", "left", "right", "up"]

@export var velocidad: float = 80.0
@export var velocidad_corriendo: float = 140.0
@export var aceleracion: float = 900.0
@export var freno: float = 1100.0

## Zonas de piso duro (caminos, estacionamiento, patio). Fuera de ellas los pasos suenan a pasto.
var superficies_duras: Array[Rect2] = []

var _sprite: AnimatedSprite2D
var _linterna: PointLight2D
var _direccion: String = "down"
var _distancia_paso: float = 0.0
var _pasos_duro: Array[AudioStream] = []
var _pasos_pasto: Array[AudioStream] = []
var _audio_pasos: AudioStreamPlayer2D
var _audio_linterna: AudioStreamPlayer2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_crear_sprite()
	_crear_colision()
	_crear_luces()
	_crear_audio()


func _physics_process(delta: float) -> void:
	var entrada: Vector2 = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	var maxima: float = velocidad_corriendo if Input.is_action_pressed("correr") else velocidad
	if entrada != Vector2.ZERO:
		velocity = velocity.move_toward(entrada * maxima, aceleracion * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, freno * delta)
	var antes: Vector2 = global_position
	move_and_slide()
	_animar(entrada)
	_sonar_pasos(global_position.distance_to(antes))


func _process(_delta: float) -> void:
	_linterna.rotation = (get_global_mouse_position() - _linterna.global_position).angle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("linterna"):
		_linterna.enabled = not _linterna.enabled
		_audio_linterna.play()


func poner_limites_camara(limites: Rect2i) -> void:
	var camara: Camera2D = $Camara
	camara.limit_left = limites.position.x
	camara.limit_top = limites.position.y
	camara.limit_right = limites.end.x
	camara.limit_bottom = limites.end.y


func _animar(entrada: Vector2) -> void:
	if entrada == Vector2.ZERO:
		_sprite.play("caminar_" + _direccion)
		_sprite.stop()
		_sprite.frame = 0
		return
	if absf(entrada.x) > absf(entrada.y):
		_direccion = "right" if entrada.x > 0.0 else "left"
	else:
		_direccion = "down" if entrada.y > 0.0 else "up"
	_sprite.speed_scale = 1.6 if Input.is_action_pressed("correr") else 1.0
	_sprite.play("caminar_" + _direccion)


func _sonar_pasos(recorrido: float) -> void:
	_distancia_paso += recorrido
	if _distancia_paso < 26.0:
		return
	_distancia_paso = 0.0
	var duro: bool = superficies_duras.any(func(r: Rect2) -> bool: return r.has_point(global_position))
	var lista: Array[AudioStream] = _pasos_duro if duro else _pasos_pasto
	_audio_pasos.stream = lista.pick_random()
	_audio_pasos.pitch_scale = randf_range(0.9, 1.1)
	_audio_pasos.play()


func _crear_sprite() -> void:
	var frames := SpriteFrames.new()
	for dir in DIRECCIONES:
		var nombre: String = "caminar_" + dir
		frames.add_animation(nombre)
		frames.set_animation_speed(nombre, 8.0)
		frames.set_animation_loop(nombre, true)
		for i in range(1, 5):
			frames.add_frame(nombre, load(RUTA_CAMINAR + "%s_%d.png" % [dir, i]) as Texture2D)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "caminar_down"
	var alto: float = frames.get_frame_texture("caminar_down", 0).get_size().y
	_sprite.offset = Vector2(0.0, -alto / 2.0)   # los pies quedan en el origen del nodo
	add_child(_sprite)


func _crear_colision() -> void:
	var forma := RectangleShape2D.new()
	forma.size = Vector2(20.0, 10.0)
	var colision := CollisionShape2D.new()
	colision.shape = forma
	colision.position = Vector2(0.0, -5.0)
	add_child(colision)


func _crear_luces() -> void:
	var aura := PointLight2D.new()   # luz tenue alrededor de Lalo para que siempre se le vea
	aura.texture = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	aura.texture_scale = 0.6
	aura.energy = 0.45
	aura.position = Vector2(0.0, -30.0)
	add_child(aura)

	_linterna = PointLight2D.new()
	_linterna.texture = load("res://assets/sprites/luces/cono_linterna.png") as Texture2D
	_linterna.texture_scale = 1.1
	_linterna.energy = 1.25
	_linterna.color = Color(1.0, 0.96, 0.85)
	_linterna.position = Vector2(0.0, -34.0)
	add_child(_linterna)

	var camara := Camera2D.new()
	camara.name = "Camara"
	camara.position = Vector2(0.0, -30.0)
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 6.0
	add_child(camara)
	camara.make_current()


func _crear_audio() -> void:
	for i in range(4):
		_pasos_duro.append(load("res://assets/audio/pasos/footstep_concrete_00%d.ogg" % i) as AudioStream)
		_pasos_pasto.append(load("res://assets/audio/pasos/footstep_grass_00%d.ogg" % i) as AudioStream)
	_audio_pasos = AudioStreamPlayer2D.new()
	_audio_pasos.volume_db = -10.0
	add_child(_audio_pasos)
	_audio_linterna = AudioStreamPlayer2D.new()
	_audio_linterna.stream = load("res://assets/audio/efectos/linterna.wav") as AudioStream
	_audio_linterna.volume_db = -6.0
	add_child(_audio_linterna)
