class_name Lalo
extends CharacterBody2D

signal vida_cambio(vida: int)
signal murio
## Lalo: movimiento desde arriba, animación en 4 direcciones, linterna que apunta al ratón y pasos.

const RUTA_CAMINAR: String = "res://assets/sprites/personajes/lalo/caminar/"
const RUTA_SENTADO: String = "res://assets/sprites/personajes/lalo/sentado/"
const RUTA_LINTERNA: String = "res://assets/sprites/personajes/lalo/linterna/"
const DIRECCIONES: Array[String] = ["down", "left", "right", "up"]
## Dónde queda la mano con la linterna en cada dirección (respecto a los pies).
const MANO: Dictionary = {
	"down": Vector2(-2, -23), "right": Vector2(25, -30), "up": Vector2(19, -31), "left": Vector2(-18, -33),
}

@export var velocidad: float = 80.0
@export var velocidad_corriendo: float = 140.0
@export var aceleracion: float = 900.0
@export var freno: float = 1100.0
@export var vida_maxima: int = 3

var vida: int = 3

## Si es false, el jugador no lo controla (escenas, diálogos en persona).
var controlable: bool = true

## Zonas de piso duro (caminos, estacionamiento, patio). Fuera de ellas los pasos suenan a pasto.
var superficies_duras: Array[Rect2] = []

var _sprite: AnimatedSprite2D
var _linterna: PointLight2D
var _direccion: String = "down"
var _distancia_paso: float = 0.0
var _pasos_duro: Array[AudioStream] = []
var _pasos_pasto: Array[AudioStream] = []
var _pasos_metal: Array[AudioStream] = []
var _audio_pasos: AudioStreamPlayer2D
var _audio_linterna: AudioStreamPlayer2D
var _audio_arma: AudioStreamPlayer2D
var _espera_disparo: float = 0.0
var _invulnerable: float = 0.0
var _empuje: Vector2 = Vector2.ZERO


func _ready() -> void:
	vida = GameState.vida_lalo
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_crear_sprite()
	_crear_colision()
	_crear_luces()
	_crear_audio()


func _physics_process(delta: float) -> void:
	if not controlable:
		velocity = Vector2.ZERO
		return
	var entrada: Vector2 = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	var maxima: float = velocidad_corriendo if Input.is_action_pressed("correr") else velocidad
	if entrada != Vector2.ZERO:
		velocity = velocity.move_toward(entrada * maxima, aceleracion * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, freno * delta)
	_espera_disparo = maxf(0.0, _espera_disparo - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	velocity += _empuje
	_empuje = _empuje.move_toward(Vector2.ZERO, 900.0 * delta)
	var antes: Vector2 = global_position
	move_and_slide()
	_animar(entrada)
	_sonar_pasos(global_position.distance_to(antes))


func _process(_delta: float) -> void:
	_linterna.rotation = (get_global_mouse_position() - _linterna.global_position).angle()


func _unhandled_input(event: InputEvent) -> void:
	if controlable and event.is_action_pressed("linterna"):
		_linterna.enabled = not _linterna.enabled
		_audio_linterna.play()
	if controlable and GameState.tiene_pistola:
		if event.is_action_pressed("disparar"):
			_disparar()
		elif event.is_action_pressed("recargar"):
			if GameState.recargar():
				_sonar_arma("recarga")


## Dispara un clavo hacia el ratón. Hace ruido: los enemigos lo escuchan.
func _disparar() -> void:
	if _espera_disparo > 0.0:
		return
	_espera_disparo = 0.35
	if not GameState.gastar_clavo():
		_sonar_arma("sin_clavos")
		return
	var salida: Vector2 = global_position + MANO[_direccion]
	var clavo := Clavo.new()
	clavo.direccion = (get_global_mouse_position() - salida).normalized()
	clavo.global_position = salida + clavo.direccion * 8.0
	get_parent().add_child(clavo)
	_sonar_arma("disparo_clavos")
	EventBus.ruido_emitido.emit(global_position, 320.0)


func recibir_dano(cantidad: int, desde: Vector2) -> void:
	if _invulnerable > 0.0 or vida <= 0:
		return
	_invulnerable = 1.0
	vida -= cantidad
	GameState.vida_lalo = vida
	vida_cambio.emit(vida)
	_empuje = (global_position - desde).normalized() * 260.0
	_sonar_arma("golpe")
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(1.0, 0.3, 0.3), 0.06)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.3)
	if vida <= 0:
		controlable = false
		murio.emit()


func _sonar_arma(nombre: String) -> void:
	_audio_arma.stream = load("res://assets/audio/efectos/%s.wav" % nombre) as AudioStream
	_audio_arma.play()


## Lalo sentado (sin control) hasta que se llame a levantarse().
func sentar() -> void:
	controlable = false
	_linterna.enabled = false
	_sprite.speed_scale = 1.0
	_sprite.play("sentado")


