extends Node2D

const Geo = preload("res://src/world/geometria_campus.gd")
const Guardado = preload("res://src/core/guardado.gd")
var estado: int = 2
var mapa: bool = false
var zonas: Dictionary = {}
var jugando: bool = false
var partida_iniciada: bool = false
var tiempo: float = 0.0
var latido: float = 0.0
var recogidos: Array[String] = []
var archivero: CharacterBody2D
var resonancia: Node2D
var sonidos: Node
var interfaz: CanvasLayer
var transicion: bool = false
var rutas_pendientes: bool = false
var peligro: float = 0.0
var oscuridad: ColorRect
var destino_salida: String = "salir"
var autoguardado: float = 0.0
var campana: Node
var cuartos: Node2D
## Modo de prueba (administradores): todo funciona igual, pero nada le hace daño a Lalo ni el Archivero lo archiva.
## Solo existe al correr el juego desde el editor de Godot (F5): en el juego exportado para los
## jugadores no hay botón, ni tecla, ni aviso. Se activa con F9 o desde el menú de pausa. No se guarda.
var modo_prueba: bool = false
## Vista en primera persona (rama primera-persona). Para ver el 2D de antes: variable de entorno TURNO_2D=1.
var vista_fp: Node3D


static func modo_admin_disponible() -> bool:
	return OS.has_feature("editor")
var encuentros: Node2D
var gatillos_mapa: Dictionary = {}
var mente: Node
var inventario_ui: CanvasLayer
var relato: Node
var susto_disponible: bool = true
var susto_espera: float = 0.0
@onready var jugador: CharacterBody2D = $Jugador

func _ready() -> void:
	add_to_group("control")
	campana = preload("res://src/story/campana.gd").new()
	add_child(campana)
	add_child(preload("res://scenes/detalles_principal.tscn").instantiate())
	preload("res://src/world/pared_v12.gd").renovar($Paredes)
	Guardado.configurar()
	get_tree().auto_accept_quit = false
	$Interfaz.hide()
	for objeto in $Objetos.get_children():
		# La alumna tiene ahora un punto interactivo de campaña, sin duplicar su imagen.
		if objeto.name.begins_with("eco_"):
			objeto.hide()
		if objeto.titulo == "Salida":
			objeto.tipo = "salida"
			objeto.add_to_group("interactivos")
		if objeto.has_signal("ruido_emitido"):
			objeto.ruido_emitido.connect(emitir_ruido)
	for monitor in get_tree().get_nodes_in_group("parpadeo"):
		monitor.set_meta("zona","Computo")
		monitor.add_to_group("luces_zona")
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		zonas[luz.get_meta("zona")] = true
		luz.set_meta("energia_base", luz.energy)
	modo_luz(2)
	sonidos = preload("res://src/audio/sonidos.gd").new()
	add_child(sonidos)
	archivero = preload("res://src/enemies/archivero.gd").new()
	add_child(archivero)
	crear_oscuridad()
	cuartos = preload("res://src/world/cuartos.gd").new()
	cuartos.name = "Cuartos"
	cuartos.escuela = self
	add_child(cuartos)
	interfaz = preload("res://src/ui/interfaz.gd").new()
	interfaz.escuela = self
	add_child(interfaz)
	interfaz.mostrar("inicio")
	encuentros = preload("res://src/enemies/encuentros.gd").new()
	encuentros.name = "Enemigos"
	encuentros.escuela = self
	add_child(encuentros)
	encuentros.armar()
	if DisplayServer.get_name() != "headless" and OS.get_environment("TURNO_2D") != "1":
		vista_fp = preload("res://src/fp/primera_persona.gd").new()
		vista_fp.name = "PrimeraPersona"
		vista_fp.escuela = self
		add_child(vista_fp)
	var pistola := preload("res://src/player/pistola_clavos.gd").new()
	pistola.name = "PistolaClavos"
	jugador.add_child(pistola)
	mente=preload("res://src/player/cordura.gd").new()
	add_child(mente)
	relato = preload("res://src/story/relato_turno.gd").new()
	add_child(relato)
	add_child(preload("res://src/world/director_terror.gd").new())
	add_child(preload("res://src/story/ecos_memoria.gd").new())
	resonancia = preload("res://src/world/archivo_resonante.gd").new()
	add_child(resonancia)
	var altavoz := preload("res://src/world/altavoz_escolar.gd").new()
	altavoz.name="AltavozEscolar"
	altavoz.position=Vector2(900,640)
	get_node("DetallesPrincipal").add_child(altavoz)
	await get_tree().physics_frame
	await get_tree().physics_frame
	archivero.construir_rutas()
	cuartos.ocultar_rotulos()
	var refugio := preload("res://src/world/refugio.gd").new()
	refugio.name = "Refugio"
	refugio.escuela = self
	add_child(refugio)
	var entrada: String = get_tree().get_meta("entrada_turno", "inicio")
	get_tree().remove_meta("entrada_turno")
	if entrada == "nuevo":
		iniciar()
	elif entrada == "cargar":
		aplicar_guardado()

