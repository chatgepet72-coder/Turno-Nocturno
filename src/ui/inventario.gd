extends CanvasLayer
## Mochila (y mostrador de la cafetería) con el diseño del equipo (assets/sprites/inventario):
## panel con pestañas, cuadrícula de 6 columnas con scroll, vista previa grande, descripción,
## línea de Cordura tipo electrocardiograma y botones que cambian según teclado, Xbox o PlayStation.
## Las posiciones salen de assets/sprites/inventario/ui/layout.json (diseñado a 1614 px de ancho).
##
## Controles: flechas / stick / cruceta = elegir · Tab, Shift+Tab, LB / RB = pestaña
##   E / A = Usar · Q / X = Combinar · R / R3 = Tirar · Esc / B / I / Y = Volver.

const Mochila = preload("res://src/player/mochila.gd")
const Productos = preload("res://src/world/productos_cafeteria.gd")
const RAIZ_ARTE: String = "res://assets/sprites/inventario/"
const ANCHO_DISENO: float = 1614.0
const FUENTE := preload("res://assets/fuentes/CrimsonText-Regular.ttf")
const FUENTE_FUERTE := preload("res://assets/fuentes/CrimsonText-SemiBold.ttf")

## Pestañas en el orden del diseño.
const PESTANAS: Array[String] = ["objetos", "documentos", "evidencias", "llaves", "recuperacion", "otros"]