func levantarse() -> void:
	_sprite.play("levantarse")
	await _sprite.animation_finished
	_direccion = "down"
	_sprite.play("caminar_down")
	_sprite.stop()
	controlable = true


## Baja los últimos peldaños de una escalera, de espaldas, con un paso de metal por peldaño.
func bajar_escalera(desde: Vector2, hasta: Vector2) -> void:
	controlable = false
	global_position = desde
	_direccion = "up"
	_sprite.speed_scale = 0.7
	_sprite.play("caminar_up")
	await _peldanos(desde, hasta, 4)
	_direccion = "down"
	_sprite.play("caminar_down")
	_sprite.stop()
	controlable = true


## Camina al pie de la escalera y sube unos peldaños de espaldas.
func subir_escalera(pie: Vector2, arriba: Vector2) -> void:
	controlable = false
	_sprite.speed_scale = 1.0
	_sprite.play("caminar_up")
	var t := create_tween()
	t.tween_property(self, "global_position", pie, maxf(0.2, global_position.distance_to(pie) / velocidad))
	await t.finished
	_sprite.speed_scale = 0.7
	await _peldanos(pie, arriba, 4)
	_sprite.stop()


func _peldanos(desde: Vector2, hasta: Vector2, cantidad: int) -> void:
	for i in cantidad:
		var t := create_tween()
		t.tween_property(self, "global_position", desde.lerp(hasta, float(i + 1) / cantidad), 0.3)
		_audio_pasos.stream = _pasos_metal.pick_random()
		_audio_pasos.pitch_scale = randf_range(0.9, 1.1)
		_audio_pasos.play()
		await t.finished
		await get_tree().create_timer(0.08).timeout


func camara() -> Camera2D:
	return $Camara


func poner_limites_camara(limites: Rect2i) -> void:
	var camara: Camera2D = $Camara
	camara.limit_left = limites.position.x
	camara.limit_top = limites.position.y
	camara.limit_right = limites.end.x
	camara.limit_bottom = limites.end.y


func _animar(entrada: Vector2) -> void:
	# Con la linterna prendida o la pistola, Lalo mira hacia donde apunta el ratón; si no, hacia donde camina.
	var mirada: Vector2 = entrada
	if _linterna.enabled or GameState.tiene_pistola:
		mirada = get_global_mouse_position() - global_position
	if mirada != Vector2.ZERO:
		if absf(mirada.x) > absf(mirada.y):
			_direccion = "right" if mirada.x > 0.0 else "left"
		else:
			_direccion = "down" if mirada.y > 0.0 else "up"
	var brazo_extendido: bool = _linterna.enabled or GameState.tiene_pistola
	var animacion: String = ("linterna_" if brazo_extendido else "caminar_") + _direccion
	_linterna.position = MANO[_direccion]
	if entrada == Vector2.ZERO:
		_sprite.play(animacion)
		_sprite.stop()
		_sprite.frame = 0
		return
	_sprite.speed_scale = 1.6 if Input.is_action_pressed("correr") else 1.0
	_sprite.play(animacion)


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
		for juego in [["caminar_", RUTA_CAMINAR], ["linterna_", RUTA_LINTERNA]]:
			var nombre: String = juego[0] + dir
			frames.add_animation(nombre)
			frames.set_animation_speed(nombre, 8.0)
			frames.set_animation_loop(nombre, true)
			for i in range(1, 5):
				frames.add_frame(nombre, load(juego[1] + "%s_%d.png" % [dir, i]) as Texture2D)
	frames.add_animation("sentado")
	frames.set_animation_speed("sentado", 1.6)
	for i in [1, 2]:
		frames.add_frame("sentado", load(RUTA_SENTADO + "sentado_%d.png" % i) as Texture2D)
	frames.add_animation("levantarse")
	frames.set_animation_speed("levantarse", 7.0)
	frames.set_animation_loop("levantarse", false)
	for i in range(1, 6):
		frames.add_frame("levantarse", load(RUTA_SENTADO + "levantarse_%d.png" % i) as Texture2D)
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
	_linterna.position = MANO["down"]
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
	for i in range(1, 4):
		_pasos_metal.append(load("res://assets/audio/efectos/paso_metal_%d.wav" % i) as AudioStream)
	_audio_pasos = AudioStreamPlayer2D.new()
	_audio_pasos.volume_db = -10.0
	add_child(_audio_pasos)
	_audio_linterna = AudioStreamPlayer2D.new()
	_audio_linterna.stream = load("res://assets/audio/efectos/linterna.wav") as AudioStream
	_audio_linterna.volume_db = -6.0
	add_child(_audio_linterna)
	_audio_arma = AudioStreamPlayer2D.new()
	_audio_arma.volume_db = -3.0
	add_child(_audio_arma)
