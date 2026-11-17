extends Node2D
## Facultad de Medicina, planta baja: un pasillo largo con 7 puertas arriba, 7 abajo y una en cada punta.
## Cada cuarto es una zona aparte dentro de la misma escena; las puertas se cruzan con la transición
## de Resident Evil (TransicionPuerta). Las medidas salen de data/medicina_cuartos.json
## (generado por tools/arte/medicina_interiores.py).

const ARTE: String = "res://assets/sprites/interiores/medicina/"
const NOCHE: Color = Color(0.015, 0.018, 0.022)   # casi negro: sin linterna casi no se ve nada
const ARRIBA: Array[String] = ["salon_101", "salon_102", "consultorio", "caseta", "laboratorio", "salon_104", "banos_h"]
const ABAJO: Array[String] = ["simulacion", "escaleras", "recepcion", "salon_105", "archivo", "bodega", "maquinas"]
const PUNTA_DERECHA: String = "entrada"
## Ala oeste: sale de la punta izquierda del pasillo principal (el pasillo da vuelta). Enfermería al fondo.
const OESTE_IZQUIERDA: Array[String] = ["cerrada_profesores", "banos_m", "cerrada_cuarto_oscuro"]
const OESTE_DERECHA: Array[String] = ["cerrada_aula_106", "cerrada_intendencia", "cerrada_oficina"]
const OESTE_FONDO: String = "enfermeria"
## Puertas con llave (se abren una vez y quedan abiertas) o que nunca abren (llave vacía).
const CERRADAS: Dictionary = {
	"archivo": "llave_archivo", "maquinas": "llave_maquinas", "bodega": "",
	"cerrada_profesores": "", "cerrada_cuarto_oscuro": "", "cerrada_aula_106": "",
	"cerrada_intendencia": "", "cerrada_oficina": "",
}
## Objetos en el piso: [id único, objeto, cantidad, cuarto, posición dentro del cuarto (0..1)]
const OBJETOS_MAPA: Array = [
	# Medicina (cura): en baños, la caseta y la enfermería
	["medicina_caseta", "medicina", 1, "caseta", Vector2(0.7, 0.72)],
	["medicina_banos_h", "medicina", 1, "banos_h", Vector2(0.3, 0.72)],
	["medicina_banos_m", "medicina", 1, "banos_m", Vector2(0.72, 0.62)],
	["medicina_enfermeria", "medicina", 1, "enfermeria", Vector2(0.5, 0.58)],
	# Para hacer bombas molotov: vendas + alcohol
	["alcohol_lab", "alcohol", 1, "laboratorio", Vector2(0.5, 0.58)],
	["alcohol_enfermeria", "alcohol", 1, "enfermeria", Vector2(0.72, 0.75)],
	["vendas_consultorio", "vendas", 1, "consultorio", Vector2(0.75, 0.62)],
	["vendas_maquinas", "vendas", 1, "maquinas", Vector2(0.3, 0.55)],
	# Llaves y herramientas del puzzle
	["llave_archivo", "llave_archivo", 1, "consultorio", Vector2(0.62, 0.42)],
	["llave_maquinas", "llave_maquinas", 1, "archivo", Vector2(0.3, 0.68)],
	["cizalla", "cizalla", 1, "maquinas", Vector2(0.62, 0.62)],
	# Clavos
	["clavos_102", "clavos", 10, "salon_102", Vector2(0.35, 0.62)],
	["clavos_archivo", "clavos", 10, "archivo", Vector2(0.72, 0.45)],
	["clavos_oeste", "clavos", 10, "pasillo_oeste", Vector2(0.55, 0.3)],
	["clavos_105", "clavos", 10, "salon_105", Vector2(0.62, 0.68)],
	# Notas: la historia por pedazos
	["recado_enfermeria", "recado_enfermeria", 1, "enfermeria", Vector2(0.3, 0.72)],
	["nota_dia_12", "nota_dia_12", 1, "recepcion", Vector2(0.62, 0.55)],
	["expediente_salvador", "expediente_salvador", 1, "archivo", Vector2(0.55, 0.55)],
	["carta_lupita", "carta_lupita", 1, "caseta", Vector2(0.75, 0.45)],
	["inventario_maniquies", "inventario_maniquies", 1, "simulacion", Vector2(0.75, 0.75)],
	["diario_estudiante", "diario_estudiante", 1, "salon_104", Vector2(0.3, 0.65)],
	["reporte_mantenimiento", "reporte_mantenimiento", 1, "maquinas", Vector2(0.72, 0.4)],
	["libro_historia", "libro_historia", 1, "archivo", Vector2(0.45, 0.78)],
	["lista_asistencia", "lista_asistencia", 1, "salon_101", Vector2(0.62, 0.62)],
]
## Emboscadas: [id, cuarto, zona que dispara (0..1), dónde aparece (0..1)]. El maniquí está escondido
## hasta que Lalo pisa la zona; entonces sale por detrás, donde no lo ve. La estática del radio sí lo delata.
const EMBOSCADAS: Array = [
	["emboscada_pasillo", "pasillo", Rect2(0.36, 0.25, 0.05, 0.55), Vector2(0.62, 0.55)],
	["emboscada_104", "salon_104", Rect2(0.35, 0.35, 0.3, 0.3), Vector2(0.5, 0.86)],
	["emboscada_banos", "banos_h", Rect2(0.42, 0.3, 0.3, 0.3), Vector2(0.48, 0.86)],
]

