extends Node3D
## Vista en primera persona. El juego 2D sigue corriendo debajo (choques, enemigos, puzzles, guardado):
## aquí solo se dibuja en 3D lo que pasa en 2D y se manda a Lalo hacia donde mira la cámara.
## - Ratón (capturado) o stick derecho: mirar. WASD / stick izquierdo: caminar relativo a la vista.
## - Linterna en el pecho (como en Silent Hill 2): se mueve con el cuerpo, no con la mano.
## - Enemigos y el Archivero: sus mismos dibujos, siempre de frente a la cámara, eligiendo el lado
##   (frente, espalda, izquierda, derecha) según desde dónde los ves.
## Afuera (campus) todavía no hay 3D: ahí se ve el juego 2D de siempre.

const Mundo = preload("res://src/fp/mundo_3d.gd")
const M = preload("res://src/fp/materiales_3d.gd")
const ESC: float = 1.0 / 44.0
const OJOS: float = 1.62
const OJOS_AGACHADO: float = 1.05
const SENSIBILIDAD_RATON: float = 0.0026
const SENSIBILIDAD_STICK: float = 2.6
const ESCALA_SPRITE: float = 0.25   # la misma escala que en 2D

var escuela: Node2D
var mundo: Node3D
var camara: Camera3D
var linterna: SpotLight3D
var rumbo: float = -PI / 2.0        # ángulo en el mapa 2D hacia donde mira Lalo (arriba al empezar)
var inclinacion: float = 0.0
var activa: bool = false
var _entorno: WorldEnvironment
var _gemelos: Dictionary = {}        # nodo 2D (enemigo, clavo, proyectil...) -> nodo 3D
var _vaiven: float = 0.0
var _retroceso: float = 0.0
var _manos: TextureRect
var _cinematica: bool = false
var _negro: ColorRect
var _anim_manos: String = "reposo"
var _cuadro_manos: float = 0.0
var _cuadros_manos: Dictionary = {}   # animación -> Array[Texture2D]
var _datos_manos: Dictionary = {}


func _ready() -> void:
	_entorno = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.07, 0.085, 0.12)
	env.fog_enabled = true
	env.fog_light_color = Color(0.006, 0.008, 0.013)
	env.fog_density = 0.075
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_entorno.environment = env
	add_child(_entorno)
	mundo = Mundo.new()
	mundo.escuela = escuela
	add_child(mundo)
	mundo.construir()
	camara = Camera3D.new()
	camara.fov = 72.0
	camara.near = 0.05
	add_child(camara)
	linterna = SpotLight3D.new()
	linterna.spot_range = 17.0
	linterna.spot_angle = 32.0
	linterna.spot_angle_attenuation = 1.5
	linterna.light_energy = 3.6
	linterna.light_color = Color(1.0, 0.96, 0.88)
	linterna.shadow_enabled = true
	linterna.shadow_bias = 0.06          # sin franjas ("acné de sombra") en las paredes
	linterna.shadow_normal_bias = 2.5
	linterna.light_specular = 0.4
	add_child(linterna)
	var capa := CanvasLayer.new()
	capa.layer = 7   # debajo de la interfaz y de los menús
	add_child(capa)
	_manos = TextureRect.new()
	_manos.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_manos.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_manos.size = Vector2(1280, 720)   # los cuadros miden 640 × 360: ×2 a pantalla completa
	_manos.modulate = Color(0.58, 0.58, 0.66)   # más oscuras para que combinen con la noche
	_manos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_manos)
	_cargar_manos()
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_negro.modulate.a = 0.0
	var capa_negra := CanvasLayer.new()
	capa_negra.layer = 29
	add_child(capa_negra)
	capa_negra.add_child(_negro)
	_activar(true)


