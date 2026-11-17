"""Sonidos para sustos: golpes detrás de una puerta (toc, toc, toc) y gatear por un ducto.
Uso: python3 -I tools/arte/sonidos_sustos.py"""
import os, wave
import numpy as np
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SR = 22050; rng = np.random.default_rng(21)
def guardar(n, x):
    x = x / (np.abs(x).max() + 1e-9) * 0.85
    with wave.open(f"{R}/assets/audio/efectos/{n}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype(np.int16).tobytes())
def golpe(dur=0.35):
    t = np.arange(int(SR * dur)) / SR
    madera = np.sin(2 * np.pi * 120 * t) * np.exp(-t * 28) + np.sin(2 * np.pi * 230 * t) * np.exp(-t * 40) * 0.6
    return madera + rng.uniform(-1, 1, len(t)) * np.exp(-t * 90) * 0.5
silencio = lambda s: np.zeros(int(SR * s))
guardar("golpes_puerta", np.concatenate([golpe(), silencio(0.25), golpe(), silencio(0.25), golpe(), silencio(0.4)]))
# Gatear: roces de ropa contra el ducto y golpecitos de rodillas sobre lámina
t = np.arange(int(SR * 2.2)) / SR
roce = np.convolve(rng.uniform(-1, 1, len(t)), np.ones(12) / 12, "same") * (0.4 + 0.6 * (np.sin(2 * np.pi * 1.6 * t) > 0))
for k in np.arange(0.15, 2.1, 0.32):
    i = int(SR * k); n = int(SR * 0.12); tt = np.arange(n) / SR
    roce[i:i + n] += np.sin(2 * np.pi * 380 * tt) * np.exp(-tt * 45) * 1.4
guardar("gatear", roce * np.minimum(1, t / 0.1) * np.minimum(1, (t[-1] - t) / 0.2))
print("ok")
