extends Node2D
## Pone en el edificio principal a los enemigos y los objetos de combate de data/enemigos.json.
## Los enemigos clavados al piso y los objetos recogidos quedan en escuela.recogidos (se guardan).

const TIPOS: Dictionary = {
	"la_baja": preload("res://src/enemies/la_baja.gd"),
	"el_desvelado": preload("res://src/enemies/el_desvelado.gd"),
	"el_expediente": preload("res://src/enemies/el_expediente.gd"),
	"el_sinodal": preload("res://src/enemies/el_sinodal.gd"),
	"el_pupitre": preload("res://src/enemies/el_pupitre.gd"),
}

var escuela: Node2D
var _pendientes: Array = []      # enemigos del archivo que todavía no aparecen
var _reloj: float = 0.0
# Encierros (data/enemigos.json → "encierros"): al entrar a un cuarto, las puertas se traban
# y salen los enemigos; se destraban cuando todos quedan clavados o quemados.
var _encierros: Array = []
var encierro_activo: Dictionary = {}   # {"id", "cuarto", "enemigos": Array[Enemigo]}
var _sin_municion: float = 0.0
var _cuarto_previo: String = ""


func armar() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemigos.json"))
	if not datos is Dictionary:
		push_error("encuentros: no se pudo leer data/enemigos.json")
		return
	_pendientes = datos.get("enemigos", []).duplicate()
	_encierros = datos.get("encierros", []).duplicate()
	_revisar_apariciones()
	var objetos: Node = escuela.get_node("Objetos")
	for o in datos.get("objetos", []):
		var nombre: String = "combate_" + o.id
		if objetos.has_node(nombre):
			continue
		if nombre in escuela.recogidos and o.get("clase", "recogible") != "punto":
			continue   # ya recogido (los puntos se quedan; la caja abierta se marca al cargar)
		var r: Node2D
		if o.get("clase", "recogible") == "punto":
			r = preload("res://src/world/punto_interes.gd").new()
			r.tipo = o.get("tipo", "examinar")
			r.texto = o.get("texto", "")
			r.combinacion = o.get("combinacion", "")
			r.premio = o.get("premio", "")
		else:
			r = preload("res://src/world/recogible.gd").new()
			r.texto = o.get("texto", "")
		r.name = nombre
		if o.get("clase", "recogible") == "punto" and nombre in escuela.recogidos:
			r.abierto = true   # cajón ya revisado / caja ya abierta en esta partida
		r.titulo = o.titulo
		r.icono = o.icono
		r.tamano = float(o.get("tamano", 18))
		r.position = Vector2(o.pos[0], o.pos[1])
		r.z_index = int(o.get("z", 0))
		objetos.add_child(r)


func _process(delta: float) -> void:
	if escuela == null or not escuela.jugando:
		return
	_revisar_encierros(delta)
	if _pendientes.is_empty():
		return
	_reloj -= delta
	if _reloj <= 0.0:
		_reloj = 1.0
		_revisar_apariciones()


## Los enemigos aparecen conforme avanza la historia, y nunca frente a Lalo.
func _revisar_apariciones() -> void:
	for e in _pendientes.duplicate():
		if not TIPOS.has(e.tipo):
			_pendientes.erase(e)
			continue
		if not _cumple(str(e.get("aparece", "inicio"))):
			continue
		var pos := Vector2(e.pos[0], e.pos[1])
		var lugar: String = e.get("lugar", "principal")
		if _lo_veria_aparecer(pos, lugar):
			continue
		_pendientes.erase(e)
		var enemigo: Enemigo = TIPOS[e.tipo].new()
		enemigo.id = e.id
		enemigo.lugar = lugar
		enemigo.territorio = float(e.get("territorio", 0.0))
		if e.has("huye_a"):
			enemigo.set("huye_a", Vector2(e.huye_a[0], e.huye_a[1]))   # solo se deja ver y huye
		enemigo.escuela = escuela
		enemigo.name = "enemigo_" + e.id
		enemigo.position = pos
		add_child(enemigo)
		if ("enemigo_" + e.id) in escuela.recogidos:
			enemigo.call_deferred("_quedar_clavado", false)


## Solo para pruebas: hace aparecer a todos sin esperar el avance.
func forzar_todos() -> void:
	for e in _pendientes:
		e["aparece"] = "inicio"
	_lo_veria_aparecer_desactivado = true
	_revisar_apariciones()
	_lo_veria_aparecer_desactivado = false


var _lo_veria_aparecer_desactivado: bool = false


func _cumple(condicion: String) -> bool:
	var partes := condicion.split(":", true, 1)
	var valor: String = partes[1] if partes.size() > 1 else ""
	match partes[0]:
		"inicio":
			return true
		"zona":
			return bool(escuela.zonas.get(valor, false)) and escuela.partida_iniciada and escuela.tiempo > 1.0
		"hecho":
			return bool(escuela.campana.hechos.get(valor, false))
		"etapa":
			return int(escuela.campana.etapa) >= int(valor)
		"objeto":
			return escuela.jugador.inventario.has(valor)
	return false


## Si Lalo está en el mismo cuarto (o a la vista, afuera), espera: no aparece de la nada frente a él.
func _lo_veria_aparecer(pos: Vector2, lugar: String) -> bool:
	if _lo_veria_aparecer_desactivado or escuela.campana.lugar != lugar or not escuela.partida_iniciada:
		return false
	var j: Vector2 = escuela.jugador.global_position
	if lugar == "principal" and escuela.cuartos != null:
		return escuela.cuartos.cuarto_en(j) == escuela.cuartos.cuarto_en(pos)
	return absf(pos.x - j.x) < 540.0 and absf(pos.y - j.y) < 310.0


