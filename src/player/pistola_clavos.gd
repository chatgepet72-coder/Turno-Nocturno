extends Node2D
## Pistola de clavos de Lalo (traída de nuestra versión): dispara hacia donde apunta la linterna.
## Cargador de 10 clavos; recargar gasta una "Caja de clavos" de la mochila.
## Disparar hace ruido: atrae a los enemigos del cuarto y al Archivero.

const CARGADOR: int = 10
const CADENCIA: float = 0.32
const TIEMPO_RECARGA: float = 1.1
const RUIDO_DISPARO: float = 0.75
const ARMA: String = "Pistola de clavos"
const CAJA: String = "Caja de clavos"

var escuela: Node2D
var jugador: CharacterBody2D
var cargados: int = CARGADOR
var _espera: float = 0.0
var _recargando: float = 0.0
var _aviso_tiempo: float = 0.0
var _contador: Label


func _ready() -> void:
	jugador = get_parent()
	escuela = jugador.get_parent()
	for nombre in ["disparo_clavos", "clavo_impacto", "recarga", "sin_clavos", "golpe", "maniqui_cae", "vidrio_roto", "fuego"]:
		escuela.sonidos.recursos[nombre] = load("res://assets/audio/combate/%s.wav" % nombre)
	_contador = escuela.interfaz.etiqueta(escuela.interfaz.get_child(0), Vector2(930, 652), 17, Color(0.86, 0.82, 0.72))
	_contador.size.x = 320
	_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_contador.hide()


func tiene_arma() -> bool:
	return jugador.inventario.has(ARMA)


func cajas() -> int:
	return jugador.inventario.count(CAJA)


func _physics_process(delta: float) -> void:
	_espera = maxf(0.0, _espera - delta)
	_aviso_tiempo = maxf(0.0, _aviso_tiempo - delta)
	_contador.visible = escuela.jugando and tiene_arma() and (_aviso_tiempo > 0.0 or _recargando > 0.0)
	if not escuela.jugando:
		return
	if not tiene_arma():
		if Input.is_action_just_pressed("lanzar") and jugador.inventario.has("Molotov") and not jugador.oculto and jugador.accion == "":
			lanzar_molotov()
		return
	if _recargando > 0.0:
		_recargando -= delta
		if _recargando <= 0.0:
			jugador.inventario.erase(CAJA)
			cargados = CARGADOR
			_mostrar()
		return
	if jugador.oculto or jugador.accion != "" or jugador.bloqueo_entrada > 0.0:
		return
	if Input.is_action_just_pressed("lanzar") and jugador.inventario.has("Molotov"):
		lanzar_molotov()
	elif Input.is_action_just_pressed("recargar"):
		recargar()
	elif Input.is_action_pressed("disparar") and _espera <= 0.0:
		disparar()


func disparar() -> void:
	_espera = CADENCIA
	if cargados <= 0:
		escuela.sonidos.efecto("sin_clavos", Vector2.INF, -6.0)
		if cajas() > 0:
			recargar()
		else:
			jugador.mensaje = "Sin clavos. Busca cajas de clavos."
		_mostrar()
		return
	cargados -= 1
	var salida: Vector2 = jugador.global_position + jugador.mano + jugador.apuntado * 10.0
	var clavo := preload("res://src/player/clavo.gd").new()
	clavo.escuela = escuela
	clavo.direccion = jugador.apuntado
	clavo.global_position = salida
	escuela.add_child(clavo)
	escuela.sonidos.efecto("disparo_clavos", Vector2.INF, -6.0)
	if escuela.vista_fp != null:
		escuela.vista_fp.avisar_disparo()
	escuela.emitir_ruido(jugador.global_position, RUIDO_DISPARO)
	Controles.vibrar(0.2, 0.06)
	_mostrar()


func recargar() -> void:
	if cargados >= CARGADOR or _recargando > 0.0:
		return
	if cajas() == 0:
		jugador.mensaje = "No tienes cajas de clavos."
		_mostrar()
		return
	_recargando = TIEMPO_RECARGA
	escuela.sonidos.efecto("recarga", Vector2.INF, -6.0)
	_mostrar()


func _mostrar() -> void:
	_aviso_tiempo = 3.0
	_contador.text = ("Recargando…" if _recargando > 0.0 else "Clavos %d / %d" % [cargados, CARGADOR]) + "   ·   Cajas %d" % cajas()


func lanzar_molotov() -> void:
	jugador.inventario.erase("Molotov")
	var m := preload("res://src/player/molotov.gd").new()
	m.escuela = escuela
	var destino: Vector2 = jugador.global_position + jugador.apuntado * 220.0
	var rayo := PhysicsRayQueryParameters2D.create(jugador.global_position, destino, 1, [jugador.get_rid()])
	var choque := jugador.get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		destino = choque.position - jugador.apuntado * 16.0
	m.destino = destino
	m.global_position = jugador.global_position + Vector2(0, -30)
	escuela.add_child(m)
