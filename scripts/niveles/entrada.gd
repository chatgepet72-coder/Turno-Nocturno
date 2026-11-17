extends Node2D
## Nivel de la entrada: caseta, estacionamiento, caminos, patio con fuente, edificios en C y obra.
## Se arma por código a partir de las tablas de abajo. Coordenadas en píxeles del juego (1 px de arte = 4 px).

const ESC: String = "res://assets/sprites/escenario/"
const PISOS: String = "res://assets/sprites/pisos/"
const MUNDO: Rect2i = Rect2i(0, 0, 1960, 1240)
const NOCHE: Color = Color(0.10, 0.11, 0.16)

# Pisos: [textura, rectángulo]
const SUELO: Array = [
	["pasto", Rect2(0, 0, 1960, 1080)],
	["asfalto", Rect2(0, 1112, 1960, 128)],          # calle
	["asfalto", Rect2(0, 648, 672, 432)],             # estacionamiento
	["adoquin", Rect2(744, 0, 88, 736)],              # camino principal
	["adoquin", Rect2(672, 736, 320, 64)],            # conexión: estacionamiento y camino de alumnos
	["adoquin", Rect2(928, 736, 64, 344)],            # camino de alumnos
	["losas", Rect2(832, 456, 168, 80)],              # entrada al patio
	["losas", Rect2(1000, 360, 640, 288)],            # patio
]
const DURAS: Array[Rect2] = [
	Rect2(0, 648, 672, 432), Rect2(744, 0, 88, 736), Rect2(672, 736, 320, 64), Rect2(928, 736, 64, 344),
	Rect2(832, 456, 168, 80), Rect2(1000, 360, 640, 288), Rect2(688, 840, 232, 192), Rect2(1200, 832, 760, 248),
]
const TIERRA_OBRA: Array[Rect2] = [Rect2(1648, 340, 312, 500), Rect2(1200, 832, 760, 248)]

# Objetos: [archivo, esquina superior izquierda, tamaño de colisión (0 = sin colisión)]
# La colisión se coloca en la base del objeto, que es también su punto para ordenar por profundidad.
const OBJETOS: Array = [
	["edificio_largo.png", Vector2(992, 192), Vector2(648, 120)],      # Facultad de Medicina
	["edificio_largo.png", Vector2(992, 656), Vector2(648, 120)],      # Museo de Biología
	["central_demolido.png", Vector2(1672, 380), Vector2(240, 160)],   # Edificio Central
	["escombro.png", Vector2(1700, 640), Vector2(120, 40)],
	["fuente.png", Vector2(1252, 436), Vector2(120, 100)],
	["seto_l.png", Vector2(1048, 392), Vector2.ZERO],
	["banca.png", Vector2(1072, 584), Vector2(72, 20)],
	["banca.png", Vector2(1512, 584), Vector2(72, 20)],
	["hueco_con_cinta.png", Vector2(1220, 880), Vector2(130, 90)],
	["cono.png", Vector2(1380, 900), Vector2(24, 12)],
	["cono.png", Vector2(1420, 900), Vector2(24, 12)],
	["excavadora.png", Vector2(1560, 880), Vector2(230, 90)],
	["autos/vocho_azul.png", Vector2(16, 664), Vector2(72, 100)],
	["autos/auto_1_sedan.png", Vector2(112, 664), Vector2(76, 128)],
	["autos/tsuru_lodo.png", Vector2(256, 664), Vector2(76, 128)],
	["autos/auto_5_pickup.png", Vector2(352, 664), Vector2(80, 140)],
	["autos/vocho_rojo.png", Vector2(496, 664), Vector2(72, 100)],
	["autos/auto_7_combi.png", Vector2(16, 868), Vector2(84, 144)],
	["autos/auto_6_camioneta.png", Vector2(160, 868), Vector2(84, 132)],
	["autos/auto_3_compacto.png", Vector2(304, 868), Vector2(72, 108)],
	["arbol.png", Vector2(160, 40), Vector2(24, 16)],
	["arbol.png", Vector2(360, 260), Vector2(24, 16)],
	["arbol.png", Vector2(60, 420), Vector2(24, 16)],
	["arbol.png", Vector2(560, 120), Vector2(24, 16)],
	["arbol.png", Vector2(600, 380), Vector2(24, 16)],
	["arbol.png", Vector2(848, 40), Vector2(24, 16)],
	["arbol.png", Vector2(848, 580), Vector2(24, 16)],
	["arbol.png", Vector2(1040, 880), Vector2(24, 16)],
	["poste.png", Vector2(712, 240), Vector2(10, 8)],
	["poste.png", Vector2(712, 560), Vector2(10, 8)],
	["poste.png", Vector2(960, 380), Vector2(10, 8)],
]
const POSTES: Array[Vector2] = [Vector2(724, 250), Vector2(724, 570), Vector2(972, 390)]
const CASETA: Rect2 = Rect2(688, 840, 232, 192)
const CASETA_PAREDES: Array[Rect2] = [
	Rect2(688, 840, 96, 32), Rect2(820, 840, 100, 32),   # pared de arriba con hueco de la puerta
	Rect2(688, 840, 12, 192), Rect2(908, 840, 12, 192),  # paredes laterales
	Rect2(688, 1020, 232, 12),                            # pared de abajo
]
const REJA_Y: float = 1036.0

