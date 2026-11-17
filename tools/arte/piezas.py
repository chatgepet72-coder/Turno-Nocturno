"""Piezas faltantes en el estilo del equipo: pixel art grueso, colores planos y vivos, borde negro.
Se dibuja a baja resolución (1 px = 1 'pixel de arte') y se escala x8 sin suavizado."""
import random, sys
from PIL import Image, ImageDraw
OUT = sys.argv[1]
ESC = 8
NEGRO = (16, 14, 14, 255)

def lienzo(w, h): im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)
def borde(im):
    """Contorno negro de 1 px de arte alrededor de todo lo opaco."""
    w, h = im.size; src = im.load(); out = im.copy(); px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and src[x + dx, y + dy][3] > 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = NEGRO
    return out
def pad(im, p=1):
    o = Image.new("RGBA", (im.width + 2 * p, im.height + 2 * p), (0, 0, 0, 0)); o.paste(im, (p, p)); return o
def guardar(im, nombre, contorno=True):
    if contorno: im = borde(pad(im))
    im.resize((im.width * ESC, im.height * ESC), Image.NEAREST).save(f"{OUT}/{nombre}.png"); return im

AZUL_V, AZUL_V2 = (40, 110, 220, 255), (120, 180, 250, 255)
CREMA, CREMA_OSC = (232, 206, 160, 255), (196, 168, 120, 255)
TEJA, TEJA2, TEJA3 = (220, 50, 40, 255), (180, 34, 28, 255), (240, 90, 70, 255)
GRIS, GRIS2, GRIS3 = (150, 150, 152, 255), (110, 110, 114, 255), (196, 196, 198, 255)

def ventana(d, x, y, w=4, h=4):
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=NEGRO); d.rectangle((x + 1, y + 1, x + w - 2, y + h - 2), fill=AZUL_V)
    d.point((x + 1, y + 1), fill=AZUL_V2)

# ---------- Caseta por fuera ----------
def caseta_fuera():
    im, d = lienzo(40, 34)
    d.rectangle((0, 0, 39, 13), fill=GRIS3)                               # azotea de concreto
    d.rectangle((0, 0, 39, 1), fill=(220, 220, 222, 255)); d.rectangle((0, 12, 39, 13), fill=GRIS)
    d.rectangle((6, 4, 12, 9), fill=GRIS)                                   # tinaco de agua
    d.rectangle((7, 4, 11, 5), fill=(70, 70, 74, 255))
    d.rectangle((0, 14, 39, 33), fill=(236, 236, 230, 255))                 # muro blanco
    d.rectangle((0, 14, 39, 16), fill=(30, 70, 150, 255))                   # franja azul de vigilancia
    for x in (3, 15, 27):                                                   # ventanales
        d.rectangle((x, 19, x + 9, 27), fill=NEGRO); d.rectangle((x + 1, 20, x + 8, 26), fill=AZUL_V)
        d.line((x + 1, 20, x + 3, 20), fill=AZUL_V2); d.line((x + 5, 20, x + 5, 26), fill=NEGRO)
    d.rectangle((14, 29, 25, 33), fill=(210, 210, 204, 255))                # zoclo
    d.rectangle((15, 15, 24, 16), fill=(250, 250, 250, 255))                # placa
    return im

# ---------- Caseta por dentro (sin techo) ----------
def caseta_dentro():
    im, d = lienzo(40, 34)
    d.rectangle((0, 0, 39, 33), fill=(236, 236, 230, 255))
    d.rectangle((0, 0, 39, 5), fill=(220, 220, 214, 255))                   # muro de arriba (se ve su cara)
    d.rectangle((15, 0, 24, 5), fill=(130, 84, 50, 255)); d.rectangle((16, 1, 23, 5), fill=(160, 104, 62, 255))  # puerta al camino
    d.rectangle((2, 6, 37, 31), fill=(176, 176, 172, 255))                  # piso
    for x in range(2, 38, 6): d.line((x, 6, x, 31), fill=(160, 160, 156, 255))
    for y in range(6, 32, 6): d.line((2, y, 37, y), fill=(160, 160, 156, 255))
    for y in (14, 20): d.rectangle((0, y, 1, y + 4), fill=AZUL_V); d.rectangle((38, y, 39, y + 4), fill=AZUL_V)   # ventanas laterales
    d.rectangle((10, 32, 29, 33), fill=AZUL_V)                              # ventanal de abajo
    return im

