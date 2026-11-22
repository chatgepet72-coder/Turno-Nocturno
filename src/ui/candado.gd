extends CanvasLayer
## Candado de 4 números. Izquierda/derecha elige el número, arriba/abajo lo cambia,
## Aceptar (E / A) prueba la combinación, Cancelar (Esc / B) cierra. También con el ratón.
## Un intento fallido hace ruido.

signal abierto_con_exito

var escuela: Node
var combinacion: String = "0000"
var titulo: String = "Candado"
var _numeros: Array[int] = [0, 0, 0, 0]
var _actual: int = 0
var _etiquetas: Array[Label] = []
var _aviso: Label
var _hizo_ruido: bool = false


func _ready() -> void:
	layer = 26
	escuela.jugando = false
	escuela.interfaz.menu_actual = "candado"
	escuela.jugador.sprite.pause()
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.82)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var nombre := _texto(titulo.to_upper(), 30, Vector2(0, 150))
	nombre.add_theme_font_override("font", preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"))
	_texto("Un candado de cuatro números.", 18, Vector2(0, 200)).modulate = Color(0.75, 0.8, 0.8)
	for i in 4:
		var x: float = 640.0 - 150.0 + i * 100.0
		var arriba := _boton("▲", Vector2(x - 30, 262))
		arriba.pressed.connect(_cambiar.bind(i, 1))
		var numero := Label.new()
		numero.position = Vector2(x - 40, 300)
		numero.size = Vector2(80, 90)
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		numero.add_theme_font_override("font", preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"))
		numero.add_theme_font_size_override("font_size", 64)
		add_child(numero)
		_etiquetas.append(numero)
		var abajo := _boton("▼", Vector2(x - 30, 396))
		abajo.pressed.connect(_cambiar.bind(i, -1))
	var probar := _boton("Probar", Vector2(640 - 130, 470))
	probar.size.x = 120
	probar.pressed.connect(_probar)
	var salir := _boton("Cancelar", Vector2(640 + 10, 470))
	salir.size.x = 120
	salir.pressed.connect(_cerrar)
	_aviso = _texto("← → elegir · ↑ ↓ cambiar · E / A probar · Esc / B salir", 15, Vector2(0, 540))
	_aviso.modulate = Color(0.7, 0.75, 0.75)
	_pintar()


func _texto(t: String, tam: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size.x = 1280
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	add_child(l)
	return l


func _boton(t: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = Vector2(60, 36)
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


func _pintar() -> void:
	for i in 4:
		_etiquetas[i].text = str(_numeros[i])
		_etiquetas[i].modulate = Color(1.0, 0.85, 0.5) if i == _actual else Color(0.8, 0.8, 0.8)


func _cambiar(indice: int, paso: int) -> void:
	_actual = indice
	_numeros[indice] = posmod(_numeros[indice] + paso, 10)
	escuela.sonidos.efecto("interruptor", Vector2.INF, -18.0)
	_pintar()


func _input(evento: InputEvent) -> void:   # antes que escuela: así Esc cierra el candado y no abre la pausa
	if evento.is_echo():
		return
	if evento.is_action_pressed("ui_left") or evento.is_action_pressed("izquierda"):
		_actual = posmod(_actual - 1, 4)
		_pintar()
	elif evento.is_action_pressed("ui_right") or evento.is_action_pressed("derecha"):
		_actual = posmod(_actual + 1, 4)
		_pintar()
	elif evento.is_action_pressed("ui_up") or evento.is_action_pressed("arriba"):
		_cambiar(_actual, 1)
	elif evento.is_action_pressed("ui_down") or evento.is_action_pressed("abajo"):
		_cambiar(_actual, -1)
	elif evento.is_action_pressed("interactuar") or evento.is_action_pressed("ui_accept"):
		_probar()
	elif evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("pausa"):
		_cerrar()
	else:
		return
	get_viewport().set_input_as_handled()


func _probar() -> void:
	var intento := "".join(_numeros.map(func(n: int) -> String: return str(n)))
	if intento == combinacion:
		escuela.sonidos.efecto("rele", Vector2.INF, -6.0)
		_cerrar()
		abierto_con_exito.emit()
	else:
		escuela.sonidos.efecto("metal", Vector2.INF, -8.0)
		_hizo_ruido = true   # el ruido se nota al cerrar (con el juego en pausa no se oye)
		_aviso.text = "No abre. El candado hizo ruido."
		_aviso.modulate = Color(1.0, 0.6, 0.5)


func _cerrar() -> void:
	queue_free()
	escuela.continuar()
	if _hizo_ruido:
		escuela.emitir_ruido(escuela.jugador.global_position, 0.4)
