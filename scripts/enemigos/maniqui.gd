class_name Maniqui
extends CharacterBody2D
## Maniquí de RCP movido por la tierra: espera quieto, despierta cuando Lalo se acerca o le disparan,
## camina rígido hacia él y lo golpea. Con suficientes clavos queda derribado.
## (El sistema de "regresar" después de derribado se agrega más adelante.)

signal derribado

enum Estado { QUIETO, PERSIGUIENDO, DERRIBADO }

const RUTA: String = "res://assets/sprites/enemigos/maniqui/"

@export var vida: int = 4
@export var velocidad: float = 92.0   # Lalo camina a 80 y corre a 140: solo corriendo te escapas
@export var radio_despertar: float = 200.0
@export var dano: int = 1

var objetivo: Lalo
var estado: Estado = Estado.QUIETO

var _sprite: AnimatedSprite2D
var _quieto: Sprite2D
var _colision: CollisionShape2D
var _espera_golpe: float = 0.0
var _atorado: float = 0.0
var _rodeo: float = 0.0
var _dir_rodeo: Vector2 = Vector2.ZERO
var _cuerpo_dano: Area2D
var _dir_vista: String = "down"
var _embestida: float = 0.0
var _espera_embestida: float = 1.0
var _paso: float = 0.0
var _audio_pasos: AudioStreamPlayer2D
var _pasos: Array[AudioStream] = []
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	collision_layer = 4          # enemigos
	add_to_group("enemigos")
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var frames := SpriteFrames.new()
	for dir in ["down", "left", "right", "up"]:
		frames.add_animation("caminar_" + dir)
		frames.set_animation_speed("caminar_" + dir, 7.0)
		for i in range(1, 5):
			frames.add_frame("caminar_" + dir, load(RUTA + "%s_%d.png" % [dir, i]) as Texture2D)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.offset = Vector2(0.0, -frames.get_frame_texture("caminar_down", 0).get_size().y / 2.0)
	_sprite.visible = false
	add_child(_sprite)
	_quieto = Sprite2D.new()   # parado, quieto, mirando hacia Lalo
	_quieto.texture = load(RUTA + "down_1.png") as Texture2D
	_quieto.centered = false
	_quieto.offset = Vector2(-_quieto.texture.get_width() / 2.0, -_quieto.texture.get_height())
	add_child(_quieto)
	var forma := RectangleShape2D.new()
	forma.size = Vector2(22.0, 10.0)
	_colision = CollisionShape2D.new()
	_colision.shape = forma
	_colision.position = Vector2(0.0, -5.0)
	add_child(_colision)
	# Zona que recibe los clavos: todo el cuerpo, de los pies a la cabeza (la colisión de arriba es solo los pies)
	_cuerpo_dano = Area2D.new()
	_cuerpo_dano.collision_layer = 4
	_cuerpo_dano.collision_mask = 0
	_cuerpo_dano.monitoring = false
	var forma_cuerpo := RectangleShape2D.new()
	forma_cuerpo.size = Vector2(30.0, 66.0)
	var cs_cuerpo := CollisionShape2D.new()
	cs_cuerpo.shape = forma_cuerpo
	cs_cuerpo.position = Vector2(0.0, -33.0)
	_cuerpo_dano.add_child(cs_cuerpo)
	add_child(_cuerpo_dano)
	_audio = AudioStreamPlayer2D.new()
	add_child(_audio)
	_audio_pasos = AudioStreamPlayer2D.new()   # pasos pesados: se oyen antes de verlo
	_audio_pasos.volume_db = 2.0
	_audio_pasos.max_distance = 520.0
	add_child(_audio_pasos)
	for i in range(4):
		_pasos.append(load("res://assets/audio/pasos/footstep_concrete_00%d.ogg" % i) as AudioStream)


func _physics_process(delta: float) -> void:
	if objetivo == null or estado == Estado.DERRIBADO:
		return
	var hacia: Vector2 = objetivo.global_position - global_position
	match estado:
		Estado.QUIETO:
			if hacia.length() < radio_despertar:
				_despertar()
		Estado.PERSIGUIENDO:
			_espera_golpe = maxf(0.0, _espera_golpe - delta)
			_espera_embestida = maxf(0.0, _espera_embestida - delta)
			if hacia.length() < 34.0:
				velocity = Vector2.ZERO
				if _espera_golpe == 0.0:
					_espera_golpe = 0.75
					objetivo.recibir_dano(dano, global_position)
			elif _embestida > 0.0:
				# Embestida: se lanza en línea recta hacia donde estaba Lalo
				_embestida -= delta
				velocity = hacia.normalized() * velocidad * 2.4
				move_and_slide()
			elif hacia.length() < 110.0 and _espera_embestida == 0.0:
				_embestida = 0.28
				_espera_embestida = 2.2
				_sonar("res://assets/audio/efectos/golpe.wav")
			else:
				_caminar_hacia(hacia, delta)
			_animar(hacia)
			_sonar_pasos(delta)


