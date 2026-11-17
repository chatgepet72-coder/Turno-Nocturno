"""Vocho, Tsuru con lodo y manchas de tierra negra como piezas sueltas (decals)."""
import random, sys, importlib.util
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
spec = importlib.util.spec_from_file_location("autos", f"{OUT}/autos.py")
# reutiliza auto() y tono() sin volver a generar la hoja anterior
src = open(f"{OUT}/autos.py").read().split("modelos = [")[0]
ns = {}; exec(src, ns); auto, tono = ns["auto"], ns["tono"]

def vocho(color):
    W, H = 36, 54
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    base, luz, sombra, borde = tono(color, 1), tono(color, 1.25), tono(color, .72), tono(color, .4)
    d.ellipse((6, 7, 32, 52), fill=(0, 0, 0, 90))                     # sombra
    for fx, fy in ((3, 9), (25, 9), (3, 34), (25, 34)):                  # salpicaderas redondas
        d.ellipse((fx, fy, fx + 8, fy + 12), fill=base, outline=borde)
        d.rectangle((fx + (0 if fx < 10 else 6), fy + 3, fx + (2 if fx < 10 else 8), fy + 9), fill=(22, 22, 24, 255))
    d.ellipse((7, 3, 29, 51), fill=base, outline=borde)               # cuerpo redondo
    d.arc((8, 5, 28, 49), 120, 240, fill=luz); d.arc((8, 5, 28, 49), 300, 60, fill=sombra)
    d.chord((10, 15, 26, 25), 180, 360, fill=(34, 46, 60, 255))          # parabrisas curvo
    d.line((12, 18, 15, 17), fill=(96, 120, 140, 255))
    d.ellipse((10, 19, 26, 38), fill=tono(color, 1.08))                 # techo
    d.chord((12, 33, 24, 41), 0, 180, fill=(34, 46, 60, 255))            # medallón chico
    for y in range(43, 49, 2): d.line((14, y, 22, y), fill=borde)       # rejillas del motor
    d.rectangle((9, 9, 11, 10), fill=(250, 240, 190, 255)); d.rectangle((25, 9, 27, 10), fill=(250, 240, 190, 255))
    d.rectangle((9, 47, 11, 48), fill=(170, 30, 30, 255)); d.rectangle((25, 47, 27, 48), fill=(170, 30, 30, 255))
    return im

def lodo(im, seed=5):
    """Salpicaduras de lodo café claro en la parte baja y alrededor de las llantas."""
    random.seed(seed); d = ImageDraw.Draw(im); a = im.split()[3]
    cafe = [(122, 92, 58, 255), (104, 78, 50, 255), (140, 108, 70, 255)]
    for _ in range(170):
        x = random.choice([random.randint(2, 9), random.randint(im.width - 10, im.width - 3), random.randint(2, im.width - 3)])
        y = random.randint(int(im.height * .15), im.height - 4) if random.random() < .7 else random.randint(4, im.height - 4)
        if a.getpixel((x, y)) > 200 and random.random() < .8:
            d.point((x, y), fill=random.choice(cafe))
    return im

