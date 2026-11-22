"""Sonidos del teaser: tic y toc del reloj de pared y zumbido de lámpara fluorescente.
Uso: python3 tools/teaser/sonidos_teaser.py"""
import numpy as np, wave

FS = 44100
def guardar(nombre, x):
    x = np.clip(x, -1, 1)
    with wave.open(f"assets/audio/teaser/{nombre}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes((x * 32767).astype(np.int16).tobytes())

def golpe(freq, dur=0.09, brillo=0.6):
    t = np.arange(int(FS * dur)) / FS
    env = np.exp(-t * 70)
    ruido = np.random.default_rng(3).normal(0, 1, t.size) * np.exp(-t * 250) * brillo
    return (np.sin(2 * np.pi * freq * t) * 0.6 + np.sin(2 * np.pi * freq * 2.7 * t) * 0.25 + ruido * 0.3) * env * 0.8

guardar("tic", golpe(2300))
guardar("toc", golpe(1650))
t = np.arange(int(FS * 4.0)) / FS
zumbido = (np.sin(2 * np.pi * 120 * t) * 0.5 + np.sin(2 * np.pi * 240 * t) * 0.25 + np.sin(2 * np.pi * 360 * t) * 0.1)
zumbido *= 0.18 * (1 + 0.08 * np.sin(2 * np.pi * 0.7 * t))
zumbido += np.random.default_rng(5).normal(0, 0.012, t.size)
borde = np.minimum(1, np.minimum(t, 4.0 - t) / 0.05)   # sin clic al repetir
guardar("zumbido", zumbido * borde)
print("listo")
