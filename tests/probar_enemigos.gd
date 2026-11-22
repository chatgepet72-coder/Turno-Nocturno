extends SceneTree
## Prueba de los enemigos nuevos y la pistola de clavos.
## godot --path . --script res://tests/probar_enemigos.gd   (con pantalla guarda capturas en docs/enemigos/)
var e: Node2D
var fallos := 0
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
func foto(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/enemigos"))
	root.get_texture().get_image().save_png("res://docs/enemigos/" + nombre + ".png")
func enemigo(id: String) -> Enemigo:
	return e.encuentros.get_node("enemigo_" + id) as Enemigo
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.Guardado.ruta = "res://partidas/prueba_enemigos.json"
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.activo = false; e.archivero.set_physics_process(false)
	var j: CharacterBody2D = e.jugador
	check(e.encuentros.get_child_count() == 8, "Aparecen los 8 enemigos del archivo")
	check(e.get_node("Objetos").has_node("combate_pistola_taller"), "La pistola está en el Taller")
	# Recoger la pistola
	var pistola: Node = e.get_node("Objetos/combate_pistola_taller")
	j.global_position = pistola.global_position + Vector2(0, 50)
	await create_timer(0.3).timeout
	check(j.mas_cercano() == pistola, "La pistola se alcanza encima de la mesa")
	pistola.interactuar(j)
	check(j.inventario.has("Pistola de clavos"), "Lalo tiene la pistola")
	j.inventario.append("Caja de clavos")
	# La Baja del pasillo: verla y dispararle
	var baja := enemigo("baja_pasillo_2")
	j.global_position = baja.global_position + Vector2(-170, 0)
	j.linterna = true
	await create_timer(0.8).timeout
	check(baja.estado in ["PERSIGUE", "ATACA", "ALERTA"], "La Baja ve a Lalo y lo persigue (" + baja.estado + ")")
	await foto("baja_persigue")
	var arma: Node = j.get_node("PistolaClavos")
	var disparos := 0
	while baja.estado != "CAIDO" and disparos < 12:
		j.apuntado = j.global_position.direction_to(baja.global_position + Vector2(0, -20))
		j.mano = Vector2.ZERO
		arma._espera = 0; arma.disparar(); disparos += 1
		await create_timer(0.35).timeout
	check(baja.estado == "CAIDO", "La Baja cae con clavos (%d disparos)" % disparos)
	await foto("baja_caida")
	await create_timer(0.4).timeout
	arma.cargados = arma.CARGADOR   # recarga para la prueba (los tiros que fallan dependen del tiempo)
	for i in range(3):
		var centro: Vector2 = (baja.get_node("Cuerpo").get_child(0) as Node2D).global_position
		j.apuntado = (centro - (j.global_position + j.mano)).normalized()
		arma._espera = 0; arma.disparar()
		await create_timer(0.3).timeout
	check(baja.estado == "CLAVADO" and "enemigo_baja_pasillo_2" in e.recogidos, "Tres clavos más la dejan clavada y se guarda")
	# Ataque cuerpo a cuerpo
	var otra := enemigo("baja_pasillo_1")
	var cordura_antes: float = j.cordura
	j.global_position = otra.global_position + Vector2(30, 0)
	await create_timer(2.5).timeout
	check(j.cordura < cordura_antes, "La Baja le baja la Cordura a Lalo de cerca (%.0f -> %.0f)" % [cordura_antes, j.cordura])
	await foto("baja_ataca")
	# El Desvelado se congela con la linterna
	j.set_physics_process(false)   # que el ratón no cambie hacia dónde apunta en la prueba
	var des := enemigo("desvelado_computo")
	j.global_position = des.global_position + Vector2(200, -40)
	j.cordura = 100
	j.apuntado = j.global_position.direction_to(des.global_position)
	await create_timer(0.6).timeout
	var antes: Vector2 = des.global_position
	await create_timer(0.8).timeout
	check(des.alumbrado and des.global_position.distance_to(antes) < 4.0, "El Desvelado se congela mientras lo alumbras")
	await foto("desvelado")
	j.set_physics_process(true)
	# El Expediente embosca
	var exp := enemigo("expediente_rectoria")
	j.linterna = false
	j.global_position = exp.global_position + Vector2(60, -10)
	await create_timer(1.6).timeout
	check(not exp.escondido, "El Expediente sale de su escondite cuando Lalo pasa cerca")
	await foto("expediente")
	# El Sinodal
	var sin: Enemigo = enemigo("sinodal_pasillo")
	j.linterna = true
	j.global_position = sin.global_position + Vector2(140, 0)
	j.apuntado = Vector2.LEFT
	j.cordura = 100
	await create_timer(1.0).timeout
	await foto("sinodal")
	check(sin.estado in ["PERSIGUE", "ATACA"], "El Sinodal persigue (" + sin.estado + ")")
	print("RESULTADO enemigos: %d fallos" % fallos)
	quit()
