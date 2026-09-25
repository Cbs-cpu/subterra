"""Piezas de las criaturas (todas menos el limo y la araña, que están en enemigos.py).

Cada función devuelve {pieza: (imagen, pivote, fotogramas)}: la imagen es una tira
horizontal de fotogramas del mismo tamaño y el pivote es el punto de giro dentro de un
fotograma (lo usa tools/build_enemy_rig.gd como offset = -pivote).
Todo mira a la derecha. Estilo del Minero: formas gorditas, pocos píxeles, contorno negro.
"""
from PIL import Image

INK = (14, 10, 10, 255)
WHITE = (255, 255, 255, 255)


def hexc(h, a=255):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def mul(c, f):
    return (min(255, int(c[0] * f)), min(255, int(c[1] * f)), min(255, int(c[2] * f)), c[3])


RAMPS = {
    "madera": ["#3b2417", "#6b4226", "#9c6a3c", "#c9975e"],
    "piedra": ["#3a3a46", "#5d5d6e", "#8b8b9c", "#bdbdc9"],
    "hueso": ["#6e6450", "#a89a78", "#d6ccae", "#f4efdc"],
    "fuego": ["#7a1c14", "#d0461e", "#f58a2a", "#ffd24a"],
    "hielo": ["#2a4e8a", "#4a8ad0", "#8ac4f0", "#e0f4ff"],
    "ceniza": ["#1e1422", "#4a2a4e", "#8a3a6e", "#e05a9a"],
    "cristal": ["#1a5a5a", "#2aa8a0", "#6ae8d8", "#e0fffa"],
    "gris": ["#26222e", "#46404e", "#6e6878", "#a8a2b0"],
    "negro": ["#0e0a10", "#1e1a24", "#3a2e44", "#6a4a7a"],
    "rey": ["#6a1e10", "#c04a1a", "#f0a02a", "#fff0a0"],
    "guardian": ["#0a0608", "#2a0a14", "#6a0a24", "#ff2a4a"],
    "morada": ["#2e1a4a", "#5a2a8a", "#8a4ac0", "#d0a0f0"],
    "oro": ["#7a4a12", "#c0801e", "#f0b93a", "#fff08a"],
    "verde": ["#1a4a1a", "#3a8a2a", "#6ac04a", "#b8f08a"],
}


def ramp(name):
    return [hexc(c) for c in RAMPS[name]]


# --- Primitivas ---------------------------------------------------------------------

def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((int(x), int(y)), c)


def rect(im, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(im, xx, yy, c)


def ellipse(im, cx, cy, rx, ry, c):
    for y in range(im.height):
        for x in range(im.width):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                im.putpixel((x, y), c)


def rrect(im, x, y, w, h, c):
    """Rectángulo con las cuatro esquinas quitadas."""
    rect(im, x, y, w, h, c)
    for cx, cy in ((x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)):
        im.putpixel((cx, cy), (0, 0, 0, 0))


def shade_bottom(im, rows, f=0.8):
    """Oscurece las `rows` filas de abajo de cada columna opaca."""
    px = im.load()
    for x in range(im.width):
        ys = [y for y in range(im.height) if px[x, y][3] > 0]
        for y in ys[-rows:]:
            px[x, y] = mul(px[x, y], f)


def ink(im):
    src = im.copy()
    sp = src.load()
    for y in range(im.height):
        for x in range(im.width):
            if sp[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < im.width and 0 <= ny < im.height and sp[nx, ny][3] > 0:
                    im.putpixel((x, y), INK)
                    break
    return im


def strip(frames):
    w, h = frames[0].size
    out = blank(w * len(frames), h)
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * w, 0))
    return out


def mirror(im):
    return im.transpose(Image.FLIP_LEFT_RIGHT)


def tint(im, f):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3]:
                px[x, y] = mul(px[x, y], f)
    return out


def pad(im):
    out = blank(im.width + 2, im.height + 2)
    out.alpha_composite(im, (1, 1))
    return out


