extends Node2D
## Nivel de la entrada: caseta, estacionamiento, caminos, patio con fuente, edificios en C y obra.
## Se arma por código a partir de las tablas de abajo. Coordenadas en píxeles del juego (1 px de arte = 4 px).

const ESC: String = "res://assets/sprites/escenario/"
const PISOS: String = "res://assets/sprites/pisos/"
const MUNDO: Rect2i = Rect2i(0, 0, 1960, 1240)
const NOCHE: Color = Color(0.025, 0.025, 0.04)   # casi negro: sin linterna casi no se ve nada

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
	["excavadora.png", Vector2(1700, 700), Vector2(230, 90)],       # donde termina el patio, junto al Edificio Central
	["hueco_con_cinta.png", Vector2(1760, 900), Vector2(130, 90)],  # al frente de la excavadora
	["cono.png", Vector2(1712, 930), Vector2(24, 12)],
	["cono.png", Vector2(1910, 930), Vector2(24, 12)],
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
	Rect2(688, 840, 96, 32), Rect2(824, 840, 96, 32),    # pared de arriba con hueco de la puerta
	Rect2(688, 840, 12, 192), Rect2(908, 840, 12, 192),  # paredes laterales
	Rect2(688, 1020, 232, 12),                            # pared de abajo
]
## Sótano del Edificio Central: un cuarto aparte, fuera del mapa del campus, al que se llega por el hueco.
const SOTANO: Rect2i = Rect2i(0, 1400, 640, 360)
## El cuarto es chico (432x264) y está rodeado de oscuridad total.
const SOTANO_PAREDES: Array[Rect2] = [
	Rect2(96, 1440, 448, 92), Rect2(96, 1440, 16, 280), Rect2(528, 1440, 16, 280), Rect2(96, 1712, 448, 16),
	Rect2(320, 1500, 200, 74),   # el derrumbe que tapa la escalera de piedra
]
const SOTANO_ESCALERA_ARRIBA: Vector2 = Vector2(154, 1604)   # donde aparece Lalo al bajar
const SOTANO_LLEGADA: Vector2 = Vector2(154, 1664)           # pie de la escalera
const SALIDA_HUECO: Vector2 = Vector2(1830, 1040)
## Tierra negra que aparece después del apagón: [archivo, posición]
const TIERRA_APAGON: Array = [
	["rastro_1.png", Vector2(740, 300)], ["rastro_2.png", Vector2(1040, 450)],
	["juntas.png", Vector2(1180, 380)], ["huellas.png", Vector2(880, 740)], ["rastro_1.png", Vector2(1640, 560)],
]
const PUERTA_MEDICINA: Rect2 = Rect2(1278, 340, 76, 56)
const SALIDA_MEDICINA: Vector2 = Vector2(1316, 420)
const PUERTA_CASETA: Rect2 = Rect2(784, 844, 40, 28)
const REJA_Y: float = 1036.0
## Barreras invisibles: la obra solo se alcanza entrando por el patio, no cortando por el pasto.
const BARRERAS: Array[Rect2] = [
	Rect2(1000, 817, 16, 260),    # pasto entre el camino de alumnos y la obra (abajo del Museo de Biología)
	Rect2(1640, 330, 320, 16),    # pasto al norte de la obra (arriba del Edificio Central)
]

## Se emite cuando Lalo sale de la caseta (lo usa el prólogo).
signal salio_caseta

var lalo: Lalo
var chava: DonChava
var puerta: Puerta
var ayuda: Label
var hud: Hud

var _mundo: Node2D
var _techo_caseta: Node2D
var _luces_campus: Array[PointLight2D] = []
var _tierra: Array[Sprite2D] = []
var _maniqui: Sprite2D
var notificador_maniqui: VisibleOnScreenNotifier2D
var _linterna_chava: Sprite2D
var _luz_linterna_chava: PointLight2D
var _respiracion: AudioStreamPlayer2D
var _respirando: bool = false
var _caja: Sprite2D


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
	_armar_sotano(suelo)
	_armar_tierra(suelo)
	_armar_maniqui()
	_crear_lalo()
	_crear_hud()
	_crear_ambiente()
	if GameState.prologo_completo:
		_despues_del_prologo()
	else:
		var prologo := Prologo.new()
		add_child(prologo)
		prologo.iniciar(self)


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
	var caja := StaticBody2D.new()   # la caja de herramientas de la obra, con la pistola de clavos
	caja.position = Vector2(868, 1014)
	_caja = Sprite2D.new()
	_caja.texture = load("res://assets/sprites/objetos/caja_cerrada.png") as Texture2D
	_caja.centered = false
	_caja.offset = Vector2(-32, -_caja.texture.get_height())
	caja.add_child(_caja)
	_forma(caja, Rect2(-28, -14, 56, 14))
	_mundo.add_child(caja)

	_objeto("caseta/silla.png", Vector2(726, 938), Vector2.ZERO)   # la silla de Lalo
	chava = DonChava.new()   # sentado junto al escritorio; el prólogo lo levanta y lo manda a su rondín
	chava.position = Vector2(812, 950)
	_mundo.add_child(chava)
	_limites(chava.camara)

	puerta = Puerta.new()   # se abre y se cierra con E; Lalo empieza con ella cerrada
	suelo.add_child(puerta)
	puerta.configurar(PUERTA_CASETA, Rect2(764, 812, 80, 96),
		load(ESC + "caseta/puerta_cerrada.png") as Texture2D, load(ESC + "caseta/puerta_abierta.png") as Texture2D)

	_techo_caseta = _objeto("caseta_fuera.png", CASETA.position, Vector2.ZERO)
	var zona := Area2D.new()   # al entrar (o al acercarse a la puerta por fuera) el techo se desvanece
	zona.collision_mask = 2
	_forma(zona, Rect2(700, 872, 208, 148))
	_forma(zona, Rect2(764, 800, 80, 44))
	zona.body_entered.connect(_al_entrar_caseta)
	zona.body_exited.connect(_al_salir_caseta)
	add_child(zona)