func crear_oscuridad() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)
	oscuridad = ColorRect.new()
	oscuridad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	oscuridad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float peligro = 0.0; void fragment(){ vec2 p = UV - vec2(0.5); float borde = smoothstep(0.20, 0.69, length(p)); float grano = fract(sin(dot(floor(FRAGCOORD.xy) + floor(TIME*12.0), vec2(12.9898,78.233)))*43758.5453); float pulso = (0.5 + 0.5*sin(TIME*7.0))*peligro; COLOR = vec4(0.13*pulso, 0.005, 0.015, clamp(borde*0.80 + pulso*0.10 + grano*0.035, 0.0, 0.94)); }"
	var material_oscuro := ShaderMaterial.new()
	material_oscuro.shader = shader
	oscuridad.material = material_oscuro
	capa.add_child(oscuridad)

## Modo de prueba (F9 o menú de pausa): invencible, todo lo demás igual.
func alternar_modo_prueba() -> void:
	if not modo_admin_disponible():
		return
	modo_prueba = not modo_prueba
	interfaz.aviso_prueba.visible = modo_prueba
	jugador.mensaje = "Modo de prueba ACTIVADO: invencible." if modo_prueba else "Modo de prueba desactivado."
	if interfaz.menu_actual == "pausa":
		interfaz.mostrar("pausa")


## Equipo completo para probar sin juntar nada.
func dar_equipo_prueba() -> void:
	if not modo_admin_disponible():
		return
	for objeto in ["Pistola de clavos", "Llave del taller", "Llave maestra"]:
		if not jugador.inventario.has(objeto):
			jugador.inventario.append(objeto)
	for objeto in ["Caja de clavos", "Caja de clavos", "Caja de clavos", "Molotov", "Molotov"]:
		jugador.inventario.append(objeto)
	jugador.mensaje = "Equipo de prueba: pistola, 3 cajas de clavos, 2 molotov y llaves."


## Admin: brincar a un nivel sin jugar los anteriores. Da por hecho lo de los niveles previos
## (objetos, hechos de la historia) para que todo quede coherente, y lleva a Lalo a ese lugar.
const SALTOS: Dictionary = {
	1: ["principal", Vector2(2112, 1180), "Nivel 1 · Edificio principal (Entrada)"],
	2: ["campus", Vector2(950, 2000), "Nivel 2 · Patio"],
	3: ["campus", Vector2(1250, 1320), "Nivel 3 · Cafetería y servicios"],
	4: ["campus", Vector2(1840, 2700), "Nivel 4 · Estacionamiento"],
}
const HECHOS_POR_NIVEL: Dictionary = {
	2: ["computo", "radio", "pala", "bitacora", "refugio_visto", "encierro_primero"],
	3: ["revision_luz", "revision_agua", "memoria_banca", "memoria_desenterrada", "archivo_enterrado", "autorizacion"],
	4: ["talleres", "llave_servicio", "revision_cafe", "revision_banos", "reporte"],
}
const OBJETOS_POR_NIVEL: Dictionary = {
	2: ["Llave maestra", "Expediente de Lalo", "Llave del taller", "Pistola de clavos"],
	3: ["Memoria USB del patio"],
	4: ["Grabación recuperada", "Llave de servicio", "Reporte de cierre"],
}