# ---------- Edificio Central a medio demoler ----------
def central_demolido():
    random.seed(7); im, d = lienzo(64, 58)
    d.polygon([(4, 0), (36, 0), (40, 6), (34, 10), (38, 16), (30, 22), (0, 22)], fill=TEJA)   # techo que queda
    for y in range(2, 22, 3): d.line((1, y, 33, y), fill=TEJA2)
    for x in range(4, 34, 4): d.line((x, 1, x, 21), fill=TEJA2)
    d.line((2, 1, 30, 1), fill=TEJA3)
    for x0, y0, x1, y1 in ((34, 10, 50, 20), (30, 22, 56, 26)):                               # vigas expuestas
        d.line((x0, y0, x1, y1), fill=(120, 80, 44, 255), width=2)
    d.rectangle((0, 22, 46, 44), fill=CREMA)                                                  # muro que queda
    d.polygon([(46, 22), (52, 28), (48, 34), (54, 40), (46, 44)], fill=CREMA)                 # orilla rota
    for x in range(3, 40, 7):
        for y in (25, 33): ventana(d, x, y)
    d.rectangle((24, 30, 34, 40), fill=(30, 26, 26, 255))                                     # boquete en el muro
    d.polygon([(24, 30), (27, 28), (31, 30), (34, 29), (34, 40), (24, 40)], fill=(30, 26, 26, 255))
    for _ in range(120):                                                                      # montón de escombro
        x, y = random.randint(26, 63), random.randint(36, 57)
        if (x - 46) ** 2 / 300 + (y - 50) ** 2 / 60 > 1: continue
        c = random.choice([GRIS, GRIS2, GRIS3, CREMA, CREMA_OSC, TEJA, TEJA2])
        d.rectangle((x, y, x + random.randint(1, 2), y + 1), fill=c)
    for x in (34, 44, 52): d.line((x, 40, x + 2, 34), fill=(120, 80, 44, 255))               # varillas
    d.rectangle((0, 44, 26, 47), fill=CREMA_OSC)
    return im

# ---------- Patio ----------
def fuente():
    im, d = lienzo(32, 32)
    d.ellipse((0, 0, 31, 31), fill=GRIS3); d.ellipse((2, 2, 29, 29), fill=GRIS)
    d.ellipse((4, 4, 27, 27), fill=(30, 110, 210, 255))
    for a, b in ((8, 10), (17, 7), (20, 19), (9, 20)): d.line((a, b, a + 4, b), fill=(140, 200, 250, 255))
    d.ellipse((12, 12, 19, 19), fill=GRIS3); d.ellipse((14, 14, 17, 17), fill=(140, 200, 250, 255))
    return im