## Cada objeto del juego: [ícono del equipo, pestaña, tipo, descripción].
const CATALOGO: Dictionary = {
	"Pistola de clavos": ["pistola_clavos", "objetos", "ARMA", "La clavadora industrial del Taller. Apunta con clic derecho / LT y dispara con clic izquierdo / RT. Hace ruido. A un enemigo tirado, dispárale 3 clavos más para clavarlo al piso."],
	"Caja de clavos": ["caja_clavos", "objetos", "MUNICIÓN", "Una tira de diez clavos. Se usa sola al recargar (R / cruceta abajo), o combínala con la pistola."],
	"Molotov": ["molotov", "objetos", "ARMA ARROJADIZA", "Lánzala con G / cruceta arriba hacia donde miras. Los enemigos de papel arden y ya no regresan. El fuego también te quema."],
	"Extintor": ["extintor", "objetos", "EMERGENCIA", "Una descarga aturde a los enemigos cercanos y frena al Archivero unos segundos. Un solo uso; el ruido puede atraerlo después."],
	"Grapadora": ["engrapadora", "objetos", "DISTRACCIÓN", "Lánzala hacia donde miras (Q / RB fuera de la mochila). El golpe hace ruido y atrae lo que camina en los pasillos."],
	"Linterna": ["celular_roto", "objetos", "EQUIPO", "La linterna de tu celular, con la pantalla estrellada. F / X la enciende. La batería se acaba y el haz se ve de lejos."],
	"Radio": ["radio", "objetos", "EQUIPO", "La voz de Don Chuy es tu vínculo con la caseta. Los mensajes importantes aparecen como testimonios."],
	"Pala": ["pala", "objetos", "HERRAMIENTA", "Úsala en la tierra removida del patio. Excavar tarda tres segundos y hace ruido."],
	"Alcohol": ["alcohol", "otros", "MATERIAL", "Alcohol de limpieza. Con una botella vacía y un trapo, en la mesa de trabajo del Taller, se vuelve una molotov."],
	"Trapo": ["trapo", "otros", "MATERIAL", "Un trapo sucio. Con una botella vacía y alcohol, en la mesa de trabajo del Taller, se vuelve una molotov."],
	"Botella vacía": ["botella_verde", "otros", "MATERIAL", "Una botella de vidrio vacía. Con alcohol y un trapo, en la mesa de trabajo del Taller, se vuelve una molotov."],
	"Botiquín": ["botiquin", "recuperacion", "RECUPERACIÓN", "Vendas y analgésicos. Recupera 40 puntos de Cordura. Se consume."],
	"Termo de cafe": ["termo", "recuperacion", "RECUPERACIÓN", "Café todavía caliente. Recupera 15 puntos de Cordura. Se consume."],
	"Llave maestra": ["llave_etiqueta", "llaves", "LLAVE", "Abre el expediente de Rectoría. Se usa sola al interactuar."],
	"Llave de servicio": ["llave_azul", "llaves", "LLAVE", "Abre el archivo detrás del mostrador de la cafetería."],
	"Llave del taller": ["llave_roja", "llaves", "LLAVE", "Abre el Taller de conserjería: el cuarto seguro."],
	"Gafete de prefectura": ["gafete", "llaves", "ACCESO", "Un cargo sigue impreso aunque su dueña ya no recuerde su nombre."],
	"Expediente de Lalo": ["carpeta_confidencial", "evidencias", "EVIDENCIA", "Tu firma aparece en una baja que no solicitaste. Recuperar tu nombre es el comienzo, no el final."],
	"Acta sellada": ["sobre_sellado", "evidencias", "EVIDENCIA", "Nadie dejó una hora de salida. Guarda este documento."],
	"Archivo 001": ["expediente_001", "evidencias", "EVIDENCIA", "La primera baja no tiene firma. El sistema empezó a archivar sin autorización."],
	"Sello roto": ["sello_roto", "evidencias", "EVIDENCIA", "El sello del archivo, partido a la mitad. Puede revertir las bajas si conservas el archivo enterrado y al menos 50 de Cordura."],
	"Memoria: maqueta": ["maqueta_escuela", "evidencias", "EVIDENCIA", "Un campus vacío en miniatura. Las aulas siguen ahí; faltan sus nombres."],
	"Memoria USB": ["usb_negra", "evidencias", "GRABACIÓN", "Registros rescatados de las computadoras. Una copia es más difícil de borrar que una persona."],
	"Memoria USB del patio": ["usb_oxidada", "evidencias", "GRABACIÓN", "Desenterrada en el patio. Muéstrala a la Prefecta y después entrégala al de Talleres."],
	"Grabación recuperada": ["usb_rec", "evidencias", "GRABACIÓN", "El de Talleres recuperó las voces. Busca el reporte de cafetería para llevar las pruebas a Don Chuy."],
	"Reporte de cierre": ["portapapeles", "documentos", "MISIÓN", "Llévalo a Don Chuy en vigilancia. Todavía puedes decidir qué ocurrirá con los demás."],
	"Memorándum de conserjería": ["nota_postit", "documentos", "DOCUMENTO", "«A conserjería: la caja de llaves de la Entrada ahora abre con la hora del cierre del sistema, en formato de 24 horas. Ya no la anoten en la pared.»"],
	"Nota de la banca": ["carta_vieja", "documentos", "DOCUMENTO", "Prueba que había alumnos dentro cuando cerraron. Entrégala a la Prefecta."],
	"Memoria de la banca": ["fotografia", "documentos", "DOCUMENTO", "La Prefecta firmaba las bajas. Este fragmento le permite recordar a quiénes pertenecían."],
	"Aviso de vigilancia": ["reporte_vigilancia", "documentos", "NOTA", ""],
	"Bitácora de intendencia": ["libreta", "documentos", "NOTA", ""],
	"Testimonios": ["libreta", "documentos", "DIARIO", ""],
}
## Productos de la cafetería: ícono y nombre que se muestra (sin marcas reales).
const PRODUCTOS_ARTE: Dictionary = {
	"Papas limón": ["papas_verdes", "Papas con limón"], "Churritos": ["palitos", "Churritos"],
	"Agua mineral": ["botella_agua", "Agua mineral"], "Chocolate": ["chocolate", "Chocolate"],
	"Sabritas Original": ["papas_amarillas", "Papas originales"], "Sabritas Adobadas": ["papas_rojas", "Papas adobadas"],
	"Coca-Cola": ["refresco", "Refresco"], "Marías Gamesa": ["galletas", "Galletas María"],
}

var escuela: Node2D
var tienda := false
var seleccion := ""
var pestana: int = 0
var detalle: Label          # el texto de la descripción (lo usan las pruebas)