## Al cargar una partida: quita lo recogido y deja tirados a los que ya estaban clavados.
func aplicar_guardado() -> void:
	for nodo in escuela.get_node("Objetos").get_children():
		if str(nodo.name).begins_with("combate_") and str(nodo.name) in escuela.recogidos:
			nodo.queue_free()
	for e in get_children():
		if e is Enemigo and ("enemigo_" + e.id) in escuela.recogidos and e.estado != "CLAVADO":
			e._quedar_clavado(false)


# ---------- Encierros ----------
## El cuarto trabado ahora mismo ("" si ninguno). cuartos.cruzar() no deja salir de él.
func cuarto_cerrado() -> String:
	return str(encierro_activo.get("cuarto", ""))


func _revisar_encierros(delta: float) -> void:
	var c: Node = escuela.cuartos
	if c == null or not c.activo():
		return
	if not encierro_activo.is_empty():
		_seguir_encierro(delta)
		return
	var aqui: String = c.cuarto_en(escuela.jugador.global_position)
	if aqui == _cuarto_previo or aqui == "":
		return
	_cuarto_previo = aqui
	for en in _encierros:
		if escuela.campana.hechos.get("encierro_" + str(en.id), false):
			continue
		var cuarto: String = en.get("cuarto", "*")
		if cuarto == "*":
			if aqui in en.get("excluye", []):
				continue
		elif cuarto != aqui:
			continue
		if not _cumple(str(en.get("requiere", "inicio"))):
			continue
		_empezar_encierro(en, aqui)
		return


func _empezar_encierro(en: Dictionary, cuarto: String) -> void:
	var j: CharacterBody2D = escuela.jugador
	var rect: Rect2 = escuela.cuartos.cuartos[cuarto]
	var lista: Array[Enemigo] = []
	var usados: Array[Vector2] = []
	for k in en.get("enemigos", []).size():
		var datos_e: Dictionary = en.enemigos[k]
		var pos := _punto_lejos(rect, j.global_position, usados)
		usados.append(pos)
		var e: Enemigo = TIPOS[datos_e.tipo].new()
		e.id = "encierro_%s_%d" % [en.id, k]
		e.escuela = escuela
		e.name = "enemigo_" + e.id
		e.position = pos
		add_child(e)
		lista.append(e)
		# Sale de entre los muebles: empieza tirado y se levanta (uno detrás de otro)
		e.call_deferred("aparecer_agazapado", 1.4 + k * 1.6)
	encierro_activo = {"id": str(en.id), "cuarto": cuarto, "enemigos": lista}
	_sin_municion = 0.0
	escuela.sonidos.efecto("puerta", j.global_position, 0.0)
	escuela.sonidos.efecto("metal", j.global_position, -2.0)
	escuela.sonidos.efecto("grito", rect.get_center(), -6.0)
	j.mensaje = str(en.get("aviso", "La puerta se cerró de golpe. No abre."))
	var vista: Variant = escuela.get("vista_fp")
	if vista != null and vista.activa:
		vista.sacudir(0.5)
	var controles: Node = get_node_or_null("/root/Controles")
	if controles != null:
		controles.vibrar(0.6, 0.25)


func _seguir_encierro(delta: float) -> void:
	var vivos := 0
	var tirados := 0
	for e in encierro_activo.enemigos:
		if not is_instance_valid(e) or e.estado == "CLAVADO":
			continue
		vivos += 1
		if e.estado == "CAIDO":
			tirados += 1
	# Sin clavos ni molotovs y con todos tirados: que no se quede atorado para siempre
	var j: CharacterBody2D = escuela.jugador
	var arma: Node = j.get_node_or_null("PistolaClavos")
	var sin_nada: bool = (arma == null or (arma.cargados <= 0 and not j.inventario.has("Caja de clavos"))) and not j.inventario.has("Molotov")
	_sin_municion = _sin_municion + delta if sin_nada and tirados == vivos else 0.0
	if vivos == 0 or _sin_municion > 3.0 or escuela.modo_prueba and Input.is_key_pressed(KEY_F10):
		_terminar_encierro()


func _terminar_encierro() -> void:
	escuela.campana.hechos["encierro_" + str(encierro_activo.id)] = true
	encierro_activo = {}
	escuela.sonidos.efecto("interruptor", Vector2.INF, -6.0)
	escuela.sonidos.efecto("puerta", Vector2.INF, -10.0)
	escuela.jugador.mensaje = "Clac. La puerta se destrabó."


## Un punto libre del cuarto, lo más lejos posible de Lalo (y de los otros que salen).
func _punto_lejos(rect: Rect2, desde: Vector2, evitar: Array[Vector2]) -> Vector2:
	var mejor := rect.get_center()
	var mejor_d := -1.0
	var espacio := get_world_2d().direct_space_state
	var forma := CircleShape2D.new()
	forma.radius = 16.0
	for fy in [0.3, 0.5, 0.7]:
		for fx in [0.15, 0.3, 0.5, 0.7, 0.85]:
			var p := rect.position + rect.size * Vector2(fx, fy)
			var consulta := PhysicsShapeQueryParameters2D.new()
			consulta.shape = forma
			consulta.transform = Transform2D(0.0, p)
			consulta.collision_mask = 1
			if not espacio.intersect_shape(consulta, 1).is_empty():
				continue
			var d: float = p.distance_to(desde)
			for o in evitar:
				d = minf(d, p.distance_to(o) * 2.0)
			if d > mejor_d:
				mejor_d = d
				mejor = p
	return mejor
