class_name Molotov
extends Node2D
## Bomba molotov: vuela en arco hasta `destino`, se rompe y deja fuego unos segundos.
## El fuego quema a los enemigos que pisen la zona (los maniquíes arden y ya no regresan).

const RADIO: float = 56.0
const DURACION_FUEGO: float = 4.5
const VUELO: float = 0.55

var destino: Vector2

var _botella: Sprite2D
var _quemados: Array[Node] = []


func _ready() -> void:
	_botella = Sprite2D.new()
	_botella.texture = load("res://assets/sprites/objetos/iconos/molotov.png") as Texture2D
	_botella.scale = Vector2(0.6, 0.6)
	add_child(_botella)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", destino, VUELO)
	t.tween_property(_botella, "rotation", TAU * 2.0, VUELO)
	# El arco: la botella sube y baja mientras avanza
	t.tween_method(func(p: float) -> void: _botella.position.y = -sin(p * PI) * 40.0, 0.0, 1.0, VUELO)
	await t.finished
	_explotar()


func _explotar() -> void:
	_botella.queue_free()
	_sonar("res://assets/audio/efectos/vidrio_roto.wav", 0.0)
	var fuego_sonido := _sonar("res://assets/audio/efectos/fuego.wav", -4.0)
	EventBus.ruido_emitido.emit(global_position, 400.0)

	var luz := PointLight2D.new()
	luz.texture = load("res://assets/sprites/luces/luz_radial.png") as Texture2D
	luz.texture_scale = 1.3
	luz.energy = 1.6
	luz.color = Color(1.0, 0.55, 0.15)
	add_child(luz)
	var particulas := CPUParticles2D.new()
	particulas.amount = 70
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
		_quemar()
		luz.energy = randf_range(1.2, 1.8)   # parpadeo del fuego
		await get_tree().create_timer(0.1).timeout
		tiempo += 0.1
	particulas.emitting = false
	var t := create_tween()
	t.tween_property(luz, "energy", 0.0, 0.6)
	t.parallel().tween_property(fuego_sonido, "volume_db", -60.0, 0.6)
	await t.finished
	queue_free()


func _quemar() -> void:
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e in _quemados or not e.has_method("recibir_fuego"):
			continue
		if (e as Node2D).global_position.distance_to(global_position) < RADIO + 10.0:
			_quemados.append(e)
			e.recibir_fuego()


func _sonar(ruta: String, volumen: float) -> AudioStreamPlayer2D:
	var a := AudioStreamPlayer2D.new()
	a.stream = load(ruta) as AudioStream
	a.volume_db = volumen
	add_child(a)
	a.play()
	return a