var _layout: Dictionary = {}
var _escala: float = 1.0
var _panel: Control
var _velo: ColorRect
var _pestanas_nodos: Array[Control] = []
var _activa: TextureRect
var _cuadricula: Control
var _contenido: Control
var _slots: Array[Control] = []
var _items: Array[String] = []
var _cantidades: Dictionary = {}
var _indice: int = 0
var _scroll_fila: int = 0
var _previa: TextureRect
var _nombre: Label
var _tipo: Label
var _ecg_recorte: Control
var _cordura_texto: Label
var _botones: Array = []       # [accion, TextureRect, Label]
var _aviso: Label
var _combinando: String = ""
var _diario_indice: int = -1
var _arte_cache: Dictionary = {}
var _stick_listo: int = 0


func _ready() -> void:
	layer = 25
	_layout = JSON.parse_string(FileAccess.get_file_as_string(RAIZ_ARTE + "ui/layout.json"))
	_velo = ColorRect.new()
	_velo.color = Color(0.01, 0.012, 0.016, 0.78)
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_velo)
	_escala = 1240.0 / ANCHO_DISENO
	_panel = Control.new()
	_panel.scale = Vector2.ONE * _escala
	_panel.size = Vector2(1614, 354)
	_panel.position = Vector2((1280.0 - 1614.0 * _escala) / 2.0, 720.0 - 354.0 * _escala - 70.0)
	add_child(_panel)
	_imagen(_panel, "ui/panel_fondo.png", Vector2.ZERO, Vector2(1614, 354))
	_armar_titulo()
	_armar_pestanas()
	_armar_cuadricula()
	_armar_descripcion()
	_armar_cordura()
	_armar_botones()
	if tienda:
		pestana = PESTANAS.find("recuperacion")
	actualizar()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.18)


# ---------- Armado ----------
func _imagen(padre: Control, ruta: String, pos: Vector2, tam: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture = load(RAIZ_ARTE + ruta) as Texture2D
	t.position = pos
	t.size = tam
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(t)
	return t


func _texto(padre: Control, t: String, pos: Vector2, tam: int, color: Color, fuente: Font = FUENTE) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l


func _armar_titulo() -> void:
	var titulo := _texto(_velo, "MOSTRADOR DE LA CAFETERÍA" if tienda else "MOCHILA", Vector2(34, 318), 32, Color(0.92, 0.9, 0.85), FUENTE_FUERTE)
	titulo.add_theme_constant_override("shadow_offset_y", 3)
	_aviso = _texto(_velo, "", Vector2(0, 330), 19, Color(0.82, 0.8, 0.74))
	_aviso.size.x = 1246.0
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _armar_pestanas() -> void:
	var p: Dictionary = _layout.pestanas
	_activa = _imagen(_panel, "ui/pestana_activa.png", Vector2.ZERO, Vector2(10, 10))
	var lista: Array = p.lista
	for i in lista.size():
		var d: Dictionary = lista[i]
		var zona := Control.new()
		zona.position = Vector2(d.x, p.y)
		zona.size = Vector2(d.ancho, p.alto)
		zona.mouse_filter = Control.MOUSE_FILTER_STOP
		zona.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_cambiar_pestana(i - pestana))
		_panel.add_child(zona)
		var icono := _imagen(zona, d.icono, Vector2(float(d.icono_x) - float(d.x), 8), Vector2(24, 24))
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var nombre := _texto(zona, d.texto, Vector2(float(d.icono_x) - float(d.x) + 32, 2), int(p.texto.tamano), Color(p.texto.color))
		nombre.set_meta("icono", icono)
		_pestanas_nodos.append(zona)


func _armar_cuadricula() -> void:
	var c: Dictionary = _layout.cuadricula
	_cuadricula = Control.new()
	_cuadricula.position = Vector2(c.area[0], c.area[1])
	_cuadricula.size = Vector2(c.area[2], c.area[3])
	_cuadricula.clip_contents = true
	_panel.add_child(_cuadricula)
	_contenido = Control.new()
	_cuadricula.add_child(_contenido)


