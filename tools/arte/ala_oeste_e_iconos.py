"""Pasillo del ala oeste de Medicina (un tramo del pasillo principal girado) e íconos de la mochila.
Uso: python3 -I tools/arte/ala_oeste_e_iconos.py <carpeta_magicart99_assets>"""
import json, os, sys
from PIL import Image, ImageDraw
MAG = sys.argv[1]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DST = os.path.join(R, "assets", "sprites", "interiores", "medicina")
p = Image.open(f"{DST}/pasillo.png"); W, H = p.size
tramo = p.crop((round(W * .29), 0, round(W * .71), H)).rotate(90, expand=True)   # el muro de arriba queda a la izquierda
tramo.save(f"{DST}/pasillo_oeste.png")
ruta = os.path.join(R, "data", "medicina_cuartos.json"); datos = json.load(open(ruta))
datos["pasillo_oeste"] = {"tam": list(tramo.size), "puertas_y": [.167, .5, .833], "piso_x": [.27, .78]}
json.dump(datos, open(ruta, "w"), indent="\t")
# Íconos de 32x32 para la mochila
ICO = os.path.join(R, "assets", "sprites", "objetos", "iconos"); os.makedirs(ICO, exist_ok=True)
N = (16, 14, 14, 255)
def nuevo(): return Image.new("RGBA", (32, 32)), None
v = Image.new("RGBA", (32, 32)); d = ImageDraw.Draw(v)                        # vendas: rollo blanco
d.ellipse((5, 9, 23, 27), fill=(236, 232, 220, 255), outline=N); d.ellipse((10, 14, 18, 22), fill=(200, 196, 186, 255), outline=N)
d.rectangle((17, 9, 28, 15), fill=(236, 232, 220, 255), outline=N); d.line((21, 10, 21, 14), fill=(200, 40, 40, 255))
v.save(f"{ICO}/vendas.png")
c = Image.new("RGBA", (32, 32)); d = ImageDraw.Draw(c)                        # cizalla
d.line((6, 26, 18, 12), fill=(200, 40, 40, 255), width=4); d.line((26, 26, 14, 12), fill=(200, 40, 40, 255), width=4)
d.polygon([(14, 12), (18, 12), (20, 3), (16, 2)], fill=(180, 184, 192, 255), outline=N); d.polygon([(14, 12), (18, 12), (12, 3), (16, 2)], fill=(150, 154, 162, 255), outline=N)
d.ellipse((14, 10, 18, 14), fill=(90, 90, 96, 255))
c.save(f"{ICO}/cizalla.png")
for nombre, origen in (("llave", "llave.png"), ("documento", "expediente.png")):
    im = Image.open(f"{MAG}/sprites/{origen}").convert("RGBA"); im = im.crop(im.getbbox()); im.thumbnail((30, 30), Image.LANCZOS)
    o = Image.new("RGBA", (32, 32)); o.alpha_composite(im, ((32 - im.width) // 2, (32 - im.height) // 2)); o.save(f"{ICO}/{nombre}.png")
# Brillo de objeto en el piso (se ve aunque esté oscuro)
b = Image.new("RGBA", (9, 9)); d = ImageDraw.Draw(b)
d.polygon([(4, 0), (5, 3), (8, 4), (5, 5), (4, 8), (3, 5), (0, 4), (3, 3)], fill=(255, 246, 200, 255)); b.save(f"{ICO}/brillo.png")
print("ok", tramo.size)
