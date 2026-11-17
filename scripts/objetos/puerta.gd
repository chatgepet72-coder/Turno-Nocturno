class_name Puerta
extends Node2D
## Puerta que Lalo abre y cierra con la tecla de interactuar (E).
## Cerrada bloquea el paso; abierta lo deja libre. Muestra un aviso cuando Lalo está cerca.

signal cambio(abierta: bool)

var abierta: bool = false

var _sprite: Sprite2D
var _bloqueo: CollisionShape2D
var _aviso: Label
var _jugador_cerca: bool = false
var _tex_cerrada: Texture2D
var _tex_abierta: Texture2D
var _audio: AudioStreamPlayer2D
var _sonido_abrir: AudioStream
var _sonido_cerrar: AudioStream


## hueco: el rectángulo que tapa la puerta. zona: dónde tiene que estar Lalo para poder usarla.
func configurar(hueco: Rect2, zona: Rect2, tex_cerrada: Texture2D, tex_abierta: Texture2D) -> void:
	_tex_cerrada = tex_cerrada
	_tex_abierta = tex_abierta
	position = hueco.position

	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = _tex_cerrada
	add_child(_sprite)

	var cuerpo := StaticBody2D.new()
	_bloqueo = CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = hueco.size
	_bloqueo.shape = forma
	_bloqueo.position = hueco.size / 2.0
	cuerpo.add_child(_bloqueo)
	add_child(cuerpo)

	var area := Area2D.new()
	area.collision_mask = 2
	var forma_zona := RectangleShape2D.new()
	forma_zona.size = zona.size
	var cs := CollisionShape2D.new()
	cs.shape = forma_zona
	cs.position = zona.get_center() - hueco.position
	area.add_child(cs)
	area.body_entered.connect(_al_entrar)
	area.body_exited.connect(_al_salir)
	add_child(area)

	_aviso = Label.new()
	var estilo := LabelSettings.new()
	estilo.font_size = 8
	estilo.outline_size = 3
	estilo.outline_color = Color.BLACK
	_aviso.label_settings = estilo
	_aviso.position = Vector2(-6, -14)
	_aviso.visible = false
	_aviso.z_index = 10
	add_child(_aviso)

	_sonido_abrir = load("res://assets/audio/efectos/door_open.wav") as AudioStream
	_sonido_cerrar = load("res://assets/audio/efectos/puerta.wav") as AudioStream
	_audio = AudioStreamPlayer2D.new()
	_audio.volume_db = -6.0
	add_child(_audio)


func _unhandled_input(event: InputEvent) -> void:
	if _jugador_cerca and event.is_action_pressed("interactuar"):
		poner_abierta(not abierta)
		get_viewport().set_input_as_handled()


func poner_abierta(valor: bool) -> void:
	abierta = valor
	_sprite.texture = _tex_abierta if abierta else _tex_cerrada
	_bloqueo.set_deferred("disabled", abierta)
	_audio.stream = _sonido_abrir if abierta else _sonido_cerrar
	_audio.play()
	_actualizar_aviso()
	cambio.emit(abierta)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_jugador_cerca = true
		_actualizar_aviso()


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_jugador_cerca = false
		_actualizar_aviso()


func _actualizar_aviso() -> void:
	_aviso.visible = _jugador_cerca
	_aviso.text = "E: cerrar" if abierta else "E: abrir"