func _armar_descripcion() -> void:
	var v: Dictionary = _layout.vista_previa
	_previa = TextureRect.new()
	_previa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_previa.position = Vector2(v.area[0] + 20, v.area[1] + 6)
	_previa.size = Vector2(v.area[2] - 40, v.area[3] - 12)
	_previa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_previa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_previa.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_previa.pivot_offset = _previa.size / 2.0
	_panel.add_child(_previa)
	var d: Dictionary = _layout.descripcion
	_nombre = _texto(_panel, "", Vector2(d.nombre.pos[0], d.nombre.pos[1] - 8), int(d.nombre.tamano), Color(d.nombre.color))
	_tipo = _texto(_panel, "", Vector2(d.tipo.pos[0], d.tipo.pos[1] - 4), int(d.tipo.tamano), Color(d.tipo.color))
	var sep := ColorRect.new()
	sep.color = Color(d.separador.color)
	sep.position = Vector2(d.separador.x[0], d.separador.y)
	sep.size = Vector2(float(d.separador.x[1]) - float(d.separador.x[0]), 1)
	_panel.add_child(sep)
	detalle = _texto(_panel, "", Vector2(d.texto.pos[0], d.texto.pos[1]), int(d.texto.tamano) - 2, Color(d.texto.color))
	detalle.size = Vector2(float(d.texto.ancho_max), 128)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detalle.clip_text = true
	detalle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _armar_cordura() -> void:
	var c: Dictionary = _layout.cordura
	_cordura_texto = _texto(_panel, c.etiqueta.texto, Vector2(c.etiqueta.pos[0], c.etiqueta.pos[1] - 6), int(c.etiqueta.tamano), Color(c.etiqueta.color))
	_ecg_recorte = Control.new()
	_ecg_recorte.position = Vector2(c.ecg.pos[0], c.ecg.pos[1])
	_ecg_recorte.size = Vector2(534, 48)
	_ecg_recorte.clip_contents = true
	_panel.add_child(_ecg_recorte)
	_imagen(_ecg_recorte, "ui/salud_ecg.png", Vector2.ZERO, Vector2(534, 48))


func _armar_botones() -> void:
	for b in _layout.botones:
		var zona := Control.new()
		zona.position = Vector2(float(b.centro[0]) - 18, float(b.centro[1]) - 18)
		zona.size = Vector2(float(b.texto_x) - float(b.centro[0]) + 120, 36)
		zona.mouse_filter = Control.MOUSE_FILTER_STOP
		var accion: String = b.accion
		zona.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_accion(accion))
		_panel.add_child(zona)
		var icono := _imagen(zona, b.iconos.teclado, Vector2(0, 0), Vector2(36, 36))
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var t := _texto(zona, "Comprar" if tienda and accion == "usar" else b.texto, Vector2(float(b.texto_x) - float(b.centro[0]) + 18, -2), int(b.tamano), Color(b.color))
		_botones.append([accion, icono, t, b.iconos])
	# Tirar (solo suministros): R / R3
	var tirar := _texto(_panel, "", Vector2(800, 304), 19, Color(0.75, 0.74, 0.7))
	_botones.append(["tirar", null, tirar, {}])


# ---------- Datos ----------
func arte(item: String) -> Array:   # [id del ícono, pestaña, tipo, descripción, nombre visible]
	if PRODUCTOS_ARTE.has(item):
		var p: Array = Productos.PRODUCTOS[item]
		return [PRODUCTOS_ARTE[item][0], "recuperacion", "CONSUMIBLE · $1" if tienda else "CONSUMIBLE", p[4], PRODUCTOS_ARTE[item][1]]
	if CATALOGO.has(item):
		var c: Array = CATALOGO[item]
		var texto: String = c[3]
		if texto == "":
			texto = _texto_de_nota(item)
		return [c[0], c[1], c[2], texto, item]
	var nota: String = _texto_de_nota(item)
	if nota != "":
		return ["nota_postit", "documentos", "NOTA", nota, item]
	return ["carta_vieja", "otros", "OBJETO", "Objeto recuperado durante el turno.", item]


## Compatibilidad con código y pruebas anteriores.
func datos(item: String) -> Array:
	var a := arte(item)
	return [a[0], a[2], a[3]]


func _textura(id: String, grande: bool) -> Texture2D:
	var clave := id + ("_g" if grande else "")
	if _arte_cache.has(clave):
		return _arte_cache[clave]
	var rutas: Array[String] = ["iconos_256/%s.png" % id]
	if grande:
		rutas = ["vistas_previas_512/%s.png" % id, "iconos_512/%s.png" % id, "iconos_256/%s.png" % id]
	var tex: Texture2D = null
	for r in rutas:
		if ResourceLoader.exists(RAIZ_ARTE + r):
			tex = load(RAIZ_ARTE + r) as Texture2D
			break
	_arte_cache[clave] = tex
	return tex


