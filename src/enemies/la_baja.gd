extends Enemigo
## La Baja (común): lenta. Embiste de cerca y escupe tinta que mancha la linterna.
## Si ve a Lalo, gime y despierta a las otras Bajas de su cuarto.

const ESPERA_ESCUPIR: float = 6.0
var _escupir: float = 2.0
var _gimio: bool = false


func _configurar() -> void:
	tipo = "la_baja"
	vida_max = 4.0
	velocidad = 46.0
	alcance = 42.0
	dano = 12.0
	vision = 230.0
	anim_mover = "walk"


func _actualizar_especial(delta: float) -> void:
	_escupir = maxf(0.0, _escupir - delta)
	if estado == "PERSIGUE" and not _gimio:
		_gimio = true
		escuela.sonidos.efecto("eco_%d" % randi_range(1, 5), global_position, -8.0)
		for otra in get_tree().get_nodes_in_group("enemigos"):
			if otra != self and otra is Enemigo and otra.cuarto == cuarto and otra.estado == "QUIETO":
				otra.escuchar(global_position, 0.6)
	elif estado in ["QUIETO", "ALERTA"]:
		_gimio = false


func _probar_ataque_especial(distancia: float) -> bool:
	if _escupir > 0.0 or distancia < 80.0 or distancia > 210.0 or not _linea_libre(jugador().global_position):
		return false
	_escupir = ESPERA_ESCUPIR
	_atacar("escupir")
	return true


func _golpe() -> void:
	if ataque != "escupir":
		super._golpe()
		return
	var p := preload("res://src/enemies/proyectil_enemigo.gd").new()
	p.escuela = escuela
	p.clase = "tinta"
	p.dano = 5.0
	p.global_position = global_position + Vector2(0, -34)
	p.velocidad = p.global_position.direction_to(jugador().global_position + Vector2(0, -20)) * 260.0
	get_parent().add_child(p)
