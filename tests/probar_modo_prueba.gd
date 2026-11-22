extends SceneTree
## Modo de prueba (admin): los enemigos atacan igual, pero Lalo no pierde Cordura ni lo archivan.
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func ejecutar() -> void:
	var e: Node2D = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.activo = false
	var j: CharacterBody2D = e.jugador
	e.alternar_modo_prueba()
	check(e.modo_prueba and e.interfaz.aviso_prueba.visible, "F9 activa el modo de prueba y se ve el aviso")
	var baja: Enemigo = e.encuentros.get_node("enemigo_baja_pasillo_1")
	j.global_position = baja.global_position + Vector2(30, 0)
	await create_timer(3.0).timeout
	check(baja.estado in ["PERSIGUE", "ATACA"], "La Baja sigue atacando (" + baja.estado + ")")
	check(j.cordura >= 100.0, "Lalo no pierde Cordura (%.0f)" % j.cordura)
	e.archivero.activo = true
	e.archivero.global_position = j.global_position + Vector2(8, 0)
	e.archivero.comprobar_captura()
	await create_timer(0.3).timeout
	check(e.jugando, "El Archivero no lo archiva")
	e.archivero.activo = false
	e.archivero.global_position = Vector2(3264, 670)
	e.dar_equipo_prueba()
	check(j.inventario.has("Pistola de clavos") and j.inventario.count("Molotov") >= 2, "El equipo de prueba da pistola y molotovs")
	e.alternar_modo_prueba()
	j.cordura = 50.0
	check(j.cordura == 50.0 and not e.modo_prueba, "Al apagarlo la Cordura vuelve a bajar normal")
	print("RESULTADO modo prueba: %d fallos" % fallos)
	quit()
