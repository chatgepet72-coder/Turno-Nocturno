extends CanvasLayer
## Teaser del inicio, hecho con el juego mismo (escena 3.1 del guion entregado):
## Lalo llega a la universidad de noche, saluda a Don Chuy en la caseta, entra al edificio,
## se sienta en la sala de espera, se queda dormido a las 23:59 y despierta con todo cambiado.
## Esc / Start / B lo salta. Al terminar empieza el juego (escuela.iniciar()).

signal terminado

const AMBIENTE_ATARDECER := Color(0.34, 0.37, 0.52)
const AMBIENTE_ADENTRO := Color(0.66, 0.7, 0.78)
const AMBIENTE_NOCHE := Color(0.045, 0.06, 0.09)
const CALLE := Vector2(3060, 2878)
const VENTANILLA := Vector2(2600, 2850)
const ANDADOR := Vector2(1505, 2340)
const PUERTA_EDIFICIO := Vector2(1520, 2090)
const ENTRADA_ADENTRO := Vector2(2112, 1300)
const SOFA := Vector2(2002, 1236)
const INICIO_JUEGO := Vector2(2112, 1120)

var escuela: Node2D
var _cancelado: bool = false
var _negro: ColorRect
var _parpado_arriba: ColorRect
var _parpado_abajo: ColorRect
var _caja: PanelContainer
var _quien: Label
var _dialogo: Label
var _carta: Label
var _subcarta: Label
var _reloj: Control
var _saltar: Label
var _sonido: AudioStreamPlayer
var _zumbido: AudioStreamPlayer
var _archiveros: Array[Node2D] = []


func _ready() -> void:
	layer = 27
	process_mode = Node.PROCESS_MODE_ALWAYS
	_negro = _rect(Color.BLACK)
	_negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_parpado_arriba = _rect(Color.BLACK)
	_parpado_arriba.position = Vector2(0, -360)
	_parpado_arriba.size = Vector2(1280, 360)
	_parpado_abajo = _rect(Color.BLACK)
	_parpado_abajo.position = Vector2(0, 720)
	_parpado_abajo.size = Vector2(1280, 360)
	_reloj = preload("res://src/story/reloj_teaser.gd").new()
	_reloj.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reloj.modulate.a = 0.0
	add_child(_reloj)
	_carta = _label(44, Vector2(0, 300), Color("e9e2d2"))
	_carta.add_theme_font_override("font", preload("res://assets/fuentes/Rajdhani-SemiBold.ttf"))
	_subcarta = _label(20, Vector2(0, 362), Color("a9b6b8"))
	_carta.modulate.a = 0.0
	_subcarta.modulate.a = 0.0
	_caja = PanelContainer.new()
	_caja.position = Vector2(290, 560)
	_caja.size = Vector2(700, 96)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.01, 0.02, 0.03, 0.88)
	estilo.border_color = Color("8a6a3c")
	estilo.border_width_left = 3
	estilo.content_margin_left = 20
	estilo.content_margin_right = 20
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 12
	_caja.add_theme_stylebox_override("panel", estilo)
	add_child(_caja)
	var columna := VBoxContainer.new()
	_caja.add_child(columna)
	_quien = Label.new()
	_quien.add_theme_font_size_override("font_size", 15)
	_quien.add_theme_color_override("font_color", Color("c9a46a"))
	columna.add_child(_quien)
	_dialogo = Label.new()
	_dialogo.custom_minimum_size = Vector2(660, 0)
	_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogo.add_theme_font_size_override("font_size", 21)
	_dialogo.add_theme_color_override("font_color", Color("eee6d4"))
	columna.add_child(_dialogo)
	_caja.hide()
	_saltar = _label(14, Vector2(0, 690), Color(0.7, 0.72, 0.72, 0.5))
	_saltar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_saltar.size.x = 1250
	_saltar.text = "Esc / Start · Saltar"
	_sonido = AudioStreamPlayer.new()
	_sonido.bus = "SFX"
	add_child(_sonido)
	_zumbido = AudioStreamPlayer.new()
	_zumbido.bus = "Ambiente"
	var hum := (load("res://assets/audio/teaser/zumbido.wav") as AudioStreamWAV).duplicate() as AudioStreamWAV
	hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hum.loop_end = hum.data.size() / 2
	_zumbido.stream = hum
	_zumbido.volume_db = -20.0
	add_child(_zumbido)


