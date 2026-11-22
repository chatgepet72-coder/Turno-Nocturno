extends RefCounted
## Materiales y texturas hechas con código para la vista en primera persona (sin depender de arte nuevo).
## Cuando el equipo de arte entregue texturas, se cambian aquí.

static var _cache: Dictionary = {}


static func color(c: Color, rugosidad: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var clave := "c_%s_%s_%s" % [c.to_html(), rugosidad, metal]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	m.metallic = metal
	_cache[clave] = m
	return m


static func emisivo(c: Color, energia: float = 1.6) -> StandardMaterial3D:
	var clave := "e_%s_%s" % [c.to_html(), energia]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energia
	_cache[clave] = m
	return m


## Textura de una imagen del juego (sprite) aplicada a una cara, con transparencia recortada.
static func imagen(tex: Texture2D, tinte: Color = Color.WHITE) -> StandardMaterial3D:
	var clave := "i_%s_%s" % [tex.resource_path, tinte.to_html()]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tinte
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cache[clave] = m
	return m


## Material con textura que se repite según la posición en el mundo (cada `metros` una vez).
static func repetida(nombre: String, metros: float = 1.0, tinte: Color = Color.WHITE) -> StandardMaterial3D:
	var clave := "r_%s_%s_%s" % [nombre, metros, tinte.to_html()]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_texture = textura(nombre)
	m.albedo_color = tinte
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metros
	m.roughness = 0.9
	_cache[clave] = m
	return m


## Texturas dibujadas con código.
static func textura(nombre: String) -> ImageTexture:
	var clave := "t_" + nombre
	if _cache.has(clave):
		return _cache[clave]
	var img: Image
	match nombre:
		"azulejo":   # azulejo de pared, 8 piezas por metro, con junta oscura y manchas
			img = _rejilla(128, 4, Color(0.62, 0.70, 0.66), Color(0.30, 0.34, 0.32), 2, 0.05)
		"plafon":    # plafón del techo: placas de 60 cm con perforaciones
			img = _rejilla(128, 2, Color(0.70, 0.70, 0.67), Color(0.40, 0.40, 0.38), 3, 0.03)
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in 900:
				img.set_pixel(rng.randi_range(0, 127), rng.randi_range(0, 127), Color(0.5, 0.5, 0.48))
		"yeso":      # yeso viejo con manchas suaves
			img = _ruido(128, Color(0.70, 0.72, 0.68), 0.06, 11)
		"madera":
			img = _vetas(128, Color(0.46, 0.31, 0.19))
		"metal":
			img = _ruido(64, Color(0.42, 0.45, 0.47), 0.05, 3)
		"concreto":
			img = _ruido(128, Color(0.45, 0.46, 0.45), 0.09, 5)
		_:
			img = Image.create(4, 4, false, Image.FORMAT_RGB8)
			img.fill(Color.MAGENTA)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[clave] = tex
	return tex


static func _rejilla(tam: int, piezas: int, base: Color, junta: Color, grosor: int, mancha: float) -> Image:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
	var paso: int = tam / piezas
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in tam:
		for x in tam:
			var c := base
			if x % paso < grosor or y % paso < grosor:
				c = junta
			else:
				var pieza := Vector2i(x / paso, y / paso)
				var variacion: float = sin(pieza.x * 12.9898 + pieza.y * 78.233) * 0.5 + 0.5
				c = base.darkened(variacion * 0.08) if variacion > 0.5 else base.lightened(variacion * 0.04)
				c = c.darkened(rng.randf() * mancha)
			img.set_pixel(x, y, c)
	return img


static func _ruido(tam: int, base: Color, fuerza: float, semilla: int) -> Image:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = semilla
	n.frequency = 0.06
	for y in tam:
		for x in tam:
			var v: float = n.get_noise_2d(x, y) * fuerza
			img.set_pixel(x, y, Color(base.r + v, base.g + v, base.b + v))
	return img


static func _vetas(tam: int, base: Color) -> Image:
	var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = 4
	n.frequency = 0.03
	for y in tam:
		for x in tam:
			var v: float = sin(x * 0.35 + n.get_noise_2d(x * 0.3, y * 3.0) * 6.0) * 0.06
			img.set_pixel(x, y, Color(base.r + v, base.g + v * 0.8, base.b + v * 0.5))
	return img