var _mundo: Node2D
var _techo_caseta: Node2D


func _ready() -> void:
	var noche := CanvasModulate.new()
	noche.color = NOCHE
	add_child(noche)
	var suelo := Node2D.new()
	suelo.name = "Suelo"
	add_child(suelo)
	_mundo = Node2D.new()
	_mundo.name = "Mundo"
	_mundo.y_sort_enabled = true
	add_child(_mundo)

	_armar_suelo(suelo)
	for o in OBJETOS:
		_objeto(o[0], o[1], o[2])
	var seto_derecho: Sprite2D = _objeto("seto_l.png", Vector2(1488, 392), Vector2.ZERO).get_child(0) as Sprite2D
	seto_derecho.flip_h = true
	_armar_estacionamiento(suelo)
	_armar_reja()
	_armar_caseta(suelo)
	_armar_bordes()
	_armar_luces()
	_crear_lalo()
	_crear_hud()
	_crear_ambiente()


# ---------- Construcción ----------
func _armar_suelo(suelo: Node2D) -> void:
	for p in SUELO:
		_piso(suelo, p[0], p[1])
	for r in TIERRA_OBRA:
		var tierra := ColorRect.new()
		tierra.color = Color(0.47, 0.33, 0.2)
		tierra.position = r.position
		tierra.size = r.size
		suelo.add_child(tierra)
	var banqueta := ColorRect.new()
	banqueta.color = Color(0.59, 0.58, 0.55)
	banqueta.position = Vector2(0, 1080)
	banqueta.size = Vector2(1960, 32)
	suelo.add_child(banqueta)


func _piso(padre: Node2D, nombre: String, r: Rect2) -> void:
	var s := Sprite2D.new()
	s.texture = load(PISOS + nombre + ".png") as Texture2D
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size)
	s.position = r.position
	padre.add_child(s)


func _objeto(archivo: String, esquina: Vector2, colision: Vector2) -> StaticBody2D:
	var tex: Texture2D = load(ESC + archivo) as Texture2D
	var tam: Vector2 = tex.get_size()
	var cuerpo := StaticBody2D.new()
	cuerpo.position = esquina + Vector2(tam.x / 2.0, tam.y)   # base al centro
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-tam.x / 2.0, -tam.y)
	cuerpo.add_child(s)
	if colision != Vector2.ZERO:
		_forma(cuerpo, Rect2(Vector2(-colision.x / 2.0, -colision.y), colision))
	_mundo.add_child(cuerpo)
	return cuerpo


func _forma(cuerpo: CollisionObject2D, r: Rect2) -> void:
	var forma := RectangleShape2D.new()
	forma.size = r.size
	var cs := CollisionShape2D.new()
	cs.shape = forma
	cs.position = r.get_center()
	cuerpo.add_child(cs)


func _armar_estacionamiento(suelo: Node2D) -> void:
	for x in [8, 104, 248, 344, 488, 584]:
		_linea(suelo, Rect2(x, 664, 6, 150))
	for x in [8, 152, 296, 392]:
		_linea(suelo, Rect2(x, 868, 6, 160))
	for x in range(16, 660, 48):
		_linea(suelo, Rect2(x, 838, 24, 4))   # pasillo de circulación


func _linea(suelo: Node2D, r: Rect2) -> void:
	var l := ColorRect.new()
	l.color = Color(0.9, 0.88, 0.78)
	l.position = r.position
	l.size = r.size
	suelo.add_child(l)


func _armar_reja() -> void:
	var x: float = 0.0
	while x < MUNDO.size.x:
		var libre: bool = (x + 72.0 <= 448.0 or x >= 680.0) and (x + 72.0 <= 920.0 or x >= 1032.0)
		if libre:
			_objeto("reja.png", Vector2(x, REJA_Y), Vector2.ZERO)
		x += 72.0
	_objeto("pluma.png", Vector2(448, REJA_Y), Vector2.ZERO)
	_objeto("puerta_alumnos.png", Vector2(928, REJA_Y - 4), Vector2.ZERO)
	var muro := StaticBody2D.new()   # por ahora Lalo no puede salir del campus
	_forma(muro, Rect2(0, REJA_Y + 40.0, MUNDO.size.x, 16))
	add_child(muro)