def part(frames, pivot):
    """Pieza lista: cada fotograma con 1 px de margen (para que el contorno no se corte)
    y el pivote ajustado a ese margen."""
    if not isinstance(frames, list):
        frames = [frames]
    return (strip([ink(pad(f)) for f in frames]), (pivot[0] + 1, pivot[1] + 1), len(frames))


def eye(im, x, y, tall=True):
    put(im, x, y, INK)
    if tall:
        put(im, x, y + 1, INK)


def eye_hurt(im, x, y):
    put(im, x - 1, y, INK)
    put(im, x, y, INK)
    put(im, x + 1, y, INK)


# --- Cuadrúpedos (cerdo, jabalí, oveja) ---------------------------------------------

def cuadrupedo(kind, main, dark):
    light = mul(main, 1.15)
    # Cuerpo: barriga redonda de 14x8.
    if kind == "oveja":
        body = blank(18, 12)
        for cx, cy, r in ((4, 5, 3.2), (7, 4, 3.4), (10, 4, 3.4), (13, 5, 3.2), (5, 8, 3.2), (9, 8, 3.4), (13, 8, 3.2)):
            ellipse(body, cx, cy, r, r, main)
        for x, y in ((6, 2), (7, 2), (9, 2), (10, 2), (4, 4), (12, 3)):
            put(body, x, y, WHITE)
        shade_bottom(body, 2, 0.85)
        bpiv = (9, 12)
    else:
        body = blank(16, 10)
        rrect(body, 1, 1, 14, 8, main)
        rect(body, 2, 1, 7, 1, light)
        rect(body, 1, 7, 14, 2, mul(main, 0.85))
        if kind == "jabali":
            for x in range(3, 12, 2):
                put(body, x, 1, dark)
            rect(body, 2, 2, 9, 1, mul(main, 0.9))
        bpiv = (8, 10)
    # Cabeza: 0 normal, 1 golpeada.
    heads = []
    for hurt in (False, True):
        hd = blank(11, 10)
        face = hexc("#3a3a44") if kind == "oveja" else main
        rrect(hd, 1, 2, 7, 6, face)
        put(hd, 2, 1, dark if kind != "oveja" else face)
        put(hd, 3, 1, dark if kind != "oveja" else face)
        if kind == "cerdo":
            rect(hd, 7, 4, 3, 3, hexc("#f0a0b0"))
            put(hd, 9, 5, hexc("#a04a60"))
        elif kind == "jabali":
            rect(hd, 7, 4, 3, 3, dark)
            put(hd, 9, 5, INK)
            put(hd, 8, 7, hexc("#f4efdc"))
            put(hd, 9, 7, hexc("#f4efdc"))
            put(hd, 9, 6, hexc("#f4efdc"))
        else:
            rect(hd, 2, 1, 4, 2, WHITE)
        if hurt:
            eye_hurt(hd, 5, 4)
        else:
            eye(hd, 5, 3)
            if kind == "oveja":
                put(hd, 6, 3, WHITE)
        heads.append(hd)
    leg = blank(4, 5)
    rect(leg, 1, 1, 2, 3, mul(main, 0.8) if kind != "oveja" else hexc("#3a3a44"))
    rect(leg, 1, 3, 2, 1, INK if kind != "oveja" else hexc("#1a1a22"))
    leg_dark = blank(4, 5)
    rect(leg_dark, 1, 1, 2, 3, mul(main, 0.6) if kind != "oveja" else hexc("#26262e"))
    tail = blank(5, 5)
    if kind == "cerdo":
        for x, y in ((2, 1), (3, 1), (3, 2), (2, 3)):
            put(tail, x, y, hexc("#f0a0b0"))
    elif kind == "jabali":
        for x, y in ((2, 1), (2, 2), (1, 3)):
            put(tail, x, y, dark)
    else:
        ellipse(tail, 2.5, 2.5, 1.6, 1.6, main)
    return {"cuerpo": part(body, bpiv), "cabeza": part(heads, (2, 8)), "pata": part(leg, (2, 1)),
            "pata_fondo": part(leg_dark, (2, 1)), "cola": part(tail, (3, 2))}


