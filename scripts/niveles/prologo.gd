class_name Prologo
extends Node
## Guion del prólogo (docs/guion.md, "Prólogo: el rondín").
## Por ahora: la plática en la caseta, Don Chava se va a su rondín y la plática por radio sobre el sótano.

const DIALOGOS: String = "res://data/dialogos/prologo.json"
## Ruta de Don Chava: de su silla a la puerta, sale, sube por el camino y voltea a la derecha hacia el patio.
const RUTA_HASTA_PUERTA: Array[Vector2] = [Vector2(812, 905), Vector2(804, 890)]
const RUTA_AFUERA: Array[Vector2] = [Vector2(804, 830), Vector2(788, 770)]
const RUTA_RONDIN: Array[Vector2] = [Vector2(788, 500), Vector2(880, 496), Vector2(1010, 496)]

var _nivel: Node2D
var _negro: ColorRect
var _hora: Label


func iniciar(nivel: Node2D) -> void:
	_nivel = nivel
	_crear_pantalla_negra()
	var lalo: Lalo = nivel.lalo
	var chava: DonChava = nivel.chava
	var dialogos: Dictionary = Dialogos.cargar(DIALOGOS)
	lalo.sentar()

	# 1. Pantalla negra y la hora
	await _esperar(0.8)
	await _fundido(_hora, 1.0, 1.0)
	await _esperar(1.6)
	await _fundido(_hora, 0.0, 0.8)
	await _fundido(_negro, 0.0, 1.5)

	# 2. La plática en la caseta
	await _esperar(0.6)
	await Dialogos.decir(dialogos["caseta"])

	# 3. Don Chava se levanta y se va a su rondín; la cámara lo sigue
	await chava.levantarse()
	chava.camara.make_current()
	await chava.caminar_por(RUTA_HASTA_PUERTA)
	nivel.puerta.poner_abierta(true)
	await chava.caminar_por(RUTA_AFUERA)
	nivel.puerta.poner_abierta(false)
	await chava.caminar_por(RUTA_RONDIN)
	chava.desvanecer(1.8)
	await chava.caminar_por([Vector2(1120, 496)], 45.0)
	await _esperar(0.5)

	# 4. Lalo se levanta y el jugador toma el control
	lalo.camara().make_current()
	await _esperar(0.4)
	await lalo.levantarse()
	nivel.ayuda.visible = true
	nivel.poner_objetivo("Haz tu rondín: estacionamiento y Facultad de Medicina.")

	# 5. Cuando Lalo sale de la caseta, Don Chava le habla por radio
	await nivel.salio_caseta
	await _esperar(5.0)
	await Dialogos.decir(dialogos["radio_sotano"], true)


func _crear_pantalla_negra() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.size = Vector2(640, 360)
	capa.add_child(_negro)
	_hora = Label.new()
	_hora.text = "22:00\nCaseta de vigilancia"
	_hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var estilo := LabelSettings.new()
	estilo.font_size = 14
	estilo.font_color = Color(0.85, 0.83, 0.76)
	_hora.label_settings = estilo
	_hora.size = Vector2(640, 60)
	_hora.position = Vector2(0, 150)
	_hora.modulate.a = 0.0
	capa.add_child(_hora)


func _fundido(nodo: CanvasItem, alfa: float, duracion: float) -> void:
	var t := create_tween()
	t.tween_property(nodo, "modulate:a", alfa, duracion)
	await t.finished


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout
