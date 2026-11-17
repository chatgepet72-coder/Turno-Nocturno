"""Convierte el arte aprobado al tamaño del juego.
Escala: 1 pixel de arte = 4 px en el viewport de 640x360. Personajes de ~60 px de alto.
Uso: python3 tools/arte/preparar_assets.py <carpeta_pendientes> <carpeta_magicart99_assets>"""
import os, sys, shutil
from PIL import Image, ImageDraw
PEN, MAG = sys.argv[1], sys.argv[2]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A = 4
NEGRO = (16, 14, 14, 255)
def dst(*p):
    path = os.path.join(R, "assets", "sprites", *p); os.makedirs(os.path.dirname(path), exist_ok=True); return path
def borde(im):
    w, h = im.size; src = im.load(); out = im.copy(); px = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and src[x + dx, y + dy][3] > 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = NEGRO
    return out
def pad(im, p=1):
    o = Image.new("RGBA", (im.width + 2 * p, im.height + 2 * p), (0, 0, 0, 0)); o.paste(im, (p, p)); return o

# ---- Caseta más grande (56x46 de arte) para que quepan Lalo, Don Chava y el escritorio ----
AZ, AZ2 = (40, 110, 220, 255), (120, 180, 250, 255)
def caseta_dentro():
    im = Image.new("RGBA", (56, 46)); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 55, 45), fill=(236, 236, 230, 255)); d.rectangle((0, 0, 55, 6), fill=(220, 220, 214, 255))
    d.rectangle((23, 0, 32, 6), fill=(130, 84, 50, 255)); d.rectangle((24, 1, 31, 6), fill=(160, 104, 62, 255))
    d.rectangle((2, 7, 53, 43), fill=(176, 176, 172, 255))
    for x in range(2, 54, 6): d.line((x, 7, x, 43), fill=(160, 160, 156, 255))
    for y in range(7, 44, 6): d.line((2, y, 53, y), fill=(160, 160, 156, 255))
    for y in (16, 28): d.rectangle((0, y, 1, y + 6), fill=AZ); d.rectangle((54, y, 55, y + 6), fill=AZ)
    d.rectangle((12, 44, 43, 45), fill=AZ)
    return im
def caseta_fuera():
    im = Image.new("RGBA", (56, 46)); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 55, 18), fill=(196, 196, 198, 255)); d.rectangle((0, 0, 55, 1), fill=(220, 220, 222, 255)); d.rectangle((0, 16, 55, 18), fill=(150, 150, 152, 255))
    d.rectangle((8, 5, 17, 12), fill=(150, 150, 152, 255)); d.rectangle((9, 5, 16, 7), fill=(70, 70, 74, 255))
    d.rectangle((0, 19, 55, 45), fill=(236, 236, 230, 255)); d.rectangle((0, 19, 55, 21), fill=(30, 70, 150, 255))
    for x in (4, 17, 30, 43):
        d.rectangle((x, 25, x + 9, 35), fill=NEGRO); d.rectangle((x + 1, 26, x + 8, 34), fill=AZ)
        d.line((x + 1, 26, x + 3, 26), fill=AZ2); d.line((x + 5, 26, x + 5, 34), fill=NEGRO)
    d.rectangle((22, 20, 33, 21), fill=(250, 250, 250, 255)); d.rectangle((20, 40, 35, 45), fill=(210, 210, 204, 255))
    return im
for n, im in (("caseta_dentro", caseta_dentro()), ("caseta_fuera", caseta_fuera())):
    im = borde(pad(im)); im.resize((im.width * A, im.height * A), Image.NEAREST).save(dst("escenario", f"{n}.png"))