func saltar_a_nivel(nivel: int) -> void:
	if not modo_admin_disponible() or not SALTOS.has(nivel):
		return
	for n in range(2, nivel + 1):
		for h in HECHOS_POR_NIVEL[n]:
			campana.hechos[h] = true
		for o in OBJETOS_POR_NIVEL[n]:
			if not jugador.inventario.has(o):
				jugador.inventario.append(o)
	campana.etapa = maxi(campana.etapa, nivel) if nivel > 1 else 1
	if campana.has_method("actualizar_accesos"):
		campana.actualizar_accesos()
	var destino: Array = SALTOS[nivel]
	continuar()
	await campana.cambiar_lugar(destino[0], destino[1], false)
	jugador.global_position = destino[1]
	anunciar(str(destino[2]).to_upper(), "Admin · " + campana.objetivo())


## Nueva partida desde el menú: primero el teaser (se puede saltar) y luego el juego.
func iniciar_con_teaser() -> void:
	if transicion or partida_iniciada or has_node("Teaser"):
		return
	var teaser := preload("res://src/story/teaser.gd").new()
	teaser.name = "Teaser"
	teaser.escuela = self
	add_child(teaser)
	teaser.terminado.connect(iniciar, CONNECT_ONE_SHOT)
	teaser.reproducir()

func iniciar() -> void:
	if transicion or partida_iniciada:
		return
	transicion = true
	while not archivero.lista:
		await get_tree().process_frame
	partida_iniciada = true
	interfaz.jugar()
	transicion = true
	anunciar("00:00  /  EL ÚLTIMO CUATRIMESTRE", "El campus entró en Turno Nocturno. Encuentra el radio y cierra tu turno.")
	sonidos.efecto("aviso", Vector2.INF, -16)
	jugador.get_node("Camera2D").zoom = Vector2(1.65, 1.65)
	var animacion := create_tween()
	animacion.tween_property(jugador.get_node("Camera2D"), "zoom", Vector2(1.3, 1.3), 3.0)
	await animacion.finished
	transicion = false
	jugando = true
	if not guardar_partida():
		anunciar("NO SE PUDO GUARDAR", "Revisa el permiso de escritura de la carpeta partidas.")

func continuar() -> void:
	if is_instance_valid(inventario_ui): inventario_ui.queue_free()
	inventario_ui=null
	jugador.bloqueo_entrada = 0.18
	interfaz.jugar()
	jugando = true

func pausar() -> void:
	jugando = false
	jugador.sprite.pause()
	archivero.sprite.pause()
	Controles.detener()
	interfaz.mostrar("pausa")

func abrir_tienda() -> void:
	if not jugando or transicion or jugador.accion != "": return
	jugando = false
	jugador.velocity = Vector2.ZERO
	jugador.sprite.pause()
	archivero.sprite.pause()
	interfaz.menu_actual = "tienda"
	inventario_ui = preload("res://src/ui/inventario.gd").new()
	inventario_ui.escuela = self
	inventario_ui.tienda = true
	add_child(inventario_ui)

func _input(evento: InputEvent) -> void:
	if interfaz == null or evento.is_echo(): return
	if evento is InputEventKey and evento.pressed and evento.physical_keycode == KEY_F9 and partida_iniciada and modo_admin_disponible():
		alternar_modo_prueba()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("inventario"):
		if interfaz.menu_actual in ["inventario", "tienda"]: continuar()
		elif jugando and jugador.accion=="" and not transicion:
			jugando=false
			interfaz.menu_actual="inventario"
			inventario_ui=preload("res://src/ui/inventario.gd").new()
			inventario_ui.escuela=self
			add_child(inventario_ui)
		get_viewport().set_input_as_handled()
		return
	# Los gatillos emiten muchas muestras: una apertura por presión completa.
	if evento is InputEventJoypadMotion and evento.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
		var clave := "%d:%d" % [evento.device,evento.axis]
		var presionado: bool = evento.axis_value > 0.65
		var anterior: bool = gatillos_mapa.get(clave,false)
		gatillos_mapa[clave] = presionado
		if not presionado or anterior: return
	if evento.is_action_pressed("mapa") or evento.is_action_pressed("minimapa"):
		if partida_iniciada and not transicion and jugador.accion == "":
			if interfaz.menu_actual == "mapa": continuar()
			elif jugando: interfaz.mostrar_mapa()
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("ui_cancel"):
		if interfaz.menu_actual in ["dialogo", "mapa", "inventario", "tienda"]:
			continuar()
			get_viewport().set_input_as_handled()
			return
		if interfaz.menu_actual == "opciones":
			interfaz.mostrar("pausa" if partida_iniciada else "inicio")
			get_viewport().set_input_as_handled()
			return
	if evento.is_action_pressed("pausa") and partida_iniciada and not transicion:
		if jugando: pausar()
		elif interfaz.menu_actual in ["pausa","inventario","tienda"]: continuar()
		get_viewport().set_input_as_handled()

