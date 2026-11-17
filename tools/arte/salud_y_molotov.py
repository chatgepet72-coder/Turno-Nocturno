"""Sangre para la pantalla (estilo Silent Hill), íconos de alcohol/molotov/medicina, sonidos de fuego y vidrio.
Cada pixel de la sangre guarda en su alfa en qué nivel de daño aparece: las orillas primero.
Uso: python3 -I tools/arte/salud_y_molotov.py"""
import math, os, random, wave
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
random.seed(13)
W, H = 640, 360
nivel = Image.new("L", (W, H), 0); d = ImageDraw.Draw(nivel)
for _ in range(240):
    lado = random.choice("tblr")
    x = random.randint(0, W) if lado in "tb" else (random.randint(0, 90) if lado == "l" else random.randint(W - 90, W))
    y = random.randint(0, H) if lado in "lr" else (random.randint(0, 70) if lado == "t" else random.randint(H - 70, H))
    hacia_centro = math.hypot((x - W / 2) / (W / 2), (y - H / 2) / (H / 2))
    v = int(255 * min(1, max(0.05, hacia_centro - 0.25 + random.uniform(-0.15, 0.15))))   # orillas = valor alto = aparece primero
    r = random.randint(3, 22)
    d.ellipse((x - r, y - r, x + r, y + r), fill=v)
    for _ in range(random.randint(0, 6)):   # gotitas alrededor
        a = random.uniform(0, 6.3); dist = r + random.randint(2, 18); rr = random.randint(1, 4)
        d.ellipse((x + math.cos(a) * dist - rr, y + math.sin(a) * dist - rr, x + math.cos(a) * dist + rr, y + math.sin(a) * dist + rr), fill=v)
    if lado == "t" and random.random() < 0.5:   # escurrimientos desde arriba
        d.rectangle((x - 2, y, x + 2, y + random.randint(10, 60)), fill=v)
nivel = nivel.filter(ImageFilter.GaussianBlur(1.2))
color = Image.new("RGB", (W, H), (96, 6, 8))
ruido = Image.effect_noise((W, H), 30).convert("L")
color = Image.merge("RGB", [ruido.point(lambda v: 60 + v // 3), ruido.point(lambda v: v // 20), ruido.point(lambda v: v // 18)])
sangre = color.copy(); sangre.putalpha(nivel)
os.makedirs(f"{R}/assets/sprites/ui", exist_ok=True); sangre.save(f"{R}/assets/sprites/ui/sangre_pantalla.png")
# Íconos
ICO = f"{R}/assets/sprites/objetos/iconos"; N = (16, 14, 14, 255)
a = Image.new("RGBA", (32, 32)); g = ImageDraw.Draw(a)                         # alcohol: botella blanca con cruz
g.rectangle((10, 8, 22, 29), fill=(232, 236, 240, 255), outline=N); g.rectangle((13, 3, 19, 8), fill=(60, 110, 200, 255), outline=N)
g.rectangle((12, 14, 20, 22), fill=(200, 40, 40, 255)); g.line((16, 15, 16, 21), fill=(255, 255, 255, 255)); g.line((13, 18, 19, 18), fill=(255, 255, 255, 255))
a.save(f"{ICO}/alcohol.png")
m = Image.new("RGBA", (32, 32)); g = ImageDraw.Draw(m)                         # molotov: botella con trapo
g.rectangle((10, 12, 22, 29), fill=(90, 150, 70, 255), outline=N); g.rectangle((13, 6, 19, 12), fill=(90, 150, 70, 255), outline=N)
g.polygon([(14, 6), (18, 6), (21, 1), (12, 2)], fill=(236, 230, 210, 255), outline=N); g.point((17, 1), fill=(255, 140, 30, 255)); g.point((18, 2), fill=(255, 200, 60, 255))
m.save(f"{ICO}/molotov.png")
c = Image.new("RGBA", (32, 32)); g = ImageDraw.Draw(c)                         # medicina: frasco ámbar con etiqueta
g.rounded_rectangle((9, 9, 23, 29), 3, fill=(170, 90, 30, 255), outline=N); g.rectangle((11, 4, 21, 9), fill=(240, 240, 240, 255), outline=N)
g.rectangle((10, 15, 22, 23), fill=(236, 232, 220, 255)); g.rectangle((14, 17, 18, 21), fill=(40, 160, 70, 255))
c.save(f"{ICO}/medicina.png")
# Sonidos: fuego (crepitar) y vidrio roto
SR = 22050; rng = np.random.default_rng(3)
def guardar(n, x):
    x = x / (np.abs(x).max() + 1e-9) * 0.8
    with wave.open(f"{R}/assets/audio/efectos/{n}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
t = np.arange(int(SR * 3.0)) / SR
fuego = rng.uniform(-1, 1, len(t)) * 0.25
fuego = np.convolve(fuego, np.ones(30) / 30, "same") * 3            # rumor grave
for _ in range(140):                                                  # chasquidos
    i = rng.integers(0, len(t) - 400); fuego[i:i + 300] += rng.uniform(-1, 1, 300) * np.exp(-np.arange(300) / 40) * rng.uniform(0.3, 1)
guardar("fuego", fuego * np.minimum(1, t / 0.1) * np.minimum(1, (t[-1] - t) / 0.5))
t = np.arange(int(SR * 0.7)) / SR
vidrio = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * rng.uniform(8, 20)) for f in rng.uniform(2500, 7000, 12)) * 0.3 + rng.uniform(-1, 1, len(t)) * np.exp(-t * 25)
guardar("vidrio_roto", vidrio)
print("ok")
