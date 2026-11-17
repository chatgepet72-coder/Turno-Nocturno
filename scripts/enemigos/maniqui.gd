class_name Maniqui
extends CharacterBody2D
## Maniquí de RCP movido por la tierra: espera quieto, despierta cuando Lalo se acerca o le disparan,
## camina rígido hacia él y lo golpea. Con suficientes clavos queda derribado.
## (El sistema de "regresar" después de derribado se agrega más adelante.)

signal derribado

enum Estado { QUIETO, PERSIGUIENDO, DERRIBADO }

const RUTA: String = "res://assets/sprites/enemigos/maniqui/"

@export var vida: int = 4
@export var velocidad: float = 36.0
@export var radio_despertar: float = 200.0
@export var dano: int = 1

var objetivo: Lalo
var estado: Estado = Estado.QUIETO

var _sprite: AnimatedSprite2D
var _quieto: Sprite2D
var _colision: CollisionShape2D
var _espera_golpe: float = 0.0
var _audio: AudioStreamPlayer2D


func _ready() -> void:
	collision_layer = 4          # enemigos
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var frames := SpriteFrames.new()
	for dir in ["down", "left", "right", "up"]:
		frames.add_animation("caminar_" + dir)
		frames.set_animation_speed("caminar_" + dir, 4.5)
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
	_audio = AudioStreamPlayer2D.new()
	add_child(_audio)


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
			if hacia.length() < 28.0:
				velocity = Vector2.ZERO
				if _espera_golpe == 0.0:
					_espera_golpe = 1.3
					objetivo.recibir_dano(dano, global_position)
			else:
				velocity = hacia.normalized() * velocidad
				move_and_slide()
			_animar(hacia)


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


func _animar(hacia: Vector2) -> void:
	var dir: String
	if absf(hacia.x) > absf(hacia.y):
		dir = "right" if hacia.x > 0.0 else "left"
	else:
		dir = "down" if hacia.y > 0.0 else "up"
	if _sprite.animation != "caminar_" + dir or not _sprite.is_playing():
		_sprite.play("caminar_" + dir)


func _derribar() -> void:
	estado = Estado.DERRIBADO
	_colision.set_deferred("disabled", true)
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
