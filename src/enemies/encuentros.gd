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


func armar() -> void:
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemigos.json"))
	if not datos is Dictionary:
		push_error("encuentros: no se pudo leer data/enemigos.json")
		return
	for e in datos.get("enemigos", []):
		if not TIPOS.has(e.tipo):
			continue
		var enemigo: Enemigo = TIPOS[e.tipo].new()
		enemigo.id = e.id
		enemigo.escuela = escuela
		enemigo.name = "enemigo_" + e.id
		enemigo.position = Vector2(e.pos[0], e.pos[1])
		add_child(enemigo)
		if ("enemigo_" + e.id) in escuela.recogidos:
			enemigo.call_deferred("_quedar_clavado", false)
	var objetos: Node = escuela.get_node("Objetos")
	for o in datos.get("objetos", []):
		var nombre: String = "combate_" + o.id
		if nombre in escuela.recogidos or objetos.has_node(nombre):
			continue
		var r := preload("res://src/world/recogible.gd").new()
		r.name = nombre
		r.titulo = o.titulo
		r.icono = o.icono
		r.tamano = float(o.get("tamano", 18))
		r.position = Vector2(o.pos[0], o.pos[1])
		r.z_index = int(o.get("z", 0))
		objetos.add_child(r)


## Al cargar una partida: quita lo recogido y deja tirados a los que ya estaban clavados.
func aplicar_guardado() -> void:
	for nodo in escuela.get_node("Objetos").get_children():
		if str(nodo.name).begins_with("combate_") and str(nodo.name) in escuela.recogidos:
			nodo.queue_free()
	for e in get_children():
		if e is Enemigo and ("enemigo_" + e.id) in escuela.recogidos and e.estado != "CLAVADO":
			e._quedar_clavado(false)
