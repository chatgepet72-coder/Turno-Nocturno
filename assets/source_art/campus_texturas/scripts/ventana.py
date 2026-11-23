"""Classroom window seen from outside, 512x512 (worked at 1024): aluminium frame, dark glass,
intact and broken versions. Not tileable."""
import numpy as np, math
from PIL import Image, ImageDraw
from texlib import Noise, down2, grade, to_img, blob, walk

S = 1024
def build(broken):
    rng = np.random.default_rng(12); N = Noise(S, 12)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # ---------------------------------------------------------------- glass (everything first painted as glass)
    g = np.array([22, 28, 34], np.float32)*(1 + .1*(1 - yy/S))[..., None]
    g = g*(1 + .04*N(60) + .02*N(2))[..., None]
    refl = np.clip(np.sin((xx*.8 - yy)*.006 + 1.3)*1.4 - .6, 0, 1)*.16 + np.clip(N(200) - .3, 0, 1)*.06
    g = g + np.array([90, 104, 118])*refl[..., None]*.6
    # faint classroom interior: desk shapes and a chair back, barely visible
    inter = np.zeros((S, S), np.float32)
    im = Image.new('L', (S, S), 0); di = ImageDraw.Draw(im)
    for x0 in (120, 380, 640, 880):
        di.rectangle([x0, 720, x0 + 150, 760], fill=255); di.rectangle([x0 + 10, 760, x0 + 22, 880], fill=255); di.rectangle([x0 + 128, 760, x0 + 140, 880], fill=255)
    di.rectangle([300, 620, 420, 700], fill=200)
    inter = np.asarray(im).astype(np.float32)/255
    inter = N.blur(inter, 6); g *= (1 - .1*inter)[..., None]
    # dust and grime: heavier at the bottom of each pane, dirt runs
    dust = np.clip(N(30)*.5 + .5, 0, 1)*.12 + np.clip(N(4, 60)*.6 - .4, 0, 1)*.18
    g = g + np.array([104, 100, 92])*dust[..., None]*.35
    # a greasy handprint smudge on the lower-left pane
    hp = Image.new('L', (S, S), 0); dh = ImageDraw.Draw(hp)
    hc = (250, 560)
    dh.ellipse([hc[0] - 46, hc[1] - 30, hc[0] + 46, hc[1] + 56], fill=255)
    for k, (dx, L) in enumerate(((-40, 70), (-14, 92), (12, 96), (38, 84))):
        dh.line([(hc[0] + dx, hc[1] - 20), (hc[0] + dx*1.2, hc[1] - 20 - L)], fill=255, width=22)
    dh.line([(hc[0] + 44, hc[1] + 30), (hc[0] + 96, hc[1] - 10)], fill=255, width=22)
    hpm = N.blur(np.asarray(hp).astype(np.float32)/255, 4)*np.clip(.7 + .3*N(6), 0, 1)
    g = g + np.array([120, 122, 120])*hpm[..., None]*.09
    rgb = g.copy()
    img = to_img(rgb); d = ImageDraw.Draw(img)
    # ---------------------------------------------------------------- aluminium frame
    AL = (132, 134, 138); ALD = (98, 100, 104); ALL = (162, 164, 168); GASK = (20, 20, 22)
    def bar(x0, y0, x1, y1, vertical):
        d.rectangle([x0, y0, x1, y1], fill=AL)
        n = 3
        for k in range(n):        # extrusion grooves along the bar
            t = (k + 1)/(n + 1)
            if vertical:
                x = x0 + (x1 - x0)*t; d.line([(x, y0), (x, y1)], fill=ALD, width=2); d.line([(x + 2, y0), (x + 2, y1)], fill=ALL, width=1)
            else:
                y = y0 + (y1 - y0)*t; d.line([(x0, y), (x1, y)], fill=ALD, width=2); d.line([(x0, y + 2), (x1, y + 2)], fill=ALL, width=1)
        d.rectangle([x0, y0, x1, y1], outline=(60, 62, 66), width=2)
    F = 56; SILL = 72; TR = 300; TRH = 40; MUL = 32
    # outer frame
    bar(0, 0, S - 1, F, False); bar(0, S - SILL, S - 1, S - 1, False); bar(0, 0, F, S - 1, True); bar(S - F, 0, S - 1, S - 1, True)
    bar(F, TR, S - F, TR + TRH, False)                                # transom
    bar(S//2 - MUL//2, F, S//2 + MUL//2, TR, True)                     # upper mullion
    # lower part: two sliding sashes, the right one in front, overlapping in the middle
    SW = 30
    L0, L1 = F, S//2 + 26; R0, R1 = S//2 - 26, S - F
    Y0, Y1 = TR + TRH, S - SILL
    for (x0, x1) in ((L0, L1), (R0, R1)):
        bar(x0, Y0, x0 + SW, Y1, True); bar(x1 - SW, Y0, x1, Y1, True)
        bar(x0, Y0, x1, Y0 + SW, False); bar(x0, Y1 - SW, x1, Y1, False)
    # glass areas (for gaskets and breakage)
    panes = [(F, F, S//2 - MUL//2, TR), (S//2 + MUL//2, F, S - F, TR), (L0 + SW, Y0 + SW, L1 - SW, Y1 - SW), (R0 + SW, Y0 + SW, R1 - SW, Y1 - SW)]
    # the left sash's right edge is hidden behind the right sash: repaint the front sash's left stile on top
    bar(R0, Y0, R0 + SW, Y1, True)
    for x0, y0, x1, y1 in panes:
        d.rectangle([x0, y0, x1, y1], outline=GASK, width=6)
    # latch on the meeting stiles, screws in the corners
    d.rounded_rectangle([R0 + 4, 640, R0 + 26, 720], radius=6, fill=(56, 56, 60), outline=(20, 20, 22), width=2)
    d.rectangle([R0 + 10, 668, R0 + 40, 684], fill=(150, 150, 156), outline=(30, 30, 32), width=2)
    for x, y in ((F//2, F//2), (S - F//2, F//2), (F//2, S - SILL//2), (S - F//2, S - SILL//2), (F//2, TR + TRH//2), (S - F//2, TR + TRH//2)):
        d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(150, 150, 154), outline=(40, 40, 42), width=2); d.line([(x - 4, y), (x + 4, y)], fill=(40, 40, 42), width=2)
    # drain slots in the sill
    for x in (200, 500, 800): d.rounded_rectangle([x, S - 30, x + 60, S - 20], radius=4, fill=(30, 30, 32))
    a = np.asarray(img).astype(np.float32)
    frame = np.ones((S, S), bool)
    for x0, y0, x1, y1 in panes: frame[y0 + 3:y1 - 2, x0 + 3:x1 - 2] = False
    # aluminium wear: white oxidation pits, grime gathered low and in corners, rain streaks below the head
    ox = frame & (N(1.0) > 2.2); a[ox] = a[ox]*.4 + np.array([200, 200, 196])*.6
    grime = frame*np.clip(N(30)*.4 + (yy/S)*.7 - .35, 0, 1)
    a = a*(1 - .3*grime[..., None]) + np.array([70, 64, 56])*.3*grime[..., None]
    run = frame*np.clip(N(80, 2.5) - 1.0, 0, 1)*.18*(yy < 340); a *= (1 - run)[..., None]
    if broken:
        img = to_img(a); d = ImageDraw.Draw(img)
        x0, y0, x1, y1 = panes[3]; ic = (x0 + (x1 - x0)*.46, y0 + (y1 - y0)*.42)
        def clipped(pts): return [(min(max(x, x0 + 4), x1 - 4), min(max(y, y0 + 4), y1 - 4)) for x, y in pts]
        # hole: jagged, shows the dark room; a few shards still hanging inside it
        hole = []; r = 80
        for k in range(30):
            t = 2*math.pi*k/30 + rng.normal(0, .06); r = np.clip(r + rng.normal(0, 22), 40, 140)
            rr = r*(rng.uniform(.6, .8) if rng.random() < .22 else 1)   # a few jagged notches
            hole.append((ic[0] + math.cos(t)*rr, ic[1] + math.sin(t)*rr*.85))
        # radial cracks out to the sash, ring cracks between them
        rad = []
        for k in range(15):
            ang = 2*math.pi*k/15 + rng.normal(0, .12)
            start = (ic[0] + math.cos(ang)*90, ic[1] + math.sin(ang)*80)
            pts = [start]; p = start; L = 0
            while x0 + 4 < p[0] < x1 - 4 and y0 + 4 < p[1] < y1 - 4 and L < 900:
                ang += rng.normal(0, .07); p = (p[0] + math.cos(ang)*18, p[1] + math.sin(ang)*18); pts.append(p); L += 18
            pts = clipped(pts); rad.append(pts)
            d.line(pts, fill=(176, 186, 192), width=2); d.line([(x + 2, y + 1) for x, y in pts], fill=(10, 12, 14), width=1)
        for R in (170, 250, 330):
            for k in range(len(rad)):
                if rng.random() < .55:
                    a1 = rad[k]; a2 = rad[(k + 1) % len(rad)]
                    i1 = min(len(a1) - 1, int(R/18)); i2 = min(len(a2) - 1, int(R/18))
                    mid = ((a1[i1][0] + a2[i2][0])/2 + rng.normal(0, 8), (a1[i1][1] + a2[i2][1])/2 + rng.normal(0, 8))
                    d.line(clipped([a1[i1], mid, a2[i2]]), fill=(150, 160, 166), width=2)
        d.polygon(clipped(hole), fill=(6, 6, 8))
        for k in range(3):
            j = rng.integers(len(hole)); p = hole[j]
            tip = (ic[0] + (p[0] - ic[0])*.35 + rng.normal(0, 8), ic[1] + (p[1] - ic[1])*.35 + rng.normal(0, 8))
            sh = clipped([p, hole[(j + 1) % len(hole)], tip])
            d.polygon(sh, fill=(30, 36, 44)); d.line(sh + sh[:1], fill=(150, 160, 168), width=2)
        d.line(clipped(hole) + clipped(hole)[:1], fill=(170, 180, 186), width=3)
        # brown packing tape slapped over one crack
        t0 = (ic[0] + 40, ic[1] + 190); t1 = (ic[0] + 200, ic[1] + 150); w = 30
        ang = math.atan2(t1[1] - t0[1], t1[0] - t0[0]); nx, ny = -math.sin(ang)*w/2, math.cos(ang)*w/2
        tape = clipped([(t0[0] + nx, t0[1] + ny), (t1[0] + nx, t1[1] + ny), (t1[0] - nx, t1[1] - ny), (t0[0] - nx, t0[1] - ny)])
        layer = Image.new('RGBA', (S, S), (0, 0, 0, 0)); dl = ImageDraw.Draw(layer)
        dl.polygon(tape, fill=(150, 112, 62, 170)); dl.line(tape + tape[:1], fill=(110, 80, 44, 220), width=2)
        img = img.convert('RGBA'); img.alpha_composite(layer); img = img.convert('RGB')
        # glass crumbs on the sill
        d = ImageDraw.Draw(img)
        for k in range(40):
            c = (rng.uniform(x0 + 40, x1 - 40), rng.uniform(S - SILL + 8, S - 40))
            d.polygon(blob(c, rng.uniform(2, 6), rng, 3, .5), fill=(140, 152, 160))
        a = np.asarray(img).astype(np.float32)
    return to_img(grade(down2(a), sat=.75, val=.88))

if __name__ == '__main__':
    build(False).save('texturas_exterior/ventana_salon.png')
    build(True).save('texturas_exterior/ventana_salon_rota.png')
    print('ok')
