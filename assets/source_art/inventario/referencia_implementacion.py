"""Rebuild the inventory screen using only the kit (panel, slots, icons, layout.json, catalogue).
Doubles as a reference implementation for whoever codes the real screen."""
import json, sys, textwrap
from PIL import Image, ImageDraw, ImageFont, ImageFilter
R = 'inventario/'
L = json.load(open(R + 'ui/layout.json'))
CAT = json.load(open(R + 'inventario.json'))
ITEMS = {i['id']: i for i in CAT['objetos']}

def font(size, bold=False):
    return ImageFont.truetype(R + 'ui/fuente/' + ('CrimsonText-SemiBold.ttf' if bold else 'CrimsonText-Regular.ttf'), size)

def icon(id, max_w, max_h):
    im = Image.open(R + f'iconos/{id}.png').convert('RGBA')
    s = min(max_w/im.width, max_h/im.height)
    return im.resize((max(1, round(im.width*s)), max(1, round(im.height*s))), Image.LANCZOS)

def screen(tab, ids, sel, salud=1.0, mando='playstation'):
    img = Image.open(R + L['panel']['imagen']).convert('RGBA'); d = ImageDraw.Draw(img)
    T = L['pestanas']
    for t in T['lista']:
        if t['id'] == tab:
            act = Image.open(R + T['fondo_activa']).convert('RGBA').resize((t['ancho'] + 8, T['alto'] + 8), Image.LANCZOS)
            img.alpha_composite(act, (t['x'] - 4, T['y'] - 4))
        ic = Image.open(R + t['icono']).convert('RGBA'); s = 28/ic.height
        ic = ic.resize((round(ic.width*s), 28), Image.LANCZOS)
        if t['id'] != tab: ic.putalpha(ic.split()[3].point(lambda v: int(v*.78)))
        img.alpha_composite(ic, (t['icono_x'], T['y'] + 6))
        f = font(T['texto']['tamano'])
        d.text((t['icono_x'] + ic.width + 10, T['y'] + T['alto']//2 + 1), t['texto'], font=f, anchor='lm',
               fill=T['texto']['color_activa'] if t['id'] == tab else T['texto']['color'])
    G = L['cuadricula']
    slot = Image.open(R + G['slot']).convert('RGBA'); slot_s = Image.open(R + G['slot_seleccionado']).convert('RGBA')
    well = G['area']
    for k in range(G['columnas']*3):
        c, r = k % G['columnas'], k//G['columnas']
        x = round(G['origen'][0] + c*G['paso'][0]); y = round(G['origen'][1] + r*G['paso'][1])
        layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
        if k == sel: layer.alpha_composite(slot_s, (x - G['margen_slot_seleccionado'], y - G['margen_slot_seleccionado']))
        else: layer.alpha_composite(slot, (x - G['margen_slot'], y - G['margen_slot']))
        if k < len(ids):
            ic = icon(ids[k], G['tamano_slot'][0] - 16, G['tamano_slot'][1] - 12)
            layer.alpha_composite(ic, (x + (G['tamano_slot'][0] - ic.width)//2, y + (G['tamano_slot'][1] - ic.height)//2))
        # the grid well clips the third row
        clip = Image.new('L', img.size, 0); ImageDraw.Draw(clip).rectangle([well[0], well[1], well[0] + well[2], well[1] + well[3]], fill=255)
        layer.putalpha(Image.composite(layer.split()[3], Image.new('L', img.size, 0), clip))
        img.alpha_composite(layer)
    it = ITEMS[ids[sel]]
    P = L['vista_previa']['area']
    if 'vista_previa_512' in it:                       # native 512 preview: only ever reduced, never enlarged
        im = Image.open(R + it['vista_previa_512']).convert('RGBA'); im = im.crop(im.getbbox())
        k = min((P[2] - 60)/im.width, (P[3] - 24)/im.height)
        big = im.resize((round(im.width*k), round(im.height*k)), Image.LANCZOS)
    else:
        big = icon(it['id'], P[2] - 70, P[3] - 30)
    sh = Image.new('RGBA', big.size, (0, 0, 0, 0)); sh.putalpha(big.split()[3].point(lambda v: v*.6))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)), (P[0] + (P[2] - big.width)//2 + 8, P[1] + (P[3] - big.height)//2 + 10))
    img.alpha_composite(big, (P[0] + (P[2] - big.width)//2, P[1] + (P[3] - big.height)//2))
    D = L['descripcion']
    d.text(tuple(D['nombre']['pos']), it['nombre'], font=font(D['nombre']['tamano']), fill=D['nombre']['color'])
    d.text(tuple(D['tipo']['pos']), it['tipo'], font=font(D['tipo']['tamano']), fill=D['tipo']['color'])
    y = D['texto']['pos'][1]
    for line in textwrap.wrap(it['descripcion'], 31):
        d.text((D['texto']['pos'][0], y), line, font=font(D['texto']['tamano']), fill=D['texto']['color']); y += D['texto']['interlineado']
    S = L['cordura']
    d.text(tuple(S['etiqueta']['pos']), S['etiqueta']['texto'], font=font(S['etiqueta']['tamano']), fill=S['etiqueta']['color'])
    ecg = Image.open(R + S['ecg']['imagen']).convert('RGBA')
    ecg = ecg.crop((0, 0, max(1, round(ecg.width*salud)), ecg.height))
    img.alpha_composite(ecg, tuple(S['ecg']['pos']))
    for b in L['botones']:
        g = Image.open(R + b['iconos'][mando]).convert('RGBA'); img.alpha_composite(g, (b['centro'][0] - g.width//2, b['centro'][1] - g.height//2))
        d.text((b['texto_x'], b['centro'][1]), b['texto'], font=font(b['tamano']), anchor='lm', fill=b['color'])
    return img

if __name__ == '__main__':
    a = screen('objetos', ['pistola_clavos', 'caja_clavos', 'molotov', 'extintor', 'engrapadora', 'botiquin',
                           'llave_etiqueta', 'llave_azul', 'llave_roja', 'celular_roto', 'radio', 'termo',
                           'pala', 'trapo', 'botella_verde', 'botella_vidrio'], 0)
    b = screen('recuperacion', [i['id'] for i in CAT['objetos'] if i['categoria'] == 'recuperacion'], 1, salud=.55, mando='xbox')
    c = screen('documentos', [i['id'] for i in CAT['objetos'] if i['categoria'] == 'documentos'], 4, mando='teclado')
    e = screen('evidencias', [i['id'] for i in CAT['objetos'] if i['categoria'] == 'evidencias'], 2, salud=.3, mando='teclado')
    l = screen('llaves', [i['id'] for i in CAT['objetos'] if i['categoria'] == 'llaves'], 1, mando='xbox')
    for nm, im in (('objetos', a), ('recuperacion', b), ('documentos', c), ('evidencias', e), ('llaves', l)):
        bg = Image.new('RGBA', im.size, (12, 12, 14, 255)); bg.alpha_composite(im); bg.convert('RGB').save(R + f'ui/ejemplo_{nm}.png')
    print('ok')