func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_CLOSE_REQUEST:
		salir()
	elif que == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for accion in ["izquierda", "derecha", "arriba", "abajo", "correr", "interactuar"]:
			Input.action_release(accion)
		if jugando: pausar()

func _process(delta: float) -> void:
	if not jugando:
		return
	tiempo += delta
	autoguardado += delta
	if autoguardado > 30.0 and puede_guardar() and not jugador.oculto:
		autoguardado = 0
		jugador.mensaje = "Guardado automático en lugar seguro." if guardar_partida() else "No se pudo guardar. Intenta guardar con F5 desde un lugar seguro."
	if tiempo > 22 and not archivero.activo:
		archivero.despertar()
	if rutas_pendientes:
		rutas_pendientes = false
		await get_tree().physics_frame
		archivero.construir_rutas()
	var distancia: float = jugador.global_position.distance_to(archivero.global_position)
	susto_espera = maxf(0, susto_espera - delta)
	if distancia > 650: susto_disponible = true
	if archivero.activo and distancia < 390 and susto_disponible and susto_espera <= 0 and not jugador.oculto:
		susto_disponible = false
		susto_espera = 16
		sonidos.efecto("grito", archivero.position, -16)
		anunciar("ALGO SE ACERCA", "Escucha de qué lado vienen los pasos. Busca dónde ocultarte.")
	peligro = clampf(1.0 - distancia / 480.0, 0, 1) if archivero.activo else 0.0
	oscuridad.material.set_shader_parameter("peligro", peligro)
	jugador.get_node("Camera2D").offset = Vector2(sin(tiempo*29), sin(tiempo*37)) * peligro * peligro * 2.5
	# Cordura: -1 punto cada 10 segundos en cordura.gd; distorsión progresiva.
	latido -= delta
	if peligro > 0.12 and latido <= 0:
		latido = lerpf(1.4, 0.55, peligro)
		sonidos.efecto("latido", Vector2.INF, lerpf(-25, -9, peligro))
		Controles.vibrar(peligro * 0.55, 0.16)
	if Input.is_action_just_pressed("guardar"):
		guardar_manual()
	var cercano: Node2D = jugador.ultimo_escondite if jugador.oculto else jugador.mas_cercano()
	var ayuda: String = "[%s] %s" % [Controles.boton_interaccion(), "Salir del escondite" if jugador.oculto else cercano.titulo] if is_instance_valid(cercano) else ""
	if jugador.accion != "": ayuda = ("EXCAVANDO" if jugador.accion == "excavar" else ("ENTRANDO AL ESCONDITE" if jugador.accion == "entrar" else "SALIENDO DEL ESCONDITE")) + " · %d%%" % int(100 * jugador.avance_accion / jugador.duracion_accion)
	interfaz.actualizar_juego(delta, ayuda)
	for luz in get_tree().get_nodes_in_group("parpadeo"):
		luz.enabled = zonas.get("Computo",false) and not campana.hechos.get("computo",false)
		luz.energy = float(luz.get_meta("energia_base", 0.5)) * (0.8 + 0.2 * sin(tiempo * 9.0))

func emitir_ruido(posicion: Vector2, intensidad: float) -> void:
	if jugando:
		if is_instance_valid(resonancia): resonancia.registrar(posicion,intensidad)
		archivero.escuchar(posicion, intensidad * (1.35 if campana.lugar == "campus" else 1.0))
		for enemigo in get_tree().get_nodes_in_group("enemigos"):
			enemigo.escuchar(posicion, intensidad)

