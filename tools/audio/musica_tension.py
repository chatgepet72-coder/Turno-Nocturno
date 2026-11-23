"""Música y sonidos de tensión (piezas originales, hechas con matemáticas: sin muestras de otros juegos).
Uso: python3 tools/audio/musica_tension.py
Genera en assets/audio/tension/:
  suspenso.wav      ambiente pesado en bucle (zumbido grave, cuerdas disonantes, raspones de metal, susurros)
  persecucion.wav   capa de persecución en bucle (tambores graves irregulares, cuerdas cortadas, pulso)
  correteo_1..4.wav carrera de muchas patas por el piso/pared con eco largo (El Pupitre)
  rasguno.wav       algo que raspa la pared
  chillido.wav      chirrido de metal de pupitre arrastrado, cuando ataca
  lanzar.wav        silbido de algo aventado
"""
import os
import wave
import numpy as np

FS = 22050
SALIDA = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "tension")
rng = np.random.default_rng(23)


def guardar(nombre, x, normal=0.9):
    x = np.asarray(x, dtype=np.float64)
    pico = np.max(np.abs(x)) or 1.0
    x = np.clip(x / pico * normal, -1, 1)
    os.makedirs(SALIDA, exist_ok=True)
    with wave.open(os.path.join(SALIDA, nombre), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes((x * 32767).astype("<i2").tobytes())


def filtro(x, bajo=None, alto=None):
    """Pasa banda con FFT (bajo y alto en Hz)."""
    f = np.fft.rfft(x)
    hz = np.fft.rfftfreq(len(x), 1 / FS)
    m = np.ones_like(hz)
    if bajo:
        m *= 1 / (1 + (bajo / np.maximum(hz, 1)) ** 4)
    if alto:
        m *= 1 / (1 + (hz / alto) ** 4)
    return np.fft.irfft(f * m, len(x))


def convolucion(x, h):
    n = len(x) + len(h)
    return np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(h, n), n)


def reverb(x, segundos=2.5, mezcla=0.45, oscuro=3000):
    """Eco de pasillo vacío: ruido que se apaga, más reflexiones tempranas."""
    largo = int(FS * segundos)
    t = np.arange(largo) / FS
    h = rng.standard_normal(largo) * np.exp(-t * 6.9 / segundos)
    h = filtro(h, 80, oscuro)
    for retraso, g in [(0.043, 0.5), (0.071, 0.35), (0.12, 0.28), (0.19, 0.2)]:
        h[int(retraso * FS)] += g * 8
    h /= np.max(np.abs(h))
    mojado = convolucion(x, h)[: len(x) + largo]
    seco = np.concatenate([x, np.zeros(largo)])
    return seco * (1 - mezcla) + mojado / (np.max(np.abs(mojado)) or 1) * np.max(np.abs(x)) * mezcla * 2.2


def bucle(x, cola):
    """La cola que sobra del final se suma al principio: el bucle no salta."""
    base = x[: len(x) - cola].copy()
    base[:cola] += x[len(x) - cola:]
    return base


def sierra(f, t):
    return 2 * ((f * t) % 1.0) - 1


