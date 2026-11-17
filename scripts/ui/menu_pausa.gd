class_name MenuPausa
extends CanvasLayer
## Pausa (Esc): Continuar, Mochila, Controles y Salir al menú. La mochila también se abre con Tab.
## Mochila: los objetos ocupan espacios (8); los documentos van aparte y se pueden volver a leer.
## También muestra documentos al recogerlos (leer()).

enum Vista { OCULTO, PRINCIPAL, MOCHILA, CONTROLES, LECTURA }

const CONTROLES: String = """Caminar ........................ W A S D o flechas
Correr ......................... Shift (hace ruido)
Apuntar ........................ Ratón
Linterna ....................... F
Disparar clavos ................ Clic izquierdo o Espacio
Recargar ....................... R
Usar, abrir, recoger ........... E
Radio .......................... Q
Mochila ........................ Tab
Pausa .......................... Esc"""

var _vista: Vista = Vista.OCULTO
var _fondo: ColorRect
var _paneles: Dictionary = {}
var _botones: VBoxContainer
var _lista: VBoxContainer
var _detalle: Label
var _espacios: Label
var _lectura_titulo: Label
var _lectura_texto: Label
var _seleccion: String = ""
var _volver_a: Vista = Vista.OCULTO


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 0.82)
	_fondo.size = Vector2(640, 360)
	add_child(_fondo)
	_armar_principal()
	_armar_mochila()
	_armar_controles()
	_armar_lectura()
	_mostrar(Vista.OCULTO)
	GameState.inventario_cambio.connect(_llenar_mochila)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		match _vista:
			Vista.OCULTO:
				if not Dialogos.activo:
					_mostrar(Vista.PRINCIPAL)
			Vista.PRINCIPAL:
				_mostrar(Vista.OCULTO)
			Vista.LECTURA:
				_mostrar(_volver_a)
			_:
				_mostrar(Vista.PRINCIPAL)
	elif event.is_action_pressed("inventario"):
		get_viewport().set_input_as_handled()
		if _vista == Vista.OCULTO and not Dialogos.activo:
			_mostrar(Vista.MOCHILA)
		elif _vista == Vista.MOCHILA:
			_mostrar(Vista.OCULTO)
	elif _vista == Vista.LECTURA and (event.is_action_pressed("interactuar") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_mostrar(_volver_a)


## Muestra un documento a pantalla completa (al recogerlo o desde la mochila).
func leer(id: String) -> void:
	var datos: Dictionary = GameState.objetos.get(id, {})
	_lectura_titulo.text = datos.get("nombre", "")
	_lectura_texto.text = datos.get("texto", "")
	_volver_a = _vista if _vista != Vista.LECTURA else Vista.OCULTO
	_mostrar(Vista.LECTURA)


func _mostrar(vista: Vista) -> void:
	_vista = vista
	visible = vista != Vista.OCULTO
	get_tree().paused = visible
	for v in _paneles:
		_paneles[v].visible = v == vista
	match vista:
		Vista.PRINCIPAL:
			(_botones.get_child(0) as Button).grab_focus()
		Vista.MOCHILA:
			_llenar_mochila()


# ---------- Paneles ----------
func _armar_principal() -> void:
	var caja := _panel(Vista.PRINCIPAL, Vector2(220, 90), Vector2(200, 180))
	caja.add_child(_titulo("PAUSA"))
	_botones = VBoxContainer.new()
	_botones.add_theme_constant_override("separation", 6)
	caja.add_child(_botones)
	_boton(_botones, "Continuar", func() -> void: _mostrar(Vista.OCULTO))
	_boton(_botones, "Mochila", func() -> void: _mostrar(Vista.MOCHILA))
	_boton(_botones, "Controles", func() -> void: _mostrar(Vista.CONTROLES))
	_boton(_botones, "Salir al menú", _salir)


func _armar_mochila() -> void:
	var caja := _panel(Vista.MOCHILA, Vector2(60, 30), Vector2(520, 300))
	caja.add_child(_titulo("MOCHILA"))
	_espacios = _texto(9)
	caja.add_child(_espacios)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var desliza := ScrollContainer.new()
	desliza.custom_minimum_size = Vector2(240, 200)
	fila.add_child(desliza)
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 3)
	desliza.add_child(_lista)
	_detalle = _texto(10)
	_detalle.custom_minimum_size = Vector2(240, 200)
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(_detalle)
	var pie := _texto(8)
	pie.text = "Enter: usar o leer   ·   Esc: volver   ·   Tab: cerrar"
	caja.add_child(pie)


