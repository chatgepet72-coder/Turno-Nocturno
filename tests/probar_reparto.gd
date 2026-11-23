extends SceneTree
## Reparto de objetos: nada tirado en el pasillo, todo alcanzable, cajones, receta de la molotov y cuarto seguro.
var fallos := 0
var e: Node2D
func _initialize() -> void: call_deferred("ejecutar")
func check(ok: bool, texto: String) -> void:
	print(("OK " if ok else "FALLO ") + texto)
	if not ok: fallos += 1
## Desde algún punto libre alrededor, ¿Lalo lo tiene como lo más cercano para usar?
func alcanzable(obj: Node2D) -> bool:
	var j: CharacterBody2D = e.jugador
	var consulta := PhysicsShapeQueryParameters2D.new()
	var forma := CircleShape2D.new(); forma.radius = 9.0
	consulta.shape = forma; consulta.collision_mask = 1; consulta.exclude = [j.get_rid()]
	for radio in [20, 34, 48, 62, 76]:
		for paso in range(16):
			var p: Vector2 = obj.global_position + Vector2.from_angle(paso * TAU / 16) * radio
			consulta.transform = Transform2D(0, p)
			if not j.get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty(): continue
			if e.cuartos.cuarto_en(p) != e.cuartos.cuarto_en(obj.global_position): continue
			j.global_position = p
			if j.mas_cercano() == obj: return true
	return false
func ejecutar() -> void:
	e = load("res://scenes/escuela.tscn").instantiate()
	root.add_child(e); current_scene = e
	await create_timer(2.0).timeout
	e.partida_iniciada = true; e.jugando = true; e.interfaz.jugar()
	e.archivero.activo = false; e.archivero.set_physics_process(false)
	var j: CharacterBody2D = e.jugador
	j.set_physics_process(false)
	# 1) Pasillo limpio: a lo mucho un objeto suelto en el piso (los extintores van en la pared)
	var en_pasillo := 0
	for padre in [e.get_node("Objetos"), e.get_node("DetallesPrincipal")]:
		for o in padre.get_children():
			if o is Node2D and e.cuartos.cuarto_en(o.global_position) == "Pasillo":
				if o.get("tipo") in ["recoger", "decoracion", "campana"] and not str(o.get("titulo")) in ["Extintor", "Lampara encendida", "Altavoz · programar aviso"]:
					en_pasillo += 1
	check(en_pasillo <= 1, "En el pasillo queda a lo mucho una cosa tirada (%d)" % en_pasillo)
	# 2) Todo lo del reparto se alcanza
	var sin_alcance: Array = []
	for o in e.get_node("Objetos").get_children():
		if str(o.name).begins_with("combate_") and e.cuartos.cuarto_en(o.global_position) != "":
			if not alcanzable(o): sin_alcance.append(str(o.name))
	check(sin_alcance.is_empty(), "Todos los objetos, notas y cajones se pueden usar " + str(sin_alcance))
	# 3) Cajón: da sus cosas una vez
	var cajon: Node = e.get_node("Objetos/combate_cajon_aula_07")
	var antes: int = j.inventario.size()
	cajon.interactuar(j)
	check(j.inventario.has("Caja de clavos") and j.inventario.has("Botiquín"), "El cajón del Aula 07 da clavos y un botiquín")
	cajon.interactuar(j)
	check(j.inventario.size() == antes + 2, "Un cajón revisado ya no da nada")
	# 4) Molotov: botella + alcohol + trapo
	var mesa: Node = e.get_node("Objetos/combate_mesa_trabajo")
	j.inventario.append("Alcohol"); j.inventario.append("Trapo")
	mesa.interactuar(j)
	var opciones: Array = []
	for n in e.interfaz.columna.get_children():
		if n is Button: opciones.append(n.text)
	check(not str(opciones).contains("Fabricar molotov"), "Sin botella no se puede fabricar la molotov")
	e.continuar()
	j.inventario.append("Botella vacía")
	mesa.interactuar(j)
	var boton: Button = null
	for n in e.interfaz.columna.get_children():
		if n is Button and n.text.begins_with("Fabricar molotov"): boton = n
	check(boton != null, "Con botella, alcohol y trapo aparece Fabricar molotov")
	if boton: boton.pressed.emit()
	check(j.inventario.has("Molotov") and not j.inventario.has("Botella vacía"), "Fabricar gasta los tres y da una molotov")
	# 5) Cuarto seguro: música al entrar, silencio al salir
	var refugio: Node = e.get_node("Refugio")
	j.global_position = Vector2(3650, 1150)
	await create_timer(0.3).timeout
	check(refugio.adentro and refugio._musica.playing, "En el cuarto seguro suena la música")
	j.global_position = Vector2(2112, 690)
	await create_timer(2.2).timeout
	check(not refugio.adentro and not refugio._musica.playing, "Al salir la música se va")
	print("RESULTADO reparto: %d fallos" % fallos)
	quit()
