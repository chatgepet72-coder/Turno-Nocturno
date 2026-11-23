extends "res://src/fp/mundo_3d.gd"
## Levanta en 3D el campus (afuera) a partir de scenes/campus.tscn, que sigue mandando: choques,
## enemigos, puntos de la historia. Usa las texturas del equipo (assets/sprites/campus/texturas):
## pasto, banqueta, asfalto, block, ventanas, lámina del andador, malla ciclónica y tierra.
## Reutiliza las piezas del edificio (mesas, sillas, bancas, escritorios, inodoros).

const TEX := "res://assets/sprites/campus/texturas/"
const ALTO_MURO: float = 3.2
const ALTO_EDIFICIO: float = 6.4      # el edificio principal: dos pisos
const ALTO_ANDADOR: float = 2.7

var exterior: Node2D
var _mats: Dictionary = {}
var _parpadean: Array[OmniLight3D] = []
var _capa: int = 0                     # cada piso un poquito más arriba (sin parpadeo entre planos)


## Material con textura repetida en el mundo (no depende del tamaño de la pieza).
func tex(nombre: String, metros: float, transparente: bool = false) -> StandardMaterial3D:
	var clave := "%s_%s" % [nombre, metros]
	if _mats.has(clave):
		return _mats[clave]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(TEX + nombre + ".png") as Texture2D
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metros
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.92
	if transparente:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[clave] = m
	return m


func construir() -> void:
	for n in exterior.get_children():
		if n is Sprite2D:
			if str(n.name).begins_with("Suelo"):
				_suelo(n as Sprite2D)
			else:
				_decoracion(n as Sprite2D)
		elif n is StaticBody2D or n is Area2D:
			_cuerpo(n as Node2D)
		elif n is Node2D and str(n.name) == "DonChuy":
			_persona(n as Node2D)


func _rect(sp: Sprite2D) -> Rect2:
	return sp.get_global_transform() * sp.get_rect()


func _plano_suelo(r: Rect2, mat: Material, alto: float = -1.0) -> void:
	_capa += 1
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = r.size * ESC
	pm.material = mat
	mi.mesh = pm
	mi.position = a3d(r.get_center(), alto if alto >= 0.0 else 0.001 * _capa)
	add_child(mi)


func _suelo(sp: Sprite2D) -> void:
	var r := _rect(sp)
	var nombre: String = sp.texture.resource_path.get_file().get_basename()
	match nombre:
		"pasto", "jardin":
			_plano_suelo(r, tex("pasto", 2.0))
		"concreto":
			_plano_suelo(r, tex("concreto_banqueta", 2.0))
		"asfalto":
			_plano_suelo(r, tex("asfalto_estacionamiento", 4.0))
		"azulejo":
			# Piso del segundo edificio (cafetería, oficinas, baños): adentro, con techo
			_plano_suelo(r, M.repetida("azulejo", 1.0, Color(0.75, 0.78, 0.76)))
			var techo := MeshInstance3D.new()
			var tm := PlaneMesh.new()
			tm.size = r.size * ESC
			tm.flip_faces = true
			tm.material = M.repetida("plafon", 1.2)
			techo.mesh = tm
			techo.position = a3d(r.get_center(), ALTO_MURO)
			add_child(techo)
		"muro":
			if minf(r.size.x, r.size.y) <= 6.0:
				# Líneas pintadas del estacionamiento y orillas
				_plano_suelo(r, M.color(Color(0.75, 0.62, 0.2), 0.8))
			else:
				# Bordes de jardineras y banquetas: un escalón de concreto
				caja(a3d(r.get_center(), 0.2), Vector3(r.size.x * ESC, 0.4, r.size.y * ESC), tex("concreto_banqueta", 2.0))
		_:
			_plano_suelo(r, M.imagen(sp.texture))


