extends Node2D
## Un clavo disparado: vuela recto, revisa con un rayo cada cuadro y pega al primer enemigo o pared.

const VELOCIDAD: float = 900.0
const ALCANCE: float = 520.0
const CAPA_PAREDES: int = 1
const CAPA_CUERPOS: int = 8   # zona de golpe de los enemigos (Area2D "Cuerpo")

var escuela: Node2D
var direccion := Vector2.RIGHT
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
