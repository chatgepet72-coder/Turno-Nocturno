"""Íconos de suministros nuevos (64 × 64, fondo transparente): botella vacía, botiquín y trapo.
Uso: python3 tools/arte/iconos_suministros.py"""
from PIL import Image, ImageDraw

def guardar(nombre, dibujar):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    dibujar(ImageDraw.Draw(im))
    im.save(f"assets/sprites/objetos_nuevos/{nombre}.png")

def botella(d):
    d.rectangle((26, 6, 37, 20), fill=(88, 120, 92, 230), outline=(20, 26, 22, 255))      # cuello
    d.rounded_rectangle((18, 18, 45, 60), 7, fill=(70, 104, 78, 210), outline=(18, 24, 20, 255), width=2)
    d.rectangle((24, 24, 28, 54), fill=(150, 190, 155, 160))                               # brillo
    d.rectangle((25, 3, 38, 7), fill=(60, 60, 60, 255))                                    # rosca

def botiquin(d):
    d.rounded_rectangle((6, 14, 58, 56), 5, fill=(214, 210, 200, 255), outline=(30, 30, 30, 255), width=2)
    d.rectangle((24, 8, 40, 14), fill=(120, 120, 118, 255), outline=(30, 30, 30, 255))     # asa
    d.rectangle((28, 22, 36, 48), fill=(176, 36, 32, 255))
    d.rectangle((19, 31, 45, 39), fill=(176, 36, 32, 255))
    d.line((8, 52, 56, 52), fill=(150, 146, 138, 255), width=2)

def trapo(d):
    d.polygon([(6, 40), (20, 18), (44, 14), (58, 30), (50, 52), (22, 58)], fill=(164, 150, 118, 255), outline=(40, 34, 26, 255))
    for k in range(4):
        d.line((14 + k * 9, 26 + k * 2, 30 + k * 7, 52), fill=(130, 116, 88, 255), width=2)
    d.ellipse((32, 30, 44, 40), fill=(60, 50, 40, 200))                                   # mancha

guardar("botella_vacia", botella)
guardar("botiquin", botiquin)
guardar("trapo", trapo)
print("ok")
