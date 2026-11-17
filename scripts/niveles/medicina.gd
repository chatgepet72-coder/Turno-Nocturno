extends Node2D
## Facultad de Medicina, planta baja: un pasillo largo con 7 puertas arriba, 7 abajo y una en cada punta.
## Cada cuarto es una zona aparte dentro de la misma escena; las puertas se cruzan con la transición
## de Resident Evil (TransicionPuerta). Las medidas salen de data/medicina_cuartos.json
## (generado por tools/arte/medicina_interiores.py).

const ARTE: String = "res://assets/sprites/interiores/medicina/"
const NOCHE: Color = Color(0.07, 0.08, 0.1)
const ARRIBA: Array[String] = ["salon_101", "salon_102", "consultorio", "caseta", "laboratorio", "salon_104", "banos_h"]
const ABAJO: Array[String] = ["simulacion", "escaleras", "recepcion", "salon_105", "archivo", "bodega", "maquinas"]
const PUNTA_IZQUIERDA: String = "enfermeria"
const PUNTA_DERECHA: String = "entrada"
const NOMBRES: Dictionary = {
	"pasillo": "Pasillo principal", "salon_101": "Salón 101", "salon_102": "Salón 102", "consultorio": "Consultorio",
	"caseta": "Caseta de vigilancia", "laboratorio": "Laboratorio", "salon_104": "Salón 104", "banos_h": "Baños",
	"simulacion": "Sala de simulación", "escaleras": "Escaleras", "recepcion": "Recepción y sala de espera",
	"salon_105": "Salón 105", "archivo": "Archivo", "bodega": "Bodega de limpieza", "maquinas": "Cuarto de máquinas",
	"enfermeria": "Enfermería", "entrada": "Entrada de Medicina",
}

var lalo: Lalo
var hud: Hud

var _datos: Dictionary = {}
var _zonas: Dictionary = {}          # id -> Rect2 (posición del cuarto en la escena)
var _mundo: Node2D
var _transicion: TransicionPuerta
var _dialogos: Dictionary = {}
var _visto: Dictionary = {}           # cuartos donde ya se dijo el comentario de llegada


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_datos = Dialogos.cargar("res://data/medicina_cuartos.json")
	_dialogos = Dialogos.cargar("res://data/dialogos/medicina.json")
	var noche := CanvasModulate.new()
	noche.color = NOCHE
	add_child(noche)
	_mundo = Node2D.new()
	_mundo.y_sort_enabled = true
	add_child(_mundo)

	_armar_pasillo()
	var todos: Array[String] = []
	todos.assign(ARRIBA + ABAJO + [PUNTA_IZQUIERDA, PUNTA_DERECHA])
	for i in todos.size():
		_armar_cuarto(todos[i], Vector2((i % 5) * 1000, 1000 + (i / 5) * 900))
	lalo = Lalo.new()
	lalo.superficies_duras.append(Rect2(-100000, -100000, 200000, 200000))   # todo es piso duro
	_mundo.add_child(lalo)
	_conectar_puertas()
	_armar_extras()
	hud = Hud.new()
	add_child(hud)
	hud.conectar(lalo)
	_transicion = TransicionPuerta.new()
	add_child(_transicion)
	_ambiente()

	if GameState.punto_entrada == "caseta":
		_mover_a("caseta", _llegada("caseta", false))
	else:
		_mover_a("entrada", _llegada("entrada", false))
	hud.poner_objetivo("Busca a Don Chava en la Facultad de Medicina.")
	if GameState.punto_entrada == "entrada":
		GameState.guardar("medicina", "entrada")   # guardado automático al llegar desde el patio
		await get_tree().create_timer(0.8).timeout
		Dialogos.decir(_dialogos["llegada"], true)


# ---------- Construcción ----------
func _armar_pasillo() -> void:
	var d: Dictionary = _datos["pasillo"]
	var tam := Vector2(d["tam"][0], d["tam"][1])
	_fondo("pasillo", Vector2.ZERO)
	_zonas["pasillo"] = Rect2(Vector2.ZERO, tam)
	var arriba: float = tam.y * d["piso"][0]
	var abajo: float = tam.y * d["piso"][1]
	var muros := StaticBody2D.new()
	_forma(muros, Rect2(0, 0, tam.x, arriba))
	_forma(muros, Rect2(0, abajo, tam.x, tam.y - abajo))
	_forma(muros, Rect2(0, 0, 30, tam.y))
	_forma(muros, Rect2(tam.x - 30, 0, 30, tam.y))
	add_child(muros)
	var radial: Texture2D = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	for fx in [0.15, 0.5, 0.85]:   # lámparas de techo que parpadean
		var l := PointLight2D.new()
		l.texture = radial
		l.texture_scale = 2.4
		l.energy = 0.7
		l.color = Color(0.75, 1.0, 0.85)
		l.position = Vector2(tam.x * fx, tam.y * 0.5)
		add_child(l)
		_parpadear(l)


