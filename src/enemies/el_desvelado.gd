extends Enemigo
## El Desvelado (rápido): mientras la linterna lo alumbra se queda congelado.
## En la oscuridad corre a tirones. De cerca da un termazo; de lejos avienta el termo, que deja un charco.

const ESPERA_TERMO: float = 7.0
const ESPERA_GRITO: float = 25.0
var _termo: float = 3.0
var _grito: float = 0.0
var alumbrado: bool = false


func _configurar() -> void:
	tipo = "el_desvelado"
	vida_max = 2.0
	velocidad = 150.0
	alcance = 40.0
	dano = 14.0
	vision = 320.0
	anim_mover = "run"
	alto_cuerpo = 84.0
	pausa_entre_ataques = 0.8


func _actualizar_especial(delta: float) -> void:
	_termo = maxf(0.0, _termo - delta)
	_grito = maxf(0.0, _grito - delta)
	# Al ver a Lalo, grita: el bostezo se oye en todo el lugar y atrae al Archivero.
	if estado == "PERSIGUE" and _grito <= 0.0:
		_grito = ESPERA_GRITO
		escuela.sonidos.efecto("grito", global_position, -2.0)
		escuela.emitir_ruido(jugador().global_position, 1.6)
		jugador().mensaje = "¡Ese grito se oyó en todo el campus! El Archivero viene."
	alumbrado = _lo_alumbra()
	if alumbrado and estado in ["PERSIGUE", "ALERTA"]:
		# Congelado a media pose, con la boca abierta: no se mueve mientras lo ves
		velocity = Vector2.ZERO
		sprite.pause()


func _lo_alumbra() -> bool:
	var j := jugador()
	if not j.linterna or j.oculto or escuela.campana.bateria <= 0:
		return false
	var hacia: Vector2 = global_position - j.global_position
	if hacia.length() > 380.0 or j.apuntado.dot(hacia.normalized()) < 0.8:
		return false
	return _linea_libre(j.global_position)


func _decidir(delta: float) -> void:
	if alumbrado and estado in ["PERSIGUE", "ALERTA"]:
		return
	super._decidir(delta)


## Corre a tirones: rápido en los cuadros 2, 3, 6 y 7 y casi frena en los demás.
func _velocidad_actual() -> float:
	var rapido: bool = sprite.frame in [1, 2, 5, 6]
	return velocidad * (1.25 if rapido else 0.35)


func _probar_ataque_especial(distancia: float) -> bool:
	if _termo > 0.0 or distancia < 110.0 or distancia > 300.0 or not _linea_libre(jugador().global_position):
		return false
	_termo = ESPERA_TERMO
	_atacar("termo")
	return true


func _golpe() -> void:
	if ataque != "termo":
		super._golpe()
		return
	var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
	p.escuela = escuela
	p.clase = "termo"
	p.dano = 10.0
	p.global_position = global_position + Vector2(0, -10)
	p.arco_hasta = jugador().global_position
	p.arco_total = clampf(global_position.distance_to(jugador().global_position) / 300.0, 0.5, 1.0)
	get_parent().add_child(p)