func _rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _label(tam: int, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size.x = 1280
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _input(evento: InputEvent) -> void:
	if _cancelado or evento.is_echo():
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancelado = true
		_terminar()


# ---------- Utilidades de la película ----------
## Espera `s` segundos. Devuelve false si el jugador saltó el teaser (y entonces hay que dejar de seguir).
func _espera(s: float) -> bool:
	if _cancelado:
		return false
	await get_tree().create_timer(s).timeout
	return not _cancelado


func _fundido(nodo: CanvasItem, alfa: float, s: float) -> bool:
	if _cancelado:
		return false
	var t := create_tween()
	t.tween_property(nodo, "modulate:a", alfa, s)
	await t.finished
	return not _cancelado


func _decir(quien: String, texto: String) -> bool:
	if _cancelado:
		return false
	_caja.show()
	_quien.text = quien
	_dialogo.text = texto
	_dialogo.visible_ratio = 0.0
	var escribir: float = clampf(texto.length() * 0.028, 0.5, 2.2)
	var t := create_tween()
	t.tween_property(_dialogo, "visible_ratio", 1.0, escribir)
	await t.finished
	var ok: bool = await _espera(1.1 + texto.length() * 0.035)
	_caja.hide()
	return ok and await _espera(0.25)


func _carta_texto(titulo: String, sub: String, s: float) -> bool:
	_carta.text = titulo
	_subcarta.text = sub
	_carta.modulate.a = 0.0
	_subcarta.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_carta, "modulate:a", 1.0, 0.9)
	t.parallel().tween_property(_subcarta, "modulate:a", 1.0, 1.4)
	await t.finished
	if not await _espera(s):
		return false
	var t2 := create_tween()
	t2.tween_property(_carta, "modulate:a", 0.0, 0.8)
	t2.parallel().tween_property(_subcarta, "modulate:a", 0.0, 0.8)
	await t2.finished
	return not _cancelado


func _sonar(nombre: String, db: float = -6.0, tono: float = 1.0) -> void:
	if _cancelado:
		return
	if nombre in ["tic", "toc"]:
		_sonido.stream = load("res://assets/audio/teaser/%s.wav" % nombre)
		_sonido.volume_db = db
		_sonido.pitch_scale = tono
		_sonido.play()
	else:
		escuela.sonidos.efecto(nombre, Vector2.INF, db)


## Lalo camina hasta `hasta` con su animación de caminar (sin física: es una escena).
func _caminar(hasta: Vector2, velocidad: float = 100.0) -> bool:
	var j: CharacterBody2D = escuela.jugador
	var paso_sonido: float = 0.0
	while j.global_position.distance_to(hasta) > 3.0:
		if _cancelado:
			return false
		var delta: float = get_process_delta_time()
		var dir: Vector2 = j.global_position.direction_to(hasta)
		var avance: float = minf(velocidad * delta, j.global_position.distance_to(hasta))
		j.global_position += dir * avance
		j.distancia_animada += avance
		j.animar_movimiento(dir * velocidad, false)
		paso_sonido -= avance
		if paso_sonido <= 0.0:
			paso_sonido = 46.0
			escuela.sonidos.efecto(j.sonido_paso(), Vector2.INF, -14.0)
		await get_tree().process_frame
	j.animar_movimiento(Vector2.ZERO, false)
	return not _cancelado


func _mirar(direccion: String) -> void:
	var j: CharacterBody2D = escuela.jugador
	j.direccion_animacion = direccion
	j.apuntado = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}[direccion]
	j.animar_movimiento(Vector2.ZERO, false)


func _parpadear(cerrar_a: float, s: float) -> bool:
	if _cancelado:
		return false
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_parpado_arriba, "position:y", -360.0 + 360.0 * cerrar_a, s)
	t.tween_property(_parpado_abajo, "position:y", 720.0 - 360.0 * cerrar_a, s)
	await t.finished
	return not _cancelado


