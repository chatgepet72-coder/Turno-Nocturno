extends Node
## Diálogos: caja de texto con efecto de máquina de escribir y voz de murmullo por personaje.
## Las líneas vienen de archivos JSON en data/dialogos/.
## Uso: await Dialogos.decir(Dialogos.cargar("res://data/dialogos/prologo.json")["caseta"])
## Con automatico = true las líneas avanzan solas (para el radio mientras Lalo camina).

signal termino

const VOCES: Array[String] = ["lalo_calmado", "lalo_angustia", "chava", "chava_debil"]
## Letras por segundo y separación mínima entre sílabas de cada voz.
const RITMO: Dictionary = {
	"lalo_calmado": [34.0, 0.07], "lalo_angustia": [42.0, 0.055],
	"chava": [26.0, 0.09], "chava_debil": [20.0, 0.11],
}
const COLOR_NOMBRE: Dictionary = {"Lalo": Color(0.55, 0.75, 1.0), "Don Chava": Color(1.0, 0.78, 0.4)}

var activo: bool = false

var _caja: PanelContainer
var _nombre: Label
var _texto: Label
var _indicador: Label
var _silabas: Dictionary = {}       # "voz_vocal" -> AudioStream
var _voz: AudioStreamPlayer
var _estatica: AudioStreamPlayer
var _efecto: AudioStreamPlayer
var _sonidos_radio: Dictionary = {}
var _quiere_avanzar: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_bus_radio()
	_crear_ui()
	_cargar_audio()


func cargar(ruta: String) -> Dictionary:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("Dialogos.cargar: no se pudo abrir %s" % ruta)
		return {}
	var datos: Variant = JSON.parse_string(archivo.get_as_text())
	if not datos is Dictionary:
		push_error("Dialogos.cargar: JSON inválido en %s" % ruta)
		return {}
	return datos


## Muestra las líneas una por una. Termina cuando se cierra la última.
func decir(lineas: Array, automatico: bool = false) -> void:
	activo = true
	_caja.visible = true
	for linea in lineas:
		await _mostrar(linea as Dictionary, automatico)
	_caja.visible = false
	activo = false
	termino.emit()


func _mostrar(linea: Dictionary, automatico: bool) -> void:
	var quien: String = linea.get("quien", "")
	var voz: String = linea.get("voz", "lalo_calmado")
	var por_radio: bool = linea.get("radio", false)
	_nombre.text = quien + ("  (radio)" if por_radio else "")
	_nombre.modulate = COLOR_NOMBRE.get(quien, Color.WHITE)
	_texto.text = linea.get("texto", "")
	_texto.visible_characters = 0
	_indicador.visible = false
	_voz.bus = &"Radio" if por_radio else &"Master"
	if por_radio:
		_efecto.stream = _sonidos_radio["clic"]
		_efecto.play()
		_estatica.play()

	# Máquina de escribir: cada vocal nueva suena como una sílaba de la voz del personaje.
	var ritmo: Array = RITMO.get(voz, [30.0, 0.08])
	var total: int = _texto.text.length()
	var tiempo_silaba: float = 0.0
	var tiempo: float = 0.0
	_quiere_avanzar = false
	while _texto.visible_characters < total:
		if _quiere_avanzar and not automatico:
			_texto.visible_characters = total
			break
		await get_tree().process_frame
		var dt: float = get_process_delta_time()
		tiempo += dt
		tiempo_silaba += dt
		var nuevos: int = mini(total, int(tiempo * ritmo[0]))
		while _texto.visible_characters < nuevos:
			var letra: String = _texto.text[_texto.visible_characters].to_lower()
			_texto.visible_characters += 1
			var vocal: String = _vocal(letra)
			if vocal != "" and tiempo_silaba >= ritmo[1]:
				tiempo_silaba = 0.0
				_voz.stream = _silabas.get(voz + "_" + vocal)
				_voz.pitch_scale = randf_range(0.93, 1.07)
				_voz.play()

	_quiere_avanzar = false
	if automatico:
		await get_tree().create_timer(1.0 + total * 0.03).timeout
	else:
		_indicador.visible = true
		while not _quiere_avanzar:
			await get_tree().process_frame
	if por_radio:
		_estatica.stop()
		_efecto.stream = _sonidos_radio["cierre"]
		_efecto.play()


