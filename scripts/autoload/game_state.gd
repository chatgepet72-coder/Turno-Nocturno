extends Node
## Estado de la partida: progreso, decisiones del jugador y cálculo del final.

signal municion_cambio(cargador: int, reserva: int)

enum Final { BUENO, MALO, SECRETO }

const VIDA_MAX_DON_CHAVA: int = 100
const CAPACIDAD_CARGADOR: int = 10

var capitulo: int = 0
var vida_don_chava: int = VIDA_MAX_DON_CHAVA
var mensajes_falsos_totales: int = 0
var mensajes_falsos_seguidos: int = 0
var documentos_leidos: Array[StringName] = []
var enemigos_eliminados: Array[StringName] = []
var tiene_pistola: bool = false
var clavos_cargador: int = 0
var clavos_reserva: int = 0


func _ready() -> void:
	EventBus.mensaje_falso_resuelto.connect(_on_mensaje_falso_resuelto)
	EventBus.documento_leido.connect(_on_documento_leido)
	EventBus.enemigo_eliminado_para_siempre.connect(_on_enemigo_eliminado)


func reiniciar() -> void:
	capitulo = 0
	vida_don_chava = VIDA_MAX_DON_CHAVA
	mensajes_falsos_totales = 0
	mensajes_falsos_seguidos = 0
	documentos_leidos.clear()
	enemigos_eliminados.clear()
	tiene_pistola = false
	clavos_cargador = 0
	clavos_reserva = 0


func dar_pistola(cargador: int, reserva: int) -> void:
	tiene_pistola = true
	clavos_cargador = cargador
	clavos_reserva = reserva
	municion_cambio.emit(clavos_cargador, clavos_reserva)


## Gasta un clavo del cargador. Devuelve false si está vacío.
func gastar_clavo() -> bool:
	if clavos_cargador <= 0:
		return false
	clavos_cargador -= 1
	municion_cambio.emit(clavos_cargador, clavos_reserva)
	return true


## Llena el cargador con la reserva. Devuelve false si no había nada que recargar.
func recargar() -> bool:
	var faltan: int = mini(CAPACIDAD_CARGADOR - clavos_cargador, clavos_reserva)
	if faltan <= 0:
		return false
	clavos_cargador += faltan
	clavos_reserva -= faltan
	municion_cambio.emit(clavos_cargador, clavos_reserva)
	return true


## Reglas del guion (docs/guion.md, "Escape y finales"):
## - Don Chava con la mitad de su vida o menos: final malo.
## - Si no, y el jugador siguió la mayoría de los mensajes falsos: final secreto.
## - Si no: final bueno.
func calcular_final() -> Final:
	if vida_don_chava * 2 <= VIDA_MAX_DON_CHAVA:
		return Final.MALO
	if mensajes_falsos_totales > 0 and mensajes_falsos_seguidos * 2 > mensajes_falsos_totales:
		return Final.SECRETO
	return Final.BUENO


func _on_mensaje_falso_resuelto(_id: StringName, lo_siguio: bool) -> void:
	mensajes_falsos_totales += 1
	if lo_siguio:
		mensajes_falsos_seguidos += 1


func _on_documento_leido(id_documento: StringName) -> void:
	if id_documento not in documentos_leidos:
		documentos_leidos.append(id_documento)


func _on_enemigo_eliminado(id_enemigo: StringName) -> void:
	if id_enemigo not in enemigos_eliminados:
		enemigos_eliminados.append(id_enemigo)
