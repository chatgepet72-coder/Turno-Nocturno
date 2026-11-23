extends Enemigo
## La Baja (común). Ideas tomadas de enemigos de terror (Molded de RE7, Lying Figure de SH2 remake,
## Haunted de The Evil Within), sin copiar ninguno:
## 1. Manotazo: de cerca, golpe torpe.
## 2. Embestida: se queda quieta, se echa para atrás y gime (aviso) y se lanza en línea recta.
##    Si la esquivas de lado se estrella contra la pared y queda aturdida; si te alcanza, te agarra.
## 3. Agarre: te sujeta y te muerde la Cordura. Presiona E / A o dispara muchas veces para zafarte;
##    si no, te avienta con un golpe fuerte. Al zafarte, ella queda tambaleando.
## 4. Escupitajo de tinta: de media distancia; mancha la linterna.
## 5. Esquiva: si le apuntas de frente a media distancia, a veces se hace a un lado.
## 6. Se hace la muerta: tirada en el piso, si pasas junto a ella sin clavarla, te agarra del tobillo.
## 7. Corre: cuando te ve se lanza a correr (más rápido que tú caminando: hay que correr o pelear).
## 8. Te sigue por las puertas si te venía persiguiendo (al Taller no entra: golpea la puerta).
## 9. Zigzag y esquiva: si le apuntas se mueve de lado; si disparas, a veces se tira a un lado.
## 10. Acecha: si la alumbras de lejos, a veces se sale del haz, te rodea en lo oscuro y embiste de lado.
## 11. Avienta cosas: si te alejas, levanta una silla o un libro y te lo avienta.
## Además gime al verte y despierta a las otras Bajas del cuarto.

const ESPERA_ESCUPIR: float = 7.0
const ESPERA_EMBESTIDA: float = 5.5
const ESPERA_ESQUIVA: float = 3.5
const CARGA: float = 0.7              # aviso antes de lanzarse
const VELOCIDAD_EMBESTIDA: float = 250.0
const DURACION_EMBESTIDA: float = 0.6
const ESTRELLADA: float = 1.6         # aturdida si choca con la pared
const PRESIONES_ZAFARSE: int = 6
const TIEMPO_AGARRE: float = 2.6      # si no te zafas en este tiempo, te avienta
const DANO_AGARRE: float = 7.0        # por segundo mientras te muerde
const DANO_AVENTON: float = 18.0
const DISTANCIA_EMBOSCADA: float = 52.0
const VELOCIDAD_CARRERA: float = 138.0   # Lalo camina a 112 y corre a 205
const ESPERA_LANZAR: float = 6.5
const PREPARA_LANZAR: float = 0.6
const ESPERA_ACECHO: float = 7.0

var _escupir: float = 2.0
var _embestida: float = 2.5
var _esquiva: float = 0.0
var _gimio: bool = false
var _rumbo := Vector2.ZERO
var _presiones: int = 0
var _hecha_muerta: bool = false
var _lanzar: float = 3.0
var _acecho: float = 4.0
var _lado_acecho: float = 1.0
var _dur_acecho: float = 2.0
var _zigzag: float = 0.0
## Vistazo: si tiene a dónde huir, solo se deja ver. Al notar a Lalo grita, corre a esa puerta y desaparece.
var huye_a := Vector2.INF


func _configurar() -> void:
	tipo = "la_baja"
	vida_max = 4.0
	velocidad = 46.0
	alcance = 40.0
	dano = 12.0
	vision = 230.0
	anim_mover = "walk"
	sigue_por_puertas = true


func _actualizar_especial(delta: float) -> void:
	_escupir = maxf(0.0, _escupir - delta)
	_embestida = maxf(0.0, _embestida - delta)
	_esquiva = maxf(0.0, _esquiva - delta)
	_lanzar = maxf(0.0, _lanzar - delta)
	_acecho = maxf(0.0, _acecho - delta)
	_zigzag += delta
	if estado == "PERSIGUE" and not _gimio:
		_gimio = true
		escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), global_position, -8.0)
		for otra in get_tree().get_nodes_in_group("enemigos"):
			if otra != self and otra is Enemigo and otra.cuarto == cuarto and otra.estado == "QUIETO":
				otra.escuchar(global_position, 0.6)
	elif estado in ["QUIETO", "ALERTA"]:
		_gimio = false
	if estado == "CAIDO":
		_vigilar_desde_el_piso()