## Las notas del mundo (data/enemigos.json) se pueden volver a leer en la mochila.
func _texto_de_nota(item: String) -> String:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemigos.json"))
	if d is Dictionary:
		for o in d.get("objetos", []):
			if o.get("titulo", "") == item and o.get("texto", "") != "":
				return str(o.texto)
	return ""


func _todos_los_objetos() -> Array[String]:
	var lista: Array[String] = []
	if tienda:
		lista.assign(Productos.PRODUCTOS.keys())
		return lista
	lista.assign(escuela.jugador.inventario.duplicate())
	lista.append("Linterna")
	for par in [["radio", "Radio"], ["pala", "Pala"], ["llave_servicio", "Llave de servicio"], ["reporte", "Reporte de cierre"]]:
		if escuela.campana.hechos.get(par[0], false):
			lista.append(par[1])
	lista.append("Testimonios")
	return lista


# ---------- Pintar ----------
func actualizar() -> void:
	_cantidades.clear()
	_items.clear()
	for item in _todos_los_objetos():
		if arte(item)[1] != PESTANAS[pestana]:
			continue
		if not _cantidades.has(item):
			_items.append(item)
			_cantidades[item] = 0
		_cantidades[item] += 1
	# Pestaña activa
	var p: Dictionary = _layout.pestanas
	for i in _pestanas_nodos.size():
		var d: Dictionary = p.lista[i]
		var activa: bool = i == pestana
		var etiqueta := _pestanas_nodos[i].get_child(1) as Label
		etiqueta.add_theme_color_override("font_color", Color(p.texto.color_activa if activa else p.texto.color))
		_pestanas_nodos[i].modulate = Color(1, 1, 1, 1.0 if activa else 0.8)
		if activa:
			_activa.position = Vector2(float(d.x) - 4, float(p.y) - 4)
			_activa.size = Vector2(float(d.ancho) + 8, float(p.alto) + 8)
	_pintar_slots()
	_indice = clampi(_indice, 0, maxi(0, _items.size() - 1))
	_seleccionar_indice(_indice)
	_pintar_cordura()
	_pintar_aviso()


func _pintar_slots() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()
	var c: Dictionary = _layout.cuadricula
	var paso := Vector2(c.paso[0], c.paso[1])
	var origen := Vector2(float(c.origen[0]) - float(c.area[0]), float(c.origen[1]) - float(c.area[1]))
	var total: int = maxi(_items.size(), 12)
	total = int(ceil(total / 6.0)) * 6 + 6   # siempre asoma una fila vacía abajo
	for k in total:
		var pos: Vector2 = origen + Vector2(k % 6, k / 6) * paso
		var slot := Control.new()
		slot.position = pos
		slot.size = Vector2(c.tamano_slot[0], c.tamano_slot[1])
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		_contenido.add_child(slot)
		var fondo := _imagen(slot, "ui/slot.png", Vector2(-4, -4), Vector2(114, 96))
		fondo.name = "Fondo"
		if k < _items.size():
			var item: String = _items[k]
			var icono := TextureRect.new()
			icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icono.texture = _textura(arte(item)[0], false)
			icono.position = Vector2(10, 4)
			icono.size = Vector2(86, 80)
			icono.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(icono)
			var cuantos: int = _cantidades[item]
			if cuantos > 1:
				var n := _texto(slot, str(cuantos), Vector2(80, 58), 22, Color.WHITE, FUENTE_FUERTE)
				n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				n.size.x = 22
			var indice := k
			slot.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					if _indice == indice and ev.double_click:
						_accion("usar")
					_seleccionar_indice(indice))
			slot.mouse_entered.connect(func() -> void: _seleccionar_indice(indice))
		_slots.append(slot)