func _armar_cuarto(id: String, pos: Vector2) -> void:
	var d: Dictionary = _datos[id]
	var tam := Vector2(d["tam"][0], d["tam"][1])
	var muro: float = d["muro"]
	_fondo(id, pos)
	_zonas[id] = Rect2(pos, tam)
	var muros := StaticBody2D.new()
	_forma(muros, Rect2(pos.x, pos.y, tam.x, muro))
	_forma(muros, Rect2(pos.x, pos.y + tam.y - muro, tam.x, muro))
	_forma(muros, Rect2(pos.x, pos.y, muro, tam.y))
	_forma(muros, Rect2(pos.x + tam.x - muro, pos.y, muro, tam.y))
	add_child(muros)


func _fondo(id: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load(ARTE + id + ".png") as Texture2D
	s.centered = false
	s.position = pos
	add_child(s)
	move_child(s, 1)   # siempre detrás de personajes y objetos


# ---------- Puertas ----------
func _conectar_puertas() -> void:
	var d: Dictionary = _datos["pasillo"]
	var tam: Rect2 = _zonas["pasillo"]
	var arriba: float = tam.size.y * d["piso"][0]
	var abajo: float = tam.size.y * d["piso"][1]
	for i in ARRIBA.size():
		var x: float = tam.size.x * d["puertas_x"][i]
		_puerta(Rect2(x - 40, arriba, 80, 44), "entrar", ARRIBA[i], _llegada(ARRIBA[i], false))
		_puerta_cuarto(ARRIBA[i], Vector2(x, arriba + 52))
	for i in ABAJO.size():
		var x: float = tam.size.x * d["puertas_x"][i]
		_puerta(Rect2(x - 40, abajo - 44, 80, 44), "entrar", ABAJO[i], _llegada(ABAJO[i], false))
		_puerta_cuarto(ABAJO[i], Vector2(x, abajo - 8))
	var medio: float = (arriba + abajo) / 2.0
	_puerta(Rect2(30, medio - 60, 60, 120), "entrar", PUNTA_IZQUIERDA, _llegada(PUNTA_IZQUIERDA, false))
	_puerta_cuarto(PUNTA_IZQUIERDA, Vector2(100, medio + 30))
	_puerta(Rect2(tam.size.x - 90, medio - 60, 60, 120), "entrar", PUNTA_DERECHA, _llegada(PUNTA_DERECHA, true))
	_puerta_cuarto(PUNTA_DERECHA, Vector2(tam.size.x - 100, medio + 30), true)
	# La entrada tiene además la puerta de vidrio que da al patio
	var salida := _interactuable(_zona_puerta("entrada", false), "salir al patio")
	salida.usado.connect(_salir_al_patio)


## Puerta en el pasillo que lleva a un cuarto.
func _puerta(zona: Rect2, texto: String, destino: String, llegada: Vector2) -> void:
	var i := _interactuable(zona, texto + ": " + NOMBRES[destino])
	i.usado.connect(_cruzar.bind(destino, llegada))


## Puerta dentro del cuarto que regresa al pasillo. En la Entrada, la del pasillo es la de arriba.
func _puerta_cuarto(id: String, llegada_pasillo: Vector2, por_arriba: bool = false) -> void:
	var i := _interactuable(_zona_puerta(id, por_arriba), "salir al pasillo")
	i.usado.connect(_cruzar.bind("pasillo", llegada_pasillo))


## Zona junto a la puerta dentro de un cuarto. `forzar_arriba` sirve para la Entrada (pasillo arriba, patio abajo).
func _zona_puerta(id: String, forzar_arriba: bool) -> Rect2:
	var d: Dictionary = _datos[id]
	var z: Rect2 = _zonas[id]
	var muro: float = d["muro"]
	var x: float = z.position.x + (z.size.x / 2.0 if forzar_arriba else float(d["puerta_x"]))
	if forzar_arriba or d["puerta"] == "t":
		return Rect2(x - 45, z.position.y + muro, 90, 50)
	return Rect2(x - 45, z.end.y - muro - 50, 90, 50)


## Dónde aparece Lalo (los pies) al entrar a un cuarto por su puerta.
func _llegada(id: String, por_arriba: bool) -> Vector2:
	var zona := _zona_puerta(id, por_arriba)
	var d: Dictionary = _datos[id]
	if por_arriba or d["puerta"] == "t":
		return Vector2(zona.get_center().x, zona.position.y + 66)
	return Vector2(zona.get_center().x, zona.end.y - 6)


func _cruzar(destino: String, llegada: Vector2) -> void:
	if not lalo.controlable:
		return
	lalo.controlable = false
	await _transicion.cruzar(_mover_a.bind(destino, llegada))
	lalo.controlable = true
	hud.avisar(NOMBRES[destino])
	if _dialogos.has(destino) and not _visto.has(destino) and destino != "escaleras":
		_visto[destino] = true
		Dialogos.decir(_dialogos[destino], true)


func _mover_a(zona_id: String, pos: Vector2) -> void:
	lalo.global_position = pos
	lalo.velocity = Vector2.ZERO
	var z: Rect2 = _zonas[zona_id]
	# Si el cuarto es más chico que la pantalla, los límites se abren para centrarlo
	var minimo := Vector2(640, 360)
	var crece: Vector2 = (minimo - z.size).max(Vector2.ZERO) / 2.0
	lalo.poner_limites_camara(Rect2i(z.grow_individual(crece.x, crece.y, crece.x, crece.y)))
	lalo.camara().reset_smoothing()


func _salir_al_patio() -> void:
	lalo.controlable = false
	await _transicion.cruzar(func() -> void: GameState.ir_a("entrada", "puerta_medicina"))


# ---------- Lo que hay dentro ----------
func _armar_extras() -> void:
	# Caseta: lámpara de escritorio encendida y el radio para guardar
	var c: Rect2 = _zonas["caseta"]
	var lampara := PointLight2D.new()
	lampara.texture = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	lampara.texture_scale = 1.6
	lampara.energy = 1.1
	lampara.color = Color(1.0, 0.82, 0.55)
	lampara.position = c.position + Vector2(c.size.x * 0.25, c.size.y * 0.28)
	add_child(lampara)
	var guardar := _interactuable(Rect2(c.position + Vector2(_datos["caseta"]["muro"], _datos["caseta"]["muro"]),
		Vector2(c.size.x * 0.5, c.size.y * 0.32)), "guardar partida")
	guardar.usado.connect(_guardar)
	# Escaleras: la reja de arriba está cerrada (planta alta: próximamente)
	var e: Rect2 = _zonas["escaleras"]
	var subir := _interactuable(Rect2(e.position.x + e.size.x * 0.35, e.position.y + e.size.y * 0.25,
		e.size.x * 0.3, e.size.y * 0.3), "subir")
	subir.usado.connect(func() -> void: Dialogos.decir(_dialogos["escaleras"]))
	# Maniquíes: uno en el pasillo y uno entre las camillas de la sala de simulación
	var p: Rect2 = _zonas["pasillo"]
	_maniqui("medicina_pasillo", p.position + Vector2(p.size.x * 0.3, p.size.y * 0.62))
	var s: Rect2 = _zonas["simulacion"]
	_maniqui("medicina_simulacion", s.position + Vector2(s.size.x * 0.5, s.size.y * 0.7))


func _maniqui(id: String, pos: Vector2) -> void:
	if StringName(id) in GameState.enemigos_eliminados:
		return
	var m := Maniqui.new()
	m.position = pos
	m.radio_despertar = 150.0
	m.objetivo = lalo
	_mundo.add_child(m)
	m.derribado.connect(func() -> void: GameState.enemigos_eliminados.append(StringName(id)))


func _guardar() -> void:
	GameState.guardar("medicina", "caseta")
	hud.avisar("Partida guardada")
	var radio := AudioStreamPlayer.new()
	radio.stream = load("res://assets/audio/efectos/radio_estatica.wav") as AudioStream
	radio.volume_db = -12.0
	add_child(radio)
	radio.play()
	radio.finished.connect(radio.queue_free)


func _ambiente() -> void:
	var musica := AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://assets/audio/ambiente/ambient_horror.ogg") as AudioStreamOggVorbis
	stream.loop = true
	musica.stream = stream
	musica.volume_db = -16.0
	add_child(musica)
	musica.play()


func _parpadear(l: PointLight2D) -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(0.8, 4.0)).timeout
		for i in randi_range(1, 4):
			l.enabled = false
			await get_tree().create_timer(randf_range(0.04, 0.12)).timeout
			l.enabled = true
			await get_tree().create_timer(randf_range(0.04, 0.2)).timeout


# ---------- Utilidades ----------
func _interactuable(zona: Rect2, texto: String) -> Interactuable:
	var i := Interactuable.new()
	add_child(i)
	i.configurar(zona, texto)
	return i


func _forma(cuerpo: CollisionObject2D, r: Rect2) -> void:
	var forma := RectangleShape2D.new()
	forma.size = r.size
	var cs := CollisionShape2D.new()
	cs.shape = forma
	cs.position = r.get_center()
	cuerpo.add_child(cs)