# ---------- Estados propios: CARGA, EMBISTE, AGARRA, ESQUIVA ----------
func _decidir(delta: float) -> void:
	if huye_a != Vector2.INF:
		_vistazo(delta)
		return
	match estado:
		"CARGA":
			_cargar()
			return
		"EMBISTE":
			_embestir(delta)
			return
		"AGARRA":
			_agarrar(delta)
			return
		"ESQUIVA":
			move_and_slide()
			if tiempo_estado > 0.28:
				_cambiar("PERSIGUE")
			return
		"LANZA":
			_preparar_lanzamiento()
			return
		"ACECHA":
			_acechar(delta)
			return
	if estado == "PERSIGUE" and _quiere_esquivar():
		return
	if estado == "PERSIGUE" and _quiere_acechar():
		return
	super._decidir(delta)


func _vistazo(delta: float) -> void:
	var j := jugador()
	if estado != "HUYE":
		velocity = Vector2.ZERO
		_mirar_hacia(j.global_position - global_position)
		_animar("idle")
		var d := global_position.distance_to(j.global_position)
		if (d < 430.0 and _alumbrada() and _linea_libre(j.global_position)) or d < 200.0:
			_cambiar("HUYE")
			escuela.sonidos.efecto("grito", global_position, -4.0)
		return
	_caminar_hacia(huye_a, delta)
	if global_position.distance_to(huye_a) < 30.0 or tiempo_estado > 6.0:
		escuela.sonidos.efecto("puerta", global_position, -2.0)
		if not ("enemigo_" + id) in escuela.recogidos:
			escuela.recogidos.append("enemigo_" + id)   # ya no regresa al cargar
		queue_free()


## Corre si te vio hace poco; si solo oyó algo, camina.
func _velocidad_actual() -> float:
	if estado == "HUYE" or estado == "PERSIGUE" and Time.get_ticks_msec() - _vio_a_lalo_ms < 2500:
		return VELOCIDAD_CARRERA
	return velocidad


## Si Lalo le apunta, no viene derecho: se mece de lado a lado.
func _desvio(dir: Vector2) -> Vector2:
	if estado != "PERSIGUE" or not _me_apunta(0.93):
		return Vector2.ZERO
	return dir.orthogonal() * sin(_zigzag * 5.5) * 95.0


func _me_apunta(precision: float) -> bool:
	var j := jugador()
	if not Input.is_action_pressed("apuntar"):
		return false
	return j.apuntado.dot((global_position - j.global_position).normalized()) > precision


## Lalo la tiene en el haz de la linterna (le está alumbrando la cara).
func _alumbrada() -> bool:
	var j := jugador()
	if not j.linterna or escuela.campana.bateria <= 0:
		return false
	var mira: Vector2 = j.apuntado   # en primera persona es hacia donde mira la cámara
	return mira.dot((global_position - j.global_position).normalized()) > 0.9


## Acecho: de lejos y alumbrada, a veces se sale del haz, te rodea en lo oscuro y embiste de lado.
func _quiere_acechar() -> bool:
	if _acecho > 0.0:
		return false
	var d := global_position.distance_to(jugador().global_position)
	if d < 120.0 or d > 270.0 or not _alumbrada():
		return false
	_acecho = ESPERA_ACECHO
	if randf() > 0.5:
		return false
	_lado_acecho = 1.0 if randf() < 0.5 else -1.0
	_dur_acecho = randf_range(1.3, 2.3)
	_cambiar("ACECHA")
	escuela.sonidos.efecto("papel", global_position, -8.0)
	return true


func _acechar(_delta: float) -> void:
	var j := jugador()
	var desde_lalo := j.global_position.direction_to(global_position)
	var d := global_position.distance_to(j.global_position)
	# De lado (fuera del haz) y manteniendo la distancia
	var lado := desde_lalo.orthogonal() * _lado_acecho
	var ajuste := desde_lalo * clampf((180.0 - d) / 60.0, -1.0, 1.0)
	velocity = (lado + ajuste).normalized() * 125.0
	var antes := global_position
	move_and_slide()
	if global_position.distance_to(antes) < 0.5:
		_lado_acecho *= -1.0   # chocó: le da la vuelta por el otro lado
	_mirar_hacia(velocity)
	_animar(anim_mover)
	sprite.speed_scale = 2.0
	if tiempo_estado >= _dur_acecho or not jugador_en_mi_cuarto():
		if jugador_en_mi_cuarto() and _linea_libre(j.global_position) and d < 200.0:
			_embestida = ESPERA_EMBESTIDA
			_empezar_carga()
		else:
			_cambiar("PERSIGUE")