## Camina directo hacia Lalo; si algo lo detiene (la fuente, una banca), rodea el obstáculo un momento.
func _caminar_hacia(hacia: Vector2, delta: float) -> void:
	var directo: Vector2 = hacia.normalized()
	if _rodeo > 0.0:
		_rodeo -= delta
		velocity = (_dir_rodeo * 0.8 + directo * 0.2).normalized() * velocidad
	else:
		velocity = directo * velocidad
	var antes: Vector2 = global_position
	move_and_slide()
	if global_position.distance_to(antes) < velocidad * delta * 0.3:
		_atorado += delta
	else:
		_atorado = 0.0
	if _atorado > 0.35 and _rodeo <= 0.0:
		_atorado = 0.0
		_rodeo = 0.7
		var lado: Vector2 = directo.orthogonal()
		_dir_rodeo = lado if randf() < 0.5 else -lado


func recibir_clavo(direccion: Vector2) -> void:
	if estado == Estado.DERRIBADO:
		return
	_sonar("res://assets/audio/efectos/clavo_impacto.wav")
	vida -= 1
	global_position += direccion * 5.0
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.8, 1.8, 1.8), 0.05)
	t.tween_property(self, "modulate", Color.WHITE, 0.12)
	if vida <= 0:
		_derribar()
	elif estado == Estado.QUIETO:
		_despertar()


func _despertar() -> void:
	estado = Estado.PERSIGUIENDO
	_quieto.visible = false
	_sprite.visible = true
	_sprite.play("caminar_down")


## Siempre mira hacia Lalo (no hacia donde se desvía al rodear algo). Solo cambia de dirección
## cuando la diferencia es clara, para que no parpadee entre "de lado" y "de frente".
func _animar(hacia: Vector2) -> void:
	var horizontal: bool = _dir_vista == "left" or _dir_vista == "right"
	var margen: float = 1.3
	var dir: String = _dir_vista
	if horizontal and absf(hacia.y) > absf(hacia.x) * margen:
		dir = "down" if hacia.y > 0.0 else "up"
	elif not horizontal and absf(hacia.x) > absf(hacia.y) * margen:
		dir = "right" if hacia.x > 0.0 else "left"
	elif horizontal:
		dir = "right" if hacia.x > 0.0 else "left"
	else:
		dir = "down" if hacia.y > 0.0 else "up"
	_dir_vista = dir
	if _sprite.animation != "caminar_" + dir or not _sprite.is_playing():
		_sprite.play("caminar_" + dir)


func _sonar_pasos(delta: float) -> void:
	if velocity == Vector2.ZERO:
		return
	_paso -= delta
	if _paso <= 0.0:
		_paso = 0.42 if _embestida <= 0.0 else 0.15
		_audio_pasos.stream = _pasos.pick_random()
		_audio_pasos.pitch_scale = randf_range(0.55, 0.7)
		_audio_pasos.play()


## Para la tensión de Lalo: solo cuenta si está despierto.
func es_amenaza() -> bool:
	return estado == Estado.PERSIGUIENDO


func _derribar() -> void:
	estado = Estado.DERRIBADO
	_colision.set_deferred("disabled", true)
	_cuerpo_dano.set_deferred("monitorable", false)
	_quieto.visible = false
	_sprite.visible = true
	_sprite.stop()
	_sonar("res://assets/audio/efectos/maniqui_cae.wav")
	var t := create_tween()   # cae de lado y se oscurece
	t.set_parallel(true)
	t.tween_property(_sprite, "rotation", PI / 2.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(_sprite, "position", Vector2(14.0, 12.0), 0.35)
	t.tween_property(self, "modulate", Color(0.6, 0.6, 0.6), 0.6)
	EventBus.enemigo_derribado.emit(self)
	derribado.emit()


func _sonar(ruta: String) -> void:
	_audio.stream = load(ruta) as AudioStream
	_audio.pitch_scale = randf_range(0.9, 1.1)
	_audio.play()