# ---------------- Suspenso ----------------
def suspenso():
    dur = 64.0
    n = int(FS * dur)
    t = np.arange(n) / FS
    x = np.zeros(n)
    # Zumbido grave que respira (Re grave con su quinta disminuida que aparece y desaparece)
    for f, g, vel in [(36.7, 0.5, 0.05), (37.1, 0.4, 0.07), (51.9, 0.22, 0.031), (73.4, 0.12, 0.043)]:
        x += np.sin(2 * np.pi * f * t + np.sin(2 * np.pi * 0.1 * t)) * g * (0.6 + 0.4 * np.sin(2 * np.pi * vel * t))
    # Cuerdas disonantes (racimo de segundas menores), muy lento, filtrado
    cuerdas = np.zeros(n)
    for semi in [0, 1, 6, 7, 13]:
        f = 146.8 * 2 ** (semi / 12)
        cuerdas += sierra(f * (1 + rng.uniform(-0.003, 0.003)), t) + sierra(f * 1.004, t)
    env = (0.5 + 0.5 * np.sin(2 * np.pi * t / 32 - np.pi / 2)) ** 2
    x += filtro(cuerdas, 120, 900) * env * 0.05
    # Raspones de metal lejanos (arco sobre lámina) en momentos sueltos
    for ini in [7.5, 21.0, 38.5, 52.0]:
        d = rng.uniform(2.5, 4.0)
        k = int(d * FS)
        tt = np.arange(k) / FS
        f0 = rng.uniform(380, 700)
        tono = np.sin(2 * np.pi * (f0 * tt + 25 * np.sin(2 * np.pi * 0.7 * tt))) + 0.6 * np.sin(2 * np.pi * f0 * 2.76 * tt)
        tono *= np.sin(np.pi * tt / d) ** 2 * (0.6 + 0.4 * rng.standard_normal(k).cumsum() / np.sqrt(k) * 0.3)
        a = int(ini * FS)
        x[a:a + k] += tono[: n - a] * 0.05
    # Golpes sordos lejanos (como una puerta pesada en otro piso)
    for ini in [14.0, 30.5, 46.0, 59.0]:
        k = int(1.2 * FS)
        tt = np.arange(k) / FS
        golpe = np.sin(2 * np.pi * 48 * tt) * np.exp(-tt * 5) + filtro(rng.standard_normal(k), 40, 300) * np.exp(-tt * 9) * 0.6
        a = int(ini * FS)
        x[a:a + k] += golpe[: n - a] * 0.35
    # Susurros: ruido con formantes que va y viene
    soplo = filtro(rng.standard_normal(n), 1200, 4200)
    soplo *= np.clip(np.sin(2 * np.pi * t / 11.0) * np.sin(2 * np.pi * t / 4.3), 0, 1) ** 3
    x += soplo * 0.035
    y = reverb(x, 3.5, 0.5, 2200)
    guardar("suspenso.wav", bucle(y, int(FS * 3.5)), 0.8)


