"""Recorta a Lalo con la linterna (hoja caminar_linterna_v10 de magicart99) y genera la puerta de la caseta.
Uso: python3 tools/arte/linterna_y_puerta.py <carpeta_magicart99_assets>"""
import os, sys
from PIL import Image, ImageDraw
MAG = sys.argv[1]
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
def dst(*p):
    path = os.path.join(R, "assets", "sprites", *p); os.makedirs(os.path.dirname(path), exist_ok=True); return path

hoja = Image.open(f"{MAG}/sprites/lalo/caminar_linterna_v10.png").convert("RGBA")
W, H = hoja.size; cw, ch = W / 4, H / 4
filas = ["down", "right", "up", "left"]
celdas = {f"{filas[r]}_{c + 1}": hoja.crop((round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))) for r in range(4) for c in range(4)}
# Mismo recuadro para los 16 cuadros (relativo a cada celda) para que no "brinque" al animar
bs = [im.getbbox() for im in celdas.values()]
bb = (min(b[0] for b in bs), min(b[1] for b in bs), max(b[2] for b in bs), max(b[3] for b in bs))
alto_figura = max(b[3] - b[1] for b in bs)
esc = 60 / alto_figura
for k, im in celdas.items():
    c = im.crop(bb); c.resize((round(c.width * esc), round(c.height * esc)), Image.LANCZOS).save(dst("personajes", "lalo", "linterna", f"{k}.png"))
print("linterna", bb, round(esc, 3), Image.open(dst("personajes", "lalo", "linterna", "down_1.png")).size)

# Puerta de la caseta (10x7 pixeles de arte, x4): cerrada y abierta
def puerta(abierta):
    im = Image.new("RGBA", (10, 7)); d = ImageDraw.Draw(im)
    if abierta:
        d.rectangle((0, 0, 9, 6), fill=(24, 20, 18, 255))                      # hueco oscuro hacia afuera
        d.rectangle((0, 0, 1, 6), fill=(160, 104, 62, 255)); d.line((1, 0, 1, 6), fill=(110, 70, 40, 255))  # hoja abierta pegada al marco
    else:
        d.rectangle((0, 0, 9, 6), fill=(130, 84, 50, 255)); d.rectangle((1, 1, 8, 6), fill=(160, 104, 62, 255))
        d.line((1, 3, 8, 3), fill=(130, 84, 50, 255)); d.point((7, 4), fill=(230, 200, 90, 255))               # tablero y manija
    return im.resize((40, 28), Image.NEAREST)
puerta(False).save(dst("escenario", "caseta", "puerta_cerrada.png"))
puerta(True).save(dst("escenario", "caseta", "puerta_abierta.png"))
print("puerta ok")
