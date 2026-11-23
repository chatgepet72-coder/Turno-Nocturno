extends Node2D
## El cuarto seguro (el Taller), como las salas de guardado de Resident Evil y Silent Hill:
## - Siempre tiene luz cálida, aunque el resto del edificio esté a oscuras.
## - Al entrar suena una música tranquila (assets/audio/refugio/refugio.wav) y se apaga el ambiente
##   de tensión; al salir la música se desvanece.
## (Ni el Archivero ni los enemigos entran: eso vive en cuartos.gd.)

const VOLUMEN: float = -13.0
const SILENCIO: float = -60.0
const FUNDIDO: float = 1.6   # segundos para entrar o salir la música

var escuela: Node2D
var adentro: bool = false
var _musica: AudioStreamPlayer
var _luz: PointLight2D


func _ready() -> void:
	_musica = AudioStreamPlayer.new()
	var pista := (load("res://assets/audio/refugio/refugio.wav") as AudioStreamWAV).duplicate() as AudioStreamWAV
	pista.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pista.loop_end = pista.data.size() / 2   # 16 bits, mono
	_musica.stream = pista
	_musica.volume_db = SILENCIO
	_musica.bus = "Música" if AudioServer.get_bus_index("Música") >= 0 else "Master"
	add_child(_musica)
	# Luz cálida para la vista desde arriba (la vista 3D pone sus propias lámparas)
	var cuarto: Rect2 = escuela.cuartos.cuartos.get(escuela.cuartos.REFUGIO, Rect2())
	if cuarto.size != Vector2.ZERO:
		_luz = PointLight2D.new()
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0, 0, 0, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.width = 512
		tex.height = 512
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		_luz.texture = tex
		_luz.texture_scale = 1.1
		_luz.energy = 0.9
		_luz.color = Color(1.0, 0.82, 0.6)
		_luz.global_position = cuarto.get_center()
		add_child(_luz)


func _process(delta: float) -> void:
	var j: CharacterBody2D = escuela.jugador
	var ahora: bool = escuela.partida_iniciada and escuela.cuartos != null and escuela.cuartos.en_refugio(j.global_position)
	if ahora != adentro:
		adentro = ahora
		escuela.sonidos.silenciar_ambiente(adentro)
		if adentro and not _musica.playing:
			_musica.play()
	if _luz != null:
		_luz.visible = escuela.campana.lugar == "principal"
	var meta: float = VOLUMEN if adentro and escuela.jugando else SILENCIO
	if adentro and not escuela.jugando:
		meta = VOLUMEN - 6.0   # en la pausa o la mochila sigue, más bajita
	_musica.volume_db = move_toward(_musica.volume_db, meta, (VOLUMEN - SILENCIO) / FUNDIDO * delta)
	if not adentro and _musica.volume_db <= SILENCIO + 0.5 and _musica.playing:
		_musica.stop()
