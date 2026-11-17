"""Rehace la sala de simulación a escala correcta: recorta de la imagen del equipo el piso, una camilla
con su maniquí, el carrito y los monitores, y arma una sala más grande con 8 camillas del tamaño de una persona.
Uso: python3 -I tools/arte/sala_simulacion.py <imagen_original_10_Sala_de_simulacion_CORREGIDA.webp>"""
import json, os, sys
from collections import deque
from PIL import Image, ImageDraw
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(R, "assets", "sprites", "interiores", "medicina")
im = Image.open(sys.argv[1]).convert("RGB")
g = im.convert("L").point(lambda v: 255 if v > 28 else 0); im = im.crop(g.getbbox()); W, H = im.size

def sin_piso(caja):
    """Recorta y quita el piso verde que toca la orilla del recorte."""
    c = im.crop(caja).convert("RGBA"); w, h = c.size; px = c.load(); vis = bytearray(w * h)
    q = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while q:
        x, y = q.popleft()
        if not (0 <= x < w and 0 <= y < h) or vis[y * w + x]: continue
        vis[y * w + x] = 1; r, gg, b, a = px[x, y]
        if gg >= r + 6 and gg >= b - 2:   # verdes del piso y sus juntas
            px[x, y] = (0, 0, 0, 0); q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return c.crop(c.getbbox())

f = lambda a, b, c_, d: (round(a * W), round(b * H), round(c_ * W), round(d * H))
camilla = sin_piso(f(0.255, 0.115, 0.415, 0.52))
carrito = sin_piso(f(0.07, 0.38, 0.215, 0.65))
monitor = sin_piso(f(0.82, 0.26, 0.915, 0.42))
loseta = im.crop(f(0.46, 0.6, 0.58, 0.76))
ESC = 160 / camilla.height         # camilla de ~160 px de largo (dentro de los edificios Lalo mide 120)
esc = lambda s: s.resize((max(1, round(s.width * ESC)), max(1, round(s.height * ESC))), Image.LANCZOS)
camilla, carrito, monitor = esc(camilla), esc(carrito), esc(monitor)
loseta = loseta.resize((round(loseta.width * ESC * 1.2), round(loseta.height * ESC * 1.2)), Image.LANCZOS)
# Sala nueva: 900 x 640
SW, SH, MURO = 1500, 1080, 70
sala = Image.new("RGB", (SW, SH), (40, 52, 46))
for x in range(0, SW, loseta.width):
    for y in range(0, SH, loseta.height): sala.paste(loseta, (x, y))
d = ImageDraw.Draw(sala)
pared, pared_osc = im.getpixel((round(W * 0.5), round(H * 0.02))), (34, 44, 38)
for caja in ((0, 0, SW, MURO), (0, SH - MURO, SW, SH), (0, 0, MURO, SH), (SW - MURO, 0, SW, SH)): d.rectangle(caja, fill=pared)
d.rectangle((MURO - 4, MURO - 4, SW - MURO + 3, SH - MURO + 3), outline=pared_osc, width=4)
d.rectangle((SW // 2 - 60, 6, SW // 2 + 60, MURO), fill=(70, 74, 62), outline=(20, 22, 18), width=4)   # puerta (arriba)
d.rectangle((SW // 2 + 34, 34, SW // 2 + 42, 42), fill=(30, 30, 26))
sala = sala.convert("RGBA")
# Suciedad: tierra negra, un rastro de arrastre entre las camillas y sombra en las orillas
import random
random.seed(8)
T = os.path.join(R, "assets", "sprites", "escenario", "tierra")
for n, x, y, rot in (("rastro_1.png", 660, 500, 0), ("rastro_2.png", 360, 880, 30), ("rastro_2.png", 1000, 180, 160),
                     ("huellas.png", 930, 540, 90), ("rastro_1.png", 1270, 880, 200)):
    t = Image.open(f"{T}/{n}").convert("RGBA").rotate(rot, expand=True)
    t = t.resize((t.width * 3 // 2, t.height * 3 // 2), Image.NEAREST)
    sala.alpha_composite(t, (x, y))
sombra = Image.new("L", (SW, SH), 0); sd = ImageDraw.Draw(sombra)
for k in range(90):
    sd.rectangle((MURO + k, MURO + k, SW - MURO - k, SH - MURO - k), outline=int(110 * (1 - k / 90)))
negro = Image.new("RGBA", (SW, SH), (8, 12, 10, 255)); negro.putalpha(sombra)
sala.alpha_composite(negro)
obstaculos = []
for fila, y in enumerate((230, 640)):
    for col in range(4):
        x = 250 + col * 290
        sala.alpha_composite(camilla, (x, y))
        obstaculos.append([x / SW, (y + 8) / SH, camilla.width / SW, (camilla.height - 14) / SH])
sala.alpha_composite(carrito, (110, 500)); obstaculos.append([110 / SW, 515 / SH, carrito.width / SW, (carrito.height - 15) / SH])
for k in range(3):
    y = 280 + k * 240; sala.alpha_composite(monitor, (SW - MURO - monitor.width - 6, y))
    obstaculos.append([(SW - MURO - monitor.width - 6) / SW, y / SH, monitor.width / SW, monitor.height / SH])
sala.save(f"{DST}/simulacion.png")
ruta = os.path.join(R, "data", "medicina_cuartos.json"); datos = json.load(open(ruta))
datos["simulacion"] = {"tam": [SW, SH], "muro": MURO, "puerta": "t", "puerta_x": SW // 2, "obstaculos": obstaculos}
json.dump(datos, open(ruta, "w"), indent="\t")
print("ok camilla", camilla.size, "carrito", carrito.size, "monitor", monitor.size, "loseta", loseta.size)