func _probar_ataque_especial(distancia: float) -> bool:
	if not _linea_libre(jugador().global_position):
		return false
	if _embestida <= 0.0 and distancia > 70.0 and distancia < 175.0:
		_embestida = ESPERA_EMBESTIDA
		_empezar_carga()
		return true
	# Si te alejas, te avienta lo que encuentre (silla o libro)
	if _lanzar <= 0.0 and distancia > 150.0 and distancia < 340.0:
		_lanzar = ESPERA_LANZAR
		_empezar_lanzamiento()
		return true
	if _escupir <= 0.0 and distancia > 110.0 and distancia < 230.0:
		_escupir = ESPERA_ESCUPIR
		_atacar("escupir")
		return true
	return false


func _empezar_lanzamiento() -> void:
	_cambiar("LANZA")
	velocity = Vector2.ZERO
	_mirar_hacia(jugador().global_position - global_position)
	sprite.speed_scale = 0.5
	_animar("attack", true)
	escuela.sonidos.efecto("metal", global_position, -8.0)   # arrastra la silla
	escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), global_position, -8.0)


func _preparar_lanzamiento() -> void:
	velocity = Vector2.ZERO
	_mirar_hacia(jugador().global_position - global_position)
	if sprite.frame >= cuadro_de_golpe() - 1:
		sprite.pause()
	if tiempo_estado < PREPARA_LANZAR:
		return
	var j := jugador()
	var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
	p.escuela = escuela
	p.clase = "silla" if randf() < 0.6 else "libro"
	p.dano = 11.0 if p.clase == "silla" else 7.0
	p.vida = 2.5
	p.giro = randf_range(6.0, 10.0)
	p.global_position = global_position + Vector2(0, -30)
	# Apunta a donde vas a estar (adelanta un poco tu movimiento): muévete de lado para esquivarla
	var objetivo: Vector2 = j.global_position + Vector2(0, -20) + j.velocity * 0.35
	p.velocidad = p.global_position.direction_to(objetivo) * 330.0
	get_parent().add_child(p)
	escuela.sonidos.efecto("lanzar", global_position, -4.0)
	sprite.play()
	sprite.speed_scale = 1.3
	_cambiar("PERSIGUE")
	espera_ataque = 0.8


func _empezar_carga() -> void:
	_cambiar("CARGA")
	velocity = Vector2.ZERO
	_mirar_hacia(jugador().global_position - global_position)
	sprite.speed_scale = 0.55   # los primeros cuadros del ataque: se echa para atrás
	_animar("attack", true)
	escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), global_position, -4.0)


func _cargar() -> void:
	velocity = Vector2.ZERO
	# Durante el aviso sigue girando hacia Lalo; el rumbo se fija al lanzarse
	if tiempo_estado < CARGA * 0.75:
		_mirar_hacia(jugador().global_position - global_position)
		_rumbo = global_position.direction_to(jugador().global_position)
	if sprite.frame >= cuadro_de_golpe() - 1:
		sprite.pause()   # se queda echada para atrás
	if tiempo_estado >= CARGA:
		_cambiar("EMBISTE")
		sprite.play()
		sprite.speed_scale = 1.4
		escuela.sonidos.efecto("paso_archivero", global_position, -4.0)


func _embestir(_delta: float) -> void:
	velocity = _rumbo * VELOCIDAD_EMBESTIDA
	var antes := global_position
	move_and_slide()
	var j := jugador()
	if not j.oculto and global_position.distance_to(j.global_position) < 30.0:
		_empezar_agarre()
		return
	var avanzo: float = global_position.distance_to(antes)
	if tiempo_estado > 0.1 and avanzo < VELOCIDAD_EMBESTIDA * get_physics_process_delta_time() * 0.35:
		# Se estrelló: queda aturdida (premio por esquivarla)
		escuela.sonidos.efecto("golpe", global_position, -2.0)
		escuela.emitir_ruido(global_position, 0.5)
		aturdir(ESTRELLADA)
		return
	if tiempo_estado >= DURACION_EMBESTIDA:
		_cambiar("PERSIGUE")
		espera_ataque = 0.6


