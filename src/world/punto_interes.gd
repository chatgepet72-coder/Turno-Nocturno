extends Node2D
## Algo que se examina o se abre en el mundo: un reloj, una caja de llaves con candado...
## tipo "examinar": muestra `texto` en el cuadro de diálogo.
## tipo "candado": abre el candado de 4 números; con la combinación correcta entrega `premio`.
## tipo "cajon": un cajón de escritorio o cajonera; la primera vez da lo que tiene (`premio`, varios
##   separados por coma) y lee la nota que haya dentro (`texto`). Después queda vacío.
## tipo "mesa": la mesa de trabajo del cuarto seguro (guardar y fabricar).

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
		"cajon":
			return _revisar_cajon(jugador, escuela)
	return ""


## Mesa de trabajo del cuarto seguro: guardar y fabricar.
func _abrir_mesa(jugador: CharacterBody2D, escuela: Node) -> void:
	var inv: Array = jugador.inventario
	var opciones: Array = ["Guardar partida"]
	var receta: Array[String] = ["Alcohol", "Trapo", "Botella vacía"]
	var acciones: Array[Callable] = [func() -> void:
		jugador.mensaje = "Partida guardada." if escuela.guardar_partida() else "No se pudo guardar."
		escuela.sonidos.efecto("rele", Vector2.INF, -10.0)]
	if inv.has("Alcohol") and inv.has("Trapo") and inv.has("Botella vacía"):
		opciones.append("Fabricar molotov · botella + alcohol + trapo")
		acciones.append(func() -> void:
			for ingrediente in receta:
				inv.erase(ingrediente)
			inv.append("Molotov")
			escuela.sonidos.efecto("vidrio_roto", Vector2.INF, -18.0)
			jugador.mensaje = "Fabricaste una molotov. G / cruceta arriba para lanzarla.")
	var faltan: Array[String] = []
	for ingrediente in receta:
		if not inv.has(ingrediente):
			faltan.append(ingrediente.to_lower())
	var detalle := "Aquí no entra el Archivero ni nada de lo que camina allá afuera.\n"
	detalle += "Molotov: botella vacía + alcohol + trapo. " + ("Tienes todo." if faltan.is_empty() else "Te falta: " + ", ".join(faltan) + ".")
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


func _revisar_cajon(jugador: CharacterBody2D, escuela: Node) -> String:
	if abierto:
		return "Ya no hay nada aquí."
	var cosas: Array[String] = []
	for parte in premio.split(",", false):
		cosas.append(parte.strip_edges())
	var mochila = preload("res://src/player/mochila.gd")
	var prueba: Array = jugador.inventario.duplicate()
	for cosa in cosas:
		if not mochila.cabe(prueba, cosa):
			return "Hay algo dentro, pero la mochila está llena (6/6)."
		prueba.append(cosa)
	abierto = true
	escuela.recogidos.append(str(name))
	for cosa in cosas:
		jugador.inventario.append(cosa)
	escuela.sonidos.efecto("papel", global_position, -6.0)
	escuela.sonidos.efecto("recoger", global_position, -8.0)
	for linea in texto.split("\n", false):
		escuela.relato.decir(linea)
	if cosas.is_empty():
		return "Revisaste el cajón."
	return "Dentro del cajón: " + ", ".join(cosas)
