extends Node3D
## Levanta en 3D el edificio principal a partir del mapa 2D (que sigue siendo el que manda: choques,
## enemigos, puzzles). Pisos, paredes con azulejo y zoclo, plafón, puertas dobles con marco,
## lámparas que siguen a las luces del juego y muebles armados con piezas.
## 44 px del mapa = 1 metro.

const M = preload("res://src/fp/materiales_3d.gd")
const ESC: float = 1.0 / 44.0
const ALTO: float = 3.0            # altura de techo
const ALTO_AZULEJO: float = 1.25   # azulejo de la pared hasta esta altura
const ALTO_PUERTA: float = 2.25

var escuela: Node2D
var _objetos_3d: Dictionary = {}   # nodo 2D -> nodo 3D (para quitarlo cuando se recoge)
var _puertas: Dictionary = {}      # puerta 2D -> [hoja izquierda, hoja derecha]
var _luces: Dictionary = {}        # PointLight2D -> OmniLight3D
var _forzadas: Dictionary = {}     # puerta 2D -> [abierta, sentido] durante una transición
var velocidad_puertas: float = 0.2


static func a3d(p: Vector2, altura: float = 0.0) -> Vector3:
	return Vector3(p.x * ESC, altura, p.y * ESC)


func construir() -> void:
	_pisos_y_techos()
	_paredes()
	for o in escuela.get_node("Objetos").get_children():
		_objeto(o)
	var detalles := escuela.get_node_or_null("DetallesPrincipal")
	if detalles != null:
		for o in detalles.get_children():
			_objeto(o)
	for luz in get_tree().get_nodes_in_group("luces_zona"):
		_lampara(luz as PointLight2D)


## Cada cuadro: puertas que el Archivero abre, objetos recogidos y luces que se prenden o parpadean.
func sincronizar() -> void:
	for o2 in _objetos_3d.keys():
		var o3: Node3D = _objetos_3d[o2]
		if not is_instance_valid(o2) or (o2 as CanvasItem).is_queued_for_deletion():
			o3.queue_free()
			_objetos_3d.erase(o2)
		else:
			o3.visible = (o2 as CanvasItem).visible
	for p in _puertas:
		if not is_instance_valid(p):
			continue
		var abierta: bool = p.abierto
		var sentido: float = 1.0
		var rapidez: float = 0.2
		if _forzadas.has(p):
			abierta = _forzadas[p][0]
			sentido = _forzadas[p][1]
			rapidez = velocidad_puertas
		var hojas: Array = _puertas[p]
		(hojas[0] as Node3D).rotation.y = lerp_angle((hojas[0] as Node3D).rotation.y, (-1.35 * sentido if abierta else 0.0), rapidez)
		(hojas[1] as Node3D).rotation.y = lerp_angle((hojas[1] as Node3D).rotation.y, (1.35 * sentido if abierta else 0.0), rapidez)
	for l2 in _luces:
		var l3: OmniLight3D = _luces[l2]
		if is_instance_valid(l2):
			l3.visible = (l2 as PointLight2D).enabled and (l2 as PointLight2D).is_visible_in_tree()
			l3.light_energy = (l2 as PointLight2D).energy * 1.4