func _empezar_agarre() -> void:
	_cambiar("AGARRA")
	_presiones = 0
	velocity = Vector2.ZERO
	sprite.pause()
	sprite.frame = mini(cuadro_de_golpe(), sprite.sprite_frames.get_frame_count(sprite.animation) - 1)
	var j := jugador()
	_mirar_hacia(j.global_position - global_position)
	lastimar_a_lalo(6.0)
	j.mensaje = "¡Te agarró! Presiona %s o dispara una y otra vez." % _boton_interaccion()
	_vibrar(0.7, 0.3)
	_sacudir(0.9)


func _agarrar(delta: float) -> void:
	var j := jugador()
	velocity = Vector2.ZERO
	j.bloqueo_entrada = 0.2
	j.velocity = Vector2.ZERO
	j.cordura = maxf(0.0, j.cordura - DANO_AGARRE * delta)
	if j.cordura <= 0.0:
		escuela.archivar()
		return
	if Input.is_action_just_pressed("interactuar") or Input.is_action_just_pressed("disparar"):
		_presiones += 1
		_vibrar(0.25, 0.06)
		_sacudir(0.25)
	if escuela.modo_prueba and tiempo_estado > 1.0:
		_presiones = PRESIONES_ZAFARSE
	if _presiones >= PRESIONES_ZAFARSE:
		j.mensaje = "Te zafaste. ¡Aléjate!"
		j.bloqueo_entrada = 0.1
		j.move_and_collide(global_position.direction_to(j.global_position) * 24.0)
		aturdir(1.4)
		return
	if tiempo_estado >= TIEMPO_AGARRE:
		# No te zafaste: te avienta
		lastimar_a_lalo(DANO_AVENTON)
		j.move_and_collide(global_position.direction_to(j.global_position) * 40.0)
		j.mensaje = "Te aventó contra el piso."
		_sacudir(1.0)
		_cambiar("PERSIGUE")
		espera_ataque = 1.5


## Si Lalo le apunta de frente desde media distancia, a veces se hace a un lado (no siempre).
func _quiere_esquivar() -> bool:
	if _esquiva > 0.0:
		return false
	var j := jugador()
	var distancia := global_position.distance_to(j.global_position)
	if distancia < 80.0 or distancia > 280.0 or not _me_apunta(0.97):
		return false
	# Al disparar se tira a un lado más seguido que cuando solo le apuntas
	var disparo: bool = Input.is_action_just_pressed("disparar")
	_esquiva = ESPERA_ESQUIVA if not disparo else 2.2
	if randf() > (0.55 if disparo else 0.25):
		return false
	var lado: Vector2 = (global_position - j.global_position).normalized().orthogonal() * (1.0 if randf() < 0.5 else -1.0)
	velocity = lado * 190.0
	_cambiar("ESQUIVA")
	escuela.sonidos.efecto("papel", global_position, -10.0)
	return true


## Tirada en el piso: si Lalo pasa junto a ella sin haberla clavado, a veces lo agarra del tobillo.
func _vigilar_desde_el_piso() -> void:
	if _hecha_muerta or tiempo_estado < 2.0:
		return
	var j := jugador()
	if j.oculto or global_position.distance_to(j.global_position) > DISTANCIA_EMBOSCADA:
		return
	_hecha_muerta = true
	if randf() > 0.6:
		return
	_levantarse()
	escuela.sonidos.efecto("grito", global_position, -8.0)
	_empezar_agarre()


func _levantarse() -> void:
	super._levantarse()
	_hecha_muerta = false


func _caer(direccion_clavo: Vector2) -> void:
	super._caer(direccion_clavo)
	_hecha_muerta = false


func _golpe() -> void:
	if ataque != "escupir":
		super._golpe()
		if global_position.distance_to(jugador().global_position) <= alcance + 16.0:
			_sacudir(0.6)
		return
	var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
	p.escuela = escuela
	p.clase = "tinta"
	p.dano = 5.0
	p.global_position = global_position + Vector2(0, -34)
	p.velocidad = p.global_position.direction_to(jugador().global_position + Vector2(0, -20)) * 260.0
	get_parent().add_child(p)


## Si te pegan con clavos mientras te tiene agarrado, te suelta.
func recibir_clavo(direccion_clavo: Vector2) -> bool:
	if estado in ["CARGA", "EMBISTE", "LANZA", "ACECHA"]:
		sprite.play()
		_cambiar("PERSIGUE")
	return super.recibir_clavo(direccion_clavo)


func _sacudir(fuerza: float) -> void:
	var vista: Variant = escuela.get("vista_fp")
	if vista != null and vista.activa:
		vista.sacudir(fuerza)