def cerdo():
    return cuadrupedo("cerdo", hexc("#f4a8bc"), hexc("#d07890"))


def jabali(pal=None):
    main, dark = {None: ("#7a5a3a", "#4a3422"), "fuego": ("#d0461e", "#7a1c14"), "gris": ("#6e6878", "#46404e")}[pal]
    return cuadrupedo("jabali", hexc(main), hexc(dark))


def oveja():
    return cuadrupedo("oveja", hexc("#f0f0f4"), hexc("#b8b8c4"))


# --- Conejo --------------------------------------------------------------------------

def conejo():
    fur, sh = hexc("#f0f0f4"), hexc("#c8c8d4")
    body = blank(12, 9)
    ellipse(body, 6, 4.8, 4.8, 3.6, fur)
    ellipse(body, 1.8, 3.5, 1.4, 1.4, WHITE)
    shade_bottom(body, 1, 0.85)
    heads = []
    for ears_back in (False, True):
        hd = blank(10, 12)
        ellipse(hd, 4.5, 8, 3.2, 2.9, fur)
        if ears_back:
            rect(hd, 0, 4, 4, 1, fur)
            rect(hd, 1, 5, 3, 1, sh)
        else:
            rect(hd, 2, 1, 2, 5, sh)
            rect(hd, 4, 1, 2, 5, fur)
            put(hd, 5, 2, hexc("#f0b0c0"))
            put(hd, 5, 3, hexc("#f0b0c0"))
        eye(hd, 5, 7, False)
        put(hd, 7, 8, hexc("#f090a8"))
        heads.append(hd)
    foot = blank(6, 3)
    rect(foot, 1, 1, 4, 1, sh)
    return {"cuerpo": part(body, (6, 9)), "cabeza": part(heads, (3, 10)), "pie": part(foot, (3, 2))}


# --- Gallina -------------------------------------------------------------------------

def gallina(pal=None):
    if pal == "rey":
        r = ramp("rey")
        main, sh, wing = r[2], r[1], r[3]
    else:
        main, sh, wing = hexc("#f4f4f8"), hexc("#c8c8d4"), hexc("#dcdce4")
    body = blank(12, 10)
    ellipse(body, 6.5, 5.5, 4.6, 3.6, main)
    rect(body, 1, 1, 2, 3, main)
    put(body, 2, 1, wing)
    rect(body, 5, 5, 3, 1, sh)
    put(body, 7, 6, sh)
    shade_bottom(body, 1, 0.85)
    heads = []
    for hurt in (False, True):
        hd = blank(9, 9)
        ellipse(hd, 3.5, 5, 2.6, 2.6, main)
        rect(hd, 2, 1, 2, 2, hexc("#e0303a"))
        put(hd, 3, 0, hexc("#e0303a"))
        rect(hd, 6, 4, 2, 2, hexc("#f0a02a"))
        put(hd, 4, 7, hexc("#e0303a"))
        if pal == "rey":
            rect(hd, 1, 1, 5, 1, hexc("#fff08a"))
            put(hd, 1, 0, hexc("#fff08a"))
            put(hd, 5, 0, hexc("#fff08a"))
        if hurt:
            eye_hurt(hd, 4, 4)
        else:
            eye(hd, 4, 3, False)
            put(hd, 4, 4, INK)
        heads.append(hd)
    leg = blank(5, 5)
    rect(leg, 1, 1, 1, 2, hexc("#f0a02a"))
    rect(leg, 1, 3, 3, 1, hexc("#f0a02a"))
    return {"cuerpo": part(body, (6, 10)), "cabeza": part(heads, (2, 7)), "pata": part(leg, (1, 1))}