func _decoracion(sp: Sprite2D) -> void:
	if not sp.visible or sp.texture == null:
		return
	var r := _rect(sp)
	var nombre: String = sp.texture.resource_path.get_file().get_basename()
	match nombre:
		"canopy":
			_andador(r)
		"tierra":
			_plano_suelo(r, tex("tierra_removida", 2.0), 0.03)
		"ventana":
			_ventana(r)
		"cancha", "drenaje", "hojas":
			_plano_suelo(r, M.imagen(sp.texture), 0.02)
		"computadora":
			var raiz := Node3D.new()
			raiz.position = a3d(sp.global_position)
			add_child(raiz)
			_mesa(raiz, 1.0, 0.6, 0.74)
			_monitor(raiz, Vector3(0, 0.74, 0))
		_:
			pass   # fachadas vistas desde arriba, ventiladores de techo: en 3D sobran


## Techo de lámina roja del andador, sobre postes.
func _andador(r: Rect2) -> void:
	var tam := Vector3(r.size.x * ESC, 0.08, r.size.y * ESC)
	var techo := caja(a3d(r.get_center(), ALTO_ANDADOR), tam, tex("lamina_roja_oxidada", 2.0))
	techo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var metal := M.color(Color(0.3, 0.3, 0.32), 0.5, 0.7)
	for fx in [0.05, 0.95]:
		for fy in [0.05, 0.95]:
			var p := r.position + r.size * Vector2(fx, fy)
			cilindro(a3d(p, ALTO_ANDADOR / 2.0), 0.06, ALTO_ANDADOR, metal)


## Las ventanas del mapa están dibujadas desde arriba sobre los muros: se ponen de pie, en los dos lados.
func _ventana(r: Rect2) -> void:
	var horizontal: bool = r.size.x >= r.size.y
	var largo: float = (r.size.x if horizontal else r.size.y) * ESC
	var grueso: float = (r.size.y if horizontal else r.size.x) * ESC
	var rota: bool = int(r.position.x + r.position.y) % 3 == 0
	var t := load(TEX + ("ventana_salon_rota" if rota else "ventana_salon") + ".png") as Texture2D
	for lado in [-1.0, 1.0]:
		var normal := Vector3(0, 0, lado) if horizontal else Vector3(lado, 0, 0)
		var centro := a3d(r.get_center(), 1.65) + normal * (grueso / 2.0 + 0.06)
		lamina(centro, minf(largo, 2.4), 1.4, t, normal)