# ---------------- Persecución ----------------
def persecucion():
    bpm = 132
    pulso = 60 / bpm
    compases = 8
    dur = pulso * 4 * compases
    n = int(FS * dur)
    t = np.arange(n) / FS
    x = np.zeros(n)

    def tambor(a, g=1.0, f=55):
        k = int(0.6 * FS)
        tt = np.arange(k) / FS
        s = np.sin(2 * np.pi * (f * tt + 30 * (1 - np.exp(-tt * 30)) / 30)) * np.exp(-tt * 7)
        s += filtro(rng.standard_normal(k), 60, 900) * np.exp(-tt * 22) * 0.5
        a = int(a * FS)
        fin = min(n, a + k)
        x[a:fin] += s[: fin - a] * g

    # Patrón irregular en 7+9 (se siente que tropieza, como correr)
    patron = [0, 0.75, 1.5, 2.5, 3.0, 3.5]
    for c in range(compases):
        for p in patron:
            tambor((c * 4 + p) * pulso, 0.9 if p == 0 else 0.6, 50 if p in (0, 2.5) else 70)
    # Pulso grave constante en corcheas
    pulso_grave = np.sin(2 * np.pi * 55 * t) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * t / (pulso / 2))))
    x += filtro(pulso_grave, 30, 200) * 0.25
    # Cuerdas cortadas (stabs) que suben medio tono cada dos compases
    for c in range(compases):
        semi = (c // 2)
        for p in [0, 1.5, 3]:
            a = int((c * 4 + p) * pulso * FS)
            k = int(pulso * 0.45 * FS)
            tt = np.arange(k) / FS
            s = sum(sierra(110 * 2 ** ((semi + d) / 12), tt) for d in (0, 1, 6))
            s = filtro(s, 150, 2500) * np.exp(-tt * 9)
            fin = min(n, a + k)
            x[a:fin] += s[: fin - a] * 0.18
    # Chillido agudo que sube a lo largo del bucle
    alto = np.sin(2 * np.pi * (880 * t + 40 * t * t / dur)) * (t / dur) ** 2
    x += filtro(alto, 600, 3000) * 0.04
    y = reverb(x, 1.6, 0.3, 4000)
    guardar("persecucion.wav", bucle(y, int(FS * 1.6)), 0.85)


# ---------------- El Pupitre: patas corriendo con eco ----------------
def golpecito(duro=1.0):
    """Una pata dura (madera, metal y uña) contra azulejo."""
    k = int(0.09 * FS)
    tt = np.arange(k) / FS
    f = rng.uniform(900, 1800)
    s = np.sin(2 * np.pi * f * tt) * np.exp(-tt * 140)
    s += filtro(rng.standard_normal(k), 1500, 7000) * np.exp(-tt * 260) * 0.8
    s += np.sin(2 * np.pi * rng.uniform(180, 260) * tt) * np.exp(-tt * 60) * 0.7 * duro
    return s * rng.uniform(0.6, 1.0)


def correteo(nombre, segundos, rapidez):
    n = int(FS * segundos)
    x = np.zeros(n)
    t = 0.05
    # Cuatro patas: grupos de cuatro golpes muy juntos (galope de insecto), que aceleran y frenan
    while t < segundos - 0.2:
        for pata in range(4):
            a = int((t + pata * rng.uniform(0.018, 0.035)) * FS)
            g = golpecito(1.2 if pata % 2 == 0 else 0.6)
            fin = min(n, a + len(g))
            x[a:fin] += g[: fin - a]
        avance = (t / segundos)
        t += rapidez * (0.75 + 0.5 * np.sin(np.pi * avance)) * rng.uniform(0.85, 1.15)
    # Se acerca y se aleja (volumen)
    env = np.sin(np.pi * np.arange(n) / n) ** 0.6
    y = reverb(x * env, 2.8, 0.55, 3500)
    guardar(nombre, y, 0.95)


def rasguno():
    d = 1.4
    n = int(FS * d)
    tt = np.arange(n) / FS
    s = filtro(rng.standard_normal(n), 2000, 6500) * (0.5 + 0.5 * np.sin(2 * np.pi * 23 * tt)) ** 2
    s *= np.sin(np.pi * tt / d)
    guardar("rasguno.wav", reverb(s, 2.0, 0.5), 0.8)


def chillido():
    d = 1.1
    n = int(FS * d)
    tt = np.arange(n) / FS
    f = 600 + 900 * tt / d + 60 * np.sin(2 * np.pi * 9 * tt)
    s = np.sin(2 * np.pi * np.cumsum(f) / FS) + 0.5 * np.sin(2 * np.pi * np.cumsum(f * 2.71) / FS)
    s += filtro(rng.standard_normal(n), 800, 5000) * 0.4
    s *= np.minimum(1, tt / 0.05) * np.exp(-tt * 1.5)
    guardar("chillido.wav", reverb(s, 2.2, 0.45), 0.9)


def lanzar():
    d = 0.5
    n = int(FS * d)
    tt = np.arange(n) / FS
    s = filtro(rng.standard_normal(n), 400, 2500) * np.sin(np.pi * tt / d) ** 2
    guardar("lanzar.wav", s, 0.7)


if __name__ == "__main__":
    suspenso()
    persecucion()
    for i, (seg, rap) in enumerate([(1.6, 0.17), (2.2, 0.14), (1.2, 0.12), (2.8, 0.2)], start=1):
        correteo("correteo_%d.wav" % i, seg, rap)
    rasguno()
    chillido()
    lanzar()
    print("listo:", sorted(os.listdir(SALIDA)))