# --- Babosa --------------------------------------------------------------------------

def babosa(pal="morada"):
    r = ramp(pal)
    frames = []
    for w, h in ((13, 5), (15, 4), (11, 6)):
        b = blank(17, 8)
        x0 = (17 - w) // 2
        y0 = 7 - h
        rrect(b, x0, y0, w, h, r[2])
        ellipse(b, x0 + w * 0.4, y0 + 1.5, w * 0.3, 1.5, r[3] if pal == "cristal" else mul(r[2], 1.15))
        rect(b, x0, 6, w, 1, r[1])
        frames.append(b)
    heads = []
    for hurt in (False, True):
        hd = blank(7, 8)
        if hurt:
            rect(hd, 1, 4, 3, 3, r[2])
            put(hd, 2, 4, INK)
        else:
            rect(hd, 1, 4, 3, 3, r[2])
            rect(hd, 2, 1, 1, 3, r[2])
            rect(hd, 4, 0, 1, 4, r[2])
            put(hd, 2, 0, WHITE)
            put(hd, 4, 0, INK)
            put(hd, 5, 0, WHITE)
            put(hd, 2, 1, INK)
        heads.append(hd)
    return {"cuerpo": part(frames, (8, 8)), "cabeza": part(heads, (2, 7))}


# --- Insectos voladores ---------------------------------------------------------------

def alas(col, big=False):
    up, down = blank(10, 8), blank(10, 8)
    ellipse(up, 5, 3, 4 if big else 3.4, 2.4, col)
    ellipse(down, 5, 5, 4 if big else 3.4, 1.6, col)
    return [up, down]


def avispa():
    y, k = hexc("#f0c03a"), hexc("#1a1320")
    ab = blank(10, 9)
    ellipse(ab, 5, 4.5, 4, 3.3, y)
    rect(ab, 3, 1, 1, 7, k)
    rect(ab, 6, 1, 1, 7, k)
    put(ab, 0, 5, k)
    put(ab, 1, 5, k)
    heads = []
    for hurt in (False, True):
        hd = blank(8, 8)
        ellipse(hd, 4, 4, 3, 3, k)
        if hurt:
            eye_hurt(hd, 5, 3)
        else:
            rect(hd, 4, 2, 2, 2, hexc("#ff4a3a"))
            put(hd, 5, 2, hexc("#ffd0c0"))
        put(hd, 6, 0, k)
        heads.append(hd)
    # Alas finas y alargadas, casi transparentes.
    wing = []
    for up in (True, False):
        w = blank(10, 8)
        if up:
            ellipse(w, 4, 3, 3.5, 1.6, hexc("#dcefff", 170))
            ellipse(w, 6, 4.5, 2.5, 1.2, hexc("#dcefff", 170))
        else:
            ellipse(w, 5, 5.5, 3.8, 1.2, hexc("#dcefff", 170))
        wing.append(w)
    return {"abdomen": part(ab, (7, 5)), "cabeza": part(heads, (2, 5)), "alas": part(wing, (3, 7))}


def mariposa():
    w1, w2 = hexc("#a05ae0"), hexc("#ff9ae0")
    frames = []
    for ry in (5.0, 3.0, 1.4):
        f = blank(16, 12)
        ellipse(f, 4.5, 6, 4, ry, w1)
        ellipse(f, 11.5, 6, 4, ry, w1)
        if ry > 2:
            rect(f, 3, 5, 2, 2, w2)
            rect(f, 11, 5, 2, 2, w2)
        frames.append(f)
    body = blank(5, 10)
    rect(body, 2, 2, 1, 7, hexc("#1a1320"))
    put(body, 1, 1, hexc("#1a1320"))
    put(body, 3, 1, hexc("#1a1320"))
    return {"alas": part(frames, (8, 6)), "cuerpo": part(body, (2, 5))}


