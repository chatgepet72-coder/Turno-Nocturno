extends Node2D
## Un clavo disparado: vuela recto, revisa con un rayo cada cuadro y pega al primer enemigo o pared.

const VELOCIDAD: float = 900.0
const ALCANCE: float = 520.0
const CAPA_PAREDES: int = 1
const CAPA_CUERPOS: int = 8   # zona de golpe de los enemigos (Area2D "Cuerpo")

var escuela: Node2D
var direccion := Vector2.RIGHT
## Primera persona: inclinación de la mira (radianes, negativo = hacia el piso). El clavo baja
## y, donde toca el piso, pega a lo que esté tirado ahí (o se clava en el piso).
var inclinacion: float = 0.0
const OJOS_PX: float = 1.55 * 44.0   # altura de la mira en píxeles del mapa
var altura: float = OJOS_PX
var _recorrido: float = 0.0
var _clavado: float = -1.0


func _ready() -> void:
	z_index = 6
	rotation = direccion.angle()
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/armas/clavo.png") as Texture2D
	s.scale = Vector2(1.4, 1.4)
	add_child(s)


func _physics_process(delta: float) -> void:
	if _clavado >= 0.0:
		_clavado += delta
		modulate.a = clampf(2.0 - _clavado, 0.0, 1.0)
		if _clavado > 2.0:
			queue_free()
		return
	var paso: Vector2 = direccion * VELOCIDAD * delta
	if inclinacion < -0.02:
		var al_piso: float = altura / tan(-inclinacion)   # distancia hasta tocar el piso
		if al_piso <= paso.length():
			var punto: Vector2 = global_position + direccion * al_piso
			var choque_corto := _primer_choque(punto)
			if choque_corto.is_empty():
				global_position = punto
				altura = 0.0
				_pegar_en_el_piso()
				return
			paso = direccion * al_piso
		altura -= paso.length() * tan(-inclinacion)
	var choque := _primer_choque(global_position + paso)
	if not choque.is_empty():
		global_position = choque.position
		var cuerpo: Object = choque.collider
		var enemigo: Node = (cuerpo as Node).get_parent() if cuerpo is Area2D else cuerpo
		if enemigo is Enemigo:
			(enemigo as Enemigo).recibir_clavo(direccion)
			queue_free()
		else:
			escuela.sonidos.efecto("clavo_impacto", global_position, -10.0)
			_clavado = 0.0   # se queda clavado en la pared un momento
		return
	global_position += paso
	_recorrido += paso.length()
	if _recorrido > ALCANCE:
		queue_free()


## Lo más cercano entre paredes/muebles (cuerpos de la capa 1) y zonas de golpe de enemigos (áreas de la capa 8).
func _primer_choque(hasta: Vector2) -> Dictionary:
	var espacio := get_world_2d().direct_space_state
	var paredes := PhysicsRayQueryParameters2D.create(global_position, hasta, CAPA_PAREDES, [escuela.jugador.get_rid()])
	var cuerpos := PhysicsRayQueryParameters2D.create(global_position, hasta, CAPA_CUERPOS)
	cuerpos.collide_with_areas = true
	cuerpos.collide_with_bodies = false
	var a := espacio.intersect_ray(paredes)
	var b := espacio.intersect_ray(cuerpos)
	if a.is_empty():
		return b
	if b.is_empty():
		return a
	return a if global_position.distance_to(a.position) < global_position.distance_to(b.position) else b


## El clavo tocó el piso: si hay un enemigo tirado ahí, le pega; si no, se queda clavado en el piso.
func _pegar_en_el_piso() -> void:
	for e in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := e as Enemigo
		if enemigo != null and enemigo.estado == "CAIDO" and enemigo.visible:
			var cuerpo := enemigo.get_node("Cuerpo") as Node2D
			var centro: Vector2 = (cuerpo.get_child(0) as Node2D).global_position
			if global_position.distance_to(centro) < 46.0 or global_position.distance_to(enemigo.global_position) < 40.0:
				enemigo.recibir_clavo(direccion)
				queue_free()
				return
	escuela.sonidos.efecto("clavo_impacto", global_position, -12.0)
	_clavado = 0.0
