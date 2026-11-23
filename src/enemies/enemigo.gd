class_name Enemigo
extends CharacterBody2D
## Base de los enemigos que sí se pueden pelear (La Baja, El Desvelado, El Expediente, El Sinodal).
## - Lee las animaciones de assets/sprites/enemigos/<tipo>/animaciones.json (cuadros, fps, loop, cuadro de golpe).
## - Solo actúa dentro de su cuarto: no cruza puertas (al estilo Resident Evil).
## - Oye los ruidos de su cuarto y ve a Lalo si no está escondido.
## - Al caer se vuelve a levantar, a menos que Lalo lo clave al piso con más clavos.
## Cada tipo hereda de aquí y cambia sus números y su ataque especial.

const ESCALA: float = 0.25                 # la misma que Lalo
const CLAVOS_PARA_CLAVAR: int = 3          # clavos extra con el enemigo en el piso para que no se levante
const CAPA_ENEMIGOS: int = 4
const CAPA_CUERPOS: int = 8                # zona de golpe de todo el cuerpo (la que pegan los clavos)

static var _cache_cuadros: Dictionary = {}  # tipo -> SpriteFrames (se comparten entre enemigos iguales)
static var _avisado_clavar: bool = false

var tipo: String = ""
var id: String = ""
var lugar: String = "principal"     # "principal" (edificio) o "campus" (afuera)
var territorio: float = 0.0          # afuera no hay cuartos: radio desde su casa donde caza
var escuela: Node2D
var sprite: AnimatedSprite2D
var datos: Dictionary = {}

# Números de cada tipo (las subclases los cambian en _configurar)
var vida_max: float = 4.0
var velocidad: float = 50.0
var alcance: float = 44.0
var dano: float = 12.0
var vision: float = 240.0
var oido: float = 1.0
var anim_mover: String = "walk"
var anim_correr: String = "run"          # se usa si el JSON la trae; si no, "walk" más rápido
var alto_cuerpo: float = 70.0             # alto de la zona de golpe, desde los pies
var ancho_cuerpo: float = 30.0
var tiempo_levantarse: float = 14.0
var pausa_entre_ataques: float = 1.1
var sigue_por_puertas: bool = false       # si lo venía persiguiendo, cruza la puerta detrás de Lalo

var vida: float = 4.0
var estado: String = "QUIETO"   # QUIETO, ALERTA, PERSIGUE, ATACA, HERIDO, ATURDIDO, CAIDO, CLAVADO
var ataque: String = "melee"
var direccion: String = "down"
var casa: Vector2
var cuarto: String = ""
var destino: Vector2 = Vector2.INF
var camino := PackedVector2Array()
var recalcular: float = 0.0
var espera_ataque: float = 0.0
var golpe_hecho: bool = false
var tiempo_estado: float = 0.0
var clavos_en_piso: int = 0
var _revisar_guardado: float = 0.0
var _vio_a_lalo_ms: int = -100000
var _forcejeo: float = 0.0               # segundos jalando la puerta antes de cruzarla
var _golpes_refugio: int = 0
var _agazapado: bool = false


func _ready() -> void:
	add_to_group("enemigos")
	_configurar()
	vida = vida_max
	casa = global_position
	collision_layer = CAPA_ENEMIGOS
	collision_mask = 1
	z_index = 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var forma := CircleShape2D.new()
	forma.radius = 12.0 if tipo != "el_sinodal" else 20.0
	var colision := CollisionShape2D.new()
	colision.shape = forma
	add_child(colision)
	var cuerpo := Area2D.new()
	cuerpo.name = "Cuerpo"
	cuerpo.collision_layer = CAPA_CUERPOS
	cuerpo.collision_mask = 0
	cuerpo.monitoring = false
	var caja := RectangleShape2D.new()
	caja.size = Vector2(ancho_cuerpo, alto_cuerpo)
	var forma_cuerpo := CollisionShape2D.new()
	forma_cuerpo.shape = caja
	forma_cuerpo.position = Vector2(0, -alto_cuerpo * 0.5)
	cuerpo.add_child(forma_cuerpo)
	add_child(cuerpo)
	datos = _leer_datos(tipo)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _cuadros(tipo, datos)
	var cuadro: Array = datos.get("tamano_cuadro", [320, 320])
	var pivote: Array = datos.get("pivote", [160, 310])
	sprite.centered = true
	sprite.offset = Vector2(float(cuadro[0]) / 2.0 - float(pivote[0]), float(cuadro[1]) / 2.0 - float(pivote[1]))
	sprite.scale = Vector2.ONE * ESCALA
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	sprite.animation_finished.connect(_al_terminar_animacion)
	sprite.frame_changed.connect(_al_cambiar_cuadro)
	_animar("idle")