def murcielago(pal="gris"):
    r = ramp(pal)
    frames = []
    for pose in ("up", "mid", "down"):
        f = blank(22, 10)
        for side in (-1, 1):
            cx = 11 + side * 6
            if pose == "up":
                ellipse(f, cx, 3.5, 4.5, 2.5, r[1])
                put(f, cx + side * 4, 1, r[1])
            elif pose == "mid":
                ellipse(f, cx, 5, 5, 1.8, r[1])
            else:
                ellipse(f, cx, 6.5, 4, 2.5, r[1])
                put(f, cx + side * 3, 9, r[1])
        frames.append(f)
    body = blank(10, 10)
    ellipse(body, 5, 5.5, 3.6, 3.4, r[2])
    put(body, 2, 1, r[2])
    put(body, 2, 2, r[2])
    put(body, 7, 1, r[2])
    put(body, 7, 2, r[2])
    put(body, 4, 5, hexc("#ff3a3a"))
    put(body, 6, 5, hexc("#ff3a3a"))
    put(body, 5, 7, WHITE)
    return {"alas": part(frames, (11, 5)), "cuerpo": part(body, (5, 5))}


def hada(imp=False):
    if imp:
        skin, dress, wingc = hexc("#d0461e"), hexc("#7a1c14"), hexc("#3a2e44")
    else:
        skin, dress, wingc = hexc("#e0f4ff"), hexc("#4a8ad0"), hexc("#ffffff", 190)
    head = blank(9, 9)
    ellipse(head, 4.5, 4.5, 3.4, 3.4, skin)
    eye(head, 5, 4, False)
    eye(head, 3, 4, False)
    if imp:
        put(head, 2, 1, hexc("#f4efdc"))
        put(head, 7, 1, hexc("#f4efdc"))
    else:
        rect(head, 2, 1, 5, 1, hexc("#fff08a"))
    body = blank(8, 8)
    rect(body, 2, 1, 4, 3, dress)
    rect(body, 1, 4, 6, 2, dress)
    if imp:
        put(body, 0, 6, hexc("#7a1c14"))
        put(body, 1, 6, hexc("#7a1c14"))
    return {"alas": part(alas(wingc, True), (5, 7)), "cuerpo": part(body, (4, 1)), "cabeza": part(head, (4, 8))}


# --- Cangrejo ------------------------------------------------------------------------

def cangrejo():
    r = ramp("piedra")
    body = blank(16, 10)
    ellipse(body, 8, 6, 6.5, 3.5, r[2])
    ellipse(body, 7, 5, 4.5, 1.8, r[3])
    rect(body, 5, 1, 1, 3, r[2])
    rect(body, 10, 1, 1, 3, r[2])
    put(body, 5, 1, INK)
    put(body, 10, 1, INK)
    shade_bottom(body, 1, 0.8)
    claws = []
    for opened in (False, True):
        c = blank(7, 7)
        ellipse(c, 3.5, 4, 2.6, 2.3, r[1])
        if opened:
            rect(c, 3, 1, 2, 2, r[1])
            put(c, 4, 3, (0, 0, 0, 0))
        claws.append(c)
    legs = []
    for ph in (0, 1):
        l = blank(16, 5)
        for i, x in enumerate((2, 5, 10, 13)):
            dx = (1 if (i + ph) % 2 else -1)
            put(l, x, 1, r[1])
            put(l, x + dx, 2, r[1])
            put(l, x + dx, 3, r[1])
        legs.append(l)
    return {"patas": part(legs, (8, 1)), "cuerpo": part(body, (8, 9)), "pinza": part(claws, (3, 5)),
            "pinza_fondo": part([mirror(c) for c in claws], (3, 5))}


# --- Mímico --------------------------------------------------------------------------

