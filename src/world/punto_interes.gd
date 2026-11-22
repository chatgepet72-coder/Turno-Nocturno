extends Node2D
## Algo que se examina o se abre en el mundo: un reloj, una caja de llaves con candado...
## tipo "examinar": muestra `texto` en el cuadro de diálogo.
## tipo "candado": abre el candado de 4 números; con la combinación correcta entrega `premio`.

@export var titulo: String = "Examinar"
@export var tipo: String = "examinar"
@export var icono: String = ""
@export var tamano: float = 24.0
@export var texto: String = ""
@export var combinacion: String = ""
@export var premio: String = ""
var abierto: bool = false


func _ready() -> void:
	add_to_group("interactivos")
	if icono != "":
		var s := Sprite2D.new()
		s.texture = load(icono) as Texture2D
		if s.texture != null:
			s.scale = Vector2.ONE * (tamano / maxf(s.texture.get_height(), 1.0))
		add_child(s)


func interactuar(jugador: CharacterBody2D) -> String:
	var escuela: Node = get_tree().get_first_node_in_group("control")
	match tipo:
		"examinar":
			for linea in texto.split("\n"):
				escuela.relato.decir("LALO · " + linea)
			return ""
		"candado":
			if abierto:
				return "La caja ya está abierta. Está vacía."
			var candado := preload("res://src/ui/candado.gd").new()
			candado.escuela = escuela
			candado.combinacion = combinacion
			candado.titulo = titulo
			candado.abierto_con_exito.connect(_abrir.bind(jugador, escuela))
			escuela.add_child(candado)
			return ""
		"mesa":
			_abrir_mesa(jugador, escuela)
			return ""
	return ""


## Mesa de trabajo del cuarto seguro: guardar y fabricar.
func _abrir_mesa(jugador: CharacterBody2D, escuela: Node) -> void:
	var inv: Array = jugador.inventario
	var opciones: Array = ["Guardar partida"]
	var acciones: Array[Callable] = [func() -> void:
		jugador.mensaje = "Partida guardada." if escuela.guardar_partida() else "No se pudo guardar."
		escuela.sonidos.efecto("rele", Vector2.INF, -10.0)]
	if inv.has("Alcohol") and inv.has("Trapo"):
		opciones.append("Fabricar molotov · alcohol + trapo")
		acciones.append(func() -> void:
			inv.erase("Alcohol")
			inv.erase("Trapo")
			inv.append("Molotov")
			escuela.sonidos.efecto("vidrio_roto", Vector2.INF, -18.0)
			jugador.mensaje = "Fabricaste una molotov. G / cruceta arriba para lanzarla.")
	var faltan: Array[String] = []
	for ingrediente in ["Alcohol", "Trapo"]:
		if not inv.has(ingrediente):
			faltan.append(ingrediente.to_lower())
	var detalle := "Aquí no entra el Archivero ni nada de lo que camina allá afuera.\n"
	detalle += "Molotov: alcohol + trapo. " + ("Tienes todo." if faltan.is_empty() else "Te falta: " + ", ".join(faltan) + ".")
	escuela.interfaz.elegir("MESA DE TRABAJO", detalle, opciones, func(i: int) -> void:
		if i >= 0 and i < acciones.size():
			acciones[i].call())


func _abrir(jugador: CharacterBody2D, escuela: Node) -> void:
	abierto = true
	titulo = "Caja de llaves (abierta)"
	escuela.recogidos.append(str(name))   # se guarda abierta
	if premio != "" and not jugador.inventario.has(premio):
		jugador.inventario.append(premio)
	escuela.sonidos.efecto("recoger", global_position)
	escuela.anunciar(premio.to_upper(), "La caja de conserjería se abrió.")
	jugador.mensaje = "Recogido: " + premio