def tierra_decal(seed, w=44, h=34):
    """Tierra regada: mancha plana e irregular, granulada, con terrones chicos, piedritas y migajas alrededor."""
    random.seed(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = im.load()
    pal = [(54, 39, 28), (66, 48, 34), (78, 58, 41), (46, 33, 24), (90, 68, 48)]
    cx, cy = w / 2, h / 2
    centros = [(cx + random.uniform(-w * .28, w * .28), cy + random.uniform(-h * .22, h * .22), random.uniform(4, 9)) for _ in range(9)]
    def dentro(x, y):
        return sum(1 for a, b, r in centros if (x - a) ** 2 + (y - b) ** 2 < r * r)
    for y in range(h):
        for x in range(w):
            n = dentro(x, y)
            if n:
                c = random.choice(pal)
                if n == 1 and random.random() < .45: c = tuple(int(v * .8) for v in c)  # orilla más oscura
                if random.random() < .12 and n > 1: c = (104, 80, 57)                   # grano claro
                px[x, y] = c + (255,)
            elif random.random() < .05 and dentro(x + random.randint(-4, 4), y + random.randint(-4, 4)):
                px[x, y] = random.choice(pal) + (255,)                                   # migajas sueltas
    d = ImageDraw.Draw(im)
    for _ in range(5):  # terrones chicos con luz arriba
        a, b, r = random.choice(centros); x, y = int(a + random.uniform(-r / 2, r / 2)), int(b + random.uniform(-r / 2, r / 2))
        d.rectangle((x, y, x + 2, y + 1), fill=(40, 29, 21, 255)); d.point((x, y), fill=(112, 88, 64, 255))
    for _ in range(3):  # piedritas grises
        a, b, r = random.choice(centros); x, y = int(a), int(b + random.uniform(-r / 2, r / 2))
        d.point((x, y), fill=(120, 114, 104, 255)); d.point((x + 1, y), fill=(92, 88, 80, 255))
    return im

f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
ESC = 4
# Autos nuevos
v1, v2 = vocho((60, 120, 170)), vocho((200, 70, 40))
tsuru = lodo(auto("sedan", (226, 226, 220)))
for n, im in (("vocho_azul", v1), ("vocho_rojo", v2), ("tsuru_lodo", tsuru)): im.save(f"{OUT}/{n}.png")
lienzo = Image.new("RGBA", (190 * 3, 340), (52, 54, 56, 255)); ld = ImageDraw.Draw(lienzo)
for i, (n, im) in enumerate((("Vocho azul", v1), ("Vocho rojo", v2), ("Tsuru blanco con lodo", tsuru))):
    g = im.resize((im.width * ESC, im.height * ESC), Image.NEAREST)
    lienzo.paste(g, (i * 190 + (190 - g.width) // 2, 10), g)
    ld.text((i * 190 + 10, 310), n, fill=(230, 225, 205, 255), font=f)
lienzo.save(f"{OUT}/autos_mexicanos.png")

# Tierra sobre los pisos y sobre un auto
P = "/home/user/pendientes/pisos"
decals = [tierra_decal(s) for s in (11, 12, 13, 14)]
for i, dcl in enumerate(decals): dcl.save(f"{P}/tierra_{i+1}.png")
def base(tile, n=5):
    t = Image.open(f"{P}/{tile}").convert("RGBA")
    b = Image.new("RGBA", (32 * n, 32 * n))
    for x in range(n):
        for y in range(n): b.paste(t, (x * 32, y * 32))
    return b
escenas = []
for tile in ("piso_1.png", "piso_2.png", "piso_4.png"):
    b = base(tile); random.seed(len(tile) + ord(tile[5]))
    for k, (x, y) in enumerate(((20, 30), (90, 70), (50, 110), (110, 18))):
        b.paste(decals[k % 4], (x, y), decals[k % 4])
    escenas.append(b)
t2 = tsuru.copy(); t2.paste(decals[0].resize((22, 16), Image.NEAREST), (6, 20), decals[0].resize((22, 16), Image.NEAREST))
fondo = base("piso_4.png", 3); fondo.paste(t2, (24, 10), t2); escenas.append(fondo)
nombres = ["Losas con tierra", "Adoquín con tierra", "Estacionamiento con tierra", "Auto con tierra encima"]
ESC = 3
lienzo = Image.new("RGBA", (500 * 2, 520 * 2), (30, 32, 34, 255)); ld = ImageDraw.Draw(lienzo)
for i, (e, n) in enumerate(zip(escenas, nombres)):
    g = e.resize((e.width * ESC, e.height * ESC), Image.NEAREST)
    x, y = (i % 2) * 500 + 10, (i // 2) * 520 + 10
    lienzo.paste(g, (x, y), g); ld.text((x, y + 485), n, fill=(230, 225, 205, 255), font=f)
lienzo.save(f"{P}/tierra_v2.png"); print("ok")
