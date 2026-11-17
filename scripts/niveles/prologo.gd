class_name Prologo
extends Node
## Guion del prólogo (docs/guion.md, "Prólogo: el rondín").
## Hasta ahora: la caseta, Don Chava se va, el radio, el sótano, el apagón, el maniquí, el Comandante y la reja.

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
	nivel.poner_objetivo("Haz tu rondín: revisa el estacionamiento y el patio.")

	# 5. Cuando Lalo sale de la caseta, Don Chava le habla por radio
	await nivel.salio_caseta
	await _esperar(5.0)
	await Dialogos.decir(dialogos["radio_sotano"], true)

	# 6. Don Chava deja de contestar
	nivel.poner_objetivo("Sigue tu rondín por el estacionamiento y el patio.")
	await _esperar(25.0)
	nivel.poner_objetivo("Don Chava no ha vuelto a hablar. Llámalo por radio (Q).")
	await _esperar_radio()
	await _decir(dialogos["radio_sin_respuesta"], true)
	nivel.poner_objetivo("Busca a Don Chava en la obra del Edificio Central.")

	# 7. El sótano: la escalera derrumbada y la linterna de Don Chava
	var hueco: Interactuable = nivel.agregar_interactuable(Rect2(1740, 880, 184, 150), "bajar al sótano")
	await hueco.usado
	hueco.activo = false
	await _fundido(_negro, 1.0, 0.6)
	nivel.entrar_sotano()
	await _esperar(0.4)
	await _fundido(_negro, 0.0, 0.8)
	await _decir(dialogos["sotano_llegada"], true)
	nivel.poner_objetivo("Revisa el sótano.")
	var linterna: Interactuable = nivel.agregar_interactuable(Rect2(380, 1610, 110, 70), "recoger")
	await linterna.usado
	linterna.activo = false
	nivel.recoger_linterna_chava()
	lalo.controlable = false
	await _decir(dialogos["sotano_linterna"])
	nivel.parar_respiracion()   # la respiración se detiene en cuanto Lalo grita
	await _esperar(2.0)
	await _decir(dialogos["sotano_silencio"])
	lalo.controlable = true
	nivel.poner_objetivo("Sal del sótano y pide ayuda.")

	# 8. Arriba todo cambió: apagón, tierra negra y el maniquí en la banca
	var escalera: Interactuable = nivel.agregar_interactuable(Rect2(40, 1580, 90, 70), "subir")
	await escalera.usado
	escalera.activo = false
	await _fundido(_negro, 1.0, 0.6)
	nivel.apagon()
	nivel.salir_sotano()
	nivel.mostrar_maniqui()
	await _esperar(0.6)
	await _fundido(_negro, 0.0, 1.0)
	await _decir(dialogos["arriba_apagon"], true)
	_vigilar_maniqui(dialogos)

	# 9. La llamada al Comandante
	nivel.poner_objetivo("Pide ayuda por radio (Q).")
	await _esperar_radio()
	await _decir(dialogos["comandante"], true)

	# 10. La reja: no hay forma de salir
	nivel.poner_objetivo("Ve a la reja de la entrada.")
	var pluma: Interactuable = nivel.agregar_interactuable(Rect2(440, 980, 250, 90), "revisar la pluma")
	await pluma.usado
	pluma.activo = false
	await _decir(dialogos["reja"], true)
	nivel.poner_objetivo("No hay forma de salir... (continuará)")


## El maniquí: Lalo lo ve en la banca y, cuando deja de verlo, ya no está.
func _vigilar_maniqui(dialogos: Dictionary) -> void:
	var notificador: VisibleOnScreenNotifier2D = _nivel.notificador_maniqui
	if not notificador.is_on_screen():
		await notificador.screen_entered
	await _esperar(1.2)
	await _decir(dialogos["maniqui"], true)
	if notificador.is_on_screen():
		await notificador.screen_exited
	_nivel.ocultar_maniqui()


## Espera a que el jugador presione Q (radio) cuando no hay un diálogo en curso.
func _esperar_radio() -> void:
	while true:
		await get_tree().process_frame
		if not Dialogos.activo and Input.is_action_just_pressed("radio"):
			return


## Igual que Dialogos.decir, pero espera su turno si ya hay otro diálogo en pantalla.
func _decir(lineas: Array, automatico: bool = false) -> void:
	while Dialogos.activo:
		await get_tree().process_frame
	await Dialogos.decir(lineas, automatico)


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