## Las subclases cambian aquí sus números.
func _configurar() -> void:
	pass


# ---------- Datos y animaciones ----------
static func _leer_datos(t: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string("res://assets/sprites/enemigos/%s/animaciones.json" % t)
	var d: Variant = JSON.parse_string(texto)
	return d if d is Dictionary else {}


static func _cuadros(t: String, d: Dictionary) -> SpriteFrames:
	if _cache_cuadros.has(t):
		return _cache_cuadros[t]
	var cuadros := SpriteFrames.new()
	cuadros.remove_animation("default")
	var anims: Dictionary = d.get("animaciones", {})
	for nombre in anims:
		var a: Dictionary = anims[nombre]
		var archivos: Dictionary = a.get("archivos", {})
		for dir in archivos:
			var clave := "%s_%s" % [nombre, dir]
			cuadros.add_animation(clave)
			cuadros.set_animation_speed(clave, float(a.get("fps", 8)))
			cuadros.set_animation_loop(clave, bool(a.get("loop", true)))
			for archivo in archivos[dir]:
				cuadros.add_frame(clave, load("res://assets/sprites/enemigos/%s/%s" % [t, archivo]) as Texture2D)
	_cache_cuadros[t] = cuadros
	return cuadros


func cuadro_de_golpe() -> int:
	var a: Dictionary = datos.get("animaciones", {}).get("attack", {})
	return int(a.get("cuadro_de_golpe", 5)) - 1   # el JSON cuenta desde 1


func _animar(nombre: String, reiniciar: bool = false) -> void:
	var clave := "%s_%s" % [nombre, direccion]
	if not sprite.sprite_frames.has_animation(clave):
		return
	if sprite.animation != clave or reiniciar or not sprite.is_playing():
		var cuadro := sprite.frame
		sprite.play(clave)
		# Al cambiar solo de dirección se conserva el paso.
		if not reiniciar and nombre != "attack" and nombre != "hurt":
			sprite.frame = mini(cuadro, sprite.sprite_frames.get_frame_count(clave) - 1)


func _mirar_hacia(v: Vector2) -> void:
	if v.length() < 0.5:
		return
	if absf(v.x) > absf(v.y) * 1.1:
		direccion = "right" if v.x > 0 else "left"
	elif absf(v.y) > absf(v.x) * 1.1:
		direccion = "down" if v.y > 0 else "up"


# ---------- Ciclo ----------
func _physics_process(delta: float) -> void:
	if escuela == null:
		return
	var aqui: bool = escuela.campana.lugar == lugar
	visible = aqui
	# Escondido en el otro lugar: que los clavos no le peguen
	(get_node("Cuerpo") as Area2D).collision_layer = CAPA_CUERPOS if aqui and estado != "CLAVADO" else 0
	if not aqui or not escuela.jugando:
		velocity = Vector2.ZERO
		sprite.pause()
		return
	_revisar_guardado -= delta
	if _revisar_guardado <= 0.0:
		_revisar_guardado = 1.0
		if ("enemigo_" + id) in escuela.recogidos and estado != "CLAVADO":
			_quedar_clavado(false)
	if cuarto == "" and territorio <= 0.0 and escuela.cuartos != null:
		cuarto = escuela.cuartos.cuarto_en(casa)
	tiempo_estado += delta
	espera_ataque = maxf(0.0, espera_ataque - delta)
	_actualizar_especial(delta)
	match estado:
		"CLAVADO":
			return
		"CAIDO":
			if tiempo_estado >= tiempo_levantarse:
				_levantarse()
			return
		"ATACA", "HERIDO":
			velocity = Vector2.ZERO
			return
		"ATURDIDO":
			velocity = Vector2.ZERO
			if tiempo_estado >= _duracion_aturdido:
				_cambiar("PERSIGUE")
			return
	_percibir()
	_decidir(delta)


var _duracion_aturdido: float = 2.0


## Se llama siempre (antes de decidir). Las subclases agregan reglas propias (luz, escondite...).
func _actualizar_especial(_delta: float) -> void:
	pass


func _cambiar(nuevo: String) -> void:
	estado = nuevo
	tiempo_estado = 0.0


func jugador() -> CharacterBody2D:
	return escuela.jugador


func jugador_en_mi_cuarto() -> bool:
	return _dentro_de_mi_zona(jugador().global_position)


func _dentro_de_mi_zona(punto: Vector2) -> bool:
	if territorio > 0.0:
		return punto.distance_to(casa) < territorio
	return escuela.cuartos == null or escuela.cuartos.cuarto_en(punto) == cuarto


func ve_a_lalo() -> bool:
	var j := jugador()
	if j.oculto or not jugador_en_mi_cuarto():
		return false
	var alcance_vista: float = vision * (0.55 if j.agachado else 1.0)
	if global_position.distance_to(j.global_position) > alcance_vista:
		return false
	return _linea_libre(j.global_position)


func _linea_libre(hasta: Vector2) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -10), hasta + Vector2(0, -10), 1, [get_rid(), jugador().get_rid()])
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	return choque.is_empty() or choque.collider.get("tipo") in ["decoracion", "escondite", "empujar"]


