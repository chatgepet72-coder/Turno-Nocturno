"""Dibujos PROVISIONALES de El Pupitre (siluetas oscuras) para probar al enemigo mientras llega el arte final.
Uso: python3 tools/arte/pupitre_provisional.py   → assets/sprites/enemigos/el_pupitre/
Cuadros de 320×320, pivote abajo al centro (160, 310), igual que los demás enemigos."""
import json, math, os
from PIL import Image, ImageDraw

RAIZ = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "enemigos", "el_pupitre")
os.makedirs(os.path.join(RAIZ, "frames"), exist_ok=True)
PIEL = (52, 44, 40, 255)
PANTALON = (28, 30, 38, 255)
ZAPATO = (12, 12, 14, 255)
MADERA = (78, 52, 32, 255)
METAL = (70, 72, 78, 255)


def pierna(d, cadera, angulo_muslo, angulo_pierna, largo=62, grosor=15):
    """Muslo + pantorrilla + zapato. Ángulos en grados (0 = hacia abajo)."""
    a1 = math.radians(angulo_muslo)
    rodilla = (cadera[0] + math.sin(a1) * largo, cadera[1] + math.cos(a1) * largo)
    a2 = math.radians(angulo_pierna)
    tobillo = (rodilla[0] + math.sin(a2) * largo, rodilla[1] + math.cos(a2) * largo)
    d.line([cadera, rodilla], fill=PANTALON, width=grosor)
    d.line([rodilla, tobillo], fill=PANTALON, width=grosor - 2)
    d.ellipse([rodilla[0] - 8, rodilla[1] - 8, rodilla[0] + 8, rodilla[1] + 8], fill=PANTALON)
    pie = (tobillo[0] + math.sin(a2 + 1.4) * 18, tobillo[1] + math.cos(a2 + 1.4) * 18)
    d.line([tobillo, pie], fill=ZAPATO, width=12)
    return tobillo


def cuadro(fase=0.0, golpe=0.0, herido=0.0, espejo=False):
    im = Image.new("RGBA", (320, 320), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cadera = (160, 160 + herido * 40)
    # Par de abajo: camina (dos piernas que se alternan)
    s = math.sin(fase * 2 * math.pi)
    pierna(d, (cadera[0] - 10, cadera[1]), 22 * s, 8 * s - 10)
    pierna(d, (cadera[0] + 10, cadera[1]), -22 * s, -8 * s - 10)
    # Asiento de la silla de paleta (el "torso")
    d.polygon([(100, cadera[1] - 8), (220, cadera[1] - 14), (226, cadera[1] + 4), (96, cadera[1] + 10)], fill=MADERA)
    d.line([(104, cadera[1] + 10), (220, cadera[1] + 4)], fill=METAL, width=5)
    d.polygon([(200, cadera[1] - 40), (262, cadera[1] - 44), (264, cadera[1] - 34), (204, cadera[1] - 30)], fill=MADERA)  # paleta
    d.line([(214, cadera[1] - 30), (214, cadera[1] - 8)], fill=METAL, width=5)
    # Par de arriba: piernas dobladas hacia arriba (el respaldo); pegan hacia adelante al atacar
    pierna(d, (cadera[0] - 8, cadera[1] - 6), 180 - 30 + golpe * 70, 180 + 20 + golpe * 90, 58, 13)
    pierna(d, (cadera[0] + 6, cadera[1] - 6), 180 - 10 + golpe * 60, 180 + 35 + golpe * 80, 58, 13)
    if espejo:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    return im


anims = {
    "idle": {"cuadros": 2, "fps": 3, "loop": True, "f": lambda k: dict(fase=0.08 * k)},
    "walk": {"cuadros": 6, "fps": 14, "loop": True, "f": lambda k: dict(fase=k / 6)},
    "run": {"cuadros": 6, "fps": 20, "loop": True, "f": lambda k: dict(fase=k / 6)},
    "attack": {"cuadros": 5, "fps": 12, "loop": False, "cuadro_de_golpe": 3, "f": lambda k: dict(golpe=[0.0, -0.3, 1.0, 0.8, 0.2][k])},
    "hurt": {"cuadros": 3, "fps": 10, "loop": False, "f": lambda k: dict(herido=k / 2)},
}
datos = {"personaje": "el_pupitre", "provisional": True, "tamano_cuadro": [320, 320], "fondo": "transparente",
         "pivote": [160, 310], "direcciones": ["down", "left", "right", "up"], "animaciones": {}}
for nombre, a in anims.items():
    archivos = {}
    for direccion in ["down", "left", "right", "up"]:
        lista = []
        for k in range(a["cuadros"]):
            ruta = "frames/%s_%s_%02d.png" % (nombre, direccion, k + 1)
            cuadro(espejo=direccion == "left", **a["f"](k)).save(os.path.join(RAIZ, ruta))
            lista.append(ruta)
        archivos[direccion] = lista
    entrada = {"cuadros": a["cuadros"], "fps": a["fps"], "loop": a["loop"], "archivos": archivos}
    if "cuadro_de_golpe" in a:
        entrada["cuadro_de_golpe"] = a["cuadro_de_golpe"]
    datos["animaciones"][nombre] = entrada
with open(os.path.join(RAIZ, "animaciones.json"), "w", encoding="utf-8") as f:
    json.dump(datos, f, ensure_ascii=False, indent=2)
with open(os.path.join(RAIZ, "LEEME.md"), "w", encoding="utf-8") as f:
    f.write("# El Pupitre (PROVISIONAL)\n\nSiluetas hechas con `tools/arte/pupitre_provisional.py` solo para probar. "
            "Cuando llegue el arte del equipo, reemplazar `frames/` y `animaciones.json` con el mismo formato que La Baja.\n")
print("listo")
