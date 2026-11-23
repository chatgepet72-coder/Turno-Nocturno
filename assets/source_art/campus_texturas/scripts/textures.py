"""Exterior textures for the school at night. Seamless 1024x1024 (worked at 2048 and box-reduced)."""
import numpy as np, math, sys, os
from PIL import Image, ImageDraw
from scipy.spatial import cKDTree
from texlib import Noise, wdraw, blob, walk, down2, grade, to_img, lerp3

M = 2048
OUT = 'texturas_exterior'
os.makedirs(OUT, exist_ok=True)

# ====================================================================== 1. dry overgrown grass with leaves and litter
def pasto():
    rng = np.random.default_rng(1); N = Noise(M, 1)
    lo, mid = N.fbm([220, 90], [1, .6]), N(30)
    base = lerp3((78, 76, 46), (126, 112, 70), np.clip(.55 + .35*lo, 0, 1))
    soil = np.clip(N(60)*.8 - .9, 0, 1)
    base = base*(1 - soil[..., None]*.6) + np.array([62, 52, 40])*soil[..., None]*.6
    base *= (1 + .08*mid)[..., None]
    img = to_img(base); d = ImageDraw.Draw(img)
    flow = N(260)*1.6                                    # blades lie in patches that share a direction
    def blades(n, pal, wr, lr, clumps=None):
        for _ in range(n):
            if clumps is not None and rng.random() < .55:
                c = clumps[rng.integers(len(clumps))]; a = rng.uniform(0, 6.283); r0 = rng.uniform(0, 26)
                p = (c[0] + math.cos(a)*r0, c[1] + math.sin(a)*r0); ang = a + rng.normal(0, .35)
            else:
                p = (rng.uniform(0, M), rng.uniform(0, M)); ang = flow[int(p[1]) % M, int(p[0]) % M] + rng.normal(0, .55)
            L = rng.uniform(*lr); w = rng.uniform(*wr); bend = rng.normal(0, .3)
            p1 = (p[0] + math.cos(ang)*L*.55, p[1] + math.sin(ang)*L*.55)
            p2 = (p1[0] + math.cos(ang + bend)*L*.45, p1[1] + math.sin(ang + bend)*L*.45)
            col = pal[rng.integers(len(pal))]; j = rng.uniform(.85, 1.12)
            col = tuple(int(min(255, v*j)) for v in col)
            wdraw(d, M, 'line', [p, p1], pad=w, fill=col, width=max(1, int(w)))
            wdraw(d, M, 'line', [p1, p2], pad=w, fill=col, width=max(1, int(w*.6)))
    clumps = [(rng.uniform(0, M), rng.uniform(0, M)) for _ in range(260)]
    blades(26000, [(44, 52, 32), (54, 60, 36), (60, 58, 38), (48, 46, 32)], (3, 5), (24, 60))
    blades(30000, [(84, 86, 52), (110, 102, 62), (126, 112, 68), (100, 86, 52), (78, 80, 48), (136, 120, 74)], (2.5, 4.5), (28, 74), clumps)
    # dry leaves (some will be covered by the last blades)
    for _ in range(140):
        c = (rng.uniform(0, M), rng.uniform(0, M)); L = rng.uniform(22, 44); a = rng.uniform(0, 6.283)
        col = [(112, 76, 42), (132, 98, 54), (88, 60, 36), (146, 118, 70), (100, 84, 50)][rng.integers(5)]
        wid = rng.uniform(.3, .55)
        pts = [(c[0] + math.cos(a)*L*math.cos(t) - math.sin(a)*L*wid*math.sin(t)*abs(math.sin(t))**.3*1.3,
                c[1] + math.sin(a)*L*math.cos(t) + math.cos(a)*L*wid*math.sin(t)*abs(math.sin(t))**.3*1.3) for t in np.linspace(0, 6.283, 18)]
        wdraw(d, M, 'poly', pts, fill=col)
        dark = tuple(int(v*.68) for v in col)
        wdraw(d, M, 'line', [(c[0] - math.cos(a)*L*1.15, c[1] - math.sin(a)*L*1.15), (c[0] + math.cos(a)*L*.9, c[1] + math.sin(a)*L*.9)], pad=3, fill=dark, width=2)
        if rng.random() < .4:      # a bite / tear out of the leaf
            e = blob((c[0] + math.cos(a + 1.4)*L*wid, c[1] + math.sin(a + 1.4)*L*wid), L*.25, rng, 8)
            wdraw(d, M, 'poly', e, fill=tuple(int(v) for v in base[int(c[1]) % M, int(c[0]) % M]))
    # litter
    for _ in range(52):
        c = (rng.uniform(0, M), rng.uniform(0, M)); a = rng.uniform(0, 6.283); k = rng.random()
        if k < .3:      # paper scrap
            pts = blob(c, rng.uniform(18, 34), rng, 5, .45, rng.uniform(.5, .9), a)
            col = [(170, 164, 146), (150, 146, 132), (176, 168, 140)][rng.integers(3)]
            wdraw(d, M, 'poly', pts, fill=col)
            wdraw(d, M, 'line', [pts[0], pts[2]], pad=2, fill=tuple(int(v*.8) for v in col), width=2)
        elif k < .58:   # chip/candy wrapper
            col = [(118, 44, 40), (52, 66, 108), (142, 142, 146), (148, 92, 42), (60, 96, 60)][rng.integers(5)]
            pts = blob(c, rng.uniform(18, 30), rng, 6, .3, .55, a)
            wdraw(d, M, 'poly', pts, fill=col)
            for q in range(3):
                p0 = pts[rng.integers(6)]; p1 = pts[rng.integers(6)]
                wdraw(d, M, 'line', [p0, p1], pad=2, fill=tuple(int(min(255, v*rng.choice([.7, 1.35]))) for v in col), width=2)
        elif k < .72:   # bottle cap
            col = [(130, 40, 36), (60, 70, 120), (150, 150, 152)][rng.integers(3)]; r = rng.uniform(8, 11)
            wdraw(d, M, 'ell', [(c[0] - r, c[1] - r), (c[0] + r, c[1] + r)], fill=tuple(int(v*.7) for v in col))
            wdraw(d, M, 'ell', [(c[0] - r + 3, c[1] - r + 3), (c[0] + r - 3, c[1] + r - 3)], fill=col)
        elif k < .86:   # cigarette butt
            p1 = (c[0] + math.cos(a)*26, c[1] + math.sin(a)*26); pm = (c[0] + math.cos(a)*12, c[1] + math.sin(a)*12)
            wdraw(d, M, 'line', [c, pm], pad=6, fill=(170, 138, 88), width=7)
            wdraw(d, M, 'line', [pm, p1], pad=6, fill=(186, 182, 172), width=6)
            wdraw(d, M, 'line', [(p1[0] - math.cos(a)*3, p1[1] - math.sin(a)*3), p1], pad=6, fill=(46, 40, 36), width=6)
        elif k < .94:   # crushed can
            p1 = (c[0] + math.cos(a)*44, c[1] + math.sin(a)*44)
            col = [(150, 150, 156), (120, 40, 40), (60, 80, 120)][rng.integers(3)]
            wdraw(d, M, 'line', [c, p1], pad=14, fill=tuple(int(v*.6) for v in col), width=26)
            wdraw(d, M, 'line', [c, p1], pad=14, fill=col, width=20)
            mid_ = ((c[0] + p1[0])/2, (c[1] + p1[1])/2)
            wdraw(d, M, 'line', [(mid_[0] - math.sin(a)*10, mid_[1] + math.cos(a)*10), (mid_[0] + math.sin(a)*10, mid_[1] - math.cos(a)*10)], pad=4, fill=tuple(int(v*.55) for v in col), width=4)
        else:           # glass shards
            for q in range(4):
                cc = (c[0] + rng.normal(0, 14), c[1] + rng.normal(0, 14))
                wdraw(d, M, 'poly', blob(cc, rng.uniform(4, 9), rng, 3, .5), fill=[(60, 92, 60), (96, 64, 34)][int(k > .97)])
    blades(11000, [(140, 126, 80), (156, 140, 90), (118, 112, 70), (104, 100, 60)], (2, 3.5), (22, 60), clumps)
    rgb = np.asarray(img).astype(np.float32)
    rgb *= (1 + .05*N(1.5) + .06*N(140))[..., None]
    return grade(down2(rgb), sat=.7, val=.82)

