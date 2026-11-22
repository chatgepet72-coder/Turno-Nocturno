extends Node2D
## Objeto suelto para recoger (pistola de clavos, cajas de clavos). Vive en `Objetos` para que el
## guardado lo quite si ya se recogió (escuela.recogidos guarda su nombre).

@export var titulo: String = "Caja de clavos"
@export var icono: String = "res://assets/sprites/caja.png"
@export var tamano: float = 20.0      # alto en pantalla del dibujo
var tipo: String = "recoger"
var abierto: bool = false


func _ready() -> void:
	add_to_group("interactivos")
	var s := Sprite2D.new()
	s.texture = load(icono) as Texture2D
	if s.texture != null:
		s.scale = Vector2.ONE * (tamano / maxf(s.texture.get_height(), 1.0))
	s.offset.y = -s.texture.get_height() * 0.5 if s.texture != null else 0.0
	add_child(s)


func interactuar(jugador: CharacterBody2D) -> String:
	var escuela: Node = get_tree().get_first_node_in_group("control")
	if not preload("res://src/player/mochila.gd").cabe(jugador.inventario, titulo):
		return "Mochila llena (6/6). Consume o descarta un suministro con I / Y."
	escuela.recogidos.append(str(name))
	jugador.inventario.append(titulo)
	escuela.sonidos.efecto("recoger", global_position)
	queue_free()
	if titulo == "Pistola de clavos":
		escuela.anunciar("PISTOLA DE CLAVOS", "Clic izquierdo / RT para disparar · R / cruceta abajo para recargar")
		return "Recogido: Pistola de clavos (10 clavos cargados)"
	return "Recogido: " + titulo
