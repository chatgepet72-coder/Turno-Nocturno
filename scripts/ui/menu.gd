extends Control
## Menú de inicio: continuar la partida guardada o empezar una nueva.

var _opciones: Label


func _ready() -> void:
	_opciones = Label.new()
	var estilo := LabelSettings.new()
	estilo.font_size = 10
	estilo.font_color = Color(0.75, 0.72, 0.66)
	_opciones.label_settings = estilo
	_opciones.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opciones.size = Vector2(640, 30)
	_opciones.position = Vector2(0, 230)
	if GameState.hay_partida():
		_opciones.text = "Enter: Continuar        N: Nueva partida"
	else:
		_opciones.text = "Enter: Nueva partida"
	add_child(_opciones)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not GameState.continuar():
			GameState.nueva_partida()
	elif event is InputEventKey and event.pressed and (event as InputEventKey).physical_keycode == KEY_N:
		GameState.nueva_partida()