def mimico():
    r = ramp("madera")
    base = blank(18, 10)
    rect(base, 1, 1, 16, 8, r[1])
    rect(base, 1, 1, 16, 1, hexc("#6a0e1e"))
    for x in range(2, 16, 2):
        put(base, x, 2, WHITE)
    rect(base, 1, 5, 16, 1, r[0])
    rect(base, 8, 4, 2, 3, hexc("#f0b93a"))
    shade_bottom(base, 1, 0.8)
    lids = []
    for angry in (False, True):
        lid = blank(18, 8)
        rect(lid, 1, 1, 16, 6, r[2])
        rect(lid, 1, 1, 16, 1, r[3])
        rect(lid, 1, 4, 16, 1, r[1])
        for x in range(3, 16, 2):
            put(lid, x, 6, WHITE)
        if angry:
            rect(lid, 4, 2, 2, 2, hexc("#ff3a3a"))
            rect(lid, 12, 2, 2, 2, hexc("#ff3a3a"))
        lids.append(lid)
    return {"base": part(base, (1, 10)), "tapa": part(lids, (1, 7))}


# --- Seta saltarina ------------------------------------------------------------------

def seta():
    caps = []
    for w, h in ((13, 6), (15, 5)):
        c = blank(17, 8)
        x0 = (17 - w) // 2
        ellipse(c, 8.5, 7 - h * 0.1, w / 2.0, h, hexc("#c0302a"))
        rect(c, x0, 6, w, 1, hexc("#8a1a1a"))
        for x, y in ((5, 3), (6, 3), (10, 2), (12, 4), (8, 5)):
            put(c, x, y, WHITE)
        frames = c
        caps.append(frames)
    stem = blank(9, 8)
    rrect(stem, 1, 1, 7, 5, hexc("#f0e0c8"))
    eye(stem, 4, 2)
    eye(stem, 6, 2)
    rect(stem, 1, 6, 2, 1, hexc("#6a4226"))
    rect(stem, 6, 6, 2, 1, hexc("#6a4226"))
    return {"tallo": part(stem, (4, 7)), "sombrero": part(caps, (8, 7))}


# --- Medusa --------------------------------------------------------------------------