func _unhandled_input(event: InputEvent) -> void:
	if activo and (event.is_action_pressed("interactuar") or event.is_action_pressed("ui_accept")):
		_quiere_avanzar = true
		get_viewport().set_input_as_handled()


func _vocal(letra: String) -> String:
	match letra:
		"a", "á": return "a"
		"e", "é": return "e"
		"i", "í": return "i"
		"o", "ó": return "o"
		"u", "ú", "ü": return "u"
	return ""


func _crear_bus_radio() -> void:
	# Bus "Radio": banda estrecha y algo de saturación, como un radio de mano.
	if AudioServer.get_bus_index(&"Radio") != -1:
		return
	var i: int = AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, &"Radio")
	AudioServer.set_bus_send(i, &"Master")
	var paso_altos := AudioEffectHighPassFilter.new()
	paso_altos.cutoff_hz = 450.0
	var paso_bajos := AudioEffectLowPassFilter.new()
	paso_bajos.cutoff_hz = 2600.0
	var saturacion := AudioEffectDistortion.new()
	saturacion.drive = 0.45
	saturacion.post_gain = -4.0
	AudioServer.add_bus_effect(i, paso_altos)
	AudioServer.add_bus_effect(i, paso_bajos)
	AudioServer.add_bus_effect(i, saturacion)


func _cargar_audio() -> void:
	for voz in VOCES:
		for vocal in ["a", "e", "i", "o", "u"]:
			_silabas[voz + "_" + vocal] = load("res://assets/audio/voces/%s_%s.wav" % [voz, vocal])
	_sonidos_radio["clic"] = load("res://assets/audio/voces/radio_clic.wav")
	_sonidos_radio["cierre"] = load("res://assets/audio/voces/radio_cierre.wav")
	_voz = AudioStreamPlayer.new()
	_voz.volume_db = -4.0
	add_child(_voz)
	_efecto = AudioStreamPlayer.new()
	_efecto.bus = &"Radio"
	add_child(_efecto)
	_estatica = AudioStreamPlayer.new()   # estática de fondo mientras habla alguien por radio
	_estatica.stream = load("res://assets/audio/efectos/radio_estatica.wav")
	_estatica.volume_db = -20.0
	_estatica.bus = &"Radio"
	_estatica.finished.connect(_repetir_estatica)
	add_child(_estatica)


func _repetir_estatica() -> void:
	if activo:
		_estatica.play()


func _crear_ui() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	_caja = PanelContainer.new()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.04, 0.04, 0.06, 0.88)
	fondo.border_color = Color(0.5, 0.48, 0.42)
	fondo.set_border_width_all(1)
	fondo.set_content_margin_all(8)
	_caja.add_theme_stylebox_override("panel", fondo)
	_caja.position = Vector2(40, 272)
	_caja.size = Vector2(560, 72)
	_caja.custom_minimum_size = Vector2(560, 72)
	_caja.visible = false
	capa.add_child(_caja)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 2)
	_caja.add_child(columna)
	_nombre = _etiqueta(10)
	columna.add_child(_nombre)
	_texto = _etiqueta(10)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(540, 36)
	columna.add_child(_texto)
	_indicador = _etiqueta(8)
	_indicador.text = "E ▸"
	_indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	columna.add_child(_indicador)


func _etiqueta(tam: int) -> Label:
	var l := Label.new()
	var estilo := LabelSettings.new()
	estilo.font_size = tam
	estilo.font_color = Color(0.93, 0.91, 0.85)
	l.label_settings = estilo
	return l