func _al_entrar_caseta(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_techo(0.0)


func _al_salir_caseta(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_techo(1.0)
		salio_caseta.emit()


func _techo(alfa: float) -> void:
	create_tween().tween_property(_techo_caseta, "modulate:a", alfa, 0.25)


func _armar_bordes() -> void:
	var bordes := StaticBody2D.new()
	_forma(bordes, Rect2(-16, 0, 16, MUNDO.size.y))
	_forma(bordes, Rect2(MUNDO.size.x, 0, 16, MUNDO.size.y))
	_forma(bordes, Rect2(0, -16, MUNDO.size.x, 16))
	for r in BARRERAS:
		_forma(bordes, r)
	add_child(bordes)


func _armar_luces() -> void:
	var radial: Texture2D = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	for p in POSTES:
		_luces_campus.append(_luz(radial, p + Vector2(0, 20), 2.2, 1.0, Color(1.0, 0.86, 0.6)))
	_luces_campus.append(_luz(radial, CASETA.get_center(), 1.4, 1.2, Color(1.0, 0.95, 0.85)))
	var torreta := _luz(radial, Vector2(1830, 890), 1.0, 0.9, Color(1.0, 0.55, 0.15))
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
	lalo = Lalo.new()
	lalo.position = Vector2(744, 1004)   # sentado frente al escritorio; empieza con el prólogo
	var duras: Array[Rect2] = []
	duras.assign(DURAS)
	duras.append(Rect2(SOTANO))
	lalo.superficies_duras = duras
	_mundo.add_child(lalo)
	lalo.poner_limites_camara(MUNDO)
	if not GameState.prologo_completo:
		lalo.sentar()


## El campus como queda después del prólogo: apagón, sin Don Chava, y Lalo en la puerta de Medicina.
func _despues_del_prologo() -> void:
	apagon()
	chava.visible = false
	chava.process_mode = Node.PROCESS_MODE_DISABLED
	if GameState.punto_entrada == "puerta_medicina":
		lalo.global_position = SALIDA_MEDICINA
		lalo.camara().reset_smoothing()
		var transicion := TransicionPuerta.new()
		add_child(transicion)
		transicion.aparecer()
	poner_objetivo("Busca a Don Chava en la Facultad de Medicina.")
	habilitar_medicina()


## La puerta de la Facultad de Medicina, en el centro del ala de arriba del patio.
func habilitar_medicina() -> void:
	var puerta_medicina := agregar_interactuable(PUERTA_MEDICINA, "entrar a Medicina")
	puerta_medicina.usado.connect(_entrar_medicina)


func _entrar_medicina() -> void:
	lalo.controlable = false
	var transicion := TransicionPuerta.new()
	add_child(transicion)
	transicion.cruzar_a_escena("medicina", "entrada")


func _limites(camara: Camera2D) -> void:
	camara.limit_left = MUNDO.position.x
	camara.limit_top = MUNDO.position.y
	camara.limit_right = MUNDO.end.x
	camara.limit_bottom = MUNDO.end.y


# ---------- Prólogo: sótano, apagón y maniquí ----------
func _armar_sotano(suelo: Node2D) -> void:
	var fondo := Sprite2D.new()
	fondo.texture = load(ESC + "prologo/sotano.png") as Texture2D
	fondo.centered = false
	fondo.position = Vector2(SOTANO.position)
	suelo.add_child(fondo)
	var paredes := StaticBody2D.new()
	for r in SOTANO_PAREDES:
		_forma(paredes, r)
	add_child(paredes)
	var radial: Texture2D = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	_luz(radial, Vector2(152, 1480), 0.9, 0.5, Color(0.6, 0.7, 0.9))   # luz que entra por el hueco de arriba
	_linterna_chava = Sprite2D.new()   # la linterna de Don Chava, tirada y encendida, apuntando al derrumbe
	_linterna_chava.texture = load(ESC + "prologo/linterna_don_chava.png") as Texture2D
	_linterna_chava.position = Vector2(452, 1688)
	_linterna_chava.rotation = -PI / 2.0
	suelo.add_child(_linterna_chava)
	_luz_linterna_chava = PointLight2D.new()
	_luz_linterna_chava.texture = load("res://assets/sprites/luces/cono_linterna.png") as Texture2D
	_luz_linterna_chava.texture_scale = 0.8
	_luz_linterna_chava.energy = 1.1
	_luz_linterna_chava.position = Vector2(452, 1680)
	_luz_linterna_chava.rotation = -PI / 2.0
	add_child(_luz_linterna_chava)
	_respiracion = AudioStreamPlayer2D.new()   # una respiración lenta detrás del derrumbe
	_respiracion.stream = load("res://assets/audio/efectos/jadeo.wav") as AudioStream
	_respiracion.pitch_scale = 0.55
	_respiracion.volume_db = -2.0
	_respiracion.max_distance = 700.0
	_respiracion.position = Vector2(420, 1530)
	_respiracion.finished.connect(_seguir_respirando)
	add_child(_respiracion)


func _armar_tierra(suelo: Node2D) -> void:
	for t in TIERRA_APAGON:
		var s := Sprite2D.new()
		s.texture = load(ESC + "tierra/" + t[0]) as Texture2D
		s.centered = false
		s.position = t[1]
		s.visible = false
		suelo.add_child(s)
		_tierra.append(s)


func _armar_maniqui() -> void:
	_maniqui = Sprite2D.new()   # sentado en la banca del patio; aparece después del apagón
	_maniqui.texture = load(ESC + "prologo/maniqui_sentado.png") as Texture2D
	_maniqui.scale = Vector2(0.75, 0.75)
	_maniqui.centered = false
	_maniqui.offset = Vector2(-32, -80)
	_maniqui.position = Vector2(1548, 618)
	_maniqui.visible = false
	notificador_maniqui = VisibleOnScreenNotifier2D.new()
	notificador_maniqui.rect = Rect2(-32, -80, 64, 80)
	_maniqui.add_child(notificador_maniqui)
	_mundo.add_child(_maniqui)


func agregar_interactuable(zona: Rect2, texto: String) -> Interactuable:
	var i := Interactuable.new()
	add_child(i)
	i.configurar(zona, texto)
	return i


func entrar_sotano() -> void:
	_mover_lalo(SOTANO_ESCALERA_ARRIBA, SOTANO)
	_respirando = true
	_respiracion.play()


func salir_sotano() -> void:
	_mover_lalo(SALIDA_HUECO, MUNDO)


func _mover_lalo(pos: Vector2, limites: Rect2i) -> void:
	lalo.global_position = pos
	lalo.velocity = Vector2.ZERO
	lalo.poner_limites_camara(limites)
	lalo.camara().reset_smoothing()


func recoger_linterna_chava() -> void:
	_linterna_chava.visible = false
	_luz_linterna_chava.enabled = false


func parar_respiracion() -> void:
	_respirando = false
	_respiracion.stop()


func _seguir_respirando() -> void:
	if _respirando:
		_respiracion.play()


## Se va la luz: postes y caseta se apagan y aparece la tierra negra en los caminos.
func apagon() -> void:
	for l in _luces_campus:
		l.enabled = false
	for t in _tierra:
		t.visible = true


func mostrar_maniqui() -> void:
	_maniqui.visible = true


func ocultar_maniqui() -> void:
	_maniqui.visible = false


# ---------- Caja, combate y pantalla de muerte ----------
func abrir_caja() -> void:
	_caja.texture = load("res://assets/sprites/objetos/caja_abierta.png") as Texture2D
	_caja.offset = Vector2(-32, -_caja.texture.get_height())


func cerrar_caja() -> void:
	_caja.texture = load("res://assets/sprites/objetos/caja_cerrada.png") as Texture2D
	_caja.offset = Vector2(-32, -_caja.texture.get_height())


func aparecer_maniqui(pos: Vector2) -> Maniqui:
	var m := Maniqui.new()
	m.position = pos
	m.objetivo = lalo
	_mundo.add_child(m)
	return m


func poner_objetivo(texto: String) -> void:
	hud.poner_objetivo(texto)


func _crear_hud() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.conectar(lalo)
	ayuda = hud.ayuda
	ayuda.visible = GameState.prologo_completo   # en el prólogo aparece cuando el jugador toma el control


func _crear_ambiente() -> void:
	var musica := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://assets/audio/ambiente/lost.ogg") as AudioStreamOggVorbis
	stream.loop = true
	musica.stream = stream
	musica.volume_db = -20.0
	add_child(musica)
	musica.play()
