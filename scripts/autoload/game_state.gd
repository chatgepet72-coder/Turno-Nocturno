extends Node
## Estado de la partida: progreso, decisiones del jugador y cálculo del final.

signal municion_cambio(cargador: int, reserva: int)

enum Final { BUENO, MALO, SECRETO }

const VIDA_MAX_DON_CHAVA: int = 100
const CAPACIDAD_CARGADOR: int = 10
const VIDA_MAX_LALO: int = 3
const ARCHIVO_PARTIDA: String = "user://partida.json"
const ESCENAS: Dictionary = {
	"entrada": "res://scenes/niveles/Entrada.tscn",
	"medicina": "res://scenes/niveles/Medicina.tscn",
}

var capitulo: int = 0
var vida_don_chava: int = VIDA_MAX_DON_CHAVA
var mensajes_falsos_totales: int = 0
var mensajes_falsos_seguidos: int = 0
var documentos_leidos: Array[StringName] = []
var enemigos_eliminados: Array[StringName] = []
var tiene_pistola: bool = false
var clavos_cargador: int = 0
var clavos_reserva: int = 0
var vida_lalo: int = VIDA_MAX_LALO
var prologo_completo: bool = false
## Dónde aparece Lalo al entrar a una escena (por ejemplo "caseta" o "puerta_medicina").
var punto_entrada: String = ""


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
	vida_lalo = VIDA_MAX_LALO
	prologo_completo = false
	punto_entrada = ""


# ---------- Escenas y partida guardada ----------
func nueva_partida() -> void:
	reiniciar()
	get_tree().change_scene_to_file(ESCENAS["entrada"])


## Cambia de escena; Lalo aparece en el punto indicado.
func ir_a(escena: String, punto: String) -> void:
	punto_entrada = punto
	get_tree().change_scene_to_file(ESCENAS[escena])


func hay_partida() -> bool:
	return FileAccess.file_exists(ARCHIVO_PARTIDA)


func guardar(escena: String, punto: String) -> void:
	var datos: Dictionary = {
		"escena": escena, "punto": punto, "vida": vida_lalo, "pistola": tiene_pistola,
		"cargador": clavos_cargador, "reserva": clavos_reserva, "prologo": prologo_completo,
		"documentos": documentos_leidos, "eliminados": enemigos_eliminados,
		"falsos_totales": mensajes_falsos_totales, "falsos_seguidos": mensajes_falsos_seguidos,
	}
	var archivo := FileAccess.open(ARCHIVO_PARTIDA, FileAccess.WRITE)
	if archivo == null:
		push_error("GameState.guardar: no se pudo escribir %s" % ARCHIVO_PARTIDA)
		return
	archivo.store_string(JSON.stringify(datos, "\t"))


## Carga la partida guardada y va a esa escena. Devuelve false si no hay partida.
func continuar() -> bool:
	if not hay_partida():
		return false
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARCHIVO_PARTIDA))
	if not datos is Dictionary:
		push_error("GameState.continuar: partida dañada")
		return false
	reiniciar()
	vida_lalo = VIDA_MAX_LALO   # al cargar, Lalo vuelve con la salud completa
	tiene_pistola = datos.get("pistola", false)
	clavos_cargador = int(datos.get("cargador", 0))
	clavos_reserva = int(datos.get("reserva", 0))
	prologo_completo = datos.get("prologo", false)
	documentos_leidos.assign(datos.get("documentos", []))
	enemigos_eliminados.assign(datos.get("eliminados", []))
	mensajes_falsos_totales = int(datos.get("falsos_totales", 0))
	mensajes_falsos_seguidos = int(datos.get("falsos_seguidos", 0))
	ir_a(datos.get("escena", "entrada"), datos.get("punto", ""))
	return true


## Después de "Te alcanzaron...": la última partida guardada, o el juego desde el principio.
func continuar_tras_morir() -> void:
	if not continuar():
		nueva_partida()


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
