extends Node2D
## Lo que avientan los enemigos: tinta (La Baja), termo (El Desvelado), hojas (El Expediente)
## y exámenes reprobados (El Sinodal). Se dibuja con código; choca con paredes y muebles.

var escuela: Node2D
var clase: String = "tinta"     # tinta, termo, hoja, examen, silla, libro (La Baja los avienta)
var velocidad := Vector2.ZERO
var dano: float = 5.0
var vida: float = 2.0
var giro: float = 0.0
# El termo vuela en arco hasta un punto y salpica al caer
var arco_desde := Vector2.ZERO
var arco_hasta := Vector2.ZERO
var arco_tiempo: float = 0.0
var arco_total: float = 0.8
var _altura: float = 0.0


func _ready() -> void:
	z_index = 6
	if clase == "termo":
		arco_desde = global_position
		var icono := Sprite2D.new()
		icono.texture = load("res://assets/sprites/termo.png") as Texture2D
		icono.scale = Vector2.ONE * (22.0 / maxf(icono.texture.get_height(), 1.0))
		icono.name = "Icono"
		add_child(icono)


func _physics_process(delta: float) -> void:
	if not escuela.jugando:
		return
	if clase == "termo":
		_volar_en_arco(delta)
		return
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	var siguiente: Vector2 = global_position + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(global_position, siguiente, 1, [escuela.jugador.get_rid()])
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		if clase in ["silla", "libro"]:
			escuela.sonidos.efecto("golpe", global_position, -4.0)
			escuela.sonidos.efecto("metal", global_position, -10.0)
		queue_free()
		return
	global_position = siguiente
	rotation += giro * delta
	var j: CharacterBody2D = escuela.jugador
	if not j.oculto and global_position.distance_to(j.global_position + Vector2(0, -20)) < 18.0:
		_pegar(j)
		queue_free()
	queue_redraw()


func _volar_en_arco(delta: float) -> void:
	arco_tiempo += delta
	var t: float = clampf(arco_tiempo / arco_total, 0.0, 1.0)
	global_position = arco_desde.lerp(arco_hasta, t)
	_altura = sin(t * PI) * 60.0
	var icono := get_node("Icono") as Sprite2D
	icono.position.y = -_altura
	icono.rotation = t * TAU * 1.5
	queue_redraw()
	if t >= 1.0:
		# Salpica café negro: pega si Lalo está cerca de donde cae
		escuela.sonidos.efecto("vidrio_roto", global_position, -6.0)
		var j: CharacterBody2D = escuela.jugador
		if not j.oculto and global_position.distance_to(j.global_position) < 46.0:
			_pegar(j)
		var charco := Node2D.new()
		charco.set_script(load("res://src/enemies/charco.gd"))
		charco.global_position = global_position
		get_parent().add_child(charco)
		queue_free()


func _pegar(j: CharacterBody2D) -> void:
	j.cordura = maxf(0.0, j.cordura - dano)
	_vibrar(0.3, 0.12)
	match clase:
		"tinta":
			j.mancha = 4.0   # la linterna queda manchada y alumbra menos
			j.mensaje = "Tinta en la linterna. Alumbra menos un momento."
		"examen":
			j.mensaje = "REPROBADO"
	if clase in ["silla", "libro"]:
		j.mensaje = "¡Te pegó con lo que aventó!"
		var vista: Variant = escuela.get("vista_fp")
		if vista != null and vista.activa:
			vista.sacudir(0.8)
	escuela.sonidos.efecto("papel" if clase in ["hoja", "examen"] else "golpe", Vector2.INF, -8.0)
	if j.cordura <= 0.0:
		escuela.archivar()


func _draw() -> void:
	match clase:
		"tinta":
			draw_circle(Vector2.ZERO, 5.0, Color(0.02, 0.02, 0.03))
			draw_circle(Vector2(-6, 0).rotated(velocidad.angle()), 3.0, Color(0.02, 0.02, 0.03, 0.7))
		"hoja":
			draw_rect(Rect2(-7, -5, 14, 10), Color(0.92, 0.9, 0.82))
			draw_line(Vector2(-5, -2), Vector2(5, -2), Color(0.4, 0.4, 0.45), 1.0)
			draw_line(Vector2(-5, 1), Vector2(4, 1), Color(0.4, 0.4, 0.45), 1.0)
		"examen":
			draw_rect(Rect2(-8, -6, 16, 12), Color(0.94, 0.92, 0.85))
			draw_line(Vector2(-6, -4), Vector2(6, 4), Color(0.8, 0.1, 0.1), 1.5)
			draw_line(Vector2(6, -4), Vector2(-6, 4), Color(0.8, 0.1, 0.1), 1.5)
		"silla":
			draw_rect(Rect2(-9, -8, 18, 16), Color(0.45, 0.3, 0.18))
			draw_rect(Rect2(-9, -8, 18, 4), Color(0.3, 0.2, 0.12))
		"libro":
			draw_rect(Rect2(-6, -8, 12, 16), Color(0.35, 0.08, 0.06))
		"termo":
			# Sombra en el piso mientras vuela
			draw_circle(Vector2.ZERO, lerpf(6.0, 10.0, 1.0 - _altura / 60.0), Color(0, 0, 0, 0.35))


func _vibrar(fuerza: float, duracion: float) -> void:
	var c: Node = get_node_or_null("/root/Controles")
	if c != null:
		c.vibrar(fuerza, duracion)