func _armar_caseta(suelo: Node2D) -> void:
	var dentro := Sprite2D.new()
	dentro.texture = load(ESC + "caseta_dentro.png") as Texture2D
	dentro.centered = false
	dentro.position = CASETA.position
	suelo.add_child(dentro)
	var paredes := StaticBody2D.new()
	for r in CASETA_PAREDES:
		_forma(paredes, r)
	add_child(paredes)

	_objeto("caseta/escritorio.png", Vector2(708, 876), Vector2(80, 26))
	_objeto("caseta/silla.png", Vector2(794, 880), Vector2.ZERO)
	_objeto("caseta/casillero.png", Vector2(866, 870), Vector2(40, 22))

	var chava := StaticBody2D.new()   # Don Chava sentado junto al escritorio, respirando
	chava.position = Vector2(812, 950)
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 1.6)
	for i in [1, 2]:
		frames.add_frame("default", load("res://assets/sprites/personajes/don_chava/sentado/sentado_%d.png" % i) as Texture2D)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = Vector2(-20, -54)
	sprite.play()
	chava.add_child(sprite)
	_forma(chava, Rect2(-15, -14, 30, 14))
	_mundo.add_child(chava)

	_techo_caseta = _objeto("caseta_fuera.png", CASETA.position, Vector2.ZERO)
	var zona := Area2D.new()   # al entrar, el techo se desvanece para ver el interior
	zona.collision_mask = 2
	_forma(zona, Rect2(700, 872, 208, 148))
	zona.body_entered.connect(_al_entrar_caseta)
	zona.body_exited.connect(_al_salir_caseta)
	add_child(zona)


func _al_entrar_caseta(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_techo(0.0)


func _al_salir_caseta(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_techo(1.0)


func _techo(alfa: float) -> void:
	create_tween().tween_property(_techo_caseta, "modulate:a", alfa, 0.25)


func _armar_bordes() -> void:
	var bordes := StaticBody2D.new()
	_forma(bordes, Rect2(-16, 0, 16, MUNDO.size.y))
	_forma(bordes, Rect2(MUNDO.size.x, 0, 16, MUNDO.size.y))
	_forma(bordes, Rect2(0, -16, MUNDO.size.x, 16))
	add_child(bordes)


func _armar_luces() -> void:
	var radial: Texture2D = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	for p in POSTES:
		_luz(radial, p + Vector2(0, 20), 2.2, 1.0, Color(1.0, 0.86, 0.6))
	_luz(radial, CASETA.get_center(), 1.4, 1.2, Color(1.0, 0.95, 0.85))
	var torreta := _luz(radial, Vector2(1300, 880), 1.0, 0.9, Color(1.0, 0.55, 0.15))
	var parpadeo := create_tween().set_loops()
	parpadeo.tween_property(torreta, "energy", 0.2, 0.5)
	parpadeo.tween_property(torreta, "energy", 0.9, 0.5)


func _luz(tex: Texture2D, pos: Vector2, escala: float, energia: float, color: Color) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex
	l.texture_scale = escala
	l.energy = energia
	l.color = color
	l.position = pos
	add_child(l)
	return l


func _crear_lalo() -> void:
	var lalo := Lalo.new()
	lalo.position = Vector2(730, 1000)
	lalo.superficies_duras = DURAS
	_mundo.add_child(lalo)
	lalo.poner_limites_camara(MUNDO)


func _crear_hud() -> void:
	var capa := CanvasLayer.new()
	var ayuda := Label.new()
	ayuda.text = "WASD o flechas: caminar   ·   Shift: correr   ·   Ratón: apuntar la linterna   ·   F: prender/apagar"
	var estilo := LabelSettings.new()
	estilo.font_size = 9
	estilo.font_color = Color(0.9, 0.88, 0.8)
	estilo.outline_size = 3
	estilo.outline_color = Color.BLACK
	ayuda.label_settings = estilo
	ayuda.position = Vector2(8, 344)
	capa.add_child(ayuda)
	add_child(capa)


func _crear_ambiente() -> void:
	var musica := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://assets/audio/ambiente/lost.ogg") as AudioStreamOggVorbis
	stream.loop = true
	musica.stream = stream
	musica.volume_db = -20.0
	add_child(musica)
	musica.play()