func anunciar(titulo: String, detalle: String) -> void:
	interfaz.anunciar(titulo, detalle)

func archivar() -> void:
	if not jugando:
		return
	if modo_prueba:
		jugador.mensaje = "MODO PRUEBA · Te alcanzaron (en el juego normal aquí terminaría el turno)."
		return
	jugando = false
	transicion = true
	jugador.sprite.pause()
	archivero.sprite.pause()
	Controles.vibrar(0.75, 0.4)
	await interfaz.reproducir_muerte()
	transicion = false
	Controles.detener()
	interfaz.mostrar("muerte")

func ganar() -> void:
	jugando = false
	Controles.detener()
	sonidos.efecto("recoger")
	interfaz.mostrar("victoria")

func modo_luz(modo: int) -> void:
	estado = modo
	$Ambiente.color = Color(0.32, 0.37, 0.45) if modo == 0 else Color(0.045, 0.06, 0.09)
	for zona in zonas:
		zonas[zona] = zona == "Exterior_Caseta" or (modo != 1 and zona == "Entrada")
	campana.alimentado = "Entrada" if modo != 1 else ""
	actualizar_luces()

func alimentar_zona(zona: String) -> void:
	for z in zonas: zonas[z] = z == "Exterior_Caseta"
	if zona != "": zonas[zona] = true
	campana.alimentado=zona
	actualizar_luces()

func alternar_zona(zona: String) -> void:
	alimentar_zona("" if zonas.get(zona,false) else zona)

func alternar_general() -> void:
	campana.elegir_circuito()

func actualizar_luces() -> void:
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		luz.enabled = zonas.get(luz.get_meta("zona"), false)
	for lampara in get_tree().get_nodes_in_group("lamparas"):
		lampara.texture = load("res://assets/sprites/lampara_encendida.png" if zonas.get(lampara.get_meta("zona"), false) else "res://assets/sprites/lampara_apagada.png")

func puede_guardar() -> bool:
	return partida_iniciada and jugador.accion == "" and not transicion and (jugando or interfaz.menu_actual in ["pausa", "inventario", "tienda", "mapa"]) and (not archivero.activo or (jugador.global_position.distance_to(archivero.global_position) > 420 and archivero.estado != "INVESTIGANDO"))

func guardar_manual() -> void:
	if not puede_guardar():
		anunciar("NO ES UN LUGAR SEGURO", "Aléjate del Archivero y espera a que deje de investigar.")
		return
	var correcto := guardar_partida()
	anunciar("PARTIDA GUARDADA" if correcto else "NO SE PUDO GUARDAR", "Puedes continuar este turno desde el menú." if correcto else "Revisa el permiso de escritura de la carpeta partidas.")

func guardar_partida() -> bool:
	var objetos := {}
	for objeto in $Objetos.get_children():
		if objeto.is_queued_for_deletion():
			continue
		if objeto.tipo in ["puerta", "empujar"]:
			objetos[str(objeto.name)] = {"posicion": [objeto.position.x, objeto.position.y], "abierto": objeto.abierto}
	var datos := {"version": 1, "tiempo": tiempo, "estado_luz": estado, "zonas": zonas.duplicate(), "recogidos": recogidos.duplicate(), "objetos": objetos,
		"jugador": {"posicion": [jugador.position.x, jugador.position.y], "inventario": jugador.inventario.duplicate(), "energia": jugador.energia, "cordura": jugador.cordura, "linterna": jugador.linterna, "agachado": jugador.agachado, "sigilo": jugador.sigilo, "sigilo_agotado": jugador.sigilo_agotado, "descanso_sigilo": jugador.descanso_sigilo, "escondite": str(jugador.ultimo_escondite.name) if jugador.oculto and is_instance_valid(jugador.ultimo_escondite) else ""},
		"archivero": {"posicion": [archivero.position.x, archivero.position.y], "destino": [archivero.destino.x, archivero.destino.y], "activo": archivero.activo, "estado": archivero.estado, "memoria": archivero.memoria, "espera": archivero.espera}}
	datos["campana"] = campana.datos()
	return Guardado.guardar(datos)