func _percibir() -> void:
	if ve_a_lalo():
		_vio_a_lalo_ms = Time.get_ticks_msec()
		if estado in ["QUIETO", "ALERTA"]:
			_cambiar("PERSIGUE")
		destino = jugador().global_position


## Lo llama escuela.emitir_ruido: solo oye lo que pasa en su cuarto.
func escuchar(posicion: Vector2, intensidad: float) -> void:
	if estado in ["CAIDO", "CLAVADO", "ATACA"] or escuela.campana.lugar != lugar:
		return
	if not _dentro_de_mi_zona(posicion):
		return
	if global_position.distance_to(posicion) > (140.0 + intensidad * 520.0) * oido:
		return
	destino = posicion
	if estado == "QUIETO":
		_cambiar("ALERTA")


func _decidir(delta: float) -> void:
	var j := jugador()
	var distancia := global_position.distance_to(j.global_position)
	if estado == "PERSIGUE":
		if not jugador_en_mi_cuarto() and _seguir_por_la_puerta(delta):
			return
		if not jugador_en_mi_cuarto() or j.oculto:
			# Lo perdió: va al último lugar donde lo vio y luego regresa a casa.
			if destino == Vector2.INF or global_position.distance_to(destino) < 20.0 or tiempo_estado > 8.0:
				destino = casa
				_cambiar("ALERTA")
		elif distancia <= alcance and espera_ataque <= 0.0:
			_atacar("melee")
			return
		elif _probar_ataque_especial(distancia):
			return
	if estado == "ALERTA" and destino != Vector2.INF and global_position.distance_to(destino) < 18.0:
		destino = Vector2.INF
		_cambiar("QUIETO")
	if estado == "QUIETO" or destino == Vector2.INF:
		velocity = Vector2.ZERO
		_animar("idle")
		return
	_caminar_hacia(destino, delta)


## Movimiento de lado que se suma al caminar (zigzag para no ser blanco fácil).
func _desvio(_dir: Vector2) -> Vector2:
	return Vector2.ZERO


