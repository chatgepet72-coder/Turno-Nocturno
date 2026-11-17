"""Tiles de 32x32 para el camino peatonal y el estacionamiento. Se repiten sin costuras."""
import random, sys
from PIL import Image, ImageDraw, ImageFont
OUT = sys.argv[1]
T = 32

def ruido(d, base, n, var, caja=(0, 0, T, T)):
    for _ in range(n):
        x, y = random.randrange(caja[0], caja[2]), random.randrange(caja[1], caja[3])
        v = random.randint(-var, var)
        d.point((x, y), fill=tuple(max(0, min(255, c + v)) for c in base))

def losas():
    random.seed(1); im = Image.new("RGB", (T, T), (128, 126, 118)); d = ImageDraw.Draw(im)
    ruido(d, (128, 126, 118), 260, 9)
    d.line((0, 0, T - 1, 0), fill=(92, 90, 84)); d.line((0, 0, 0, T - 1), fill=(92, 90, 84))
    d.line((0, 16, T - 1, 16), fill=(100, 98, 92))
    d.line((1, 1, T - 1, 1), fill=(146, 144, 136))
    d.line((9, 20, 13, 24), fill=(84, 82, 78)); d.line((13, 24, 12, 29), fill=(84, 82, 78))  # grieta
    return im

def adoquin():
    random.seed(2); im = Image.new("RGB", (T, T), (60, 52, 48)); d = ImageDraw.Draw(im)
    colores = [(150, 84, 62), (138, 76, 58), (160, 96, 70), (126, 72, 56)]
    for fila in range(4):
        off = 0 if fila % 2 == 0 else 8
        for col in range(-1, 3):
            x = col * 16 + off; y = fila * 8
            c = random.choice(colores)
            d.rectangle((x + 1, y + 1, x + 14, y + 6), fill=c)
            d.line((x + 1, y + 1, x + 14, y + 1), fill=tuple(min(255, v + 22) for v in c))
            d.line((x + 1, y + 6, x + 14, y + 6), fill=tuple(int(v * 0.75) for v in c))
    ruido(d, (140, 80, 60), 60, 14)
    return im

def orilla_pasto():
    random.seed(3); im = Image.new("RGB", (T, T), (128, 126, 118)); d = ImageDraw.Draw(im)
    ruido(d, (128, 126, 118), 180, 9, (0, 0, 20, T))
    d.rectangle((20, 0, 24, T - 1), fill=(196, 168, 52))            # guarnición pintada
    d.line((20, 0, 20, T - 1), fill=(222, 196, 80)); d.line((24, 0, 24, T - 1), fill=(150, 126, 40))
    d.rectangle((25, 0, T - 1, T - 1), fill=(46, 72, 42))
    ruido(d, (52, 82, 46), 90, 16, (25, 0, T, T))
    for y in range(2, T, 6): d.point((25, y), fill=(70, 104, 58))  # hierba sobre la orilla
    d.line((0, 15, 19, 15), fill=(100, 98, 92))
    return im

def asfalto_aceite():
    random.seed(4); im = Image.new("RGB", (T, T), (56, 58, 60)); d = ImageDraw.Draw(im)
    ruido(d, (56, 58, 60), 320, 10)
    d.rectangle((0, 0, 2, T - 1), fill=(206, 200, 172))  # línea de cajón
    return im

def con_tierra(base):
    random.seed(9); im = base.copy(); d = ImageDraw.Draw(im)
    for _ in range(4):
        x, y = random.randrange(T), random.randrange(T)
        for k in range(14):
            d.point(((x + random.randint(-3, 3)) % T, (y + k) % T), fill=(18, 14, 12))
            d.point(((x + random.randint(-2, 2)) % T, (y + k) % T), fill=(28, 20, 16))
    return im

pisos = [("Losas de concreto", losas()), ("Adoquín rojo", adoquin()),
         ("Concreto con guarnición y pasto", orilla_pasto()), ("Asfalto", asfalto_aceite()),
         ("Losas con tierra negra", con_tierra(losas())), ("Adoquín con tierra negra", con_tierra(adoquin()))]
ESC, REP = 3, 4
f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
cw, ch = T * REP * ESC + 30, T * REP * ESC + 34
lienzo = Image.new("RGB", (cw * 3, ch * 2), (30, 32, 34)); ld = ImageDraw.Draw(lienzo)
for i, (nombre, t) in enumerate(pisos):
    t.save(f"{OUT}/piso_{i+1}.png")
    bloque = Image.new("RGB", (T * REP, T * REP))
    for x in range(REP):
        for y in range(REP): bloque.paste(t, (x * T, y * T))
    bloque = bloque.resize((bloque.width * ESC, bloque.height * ESC), Image.NEAREST)
    cx, cy = (i % 3) * cw + 15, (i // 3) * ch + 6
    lienzo.paste(bloque, (cx, cy)); ld.text((cx, cy + bloque.height + 4), nombre, fill=(230, 225, 205), font=f)
lienzo.save(f"{OUT}/pisos_opciones.png"); print("pisos ok")
