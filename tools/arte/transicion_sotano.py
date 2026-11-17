"""Recursos del sótano y su transición: cuarto chico, linterna reducida, escalera para la transición,
viñeta oscura y pasos sobre metal. Uso: python3 tools/arte/transicion_sotano.py <carpeta_pendientes>"""
import math, os, sys, wave
import numpy as np
from PIL import Image
PEN = sys.argv[1]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SP = os.path.join(R, "assets", "sprites")
os.makedirs(f"{SP}/ui", exist_ok=True)
# Sótano chico armado con las piezas del equipo (sotano_chico.png de la carpeta de pendientes)
Image.open(f"{PEN}/sotano/sotano_chico.png").save(f"{SP}/escenario/prologo/sotano.png")
# Linterna de Don Chava a la mitad
lt = Image.open(f"{SP}/escenario/prologo/linterna_don_chava.png")
if lt.width > 30: lt.resize((lt.width // 2, lt.height // 2), Image.NEAREST).save(f"{SP}/escenario/prologo/linterna_don_chava.png")
# Escalera para la transición: tres escaleras una sobre otra
e = Image.open(f"{PEN}/sotano/escalera.png"); e = e.resize((120, round(e.height * 120 / e.width)), Image.NEAREST)
larga = Image.new("RGBA", (120, e.height * 3))
for i in range(3): larga.paste(e, (0, i * e.height))
larga.save(f"{SP}/ui/escalera_transicion.png")
# Viñeta: centro transparente y orillas negras
v = Image.new("RGBA", (640, 360)); px = v.load()
for y in range(360):
    for x in range(640):
        r = math.hypot((x - 320) / 1.0, (y - 170) / 0.9)
        px[x, y] = (0, 0, 0, int(255 * min(1, max(0, (r - 70) / 170)) ** 1.2))
v.save(f"{SP}/ui/vineta.png")
# Pasos sobre metal: golpe seco + resonancias metálicas que se apagan
SR = 22050
os.makedirs(f"{R}/assets/audio/efectos", exist_ok=True)
rng = np.random.default_rng(7)
for k, (f1, f2, f3) in enumerate(((880, 1420, 2260), (820, 1350, 2410), (940, 1510, 2180)), 1):
    n = int(SR * 0.45); t = np.arange(n) / SR
    golpe = rng.uniform(-1, 1, n) * np.exp(-t * 90)
    metal = (np.sin(2 * np.pi * f1 * t) * 0.6 + np.sin(2 * np.pi * f2 * t) * 0.35 + np.sin(2 * np.pi * f3 * t) * 0.2) * np.exp(-t * 11)
    sordo = np.sin(2 * np.pi * 110 * t) * np.exp(-t * 30) * 0.8
    a = golpe * 0.5 + metal * 0.45 + sordo; a = a / np.abs(a).max() * 0.8
    with wave.open(f"{R}/assets/audio/efectos/paso_metal_{k}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((a * 32767).astype(np.int16).tobytes())
# La lápida, para la cripta del final
Image.open(f"{PEN}/sotano/lapida.png").save(f"{SP}/escenario/lapida.png")
print("ok", larga.size)
