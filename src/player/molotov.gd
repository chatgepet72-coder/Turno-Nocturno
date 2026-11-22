extends Node2D
## Molotov (traída de nuestra versión): vuela en arco hasta `destino`, se rompe y deja fuego unos segundos.
## Los enemigos de papel que pisan el fuego arden y ya no regresan. El ruido atrae al Archivero.

const RADIO: float = 58.0
const DURACION_FUEGO: float = 4.5
const VUELO: float = 0.55

var escuela: Node2D
var destino: Vector2
var _botella: Polygon2D
var _quemados: Array[Node] = []


func _ready() -> void:
	z_index = 6
	_botella = Polygon2D.new()
	_botella.polygon = PackedVector2Array([Vector2(-3, -7), Vector2(3, -7), Vector2(4, 6), Vector2(-4, 6)])
	_botella.color = Color(0.45, 0.6, 0.4)
	add_child(_botella)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", destino, VUELO)
	t.tween_property(_botella, "rotation", TAU * 2.0, VUELO)
	t.tween_method(func(p: float) -> void: _botella.position.y = -sin(p * PI) * 46.0, 0.0, 1.0, VUELO)
	await t.finished
	_explotar()


func _explotar() -> void:
	_botella.queue_free()
	escuela.sonidos.efecto("vidrio_roto", global_position, 0.0)
	escuela.sonidos.efecto("fuego", global_position, -4.0)
	escuela.emitir_ruido(global_position, 1.1)
	var luz := PointLight2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0, 0, 0, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	luz.texture = tex
	luz.energy = 1.5
	luz.color = Color(1.0, 0.55, 0.15)
	add_child(luz)
	var particulas := CPUParticles2D.new()
	particulas.amount = 80
	particulas.lifetime = 0.7
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = RADIO * 0.8
	particulas.direction = Vector2.UP
	particulas.spread = 25.0
	particulas.gravity = Vector2(0, -60)
	particulas.initial_velocity_min = 20.0
	particulas.initial_velocity_max = 50.0
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 4.0
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1.0, 0.85, 0.3))
	degradado.set_color(1, Color(0.6, 0.05, 0.0, 0.0))
	particulas.color_ramp = degradado
	var sin_sombra := CanvasItemMaterial.new()
	sin_sombra.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el fuego se ve en la oscuridad
	particulas.material = sin_sombra
	add_child(particulas)
	var tiempo: float = 0.0
	while tiempo < DURACION_FUEGO:
		if escuela.jugando:
			_quemar()
			luz.energy = randf_range(1.2, 1.8)
			tiempo += 0.1
		await get_tree().create_timer(0.1).timeout
	particulas.emitting = false
	var t := create_tween()
	t.tween_property(luz, "energy", 0.0, 0.6)
	await t.finished
	queue_free()


func _quemar() -> void:
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e in _quemados or not e.visible:
			continue
		if (e as Node2D).global_position.distance_to(global_position) < RADIO + 12.0:
			_quemados.append(e)
			e.recibir_fuego()
	# Lalo también se quema si se queda en el fuego
	var j: CharacterBody2D = escuela.jugador
	if j.global_position.distance_to(global_position) < RADIO * 0.8:
		j.cordura = maxf(1.0, j.cordura - 1.5)
