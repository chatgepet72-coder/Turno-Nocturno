extends Enemigo
## El Sinodal (pesado): camina lento y nunca se detiene. El guillotinazo quita mucho, pero después
## se queda aturdido con la cuchilla atorada: esa es la ventana para dispararle.
## Los clavos casi no le hacen nada si no está aturdido. De lejos avienta exámenes reprobados.

const ESPERA_EXAMENES: float = 9.0
const ATURDIDO_TRAS_GOLPE: float = 1.6
var _examenes: float = 4.0


func _configurar() -> void:
	tipo = "el_sinodal"
	vida_max = 12.0
	velocidad = 36.0
	alcance = 62.0
	dano = 28.0
	vision = 260.0
	oido = 1.2
	anim_mover = "walk"
	alto_cuerpo = 112.0
	ancho_cuerpo = 54.0
	tiempo_levantarse = 10.0
	pausa_entre_ataques = 1.4


func _actualizar_especial(delta: float) -> void:
	_examenes = maxf(0.0, _examenes - delta)


func _dano_de_clavo() -> float:
	return 1.0 if estado == "ATURDIDO" else 0.3


func _se_inmuta() -> bool:
	return estado == "ATURDIDO"


func _probar_ataque_especial(distancia: float) -> bool:
	if _examenes > 0.0 or distancia < 120.0 or distancia > 320.0 or not _linea_libre(jugador().global_position):
		return false
	_examenes = ESPERA_EXAMENES
	_atacar("examenes")
	return true


func _al_empezar_ataque() -> void:
	if ataque == "melee":
		escuela.sonidos.efecto("metal", global_position, -6.0)   # la cuchilla raspa: aviso


func _golpe() -> void:
	if ataque == "melee":
		escuela.sonidos.efecto("golpe", global_position, 0.0)
		_vibrar(0.35, 0.15)
		super._golpe()
		return
	for i in range(5):
		var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
		p.escuela = escuela
		p.clase = "examen"
		p.dano = 6.0
		p.giro = randf_range(-8.0, 8.0)
		p.vida = 1.6
		p.global_position = global_position + Vector2(0, -60)
		var base := p.global_position.direction_to(jugador().global_position + Vector2(0, -20))
		p.velocidad = base.rotated((i - 2) * 0.22) * randf_range(170.0, 220.0)
		get_parent().add_child(p)


func _despues_de_atacar() -> void:
	if ataque == "melee":
		aturdir(ATURDIDO_TRAS_GOLPE)   # la cuchilla se atoró en el piso
	else:
		super._despues_de_atacar()
