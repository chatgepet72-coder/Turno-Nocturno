extends Enemigo
## El Expediente (embosca): espera casi invisible entre los muebles. Si Lalo pasa cerca sin alumbrarlo,
## lo agarra del tobillo y hay que zafarse presionando un botón muchas veces.
## De lejos avienta tres hojas cortantes en abanico. Es el que menos aguanta el fuego.

const DISTANCIA_EMBOSCADA: float = 70.0
const PRESIONES_PARA_ZAFARSE: int = 7
const DANO_AGARRE: float = 6.0          # por segundo mientras te tiene
const ESPERA_HOJAS: float = 6.0

var escondido: bool = true
var agarrando: bool = false
var _presiones: int = 0
var _hojas: float = 2.0


func _configurar() -> void:
	tipo = "el_expediente"
	vida_max = 3.0
	velocidad = 58.0
	alcance = 46.0
	dano = 6.0
	vision = 200.0
	anim_mover = "crawl"
	alto_cuerpo = 34.0
	ancho_cuerpo = 54.0


func _ready() -> void:
	super._ready()
	sprite.modulate.a = 0.12


func _actualizar_especial(delta: float) -> void:
	_hojas = maxf(0.0, _hojas - delta)
	if escondido:
		_esperar_escondido()
	if agarrando:
		_sostener_agarre(delta)


func _esperar_escondido() -> void:
	velocity = Vector2.ZERO
	var j := jugador()
	if not jugador_en_mi_cuarto():
		return
	var distancia := global_position.distance_to(j.global_position)
	var alumbrado: bool = j.linterna and not j.oculto and distancia < 260.0 \
		and j.apuntado.dot((global_position - j.global_position).normalized()) > 0.85 and _linea_libre(j.global_position)
	if alumbrado:
		_salir("Algo se mueve entre los papeles.")
	elif distancia < DISTANCIA_EMBOSCADA and not j.oculto:
		_salir("")
		_atacar("agarre")


func _salir(aviso: String) -> void:
	escondido = false
	create_tween().tween_property(sprite, "modulate:a", 1.0, 0.3)
	escuela.sonidos.efecto("papel", global_position, -2.0)
	if aviso != "":
		jugador().mensaje = aviso
	_cambiar("PERSIGUE")


func _percibir() -> void:
	if escondido:
		return
	super._percibir()


func escuchar(posicion: Vector2, intensidad: float) -> void:
	if escondido:
		return   # escondido no se mueve: espera a que pasen cerca
	super.escuchar(posicion, intensidad)


func _decidir(delta: float) -> void:
	if escondido or agarrando:
		velocity = Vector2.ZERO
		return
	super._decidir(delta)


## Se arrastra a tirones: rápido en los cuadros 2, 3, 6 y 7.
func _velocidad_actual() -> float:
	return velocidad * (1.5 if sprite.frame in [1, 2, 5, 6] else 0.45)


func _probar_ataque_especial(distancia: float) -> bool:
	if _hojas > 0.0 or distancia < 100.0 or distancia > 260.0 or not _linea_libre(jugador().global_position):
		return false
	_hojas = ESPERA_HOJAS
	_atacar("hojas")
	return true


func _atacar(cual: String) -> void:
	# De cerca siempre agarra del tobillo
	super._atacar("agarre" if cual == "melee" else cual)


func _golpe() -> void:
	match ataque:
		"agarre":
			var j := jugador()
			if global_position.distance_to(j.global_position) <= alcance + 18.0 and not j.oculto:
				agarrando = true
				_presiones = 0
				lastimar_a_lalo(dano)
				j.mensaje = "¡Te agarró del tobillo! Presiona %s o dispara una y otra vez." % _boton_interaccion()
				_vibrar(0.6, 0.3)
		"hojas":
			for angulo in [-0.28, 0.0, 0.28]:
				var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
				p.escuela = escuela
				p.clase = "hoja"
				p.dano = 5.0
				p.giro = 14.0
				p.global_position = global_position + Vector2(0, -16)
				p.velocidad = p.global_position.direction_to(jugador().global_position + Vector2(0, -20)).rotated(angulo) * 300.0
				get_parent().add_child(p)


func _despues_de_atacar() -> void:
	if agarrando:
		_cambiar("ATACA")   # se queda sosteniendo el agarre
		sprite.pause()
	else:
		super._despues_de_atacar()


func _sostener_agarre(delta: float) -> void:
	var j := jugador()
	j.bloqueo_entrada = 0.2   # Lalo no se puede mover
	j.cordura = maxf(0.0, j.cordura - DANO_AGARRE * delta)
	if j.cordura <= 0.0:
		agarrando = false
		escuela.archivar()
		return
	if Input.is_action_just_pressed("interactuar") or Input.is_action_just_pressed("disparar"):
		_presiones += 1
		_vibrar(0.2, 0.06)
	if _presiones >= PRESIONES_PARA_ZAFARSE or estado in ["CAIDO", "CLAVADO", "HERIDO"]:
		agarrando = false
		j.bloqueo_entrada = 0.15
		if estado == "ATACA":
			j.mensaje = "Te zafaste."
			aturdir(1.6)


func recibir_clavo(direccion_clavo: Vector2) -> bool:
	if escondido:
		_salir("")
	return super.recibir_clavo(direccion_clavo)