## Lalo se fue por una puerta mientras lo perseguía: camina a esa puerta, la jala y entra detrás de él.
## Al cuarto seguro no entra: golpea la puerta y se va.
func _seguir_por_la_puerta(delta: float) -> bool:
	var c: Node = escuela.cuartos
	if not sigue_por_puertas or territorio > 0.0 or c == null or jugador().oculto:
		return false
	var p: Node2D = c.ultima_puerta
	if p == null or not is_instance_valid(p) or Time.get_ticks_msec() - c.ultimo_cruce_ms > 9000:
		return false
	if c.ultimo_cruce_ms - _vio_a_lalo_ms > 4000:
		return false   # no lo venía siguiendo cuando cruzó
	var llegada: Vector2 = c.ultima_llegada
	var hacia: String = c.cuarto_en(llegada)
	var mi_lado: Vector2 = p.global_position + (p.global_position - llegada)
	if hacia == "" or hacia == cuarto or c.cuarto_en(mi_lado) != cuarto:
		return false
	if global_position.distance_to(p.global_position) > 34.0:
		_caminar_hacia(p.global_position, delta)
		return true
	velocity = Vector2.ZERO
	_animar("idle")
	if hacia == c.REFUGIO:
		# Golpea la puerta del Taller tres veces y se rinde
		_forcejeo += delta
		if _forcejeo > 0.7:
			_forcejeo = 0.0
			_golpes_refugio += 1
			escuela.sonidos.efecto("golpe", p.global_position, -2.0)
			_vibrar(0.2, 0.1)
		if _golpes_refugio >= 3:
			_golpes_refugio = 0
			c.ultima_puerta = null
			destino = casa
			_cambiar("ALERTA")
		return true
	_forcejeo += delta
	if _forcejeo < 0.6:
		return true
	_forcejeo = 0.0
	escuela.sonidos.efecto("puerta", p.global_position, 0.0)
	escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), llegada, -6.0)
	var vista: Variant = escuela.get("vista_fp")
	if vista != null and vista.activa:
		var sentido: float = 1.0 if llegada.y > p.global_position.y else -1.0
		vista.mundo.forzar_puerta(p, true, sentido)
		get_tree().create_timer(1.3).timeout.connect(func() -> void:
			if is_instance_valid(vista) and is_instance_valid(p):
				vista.mundo.soltar_puerta(p))
	global_position = llegada + Vector2(randf_range(-14.0, 14.0), 0.0)
	cuarto = hacia
	casa = global_position
	destino = jugador().global_position
	_vio_a_lalo_ms = Time.get_ticks_msec()
	espera_ataque = 0.5
	_cambiar("PERSIGUE")
	return true


## Las subclases deciden si usan su ataque a distancia. Devuelve true si atacó.
func _probar_ataque_especial(_distancia: float) -> bool:
	return false


func _velocidad_actual() -> float:
	return velocidad


func _caminar_hacia(punto: Vector2, delta: float) -> void:
	recalcular -= delta
	var a: Node = escuela.archivero
	if recalcular <= 0.0 and a.lista:
		recalcular = 0.45
		camino = a.rejilla.get_point_path(a.celda_libre(global_position), a.celda_libre(punto))
		if camino.size() > 1:
			camino.remove_at(0)
	while camino.size() > 0 and global_position.distance_to(camino[0]) < 6.0:
		camino.remove_at(0)
	var siguiente: Vector2 = camino[0] if camino.size() > 0 else punto
	var dir := global_position.direction_to(siguiente)
	velocity = dir * _velocidad_actual() + _desvio(dir)
	move_and_slide()
	var real := get_real_velocity()
	_mirar_hacia(real if real.length() > 2.0 else dir)
	var corriendo: bool = real.length() > velocidad * 1.5
	var anim: String = anim_mover
	if corriendo and sprite.sprite_frames.has_animation("%s_%s" % [anim_correr, direccion]):
		anim = anim_correr
	_animar(anim if real.length() > 2.0 else "idle")
	sprite.speed_scale = clampf(real.length() / maxf(velocidad, 1.0), 0.6, 1.2 if anim == anim_correr else 2.4)