# ---- Mis piezas (guardadas a x8) -> x4 ----
for n in ("central_demolido", "fuente", "seto_recto", "seto_l", "reja", "pluma", "puerta_alumnos", "hueco_con_cinta", "escombro", "cono"):
    im = Image.open(f"{PEN}/estilo/piezas/{n}.png"); im.resize((im.width // 2, im.height // 2), Image.NEAREST).save(dst("escenario", f"{n}.png"))
for t in ("pasto", "adoquin", "losas", "asfalto"):
    im = Image.open(f"{PEN}/estilo/piezas/piso_{t}.png"); im.resize((im.width // 2, im.height // 2), Image.NEAREST).save(dst("pisos", f"{t}.png"))

# ---- Piezas del equipo, a su ancho en arte ----
for n, ancho in (("edificio_largo", 162), ("excavadora", 62), ("arbol", 32), ("banca", 18), ("poste", 6)):
    im = Image.open(f"{PEN}/sprites_equipo/{n}.png"); w = ancho * A
    im.resize((w, round(im.height * w / im.width)), Image.LANCZOS).save(dst("escenario", f"{n}.png"))

# ---- Autos con contorno negro ----
for n in ("auto_1_sedan", "auto_2_sedan", "auto_3_compacto", "auto_5_pickup", "auto_6_camioneta", "auto_7_combi", "vocho_azul", "vocho_rojo", "tsuru_lodo"):
    a = Image.open(f"{PEN}/autos/{n}.png").convert("RGBA"); px = a.load()
    for y in range(a.height):
        for x in range(a.width):
            if px[x, y][3] < 200: px[x, y] = (0, 0, 0, 0)
    a = borde(pad(a.resize((a.width // 2, a.height // 2), Image.NEAREST)))
    a.resize((a.width * A, a.height * A), Image.NEAREST).save(dst("escenario", "autos", f"{n}.png"))

# ---- Tierra negra (decals, para más adelante) ----
for n in ("tierra_v3_rastro_1", "tierra_v3_rastro_2", "tierra_v3_juntas", "tierra_v3_huellas"):
    im = Image.open(f"{PEN}/pisos/{n}.png"); im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(dst("escenario", "tierra", n.replace("tierra_v3_", "") + ".png"))

# ---- Personajes al tamaño del juego ----
def union_bbox(ims):
    bs = [im.getbbox() for im in ims]; return (min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs))
def caminar(origen, destino, alto):
    ims = {f"{dr}_{i}": Image.open(f"{origen}/{dr}_{i}.png").convert("RGBA") for dr in ("down", "left", "right", "up") for i in range(1, 5)}
    bb = union_bbox(list(ims.values())); esc = alto / (bb[3] - bb[1])
    for k, im in ims.items():
        c = im.crop(bb); c.resize((round(c.width * esc), round(c.height * esc)), Image.LANCZOS).save(dst("personajes", destino, "caminar", f"{k}.png"))
caminar(f"{MAG}/sprites/lalo", "lalo", 60)
caminar(f"{MAG}/sprites/guardia", "don_chava", 64)
for quien, base_alto, alto in (("lalo", 224, 60), ("don_chava", 289, 64)):
    esc = alto / base_alto
    for f in sorted(os.listdir(f"{PEN}/sentados_v2/{quien}")):
        if not f.endswith(".png") or f.startswith("hoja"): continue
        im = Image.open(f"{PEN}/sentados_v2/{quien}/{f}")
        im.resize((round(im.width * esc), round(im.height * esc)), Image.LANCZOS).save(dst("personajes", quien, "sentado", f))
# Muebles de la caseta (magicart99)
for n, ancho in (("escritorio", 20), ("casillero", 10), ("silla", 9), ("termo", 3)):
    im = Image.open(f"{MAG}/sprites/{n}.png").convert("RGBA"); im = im.crop(im.getbbox()); w = ancho * A
    im.resize((w, round(im.height * w / im.width)), Image.LANCZOS).save(dst("escenario", "caseta", f"{n}.png"))

# ---- Texturas de luz ----
import math
rad = Image.new("RGBA", (256, 256))
for y in range(256):
    for x in range(256):
        r = math.hypot(x - 127.5, y - 127.5) / 128
        v = max(0.0, 1 - r) ** 1.6; rad.putpixel((x, y), (255, 255, 255, int(255 * v)))
rad.save(dst("luces", "luz_radial.png"))
cono = Image.new("RGBA", (512, 256)); ang = math.radians(26)
for y in range(256):
    for x in range(512):
        dx, dy = x - 256, y - 128
        if dx <= 0: continue
        a = abs(math.atan2(dy, dx)); dist = math.hypot(dx, dy) / 256
        if a > ang or dist > 1: continue
        v = (1 - (a / ang) ** 2) * (1 - dist) ** 0.7
        cono.putpixel((x, y), (255, 255, 255, int(255 * max(0, min(1, v)))))
cono.save(dst("luces", "cono_linterna.png"))
print("ok")