const NOMBRES: Dictionary = {
	"pasillo": "Pasillo principal", "salon_101": "Salón 101", "salon_102": "Salón 102", "consultorio": "Consultorio",
	"caseta": "Caseta de vigilancia", "laboratorio": "Laboratorio", "salon_104": "Salón 104", "banos_h": "Baños",
	"simulacion": "Sala de simulación", "escaleras": "Escaleras", "recepcion": "Recepción y sala de espera",
	"salon_105": "Salón 105", "archivo": "Archivo", "bodega": "Bodega de limpieza", "maquinas": "Cuarto de máquinas",
	"enfermeria": "Enfermería", "entrada": "Entrada de Medicina", "pasillo_oeste": "Pasillo del ala oeste",
	"banos_m": "Baños de mujeres", "cerrada_profesores": "Sala de profesores", "cerrada_cuarto_oscuro": "Cuarto oscuro",
	"cerrada_aula_106": "Aula 106", "cerrada_intendencia": "Intendencia", "cerrada_oficina": "Oficina",
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
	todos.assign(ARRIBA + ABAJO + [OESTE_FONDO, PUNTA_DERECHA, "banos_m"])
	for i in todos.size():
		_armar_cuarto(todos[i], Vector2((i % 5) * 1300, 1300 + floori(i / 5.0) * 1150))
	_armar_ala_oeste(Vector2(5500, 0))
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
	_transicion.aparecer()
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
		l.texture_scale = 1.6
		l.energy = 0.4
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
	# Punta izquierda: el pasillo da vuelta hacia el ala oeste
	var o: Rect2 = _zonas["pasillo_oeste"]
	_puerta(Rect2(30, medio - 60, 60, 120), "ir", "pasillo_oeste", Vector2(o.get_center().x, o.end.y - 90))
	var vuelta := _interactuable(Rect2(o.position.x + o.size.x * 0.27, o.end.y - 80, o.size.x * 0.51, 50),
		"ir: Pasillo principal")
	vuelta.usado.connect(_cruzar.bind("pasillo", Vector2(100, medio + 30)))
	_conectar_ala_oeste()
	_puerta(Rect2(tam.size.x - 90, medio - 60, 60, 120), "entrar", PUNTA_DERECHA, _llegada(PUNTA_DERECHA, true))
	_puerta_cuarto(PUNTA_DERECHA, Vector2(tam.size.x - 100, medio + 30), true)
	# La entrada tiene además la puerta de vidrio que da al patio
	var salida := _interactuable(_zona_puerta("entrada", false), "salir al patio")
	salida.usado.connect(_salir_al_patio)


## Puerta en el pasillo que lleva a un cuarto. Si está cerrada, revisa la llave.
func _puerta(zona: Rect2, texto: String, destino: String, llegada: Vector2) -> void:
	var i := _interactuable(zona, texto + ": " + NOMBRES[destino])
	i.usado.connect(_intentar_puerta.bind(destino, llegada))


func _intentar_puerta(destino: String, llegada: Vector2) -> void:
	if CERRADAS.has(destino) and destino not in GameState.puertas_abiertas:
		var llave: String = CERRADAS[destino]
		if llave == "":
			_decir_lalo(["No abre. Algo la atora desde adentro.", "Está atascada.", "Cerrada. Ni se mueve."].pick_random())
			return
		if not GameState.tiene(llave):
			_decir_lalo("Está cerrada con llave.")
			return
		GameState.quitar(llave)
		GameState.puertas_abiertas.append(destino)
		hud.avisar("Usaste: " + GameState.objetos[llave]["nombre"])
	if _zonas.has(destino):
		_cruzar(destino, llegada)


func _decir_lalo(texto: String) -> void:
	if not Dialogos.activo:
		Dialogos.decir([{"quien": "Lalo", "voz": "lalo_angustia", "texto": texto}])


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
	_transicion.cruzar_a_escena("entrada", "puerta_medicina")


# ---------- Ala oeste ----------
func _armar_ala_oeste(pos: Vector2) -> void:
	var d: Dictionary = _datos["pasillo_oeste"]
	var tam := Vector2(d["tam"][0], d["tam"][1])
	_fondo("pasillo_oeste", pos)
	_zonas["pasillo_oeste"] = Rect2(pos, tam)
	var izq: float = tam.x * d["piso_x"][0]
	var der: float = tam.x * d["piso_x"][1]
	var muros := StaticBody2D.new()
	_forma(muros, Rect2(pos.x, pos.y, izq, tam.y))
	_forma(muros, Rect2(pos.x + der, pos.y, tam.x - der, tam.y))
	_forma(muros, Rect2(pos.x, pos.y, tam.x, 30))
	_forma(muros, Rect2(pos.x, pos.y + tam.y - 30, tam.x, 30))
	add_child(muros)
	var l := PointLight2D.new()   # una sola lámpara, la mitad del tiempo apagada
	l.texture = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	l.texture_scale = 1.4
	l.energy = 0.35
	l.color = Color(0.75, 1.0, 0.85)
	l.position = pos + tam / 2.0
	add_child(l)
	_parpadear(l)


func _conectar_ala_oeste() -> void:
	var d: Dictionary = _datos["pasillo_oeste"]
	var o: Rect2 = _zonas["pasillo_oeste"]
	var izq: float = o.position.x + o.size.x * d["piso_x"][0]
	var der: float = o.position.x + o.size.x * d["piso_x"][1]
	for i in 3:
		var y: float = o.position.y + o.size.y * d["puertas_y"][i]
		var id: String = OESTE_IZQUIERDA[i]
		if _zonas.has(id):   # Baños M: el único cuarto que abre en esta ala
			_puerta(Rect2(izq, y - 40, 44, 80), "entrar", id, _llegada(id, false))
			_puerta_cuarto(id, Vector2(izq + 40, y + 24))
		else:
			_puerta(Rect2(izq, y - 40, 44, 80), "entrar", id, Vector2.ZERO)
		_puerta(Rect2(der - 44, y - 40, 44, 80), "entrar", OESTE_DERECHA[i], Vector2.ZERO)
	_puerta(Rect2(izq, o.position.y + 30, der - izq, 50), "entrar", OESTE_FONDO, _llegada(OESTE_FONDO, false))
	_puerta_cuarto(OESTE_FONDO, Vector2(o.get_center().x, o.position.y + 130))


# ---------- Objetos para recoger ----------
func _armar_objetos() -> void:
	for o in OBJETOS_MAPA:
		if o[0] in GameState.recogidos:
			continue
		var z: Rect2 = _zonas[o[3]]
		_recogible(o[0], o[1], o[2], z.position + z.size * (o[4] as Vector2))


## Un objeto en el piso: un brillo que se ve aunque esté oscuro, y "E: recoger".
func _recogible(id_unico: String, objeto: String, cantidad: int, pos: Vector2) -> void:
	var brillo := Sprite2D.new()
	brillo.texture = load("res://assets/sprites/objetos/iconos/brillo.png") as Texture2D
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	brillo.material = material
	brillo.position = pos
	add_child(brillo)
	var t := brillo.create_tween().set_loops()
	t.tween_property(brillo, "modulate:a", 0.15, 0.7)
	t.tween_property(brillo, "modulate:a", 1.0, 0.7)
	var zona := _interactuable(Rect2(pos - Vector2(24, 24), Vector2(48, 48)), "recoger")
	zona.usado.connect(_recoger.bind(id_unico, objeto, cantidad, brillo, zona))


func _recoger(id_unico: String, objeto: String, cantidad: int, brillo: Sprite2D, zona: Interactuable) -> void:
	if objeto == "clavos":
		GameState.agregar_clavos(cantidad)
		hud.avisar("Recogiste: caja de clavos (+%d)" % cantidad)
	elif not GameState.agregar(objeto, cantidad):
		hud.avisar("La mochila está llena")
		return
	elif GameState.es_documento(objeto):
		hud.menu.leer(objeto)
	else:
		hud.avisar("Recogiste: " + GameState.objetos[objeto]["nombre"])
	GameState.recogidos.append(id_unico)
	var sonido := AudioStreamPlayer.new()
	sonido.stream = load("res://assets/audio/efectos/recoger.wav") as AudioStream
	add_child(sonido)
	sonido.play()
	brillo.queue_free()
	zona.queue_free()


# ---------- Cosas para examinar y emboscadas ----------
func _armar_examinables() -> void:
	for e in _dialogos.get("_examinar", []):
		var z: Rect2 = _zonas[e[0]]
		var pos: Vector2 = z.position + z.size * Vector2(e[1][0], e[1][1])
		var lineas: Array = []
		for texto in e[2]:
			lineas.append({"quien": "Lalo", "voz": "lalo_angustia", "texto": texto})
		var i := _interactuable(Rect2(pos - Vector2(36, 36), Vector2(72, 72)), "examinar")
		i.usado.connect(_examinar.bind(lineas))


func _examinar(lineas: Array) -> void:
	if not Dialogos.activo:
		Dialogos.decir(lineas)


func _armar_emboscadas() -> void:
	for e in EMBOSCADAS:
		if StringName(e[0]) in GameState.enemigos_eliminados:
			continue
		var z: Rect2 = _zonas[e[1]]
		var zona: Rect2 = e[2]
		var m := _maniqui(e[0], z.position + z.size * (e[3] as Vector2), true)
		var disparo := Area2D.new()
		disparo.collision_mask = 2
		_forma(disparo, Rect2(z.position + z.size * zona.position, z.size * zona.size))
		add_child(disparo)
		disparo.body_entered.connect(_saltar.bind(m, z.position + z.size * (e[3] as Vector2), disparo))


func _saltar(cuerpo: Node2D, m: Maniqui, pos: Vector2, disparo: Area2D) -> void:
	if not cuerpo is Lalo or not is_instance_valid(m):
		return
	disparo.queue_free()
	await get_tree().create_timer(0.5).timeout
	m.emboscar(pos)


# ---------- Lo que hay dentro ----------
func _armar_extras() -> void:
	_armar_objetos()
	_armar_examinables()
	_armar_emboscadas()
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
	subir.usado.connect(_usar_escaleras)
	# Maniquíes: uno en el pasillo y uno entre las camillas de la sala de simulación
	var p: Rect2 = _zonas["pasillo"]
	_maniqui("medicina_pasillo", p.position + Vector2(p.size.x * 0.14, p.size.y * 0.62))
	var s: Rect2 = _zonas["simulacion"]
	_maniqui("medicina_simulacion", s.position + Vector2(s.size.x * 0.5, s.size.y * 0.7))
	var w: Rect2 = _zonas["pasillo_oeste"]
	_maniqui("medicina_oeste", w.position + Vector2(w.size.x * 0.5, w.size.y * 0.45))


## La reja de la escalera: cerrada con cadena hasta tener la cizalla del cuarto de máquinas.
func _usar_escaleras() -> void:
	if Dialogos.activo:
		return
	if "escaleras" in GameState.puertas_abiertas:
		Dialogos.decir(_dialogos["escaleras_abiertas"])
	elif GameState.tiene("cizalla"):
		GameState.quitar("cizalla")
		GameState.puertas_abiertas.append("escaleras")
		Dialogos.decir(_dialogos["escaleras_cizalla"])
	else:
		Dialogos.decir(_dialogos["escaleras"])


func _maniqui(id: String, pos: Vector2, oculto: bool = false) -> Maniqui:
	if StringName(id) in GameState.enemigos_eliminados:
		return null
	var m := Maniqui.new()
	m.position = pos
	m.radio_despertar = 150.0
	m.objetivo = lalo
	m.oculto = oculto
	_mundo.add_child(m)
	m.derribado.connect(func() -> void: GameState.enemigos_eliminados.append(StringName(id)))
	return m


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
