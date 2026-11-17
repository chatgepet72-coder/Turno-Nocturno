"""Caja de herramientas, pistola de clavos, maniquí y sonidos del combate, al tamaño del juego.
Uso: python3 tools/arte/pistola_y_maniqui.py <carpeta_pendientes>"""
import os, shutil, sys, wave
from collections import deque
import numpy as np
from PIL import Image, ImageDraw
PEN = sys.argv[1]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SP = os.path.join(R, "assets", "sprites")
def sin_fondo(im, tol=30):
    im = im.convert("RGBA"); w, h = im.size; px = im.load(); vis = bytearray(w * h)
    q = deque([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
    while q:
        x, y = q.popleft()
        if not (0 <= x < w and 0 <= y < h) or vis[y * w + x]: continue
        vis[y * w + x] = 1; r, g, b, a = px[x, y]
        if r > 255 - tol and g > 255 - tol and b > 255 - tol: px[x, y] = (0, 0, 0, 0); q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return im.crop(im.getbbox())
def ancho(im, w): return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
os.makedirs(f"{SP}/objetos", exist_ok=True)
cerrada = sin_fondo(Image.open(f"{PEN}/caja/26.webp")); abierta = sin_fondo(Image.open(f"{PEN}/caja/27.webp"))
ancho(cerrada, 64).save(f"{SP}/objetos/caja_cerrada.png")
ab = ancho(abierta, 64); ab.save(f"{SP}/objetos/caja_abierta.png")
# Después de tomar la pistola, Lalo cierra la caja: se vuelve a usar caja_cerrada.png
ancho(sin_fondo(Image.open(f"{PEN}/caja/23.webp")), 56).save(f"{SP}/ui/pistola_clavos.png")
# Clavo (proyectil)
c = Image.new("RGBA", (10, 3)); d = ImageDraw.Draw(c)
d.rectangle((0, 1, 8, 1), fill=(190, 190, 196, 255)); d.rectangle((0, 0, 1, 2), fill=(150, 150, 156, 255)); d.point((9, 1), fill=(230, 230, 236, 255))
c.save(f"{SP}/objetos/clavo.png")
# Maniquí: cuadros caminando y poses sueltas
dst = f"{SP}/enemigos/maniqui"; os.makedirs(dst, exist_ok=True)
for f in os.listdir(f"{PEN}/maniqui/juego"): shutil.copy(f"{PEN}/maniqui/juego/{f}", f"{dst}/{f}")
# Sonidos
SR = 22050; rng = np.random.default_rng(5)
def guardar(n, a):
    a = np.clip(a / (np.abs(a).max() + 1e-9) * 0.8, -1, 1)
    with wave.open(f"{R}/assets/audio/efectos/{n}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((a * 32767).astype(np.int16).tobytes())
def t(seg): return np.arange(int(SR * seg)) / SR
x = t(0.35)   # disparo: golpe neumático + siseo de aire
guardar("disparo_clavos", np.sin(2 * np.pi * 70 * x) * np.exp(-x * 25) + rng.uniform(-1, 1, len(x)) * np.exp(-x * 14) * 0.55 + np.sin(2 * np.pi * 1900 * x) * np.exp(-x * 60) * 0.3)
x = t(0.25)   # clavo que se clava en plástico duro
guardar("clavo_impacto", np.sin(2 * np.pi * 320 * x) * np.exp(-x * 40) + rng.uniform(-1, 1, len(x)) * np.exp(-x * 70) * 0.6)
x = t(0.3)    # recarga: dos clics metálicos
r = np.zeros(len(x)); 
for ini in (0.0, 0.14):
    i = int(SR * ini); seg = x[: len(x) - i] ; r[i:] += np.sin(2 * np.pi * 2600 * seg) * np.exp(-seg * 120) + rng.uniform(-1, 1, len(seg)) * np.exp(-seg * 200) * 0.5
guardar("recarga", r)
x = t(0.2)    # sin clavos
guardar("sin_clavos", np.sin(2 * np.pi * 1200 * x) * np.exp(-x * 90))
x = t(0.4)    # golpe del maniquí
guardar("golpe", np.sin(2 * np.pi * 90 * x) * np.exp(-x * 18) + rng.uniform(-1, 1, len(x)) * np.exp(-x * 35) * 0.7)
x = t(0.8)    # maniquí cayendo al piso
guardar("maniqui_cae", np.sin(2 * np.pi * 60 * x) * np.exp(-x * 8) + rng.uniform(-1, 1, len(x)) * np.exp(-x * 10) * 0.5)
print("ok", ab.size, Image.open(f"{SP}/ui/pistola_clavos.png").size)
