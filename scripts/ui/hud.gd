class_name Hud
extends CanvasLayer
## Pantalla del jugador: objetivo, ayuda de controles, salud, clavos, avisos y la pantalla de muerte.
## La usan todos los niveles.

## Una sola línea discreta: los controles completos están en el menú de pausa (Esc).
const AYUDA: String = "Esc: pausa, mochila y controles"

var ayuda: Label
var menu: MenuPausa

var _objetivo: Label
var _salud: Label
var _municion: Label
var _icono_pistola: TextureRect
var _aviso: Label
var _lalo: Lalo


func _ready() -> void:
	var estilo := _estilo(9)
	ayuda = _etiqueta(estilo, Vector2(8, 344))
	ayuda.text = AYUDA
	ayuda.modulate.a = 0.6
	_objetivo = _etiqueta(estilo, Vector2(8, 6))
	_objetivo.visible = false
	_salud = _etiqueta(estilo, Vector2(560, 6))
	_icono_pistola = TextureRect.new()
	_icono_pistola.texture = load("res://assets/sprites/ui/pistola_clavos.png") as Texture2D
	_icono_pistola.position = Vector2(560, 300)
	add_child(_icono_pistola)
	_municion = _etiqueta(estilo, Vector2(560, 338))
	_aviso = _etiqueta(_estilo(12), Vector2(0, 60))
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.size = Vector2(640, 20)
	_aviso.modulate.a = 0.0
	GameState.municion_cambio.connect(_al_cambiar_municion)
	_al_cambiar_municion(GameState.clavos_cargador, GameState.clavos_reserva)
	menu = MenuPausa.new()
	add_child(menu)


func conectar(lalo: Lalo) -> void:
	_lalo = lalo
	lalo.vida_cambio.connect(_al_cambiar_vida)
	lalo.murio.connect(_al_morir)
	_al_cambiar_vida(lalo.vida)


func poner_objetivo(texto: String) -> void:
	_objetivo.text = "Objetivo: " + texto
	_objetivo.visible = true


## Al tomar la pistola: un aviso con sus controles (también están en Esc > Controles).
func armado() -> void:
	avisar("Clic o Espacio: disparar   ·   R: recargar")


## Mensaje corto en el centro de arriba que se desvanece solo (por ejemplo, "Partida guardada").
func avisar(texto: String) -> void:
	_aviso.text = texto
	var t := create_tween()
	t.tween_property(_aviso, "modulate:a", 1.0, 0.3)
	t.tween_interval(2.0)
	t.tween_property(_aviso, "modulate:a", 0.0, 0.6)


func _al_cambiar_municion(cargador: int, reserva: int) -> void:
	_icono_pistola.visible = GameState.tiene_pistola
	_municion.visible = GameState.tiene_pistola
	_municion.text = "Clavos %d / %d" % [cargador, reserva]


func _al_cambiar_vida(vida: int) -> void:
	_salud.text = "Salud " + "■".repeat(maxi(vida, 0)) + "□".repeat(maxi(_lalo.vida_maxima - vida, 0))


## "Te alcanzaron..." y después se carga la última partida guardada (o empieza de nuevo si no hay).
func _al_morir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.25, 0.0, 0.0, 0.0)
	fondo.size = Vector2(640, 360)
	add_child(fondo)
	var texto := _etiqueta(_estilo(18), Vector2(0, 160))
	texto.text = "Te alcanzaron..."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.size = Vector2(640, 40)
	texto.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(fondo, "color:a", 0.85, 1.2)
	t.tween_property(texto, "modulate:a", 1.0, 0.8)
	t.tween_interval(2.5)
	t.tween_callback(GameState.continuar_tras_morir)


func _estilo(tam: int) -> LabelSettings:
	var e := LabelSettings.new()
	e.font_size = tam
	e.font_color = Color(0.9, 0.88, 0.8)
	e.outline_size = 3
	e.outline_color = Color.BLACK
	return e


func _etiqueta(estilo: LabelSettings, pos: Vector2) -> Label:
	var l := Label.new()
	l.label_settings = estilo
	l.position = pos
	add_child(l)
	return l
