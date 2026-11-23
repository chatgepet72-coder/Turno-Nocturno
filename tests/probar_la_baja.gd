extends SceneTree
## Ataques de La Baja: embestida con aviso, agarre y zafarse, estrellarse, esquiva y hacerse la muerta.
var fallos := 0
var e: Node2D
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func nueva_baja(pos: Vector2) -> Enemigo:
	var b: Enemigo = preload("res://src/enemies/la_baja.gd").new()
	b.id = "prueba_%d" % randi(); b.escuela = e; b.position = pos
	e.encuentros.add_child(b)
	return b
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.activo = false; e.archivero.set_physics_process(false)
	for x in e.encuentros.get_children(): x.queue_free()
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	# 1) Embestida: a media distancia carga (aviso) y se lanza; si alcanza, agarra
	var b := nueva_baja(Vector2(1500, 690))
	j.global_position = Vector2(1640, 690)
	b.estado = "PERSIGUE"; b._escupir = 99.0; b._embestida = 0.0
	await create_timer(0.4).timeout
	check(b.estado == "CARGA", "A media distancia se prepara para embestir (" + b.estado + ")")
	await create_timer(1.1).timeout
	check(b.estado == "AGARRA", "La embestida alcanza y agarra a Lalo (" + b.estado + ")")
	var cordura: float = j.cordura
	await create_timer(0.6).timeout
	check(j.cordura < cordura, "El agarre le baja la Cordura (%.0f -> %.0f)" % [cordura, j.cordura])
	# zafarse presionando
	for k in 7:
		var ev := InputEventAction.new(); ev.action = "interactuar"; ev.pressed = true
		Input.parse_input_event(ev)
		await physics_frame; await physics_frame
		var su := InputEventAction.new(); su.action = "interactuar"; su.pressed = false
		Input.parse_input_event(su)
		await physics_frame
	await create_timer(0.1).timeout
	check(b.estado == "ATURDIDO", "Presionar muchas veces lo zafa y ella queda tambaleando (" + b.estado + ")")
	b.queue_free()
	# 2) Si la esquivas, se estrella contra la pared y queda aturdida
	var b2 := nueva_baja(Vector2(1500, 590))
	j.global_position = Vector2(1500, 500)   # Lalo entre ella y la pared de arriba
	b2.estado = "PERSIGUE"; b2._escupir = 99.0; b2._embestida = 0.0
	await create_timer(0.62).timeout          # ya fijó el rumbo hacia Lalo
	j.global_position = Vector2(1680, 600)    # Lalo se hace a un lado
	var vio_carga: bool = b2.estado == "CARGA"
	await create_timer(0.7).timeout
	check(vio_carga and b2.estado == "ATURDIDO", "Si la esquivas se estrella contra la pared y queda aturdida (" + b2.estado + ")")
	b2.queue_free()
	# 3) Se hace la muerta: tirada, si pasas junto a ella te agarra (60%)
	var agarres := 0
	for intento in 6:
		var b3 := nueva_baja(Vector2(1300, 690))
		j.global_position = Vector2(1500, 690)
		await physics_frame
		for k in 6: b3.recibir_clavo(Vector2.RIGHT)
		await create_timer(2.2).timeout
		j.global_position = Vector2(1330, 690)
		await create_timer(0.3).timeout
		if b3.estado == "AGARRA": agarres += 1
		b3.queue_free()
		j.cordura = 100
		await physics_frame
	check(agarres >= 1 and agarres <= 6, "Tirada, a veces agarra a quien pasa junto (%d de 6)" % agarres)
	# 4) Modo prueba: el agarre suelta solo
	e.modo_prueba = true
	var b4 := nueva_baja(Vector2(1500, 690))
	j.global_position = Vector2(1528, 690)
	b4._empezar_agarre()
	await create_timer(1.4).timeout
	check(b4.estado != "AGARRA", "En modo prueba el agarre suelta solo (" + b4.estado + ")")
	print("RESULTADO la baja: %d fallos" % fallos)
	quit()