# ---------- Piezas básicas ----------
func caja(centro: Vector3, tam: Vector3, mat: Material, padre: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	b.material = mat
	mi.mesh = b
	mi.position = centro
	padre.add_child(mi)
	return mi


func cilindro(centro: Vector3, radio: float, alto: float, mat: Material, padre: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radio
	c.bottom_radius = radio
	c.height = alto
	c.radial_segments = 12
	c.material = mat
	mi.mesh = c
	mi.position = centro
	padre.add_child(mi)
	return mi


## Un cuadro plano con una imagen del juego (una cara de mueble, un letrero, algo pegado a la pared).
func lamina(centro: Vector3, ancho: float, alto: float, tex: Texture2D, normal: Vector3, padre: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(ancho, alto)
	q.material = M.imagen(tex)
	mi.mesh = q
	padre.add_child(mi)
	mi.position = centro
	mi.rotation.y = atan2(normal.x, normal.z)   # el cuadro mira hacia +Z; se gira hacia la normal
	return mi


func _pisos_y_techos() -> void:
	var plafon := M.repetida("plafon", 1.2)
	for p in escuela.get_node("Pisos").get_children():
		var sp := p as Sprite2D
		if sp == null or sp.texture == null:
			continue
		var r: Rect2 = sp.get_transform() * sp.get_rect()
		var piso := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = r.size * ESC
		var mp := StandardMaterial3D.new()
		mp.albedo_texture = sp.texture
		mp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mp.roughness = 0.55   # piso encerado: brilla un poco con la linterna
		pm.material = mp
		piso.mesh = pm
		piso.position = a3d(r.get_center())
		add_child(piso)
		var techo := MeshInstance3D.new()
		var tm := PlaneMesh.new()
		tm.size = pm.size
		tm.flip_faces = true
		tm.material = plafon
		techo.mesh = tm
		techo.position = a3d(r.get_center(), ALTO)
		add_child(techo)


func _paredes() -> void:
	var yeso := M.repetida("yeso", 2.0)
	var azulejo := M.repetida("azulejo", 1.0)
	var zoclo := M.color(Color(0.16, 0.17, 0.18), 0.6)
	var franja := M.color(Color(0.33, 0.42, 0.40), 0.7)
	for m in escuela.get_node("Paredes").get_children():
		var col := m.get_node_or_null("Colision") as CollisionShape2D
		if col == null or not col.shape is RectangleShape2D:
			continue
		var s: Vector2 = (col.shape as RectangleShape2D).size
		var c: Vector2 = (m as Node2D).position + col.position
		var tam := Vector3(maxf(s.x * ESC, 0.3), ALTO, maxf(s.y * ESC, 0.3))
		caja(a3d(c, ALTO / 2.0), tam, yeso)
		# Azulejo hasta media altura, una franja de color encima y zoclo abajo (un poco salidos)
		caja(a3d(c, ALTO_AZULEJO / 2.0), Vector3(tam.x + 0.03, ALTO_AZULEJO, tam.z + 0.03), azulejo)
		caja(a3d(c, ALTO_AZULEJO + 0.04), Vector3(tam.x + 0.05, 0.08, tam.z + 0.05), franja)
		caja(a3d(c, 0.06), Vector3(tam.x + 0.06, 0.12, tam.z + 0.06), zoclo)


func _lampara(luz: PointLight2D) -> void:
	if luz == null:
		return
	var p: Vector2 = luz.global_position
	var l := OmniLight3D.new()
	l.position = a3d(p, ALTO - 0.25)
	l.light_color = Color(0.72, 1.0, 0.9)
	l.omni_range = 6.5
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	add_child(l)
	_luces[luz] = l
	# El gabinete de la lámpara fluorescente en el plafón
	caja(a3d(p, ALTO - 0.03), Vector3(1.25, 0.05, 0.32), M.color(Color(0.55, 0.56, 0.55)))
	caja(a3d(p, ALTO - 0.06), Vector3(1.15, 0.02, 0.22), M.emisivo(Color(0.75, 0.95, 0.9), 0.9))


# ---------- Objetos del mapa ----------
func _sprite_de(o: Node) -> Sprite2D:
	var sp := o.get_node_or_null("Sprite") as Sprite2D
	if sp != null and sp.texture != null:
		return sp
	for h in o.get_children():
		if h is Sprite2D and (h as Sprite2D).texture != null:
			return h
	return null


func _objeto(o: Node) -> void:
	if not o is Node2D or str(o.name).begins_with("eco_"):
		return
	var o2 := o as Node2D
	var sp := _sprite_de(o)
	var tipo: String = str(o.get("tipo")) if o.get("tipo") != null else ""
	if tipo == "puerta":
		_puerta(o2, sp)
		return
	if sp == null:
		return
	var nombre: String = sp.texture.resource_path.get_file().get_basename()
	var pos: Vector2 = o2.global_position
	var ancho: float = sp.texture.get_width() * absf(sp.scale.x * o2.scale.x) * ESC
	var fondo: float = sp.texture.get_height() * absf(sp.scale.y * o2.scale.y) * ESC * 0.55
	var sobre_mueble: bool = o2.z_index >= 1
	var raiz := Node3D.new()
	raiz.position = a3d(pos, 0.78 if sobre_mueble else 0.0)
	add_child(raiz)
	var hecho: bool = true
	if "moneda" in str(o.name):
		# Moneda tirada: un disco chiquito en el piso, no un recorte parado
		var disco := cilindro(Vector3(0, 0.006, 0), 0.035, 0.008, M.color(Color(0.8, 0.62, 0.2), 0.3, 0.8), raiz)
		disco.name = "Moneda"
		_objetos_3d[o2] = raiz
		return
	match nombre:
		"escritorio":
			_escritorio(raiz, ancho, fondo)
		"mesa_alumno":
			_mesa(raiz, ancho, fondo * 0.85, 0.72)
		"computadora":
			_mesa(raiz, ancho, fondo, 0.74)
			_monitor(raiz, Vector3(0, 0.74, 0))
			caja(Vector3(ancho * 0.36, 0.25, 0), Vector3(0.2, 0.46, 0.45), M.color(Color(0.13, 0.13, 0.14), 0.5), raiz)
		"silla":
			_silla(raiz)
		"sofa":
			_sofa(raiz, ancho, fondo)
		"banco":
			_banca(raiz, ancho, fondo)
		"archivero_mueble":
			_frente(raiz, sp.texture, ancho, 1.35, 0.6, M.repetida("metal", 1.0, Color(0.7, 0.72, 0.75)))
		"casillero":
			_frente(raiz, sp.texture, ancho, 1.85, 0.5, M.repetida("metal", 1.0, Color(0.6, 0.66, 0.72)))
		"estanteria":
			_frente(raiz, sp.texture, ancho, 1.85, 0.4, M.repetida("madera", 1.0))
		"fotocopiadora":
			_frente(raiz, sp.texture, ancho, 1.1, 0.65, M.color(Color(0.72, 0.73, 0.72), 0.5))
		"cajonera":
			_frente(raiz, sp.texture, ancho, 0.62, 0.5, M.repetida("metal", 1.0, Color(0.5, 0.52, 0.55)))
		"caja":
			caja(Vector3(0, 0.22, 0), Vector3(0.55, 0.44, 0.45), M.color(Color(0.55, 0.40, 0.24)), raiz)
			caja(Vector3(0, 0.445, 0), Vector3(0.56, 0.01, 0.08), M.color(Color(0.72, 0.62, 0.42)), raiz)
		"torre_pc":
			caja(Vector3(0, 0.23, 0), Vector3(0.2, 0.46, 0.45), M.color(Color(0.13, 0.13, 0.14), 0.5), raiz)
		"papelera":
			cilindro(Vector3(0, 0.2, 0), 0.16, 0.4, M.color(Color(0.18, 0.2, 0.22), 0.6), raiz)
		"planta":
			cilindro(Vector3(0, 0.18, 0), 0.2, 0.36, M.color(Color(0.42, 0.24, 0.16)), raiz)
			_parado(raiz, sp.texture, 1.15, 0.0)
		"inodoro":
			_inodoro(raiz)
		"mingitorio":
			caja(Vector3(0, 0.75, -0.15), Vector3(0.42, 0.6, 0.3), M.color(Color(0.88, 0.88, 0.85), 0.25), raiz)
		"lavamanos":
			caja(Vector3(0, 0.84, -0.1), Vector3(0.6, 0.14, 0.45), M.color(Color(0.88, 0.88, 0.85), 0.25), raiz)
			cilindro(Vector3(0, 0.42, -0.2), 0.05, 0.84, M.color(Color(0.6, 0.6, 0.6), 0.3, 0.6), raiz)
		"extintor":
			cilindro(Vector3(0, 0.55, 0), 0.08, 0.5, M.color(Color(0.65, 0.08, 0.06), 0.4), raiz)
		"papeles", "cables", "expediente":
			if sobre_mueble:
				_plano(raiz, sp.texture, ancho, fondo / 0.55, 0.005)
			else:
				_plano(raiz, sp.texture, ancho, fondo / 0.55, 0.01)
		"pizarron", "reloj", "breaker", "interruptor", "cartelera", "espejo", "salida":
			raiz.queue_free()
			_en_pared(o2, sp, nombre)
			return
		"lampara_encendida", "lampara_apagada", "puerta_cubiculo", "division_bano", "rejilla":
			hecho = false
		_:
			# Lo demás (llave, termo, grapadora, gafete, monedas, objetos chicos): de pie, mirando a la cámara.
			var alto: float = clampf(sp.texture.get_height() * absf(sp.scale.y) * ESC * 0.8, 0.08, 1.2)
			_parado(raiz, sp.texture, alto, 0.0)
	if not hecho:
		raiz.queue_free()
		return
	_objetos_3d[o2] = raiz


func _parado(raiz: Node3D, tex: Texture2D, alto: float, base: float) -> void:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = alto / maxf(tex.get_height(), 1.0)
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.position = Vector3(0, base + alto / 2.0, 0)
	raiz.add_child(s)


## Algo acostado en el piso o sobre la mesa (papeles, cables): calcomanía plana.
func _plano(raiz: Node3D, tex: Texture2D, ancho: float, largo: float, altura: float) -> void:
	var mi := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(ancho, largo * 0.6)
	q.material = M.imagen(tex)
	mi.mesh = q
	mi.position = Vector3(0, altura, 0)
	raiz.add_child(mi)


func _escritorio(raiz: Node3D, ancho: float, fondo: float) -> void:
	var madera := M.repetida("madera", 1.2)
	var metal := M.repetida("metal", 1.0, Color(0.55, 0.57, 0.6))
	fondo = clampf(fondo, 0.7, 1.0)
	caja(Vector3(0, 0.755, 0), Vector3(ancho, 0.045, fondo), madera, raiz)
	caja(Vector3(-ancho / 2 + 0.22, 0.37, 0), Vector3(0.42, 0.74, fondo - 0.06), metal, raiz)    # cajonera izquierda
	caja(Vector3(ancho / 2 - 0.22, 0.37, 0), Vector3(0.42, 0.74, fondo - 0.06), metal, raiz)     # cajonera derecha
	caja(Vector3(0, 0.45, -fondo / 2 + 0.03), Vector3(ancho - 0.9, 0.55, 0.03), metal, raiz)     # panel de enfrente
	for k in 3:
		caja(Vector3(ancho / 2 - 0.22, 0.62 - k * 0.22, fondo / 2 - 0.02), Vector3(0.3, 0.015, 0.01), M.color(Color(0.2, 0.2, 0.2)), raiz)


func _mesa(raiz: Node3D, ancho: float, fondo: float, alto: float) -> void:
	fondo = clampf(fondo, 0.45, 0.9)
	caja(Vector3(0, alto - 0.02, 0), Vector3(ancho, 0.04, fondo), M.repetida("madera", 1.2), raiz)
	var metal := M.color(Color(0.25, 0.26, 0.28), 0.45, 0.5)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			caja(Vector3(sx * (ancho / 2 - 0.05), (alto - 0.04) / 2, sz * (fondo / 2 - 0.05)), Vector3(0.035, alto - 0.04, 0.035), metal, raiz)
	caja(Vector3(0, alto - 0.16, 0), Vector3(ancho - 0.1, 0.02, fondo - 0.12), M.color(Color(0.3, 0.31, 0.33)), raiz)   # rejilla de libros


func _monitor(raiz: Node3D, base: Vector3) -> void:
	var plastico := M.color(Color(0.16, 0.16, 0.17), 0.45)
	caja(base + Vector3(0, 0.02, 0.0), Vector3(0.22, 0.03, 0.18), plastico, raiz)              # pie
	caja(base + Vector3(0, 0.12, -0.02), Vector3(0.05, 0.18, 0.05), plastico, raiz)            # cuello
	caja(base + Vector3(0, 0.36, -0.04), Vector3(0.56, 0.36, 0.06), plastico, raiz)            # cuerpo
	caja(base + Vector3(0, 0.37, -0.005), Vector3(0.49, 0.29, 0.005), M.emisivo(Color(0.12, 0.3, 0.85), 1.3), raiz)   # pantalla
	caja(base + Vector3(0, 0.015, 0.2), Vector3(0.45, 0.02, 0.15), plastico, raiz)             # teclado


func _silla(raiz: Node3D) -> void:
	var madera := M.repetida("madera", 0.8, Color(0.85, 0.72, 0.6))
	var metal := M.color(Color(0.22, 0.23, 0.25), 0.45, 0.5)
	caja(Vector3(0, 0.45, 0), Vector3(0.42, 0.035, 0.4), madera, raiz)
	caja(Vector3(0, 0.74, 0.2), Vector3(0.4, 0.26, 0.03), madera, raiz)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			caja(Vector3(sx * 0.18, 0.225, sz * 0.17), Vector3(0.025, 0.45, 0.025), metal, raiz)
		caja(Vector3(sx * 0.18, 0.62, 0.19), Vector3(0.025, 0.34, 0.025), metal, raiz)


func _sofa(raiz: Node3D, ancho: float, fondo: float) -> void:
	var tela := M.color(Color(0.14, 0.2, 0.42), 0.95)
	fondo = clampf(fondo, 0.6, 0.85)
	caja(Vector3(0, 0.24, 0.02), Vector3(ancho, 0.22, fondo - 0.1), tela, raiz)
	caja(Vector3(0, 0.55, -fondo / 2 + 0.08), Vector3(ancho, 0.5, 0.16), tela, raiz)
	for sx in [-1, 1]:
		caja(Vector3(sx * (ancho / 2 - 0.05), 0.4, 0), Vector3(0.1, 0.3, fondo), tela, raiz)
	for k in 3:   # divisiones de los asientos
		caja(Vector3(-ancho / 3 + k * ancho / 3, 0.36, 0.02), Vector3(0.01, 0.02, fondo - 0.12), M.color(Color(0.08, 0.1, 0.2)), raiz)
	caja(Vector3(0, 0.07, 0), Vector3(ancho - 0.1, 0.14, fondo - 0.2), M.color(Color(0.15, 0.15, 0.16), 0.4, 0.6), raiz)


func _banca(raiz: Node3D, ancho: float, fondo: float) -> void:
	_mesa(raiz, ancho, clampf(fondo, 0.35, 0.5), 0.45)


func _inodoro(raiz: Node3D) -> void:
	var loza := M.color(Color(0.9, 0.9, 0.87), 0.2)
	caja(Vector3(0, 0.2, 0.05), Vector3(0.36, 0.4, 0.5), loza, raiz)
	caja(Vector3(0, 0.6, -0.22), Vector3(0.44, 0.4, 0.18), loza, raiz)
	caja(Vector3(0, 0.41, 0.05), Vector3(0.38, 0.03, 0.46), M.color(Color(0.8, 0.8, 0.78), 0.3), raiz)


## Muebles altos: cuerpo de metal o madera y el frente con el dibujo del equipo.
func _frente(raiz: Node3D, tex: Texture2D, ancho: float, alto: float, fondo: float, cuerpo: Material) -> void:
	ancho = clampf(ancho, 0.4, 2.2)
	caja(Vector3(0, alto / 2, 0), Vector3(ancho, alto, fondo), cuerpo, raiz)
	lamina(Vector3(0, alto / 2, fondo / 2 + 0.006), ancho, alto, tex, Vector3.BACK, raiz)


## Lo que va colgado: queda pegado a la pared más cercana, mirando hacia el cuarto.
func _en_pared(o2: Node2D, sp: Sprite2D, nombre: String) -> void:
	var alturas := {"pizarron": [1.2, 1.5], "reloj": [0.32, 2.3], "breaker": [0.5, 1.45], "interruptor": [0.13, 1.2],
		"cartelera": [1.0, 1.5], "espejo": [0.6, 1.55], "salida": [0.28, 2.45]}
	var dato: Array = alturas[nombre]
	var alto: float = dato[0]
	var ancho: float = alto * sp.texture.get_width() / maxf(sp.texture.get_height(), 1.0)
	var pos: Vector2 = o2.global_position
	var normal := Vector3.BACK
	var punto := pos
	if escuela.cuartos != null:
		var cuarto: String = escuela.cuartos.cuarto_en(pos)
		if cuarto != "":
			var r: Rect2 = escuela.cuartos.cuartos[cuarto]
			var distancias := {"arriba": pos.y - r.position.y, "abajo": r.end.y - pos.y, "izq": pos.x - r.position.x, "der": r.end.x - pos.x}
			var lado: String = "arriba"
			for k in distancias:
				if distancias[k] < distancias[lado]:
					lado = k
			match lado:
				"arriba":
					normal = Vector3.BACK
					punto = Vector2(pos.x, r.position.y + 7)
				"abajo":
					normal = Vector3.FORWARD
					punto = Vector2(pos.x, r.end.y - 7)
				"izq":
					normal = Vector3.RIGHT
					punto = Vector2(r.position.x + 7, pos.y)
				"der":
					normal = Vector3.LEFT
					punto = Vector2(r.end.x - 7, pos.y)
	punto = _lejos_de_puertas(punto, ancho / ESC, normal)
	var centro := a3d(punto, dato[1]) + normal * 0.05
	var mi := lamina(centro, ancho, alto, sp.texture, normal)
	_objetos_3d[o2] = mi


## Si algo colgado (pizarrón, reloj...) quedaría encima de una puerta, se recorre a un lado de la puerta.
func _lejos_de_puertas(punto: Vector2, ancho_px: float, normal: Vector3) -> Vector2:
	if absf(normal.z) < 0.5:
		return punto   # paredes laterales: ahí no hay puertas
	for o in escuela.get_node("Objetos").get_children():
		if o.get("tipo") != "puerta":
			continue
		var p: Vector2 = (o as Node2D).global_position
		var libre: float = 48.0 + ancho_px / 2.0 + 18.0
		if absf(p.y - punto.y) < 45.0 and absf(p.x - punto.x) < libre:
			var izquierda := Vector2(p.x - libre, punto.y)
			var derecha := Vector2(p.x + libre, punto.y)
			var cuarto: String = escuela.cuartos.cuarto_en(Vector2(punto.x, punto.y + normal.z * 30.0)) if escuela.cuartos != null else ""
			if cuarto != "":
				var r: Rect2 = escuela.cuartos.cuartos[cuarto]
				if izquierda.x - ancho_px / 2.0 > r.position.x + 10.0:
					return izquierda
				return derecha
			return izquierda
	return punto


## Letrero arriba de la puerta: del lado del pasillo dice el nombre del cuarto; de adentro, "PASILLO".
func _letreros_de_puerta(o2: Node2D, base: Vector3) -> void:
	var titulo: String = str(o2.get("titulo"))
	var clave: String = titulo.trim_prefix("Puerta: ")
	var nombre: String = escuela.cuartos.nombre_visible(clave) if escuela.cuartos != null else clave
	var pos: Vector2 = o2.global_position
	for lado in [-1.0, 1.0]:
		var del_lado: String = escuela.cuartos.cuarto_en(pos + Vector2(0, lado * 40.0)) if escuela.cuartos != null else ""
		var texto: String = "PASILLO" if del_lado == clave else nombre.to_upper()
		var placa := caja(base + Vector3(0, ALTO_PUERTA + 0.42, lado * 0.185), Vector3(1.3, 0.3, 0.02), M.color(Color(0.1, 0.16, 0.2), 0.5, 0.2))
		var marco := caja(base + Vector3(0, ALTO_PUERTA + 0.42, lado * 0.178), Vector3(1.36, 0.36, 0.01), M.color(Color(0.6, 0.62, 0.6), 0.3, 0.8))
		placa.name = "Letrero"
		marco.name = "MarcoLetrero"
		var etiqueta := Label3D.new()
		etiqueta.text = texto
		etiqueta.font_size = 48
		etiqueta.pixel_size = 0.0042
		etiqueta.outline_size = 0
		etiqueta.modulate = Color(0.92, 0.92, 0.86)
		etiqueta.shaded = true
		etiqueta.position = base + Vector3(0, ALTO_PUERTA + 0.42, lado * 0.198)
		etiqueta.rotation.y = 0.0 if lado > 0 else PI
		add_child(etiqueta)


## Puerta doble de escuela, armada en 3D (sin dibujo pegado): hojas de lámina pintada con ventanilla
## de vidrio alambrado, barra de empuje, placa de patada y bisagras; marco metálico y dintel hasta el techo.
## Las hojas se abren solas cuando el Archivero pasa o durante la transición de puerta.
func _puerta(o2: Node2D, _sp: Sprite2D) -> void:
	var pos: Vector2 = o2.global_position
	var hueco: float = 96.0 * ESC
	var base := a3d(pos)
	_inicio_puerta = get_child_count()
	var muro := M.repetida("yeso", 2.0)
	var marco := M.color(Color(0.17, 0.18, 0.19), 0.45, 0.6)
	caja(base + Vector3(0, (ALTO + ALTO_PUERTA) / 2.0, 0), Vector3(hueco + 0.1, ALTO - ALTO_PUERTA, 0.34), muro)
	caja(base + Vector3(0, ALTO_PUERTA + 0.05, 0), Vector3(hueco + 0.16, 0.1, 0.38), marco)
	for lado in [-1, 1]:
		caja(base + Vector3(lado * (hueco / 2 + 0.04), ALTO_PUERTA / 2, 0), Vector3(0.1, ALTO_PUERTA, 0.38), marco)
	caja(base + Vector3(0, 0.01, 0), Vector3(hueco, 0.02, 0.3), M.color(Color(0.3, 0.3, 0.3), 0.4, 0.7))   # umbral
	_letreros_de_puerta(o2, base)
	_sin_sombra_desde(_inicio_puerta)
	var hojas: Array = []
	for lado in [-1, 1]:
		var bisagra := Node3D.new()
		bisagra.position = base + Vector3(lado * hueco / 2, 0, 0)
		add_child(bisagra)
		var hoja := Node3D.new()
		hoja.position = Vector3(-lado * hueco / 4, 0, 0)
		bisagra.add_child(hoja)
		_hoja_de_puerta(hoja, hueco / 2 - 0.02, lado)
		for pieza in hoja.get_children():   # piezas finas de la hoja: sin sombra (dibujaban rayas en la pared)
			if pieza is GeometryInstance3D:
				(pieza as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hojas.append(bisagra)
	_puertas[o2] = hojas


func _hoja_de_puerta(hoja: Node3D, ancho: float, lado: int) -> void:
	var pintura := M.color(Color(0.24, 0.32, 0.33), 0.55, 0.25)       # lámina verde azulado gastada
	var orilla := M.color(Color(0.15, 0.19, 0.2), 0.5, 0.4)
	var metal := M.color(Color(0.62, 0.63, 0.62), 0.3, 0.9)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.05, 0.08, 0.1, 0.55)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.08
	vidrio.metallic = 0.3
	var alto: float = ALTO_PUERTA - 0.03
	var grueso: float = 0.05
	# Cuerpo de la hoja dejando el hueco de la ventanilla (arriba, del lado de en medio)
	var vx: float = lado * -ancho * 0.18        # la ventanilla va cargada hacia el centro de la puerta doble
	var vw: float = ancho * 0.32
	var vy0: float = 1.25
	var vy1: float = 1.95
	caja(Vector3(0, vy0 / 2, 0), Vector3(ancho, vy0, grueso), pintura, hoja)
	caja(Vector3(0, (vy1 + alto) / 2, 0), Vector3(ancho, alto - vy1, grueso), pintura, hoja)
	var izq: float = -ancho / 2
	var der: float = ancho / 2
	var vent_izq: float = vx - vw / 2
	var vent_der: float = vx + vw / 2
	caja(Vector3((izq + vent_izq) / 2, (vy0 + vy1) / 2, 0), Vector3(vent_izq - izq, vy1 - vy0, grueso), pintura, hoja)
	caja(Vector3((vent_der + der) / 2, (vy0 + vy1) / 2, 0), Vector3(der - vent_der, vy1 - vy0, grueso), pintura, hoja)
	caja(Vector3(vx, (vy0 + vy1) / 2, 0), Vector3(vw, vy1 - vy0, 0.012), vidrio, hoja)
	# Marco de la ventanilla y alambre del vidrio
	for y in [vy0, vy1]:
		caja(Vector3(vx, y, 0), Vector3(vw + 0.04, 0.025, grueso + 0.01), orilla, hoja)
	for x in [vent_izq, vent_der]:
		caja(Vector3(x, (vy0 + vy1) / 2, 0), Vector3(0.025, vy1 - vy0 + 0.04, grueso + 0.01), orilla, hoja)
	for k in range(1, 4):
		caja(Vector3(vx, vy0 + (vy1 - vy0) * k / 4.0, 0), Vector3(vw, 0.003, 0.014), metal, hoja)
	for cara in [1, -1]:
		var z: float = cara * (grueso / 2 + 0.01)
		caja(Vector3(0, 0.15, z * 0.9), Vector3(ancho - 0.04, 0.26, 0.006), metal, hoja)                 # placa de patada
		caja(Vector3(0, 1.0, z * 2.2), Vector3(ancho * 0.7, 0.045, 0.04), metal, hoja)                    # barra de empuje
		for x in [-ancho * 0.33, ancho * 0.33]:
			caja(Vector3(x, 1.0, z * 1.4), Vector3(0.03, 0.06, 0.04), metal, hoja)
	for y in [0.3, 1.1, 1.9]:   # bisagras
		caja(Vector3(lado * ancho / 2, y, 0), Vector3(0.03, 0.12, 0.07), metal, hoja)


var _inicio_puerta: int = 0


## Marco, dintel, umbral y letreros van pegados a la pared: no proyectan sombra (si no, la linterna
## dibuja rayas oscuras donde se cruzan con el muro). Las hojas de la puerta sí dan sombra.
func _sin_sombra_desde(indice: int) -> void:
	for k in range(indice, get_child_count()):
		var n := get_child(k)
		if n is GeometryInstance3D:
			(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Durante la transición se fuerza abrir o cerrar una puerta. sentido: +1 abre hacia +Z, -1 hacia -Z.
func forzar_puerta(puerta: Node2D, abierta: bool, sentido: float) -> void:
	_forzadas[puerta] = [abierta, sentido]


func soltar_puerta(puerta: Node2D) -> void:
	_forzadas.erase(puerta)