def seto(w, h):
    random.seed(w * h); im, d = lienzo(w, h)
    d.rectangle((0, 0, w - 1, h - 1), fill=(20, 110, 40, 255))
    d.rectangle((0, 0, w - 1, 0), fill=(60, 150, 60, 255))
    for _ in range(w * h // 6): d.point((random.randrange(w), random.randrange(h)), fill=random.choice([(10, 80, 30, 255), (40, 140, 50, 255)]))
    return im
def seto_l():
    im, d = lienzo(30, 14); im.paste(seto(30, 5), (0, 0)); im.paste(seto(5, 14), (0, 0)); return im

# ---------- Entrada ----------
def reja():
    im, d = lienzo(16, 12)
    d.rectangle((0, 1, 15, 2), fill=(70, 70, 76, 255)); d.rectangle((0, 9, 15, 10), fill=(70, 70, 76, 255))
    for x in range(1, 16, 3): d.rectangle((x, 0, x, 11), fill=(56, 56, 62, 255)); d.point((x, 0), fill=(110, 110, 118, 255))
    return im
def pluma():
    im, d = lienzo(56, 12)
    d.rectangle((0, 2, 7, 11), fill=(240, 190, 20, 255)); d.rectangle((0, 2, 7, 3), fill=(255, 220, 80, 255))
    for y in (6, 9): d.line((0, y, 7, y), fill=NEGRO)
    for i in range(6):
        d.rectangle((8 + i * 8, 4, 15 + i * 8, 6), fill=(240, 240, 236, 255) if i % 2 == 0 else (220, 40, 30, 255))
    d.rectangle((52, 3, 55, 7), fill=(220, 40, 30, 255))
    return im
def puerta_alumnos():
    im, d = lienzo(24, 14)
    for x in (0, 21): d.rectangle((x, 0, x + 2, 13), fill=(70, 70, 76, 255)); d.point((x + 1, 0), fill=(140, 140, 148, 255))
    d.polygon([(3, 12), (12, 4), (13, 5), (4, 13)], fill=(90, 90, 98, 255))                  # hoja abierta
    for k in range(4): d.line((5 + k * 2, 11 - k * 2, 6 + k * 2, 13 - k * 2), fill=(56, 56, 62, 255))
    return im

# ---------- Obra ----------
def hueco():
    random.seed(3); im, d = lienzo(34, 26)
    d.ellipse((3, 4, 30, 23), fill=(120, 80, 48, 255)); d.ellipse((6, 6, 27, 21), fill=(70, 46, 30, 255))
    d.ellipse((8, 8, 25, 19), fill=(14, 10, 10, 255))
    for _ in range(40):
        x, y = random.randint(2, 31), random.randint(3, 23)
        if 0.7 < ((x - 16.5) / 14) ** 2 + ((y - 13.5) / 10) ** 2 < 1.2: d.point((x, y), fill=random.choice([(140, 96, 58, 255), (96, 64, 40, 255)]))
    for x, y in ((0, 2), (31, 2), (0, 22), (31, 22)): d.rectangle((x, y - 2, x + 2, y + 2), fill=(240, 120, 30, 255))  # postes
    for (x0, y0, x1, y1) in ((2, 1, 31, 1), (2, 23, 31, 23), (1, 3, 1, 21), (32, 3, 32, 21)):                         # cinta amarilla
        n = max(abs(x1 - x0), abs(y1 - y0))
        for k in range(n + 1):
            x, y = x0 + (x1 - x0) * k // max(n, 1), y0 + (y1 - y0) * k // max(n, 1)
            d.point((x, y), fill=(250, 210, 30, 255) if (k // 2) % 2 == 0 else NEGRO)
    return im
def escombro():
    random.seed(11); im, d = lienzo(34, 18)
    for _ in range(170):
        x, y = random.randint(0, 32), random.randint(0, 16)
        if ((x - 16) / 17) ** 2 + ((y - 10) / 8) ** 2 > 1: continue
        c = random.choice([GRIS, GRIS2, GRIS3, CREMA, CREMA_OSC, TEJA2])
        d.rectangle((x, y, x + random.randint(0, 2), y + random.randint(0, 1)), fill=c)
    for x in (8, 18, 26): d.line((x, 6, x + 3, 1), fill=(120, 80, 44, 255))
    return im
def cono():
    im, d = lienzo(8, 10)
    d.polygon([(3, 0), (4, 0), (7, 8), (0, 8)], fill=(250, 120, 20, 255)); d.rectangle((0, 8, 7, 9), fill=(200, 90, 10, 255))
    d.line((2, 4, 5, 4), fill=(250, 250, 250, 255))
    return im

# ---------- Pisos (16x16, sin contorno porque se repiten) ----------
def piso(tipo):
    random.seed(len(tipo)); im, d = lienzo(16, 16)
    if tipo == "pasto":
        d.rectangle((0, 0, 15, 15), fill=(40, 130, 50, 255))
        for _ in range(26):
            x, y = random.randrange(16), random.randrange(15)
            d.point((x, y), fill=(24, 100, 36, 255)); d.point((x, y + 1), fill=(70, 170, 70, 255))
    elif tipo == "adoquin":
        d.rectangle((0, 0, 15, 15), fill=(110, 40, 30, 255))
        for fila in range(4):
            off = 0 if fila % 2 == 0 else 4
            for col in range(-1, 3):
                x, y = col * 8 + off, fila * 4
                d.rectangle((x + 1, y + 1, x + 7, y + 3), fill=random.choice([(200, 70, 50, 255), (184, 60, 44, 255)]))
                d.line((x + 1, y + 1, x + 6, y + 1), fill=(226, 104, 80, 255))
    elif tipo == "losas":
        d.rectangle((0, 0, 15, 15), fill=(176, 176, 172, 255))
        d.line((0, 0, 15, 0), fill=(130, 130, 128, 255)); d.line((0, 0, 0, 15), fill=(130, 130, 128, 255)); d.line((1, 8, 15, 8), fill=(150, 150, 146, 255))
        d.line((1, 1, 15, 1), fill=(200, 200, 196, 255))
    elif tipo == "asfalto":
        d.rectangle((0, 0, 15, 15), fill=(60, 62, 66, 255))
        for _ in range(18): d.point((random.randrange(16), random.randrange(16)), fill=random.choice([(48, 50, 54, 255), (78, 80, 84, 255)]))
    return im

piezas = {
    "caseta_fuera": caseta_fuera(), "caseta_dentro": caseta_dentro(), "central_demolido": central_demolido(),
    "fuente": fuente(), "seto_recto": seto(30, 5), "seto_l": seto_l(), "reja": reja(), "pluma": pluma(),
    "puerta_alumnos": puerta_alumnos(), "hueco_con_cinta": hueco(), "escombro": escombro(), "cono": cono(),
}
listas = {n: guardar(im, n) for n, im in piezas.items()}
for t in ("pasto", "adoquin", "losas", "asfalto"): guardar(piso(t), f"piso_{t}", contorno=False)
print("ok", len(listas))
