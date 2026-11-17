"""Piezas del prólogo en el estilo del equipo: sótano del Central, linterna de Don Chava en el piso y maniquí sentado.
Uso: python3 tools/arte/prologo_piezas.py"""
import os, random
from PIL import Image, ImageDraw
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A = 4; NEGRO = (16, 14, 14, 255)
def dst(n):
    p = os.path.join(R, "assets", "sprites", "escenario", "prologo", n); os.makedirs(os.path.dirname(p), exist_ok=True); return p
def borde(im):
    w, h = im.size; src = im.load(); out = im.copy(); px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and src[x + dx, y + dy][3] > 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = NEGRO
    return out
def pad(im): o = Image.new("RGBA", (im.width + 2, im.height + 2)); o.paste(im, (1, 1)); return o
def guardar(im, n, contorno=True):
    if contorno: im = borde(pad(im))
    im.resize((im.width * A, im.height * A), Image.NEAREST).save(dst(n))

# ---- Sótano del Edificio Central (160x90 de arte = 640x360 en el juego) ----
random.seed(4)
s = Image.new("RGBA", (160, 90), (44, 42, 40, 255)); d = ImageDraw.Draw(s)
for _ in range(900): d.point((random.randrange(160), random.randrange(22, 90)), fill=random.choice([(36, 34, 32, 255), (54, 52, 48, 255)]))
def ladrillos(x0, y0, x1, y1):
    d.rectangle((x0, y0, x1, y1), fill=(52, 36, 30, 255))
    for fila, y in enumerate(range(y0, y1, 4)):
        off = 0 if fila % 2 == 0 else 4
        for x in range(x0 - 4 + off, x1, 8):
            d.rectangle((max(x0, x + 1), y + 1, min(x1, x + 7), min(y1, y + 3)), fill=random.choice([(118, 64, 46, 255), (104, 56, 40, 255), (126, 72, 52, 255)]))
ladrillos(0, 0, 159, 21); ladrillos(0, 0, 5, 89); ladrillos(154, 0, 159, 89); ladrillos(0, 84, 159, 89)
d.rectangle((0, 20, 159, 21), fill=(30, 22, 18, 255))
# muro roto y escalera de piedra hacia abajo, tapada por el derrumbe
d.polygon([(92, 0), (98, 2), (100, 6), (124, 4), (130, 10), (128, 21), (94, 21), (90, 12)], fill=(12, 9, 9, 255))
for k, y in enumerate(range(6, 21, 3)): d.rectangle((98 + k, y, 124 - k, y + 1), fill=(70, 66, 60, 255))
for _ in range(260):
    x, y = random.randint(84, 140), random.randint(8, 46)
    if ((x - 112) / 28) ** 2 + ((y - 24) / 20) ** 2 > 1: continue
    c = random.choice([(96, 92, 86, 255), (120, 116, 108, 255), (80, 76, 70, 255), (118, 64, 46, 255), (70, 50, 40, 255)])
    d.rectangle((x, y, x + random.randint(1, 3), y + random.randint(1, 2)), fill=c)
for k in range(26):  # hilo de tierra negra que escurre del derrumbe
    x = 108 + int(3 * random.random()) - (k // 6); d.point((x, 44 + k), fill=(20, 18, 16, 255)); d.point((x + 1, 44 + k), fill=(32, 28, 24, 255))
# escalera de obra por donde bajó Lalo, con la luz que entra del hueco
d.rectangle((12, 8, 26, 50), fill=(56, 60, 70, 255))
for x in (13, 24): d.rectangle((x, 4, x + 1, 46), fill=(170, 170, 176, 255))
for y in range(8, 46, 5): d.line((13, y, 25, y), fill=(150, 150, 156, 255))
for _ in range(25): d.point((random.randint(28, 40), random.randint(30, 60)), fill=(88, 84, 78, 255))
s.save(dst("sotano.png")); s.resize((640, 360), Image.NEAREST).save(dst("sotano.png"))

# ---- Linterna de Don Chava tirada (10x5 de arte) ----
l = Image.new("RGBA", (10, 5)); d = ImageDraw.Draw(l)
d.rectangle((0, 1, 6, 3), fill=(70, 70, 76, 255)); d.rectangle((6, 0, 9, 4), fill=(110, 110, 118, 255)); d.rectangle((8, 1, 9, 3), fill=(255, 236, 160, 255))
d.line((1, 1, 5, 1), fill=(110, 110, 118, 255))
guardar(l, "linterna_don_chava.png")

# ---- Maniquí de RCP sentado (14x18 de arte), con tierra en el cuello ----
m = Image.new("RGBA", (14, 18)); d = ImageDraw.Draw(m)
PIEL, PIEL2, AZUL = (226, 196, 160, 255), (196, 164, 128, 255), (40, 70, 140, 255)
d.ellipse((4, 0, 9, 5), fill=PIEL); d.line((5, 1, 6, 1), fill=(240, 214, 182, 255))          # cabeza lisa, sin cara
d.rectangle((6, 5, 7, 6), fill=(30, 26, 22, 255))                                             # cuello con tierra
d.rectangle((3, 6, 10, 11), fill=PIEL); d.rectangle((3, 10, 10, 11), fill=PIEL2)               # torso
d.rectangle((1, 7, 2, 11), fill=PIEL2); d.rectangle((11, 7, 12, 11), fill=PIEL2)               # brazos caídos
d.rectangle((3, 12, 10, 14), fill=AZUL); d.rectangle((3, 15, 5, 17), fill=AZUL); d.rectangle((8, 15, 10, 17), fill=AZUL)  # piernas dobladas
for x, y in ((6, 7), (7, 9), (5, 12), (9, 16)): d.point((x, y), fill=(26, 22, 18, 255))         # tierra escurriendo
guardar(m, "maniqui_sentado.png")
print("ok")
