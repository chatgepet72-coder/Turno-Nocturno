extends Enemigo
## El Pupitre: una silla de paleta que tiene por patas dos pares de piernas de alumno unidas por la cadera.
## El par de abajo corre; el de arriba (el respaldo) patea. Vive en lo oscuro del pasillo.
## - Casi nunca se ve: corre por el piso y las paredes y solo se le OYE (patas en el azulejo, con eco).
## - Le teme a la luz: si lo alumbras se congela un instante (chirrido) y huye fuera del haz.
##   Mientras está congelado es cuando se le puede pegar.
## - Si le das la espalda o apagas la linterna, se acerca por fuera del haz y te patea; luego se esconde.
## - Al caer se clava al piso como los demás; el fuego lo quema.
## Idea original para la escuela, inspirada en enemigos que acechan en la oscuridad (sin copiar ninguno).

const VELOCIDAD_RONDA: float = 175.0
const VELOCIDAD_HUIDA: float = 270.0
const VELOCIDAD_ATAQUE: float = 300.0
const CONGELADO: float = 0.55          # segundos quieto al recibir la luz
const DISTANCIA_ACECHO: float = 280.0
const ESPERA_ATAQUE: float = 4.0

var altura_3d: float = 0.0             # en primera persona: qué tan arriba de la pared va (m)
var _altura_meta: float = 0.0
var _sonido: float = 1.0
var _espera: float = 3.0
var _punto := Vector2.INF


func _configurar() -> void:
	tipo = "el_pupitre"
	vida_max = 3.0
	velocidad = VELOCIDAD_RONDA
	alcance = 42.0
	dano = 14.0
	vision = 320.0
	anim_mover = "walk"
	anim_correr = "run"
	alto_cuerpo = 58.0
	tiempo_levantarse = 10.0


func _actualizar_especial(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	altura_3d = move_toward(altura_3d, _altura_meta, delta * 3.0)
	# Lo que se oye: patas corriendo con eco cuando se mueve, rasguños cuando espera
	_sonido -= delta
	if _sonido <= 0.0 and jugador_en_mi_cuarto():
		var moviendo: bool = velocity.length() > 40.0
		_sonido = randf_range(1.0, 2.0) if moviendo else randf_range(4.0, 8.0)
		escuela.sonidos.efecto("correteo_%d" % randi_range(1, 4) if moviendo else "rasguno", global_position, -3.0 if moviendo else -9.0)


## No usa la vista normal: decide con la luz y la espalda de Lalo.
func _percibir() -> void:
	if ve_a_lalo():
		_vio_a_lalo_ms = Time.get_ticks_msec()


func _decidir(delta: float) -> void:
	var j := jugador()
	var d := global_position.distance_to(j.global_position)
	match estado:
		"CONGELADO":
			velocity = Vector2.ZERO
			sprite.pause()
			if tiempo_estado >= CONGELADO:
				sprite.play()
				_huir()
			return
		"HUYE":
			_correr_a(_punto, VELOCIDAD_HUIDA, delta)
			if global_position.distance_to(_punto) < 24.0 or tiempo_estado > 2.5:
				_cambiar("QUIETO")
				_espera = ESPERA_ATAQUE * (0.5 if not j.linterna else 1.0)
			return
		"EMBISTE":
			_altura_meta = 0.0
			_correr_a(j.global_position, VELOCIDAD_ATAQUE, delta)
			if d <= alcance:
				_atacar("melee")
			elif tiempo_estado > 1.6 or _alumbrado():
				_cambiar("QUIETO")
			return
	# Le da la luz de cerca: se congela con un chirrido
	if jugador_en_mi_cuarto() and d < 360.0 and _alumbrado() and _linea_libre(j.global_position):
		_cambiar("CONGELADO")
		velocity = Vector2.ZERO
		escuela.sonidos.efecto("chillido", global_position, -4.0)
		_vibrar(0.25, 0.1)
		return
	# Lalo de espaldas (o a oscuras) y cerca: ataca por fuera del haz
	if jugador_en_mi_cuarto() and not j.oculto and _espera <= 0.0 and d < DISTANCIA_ACECHO and espera_ataque <= 0.0:
		_cambiar("EMBISTE")
		escuela.sonidos.efecto("correteo_3", global_position, 0.0)
		return
	# Ronda: corre de un punto oscuro a otro, a veces por la pared
	if _punto == Vector2.INF or global_position.distance_to(_punto) < 24.0 or tiempo_estado > 4.0:
		_punto = _punto_oscuro()
		_altura_meta = randf_range(0.8, 2.0) if randf() < 0.5 else 0.0
		_cambiar("QUIETO")
	_correr_a(_punto, VELOCIDAD_RONDA, delta)


func _correr_a(punto: Vector2, rapidez: float, delta: float) -> void:
	velocidad = rapidez
	_caminar_hacia(punto, delta)
	velocidad = VELOCIDAD_RONDA


func _velocidad_actual() -> float:
	return velocidad


func _despues_de_atacar() -> void:
	_huir()


## Sale corriendo a un punto oscuro a un lado de Lalo, fuera del haz.
func _huir() -> void:
	var j := jugador()
	var lado: Vector2 = j.apuntado.orthogonal() * (1.0 if randf() < 0.5 else -1.0)
	var atras: Vector2 = -j.apuntado
	_punto = _en_mi_zona(j.global_position + (lado * 0.8 + atras * 0.6).normalized() * 260.0)
	_altura_meta = randf_range(1.0, 2.2)
	_cambiar("HUYE")


func _alumbrado() -> bool:
	var j := jugador()
	if not j.linterna or escuela.campana.bateria <= 0 or j.oculto:
		return false
	return j.apuntado.dot((global_position - j.global_position).normalized()) > 0.9


## Un punto del cuarto/pasillo que Lalo no esté alumbrando, a media distancia.
func _punto_oscuro() -> Vector2:
	var j := jugador()
	for intento in 10:
		var p := _en_mi_zona(j.global_position + Vector2.from_angle(randf() * TAU) * randf_range(180.0, 380.0))
		if j.apuntado.dot((p - j.global_position).normalized()) < 0.6:
			return p
	return casa


func _en_mi_zona(p: Vector2) -> Vector2:
	if escuela.cuartos != null and escuela.cuartos.cuartos.has(cuarto):
		var r: Rect2 = (escuela.cuartos.cuartos[cuarto] as Rect2).grow(-30.0)
		return p.clamp(r.position, r.end)
	return p


func _golpe() -> void:
	if global_position.distance_to(jugador().global_position) <= alcance + 18.0 and not jugador().oculto:
		lastimar_a_lalo(dano)
		jugador().mensaje = "Algo te pateó desde lo oscuro."


func recibir_clavo(direccion_clavo: Vector2) -> bool:
	_altura_meta = 0.0
	altura_3d = 0.0
	if estado in ["EMBISTE", "HUYE"]:
		_cambiar("QUIETO")
	return super.recibir_clavo(direccion_clavo)