func _cuerpo(n: Node2D) -> void:
	var sp := _sprite_de(n)
	var col: CollisionShape2D = null
	for h in n.get_children():
		if h is CollisionShape2D:
			col = h
	var tam := Vector2.ZERO
	var centro: Vector2 = n.global_position
	if col != null and col.shape is RectangleShape2D:
		tam = (col.shape as RectangleShape2D).size * n.scale.abs()
		centro = col.global_position
	var nombre: String = sp.texture.resource_path.get_file().get_basename() if sp != null else ""
	var raiz := Node3D.new()
	raiz.position = a3d(centro)
	add_child(raiz)
	var t3 := Vector3(tam.x * ESC, 0.0, tam.y * ESC)
	match nombre:
		"valla":
			# Reja perimetral: malla ciclónica con postes
			caja(Vector3(0, 1.2, 0), Vector3(maxf(t3.x, 0.04), 2.4, maxf(t3.z, 0.04)), tex("malla_ciclonica", 0.8, true), raiz)
			var largo: float = maxf(t3.x, t3.z)
			var pasos: int = int(largo / 3.0)
			for k in pasos + 1:
				var d: float = -largo / 2.0 + k * largo / maxf(pasos, 1)
				var p := Vector3(d, 1.25, 0) if t3.x > t3.z else Vector3(0, 1.25, d)
				cilindro(p, 0.04, 2.5, M.color(Color(0.4, 0.41, 0.42), 0.5, 0.7), raiz)
		"techo_claro":
			_edificio(raiz, t3)
		"muro":
			caja(Vector3(0, ALTO_MURO / 2.0, 0), Vector3(maxf(t3.x, 0.2), ALTO_MURO, maxf(t3.z, 0.2)), tex("pared_block", 3.2), raiz)
		"arbol":
			_arbol(raiz, int(centro.x + centro.y))
		"poste":
			_farol(raiz, int(centro.x / 7.0 + centro.y))
		"barandal":
			var metal := M.color(Color(0.35, 0.36, 0.38), 0.5, 0.7)
			caja(Vector3(0, 0.95, 0), Vector3(maxf(t3.x, 0.05), 0.05, maxf(t3.z, 0.05)), metal, raiz)
			caja(Vector3(0, 0.5, 0), Vector3(maxf(t3.x, 0.05), 0.04, maxf(t3.z, 0.05)), metal, raiz)
		"banca":
			_banca(raiz, t3.x, t3.z)
		"bote":
			cilindro(Vector3(0, 0.45, 0), 0.28, 0.9, M.color(Color(0.16, 0.28, 0.2), 0.7), raiz)
		"mesa":
			_mesa(raiz, t3.x, t3.z, 0.75)
		"mesa_picnic":
			_mesa(raiz, t3.x, t3.z * 0.5, 0.75)
			caja(Vector3(0, 0.45, t3.z * 0.38), Vector3(t3.x, 0.05, 0.3), M.repetida("madera", 1.0), raiz)
			caja(Vector3(0, 0.45, -t3.z * 0.38), Vector3(t3.x, 0.05, 0.3), M.repetida("madera", 1.0), raiz)
		"silla_negra":
			_silla(raiz)
		"escritorio":
			_escritorio(raiz, t3.x, t3.z)
		"inodoro":
			_inodoro(raiz)
		"lavamanos":
			caja(Vector3(0, 0.84, 0), Vector3(0.6, 0.14, 0.45), M.color(Color(0.88, 0.88, 0.85), 0.25), raiz)
		"nevera":
			caja(Vector3(0, 0.9, 0), Vector3(t3.x, 1.8, t3.z), M.color(Color(0.8, 0.8, 0.78), 0.4), raiz)
		"estufa":
			caja(Vector3(0, 0.45, 0), Vector3(t3.x, 0.9, t3.z), M.color(Color(0.55, 0.55, 0.56), 0.4, 0.5), raiz)
		"mostrador":
			caja(Vector3(0, 0.5, 0), Vector3(t3.x, 1.0, t3.z), M.repetida("madera", 1.0, Color(0.7, 0.6, 0.5)), raiz)
		"auto_blanco", "auto_azul", "auto_rojo":
			_auto(raiz, t3, {"auto_blanco": Color(0.75, 0.76, 0.74), "auto_azul": Color(0.16, 0.25, 0.42), "auto_rojo": Color(0.5, 0.1, 0.08)}[nombre])
		_:
			if sp == null:
				raiz.queue_free()
				return
			# Lo que se recoge o se revisa (pala, radio, monedas, pilas, breakers, ecos...): dibujo de pie
			var persona: bool = nombre.begins_with("eco_")
			var alto: float = 1.7 if persona else clampf(sp.texture.get_height() * absf(sp.scale.y) * ESC * 0.75, 0.15, 0.6)
			_parado(raiz, sp.texture, alto, 0.0 if persona else 0.55)
			if not persona:
				cilindro(Vector3(0, 0.27, 0), 0.22, 0.54, M.color(Color(0.3, 0.3, 0.32), 0.6), raiz)   # pedestal
	_objetos_3d[n] = raiz


func _edificio(raiz: Node3D, t3: Vector3) -> void:
	caja(Vector3(0, ALTO_EDIFICIO / 2.0, 0), Vector3(t3.x, ALTO_EDIFICIO, t3.z), tex("pared_block", 3.2), raiz)
	caja(Vector3(0, ALTO_EDIFICIO + 0.1, 0), Vector3(t3.x + 0.3, 0.2, t3.z + 0.3), M.color(Color(0.2, 0.2, 0.21)), raiz)
	var sana := load(TEX + "ventana_salon.png") as Texture2D
	var rota := load(TEX + "ventana_salon_rota.png") as Texture2D
	# Ventanas en las cuatro caras, dos pisos
	for cara in [[Vector3(0, 0, 1), t3.x, t3.z], [Vector3(0, 0, -1), t3.x, t3.z], [Vector3(1, 0, 0), t3.z, t3.x], [Vector3(-1, 0, 0), t3.z, t3.x]]:
		var normal: Vector3 = cara[0]
		var largo: float = cara[1]
		var fondo: float = cara[2]
		var n: int = int(largo / 3.6)
		for k in n:
			var d: float = -largo / 2.0 + (k + 0.5) * largo / n
			for piso in [1.6, 4.8]:
				var lado := Vector3(d, piso, 0) if normal.x == 0.0 else Vector3(0, piso, d)
				var centro: Vector3 = raiz.position + lado + normal * (fondo / 2.0 + 0.02)
				lamina(centro, 1.9, 1.5, rota if (k * 7 + int(piso)) % 5 == 0 else sana, normal)


