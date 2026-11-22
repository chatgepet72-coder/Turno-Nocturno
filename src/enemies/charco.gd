extends Node2D
## Charco negro que deja el termo del Desvelado. Mientras Lalo lo pisa, la Cordura le sigue bajando.

const DURACION: float = 5.0
const DANO_POR_SEGUNDO: float = 4.0
const RADIO: float = 34.0
var _tiempo: float = 0.0


func _ready() -> void:
	z_index = 1


func _physics_process(delta: float) -> void:
	var escuela: Node2D = get_tree().get_first_node_in_group("control")
	if escuela == null or not escuela.jugando:
		return
	_tiempo += delta
	if _tiempo >= DURACION:
		queue_free()
		return
	var j: CharacterBody2D = escuela.jugador
	if not j.oculto and global_position.distance_to(j.global_position) < RADIO:
		j.cordura = maxf(0.0, j.cordura - DANO_POR_SEGUNDO * delta)
		if j.cordura <= 0.0:
			escuela.archivar()
	modulate.a = clampf((DURACION - _tiempo) / 1.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIO, Color(0.03, 0.02, 0.015, 0.75))
	draw_circle(Vector2(12, 6), RADIO * 0.45, Color(0.03, 0.02, 0.015, 0.75))
