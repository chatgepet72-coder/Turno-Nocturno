"""Helpers for seamless (periodic) textures: FFT noise, wrap-around drawing, 2x box downsample, night grade."""
import numpy as np, math
from PIL import Image, ImageDraw

class Noise:
    def __init__(s, M, seed=0):
        s.M = M; s.r = np.random.default_rng(seed)
        s.ky = np.fft.fftfreq(M)[:, None].astype(np.float32); s.kx = np.fft.rfftfreq(M)[None, :].astype(np.float32)
    def _g(s, sy, sx): return np.exp(-2*np.pi**2*(sy**2*s.ky**2 + sx**2*s.kx**2)).astype(np.float32)
    def __call__(s, sig, sigx=None):
        """periodic gaussian noise, unit variance. sig = vertical sigma, sigx = horizontal sigma (anisotropic)."""
        sx = sig if sigx is None else sigx
        f = np.fft.rfft2(s.r.standard_normal((s.M, s.M)).astype(np.float32))
        n = np.fft.irfft2(f*s._g(sig, sx), s=(s.M, s.M)).astype(np.float32)
        return (n - n.mean())/(n.std() + 1e-9)
    def fbm(s, sigs, ws):
        out = sum(w*s(g) for g, w in zip(sigs, ws)); return out/np.sqrt(sum(w*w for w in ws))
    def blur(s, a, sig, sigx=None):
        sx = sig if sigx is None else sigx
        return np.fft.irfft2(np.fft.rfft2(a.astype(np.float32))*s._g(sig, sx), s=a.shape).astype(np.float32)

def wdraw(d, M, kind, pts, pad=0, **kw):
    """draw with wrap-around so shapes crossing an edge reappear on the other side."""
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    x0, x1, y0, y1 = min(xs) - pad, max(xs) + pad, min(ys) - pad, max(ys) + pad
    for ox in (-M, 0, M):
        if x1 + ox < 0 or x0 + ox > M: continue
        for oy in (-M, 0, M):
            if y1 + oy < 0 or y0 + oy > M: continue
            P = [(x + ox, y + oy) for x, y in pts]
            if kind == 'poly': d.polygon(P, **kw)
            elif kind == 'line': d.line(P, **kw)
            elif kind == 'ell': d.ellipse([P[0], P[1]], **kw)

def blob(c, r, rng, n=14, irr=.3, aspect=1.0, ang=0.0):
    ca, sa = math.cos(ang), math.sin(ang); pts = []
    for k in range(n):
        t = 2*math.pi*k/n; rr = r*(1 + irr*rng.uniform(-1, 1))
        x, y = math.cos(t)*rr, math.sin(t)*rr*aspect
        pts.append((c[0] + x*ca - y*sa, c[1] + x*sa + y*ca))
    return pts

def walk(p, ang, steps, step, turn, rng):
    pts = [p]
    for _ in range(steps):
        ang += rng.normal(0, turn); p = (p[0] + math.cos(ang)*step, p[1] + math.sin(ang)*step); pts.append(p)
    return pts, ang

def down2(a):
    H, W = a.shape[:2]
    return a.reshape(H//2, 2, W//2, 2, *a.shape[2:]).mean((1, 3))

def grade(rgb, sat=.72, val=.86, tint=(.96, .985, 1.04), gamma=1.0):
    """night look: less saturation, a little darker, cold tint. rgb float 0..255."""
    lum = rgb @ np.array([.299, .587, .114], np.float32)
    out = lum[..., None] + (rgb - lum[..., None])*sat
    out = 255*np.clip(out/255, 0, 1)**gamma*val
    return np.clip(out*np.array(tint, np.float32), 0, 255)

def to_img(rgb, alpha=None):
    if alpha is None: return Image.fromarray(np.clip(rgb + .5, 0, 255).astype(np.uint8), 'RGB')
    return Image.fromarray(np.dstack([np.clip(rgb + .5, 0, 255), np.clip(alpha*255 + .5, 0, 255)]).astype(np.uint8), 'RGBA')

def lerp3(a, b, t): return np.array(a, np.float32) + (np.array(b, np.float32) - np.array(a, np.float32))*t[..., None]

def seam_ratio(img, horizontal_only=False):
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    def r(arr):
        edge = np.abs(arr[:, 0] - arr[:, -1]).mean()
        inner = np.mean([np.abs(arr[:, i] - arr[:, i + 1]).mean() for i in range(100, arr.shape[1] - 100, 97)])
        return edge/inner
    h = r(a); v = None if horizontal_only else r(a.transpose(1, 0, 2))
    return h, v
