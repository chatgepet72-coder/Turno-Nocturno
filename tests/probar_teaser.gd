extends SceneTree
## Teaser del inicio: se salta con Esc y deja el juego listo en la Entrada.
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func ejecutar() -> void:
	var e: Node2D = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.iniciar_con_teaser()
	await create_timer(8.0).timeout
	var teaser: Node = e.get_node_or_null("Teaser")
	check(teaser != null and not e.jugando, "El teaser corre antes del juego")
	check(e.campana.lugar == "campus", "Empieza afuera, en la calle de la universidad")
	var esc := InputEventAction.new()
	esc.action = "pausa"
	esc.pressed = true
	Input.parse_input_event(esc)
	await create_timer(6.0).timeout
	check(e.jugando and e.partida_iniciada, "Saltar el teaser empieza el juego")
	check(e.campana.lugar == "principal" and e.jugador.global_position.distance_to(Vector2(2112, 1120)) < 2.0, "Lalo queda en la Entrada")
	check(not e.has_node("Teaser"), "El teaser se quita al terminar")
	print("RESULTADO teaser: %d fallos" % fallos)
	quit()
