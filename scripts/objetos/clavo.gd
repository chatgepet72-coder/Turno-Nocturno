class_name Clavo
extends Area2D
## Clavo disparado por la pistola: vuela recto, se clava en el primer enemigo o pared que toque.

const VELOCIDAD: float = 520.0
const DURACION: float = 0.7

var direccion: Vector2 = Vector2.RIGHT
var _restante: float = DURACION


func _ready() -> void:
	collision_layer = 8          # proyectiles
	collision_mask = 1 | 4       # mundo y enemigos
	rotation = direccion.angle()
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/objetos/clavo.png") as Texture2D
	add_child(s)
	var forma := CircleShape2D.new()
	forma.radius = 4.0
	var cs := CollisionShape2D.new()
	cs.shape = forma
	add_child(cs)
	body_entered.connect(_al_chocar)
	area_entered.connect(_al_tocar_area)


func _physics_process(delta: float) -> void:
	position += direccion * VELOCIDAD * delta
	_restante -= delta
	if _restante <= 0.0:
		queue_free()


func _al_chocar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("recibir_clavo"):
		cuerpo.recibir_clavo(direccion)
	queue_free()


## Zonas que reciben daño (el cuerpo completo de los enemigos).
func _al_tocar_area(area: Area2D) -> void:
	var dueno: Node = area.get_parent()
	if dueno != null and dueno.has_method("recibir_clavo"):
		dueno.recibir_clavo(direccion)
		queue_free()
