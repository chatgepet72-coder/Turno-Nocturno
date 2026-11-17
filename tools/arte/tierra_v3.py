"""Tierra negra v3: rastros arrastrados, tierra que brota de las juntas y huellas. Gris carbón con granos, sin manchas cafés lisas."""
import math, random, sys
from PIL import Image, ImageDraw, ImageFont
P = sys.argv[1]
NUCLEO = [(22, 21, 20), (30, 28, 26), (38, 35, 32), (46, 42, 38)]
GRANO_CLARO = [(66, 62, 56), (78, 72, 64)]
CALIDO = (56, 45, 36)
POLVO = (64, 60, 55)

def granular(px, x, y, densidad, w, h):
    if 0 <= x < w and 0 <= y < h and random.random() < densidad:
        r = random.random()
        c = random.choice(GRANO_CLARO) if r < .12 else (CALIDO if r < .2 else random.choice(NUCLEO))
        px[x, y] = c + (255,)

def polvo(px, x, y, w, h, a=70):
    if 0 <= x < w and 0 <= y < h and px[x, y][3] == 0 and random.random() < .5:
        px[x, y] = POLVO + (a,)

def rastro(seed, w=120, h=60):
    """Una línea de tierra arrastrada, más gruesa al inicio y que se deshace al final."""
    random.seed(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = im.load()
    pts, x, y, ang = [], 6.0, h / 2, random.uniform(-.3, .3)
    while x < w - 6:
        pts.append((x, y)); ang += random.uniform(-.25, .25); ang = max(-.6, min(.6, ang))
        x += math.cos(ang) * 1.5; y += math.sin(ang) * 1.5; y = max(10, min(h - 10, y))
    for i, (cx, cy) in enumerate(pts):
        t = i / len(pts); ancho = 5.5 * (1 - t) + 1.2
        for dy in range(-9, 10):
            for dx in range(-2, 3):
                X, Y, dist = int(cx + dx), int(cy + dy), abs(dy)
                if dist <= ancho:
                    granular(px, X, Y, .9 - .5 * (dist / ancho) - .35 * t, w, h)
                elif dist <= ancho + 4:
                    polvo(px, X, Y, w, h, int(80 * (1 - t)))
    d = ImageDraw.Draw(im)
    for k in range(3):  # surcos del arrastre
        off = random.uniform(-2.5, 2.5)
        for i in range(0, int(len(pts) * .7), 2):
            cx, cy = pts[i]; d.point((int(cx), int(cy + off)), fill=(16, 15, 14, 255))
    for _ in range(18):  # terroncitos y piedritas sueltas
        cx, cy = random.choice(pts[: len(pts) * 2 // 3])
        X, Y = int(cx + random.uniform(-3, 3)), int(cy + random.uniform(-9, 9))
        if 0 <= X < w - 1 and 0 <= Y < h - 1:
            px[X, Y] = (20, 19, 18, 255); px[X + 1, Y] = (58, 54, 50, 255)
    return im

def juntas(tile_px=32, n=4, seed=3):
    """Tierra que brota de las juntas de las losas: líneas rellenas y derrames pequeños hacia los lados."""
    random.seed(seed); w = h = tile_px * n
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = im.load()
    lineas = [("h", 16 + tile_px * 1), ("h", tile_px * 2), ("v", tile_px * 2)]
    for tipo, pos in lineas:
        largo0, largo1 = random.randint(0, 20), random.randint(w - 40, w)
        for a in range(largo0, largo1):
            for e in (-1, 0, 1):
                X, Y = (a, pos + e) if tipo == "h" else (pos + e, a)
                granular(px, X, Y, .95 if e == 0 else .7, w, h)
            if random.random() < .18:  # derrame desde la junta
                largo = random.randint(2, 6); lado = random.choice((-1, 1))
                for k in range(2, largo + 2):
                    for e2 in (-1, 0, 1):
                        X, Y = (a + e2, pos + lado * k) if tipo == "h" else (pos + lado * k, a + e2)
                        granular(px, X, Y, .8 - k * .1, w, h)
            for k in range(2, 6):
                X, Y = (a, pos + k * random.choice((-1, 1))) if tipo == "h" else (pos + k * random.choice((-1, 1)), a)
                polvo(px, X, Y, w, h, 60)
    return im

def huellas(seed=5, w=128, h=60):
    """Huellas de zapato con tierra (suela y tacón separados) que se van gastando al caminar."""
    random.seed(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = im.load()
    for i in range(6):
        cx, cy = 12 + i * 19, h / 2 + (-6 if i % 2 else 6)
        dens = .97 - i * .1
        for y in range(-5, 6):
            for x in range(-10, 11):
                planta = ((x - 3) / 7) ** 2 + (y / 4.6) ** 2 <= 1
                tacon = ((x + 7) / 3.2) ** 2 + (y / 3.8) ** 2 <= 1
                if planta or tacon:
                    borde = ((x - 3) / 7) ** 2 + (y / 4.6) ** 2 > .6 if planta else ((x + 7) / 3.2) ** 2 + (y / 3.8) ** 2 > .55
                    granular(px, int(cx + x), int(cy + y), dens if not borde else dens * .75, w, h)
                    if not borde and y % 2 == 0 and x % 3 == 0 and planta and random.random() < .7:
                        px[int(cx + x), int(cy + y)] = (14, 13, 12, 255)  # dibujo de la suela
                elif ((x - 1) / 12) ** 2 + (y / 6.5) ** 2 <= 1:
                    polvo(px, int(cx + x), int(cy + y), w, h, int(55 * dens))
    return im

def base(tile, n):
    t = Image.open(f"{P}/{tile}").convert("RGBA"); b = Image.new("RGBA", (32 * n, 32 * n))
    for x in range(n):
        for y in range(n): b.paste(t, (x * 32, y * 32))
    return b

r1, r2, j, hu = rastro(21), rastro(34, 110, 56), juntas(), huellas()
for n, im in (("rastro_1", r1), ("rastro_2", r2), ("juntas", j), ("huellas", hu)): im.save(f"{P}/tierra_v3_{n}.png")
escenas = []
b = base("piso_1.png", 4); b.alpha_composite(j); b.alpha_composite(r2.rotate(90, expand=True).crop((0, 0, 56, 110)), (70, 10)); escenas.append(("Losas: brota de las juntas", b))
b = base("piso_2.png", 4); b.alpha_composite(r1, (4, 34)); escenas.append(("Adoquín: rastro arrastrado", b))
b = base("piso_4.png", 4); b.alpha_composite(r2, (10, 6)); b.alpha_composite(hu, (4, 64)); escenas.append(("Estacionamiento: rastro y huellas", b))
b = base("piso_1.png", 4); b.alpha_composite(hu, (4, 34)); escenas.append(("Losas: huellas de tierra", b))
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
E = 3; cw = 128 * E + 20
L = Image.new("RGBA", (cw * 2, (128 * E + 30) * 2), (30, 32, 34, 255)); ld = ImageDraw.Draw(L)
for i, (n, e) in enumerate(escenas):
    g = e.resize((e.width * E, e.height * E), Image.NEAREST); x, y = (i % 2) * cw + 10, (i // 2) * (128 * E + 30) + 6
    L.paste(g, (x, y), g); ld.text((x, y + g.height + 4), n, fill=(230, 225, 205, 255), font=f)
L.save(f"{P}/tierra_v3.png"); print("ok")