func _llenar_mochila() -> void:
	for h in _lista.get_children():
		h.queue_free()
	_espacios.text = "Espacios: %d / %d" % [GameState.espacios_usados(), GameState.ESPACIOS_MOCHILA]
	_detalle.text = "La mochila está vacía." if GameState.inventario.is_empty() else "Elige un objeto."
	var primero: Button = null
	for id in GameState.inventario:
		var datos: Dictionary = GameState.objetos.get(id, {})
		var n: int = GameState.inventario[id]
		var nombre: String = datos.get("nombre", id) + (" x%d" % n if n > 1 else "")
		var b := _boton(_lista, nombre, _usar.bind(id))
		var icono := load("res://assets/sprites/objetos/iconos/%s.png" % datos.get("icono", "documento")) as Texture2D
		b.icon = icono
		b.expand_icon = false
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_entered.connect(_elegir.bind(id))
		if primero == null:
			primero = b
	if _vista == Vista.MOCHILA and primero != null:
		primero.grab_focus.call_deferred()


func _elegir(id: String) -> void:
	_seleccion = id
	var datos: Dictionary = GameState.objetos.get(id, {})
	var extra: String = ""
	if datos.get("documento", false):
		extra = "\n\n(Enter: leer)"
	elif datos.get("usable", false):
		extra = "\n\n(Enter: usar)"
	_detalle.text = datos.get("nombre", id) + "\n\n" + datos.get("descripcion", "Un documento.") + extra


func _usar(id: String) -> void:
	var datos: Dictionary = GameState.objetos.get(id, {})
	if datos.get("documento", false):
		leer(id)
	elif id == "vendas":
		var lalo := get_tree().get_first_node_in_group("jugador") as Lalo
		if lalo == null or lalo.vida >= lalo.vida_maxima:
			_detalle.text = "No estás herido."
			return
		lalo.curar(1)
		GameState.quitar("vendas")
		_detalle.text = "Te vendaste. +1 de salud."


func _armar_controles() -> void:
	var caja := _panel(Vista.CONTROLES, Vector2(110, 50), Vector2(420, 260))
	caja.add_child(_titulo("CONTROLES"))
	var t := _texto(10)
	t.text = CONTROLES
	caja.add_child(t)
	var pie := _texto(8)
	pie.text = "Esc: volver"
	caja.add_child(pie)


func _armar_lectura() -> void:
	var caja := _panel(Vista.LECTURA, Vector2(120, 40), Vector2(400, 280))
	_lectura_titulo = _titulo("")
	caja.add_child(_lectura_titulo)
	_lectura_texto = _texto(10)
	_lectura_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lectura_texto.custom_minimum_size = Vector2(380, 200)
	caja.add_child(_lectura_texto)
	var pie := _texto(8)
	pie.text = "E: cerrar"
	caja.add_child(pie)


func _salir() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# ---------- Utilidades ----------
func _panel(vista: Vista, pos: Vector2, tam: Vector2) -> VBoxContainer:
	var p := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.05, 0.06, 0.06, 0.95)
	estilo.border_color = Color(0.45, 0.5, 0.45)
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", estilo)
	p.position = pos
	p.custom_minimum_size = tam
	add_child(p)
	_paneles[vista] = p
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	p.add_child(caja)
	return caja


func _titulo(texto: String) -> Label:
	var l := _texto(14)
	l.text = texto
	return l


func _texto(tam: int) -> Label:
	var l := Label.new()
	var e := LabelSettings.new()
	e.font_size = tam
	e.font_color = Color(0.9, 0.88, 0.8)
	l.label_settings = e
	return l


func _boton(padre: Container, texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 10)
	b.pressed.connect(accion)
	padre.add_child(b)
	return b
