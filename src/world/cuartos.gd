extends Node2D
## Cuartos del edificio principal al estilo Resident Evil:
## - Solo se ve el cuarto donde está Lalo; los demás quedan en negro.
## - Las puertas no se abren a la vista: al usarlas, la pantalla se va a negro con la
##   transición de puerta y Lalo aparece del otro lado.
## Los cuartos salen de los pisos de la escena (`Pisos/*`); el pasillo es la unión de `Pasillo_*`.

const DISTANCIA_LLEGADA: float = 58.0   # qué tan adentro del cuarto aparece Lalo al cruzar
const NOMBRES: Dictionary = {
	"Pasillo": "Pasillo", "Computo": "Laboratorio de Cómputo", "Auditorio": "Auditorio",
	"Entrada": "Entrada", "Direccion": "Dirección", "Rectoria_Archivo": "Rectoría y Archivo",
	"Taller": "Taller", "Bano_H": "Baño de hombres", "Bano_M": "Baño de mujeres",
}

var escuela: Node2D
var cuartos: Dictionary = {}       # nombre -> Rect2 en coordenadas del mundo
var actual: String = ""
var transicion: CanvasLayer


func _ready() -> void:
	z_as_relative = false
	z_index = 200   # por encima de muebles y personajes
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el negro no se aclara con la linterna
	material = sin_luz
	var pasillo := Rect2()
	var hay_pasillo := false
	for piso in escuela.get_node("Pisos").get_children():
		var sprite := piso as Sprite2D
		if sprite == null:
			continue
		var rect: Rect2 = sprite.get_global_transform() * sprite.get_rect()
		if str(sprite.name).begins_with("Pasillo"):
			pasillo = rect if not hay_pasillo else pasillo.merge(rect)
			hay_pasillo = true
		else:
			cuartos[str(sprite.name)] = rect
	if hay_pasillo:
		cuartos["Pasillo"] = pasillo
	transicion = preload("res://src/ui/transicion_puerta.gd").new()
	add_child(transicion)


## Quita los letreros escritos sobre el piso (nombres de cuartos, "TABLERO PRINCIPAL"...).
## El nombre del cuarto aparece un momento al cruzar la puerta. Los rombos ◇ de los objetos se quedan.
func ocultar_rotulos() -> void:
	for nodo in escuela.find_children("*", "Label", true, false):
		var rotulo := nodo as Label
		if rotulo.text.strip_edges() == "◇" or _en_interfaz(rotulo):
			continue
		rotulo.visible = false


func _en_interfaz(nodo: Node) -> bool:
	var padre := nodo.get_parent()
	while padre != null:
		if padre is CanvasLayer:
			return true
		padre = padre.get_parent()
	return false


func activo() -> bool:
	return escuela.campana.lugar == "principal"


func cuarto_en(punto: Vector2) -> String:
	for nombre in cuartos:
		if (cuartos[nombre] as Rect2).has_point(punto):
			return nombre
	return ""


func nombre_visible(cuarto: String) -> String:
	if NOMBRES.has(cuarto):
		return NOMBRES[cuarto]
	return cuarto.replace("_", " ")


func _process(_delta: float) -> void:
	visible = activo()
	if not visible:
		return
	var aqui := cuarto_en(escuela.jugador.global_position)
	if aqui != "" and aqui != actual:
		actual = aqui
		queue_redraw()


func _draw() -> void:
	if actual == "":
		return
	for nombre in cuartos:
		if nombre != actual:
			draw_rect(cuartos[nombre], Color.BLACK)


## Lo llama una puerta cuando Lalo la usa. Devuelve false si no se pudo cruzar (para el mensaje).
func cruzar(puerta: Node2D) -> bool:
	if not activo() or transicion.activa:
		return false
	var jugador: CharacterBody2D = escuela.jugador
	var lado: float = -1.0 if jugador.global_position.y > puerta.global_position.y else 1.0
	var destino := _llegada_libre(puerta.global_position, lado)
	if destino == Vector2.INF:
		return false
	escuela.jugando = false
	escuela.emitir_ruido(puerta.global_position, 0.35)
	await transicion.cruzar(func() -> void:
		jugador.global_position = destino
		jugador.velocity = Vector2.ZERO
		var camara := jugador.get_node("Camera2D") as Camera2D
		camara.reset_smoothing()
		actual = cuarto_en(destino)
		queue_redraw()
	, func(efecto: String) -> void: escuela.sonidos.efecto(efecto, Vector2.INF, -4.0 if efecto == "puerta" else -10.0))
	escuela.jugando = true
	jugador.mensaje = nombre_visible(actual)
	return true


## Busca un punto libre del otro lado de la puerta (sin muebles encima).
func _llegada_libre(origen: Vector2, lado: float) -> Vector2:
	var jugador: CharacterBody2D = escuela.jugador
	var colision := jugador.get_node("Colision") as CollisionShape2D
	var forma: Shape2D = colision.shape
	var espacio := jugador.get_world_2d().direct_space_state
	for extra in [0.0, 18.0, 36.0, 54.0]:
		for dx in [0.0, -28.0, 28.0, -56.0, 56.0]:
			var punto: Vector2 = origen + Vector2(dx, lado * (DISTANCIA_LLEGADA + extra))
			var consulta := PhysicsShapeQueryParameters2D.new()
			consulta.shape = forma
			consulta.transform = Transform2D(0.0, punto + colision.position)
			consulta.collision_mask = jugador.collision_mask
			consulta.exclude = [jugador.get_rid()]
			if espacio.intersect_shape(consulta, 1).is_empty():
				return punto
	return Vector2.INF