## Encendida en el edificio; afuera (sin 3D todavía) y durante el teaser se ve el 2D.
func _activar(si: bool) -> void:
	if activa == si:
		return
	activa = si
	visible = si
	camara.current = si
	_manos.get_parent().visible = si
	_ocultar_2d(si)
	escuela.oscuridad.get_parent().visible = not si
	if not si:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Todo lo que el juego 2D dibuja en el mundo (mapa, personajes, textos del piso como "PRESENTE",
## huellas, clavos, proyectiles) se vuelve transparente: sigue funcionando, pero no se ve.
func _ocultar_2d(si: bool) -> void:
	for n in escuela.get_children():
		if n is CanvasItem and not n is CanvasLayer:
			(n as CanvasItem).modulate.a = 0.0 if si else 1.0


func _debe_estar_activa() -> bool:
	return escuela.campana.lugar == "principal" and not escuela.has_node("Teaser")


func _input(evento: InputEvent) -> void:
	if not activa or not escuela.jugando:
		return
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var m := evento as InputEventMouseMotion
		rumbo += m.relative.x * SENSIBILIDAD_RATON
		inclinacion = clampf(inclinacion - m.relative.y * SENSIBILIDAD_RATON, -1.2, 1.1)


func _process(delta: float) -> void:
	_activar(_debe_estar_activa())
	if not activa:
		return
	var j: CharacterBody2D = escuela.jugador
	# Ratón capturado solo mientras se juega (en menús se suelta)
	var quiere_captura: bool = escuela.jugando and not Controles.usando_mando and DisplayServer.get_name() != "headless"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if quiere_captura else Input.MOUSE_MODE_VISIBLE
	if escuela.jugando and Controles.usando_mando and Controles.mando >= 0:
		var palanca := Vector2(Input.get_joy_axis(Controles.mando, JOY_AXIS_RIGHT_X), Input.get_joy_axis(Controles.mando, JOY_AXIS_RIGHT_Y))
		if palanca.length() > 0.2:
			rumbo += palanca.x * SENSIBILIDAD_STICK * delta
			inclinacion = clampf(inclinacion - palanca.y * SENSIBILIDAD_STICK * 0.7 * delta, -1.2, 1.1)
	j.rumbo_fp = rumbo
	if _cinematica:
		mundo.sincronizar()
		_sincronizar_dinamicos()
		return
	# Cámara en los ojos, con vaivén al caminar
	var velocidad: float = j.get_real_velocity().length() if escuela.jugando else 0.0
	_vaiven += velocidad * delta * 0.09
	var bob := Vector3(cos(_vaiven) * 0.025, absf(sin(_vaiven)) * 0.035, 0) * clampf(velocidad / 110.0, 0.0, 1.0)
	var adelante := Vector3(cos(rumbo), 0, sin(rumbo))
	var ojos: float = OJOS_AGACHADO if j.agachado else OJOS
	camara.position = Mundo.a3d(j.global_position, ojos)
	camara.rotation = Vector3(inclinacion, atan2(-adelante.x, -adelante.z), 0)
	camara.position += camara.basis * bob
	# La linterna va en el pecho: sigue el cuerpo (rumbo) y casi nada la inclinación de la cabeza
	linterna.position = Mundo.a3d(j.global_position, ojos - 0.38) + adelante * 0.12
	linterna.rotation = Vector3(inclinacion * 0.35 - 0.1, camara.rotation.y, 0)
	linterna.visible = j.linterna and escuela.campana.bateria > 0 and not j.oculto
	linterna.light_energy = j.get_node("Linterna").energy * 3.3
	_ocultar_2d(true)   # lo que aparece después (clavos, proyectiles, campus) también se oculta
	mundo.sincronizar()
	_sincronizar_dinamicos()
	_manos_y_arma(delta, velocidad)


func _cargar_manos() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/manos/animaciones.json"))
	_datos_manos = (d as Dictionary).get("animaciones", {}) if d is Dictionary else {}
	for nombre in _datos_manos:
		var lista: Array[Texture2D] = []
		for k in int(_datos_manos[nombre].get("cuadros", 1)):
			lista.append(load("res://assets/sprites/manos/frames/%s_%02d.png" % [nombre, k + 1]) as Texture2D)
		_cuadros_manos[nombre] = lista


func _poner_animacion_manos(nombre: String) -> void:
	if _cuadros_manos.has(nombre) and _anim_manos != nombre:
		_anim_manos = nombre
		_cuadro_manos = 0.0


func avisar_disparo() -> void:
	_retroceso = 1.0
	_anim_manos = ""   # reinicia aunque ya estuviera disparando
	_poner_animacion_manos("disparo")


func avisar_molotov() -> void:
	_poner_animacion_manos("molotov")


func _manos_y_arma(delta: float, velocidad: float) -> void:
	var j: CharacterBody2D = escuela.jugador
	var arma: Node = j.get_node_or_null("PistolaClavos")
	var tiene_arma: bool = j.inventario.has("Pistola de clavos")
	_manos.visible = not j.oculto and not _cuadros_manos.is_empty()
	# Qué animación toca
	if arma != null and float(arma.get("_recargando")) > 0.0:
		_poner_animacion_manos("recarga")
	elif _anim_manos in ["disparo", "molotov", "recarga"]:
		pass   # se termina sola
	else:
		_poner_animacion_manos("reposo" if tiene_arma else "sin_arma")
	var datos: Dictionary = _datos_manos.get(_anim_manos, {})
	var cuadros: Array = _cuadros_manos.get(_anim_manos, [])
	if cuadros.is_empty():
		return
	var fps: float = float(datos.get("fps", 6))
	if _anim_manos == "recarga" and arma != null:
		fps = cuadros.size() / maxf(float(arma.TIEMPO_RECARGA), 0.1)   # que dure lo mismo que la recarga
	_cuadro_manos += delta * fps
	if _cuadro_manos >= cuadros.size():
		if bool(datos.get("loop", false)):
			_cuadro_manos = fmod(_cuadro_manos, cuadros.size())
		else:
			_poner_animacion_manos("reposo" if tiene_arma else "sin_arma")
			cuadros = _cuadros_manos.get(_anim_manos, cuadros)
			_cuadro_manos = 0.0
	_manos.texture = cuadros[mini(int(_cuadro_manos), cuadros.size() - 1)]
	# Vaivén al caminar y retroceso del disparo
	_retroceso = maxf(0.0, _retroceso - delta * 6.0)
	var balanceo := Vector2(cos(_vaiven * 0.5) * 8.0, absf(sin(_vaiven)) * 7.0) * clampf(velocidad / 110.0, 0.0, 1.0)
	_manos.position = balanceo + Vector2(0, _retroceso * 10.0)


## Transición de puerta doble en 3D: la cámara queda frente a la puerta, las dos hojas se abren con el
## sonido metálico, Lalo cruza, todo se va a negro y aparece del otro lado.
func transicion_puerta_doble(puerta: Node2D, destino: Vector2, cambiar: Callable, sonar: Callable) -> void:
	_cinematica = true
	var j: CharacterBody2D = escuela.jugador
	var lado: float = signf(j.global_position.y - puerta.global_position.y)   # +1: Lalo está al sur de la puerta
	if lado == 0.0:
		lado = 1.0
	var centro := Mundo.a3d(puerta.global_position)
	await _fundido(1.0, 0.22)
	# Frente a la puerta, a la altura de los ojos
	var desde := centro + Vector3(0, OJOS, lado * 1.5)
	camara.position = desde
	camara.rotation = Vector3(-0.04, 0.0 if lado > 0 else PI, 0)
	linterna.position = desde + Vector3(0, -0.38, 0)
	linterna.rotation = Vector3(-0.12, camara.rotation.y, 0)
	_manos.get_parent().visible = false
	mundo.forzar_puerta(puerta, false, -lado)
	await _fundido(0.0, 0.3)
	await get_tree().create_timer(0.25).timeout
	sonar.call("puerta")
	mundo.velocidad_puertas = 0.06
	mundo.forzar_puerta(puerta, true, -lado)   # se abren hacia el otro lado, lejos de Lalo
	var avance := create_tween()
	avance.tween_interval(0.35)
	avance.tween_property(camara, "position", centro + Vector3(0, OJOS, -lado * 0.9), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	avance.parallel().tween_property(linterna, "position", centro + Vector3(0, OJOS - 0.38, -lado * 0.9), 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.9).timeout
	sonar.call("paso")
	await avance.finished
	await _fundido(1.0, 0.3)
	cambiar.call()
	mundo.velocidad_puertas = 0.2
	mundo.forzar_puerta(puerta, false, -lado)
	# Del otro lado mira hacia dentro del cuarto nuevo
	rumbo = (destino - puerta.global_position).angle()
	inclinacion = 0.0
	sonar.call("paso")
	await get_tree().create_timer(0.3).timeout
	mundo.soltar_puerta(puerta)
	_cinematica = false
	_manos.get_parent().visible = true
	await _fundido(0.0, 0.4)


func _fundido(alfa: float, segundos: float) -> void:
	var t := create_tween()
	t.tween_property(_negro, "modulate:a", alfa, segundos)
	await t.finished


# ---------- Enemigos, Archivero, clavos, proyectiles, fuego ----------
func _sincronizar_dinamicos() -> void:
	var vivos: Dictionary = {}
	for e in get_tree().get_nodes_in_group("enemigos"):
		vivos[e] = true
		_actor(e, (e as Enemigo).sprite, e.direccion)
	var a: Node2D = escuela.archivero
	if a != null and a.sprite != null:
		vivos[a] = true
		_actor(a, a.sprite, "")
	for n in escuela.get_children():
		var guion: Script = n.get_script()
		if guion == null:
			continue
		var ruta: String = guion.resource_path.get_file()
		if ruta in ["clavo.gd", "proyectil_enemigo.gd", "molotov.gd", "charco.gd"]:
			vivos[n] = true
			_efecto(n, ruta)
	for n in _gemelos.keys():
		if n is String:
			continue
		if not vivos.has(n) or not is_instance_valid(n):
			(_gemelos[n] as Node3D).queue_free()
			_gemelos.erase(n)


func _actor(n: Node2D, sp: AnimatedSprite2D, direccion: String) -> void:
	var s: Sprite3D = _gemelos.get(n)
	if s == null:
		s = Sprite3D.new()
		s.shaded = true
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		mundo.add_child(s)
		_gemelos[n] = s
	s.visible = n.visible and sp.visible
	var tirado: Node3D = _gemelos.get(str(n.get_instance_id()) + "_tirado")
	var acostado: bool = absf(sp.rotation) > 0.6
	if tirado != null:
		tirado.visible = s.visible and acostado
	if not s.visible:
		return
	if acostado:
		# Tirado en el piso: un cuerpo con grosor, fijo (no gira con la cámara)
		s.visible = false
		if tirado == null:
			tirado = _cuerpo_tirado(n, sp)
		return
	elif tirado != null:
		tirado.queue_free()
		_gemelos.erase(str(n.get_instance_id()) + "_tirado")
	# El lado del dibujo depende de hacia dónde mira el enemigo y desde dónde lo ve Lalo
	var anim: String = sp.animation
	var base: String = anim.rsplit("_", true, 1)[0] if "_" in anim else anim
	var lado: String = _lado_visto(n, direccion) if direccion != "" else ""
	var clave: String = base + "_" + lado if lado != "" and sp.sprite_frames.has_animation(base + "_" + lado) else anim
	var cuadro: int = mini(sp.frame, sp.sprite_frames.get_frame_count(clave) - 1)
	s.texture = sp.sprite_frames.get_frame_texture(clave, cuadro)
	s.pixel_size = absf(sp.scale.y) * ESC
	s.offset = Vector2(sp.offset.x, -sp.offset.y)
	s.modulate = sp.modulate * n.modulate
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.position = Mundo.a3d(n.global_position)
	s.rotation = Vector3.ZERO


## Cuerpo tirado: el dibujo de frente (boca arriba) acostado en el piso, con varias capas encimadas
## para que tenga grosor, más oscuras las de abajo, y un charco de tinta debajo. Queda fijo en el mundo.
func _cuerpo_tirado(n: Node2D, sp: AnimatedSprite2D) -> Node3D:
	var raiz := Node3D.new()
	raiz.position = Mundo.a3d(n.global_position)
	# Hacia dónde quedó la cabeza: depende del lado al que cayó, no de dónde está la cámara
	raiz.rotation.y = (PI / 2 if sp.rotation > 0 else -PI / 2) + float(n.get_instance_id() % 7) * 0.12
	mundo.add_child(raiz)
	var clave: String = "hurt_down" if sp.sprite_frames.has_animation("hurt_down") else sp.animation
	var tex: Texture2D = sp.sprite_frames.get_frame_texture(clave, sp.sprite_frames.get_frame_count(clave) - 1)
	var capas := Node3D.new()
	raiz.add_child(capas)
	var tamano: float = absf(sp.scale.y) * ESC
	var desplazamiento := Vector2(sp.offset.x, -sp.offset.y)
	for k in 7:
		var capa := Sprite3D.new()
		capa.texture = tex
		capa.pixel_size = tamano
		capa.offset = desplazamiento
		capa.shaded = true
		capa.double_sided = true
		capa.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		capa.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		capa.rotation = Vector3(-PI / 2, 0, 0)
		capa.position = Vector3(0, 0.012 + k * 0.014, 0)
		var oscuro: float = 0.35 + 0.65 * k / 6.0
		capa.modulate = Color(oscuro, oscuro, oscuro)
		capas.add_child(capa)
	var charco := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.32
	c.bottom_radius = 0.32
	c.height = 0.004
	var tinta := StandardMaterial3D.new()
	tinta.albedo_color = Color(0.02, 0.015, 0.02, 0.6)
	tinta.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tinta.roughness = 0.05
	c.material = tinta
	charco.mesh = c
	charco.scale = Vector3(1.3, 1.0, 2.2)
	charco.position = Vector3(0.04, 0.004, sp.offset.y * tamano * 0.95)   # debajo del torso
	raiz.add_child(charco)
	_gemelos[str(n.get_instance_id()) + "_tirado"] = raiz
	return raiz


## "down" = lo ves de frente, "up" = de espaldas, o de lado.
func _lado_visto(n: Node2D, direccion: String) -> String:
	var mira := {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}.get(direccion, Vector2.DOWN) as Vector2
	var hacia_mi: Vector2 = (escuela.jugador.global_position - n.global_position).normalized()
	var angulo: float = mira.angle_to(hacia_mi)
	if absf(angulo) < PI / 4:
		return "down"
	if absf(angulo) > 3 * PI / 4:
		return "up"
	return "right" if angulo < 0 else "left"


func _efecto(n: Node2D, ruta: String) -> void:
	var g: Node3D = _gemelos.get(n)
	if g == null:
		g = Node3D.new()
		mundo.add_child(g)
		_gemelos[n] = g
		match ruta:
			"clavo.gd":
				mundo.caja(Vector3.ZERO, Vector3(0.012, 0.012, 0.12), M.color(Color(0.7, 0.7, 0.72), 0.3, 0.8), g)
			"proyectil_enemigo.gd":
				var clase: String = n.get("clase")
				if clase == "tinta":
					var b := MeshInstance3D.new()
					var esfera := SphereMesh.new()
					esfera.radius = 0.07
					esfera.height = 0.14
					esfera.material = M.color(Color(0.02, 0.02, 0.03), 0.2)
					b.mesh = esfera
					g.add_child(b)
				elif clase == "termo":
					mundo.cilindro(Vector3.ZERO, 0.05, 0.2, M.color(Color(0.6, 0.6, 0.62), 0.3, 0.7), g)
				else:
					mundo.caja(Vector3.ZERO, Vector3(0.21, 0.005, 0.28), M.color(Color(0.92, 0.9, 0.82)), g)
			"molotov.gd":
				var fuego := OmniLight3D.new()
				fuego.light_color = Color(1.0, 0.55, 0.15)
				fuego.omni_range = 5.0
				fuego.light_energy = 0.0
				fuego.name = "Fuego"
				g.add_child(fuego)
				mundo.cilindro(Vector3(0, 0.1, 0), 0.04, 0.2, M.color(Color(0.4, 0.55, 0.35), 0.2), g).name = "Botella"
			"charco.gd":
				var d := MeshInstance3D.new()
				var c := CylinderMesh.new()
				c.top_radius = 34.0 * ESC
				c.bottom_radius = c.top_radius
				c.height = 0.01
				c.material = M.color(Color(0.03, 0.02, 0.015), 0.1)
				d.mesh = c
				g.add_child(d)
	var altura: float = 0.0
	match ruta:
		"clavo.gd":
			altura = 1.2
			var dir: Vector2 = n.get("direccion")
			g.rotation.y = atan2(-dir.x, -dir.y)
		"proyectil_enemigo.gd":
			altura = 1.0
			if n.get("clase") == "termo":
				altura = 0.3 + float(n.get("_altura")) * ESC
		"molotov.gd":
			var botella := g.get_node_or_null("Botella") as Node3D
			var b: Variant = n.get("_botella")
			var explotada: bool = b == null or not is_instance_valid(b)
			if botella != null:
				botella.visible = not explotada
			(g.get_node("Fuego") as OmniLight3D).light_energy = randf_range(2.0, 3.0) if explotada else 0.0
		"charco.gd":
			altura = 0.01
	g.position = Mundo.a3d(n.global_position, altura)