# ---------- La película ----------
func reproducir() -> void:
	escuela.interfaz.menu_actual = "teaser"
	escuela.interfaz.panel.hide()
	escuela.interfaz.fondo.activar(false)
	escuela.sonidos.silenciar_ambiente(false)
	escuela.oscuridad.get_parent().visible = false
	var j: CharacterBody2D = escuela.jugador
	j.linterna = false
	j.get_node("Linterna").enabled = false
	j.sprite.modulate.a = 1.0
	_negro.modulate.a = 1.0
	if not await _carta_texto("UNIVERSIDAD TECNOLÓGICA", "Última semana del cuatrimestre  ·  Cierre de actas  ·  22:41", 2.2):
		return
	# 1. Afuera: llega caminando por la calle
	await escuela.campana.cambiar_lugar("campus", CALLE, false)
	if _cancelado:
		return
	escuela.get_node("Ambiente").color = AMBIENTE_ATARDECER
	(j.get_node("Camera2D") as Camera2D).zoom = Vector2(1.5, 1.5)
	_mirar("left")
	if not await _fundido(_negro, 0.0, 1.6):
		return
	if not await _caminar(VENTANILLA, 92.0):
		return
	_mirar("left")
	var don_chuy := escuela.campana.exterior.get_node_or_null("DonChuy") as Node2D
	if don_chuy != null and don_chuy.get("animacion") != null:
		var anim: AnimatedSprite2D = don_chuy.animacion
		var lado: String = "right" if VENTANILLA.x > don_chuy.global_position.x else "left"
		if anim.sprite_frames.has_animation(lado):
			anim.play(lado)
			anim.pause()
	if not await _espera(0.6):
		return
	if not await _decir("DON CHUY", "¿Tan tarde, joven? Ya casi cierran el sistema."):
		return
	if not await _decir("LALO", "Nomás vengo a que me firmen esta hoja, Don Chuy. Si no, me dan de baja."):
		return
	if not await _decir("DON CHUY", "Ándele pues. Pero no se me vaya a quedar dormido allá adentro, ¿eh?"):
		return
	if not await _decir("LALO", "No, cómo cree. Cinco minutos y me voy."):
		return
	_sonar("rele", -10.0)
	if not await _fundido(_negro, 1.0, 0.8):
		return
	# 2. Por el andador hasta la puerta del edificio
	j.global_position = ANDADOR
	(j.get_node("Camera2D") as Camera2D).reset_smoothing()
	_mirar("up")
	if not await _fundido(_negro, 0.0, 1.0):
		return
	if not await _caminar(PUERTA_EDIFICIO, 96.0):
		return
	_sonar("puerta", -6.0)
	if not await _fundido(_negro, 1.0, 0.7):
		return
	# 3. Adentro: la sala de espera, con todo encendido
	await escuela.campana.cambiar_lugar("principal", ENTRADA_ADENTRO, false)
	if _cancelado:
		return
	escuela.get_node("Ambiente").color = AMBIENTE_ADENTRO
	_zumbido.play()
	_mirar("up")
	if not await _fundido(_negro, 0.0, 1.0):
		return
	if not await _caminar(Vector2(2112, 1235), 96.0):
		return
	if not await _caminar(SOFA, 80.0):
		return
	j.agachado = true   # sentado en el sillón de la sala de espera
	_mirar("down")
	if not await _espera(0.8):
		return
	if not await _decir("LALO", "(frotándose los ojos) Solo necesito que me firmen esta hoja… no me puedo ir sin esto…"):
		return
	# 4. El reloj: 23:58… 23:59
	_reloj.hora = 23 * 60 + 58
	if not await _fundido(_reloj, 1.0, 0.8):
		return
	for i in 6:
		_sonar("tic" if i % 2 == 0 else "toc", -8.0)
		_reloj.segundos = 54 + i
		if not await _espera(1.0):
			return
	_reloj.hora = 23 * 60 + 59
	_reloj.segundos = 0
	_sonar("tic", -6.0)
	if not await _espera(1.2):
		return
	if not await _fundido(_reloj, 0.0, 0.6):
		return
	# 5. Se queda dormido: los párpados pesan
	for paso in [[0.55, 1.2], [0.2, 0.6], [0.8, 1.4], [0.45, 0.8], [1.0, 1.6]]:
		_sonar("tic" if randf() < 0.5 else "toc", -14.0)
		if not await _parpadear(paso[0], paso[1]):
			return
	_zumbido.stop()
	_negro.modulate.a = 1.0
	if not await _espera(1.8):   # un segundo de silencio total
		return
	# 6. Despierta: el reloj suena distinto y todo cambió
	escuela.get_node("Ambiente").color = AMBIENTE_NOCHE
	escuela.oscuridad.get_parent().visible = true
	_poner_archiveros()
	for i in 3:
		_sonar("tic" if i % 2 == 0 else "toc", -4.0, 0.55)
		if not await _espera(1.4):
			return
	_parpado_arriba.position.y = -360.0 + 360.0
	_parpado_abajo.position.y = 720.0 - 360.0
	_negro.modulate.a = 0.0
	if not await _parpadear(0.0, 0.9):
		return
	if not await _decir("LALO", "(desorientado) ¿Qué hora…?"):
		return
	_sonar("golpe", 0.0)
	_sonar("alarma", -6.0)
	if not await _espera(0.7):
		return
	escuela.sonidos.silenciar_ambiente(true)
	for i in 3:
		escuela.get_node("Ambiente").color = AMBIENTE_ADENTRO
		_sonar("interruptor", -12.0)
		if not await _espera(0.08):
			return
		escuela.get_node("Ambiente").color = AMBIENTE_NOCHE
		if not await _espera(0.35):
			return
	escuela.sonidos.silenciar_ambiente(false)
	j.agachado = false   # se levanta de golpe
	_mirar("down")
	if not await _decir("LALO", "¿Hola? ¿Hay alguien ahí? ¿Dirección? ¿Guardia?"):
		return
	# Enciende la linterna del celular
	j.linterna = true
	j.get_node("Linterna").enabled = true
	j.get_node("Linterna").rotation = PI * 0.5
	j.get_node("Linterna").position = Vector2(-7, -26)
	_sonar("linterna", -8.0)
	if not await _espera(1.4):
		return
	for i in 3:
		escuela.sonidos.efecto("papel", j.global_position + Vector2(-380 + i * 60, -260), -10.0)
		if not await _espera(0.55):
			return
	if not await _decir("LALO", "(susurrando, retrocediendo) Esto no estaba aquí…"):
		return
	if not await _fundido(_negro, 1.0, 1.2):
		return
	if not await _carta_texto("TURNO NOCTURNO", "El Último Cuatrimestre", 2.4):
		return
	_terminar()