func _arbol(raiz: Node3D, semilla: int) -> void:
	var tronco := M.color(Color(0.18, 0.13, 0.1))
	var hojas := M.color(Color(0.07, 0.1, 0.06), 0.95)
	var alto: float = 3.2 + float(semilla % 5) * 0.3
	cilindro(Vector3(0, alto / 2.0, 0), 0.18, alto, tronco, raiz)
	for k in 3:
		var esfera := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.3 - k * 0.25
		s.height = s.radius * 1.7
		s.radial_segments = 10
		s.rings = 6
		s.material = hojas
		esfera.mesh = s
		esfera.position = Vector3(sin(k * 2.1 + semilla) * 0.5, alto + k * 0.6, cos(k * 2.1 + semilla) * 0.5)
		raiz.add_child(esfera)


## Farol de luz de sodio (naranja). Algunos fundidos, otros parpadean.
func _farol(raiz: Node3D, semilla: int) -> void:
	var metal := M.color(Color(0.25, 0.26, 0.27), 0.5, 0.7)
	cilindro(Vector3(0, 2.75, 0), 0.07, 5.5, metal, raiz)
	caja(Vector3(0.35, 5.5, 0), Vector3(0.8, 0.08, 0.08), metal, raiz)
	var fundido: bool = semilla % 3 == 0
	caja(Vector3(0.7, 5.42, 0), Vector3(0.4, 0.1, 0.22), M.emisivo(Color(1.0, 0.6, 0.25), 0.0 if fundido else 1.4) if not fundido else metal, raiz)
	if fundido:
		return
	var luz := OmniLight3D.new()
	luz.position = Vector3(0.7, 5.2, 0)
	luz.light_color = Color(1.0, 0.58, 0.26)
	luz.light_energy = 1.3
	luz.omni_range = 10.0
	luz.omni_attenuation = 1.6
	raiz.add_child(luz)
	if semilla % 3 == 1:
		_parpadean.append(luz)


func _auto(raiz: Node3D, t3: Vector3, pintura: Color) -> void:
	var cuerpo := M.color(pintura, 0.35, 0.6)
	var vidrio := M.color(Color(0.04, 0.05, 0.06), 0.1, 0.3)
	var llanta := M.color(Color(0.05, 0.05, 0.05), 0.9)
	var a: float = t3.x
	var l: float = t3.z
	caja(Vector3(0, 0.55, 0), Vector3(a, 0.6, l), cuerpo, raiz)
	caja(Vector3(0, 1.08, -l * 0.05), Vector3(a * 0.88, 0.5, l * 0.48), vidrio, raiz)
	caja(Vector3(0, 1.35, -l * 0.05), Vector3(a * 0.86, 0.06, l * 0.44), cuerpo, raiz)
	for x in [-a / 2.0, a / 2.0]:
		for z in [-l * 0.32, l * 0.32]:
			var r := cilindro(Vector3(x, 0.33, z), 0.33, 0.22, llanta, raiz)
			r.rotation.z = PI / 2.0


func _persona(n: Node2D) -> void:
	var sp := _sprite_de(n)
	if sp == null:
		for h in n.get_children():
			if h is AnimatedSprite2D:
				return   # los personajes animados ya los dibuja la vista (como enemigos)
		return
	var raiz := Node3D.new()
	raiz.position = a3d(n.global_position)
	add_child(raiz)
	_parado(raiz, sp.texture, 1.7, 0.0)
	_objetos_3d[n] = raiz


## Los faroles que parpadean.
func sincronizar() -> void:
	super.sincronizar()
	for luz in _parpadean:
		luz.light_energy = 0.0 if randf() < 0.08 else 1.3
