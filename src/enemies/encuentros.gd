extends Node2D
## Pone en el edificio principal a los enemigos y los objetos de combate de data/enemigos.json.
## Los enemigos clavados al piso y los objetos recogidos quedan en escuela.recogidos (se guardan).

const TIPOS: Dictionary = {
	"la_baja": preload("res://src/enemies/la_baja.gd"),
	"el_desvelado": preload("res://src/enemies/el_desvelado.gd"),
	"el_expediente": preload("res://src/enemies/el_expediente.gd"),
	"el_sinodal": preload("res://src/enemies/el_sinodal.gd"),
}

var escuela: Node2D
var _pendientes: Array = []      # enemigos del archivo que todavía no aparecen
var _reloj: float = 0.0


func armar() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemigos.json"))
	if not datos is Dictionary:
		push_error("encuentros: no se pudo leer data/enemigos.json")
		return
	_pendientes = datos.get("enemigos", []).duplicate()
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
	if escuela == null or not escuela.jugando or _pendientes.is_empty():
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
