class_name DonChava
extends Node2D
## Don Chava en escenas guionizadas: sentado, levantarse y caminar por una ruta.
## No tiene IA: hace siempre lo mismo, en el orden que le marque la escena.

const RUTA: String = "res://assets/sprites/personajes/don_chava/"

var camara: Camera2D

var _sprite: AnimatedSprite2D
var _cuerpo: StaticBody2D


func _ready() -> void:
	var frames := SpriteFrames.new()
	for dir in ["down", "left", "right", "up"]:
		var nombre: String = "caminar_" + dir
		frames.add_animation(nombre)
		frames.set_animation_speed(nombre, 7.0)
		for i in range(1, 5):
			frames.add_frame(nombre, load(RUTA + "caminar/%s_%d.png" % [dir, i]) as Texture2D)
	frames.add_animation("sentado")
	frames.set_animation_speed("sentado", 1.6)
	for i in [1, 2]:
		frames.add_frame("sentado", load(RUTA + "sentado/sentado_%d.png" % i) as Texture2D)
	frames.add_animation("levantarse")
	frames.set_animation_speed("levantarse", 7.0)
	frames.set_animation_loop("levantarse", false)
	for i in range(1, 6):
		frames.add_frame("levantarse", load(RUTA + "sentado/levantarse_%d.png" % i) as Texture2D)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.offset = Vector2(0.0, -32.0)   # pies en el origen (cuadros de 64 px de alto)
	add_child(_sprite)
	_sprite.play("sentado")

	_cuerpo = StaticBody2D.new()   # mientras está sentado, Lalo no lo atraviesa
	var forma := RectangleShape2D.new()
	forma.size = Vector2(28.0, 12.0)
	var cs := CollisionShape2D.new()
	cs.shape = forma
	cs.position = Vector2(0.0, -6.0)
	_cuerpo.add_child(cs)
	add_child(_cuerpo)

	camara = Camera2D.new()   # para seguirlo cuando se va a su rondín
	camara.position = Vector2(0.0, -30.0)
	camara.position_smoothing_enabled = true
	camara.position_smoothing_speed = 4.0
	add_child(camara)


func levantarse() -> void:
	_sprite.play("levantarse")
	await _sprite.animation_finished
	_cuerpo.queue_free()


## Camina por los puntos en orden, a la velocidad dada (px por segundo).
func caminar_por(puntos: Array[Vector2], velocidad: float = 55.0) -> void:
	for p in puntos:
		var d: Vector2 = p - position
		if d.length() < 1.0:
			continue
		var dir: String
		if absf(d.x) > absf(d.y):
			dir = "right" if d.x > 0.0 else "left"
		else:
			dir = "down" if d.y > 0.0 else "up"
		_sprite.play("caminar_" + dir)
		var t := create_tween()
		t.tween_property(self, "position", p, d.length() / velocidad)
		await t.finished
	_sprite.stop()


func desvanecer(duracion: float = 1.5) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, duracion)
	await t.finished
	visible = false