func _seleccionar_indice(k: int) -> void:
	if _items.is_empty():
		_indice = 0
		seleccion = ""
		_previa.texture = null
		_nombre.text = "Vacío"
		_tipo.text = ""
		detalle.text = "No tienes nada en esta pestaña."
		_marcar(-1)
		_pintar_botones()
		return
	_indice = clampi(k, 0, _items.size() - 1)
	seleccionar(_items[_indice])
	# scroll: que la fila elegida quede visible (2 filas visibles)
	var fila: int = _indice / 6
	if fila < _scroll_fila:
		_scroll_fila = fila
	elif fila > _scroll_fila + 1:
		_scroll_fila = fila - 1
	var paso_y: float = float(_layout.cuadricula.paso[1])
	create_tween().tween_property(_contenido, "position:y", -_scroll_fila * paso_y, 0.12)
	_marcar(_indice)


func _marcar(k: int) -> void:
	for i in _slots.size():
		var fondo := _slots[i].get_node("Fondo") as TextureRect
		var elegido: bool = i == k
		fondo.texture = load(RAIZ_ARTE + ("ui/slot_seleccionado.png" if elegido else "ui/slot.png")) as Texture2D
		fondo.position = Vector2(-10, -10) if elegido else Vector2(-4, -4)
		fondo.size = Vector2(126, 108) if elegido else Vector2(114, 96)


func seleccionar(item: String) -> void:
	var nuevo: bool = seleccion != item
	seleccion = item
	var a := arte(item)
	var i: int = _items.find(item)
	if i >= 0:
		_indice = i
	_nombre.text = a[4]
	_tipo.text = str(a[2]).to_upper()
	detalle.text = a[3]
	if item == "Testimonios":
		detalle.text = _texto_testimonios(false)
	if _combinando != "":
		detalle.text = "Combinar %s con… elige otro objeto y presiona Usar." % _combinando
	_previa.texture = _textura(a[0], true)
	if nuevo:
		_previa.modulate.a = 0.4
		_previa.rotation = -0.05
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(_previa, "modulate:a", 1.0, 0.15)
		t.tween_property(_previa, "rotation", 0.0, 0.2)
	_pintar_botones()


func _pintar_cordura() -> void:
	var cordura: float = escuela.jugador.cordura
	_ecg_recorte.size.x = 534.0 * clampf(cordura / 100.0, 0.08, 1.0)
	var estado: String = "Estable" if cordura > 66 else ("Alterado" if cordura > 33 else "Al límite")
	_cordura_texto.text = "Cordura"
	_cordura_texto.tooltip_text = estado


func _pintar_aviso() -> void:
	if tienda:
		_aviso.text = "Saldo: $%d  ·  Todo a $1  ·  Mochila: %d / %d suministros" % [escuela.campana.monedas, Mochila.usados(escuela.jugador.inventario), Mochila.CAPACIDAD]
	else:
		_aviso.text = "Suministros %d / %d  ·  Pila %d%%  ·  $%d" % [Mochila.usados(escuela.jugador.inventario), Mochila.CAPACIDAD, int(escuela.campana.bateria), escuela.campana.monedas]


func _pintar_botones() -> void:
	var dispositivo: String = _dispositivo()
	for b in _botones:
		var accion: String = b[0]
		if accion == "tirar":
			var puede: bool = not tienda and Mochila.ocupa(seleccion)
			(b[2] as Label).text = ("R3" if dispositivo != "teclado" else "R") + " · Tirar" if puede else ""
			continue
		(b[1] as TextureRect).get_parent().visible = not (tienda and accion == "combinar")
		(b[1] as TextureRect).texture = load(RAIZ_ARTE + str(b[3][dispositivo])) as Texture2D
		var texto: String = {"usar": "Usar", "combinar": "Combinar", "volver": "Volver"}[accion]
		if accion == "usar":
			texto = _texto_usar()
		if accion == "combinar" and _combinando != "":
			texto = "Cancelar"
		(b[2] as Label).text = texto


func _texto_usar() -> String:
	if tienda:
		return "Comprar"
	if seleccion == "Termo de cafe" or seleccion in ["Agua mineral", "Coca-Cola"]:
		return "Beber"
	if Productos.PRODUCTOS.has(seleccion):
		return "Comer"
	if arte(seleccion)[1] == "documentos":
		return "Leer"
	return "Usar"


func _dispositivo() -> String:
	var controles: Node = get_node_or_null("/root/Controles")
	if controles == null or not controles.usando_mando:
		return "teclado"
	var nombre := Input.get_joy_name(maxi(int(controles.mando), 0)).to_lower()
	return "playstation" if "playstation" in nombre or "dual" in nombre or "sony" in nombre or "ps" in nombre else "xbox"


