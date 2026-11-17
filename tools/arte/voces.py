"""Voces de murmullo: sílabas sintetizadas que siguen las vocales del texto, con tono y ritmo propios.
Versión en persona y versión por radio (banda estrecha, saturación, estática y chasquidos)."""
import math, random, sys, wave
import numpy as np
SR = 22050
OUT = sys.argv[1]
FORMANTES = {"a": (800, 1250), "e": (480, 1900), "i": (300, 2300), "o": (500, 900), "u": (330, 800)}
ACENTOS = str.maketrans("áéíóúü", "aeiouu")

def biquad_bp(x, f, q):
    w = 2 * math.pi * f / SR; al = math.sin(w) / (2 * q); c = math.cos(w)
    b0, b1, b2, a0, a1, a2 = al, 0, -al, 1 + al, -2 * c, 1 - al
    return _filtro(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
def biquad(x, f, tipo, q=0.707):
    w = 2 * math.pi * f / SR; al = math.sin(w) / (2 * q); c = math.cos(w)
    if tipo == "lp": b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    else: b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
    a0, a1, a2 = 1 + al, -2 * c, 1 - al
    return _filtro(x, b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0)
def _filtro(x, b0, b1, b2, a1, a2):
    y = np.zeros_like(x); x1 = x2 = y1 = y2 = 0.0
    for n in range(len(x)):
        v = b0 * x[n] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x[n], y1, v; y[n] = v
    return y

def silaba(vocal, f0, dur, aire, grave):
    n = int(SR * dur); t = np.arange(n) / SR
    fase = 2 * np.pi * np.cumsum(np.full(n, f0) * (1 + 0.02 * np.sin(2 * np.pi * 5 * t))) / SR
    fuente = sum(np.sin(k * fase) / k for k in range(1, int(3800 / f0)))       # diente de sierra suave
    fuente = fuente + aire * np.random.uniform(-1, 1, n) * 2
    f1, f2 = FORMANTES[vocal]
    s = biquad_bp(fuente, f1 * grave, 4) * 1.0 + biquad_bp(fuente, f2 * grave, 6) * 0.6
    env = np.minimum(1, t / 0.008) * np.minimum(1, (dur - t) / 0.025)
    return s * np.clip(env, 0, 1)

def hablar(texto, f0, dur, jitter, aire, grave=1.0, pausa=0.035):
    random.seed(len(texto)); partes = []
    letras = texto.lower().translate(ACENTOS)
    vocales = [c for c in letras if c in FORMANTES]; total = max(1, len(vocales)); k = 0
    pregunta = "?" in texto
    for c in letras:
        if c in FORMANTES:
            avance = k / total
            curva = 1 + (0.12 * avance if pregunta and avance > 0.7 else -0.08 * avance)   # entonación
            tono = f0 * curva * (1 + random.uniform(-jitter, jitter))
            partes.append(silaba(c, tono, dur * random.uniform(0.85, 1.15), aire, grave))
            partes.append(np.zeros(int(SR * pausa))); k += 1
        elif c in ",;": partes.append(np.zeros(int(SR * 0.16)))
        elif c in ".…!?": partes.append(np.zeros(int(SR * 0.3)))
        elif c == " ": partes.append(np.zeros(int(SR * 0.025)))
    a = np.concatenate(partes); return a / (np.abs(a).max() + 1e-9) * 0.8

def radio(a):
    a = biquad(biquad(a, 450, "hp"), 2600, "lp")
    a = np.tanh(a * 3.5) * 0.6
    a = a + np.random.uniform(-1, 1, len(a)) * 0.035                              # estática
    for _ in range(len(a) // 4000): i = random.randrange(len(a)); a[i:i + 30] += np.random.uniform(-0.5, 0.5, len(a[i:i + 30]))  # chasquidos
    clic = biquad(np.random.uniform(-1, 1, int(SR * 0.05)), 1800, "hp") * 0.5      # al presionar el botón
    cierre = biquad(np.random.uniform(-1, 1, int(SR * 0.16)), 1200, "hp") * np.linspace(0.6, 0, int(SR * 0.16))  # "kshh" al soltar
    return np.concatenate([clic, np.zeros(int(SR * 0.08)), a, np.zeros(int(SR * 0.06)), cierre])

def guardar(nombre, a):
    a = np.clip(a, -1, 1); d = (a * 32767).astype(np.int16)
    with wave.open(f"{OUT}/{nombre}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())

CHAVA = "Oye, mijo... ¿tú sabes qué hay abajo del Central? Nomás me asomo, no me tardo."
LALO = "Ni idea, Don Chava. Dijeron que nadie se meta. ¡No sea necio!"
voces = {
    "lalo_A_joven": (LALO, dict(f0=150, dur=0.062, jitter=0.07, aire=0.05)),
    "lalo_B_nervioso": (LALO, dict(f0=178, dur=0.052, jitter=0.12, aire=0.04, pausa=0.025)),
    "don_chava_A_ronco": (CHAVA, dict(f0=96, dur=0.092, jitter=0.05, aire=0.2, grave=0.92, pausa=0.05)),
    "don_chava_B_calido": (CHAVA, dict(f0=112, dur=0.085, jitter=0.06, aire=0.07, grave=0.96, pausa=0.045)),
}
for nombre, (texto, p) in voces.items():
    np.random.seed(1); normal = hablar(texto, **p)
    guardar(nombre, np.concatenate([normal, np.zeros(int(SR * 0.8)), radio(normal)]))
    print(nombre)
