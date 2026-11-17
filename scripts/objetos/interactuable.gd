class_name Interactuable
extends Area2D
## Zona donde Lalo puede hacer algo con la tecla de interactuar (E): bajar, recoger, revisar...
## Muestra un aviso ("E: recoger") cuando Lalo está dentro y emite `usado` al presionar E.

signal usado

var activo: bool = true:
	set(valor):
		activo = valor
		_actualizar_aviso()

var _cerca: bool = false
var _aviso: Label


func configurar(zona: Rect2, texto: String) -> void:
	position = zona.position
	collision_mask = 2
	var forma := RectangleShape2D.new()
	forma.size = zona.size
	var cs := CollisionShape2D.new()
	cs.shape = forma
	cs.position = zona.size / 2.0
	add_child(cs)
	_aviso = Label.new()
	_aviso.text = "E: " + texto
	var estilo := LabelSettings.new()
	estilo.font_size = 8
	estilo.outline_size = 3
	estilo.outline_color = Color.BLACK
	_aviso.label_settings = estilo
	_aviso.position = Vector2(zona.size.x / 2.0 - 20.0, -12.0)
	_aviso.z_index = 10
	_aviso.visible = false
	add_child(_aviso)
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _unhandled_input(event: InputEvent) -> void:
	if activo and _cerca and not Dialogos.activo and event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		usado.emit()


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_cerca = true
		_actualizar_aviso()


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Lalo:
		_cerca = false
		_actualizar_aviso()


func _actualizar_aviso() -> void:
	if _aviso != null:
		_aviso.visible = activo and _cerca
