extends SceneTree
## Enemigos que cazan: La Baja corre, te sigue por las puertas, avienta cosas y se deja ver y huye;
## el encierro traba las puertas hasta clavarla; El Pupitre se congela con la luz y ataca a oscuras.
var fallos := 0
var e: Node2D
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func nuevo(guion: String, pos: Vector2) -> Enemigo:
	var b: Enemigo = load(guion).new()
	b.id = "prueba_%d" % randi(); b.escuela = e; b.position = pos
	e.encuentros.add_child(b)
	return b
func puerta(titulo: String) -> Node2D:
	for p in e.get_tree().get_nodes_in_group("interactivos"):
		if p.get("titulo") == titulo: return p
	return null
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.activo = false; e.archivero.set_physics_process(false)
	for x in e.encuentros.get_children(): x.queue_free()
	e.encuentros._pendientes.clear()
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	j.linterna = false

	# 1) Corre cuando te ve (más rápido que Lalo caminando, 112)
	var b := nuevo("res://src/enemies/la_baja.gd", Vector2(1200, 690))
	b._embestida = 99.0; b._escupir = 99.0; b._lanzar = 99.0
	j.global_position = Vector2(1430, 690)
	await create_timer(0.5).timeout
	check(b.estado == "PERSIGUE" and b.get_real_velocity().length() > 120.0, "Al verte corre (%.0f px/s)" % b.get_real_velocity().length())
	b.queue_free()

	# 2) Te sigue por la puerta si te venía persiguiendo
	var b2 := nuevo("res://src/enemies/la_baja.gd", Vector2(2300, 620))
	b2._embestida = 99.0; b2._escupir = 99.0; b2._lanzar = 99.0
	j.global_position = Vector2(2470, 560)
	await create_timer(0.4).timeout
	var p: Node2D = puerta("Puerta: Aula_07")
	e.cuartos.ultima_puerta = p
	e.cuartos.ultima_llegada = Vector2(2496, 378)
	e.cuartos.ultimo_cruce_ms = Time.get_ticks_msec()
	j.global_position = Vector2(2420, 250)
	var entro := false
	for k in 60:
		await create_timer(0.1).timeout
		if b2.cuarto == "Aula_07": entro = true; break
	check(entro, "Te sigue por la puerta al Aula 07 (está en " + b2.cuarto + ")")
	b2.queue_free()

	# 3) Si te alejas, avienta una silla o un libro
	var b3 := nuevo("res://src/enemies/la_baja.gd", Vector2(1100, 690))
	b3._embestida = 99.0; b3._escupir = 99.0; b3._lanzar = 0.0
	j.global_position = Vector2(1300, 690)
	var lanzo := false
	var vio_lanza := false
	for k in 30:
		await create_timer(0.05).timeout
		if b3.estado == "LANZA": vio_lanza = true
		for n in e.encuentros.get_children():
			if n.get("clase") in ["silla", "libro"]: lanzo = true
		if lanzo: break
	check(vio_lanza and lanzo, "Se prepara y avienta algo (preparó %s, lanzó %s)" % [vio_lanza, lanzo])
	b3.queue_free()
	await create_timer(0.3).timeout

	# 4) Vistazo: se deja ver, grita, huye por la puerta y desaparece
	var b4 := nuevo("res://src/enemies/la_baja.gd", Vector2(2330, 700))
	b4.huye_a = Vector2(2496, 470)
	j.global_position = Vector2(2480, 760)
	await create_timer(0.3).timeout
	check(b4.estado == "HUYE", "Vistazo: al notar a Lalo huye (" + b4.estado + ")")
	await create_timer(3.5).timeout
	check(not is_instance_valid(b4), "Vistazo: desaparece por la puerta")

	# 5) Encierro: con la pistola, el primer cuarto se traba hasta clavarla
	j.inventario.append("Pistola de clavos")
	j.global_position = Vector2(560, 700)   # pasillo
	await create_timer(1.2).timeout
	j.global_position = Vector2(560, 300)   # Aula 02
	await create_timer(0.3).timeout
	check(e.encuentros.cuarto_cerrado() == "Aula_02", "Encierro: el Aula 02 se traba ('" + e.encuentros.cuarto_cerrado() + "')")
	var cruzo: bool = await e.cuartos.cruzar(puerta("Puerta: Aula_02"))
	check(not cruzo, "Encierro: la puerta no deja salir")
	var enemigos: Array = e.encuentros.encierro_activo.get("enemigos", [])
	check(enemigos.size() == 1 and enemigos[0].estado == "CAIDO", "Encierro: sale una Baja agazapada")
	await create_timer(1.9).timeout
	check(enemigos[0].estado != "CAIDO" and is_equal_approx(enemigos[0].vida, enemigos[0].vida_max), "Encierro: se levanta con toda su vida (" + enemigos[0].estado + ")")
	enemigos[0]._quedar_clavado(false)
	await create_timer(1.2).timeout
	check(e.encuentros.cuarto_cerrado() == "" and e.campana.hechos.get("encierro_primero", false), "Encierro: al clavarla se destraba")

	# 6) El Pupitre: con la luz se congela; a oscuras y cerca, ataca
	var pu := nuevo("res://src/enemies/el_pupitre.gd", Vector2(1500, 690))
	j.global_position = Vector2(1300, 690)
	j.apuntado = Vector2.RIGHT
	j.linterna = true
	e.campana.bateria = 80
	await create_timer(0.15).timeout
	check(pu.estado in ["CONGELADO", "HUYE"], "Pupitre: alumbrado se congela (" + pu.estado + ")")
	await create_timer(1.0).timeout
	check(pu.estado in ["HUYE", "QUIETO"] , "Pupitre: luego huye del haz (" + pu.estado + ")")
	j.linterna = false
	pu._espera = 0.0; pu.espera_ataque = 0.0
	pu.global_position = Vector2(1450, 690)
	pu._cambiar("QUIETO")
	var ataco := false
	for k in 40:
		await create_timer(0.05).timeout
		if pu.estado in ["EMBISTE", "ATACA"]: ataco = true; break
	check(ataco, "Pupitre: a oscuras se acerca a patearte")
	print("RESULTADO cazadores: %d fallos" % fallos)
	quit()