# ---------- Controles ----------
func _input(ev: InputEvent) -> void:
	if ev is InputEventJoypadMotion:
		# El stick manda muchas muestras: un paso por empujón, y repite despacio si se mantiene.
		if absf(ev.axis_value) < 0.6 or Time.get_ticks_msec() < _stick_listo:
			if absf(ev.axis_value) < 0.3 and ev.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
				_stick_listo = 0
			get_viewport().set_input_as_handled()
			return
		_stick_listo = Time.get_ticks_msec() + 260
	if ev.is_echo() and not (ev.is_action("ui_left") or ev.is_action("ui_right") or ev.is_action("ui_up") or ev.is_action("ui_down")):
		return
	var manejado := true
	if ev.is_action_pressed("ui_left") or ev.is_action_pressed("izquierda"):
		_mover(-1)
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("derecha"):
		_mover(1)
	elif ev.is_action_pressed("ui_up") or ev.is_action_pressed("arriba"):
		_mover(-6)
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("abajo"):
		_mover(6)
	elif (ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_TAB) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		var atras: bool = (ev is InputEventKey and ev.shift_pressed) or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_LEFT_SHOULDER)
		_cambiar_pestana(-1 if atras else 1)
	elif ev.is_action_pressed("interactuar") or ev.is_action_pressed("ui_accept"):
		_accion("usar")
	elif (ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_Q) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_X):
		_accion("combinar")
	elif (ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_R) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_RIGHT_STICK):
		_accion("tirar")
	elif ev.is_action_pressed("pausa") or ev.is_action_pressed("ui_cancel") or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		if _combinando != "":
			_combinando = ""
			seleccionar(seleccion)
		else:
			_accion("volver")
	else:
		manejado = false
	if manejado:
		get_viewport().set_input_as_handled()


func _mover(paso: int) -> void:
	if _items.is_empty():
		return
	var nuevo: int = _indice + paso
	if paso == 1 or paso == -1:
		nuevo = posmod(nuevo, _items.size())
	nuevo = clampi(nuevo, 0, _items.size() - 1)
	if nuevo != _indice:
		escuela.sonidos.efecto("papel", Vector2.INF, -26.0)
	_seleccionar_indice(nuevo)


func _cambiar_pestana(paso: int) -> void:
	if tienda or paso == 0:
		return
	pestana = posmod(pestana + paso, PESTANAS.size())
	_indice = 0
	_scroll_fila = 0
	_contenido.position.y = 0
	escuela.sonidos.efecto("papel", Vector2.INF, -20.0)
	actualizar()


func _accion(accion: String) -> void:
	match accion:
		"usar":
			if _combinando != "":
				_combinar(_combinando, seleccion)
			else:
				utilizar()
		"combinar":
			if tienda or seleccion == "":
				return
			_combinando = "" if _combinando != "" else seleccion
			seleccionar(seleccion)
		"tirar":
			descartar_unidad()
		"volver":
			escuela.continuar()


## Combinar como en Resident Evil: clavos + pistola = recargar; la molotov se arma en la mesa del Taller.
func _combinar(a: String, b: String) -> void:
	_combinando = ""
	var par := [a, b]
	par.sort()
	var j: CharacterBody2D = escuela.jugador
	if par == ["Caja de clavos", "Pistola de clavos"]:
		var arma: Node = j.get_node_or_null("PistolaClavos")
		if arma != null and arma.cargados < arma.CARGADOR:
			escuela.continuar()
			arma.recargar()
			return
		detalle.text = "La pistola ya está cargada."
	elif a in ["Alcohol", "Trapo", "Botella vacía"] and b in ["Alcohol", "Trapo", "Botella vacía"] and a != b:
		detalle.text = "Para armar la molotov necesitas los tres (botella vacía, alcohol y trapo) y la mesa de trabajo del Taller."
	else:
		detalle.text = "Eso no se puede combinar."
	_pintar_botones()


