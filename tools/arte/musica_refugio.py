"""Música del cuarto seguro: pieza original, tranquila, en bucle (acordes suaves y cajita musical con eco).
Uso: python3 tools/arte/musica_refugio.py"""
import numpy as np, wave

FS = 22050
BPM = 60
BEAT = 60 / BPM
ACORDES = [  # 4 compases de 4 tiempos; notas en semitonos desde La 220 Hz
    [3, 7, 10, 14],    # Do maj7
    [0, 3, 7, 10],     # La m7
    [-4, 0, 3, 7],     # Fa maj7
    [-2, 2, 5, 9],     # Sol 6
]
VUELTAS = 3            # 4 compases × 4 tiempos × 3 vueltas = 48 s
largo = int(FS * BEAT * 16 * VUELTAS)
t = np.arange(largo) / FS
musica = np.zeros(largo)

def freq(semi):
    return 220.0 * 2 ** (semi / 12)

for v in range(VUELTAS):
    for i, acorde in enumerate(ACORDES):
        ini = int(FS * BEAT * (v * 16 + i * 4))
        dur = int(FS * BEAT * 4.6)          # se encima un poco con el siguiente
        tt = np.arange(dur) / FS
        env = np.minimum(1, tt / 1.6) * np.minimum(1, (dur / FS - tt) / 1.4)
        pad = sum(np.sin(2 * np.pi * freq(n - 12) * tt) * 0.5 + np.sin(2 * np.pi * freq(n) * tt * 1.002) * 0.25 for n in acorde)
        fin = min(largo, ini + dur)
        musica[ini:fin] += (pad * env * 0.07)[: fin - ini]
        # Cajita musical: arpegio lento, un tono por tiempo y medio
        for k, n in enumerate([acorde[0], acorde[2], acorde[1], acorde[3], acorde[2] + 12]):
            a = ini + int(FS * BEAT * (k * 0.75 + 0.25))
            d = int(FS * 1.8)
            tn = np.arange(d) / FS
            nota = (np.sin(2 * np.pi * freq(n + 12) * tn) + 0.3 * np.sin(2 * np.pi * freq(n + 24) * tn)) * np.exp(-tn * 2.6)
            f2 = min(largo, a + d)
            musica[a:f2] += (nota * 0.09)[: f2 - a]

# Eco suave (dos repeticiones) y bucle sin salto: lo que sale del final se suma al principio
eco = musica.copy()
for retraso, g in [(0.42, 0.35), (0.84, 0.18)]:
    r = int(FS * retraso)
    eco[r:] += musica[:-r] * g
    eco[:r] += musica[-r:] * g
musica = eco / max(1e-6, np.abs(eco).max()) * 0.6
with wave.open("assets/audio/refugio/refugio.wav", "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
    w.writeframes((musica * 32767).astype(np.int16).tobytes())
print("listo", round(largo / FS, 1), "s")
