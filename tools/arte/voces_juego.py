"""Genera las sílabas de voz de cada personaje (una por vocal) y los sonidos del radio para el juego.
Uso: python3 tools/arte/voces_juego.py"""
import os, sys, wave
import numpy as np
AQUI = os.path.dirname(os.path.abspath(__file__))
R = os.path.dirname(os.path.dirname(AQUI))
sys.argv = ["voces", "/tmp"]
src = open(os.path.join(AQUI, "voces.py")).read().split("CHAVA = ")[0]
ns = {}; exec(src, ns)
SR, silaba, radio, biquad = ns["SR"], ns["silaba"], ns["radio"], ns["biquad"]
OUT = os.path.join(R, "assets", "audio", "voces"); os.makedirs(OUT, exist_ok=True)
def guardar(nombre, a):
    a = np.clip(a, -1, 1); d = (a * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, f"{nombre}.wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
VOCES = {  # id: parámetros de la muestra aprobada
    "lalo_calmado": dict(f0=150, dur=0.062, aire=0.05),
    "lalo_angustia": dict(f0=178, dur=0.052, aire=0.04),
    "chava": dict(f0=112, dur=0.085, aire=0.07, grave=0.96),
    "chava_debil": dict(f0=96, dur=0.092, aire=0.2, grave=0.92),
}
np.random.seed(3)
for voz, p in VOCES.items():
    for v in "aeiou":
        a = silaba(v, p["f0"], p["dur"], p["aire"], p.get("grave", 1.0))
        guardar(f"{voz}_{v}", a / (np.abs(a).max() + 1e-9) * 0.8)
clic = biquad(np.random.uniform(-1, 1, int(SR * 0.05)), 1800, "hp") * 0.5
cierre = biquad(np.random.uniform(-1, 1, int(SR * 0.16)), 1200, "hp") * np.linspace(0.6, 0, int(SR * 0.16))
guardar("radio_clic", clic); guardar("radio_cierre", cierre)
print("voces ok", len(os.listdir(OUT)))
