"""Interiores de Medicina (arte del equipo): recorta cada cuarto, lo escala al juego y calcula
paredes y puerta. También la puerta de la transición, las espaldas del maniquí y el rechinido.
Uso: python3 -I tools/arte/medicina_interiores.py <zip_corregidos> <imagen_maniqui_28>"""
import json, os, sys, wave
import numpy as np
from PIL import Image, ImageOps
CORR, MANIQUI = sys.argv[1], sys.argv[2]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(R, "assets", "sprites", "interiores", "medicina"); os.makedirs(DST, exist_ok=True)
ESC = 0.5
# id: (archivo, lado de la puerta "b" abajo / "t" arriba, posición horizontal de la puerta 0..1)
CUARTOS = {
    "salon_101": ("01_Salon_101_CORREGIDO", "b", .5), "salon_102": ("02_Salon_102_CORREGIDO", "b", .5),
    "consultorio": ("03_Consultorio_CORREGIDO", "b", .5), "caseta": ("04_Caseta_punto_seguro_CORREGIDA", "b", .5),
    "laboratorio": ("05_Laboratorio_ex_Salon_103_CORREGIDO", "b", .5), "salon_104": ("06_Salon_104_CORREGIDO", "b", .5),
    "banos_h": ("07_Banos_H_CORREGIDO", "b", .48), "banos_m": ("08_Banos_M_CORREGIDO", "b", .5),
    "enfermeria": ("09_Enfermeria_CORREGIDA", "t", .5), "simulacion": ("10_Sala_de_simulacion_CORREGIDA", "t", .5),
    "escaleras": ("11_Escaleras_CORREGIDA", "t", .5), "recepcion": ("12_Recepcion_CORREGIDA", "t", .47),
    "salon_105": ("13_Salon_105_CORREGIDO", "t", .5), "archivo": ("14_Archivo_CORREGIDO", "t", .75),
    "bodega": ("15_Bodega_limpieza_CORREGIDA", "t", .5), "maquinas": ("16_Cuarto_maquinas_CORREGIDO", "t", .5),
    "entrada": ("17_Entrada_CORREGIDA", "b", .5),
}
def recortar(im):
    g = np.array(im.convert("L")) > 28
    ys, xs = np.where(g); return im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
datos = {}
for cid, (archivo, lado, fx) in CUARTOS.items():
    im = recortar(Image.open(f"{CORR}/{archivo}.webp").convert("RGB"))
    im = im.resize((round(im.width * ESC), round(im.height * ESC)), Image.LANCZOS)
    im.save(f"{DST}/{cid}.png")
    w, h = im.size; muro = round(min(w, h) * 0.075)
    datos[cid] = {"tam": [w, h], "muro": muro, "puerta": lado, "puerta_x": round(w * fx)}
# Pasillo largo: 7 puertas arriba y 7 abajo
p = recortar(Image.open(f"{CORR}/18_Pasillo_Principal_LARGO_CORREGIDO.webp").convert("RGB"))
p = p.resize((round(p.width * 0.75), round(p.height * 0.75)), Image.LANCZOS); p.save(f"{DST}/pasillo.png")   # el pasillo va más grande que los cuartos
datos["pasillo"] = {"tam": list(p.size), "puertas_x": [.084, .222, .36, .5, .64, .778, .916], "piso": [.27, .78]}
with open(os.path.join(R, "data", "medicina_cuartos.json"), "w") as f: json.dump(datos, f, indent="\t")
# Puerta de la transición: 4 cuadros
hoja = Image.open(f"{CORR}/19_Puerta_transicion_4_cuadros_TRANSPARENTE.png").convert("RGBA")
cw = hoja.width // 4; cuadros = [hoja.crop((i * cw, 0, (i + 1) * cw, hoja.height)) for i in range(4)]
bb = [c.getbbox() for c in cuadros]; caja = (min(b[0] for b in bb), min(b[1] for b in bb), max(b[2] for b in bb), max(b[3] for b in bb))
os.makedirs(os.path.join(R, "assets", "sprites", "ui"), exist_ok=True)
for i, c in enumerate(cuadros, 1):
    c = c.crop(caja); c.resize((round(c.width * 220 / c.height), 220), Image.LANCZOS).save(os.path.join(R, "assets", "sprites", "ui", f"puerta_{i}.png"))
# Maniquí de espaldas (hoja nueva, 4 columnas x 3 filas)
m = Image.open(MANIQUI).convert("RGBA"); px = m.load()
for y in range(m.height):
    for x in range(m.width):
        r, g, b, a = px[x, y]
        if r > 232 and g > 232 and b > 232: px[x, y] = (0, 0, 0, 0)
        elif r > 160 and b > 140 and g < 90: px[x, y] = (0, 0, 0, 0)
cw, ch = m.width // 4, m.height // 3
celda = lambda f, c: m.crop((c * cw, f * ch, (c + 1) * cw, (f + 1) * ch)).crop(m.crop((c * cw, f * ch, (c + 1) * cw, (f + 1) * ch)).getbbox())
espaldas = [celda(1, 1), celda(1, 2), celda(1, 3), ImageOps.mirror(celda(1, 2))]
MD = os.path.join(R, "assets", "sprites", "enemigos", "maniqui")
ref = Image.open(f"{MD}/down_1.png"); W, H = ref.size
for i, e in enumerate(espaldas, 1):
    e = e.resize((max(1, round(e.width * 66 / e.height)), 66), Image.LANCZOS)
    c = Image.new("RGBA", (max(W, e.width), H)); c.alpha_composite(e, ((c.width - e.width) // 2, H - e.height)); c.save(f"{MD}/up_{i}.png")
# Rechinido de puerta: fricción que se pega y se suelta, con tono que sube
SR = 22050; rng = np.random.default_rng(9); n = int(SR * 1.6); t = np.arange(n) / SR
f0 = 170 + 110 * t / t[-1] + 20 * np.sin(2 * np.pi * 1.3 * t)
fase = 2 * np.pi * np.cumsum(f0) / SR
saw = sum(np.sin(k * fase) / k for k in range(1, 18))
pulsos = (np.sin(2 * np.pi * (11 + 6 * rng.random()) * t) > 0.2).astype(float)
pulsos = np.convolve(pulsos, np.ones(200) / 200, "same")
a = saw * (0.35 + 0.65 * pulsos) * np.minimum(1, t / 0.08) * np.minimum(1, (t[-1] - t) / 0.25)
a = a / np.abs(a).max() * 0.7
with wave.open(os.path.join(R, "assets", "audio", "efectos", "puerta_rechina.wav"), "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((a * 32767).astype(np.int16).tobytes())
print("ok", {k: v["tam"] for k, v in datos.items()})