func cargar() -> void:
	if Guardado.leer().is_empty():
		anunciar("NO HAY PARTIDA VÁLIDA", "Inicia un nuevo turno.")
		return
	reiniciar("cargar")

func reiniciar(entrada: String) -> void:
	Controles.detener()
	get_tree().set_meta("entrada_turno", entrada)
	get_tree().reload_current_scene()

func aplicar_guardado() -> void:
	var datos := Guardado.leer()
	if datos.is_empty():
		interfaz.mostrar("inicio")
		return
	tiempo = datos.tiempo
	estado = int(datos.get("estado_luz", 2))
	zonas.merge(datos.zonas, true)
	actualizar_luces()
	jugador.position = Vector2(datos.jugador.posicion[0], datos.jugador.posicion[1])
	jugador.inventario.assign(datos.jugador.inventario)
	jugador.energia = datos.jugador.energia
	jugador.cordura = datos.jugador.cordura
	jugador.linterna = datos.jugador.linterna
	jugador.agachado = bool(datos.jugador.get("agachado",false))
	jugador.sigilo = float(datos.jugador.get("sigilo",100.0))
	jugador.sigilo_agotado = bool(datos.jugador.get("sigilo_agotado",false))
	jugador.descanso_sigilo = float(datos.jugador.get("descanso_sigilo",0.0))
	jugador.bloqueo_entrada = 0.18
	await campana.restaurar(datos.get("campana", {}))
	recogidos.assign(datos.recogidos)
	for objeto in $Objetos.get_children():
		if str(objeto.name) in recogidos:
			objeto.queue_free()
		elif datos.objetos.has(str(objeto.name)):
			var valor: Dictionary = datos.objetos[str(objeto.name)]
			objeto.position = Vector2(valor.posicion[0], valor.posicion[1])
			if objeto.tipo == "puerta":
				objeto.establecer_puerta(valor.abierto)
	var escondite := $Objetos.get_node_or_null(NodePath(str(datos.jugador.get("escondite", "")))) if not str(datos.jugador.get("escondite", "")).is_empty() else null
	if is_instance_valid(escondite) and escondite.tipo == "escondite":
		jugador.oculto = true
		jugador.ultimo_escondite = escondite
	archivero.position = Vector2(datos.archivero.posicion[0], datos.archivero.posicion[1])
	archivero.destino = Vector2(datos.archivero.destino[0], datos.archivero.destino[1])
	if campana.lugar == "campus" and int(datos.get("campana",{}).get("mapa_version",3)) < Geo.VERSION:
		archivero.position = Geo.ARCHIVERO
		archivero.destino = Geo.ARCHIVERO
	archivero.activo = datos.archivero.activo
	if campana.gracia_activa(): archivero.activo = false
	archivero.visible = archivero.activo
	archivero.estado = datos.archivero.estado
	archivero.memoria = datos.archivero.memoria
	archivero.espera = datos.archivero.espera
	jugador.get_node("Camera2D").reset_smoothing()
	await get_tree().physics_frame
	await get_tree().physics_frame
	archivero.construir_rutas()
	partida_iniciada = true
	jugando = true
	interfaz.jugar()
	anunciar("TURNO RECUPERADO", "Tu expediente todavía sigue abierto.")

func salir() -> void:
	solicitar_salida("salir")

func solicitar_salida(destino: String) -> void:
	destino_salida = destino
	if partida_iniciada and (jugando or interfaz.menu_actual in ["pausa", "opciones", "confirmar_salida", "inventario", "tienda", "mapa"]):
		var seguro := puede_guardar()
		jugando = false
		if not seguro or not guardar_partida():
			# La mochila está sobre los diálogos: retirarla antes de pedir salida.
			if is_instance_valid(inventario_ui): inventario_ui.queue_free()
			inventario_ui = null
			Controles.detener()
			interfaz.mostrar("confirmar_salida")
			return
	confirmar_salida()

func confirmar_salida() -> void:
	Controles.detener()
	Controles.guardar_opciones()
	if destino_salida == "menu":
		reiniciar("inicio")
	else:
		get_tree().quit()
