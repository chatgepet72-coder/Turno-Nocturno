"""Autos en pixel art vistos desde arriba (frente hacia arriba). Dibujados a 1x y escalados sin suavizado."""
import random, sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
random.seed(3)

def tono(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)

def auto(tipo, color, sucio=False):
    specs = {  # ancho, alto, [(seccion, alto)]
        "sedan":    (30, 60, [("cofre", 15), ("parabrisas", 8), ("techo", 17), ("medallon", 6), ("cajuela", 10)]),
        "compacto": (28, 50, [("cofre", 11), ("parabrisas", 8), ("techo", 20), ("medallon", 7), ("cajuela", 2)]),
        "pickup":   (32, 66, [("cofre", 15), ("parabrisas", 8), ("techo", 11), ("medallon", 4), ("caja", 26)]),
        "camioneta":(34, 62, [("cofre", 13), ("parabrisas", 8), ("techo", 30), ("medallon", 5), ("cajuela", 2)]),
        "combi":    (34, 68, [("cofre", 4), ("parabrisas", 9), ("techo", 51), ("medallon", 4), ("cajuela", 0)]),
    }
    w, h, secs = specs[tipo]
    W, H = w + 8, h + 8
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = 4, 4, 4 + w - 1, 4 + h - 1
    # sombra
    d.rounded_rectangle((x0 + 2, y0 + 3, x1 + 2, y1 + 3), 6, fill=(0, 0, 0, 90))
    # llantas
    llanta = (22, 22, 24, 255)
    for ty in (y0 + 7, y1 - 15):
        d.rectangle((x0 - 2, ty, x0 + 2, ty + 9), fill=llanta)
        d.rectangle((x1 - 2, ty, x1 + 2, ty + 9), fill=llanta)
    base, luz, sombra, borde = tono(color, 1), tono(color, 1.25), tono(color, 0.72), tono(color, 0.4)
    d.rounded_rectangle((x0, y0, x1, y1), 6 if tipo != "combi" else 4, fill=base, outline=borde)
    # volumen: costado izquierdo con luz, derecho en sombra
    d.line((x0 + 1, y0 + 6, x0 + 1, y1 - 6), fill=luz)
    d.line((x1 - 1, y0 + 6, x1 - 1, y1 - 6), fill=sombra)
    d.line((x1 - 2, y0 + 8, x1 - 2, y1 - 8), fill=sombra)
    vidrio, vidrio_luz = (34, 46, 60, 255), (96, 120, 140, 255)
    y = y0
    for nombre, alto in secs:
        if nombre == "parabrisas":
            d.polygon([(x0 + 3, y + alto - 1), (x0 + 5, y), (x1 - 5, y), (x1 - 3, y + alto - 1)], fill=vidrio)
            d.line((x0 + 7, y + 2, x0 + 11, y + 2), fill=vidrio_luz)
        elif nombre == "medallon":
            d.polygon([(x0 + 4, y), (x1 - 4, y), (x1 - 6, y + alto - 1), (x0 + 6, y + alto - 1)], fill=vidrio)
        elif nombre == "techo":
            d.rectangle((x0 + 4, y, x1 - 4, y + alto - 1), fill=tono(color, 1.08))
            d.line((x0 + 3, y, x0 + 3, y + alto - 1), fill=vidrio)   # ventanas laterales
            d.line((x1 - 3, y, x1 - 3, y + alto - 1), fill=vidrio)
            if tipo == "camioneta":
                for rx in (x0 + 8, x1 - 8):
                    d.line((rx, y + 3, rx, y + alto - 4), fill=borde)
            if tipo == "combi":
                for ry in range(y + 6, y + alto - 2, 8):
                    d.line((x0 + 6, ry, x1 - 6, ry), fill=tono(color, 0.9))
        elif nombre == "cofre":
            d.line(((x0 + x1) // 2, y + 3, (x0 + x1) // 2, y + alto - 2), fill=tono(color, 0.9))
        elif nombre == "caja":
            d.rectangle((x0 + 3, y + 1, x1 - 3, y + alto - 3), fill=tono(color, 0.5))
            for ry in range(y + 4, y + alto - 3, 4):
                d.line((x0 + 4, ry, x1 - 4, ry), fill=tono(color, 0.42))
        y += alto
    # faros y calaveras
    d.rectangle((x0 + 2, y0, x0 + 6, y0 + 1), fill=(250, 240, 190, 255))
    d.rectangle((x1 - 6, y0, x1 - 2, y0 + 1), fill=(250, 240, 190, 255))
    d.rectangle((x0 + 2, y1 - 1, x0 + 6, y1), fill=(170, 30, 30, 255))
    d.rectangle((x1 - 6, y1 - 1, x1 - 2, y1), fill=(170, 30, 30, 255))
    # espejos
    py = y0 + secs[0][1] + 1
    d.rectangle((x0 - 2, py, x0, py + 2), fill=borde); d.rectangle((x1, py, x1 + 2, py + 2), fill=borde)
    if sucio:  # tierra negra escurriendo y parabrisas estrellado
        for _ in range(55):
            px, pyy = random.randint(x0 + 2, x1 - 2), random.randint(y0 + 2, y1 - 2)
            d.point((px, pyy), fill=(18, 14, 12, 255))
        for sx in (x0 + 6, x1 - 9):
            d.line((sx, y0 + 10, sx + random.randint(-2, 2), y1 - 4), fill=(20, 15, 12, 255), width=2)
        py2 = y0 + secs[0][1]
        d.line((x0 + 10, py2 + 1, x0 + 16, py2 + 6), fill=(200, 210, 220, 255))
        d.line((x0 + 16, py2 + 1, x0 + 12, py2 + 7), fill=(200, 210, 220, 255))
    return im

modelos = [
    ("Sedán", "sedan", (150, 28, 30)),
    ("Sedán", "sedan", (205, 205, 200)),
    ("Compacto", "compacto", (40, 80, 150)),
    ("Compacto", "compacto", (200, 160, 40)),
    ("Pickup", "pickup", (70, 100, 70)),
    ("Camioneta", "camioneta", (30, 30, 34)),
    ("Combi", "combi", (230, 225, 210)),
    ("Abandonado (con tierra)", "sedan", (120, 120, 112)),
]
ESC = 4
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
celda_w, celda_h = 46 * ESC, 80 * ESC
lienzo = Image.new("RGBA", (celda_w * 4, celda_h * 2 + 20), (52, 54, 56, 255))
ld = ImageDraw.Draw(lienzo)
for _ in range(9000):  # textura de asfalto
    x, y = random.randrange(lienzo.width), random.randrange(lienzo.height)
    v = random.randint(-10, 10); ld.point((x, y), fill=(52 + v, 54 + v, 56 + v, 255))
for i, (nombre, tipo, color) in enumerate(modelos):
    a = auto(tipo, color, sucio=nombre.startswith("Abandonado"))
    a.save(f"{OUT}/auto_{i+1}_{tipo}.png")
    g = a.resize((a.width * ESC, a.height * ESC), Image.NEAREST)
    cx, cy = (i % 4) * celda_w, (i // 4) * celda_h
    ld.rectangle((cx + 2, cy + 10, cx + 5, cy + celda_h - 30), fill=(205, 200, 175, 255))  # línea del cajón
    lienzo.paste(g, (cx + (celda_w - g.width) // 2, cy + 10), g)
    ld.text((cx + 12, cy + celda_h - 22), nombre, fill=(230, 225, 205, 255), font=f)
lienzo.save(f"{OUT}/autos_opciones.png"); print("autos ok")
