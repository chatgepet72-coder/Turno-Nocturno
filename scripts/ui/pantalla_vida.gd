class_name PantallaVida
extends CanvasLayer
## Salud al estilo Silent Hill: no hay barra; el estado se ve en la pantalla y en la luz del control.
##   Bien (más de 75):       pantalla normal, control verde.
##   Herido (51 a 75):       unas manchitas de sangre en las orillas, control verde.
##   Grave (26 a 50):        más sangre, la imagen pierde color, control naranja.
##   Crítico (25 o menos):   pantalla rojiza que palpita como respiración, control rojo que parpadea.

const SHADER: String = """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform sampler2D sangre_tex : filter_linear;
uniform float sangre = 0.0;   // 0 nada, 1 toda la sangre
uniform float gris = 0.0;     // cuánto color pierde la imagen
uniform float rojo = 0.0;     // tinte rojo (crítico)
void fragment() {
	vec3 c = texture(pantalla, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), gris);
	float borde = smoothstep(0.25, 0.85, length((UV - 0.5) * vec2(1.6, 1.2)));
	c = mix(c, c * vec3(1.0, 0.35, 0.3) + vec3(0.22, 0.0, 0.0) * borde, rojo);
	vec4 s = texture(sangre_tex, UV);
	float aparece = smoothstep(1.0 - sangre, 1.0 - sangre + 0.08, s.a);
	c = mix(c, s.rgb, aparece * 0.85);
	COLOR = vec4(c, 1.0);
}
"""

var _material: ShaderMaterial
var _vida: int = 100
var _tiempo: float = 0.0
var _sangre: float = 0.0
var _gris: float = 0.0
var _rojo: float = 0.0


func _ready() -> void:
	layer = 5   # encima del mundo, debajo de los textos de la pantalla
	var rect := ColorRect.new()
	rect.size = Vector2(640, 360)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("sangre_tex", load("res://assets/sprites/ui/sangre_pantalla.png") as Texture2D)
	rect.material = _material
	add_child(rect)


func poner_vida(vida: int) -> void:
	_vida = vida


func _process(delta: float) -> void:
	_tiempo += delta
	var objetivo_sangre: float = 0.0
	var objetivo_gris: float = 0.0
	var objetivo_rojo: float = 0.0
	var luz: Color = Color(0.0, 0.9, 0.2)            # verde
	if _vida <= 25:
		var respiracion: float = 0.5 + 0.5 * sin(_tiempo * 2.6)
		objetivo_sangre = 0.95
		objetivo_gris = 0.55
		objetivo_rojo = 0.35 + 0.3 * respiracion
		luz = Color(1.0, 0.0, 0.0) * (0.25 + 0.75 * respiracion)   # rojo que parpadea como respiración
	elif _vida <= 50:
		objetivo_sangre = 0.6
		objetivo_gris = 0.35
		luz = Color(1.0, 0.45, 0.0)                    # naranja
	elif _vida <= 75:
		objetivo_sangre = 0.25
	# Cambios suaves, no de golpe
	_sangre = move_toward(_sangre, objetivo_sangre, delta * 0.8)
	_gris = move_toward(_gris, objetivo_gris, delta * 0.8)
	_rojo = lerpf(_rojo, objetivo_rojo, delta * 4.0)
	_material.set_shader_parameter("sangre", _sangre)
	_material.set_shader_parameter("gris", _gris)
	_material.set_shader_parameter("rojo", _rojo)
	for d in Input.get_connected_joypads():
		if Input.has_joy_light(d):
			Input.set_joy_light(d, luz)
