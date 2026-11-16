extends Node
## Estado de la partida: progreso, decisiones del jugador y cálculo del final.

enum Final { BUENO, MALO, SECRETO }

const VIDA_MAX_DON_CHAVA: int = 100

var capitulo: int = 0
var vida_don_chava: int = VIDA_MAX_DON_CHAVA
var mensajes_falsos_totales: int = 0
var mensajes_falsos_seguidos: int = 0
var documentos_leidos: Array[StringName] = []
var enemigos_eliminados: Array[StringName] = []


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
