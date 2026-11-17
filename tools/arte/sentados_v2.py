import sys
from PIL import Image
A, OUT = sys.argv[1], sys.argv[2]

def pose(src, hip, shoe, squash, dip=0):
    """Vista de frente. squash: 0.32 sentado, 1.0 de pie. dip: cuánto baja el torso (inclinarse para pararse)."""
    s = src
    w, h = s.size
    torso = s.crop((0, 0, w, hip))
    piernas = s.crop((0, hip, w, shoe))
    piernas = piernas.resize((w, max(1, round(piernas.height * squash))), Image.NEAREST)
    zapatos = s.crop((0, shoe, w, h))
    alto = torso.height + piernas.height + zapatos.height
    out = Image.new("RGBA", (w, alto), (0, 0, 0, 0))
    out.paste(zapatos, (0, alto - zapatos.height), zapatos)
    out.paste(piernas, (0, torso.height), piernas)
    out.paste(torso, (0, dip), torso)
    return out

def cargar(p):
    s = Image.open(p).convert("RGBA"); return s.crop(s.getbbox())

def hoja(frames, path):
    w = max(f.width for f in frames); h = max(f.height for f in frames)
    sh = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames): sh.paste(f, (i * w + (w - f.width) // 2, h - f.height), f)
    sh.save(path)

def hacer(nombre, src, hip, shoe, respiro):
    sentado = [pose(src, hip, shoe, 0.32), pose(src, hip, shoe, 0.32, dip=respiro)]
    # levantarse: inclinarse, empujar, casi de pie, de pie
    levantarse = [pose(src, hip, shoe, 0.32),
                  pose(src, hip, shoe, 0.34, dip=respiro * 3),
                  pose(src, hip, shoe, 0.55, dip=respiro * 2),
                  pose(src, hip, shoe, 0.82, dip=respiro),
                  pose(src, hip, shoe, 1.0)]
    hoja(sentado, f"{OUT}/sprites_v2/{nombre}/hoja_sentado.png")
    hoja(levantarse, f"{OUT}/sprites_v2/{nombre}/hoja_levantarse.png")
    for i, f in enumerate(sentado): f.save(f"{OUT}/sprites_v2/{nombre}/sentado_{i+1}.png")
    for i, f in enumerate(levantarse): f.save(f"{OUT}/sprites_v2/{nombre}/levantarse_{i+1}.png")
    return sentado, levantarse

lalo = hacer("lalo", cargar(f"{A}/sprites/lalo_sur.png"), 158, 198, 3)
chava = hacer("don_chava", cargar(f"{A}/sprites/guardia/down_2.png"), 182, 250, 4)

silla = cargar(f"{A}/sprites/silla.png")
BG = (34, 36, 40, 255)
def escena(fl, fc):
    c = Image.new("RGBA", (560, 380), BG)
    sl = silla.resize((150, int(silla.height * 150 / silla.width)), Image.NEAREST)
    for x, f in ((60, fl), (300, fc)):
        cx = x + 90
        c.paste(sl, (cx - sl.width // 2, 360 - sl.height), sl)
        c.paste(f, (cx - f.width // 2, 362 - f.height), f)
    return c

# Tira estática: sentado 1, sentado 2, y los 5 de levantarse
tira = Image.new("RGBA", (560 * 7 // 2, 380 * 2), BG)
cuadros = [escena(lalo[0][0], chava[0][0]), escena(lalo[0][1], chava[0][1])] + [escena(a, b) for a, b in zip(lalo[1], chava[1])]
tira = Image.new("RGBA", (280 * 7, 380), BG)
for i, c in enumerate(cuadros):
    tira.paste(c.resize((280, 190), Image.NEAREST), (i * 280, 95))
tira.save(f"{OUT}/sentados_v2_tira.png")

# GIF: respira, se levanta, espera, se sienta
seq, dur = [], []
for _ in range(3):
    for i in (0, 1): seq.append(escena(lalo[0][i], chava[0][i])); dur.append(450)
for a, b in zip(lalo[1], chava[1]): seq.append(escena(a, b)); dur.append(140)
seq.append(seq[-1]); dur.append(900)
for a, b in zip(reversed(lalo[1]), reversed(chava[1])): seq.append(escena(a, b)); dur.append(140)
seq = [s.convert("RGB") for s in seq]
seq[0].save(f"{OUT}/sentados_v2.gif", save_all=True, append_images=seq[1:], duration=dur, loop=0)
print("ok")