## Pared de archiveros donde estaba la salida (como en el guion). Solo durante el teaser.
func _poner_archiveros() -> void:
	var textura := load("res://assets/sprites/archivero_mueble.png") as Texture2D
	for i in 4:
		var s := Sprite2D.new()
		s.texture = textura
		s.scale = Vector2.ONE * (78.0 / maxf(textura.get_height(), 1.0))
		s.position = Vector2(2040 + i * 48, 1282)
		s.z_index = 3
		escuela.add_child(s)
		_archiveros.append(s)


## Deja todo como el juego lo espera y empieza la partida.
func _terminar() -> void:
	_zumbido.stop()
	for a in _archiveros:
		if is_instance_valid(a):
			a.queue_free()
	_archiveros.clear()
	var j: CharacterBody2D = escuela.jugador
	j.agachado = false
	if escuela.campana.lugar != "principal":
		await escuela.campana.cambiar_lugar("principal", INICIO_JUEGO, false)
	j.global_position = INICIO_JUEGO
	(j.get_node("Camera2D") as Camera2D).reset_smoothing()
	escuela.get_node("Ambiente").color = AMBIENTE_NOCHE
	escuela.oscuridad.get_parent().visible = true
	j.linterna = true
	escuela.sonidos.silenciar_ambiente(false)
	escuela.interfaz.menu_actual = ""
	terminado.emit()
	var t := create_tween()
	t.tween_property(_negro, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(_caja, "modulate:a", 0.0, 0.3)
	await t.finished
	queue_free()