# ---------- Ataques ----------
func _atacar(cual: String) -> void:
	ataque = cual
	golpe_hecho = false
	_mirar_hacia(jugador().global_position - global_position)
	_cambiar("ATACA")
	sprite.speed_scale = 1.0
	_animar("attack", true)
	_al_empezar_ataque()


func _al_empezar_ataque() -> void:
	pass


func _al_cambiar_cuadro() -> void:
	if estado != "ATACA" or golpe_hecho or not sprite.animation.begins_with("attack"):
		return
	if sprite.frame == cuadro_de_golpe():
		golpe_hecho = true
		_golpe()


## En el cuadro de golpe: el ataque cuerpo a cuerpo pega si Lalo sigue cerca. Las subclases cambian los especiales.
func _golpe() -> void:
	if ataque == "melee":
		if global_position.distance_to(jugador().global_position) <= alcance + 16.0 and not jugador().oculto:
			lastimar_a_lalo(dano)


func _al_terminar_animacion() -> void:
	if estado == "ATACA":
		espera_ataque = pausa_entre_ataques
		_despues_de_atacar()
	elif estado == "HERIDO":
		_cambiar("PERSIGUE")
		destino = jugador().global_position


func _despues_de_atacar() -> void:
	_cambiar("PERSIGUE")


func lastimar_a_lalo(cuanto: float) -> void:
	var j := jugador()
	if j.oculto or not escuela.jugando:
		return
	j.cordura = maxf(0.0, j.cordura - cuanto)
	escuela.sonidos.efecto("golpe", Vector2.INF, -6.0)
	_vibrar(clampf(cuanto / 30.0, 0.25, 0.8), 0.18)
	# Empujón corto para que se sienta el golpe
	j.move_and_collide(global_position.direction_to(j.global_position) * 10.0)
	var vista: Variant = escuela.get("vista_fp")
	if vista != null and vista.activa:
		vista.sacudir(clampf(cuanto / 25.0, 0.3, 1.0))
	if j.cordura <= 0.0:
		escuela.archivar()


# ---------- Recibir daño ----------
## Lo llama el clavo. Devuelve true si el clavo se quedó en el enemigo.
func recibir_clavo(direccion_clavo: Vector2) -> bool:
	match estado:
		"CLAVADO":
			return false
		"CAIDO":
			if _agazapado:
				tiempo_estado = tiempo_levantarse   # el disparo lo despierta: se levanta ya
				return true
			clavos_en_piso += 1
			escuela.sonidos.efecto("clavo_impacto", global_position, -4.0)
			if clavos_en_piso >= CLAVOS_PARA_CLAVAR:
				_quedar_clavado(true)
			return true
	vida -= _dano_de_clavo()
	escuela.sonidos.efecto("clavo_impacto", global_position, -6.0)
	destino = jugador().global_position
	if vida <= 0.0:
		_caer(direccion_clavo)
	elif _se_inmuta():
		_mirar_hacia(-direccion_clavo)
		_cambiar("HERIDO")
		sprite.speed_scale = 1.0
		_animar("hurt", true)
		move_and_collide(direccion_clavo * 6.0)
	elif estado in ["QUIETO", "ALERTA"]:
		_cambiar("PERSIGUE")
	return true


func _dano_de_clavo() -> float:
	return 1.0


## Si un clavo lo hace retroceder (El Sinodal casi no se inmuta).
func _se_inmuta() -> bool:
	return true


func aturdir(segundos: float) -> void:
	if estado in ["CAIDO", "CLAVADO"]:
		return
	_duracion_aturdido = segundos
	_cambiar("ATURDIDO")
	_animar("stun" if sprite.sprite_frames.has_animation("stun_" + direccion) else "idle", true)


