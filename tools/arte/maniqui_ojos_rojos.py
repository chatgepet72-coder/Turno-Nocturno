"""Maniquí con ojos rojos: arma la caminata en 4 direcciones con cuadros que miran hacia donde caminan.
Uso: python3 -I tools/arte/maniqui_ojos_rojos.py <hoja_sin_fondo.png>"""
import os, sys
from PIL import Image, ImageOps
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(R, "assets", "sprites", "enemigos", "maniqui")
h = Image.open(sys.argv[1]).convert("RGBA"); cw, ch = h.width // 4, h.height // 3
def c(f, col):
    """Recorta un cuadro y se queda con el tramo vertical más largo sin filas vacías
    (quita los pedacitos de pies de la fila de arriba)."""
    cel = h.crop((col * cw, f * ch, (col + 1) * cw, (f + 1) * ch)); al = cel.split()[3]
    filas = [any(al.getpixel((x, y)) > 0 for x in range(0, cel.width, 2)) for y in range(cel.height)]
    mejor, ini = (0, 0), None
    for y, lleno in enumerate(filas + [False]):
        if lleno and ini is None: ini = y
        elif not lleno and ini is not None:
            if y - ini > mejor[1] - mejor[0]: mejor = (ini, y)
            ini = None
    cel = cel.crop((0, mejor[0], cel.width, mejor[1])); return cel.crop(cel.getbbox())
m = ImageOps.mirror
izquierda = [c(2, 0), m(c(2, 2)), c(1, 0), m(c(2, 3))]          # todos miran a la izquierda
ciclos = {
    "down": [c(0, 0), c(0, 3), c(0, 2), c(0, 3)],
    "up": [c(1, 1), c(1, 2), c(1, 3), m(c(1, 2))],
    "left": izquierda,
    "right": [m(f) for f in izquierda],
}
alto = 66; esc = alto / max(f.height for f in ciclos["down"])
todos = {k: [f.resize((max(1, round(f.width * esc)), max(1, round(f.height * esc))), Image.LANCZOS) for f in v] for k, v in ciclos.items()}
W = max(f.width for v in todos.values() for f in v); H = max(f.height for v in todos.values() for f in v)
for k, v in todos.items():
    for i, f in enumerate(v, 1):
        lienzo = Image.new("RGBA", (W, H)); lienzo.alpha_composite(f, ((W - f.width) // 2, H - f.height)); lienzo.save(f"{DST}/{k}_{i}.png")
print("ok", W, H)