def medusa():
    pink, light = hexc("#f09af0", 235), hexc("#ffd8ff", 235)
    bells = []
    for rx, ry in ((6.5, 4.5), (5.5, 5.2)):
        b = blank(15, 11)
        ellipse(b, 7.5, 6, rx, ry, pink)
        rect(b, 1, 7, 13, 4, (0, 0, 0, 0))
        rect(b, int(7.5 - rx), 7, int(rx * 2), 1, mul(pink, 0.8))
        ellipse(b, 6, 4, 2.5, 1.3, light)
        eye(b, 5, 5, False)
        eye(b, 9, 5, False)
        bells.append(b)
    tent = []
    for ph in (0, 1):
        t = blank(4, 10)
        for y in range(1, 9):
            x = 1 + ((y // 2 + ph) % 2)
            put(t, x, y, pink)
        tent.append(t)
    return {"campana": part(bells, (7, 8)), "tentaculo": part(tent, (2, 1))}


# --- Dragón --------------------------------------------------------------------------

def dragon(pal="fuego"):
    r = ramp(pal)
    body = blank(18, 11)
    ellipse(body, 9, 6, 7.5, 4.2, r[1])
    ellipse(body, 9, 8, 5.5, 2, r[3] if pal != "negro" else r[2])
    for x in range(3, 15, 3):
        put(body, x, 1, r[2])
    heads = []
    for open_ in (False, True):
        hd = blank(12, 10)
        ellipse(hd, 5, 4.5, 4, 3.3, r[1])
        rect(hd, 7, 4, 4, 2, r[1])
        if open_:
            rect(hd, 7, 7, 4, 1, r[1])
            rect(hd, 8, 6, 3, 1, hexc("#6a0e1e"))
            put(hd, 11, 6, hexc("#ffd24a"))
        else:
            rect(hd, 7, 6, 4, 1, r[0])
        rect(hd, 5, 3, 2, 1, hexc("#fff27a"))
        put(hd, 6, 3, INK)
        put(hd, 2, 0, r[3])
        put(hd, 3, 1, r[3])
        heads.append(hd)
    wings = []
    for up in (True, False):
        w = blank(14, 11)
        if up:
            for i in range(6):
                rect(w, 3 + i, 1 + i, 2, 8 - i, r[0])
            rect(w, 3, 1, 8, 1, r[2])
        else:
            for i in range(5):
                rect(w, 2 + i, 5, 2, 5 - i, r[0])
            rect(w, 2, 5, 9, 1, r[2])
        wings.append(w)
    tail = blank(12, 6)
    rect(tail, 1, 3, 3, 1, r[1])
    rect(tail, 3, 2, 5, 2, r[1])
    rect(tail, 7, 1, 4, 3, r[1])
    put(tail, 1, 2, r[2])
    leg = blank(5, 6)
    rect(leg, 1, 1, 3, 3, r[0])
    rect(leg, 1, 4, 3, 1, hexc("#f4efdc"))
    return {"cola": part(tail, (10, 3)), "ala_fondo": part([tint(w, 0.7) for w in wings], (4, 9)), "pata": part(leg, (2, 1)),
            "cuerpo": part(body, (9, 6)), "cabeza": part(heads, (2, 7)), "ala": part(wings, (4, 9))}


# --- Gólem de cristal ----------------------------------------------------------------

def golem():
    r = ramp("cristal")
    torso = blank(20, 15)
    rrect(torso, 1, 1, 18, 12, r[2])
    rect(torso, 2, 1, 10, 2, r[3])
    rect(torso, 14, 3, 4, 9, r[1])
    for x, y in ((5, 6), (9, 9), (12, 5)):
        rect(torso, x, y, 2, 1, r[3])
    head = blank(11, 9)
    rrect(head, 1, 1, 9, 7, r[2])
    rect(head, 2, 1, 5, 1, r[3])
    rect(head, 6, 3, 3, 2, WHITE)
    put(head, 7, 4, r[1])
    arm = blank(7, 13)
    rrect(arm, 1, 1, 5, 11, r[1])
    rect(arm, 1, 8, 5, 3, r[2])
    leg = blank(8, 8)
    rrect(leg, 1, 1, 6, 6, r[1])
    rect(leg, 1, 5, 6, 1, r[0])
    return {"brazo_fondo": part(arm, (3, 2)), "pierna": part(leg, (4, 1)), "torso": part(torso, (10, 14)),
            "cabeza": part(head, (5, 8)), "brazo": part(arm, (3, 2))}


# --- Calavera voladora -----------------------------------------------------------------

def calavera(pal=None):
    bone = ramp("hueso")[2] if pal != "guardian" else ramp("guardian")[1]
    glow = hexc("#e05a9a") if pal != "guardian" else hexc("#ff2a4a")
    skulls = []
    for bright in (False, True):
        s = blank(16, 13)
        ellipse(s, 8, 6, 7, 5.6, bone)
        rect(s, 3, 5, 4, 3, INK)
        rect(s, 9, 5, 4, 3, INK)
        rect(s, 4, 6, 2, 1, glow if not bright else WHITE)
        rect(s, 10, 6, 2, 1, glow if not bright else WHITE)
        put(s, 8, 9, INK)
        if pal == "guardian":
            for x in (3, 6, 9, 12):
                put(s, x, 0, glow)
        skulls.append(s)
    jaw = blank(12, 5)
    rrect(jaw, 1, 1, 10, 3, bone)
    for x in (3, 5, 7, 9):
        put(jaw, x, 1, INK)
    return {"mandibula": part(jaw, (6, 1)), "craneo": part(skulls, (8, 11))}


# --- Gusano de ceniza ----------------------------------------------------------------

def gusano():
    r = ramp("ceniza")
    seg = blank(13, 9)
    ellipse(seg, 6.5, 4.5, 5.5, 3.5, r[2])
    rect(seg, 2, 6, 9, 1, r[1])
    ellipse(seg, 5, 3, 2.5, 1, r[3])
    heads = []
    for open_ in (False, True):
        hd = blank(14, 11)
        ellipse(hd, 7, 5.5, 6, 4.5, r[1])
        if open_:
            rect(hd, 3, 5, 8, 4, hexc("#6a0e1e"))
            for x in range(3, 11, 2):
                put(hd, x, 5, WHITE)
                put(hd, x + 1, 8, WHITE)
        else:
            rect(hd, 3, 7, 8, 1, INK)
        rect(hd, 4, 3, 2, 1, hexc("#ff2a4a"))
        rect(hd, 9, 3, 2, 1, hexc("#ff2a4a"))
        heads.append(hd)
    return {"segmento": part(seg, (6, 4)), "cabeza": part(heads, (7, 9))}


# --- Tiranodonte ---------------------------------------------------------------------

def tiranodonte():
    g, d, belly = hexc("#4a8a3a"), hexc("#2a5a24"), hexc("#c0d08a")
    body = blank(24, 18)
    ellipse(body, 12, 9, 10.5, 7.5, g)
    ellipse(body, 13, 12.5, 7, 3.5, belly)
    for i, x in enumerate(range(5, 19, 3)):
        put(body, x, 1 + (i % 2), hexc("#e05a3a"))
    heads = []
    for open_ in (False, True):
        hd = blank(20, 14)
        ellipse(hd, 8, 5.5, 7.5, 4.5, g)
        rect(hd, 8, 4, 10, 4, g)
        rect(hd, 6, 3, 3, 2, hexc("#ffd24a"))
        put(hd, 8, 3, INK)
        if open_:
            rect(hd, 8, 8, 10, 1, hexc("#6a0e1e"))
            rect(hd, 8, 11, 10, 2, d)
            for x in range(9, 18, 2):
                put(hd, x, 8, WHITE)
                put(hd, x, 10, WHITE)
            rect(hd, 8, 9, 10, 1, hexc("#6a0e1e"))
        else:
            rect(hd, 8, 8, 10, 2, d)
            for x in range(9, 18, 2):
                put(hd, x, 8, WHITE)
        heads.append(hd)
    leg = blank(9, 11)
    rrect(leg, 1, 1, 6, 7, g)
    rect(leg, 1, 8, 8, 2, d)
    tail = blank(16, 8)
    rect(tail, 1, 4, 4, 2, g)
    rect(tail, 4, 3, 6, 3, g)
    rect(tail, 9, 1, 6, 5, g)
    arm = blank(6, 6)
    rect(arm, 1, 1, 2, 3, d)
    rect(arm, 2, 3, 3, 1, d)
    return {"cola": part(tail, (14, 4)), "pierna_fondo": part(leg, (4, 1)), "cuerpo": part(body, (12, 16)),
            "pierna": part(leg, (4, 1)), "brazo": part(arm, (2, 1)), "cabeza": part(heads, (4, 10))}


CRIATURAS = {
    "cerdo": cerdo, "jabali": jabali, "jabali_fuego": lambda: jabali("fuego"), "jabali_gris": lambda: jabali("gris"),
    "oveja": oveja, "conejo": conejo, "gallina": gallina, "gallina_rey": lambda: gallina("rey"),
    "babosa": babosa, "babosa_cristal": lambda: babosa("cristal"), "avispa": avispa, "mariposa": mariposa,
    "murcielago": murcielago, "murcielago_cristal": lambda: murcielago("cristal"),
    "hada": hada, "diablillo": lambda: hada(True), "cangrejo": cangrejo, "mimico": mimico,
    "seta_bicho": seta, "medusa": medusa, "dragon": dragon, "dragon_negro": lambda: dragon("negro"),
    "golem": golem, "calavera": calavera, "calavera_guardian": lambda: calavera("guardian"),
    "gusano": gusano, "tiranodonte": tiranodonte,
}