# ====================================================================== 2. sidewalk concrete: cracks, gum, stains
def concreto():
    rng = np.random.default_rng(2); N = Noise(M, 2)
    rgb = np.ones((M, M, 3), np.float32)*np.array([134, 131, 124], np.float32)
    rgb *= (1 + .05*N(260) + .04*N(50) + .035*N(2.5) + .025*N(.7, 16))[..., None]
    # aggregate speckle
    for col, n, sz in (((170, 166, 156), 70000, 1), ((96, 94, 90), 70000, 1), ((150, 146, 136), 9000, 2), ((84, 82, 78), 7000, 2)):
        ys, xs = rng.integers(0, M, n), rng.integers(0, M, n)
        for dy in range(sz):
            for dx in range(sz): rgb[(ys + dy) % M, (xs + dx) % M] = rgb[(ys + dy) % M, (xs + dx) % M]*.45 + np.array(col)*.55
    # stains (water, oil, dirt) and dirt along the joints
    st = np.clip(N(70)*1.0 - .9, 0, 1.2); rgb *= (1 - .12*st)[..., None]
    ring = np.clip(1 - np.abs(N(90))*7, 0, 1)*(N(300) > .4); rgb *= (1 - .08*ring)[..., None]
    img = to_img(rgb); dmask = Image.new('L', (M, M), 0); dm = ImageDraw.Draw(dmask)
    # control joints: tile = 2 x 2 slabs
    for v in (0, M//2):
        for k in range(0, M, 64):
            j = rng.normal(0, .8)
            wdraw(dm, M, 'line', [(v + j, k), (v + j, k + 64)], pad=8, fill=255, width=9)
            wdraw(dm, M, 'line', [(k, v + j), (k + 64, v + j)], pad=8, fill=255, width=9)
    # cracks (random walks with branches), many start at a joint
    cmask = Image.new('L', (M, M), 0); cm = ImageDraw.Draw(cmask)
    def crack(p, ang, steps, w):
        pts, _ = walk(p, ang, steps, 7, .28, rng)
        for a_, b_ in zip(pts[:-1], pts[1:]): wdraw(cm, M, 'line', [a_, b_], pad=w, fill=255, width=max(1, int(w)))
        for i in range(4, len(pts) - 4, 1):
            if rng.random() < .03: crack(pts[i], ang + rng.choice([-1, 1])*rng.uniform(.6, 1.2), int(steps*rng.uniform(.2, .5)), max(1.5, w*.6))
    for _ in range(9):
        if rng.random() < .6:
            v = rng.choice([0, M//2]); p = (v, rng.uniform(0, M)) if rng.random() < .5 else (rng.uniform(0, M), v)
        else: p = (rng.uniform(0, M), rng.uniform(0, M))
        crack(p, rng.uniform(0, 6.283), rng.integers(40, 140), rng.uniform(2.5, 4.5))
    a = np.asarray(img).astype(np.float32)
    jm = np.asarray(dmask).astype(np.float32)/255; crk = np.asarray(cmask).astype(np.float32)/255
    halo = np.clip(N.blur(jm + crk, 6)*1.6, 0, 1)
    a *= (1 - .18*halo)[..., None]
    a = a*(1 - jm[..., None]) + np.array([66, 64, 60])*(1 + .15*N(3))[..., None]*jm[..., None]
    a = a*(1 - crk[..., None]) + np.array([56, 54, 52])*crk[..., None]
    chip = (N(4) > 1.6)*np.clip(N.blur(jm, 4)*3, 0, 1); a *= (1 - .12*chip)[..., None]
    # chewing gum: clustered, mostly black-grey, a few pale ones, with a faint stain ring
    img = to_img(a); d = ImageDraw.Draw(img)
    dens = N(240)
    placed = 0
    while placed < 90:
        c = (rng.uniform(0, M), rng.uniform(0, M))
        if rng.random() > np.clip(.25 + .5*dens[int(c[1]), int(c[0])], .05, 1): continue
        placed += 1; r = rng.uniform(5, 10)
        bg = a[int(c[1]) % M, int(c[0]) % M]
        wdraw(d, M, 'poly', blob(c, r + 4, rng, 12, .2), fill=tuple(int(v*.84) for v in bg))
        g = rng.random()
        col = (52, 51, 50) if g < .35 else (72, 70, 67) if g < .7 else (104, 102, 98) if g < .93 else (122, 108, 106)
        pts = blob(c, r, rng, 12, .22); wdraw(d, M, 'poly', pts, fill=col)
        inner = blob((c[0] + rng.normal(0, 2), c[1] + rng.normal(0, 2)), r*.55, rng, 9, .35)
        wdraw(d, M, 'poly', inner, fill=tuple(int(min(255, v*rng.choice([.8, 1.18]))) for v in col))
    a = np.asarray(img).astype(np.float32)
    a *= (1 + .03*N(1.2))[..., None]
    return grade(down2(a), sat=.6, val=.84)

# ====================================================================== 3. worn parking-lot asphalt
def asfalto():
    rng = np.random.default_rng(3); N = Noise(M, 3)
    worn = np.clip(.5 + .32*N(200) + .2*N(60), 0, 1)
    a = lerp3((48, 48, 50), (78, 77, 76), worn)
    a *= (1 + .06*N(1.2) + .04*N(8))[..., None]
    # aggregate stones: more exposed where worn
    for n, (lo, hi), sz in ((260000, (70, 120), 1), (70000, (90, 150), 2), (14000, (100, 160), 3)):
        ys, xs = rng.integers(0, M, n), rng.integers(0, M, n)
        keep = rng.random(n) < (.35 + .65*worn[ys, xs]); ys, xs = ys[keep], xs[keep]
        v = rng.uniform(lo, hi, len(ys)); tint = rng.uniform(-6, 6, len(ys))
        col = np.stack([v + tint, v, v - tint], -1)
        for dy in range(sz):
            for dx in range(sz):
                if sz == 3 and (dy, dx) in ((0, 0), (0, 2), (2, 0), (2, 2)): continue
                a[(ys + dy) % M, (xs + dx) % M] = col*.85 + a[(ys + dy) % M, (xs + dx) % M]*.15
    # dust in low spots
    dust = np.clip(N(40) - 1.1, 0, 1); a = a*(1 - .35*dust[..., None]) + np.array([118, 112, 102])*.35*dust[..., None]
    # oil stains
    oil = np.zeros((M, M), np.float32)
    yy, xx = np.mgrid[0:M, 0:M].astype(np.float32)
    lumpy = N(14)
    for _ in range(4):
        c = rng.uniform(0, M, 2); r = rng.uniform(40, 90)
        dx = (xx - c[0] + M/2) % M - M/2; dy = (yy - c[1] + M/2) % M - M/2
        rr = np.sqrt(dx*dx + (dy*rng.uniform(.6, 1))**2)/r
        oil = np.maximum(oil, np.clip((1 - rr + .25*lumpy)*2.2, 0, 1))
    a *= (1 - .3*N.blur(oil, 3))[..., None]
    # patch of newer asphalt
    img = to_img(a); pm = Image.new('L', (M, M), 0); dp = ImageDraw.Draw(pm)
    c = (M*.68, M*.3); w, h, ang = 220, 150, .06
    pts = [(c[0] + x*math.cos(ang) - y*math.sin(ang), c[1] + x*math.sin(ang) + y*math.cos(ang)) for x, y in ((-w, -h), (w, -h), (w, h), (-w, h))]
    wdraw(dp, M, 'poly', pts, fill=255)
    # cracks: long ones + sealed ones + alligator area
    cmask = Image.new('L', (M, M), 0); cm = ImageDraw.Draw(cmask); smask = Image.new('L', (M, M), 0); sm = ImageDraw.Draw(smask)
    for _ in range(7):
        pts_, _a = walk((rng.uniform(0, M), rng.uniform(0, M)), rng.uniform(0, 6.283), rng.integers(60, 200), 8, .18, rng)
        target = sm if rng.random() < .25 else cm; w_ = 9 if target is sm else rng.uniform(2, 3.5)
        for p0, p1 in zip(pts_[:-1], pts_[1:]): wdraw(target, M, 'line', [p0, p1], pad=w_, fill=255, width=int(w_))
    pts = rng.uniform(0, M, (2200, 2))
    tree = cKDTree(pts, boxsize=M)
    ys_, xs_ = np.mgrid[0:M:2, 0:M:2]
    q = np.stack([xs_.ravel() + 3*N(20)[::2, ::2].ravel(), ys_.ravel() + 3*N(20)[::2, ::2].ravel()], -1) % M
    dd, _ = tree.query(q, k=2)
    edge = ((dd[:, 1] - dd[:, 0]) < 2.2).reshape(M//2, M//2)
    edge = np.kron(edge, np.ones((2, 2), bool))
    gator = edge & (N(160) > .9)
    a = np.asarray(img).astype(np.float32)
    patch = np.asarray(pm).astype(np.float32)/255
    pa = np.array([50, 50, 52], np.float32)*(1 + .1*N(1.4) + .04*N(30))[..., None]
    a = a*(1 - patch[..., None]) + pa*patch[..., None]
    pe = np.clip(N.blur(patch, 1.5), 0, 1); pedge = (pe > .1) & (pe < .9)
    a[pedge] = a[pedge]*.6 + np.array([30, 30, 32])*.4
    crk = np.maximum(np.asarray(cmask).astype(np.float32)/255, gator*1.0)
    a *= (1 - .45*crk)[..., None]
    seal = np.asarray(smask).astype(np.float32)/255
    a = a*(1 - seal[..., None]) + np.array([22, 22, 24])*(1 + .1*N(2))[..., None]*seal[..., None]
    return grade(down2(a), sat=.5, val=.88)

# ====================================================================== 4. painted concrete-block wall: cream over grey, efflorescence
def pared():
    rng = np.random.default_rng(4); N = Noise(M, 4)
    yy, xx = np.mgrid[0:M, 0:M].astype(np.float32)
    CH, BW, J = 128, 256, 7                                    # course height, block width, joint (2x px)
    line_y = M*.64 + 2.5*N(40)[0]                              # paint line, periodic in x
    cream = np.array([194, 180, 144], np.float32); grey = np.array([118, 118, 115], np.float32)
    top = (yy < line_y[None, :]).astype(np.float32)
    soft = np.clip((line_y[None, :] - yy + 1.5)/3, 0, 1)
    a = cream*soft[..., None] + grey*(1 - soft[..., None])
    # block faces: per-block tone, porous surface under the paint
    row = (yy // CH).astype(int); off = (row % 2)*(BW//2)
    col_ = ((xx + off) // BW).astype(int)
    bid = (row*131 + col_*17) % 997
    tone = np.random.default_rng(9).normal(0, 1, 997).astype(np.float32)[bid]
    a *= (1 + .025*tone + .03*N(1.3) + .02*N(6) + .03*N(120))[..., None]
    pits = N(.8) > 2.3; a[pits] *= .82
    # mortar joints (painted over, slightly recessed)
    jy = ((yy + J/2) % CH) < J; jx = ((xx + off + J/2) % BW) < J
    jm = (jy | jx).astype(np.float32)
    jm = np.clip(N.blur(jm, .9)*1.2, 0, 1)
    a *= (1 - .2*jm*(1 + .3*N(3)))[..., None]
    # rain streaks from the top, splash dirt at the bottom
    streak = np.clip(N(70, 3)*.9 - .3, 0, 1)*np.clip(1.1 - yy/(M*.7), 0, 1)
    a *= (1 - .16*streak)[..., None]
    splash = np.clip((yy - M*.9)/(M*.1), 0, 1)*(.6 + .4*np.clip(.5 + N(12), 0, 1))
    a = a*(1 - .45*splash[..., None]) + np.array([86, 76, 62])*.45*splash[..., None]
    # efflorescence (salitre) rising from the floor, with a damp tide line, and peeled paint inside it
    h = M*(.17 + .05*N(260)[0] + .02*N(60)[0])                # height of the damp zone, periodic in x
    z = (yy - (M - h[None, :]))/90 + .35*N(40)                 # >0 inside, soft wavy edge
    a *= (1 - .14*np.clip(z + 1.2, 0, 1)*(1 - np.clip(z, 0, 1)))[..., None]      # damp band just above
    tide = np.clip(1 - np.abs(z + .15)*5, 0, 1)*np.clip(.5 + N(30), 0, 1)
    a = a*(1 - .3*tide[..., None]) + np.array([150, 130, 96])*.3*tide[..., None]
    zin = np.clip(z, 0, 1)
    patchy = np.clip(.3 + .7*N(18) + .4*N(5), 0, 1)
    powder = np.clip(N(1.2)*.5 + .6, 0, 1)
    salt = zin*np.clip(patchy - .25, 0, 1)*powder*.6
    a = a*(1 - salt[..., None]) + np.array([214, 212, 204])*salt[..., None]
    peel = (zin > .6) & (N(30) + .4*N(6) > 1.3)
    raw = np.array([142, 136, 124], np.float32)*(1 + .06*N(1.1) + .05*N(7))[..., None]
    a[peel] = raw[peel]*(1 - .25*pits[peel])[..., None]
    pe = (N.blur(peel.astype(np.float32), 2) > .08) & ~peel
    a[pe] = a[pe]*.55 + np.array([222, 218, 208])*.45          # flaking paint lip
    # a few salt spots higher up
    hi = (N(10) > 2.9) & (yy < M*.6); a[hi] = a[hi]*.6 + np.array([214, 212, 204])*.4
    return grade(down2(a), sat=.68, val=.84)

# ====================================================================== 6. rusty red corrugated roof sheet
def lamina():
    rng = np.random.default_rng(6); N = Noise(M, 6)
    yy, xx = np.mgrid[0:M, 0:M].astype(np.float32)
    P = 256; u = (xx % P)/P                                    # 8 ribs per tile, trapezoidal profile
    # crest [0, .28], slope down [.28, .42], valley [.42, .86], slope up [.86, 1]
    crest = (u < .28); s1 = (u >= .28) & (u < .42); val = (u >= .42) & (u < .86); s2 = u >= .86
    shade = np.where(crest, 1.04, np.where(s1, .86, np.where(val, .95, .92))).astype(np.float32)
    bend = np.minimum.reduce([np.abs(u - t) for t in (.28, .42, .86, 1.0)] + [u])
    shade *= (1 - .12*np.exp(-(bend*P/3)**2))
    valley_w = (val*1.0).astype(np.float32); valley_w = np.clip(N.blur(valley_w, 8, 14), 0, 1)
    red = np.array([142, 44, 34], np.float32)
    a = red*(1 + .05*N(1.2) + .04*N(30))[..., None]
    chalk = np.clip(.4 + .6*N(150) + .3*crest, 0, 1)*.55
    a = a*(1 - chalk[..., None]) + np.array([156, 100, 90])*chalk[..., None]
    # rust: spots, valleys, streaks running down the valleys
    streaks = np.clip(N(90, 2.5)*.8 + valley_w*1.2 - .7, 0, 1)
    spots = np.clip((N(22) + .35*N(5)) - 1.35, 0, 1)
    rust = np.clip(streaks*.8 + spots*1.4 + valley_w*np.clip(N(40), 0, 1)*.6, 0, 1)
    rc = lerp3((132, 74, 36), (74, 40, 24), np.clip(.5 + .5*N(3), 0, 1))
    a = a*(1 - rust[..., None]) + rc*rust[..., None]
    flake = (rust > .25) & (rust < .32); a[flake] = a[flake]*.6 + np.array([184, 120, 104])*.4
    dirt = np.clip(valley_w*(.5 + .5*N(20)) - .2, 0, 1); a *= (1 - .3*dirt)[..., None]
    a *= shade[..., None]
    # end lap at the tile edge (y = 0): overlapping sheet edge
    # screws on the crests along two purlins, rust halo and a rust run below each
    img = to_img(a); d = ImageDraw.Draw(img)
    halo = Image.new('L', (M, M), 0); dh = ImageDraw.Draw(halo)
    for yv in (M*.25, M*.75):
        for k in range(M//P):
            c = (k*P + .14*P, yv + rng.normal(0, 2))
            wdraw(dh, M, 'ell', [(c[0] - 22, c[1] - 22), (c[0] + 22, c[1] + 22)], fill=200)
            L = rng.uniform(80, 320)
            wdraw(dh, M, 'line', [c, (c[0] + rng.normal(0, 3), c[1] + L)], pad=10, fill=150, width=int(rng.uniform(6, 14)))
    hm = N.blur(np.asarray(halo).astype(np.float32)/255, 6, 3)
    b = np.asarray(img).astype(np.float32)
    hm = np.clip(hm*1.4, 0, 1)*np.clip(.6 + .5*N(3), 0, 1)
    b = b*(1 - hm[..., None]*.75) + np.array([110, 58, 28])*hm[..., None]*.75
    img = to_img(b); d = ImageDraw.Draw(img)
    for yv in (M*.25, M*.75):
        for k in range(M//P):
            c = (k*P + .14*P, yv)
            wdraw(d, M, 'ell', [(c[0] - 13, c[1] - 13), (c[0] + 13, c[1] + 13)], fill=(36, 32, 30))
            wdraw(d, M, 'ell', [(c[0] - 9, c[1] - 9), (c[0] + 9, c[1] + 9)], fill=(96, 92, 88) if rng.random() < .6 else (98, 60, 36))
            wdraw(d, M, 'line', [(c[0] - 5, c[1]), (c[0] + 5, c[1])], pad=3, fill=(52, 48, 46), width=3)
    # small debris and a couple of rust holes in the valleys
    for _ in range(26):
        k = rng.integers(M//P); c = (k*P + rng.uniform(.5, .8)*P, rng.uniform(0, M))
        if rng.random() < .25:
            wdraw(d, M, 'poly', blob(c, rng.uniform(3, 7), rng, 7, .4), fill=(16, 12, 10))
        else:
            ang = rng.uniform(1.2, 1.9)
            col = [(96, 70, 42), (70, 58, 40), (110, 84, 52)][rng.integers(3)]
            wdraw(d, M, 'poly', blob(c, rng.uniform(10, 18), rng, 9, .3, .4, ang), fill=col)
    b = np.asarray(img).astype(np.float32)
    return grade(down2(b), sat=.72, val=.84)

# ====================================================================== 7. chain-link fence on transparent background
def malla():
    N = Noise(M, 7)
    yy, xx = np.mgrid[0:M, 0:M].astype(np.float32)
    s = 128.0; r = 5.6
    wA = 3.0*N(90); wB = 3.0*N(90)
    def wire(sign, wob):
        q = (xx + sign*yy + wob) % s
        dist = np.minimum(q, s - q)/np.sqrt(2)
        al = np.clip(r - dist + .5, 0, 1)
        prof = .5 + .5*np.sqrt(np.clip(1 - (dist/r)**2, 0, 1))
        return al, prof
    aA, pA = wire(1, wA); aB, pB = wire(-1, wB)
    ia = np.round((xx + yy)/s); ib = np.round((xx - yy)/s)
    A_on_top = ((ia + ib) % 2 == 0)
    # distance to nearest crossing, to darken the wire going under
    cx = (ia + ib)*s/2; cy = (ia - ib)*s/2
    dc = np.hypot(xx - cx, yy - cy)
    near = np.clip(1 - dc/(r*2.6), 0, 1)
    galv = np.array([150, 153, 158], np.float32)
    tint = (1 + .06*N(2) + .05*N(40))[..., None]
    rust = np.clip(N(30) - 1.1, 0, 1)*.9 + np.clip(N(70) - .6, 0, 1)*.35
    rust = np.clip(rust, 0, 1)
    base = galv*tint
    base = base*(1 - rust[..., None]) + np.array([120, 80, 50])*rust[..., None]
    colA = base*pA[..., None]; colB = base*pB[..., None]
    # under-wire is a little darker where it passes under
    dimA = np.where(~A_on_top, 1 - .35*near, 1); dimB = np.where(A_on_top, 1 - .35*near, 1)
    colA *= dimA[..., None]; colB *= dimB[..., None]
    top_c = np.where(A_on_top[..., None], colA, colB); top_a = np.where(A_on_top, aA, aB)
    bot_c = np.where(A_on_top[..., None], colB, colA); bot_a = np.where(A_on_top, aB, aA)
    # a thin gap around the top wire at each crossing so the weave reads
    q_top = np.where(A_on_top, (xx + yy + wA) % s, (xx - yy + wB) % s)
    d_top = np.minimum(q_top, s - q_top)/np.sqrt(2)
    bot_a = bot_a*(1 - np.clip(r + 2.2 - d_top, 0, 1)*(1 - top_a)*np.clip(near*3, 0, 1))
    al = top_a + bot_a*(1 - top_a)
    rgb = (top_c*top_a[..., None] + bot_c*(bot_a*(1 - top_a))[..., None])/np.maximum(al[..., None], 1e-6)
    # premultiplied 2x reduction; transparent pixels keep the wire colour (no dark halo on mipmaps)
    pre = down2(rgb*al[..., None]); a2 = down2(al)
    rgb2 = pre/np.maximum(a2[..., None], 1e-6)
    fill = rgb2[a2 > .5].mean(0)
    rgb2[a2 < 1e-3] = fill
    return grade(rgb2, sat=.6, val=.86), a2

# ====================================================================== 8. freshly dug wet soil
def tierra():
    rng = np.random.default_rng(8); N = Noise(M, 8)
    ys_, xs_ = np.mgrid[0:M, 0:M].astype(np.float32)
    def voronoi(n, warp, sig):
        pts = rng.uniform(0, M, (n, 2)); tree = cKDTree(pts, boxsize=M)
        q = np.stack([(xs_ + warp*N(sig)).ravel() % M, (ys_ + warp*N(sig)).ravel() % M], -1)
        dd, ii = tree.query(q, k=2)
        return dd[:, 0].reshape(M, M), dd[:, 1].reshape(M, M), ii[:, 0].reshape(M, M)
    wet = np.clip(.6 + .25*N(200), 0, 1)
    base = lerp3((96, 76, 56), (58, 44, 34), wet)
    loose = base*.6*(1 + .16*N(1.2) + .1*N(3.5))[..., None]          # crumbly soil between clods
    a = loose.copy()
    big = np.clip(.5 + .8*N(150), 0, 1)                               # where the big clods are
    for n, warp, wsig, scale, wgt in ((260, 22, 40, 70, big), (1400, 8, 14, 30, 1 - big*.7), (6000, 3, 5, 12, None)):
        f1, f2, cid = voronoi(n, warp, wsig)
        gap = f2 - f1
        tone = rng.normal(0, 1, n).astype(np.float32)[cid]
        dome = np.clip(gap/scale, 0, 1)**.55                           # rounded lump: brighter toward its middle
        cov = np.clip((gap - scale*.3)/(scale*.18), 0, 1)
        if wgt is not None: cov *= np.clip(wgt*1.6 - .2, 0, 1)
        else: cov *= .45*np.clip(.5 + N(60), 0, 1)
        col = base*(1 + .08*tone)[..., None]*(.62 + .5*dome)[..., None]*(1 + .06*N(1.5) + .05*N(5))[..., None]
        a = a*(1 - cov[..., None]) + col*cov[..., None]
    dome = np.clip(N(3), 0, 1)
    # wet glints (very soft)
    glint = (N(1.0) > 2.7) & (wet > .5); a[glint] = a[glint]*.6 + np.array([120, 112, 104])*.4
    # puddles
    yy, xx = ys_, xs_
    for _ in range(1):
        c = rng.uniform(0, M, 2); r = rng.uniform(60, 90)
        dx = (xx - c[0] + M/2) % M - M/2; dy = (yy - c[1] + M/2) % M - M/2
        rr = np.sqrt(dx*dx + (dy*1.5)**2)/r + .25*N(16)
        pud = np.clip((1 - rr)*6, 0, 1)
        pud *= .8
        a = a*(1 - pud[..., None]) + (np.array([34, 30, 28])*(1 + .05*N(40))[..., None] + np.array([6, 9, 14])*np.clip(-dy/r, 0, 1)[..., None])*pud[..., None]
        rim = np.clip(1 - np.abs(rr - 1)*10, 0, 1); a *= (1 - .3*rim)[..., None]
    img = to_img(a); d = ImageDraw.Draw(img)
    # roots
    for _ in range(26):
        pts, _a = walk((rng.uniform(0, M), rng.uniform(0, M)), rng.uniform(0, 6.283), rng.integers(10, 40), 9, .3, rng)
        w = rng.uniform(2, 6); col = [(118, 86, 58), (92, 68, 48), (136, 108, 80)][rng.integers(3)]
        for i, (p0, p1) in enumerate(zip(pts[:-1], pts[1:])):
            ww = max(1, int(w*(1 - i/len(pts))))
            wdraw(d, M, 'line', [p0, p1], pad=ww, fill=col, width=ww)
            if rng.random() < .12:
                q, _ = walk(p0, rng.uniform(0, 6.283), 4, 6, .5, rng)
                wdraw(d, M, 'line', q, pad=3, fill=(150, 130, 104), width=1)
    # pebbles
    for _ in range(340):
        c = (rng.uniform(0, M), rng.uniform(0, M)); r = rng.uniform(3, 12)
        v = rng.uniform(70, 120); col = (int(v + 6), int(v), int(v - 8))
        p = blob(c, r, rng, 8, .3, rng.uniform(.6, 1), rng.uniform(0, 3.14))
        wdraw(d, M, 'poly', [(x + 1.5, y + 1.5) for x, y in p], fill=(26, 20, 16))
        wdraw(d, M, 'poly', p, fill=col)
        if r > 6: wdraw(d, M, 'poly', blob((c[0] - r*.2, c[1] - r*.2), r*.45, rng, 7, .3), fill=tuple(int(min(255, v*1.12)) for v in col))
    # a few dead grass stalks
    for _ in range(60):
        p = (rng.uniform(0, M), rng.uniform(0, M)); ang = rng.uniform(0, 6.283); L = rng.uniform(20, 50)
        wdraw(d, M, 'line', [p, (p[0] + math.cos(ang)*L, p[1] + math.sin(ang)*L)], pad=3, fill=(118, 104, 70), width=2)
    b = np.asarray(img).astype(np.float32)
    return grade(down2(b), sat=.72, val=.86)

GEN = {'pasto': pasto, 'concreto_banqueta': concreto, 'asfalto_estacionamiento': asfalto, 'pared_block': pared,
       'lamina_roja_oxidada': lamina, 'malla_ciclonica': malla, 'tierra_removida': tierra}

if __name__ == '__main__':
    import time
    for n in (sys.argv[1:] or list(GEN)):
        t = time.time(); r = GEN[n]()
        (to_img(*r) if isinstance(r, tuple) else to_img(r)).save(f'{OUT}/{n}.png')
        print(n, round(time.time() - t, 1), 's', flush=True)
