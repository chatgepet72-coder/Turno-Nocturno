extends CanvasLayer
## Transición de puerta al estilo de los primeros Resident Evil: la pantalla se va a negro,
## aparece la puerta y se abre lento con el sonido metálico, se oyen los pasos de Lalo
## y el cambio de cuarto ocurre mientras todo está negro.

const CUADROS: int = 4
const ESCALA: float = 2.0   # el arte de la puerta está hecho para 640×360

var _negro: ColorRect
var _puerta: TextureRect
var _vineta: TextureRect
var _texturas: Array[Texture2D] = []
var activa: bool = false


func _ready() -> void:
	layer = 30
	visible = false
	_negro = ColorRect.new()
	_negro.color = Color.BLACK
	_negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_negro)
	for i in range(1, CUADROS + 1):
		_texturas.append(load("res://assets/sprites/ui/transicion/puerta_%d.png" % i) as Texture2D)
	_puerta = TextureRect.new()
	_puerta.texture = _texturas[0]
	_puerta.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_puerta.size = _texturas[0].get_size() * ESCALA
	_puerta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_puerta.position = (Vector2(1280, 720) - _puerta.size) / 2.0
	_puerta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_puerta)
	_vineta = TextureRect.new()
	_vineta.texture = load("res://assets/sprites/ui/transicion/vineta.png") as Texture2D
	_vineta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vineta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vineta)


## Negro, puerta que se abre, `cambiar` (mueve a Lalo) y vuelve el juego. `sonar` reproduce un efecto por nombre.
func cruzar(cambiar: Callable, sonar: Callable) -> void:
	activa = true
	visible = true
	_negro.modulate.a = 0.0
	_puerta.modulate.a = 0.0
	_puerta.texture = _texturas[0]
	await _tween(_negro, "modulate:a", 1.0, 0.3)
	await _tween(_puerta, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(0.2).timeout
	sonar.call("puerta")
	for i in range(1, CUADROS):   # se abre lento, cuadro por cuadro
		await get_tree().create_timer(0.3).timeout
		_puerta.texture = _texturas[i]
	await get_tree().create_timer(0.35).timeout
	await _tween(_puerta, "modulate:a", 0.0, 0.3)
	cambiar.call()
	for i in range(2):   # los pasos de Lalo al entrar, todavía a oscuras
		sonar.call("paso")
		await get_tree().create_timer(0.3).timeout
	await _tween(_negro, "modulate:a", 0.0, 0.45)
	visible = false
	activa = false


func _tween(nodo: Object, propiedad: String, valor: Variant, duracion: float) -> void:
	var t := create_tween()
	t.tween_property(nodo, propiedad, valor, duracion)
	await t.finished