func utilizar() -> void:
	var j: CharacterBody2D = escuela.jugador
	if seleccion == "":
		return
	if tienda:
		if not Productos.PRODUCTOS.has(seleccion):
			return
		if escuela.campana.monedas < 1:
			detalle.text = "No tienes monedas. Busca en bancos, escritorios y patio."
			return
		if not Mochila.cabe(j.inventario, seleccion):
			detalle.text = "Mochila llena (%d/%d). Cierra el mostrador y consume o tira un suministro." % [Mochila.usados(j.inventario), Mochila.CAPACIDAD]
			return
		escuela.campana.monedas -= 1
		j.inventario.append(seleccion)
		escuela.sonidos.efecto("recoger", Vector2.INF, -20)
		_pintar_aviso()
		detalle.text = "Compraste %s por $1. En tu mochila: %d." % [arte(seleccion)[4], j.inventario.count(seleccion)]
		return
	if seleccion == "Testimonios":
		detalle.text = _texto_testimonios(true)
		return
	if Productos.PRODUCTOS.has(seleccion):
		if Productos.consumir(escuela, seleccion):
			actualizar()
		else:
			detalle.text = "Tus medidores ya están llenos. Consérvalo para más tarde."
		return
	if seleccion == "Termo de cafe" and j.inventario.has(seleccion):
		if j.cordura >= 100:
			detalle.text = "No necesitas beber ahora. Conserva el termo para más tarde."
			return
		j.inventario.erase(seleccion)
		j.cordura = minf(100, j.cordura + 15)
		escuela.sonidos.efecto("recoger", Vector2.INF, -20)
		actualizar()
	elif seleccion == "Botiquín" and j.inventario.has(seleccion):
		if j.cordura >= 100:
			detalle.text = "No lo necesitas ahora. Guárdalo para más tarde."
			return
		j.inventario.erase(seleccion)
		j.cordura = minf(100, j.cordura + 40)
		escuela.sonidos.efecto("recoger", Vector2.INF, -18)
		actualizar()
	elif seleccion == "Grapadora" and j.inventario.has(seleccion):
		escuela.continuar()
		j.distraer()
	elif seleccion == "Extintor" and j.inventario.has(seleccion):
		j.inventario.erase(seleccion)
		escuela.continuar()
		var a: CharacterBody2D = escuela.archivero
		var rayo := PhysicsRayQueryParameters2D.create(j.position, a.position, 1, [j.get_rid(), a.get_rid()])
		if a.activo and j.position.distance_to(a.position) < 210 and escuela.get_world_2d().direct_space_state.intersect_ray(rayo).is_empty():
			a.repelido = 3
		for enemigo in get_tree().get_nodes_in_group("enemigos"):
			if j.position.distance_to(enemigo.global_position) < 210:
				enemigo.aturdir(3.0)
		escuela.sonidos.efecto("radio_estatica", j.position, -10)
		escuela.emitir_ruido(j.position, 0.8)
		j.mensaje = "Extintor descargado. Aprovecha para alejarte."


func _texto_testimonios(siguiente: bool) -> String:
	var texto: String = "Tu expediente fue cerrado sin tu firma. Busca a quienes todavía recuerdan su nombre."
	if escuela.campana.hechos.get("computo", false):
		texto = "La de Cómputo quedó encerrada. Su memoria USB está enterrada en el patio."
	if escuela.campana.hechos.get("archivo_enterrado", false):
		texto += " La memoria contiene una grabación de la noche en que desaparecieron."
	if escuela.campana.hechos.get("reporte", false):
		texto = "El reporte prueba que el campus no está vacío. Don Chuy puede abrir la salida; el Sello Roto puede liberar a los demás."
	var recuerdos: Array[String] = []
	for i in range(4):
		if escuela.campana.hechos.get("testimonio_%d" % (i + 1), false):
			recuerdos.append(preload("res://src/story/ecos_memoria.gd").RELATOS[i])
	if recuerdos.is_empty():
		return texto
	if siguiente or _diario_indice < 0:
		_diario_indice = (_diario_indice + 1) % recuerdos.size()
	return recuerdos[_diario_indice] + "  (%d / %d)" % [_diario_indice + 1, recuerdos.size()]


func descartar_unidad() -> void:
	if tienda or not Mochila.ocupa(seleccion):
		return
	escuela.jugador.inventario.erase(seleccion)
	escuela.sonidos.efecto("papel", Vector2.INF, -14.0)
	actualizar()
