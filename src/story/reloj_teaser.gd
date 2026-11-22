extends Control
## Primer plano del reloj de pared de la sala de espera (teaser): fondo negro y un reloj de manecillas.

var hora: int = 23 * 60 + 58   # minutos desde medianoche
var segundos: int = 0:
	set(v):
		segundos = v
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.03))
	var c := size * 0.5
	var r: float = 170.0
	draw_circle(c + Vector2(6, 8), r + 14, Color(0, 0, 0, 0.6))
	draw_circle(c, r + 14, Color(0.16, 0.17, 0.18))
	draw_circle(c, r, Color(0.86, 0.84, 0.78))
	for i in 60:
		var a: float = TAU * i / 60.0
		var largo: float = 20.0 if i % 5 == 0 else 8.0
		var grueso: float = 6.0 if i % 5 == 0 else 2.0
		var dir := Vector2(sin(a), -cos(a))
		draw_line(c + dir * (r - 8), c + dir * (r - 8 - largo), Color(0.12, 0.12, 0.13), grueso)
	var h: float = float(hora % 720) / 60.0
	var m: float = float(hora % 60)
	_mano(c, TAU * h / 12.0, r * 0.5, 11.0, Color(0.1, 0.1, 0.11))
	_mano(c, TAU * m / 60.0, r * 0.78, 7.0, Color(0.1, 0.1, 0.11))
	_mano(c, TAU * segundos / 60.0, r * 0.86, 2.5, Color(0.7, 0.12, 0.1))
	draw_circle(c, 9, Color(0.1, 0.1, 0.11))
	var marca := ThemeDB.fallback_font
	draw_string(marca, c + Vector2(-60, r * 0.42), "UNIVERSIDAD", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color(0.25, 0.25, 0.27))


func _mano(c: Vector2, angulo: float, largo: float, grueso: float, color: Color) -> void:
	var dir := Vector2(sin(angulo), -cos(angulo))
	draw_line(c - dir * largo * 0.15, c + dir * largo, color, grueso)