func _caer(direccion_clavo: Vector2) -> void:
	_cambiar("CAIDO")
	clavos_en_piso = 0
	velocity = Vector2.ZERO
	collision_layer = 0   # Lalo puede pasar por encima
	escuela.sonidos.efecto("maniqui_cae", global_position, -4.0)
	_animar("hurt", true)
	sprite.pause()
	sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1
	var lado: float = 1.0 if direccion_clavo.x >= 0.0 else -1.0
	var t := create_tween()
	t.tween_property(sprite, "rotation", lado * PI * 0.5, 0.25)
	t.parallel().tween_property(get_node("Cuerpo"), "rotation", lado * PI * 0.5, 0.25)
	t.parallel().tween_property(sprite, "modulate", Color(0.75, 0.75, 0.78), 0.25)
	if not _avisado_clavar:
		_avisado_clavar = true
		jugador().mensaje = "Se va a levantar. Clávalo al piso: dispárale %d veces más mientras está tirado." % CLAVOS_PARA_CLAVAR


## Encierros: aparece tirado entre los muebles y se levanta a los pocos segundos con toda su vida.
func aparecer_agazapado(segundos: float) -> void:
	_cambiar("CAIDO")
	velocity = Vector2.ZERO
	collision_layer = 0
	_animar("hurt", true)
	sprite.pause()
	sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1
	sprite.rotation = PI * 0.5
	(get_node("Cuerpo") as Node2D).rotation = PI * 0.5
	sprite.modulate = Color(0.75, 0.75, 0.78)
	_agazapado = true
	var normal: float = tiempo_levantarse
	tiempo_levantarse = segundos
	await get_tree().create_timer(segundos + 0.2).timeout
	tiempo_levantarse = normal
	_agazapado = false
	if is_instance_valid(self) and estado not in ["CAIDO", "CLAVADO"]:
		vida = vida_max
		_vio_a_lalo_ms = Time.get_ticks_msec()


func _levantarse() -> void:
	vida = vida_max * 0.6
	collision_layer = CAPA_ENEMIGOS
	var t := create_tween()
	t.tween_property(sprite, "rotation", 0.0, 0.6)
	t.parallel().tween_property(get_node("Cuerpo"), "rotation", 0.0, 0.6)
	t.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.6)
	escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), global_position, -10.0)
	destino = jugador().global_position
	_cambiar("PERSIGUE")


func _quedar_clavado(con_sonido: bool) -> void:
	_cambiar("CLAVADO")
	collision_layer = 0
	velocity = Vector2.ZERO
	sprite.pause()
	if is_equal_approx(sprite.rotation, 0.0):
		sprite.rotation = PI * 0.5
	sprite.modulate = Color(0.45, 0.45, 0.5)
	if not ("enemigo_" + id) in escuela.recogidos:
		escuela.recogidos.append("enemigo_" + id)   # se guarda: ya no regresa
	if con_sonido:
		escuela.sonidos.efecto("clavo_impacto", global_position, 0.0)
		jugador().mensaje = "Clavado al piso. Ese ya no se levanta."


# El autoload Controles se busca al usarlo (esta clase se compila antes que los autoloads en las pruebas).
func _vibrar(fuerza: float, duracion: float) -> void:
	var c: Node = get_node_or_null("/root/Controles")
	if c != null:
		c.vibrar(fuerza, duracion)


func _boton_interaccion() -> String:
	var c: Node = get_node_or_null("/root/Controles")
	return c.boton_interaccion() if c != null else "E"


## Fuego (molotov): los de papel arden y ya no regresan; El Sinodal aguanta más.
func recibir_fuego() -> void:
	if estado == "CLAVADO":
		return
	if tipo == "el_sinodal" and estado != "CAIDO":
		vida -= 6.0
		if vida > 0.0:
			aturdir(2.5)
			return
	if estado != "CAIDO":
		_caer(Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT)
	_quedar_clavado(false)
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(1.0, 0.45, 0.15), 0.2)
	t.tween_property(sprite, "modulate", Color(0.18, 0.15, 0.14), 1.6)
	jugador().mensaje = "Ardió como papel. Ese ya no regresa."
