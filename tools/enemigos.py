"""Piezas de pixel art de los enemigos (estilo del Minero: gordito y con contorno negro).

Cada enemigo se monta en Godot con estas piezas y se anima con un AnimationPlayer
(tools/build_enemy_rig.gd). Una pieza con varios fotogramas se guarda como tira horizontal
(Sprite2D.hframes) y el AnimationPlayer cambia de fotograma: así se aplasta o parpadea sin
deformar los píxeles.

Uso: python tools/enemigos.py [enemigo]
Escribe assets/sprites/enemigos/<enemigo>/<pieza>.png y shots/enemigo_<enemigo>_piezas.png.
"""
import json
import os
import sys

from PIL import Image

OUT = "assets/sprites/enemigos"
INK = (14, 10, 10, 255)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def ink(im):
    """Contorno negro de 1 px alrededor de todo lo opaco."""
    src = im.copy()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3] > 0:
                    im.putpixel((x, y), INK)
                    break
    return im


def strip(frames):
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * w, 0))
    return out


# --- Limo -------------------------------------------------------------------------------

LIMO = {"base": hexc("#5ec24a"), "luz": hexc("#9ae070"), "brillo": hexc("#e0ffc0"),
        "sombra": hexc("#3a8a2e"), "hondo": hexc("#2a6a24")}


def limo_cuerpo(bw, bh, pal=LIMO, cw=18, ch=14):
    """Gota de bw x bh por dentro, apoyada abajo al centro de un lienzo cw x ch."""
    im = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    x0 = (cw - bw) // 2
    y0 = ch - 1 - bh            # deja la fila de abajo para el contorno
    cx = x0 + bw / 2.0
    top_r = bh * 0.62
    for y in range(y0, y0 + bh):
        for x in range(x0, x0 + bw):
            fy = y - y0
            inside = True
            if fy < top_r:
                # cúpula redondeada arriba
                dx = (x + 0.5 - cx) / (bw / 2.0)
                dy = (top_r - (fy + 0.5)) / top_r
                inside = dx * dx + dy * dy <= 1.0
            elif fy == bh - 1 and (x == x0 or x == x0 + bw - 1):
                inside = False       # esquinas de abajo redondeadas
            if not inside:
                continue
            c = pal["base"]
            if fy >= bh - 2:
                c = pal["sombra"]
            if x >= x0 + bw - 2 and fy >= 2:
                c = pal["sombra"]
            if fy == bh - 1:
                c = pal["hondo"]
            im.putpixel((x, y), c)
    # luz arriba a la izquierda y brillo
    for y in range(y0, y0 + bh):
        for x in range(x0, x0 + bw):
            if im.getpixel((x, y))[3] == 0:
                continue
            fy, fx = y - y0, x - x0
            if fy <= 1 and fx <= bw // 2 and im.getpixel((x, y)) == pal["base"]:
                im.putpixel((x, y), pal["luz"])
    bx, by = x0 + max(1, bw // 4), y0 + 1 + (1 if bh > 7 else 0)
    for dx, dy in ((0, 0), (1, 0), (0, 1)):
        if im.getpixel((bx + dx, by + dy))[3]:
            im.putpixel((bx + dx, by + dy), pal["brillo"])
    return ink(im)


def limo_ojos():
    """Dos ojos de 2x2 con brillo; fotograma 0 abiertos, 1 cerrados, 2 aturdidos (x)."""
    w, h = 8, 3
    E, W = INK, (255, 255, 255, 255)
    frames = []
    for kind in ("abiertos", "cerrados", "aturdidos"):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        for ox in (0, 5):
            if kind == "abiertos":
                for dx, dy in ((0, 1), (1, 1), (0, 2), (1, 2)):
                    im.putpixel((ox + dx, dy), E)
                im.putpixel((ox + 1, 1), W)
            elif kind == "cerrados":
                im.putpixel((ox, 2), E)
                im.putpixel((ox + 1, 2), E)
            else:
                im.putpixel((ox, 0), E)
                im.putpixel((ox + 1, 1), E)
                im.putpixel((ox, 2), E)
                im.putpixel((ox + 2, 0), E) if ox + 2 < w else None
                im.putpixel((ox + 2, 2), E) if ox + 2 < w else None
        frames.append(im)
    return strip(frames)


LIMO_AZUL = {"base": hexc("#4aa0e8"), "luz": hexc("#8ac8ff"), "brillo": hexc("#e8f6ff"),
             "sombra": hexc("#2a70b8"), "hondo": hexc("#1a4a8a")}


def limo(pal=LIMO):
    # Cuerpo: 0 normal, 1 aplastado, 2 estirado, 3 muy aplastado (aterrizaje).
    cuerpo = strip([limo_cuerpo(12, 9, pal), limo_cuerpo(14, 7, pal), limo_cuerpo(10, 11, pal), limo_cuerpo(16, 6, pal)])
    return {"cuerpo": cuerpo, "ojos": limo_ojos()}


# --- Utilidades de dibujo ---------------------------------------------------------------

def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def ellipse(im, cx, cy, rx, ry, c):
    for y in range(im.height):
        for x in range(im.width):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1.0:
                im.putpixel((x, y), c)


def rect(im, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            put(im, xx, yy, c)


def mirror(im):
    return im.transpose(Image.FLIP_LEFT_RIGHT)


def tint(im, f):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b, a) != INK:
                px[x, y] = (int(r * f), int(g * f), int(b * f), a)
    return out


# --- Araña ------------------------------------------------------------------------------

ARANA = {"verde": ["#1a4a1a", "#3a8a2a", "#6ac04a", "#b8f08a"],
         "morada": ["#2e1a4a", "#5a2a8a", "#8a4ac0", "#d0a0f0"],
         "madre": ["#2a0e2a", "#5a1a4a", "#9a2a6a", "#e05aa0"]}


def arana(pal="verde"):
    r = [hexc(c) for c in ARANA[pal]]
    ojo = hexc("#ff3a3a")
    # Abdomen redondo con manchas y brillo.
    ab = blank(14, 11)
    ellipse(ab, 7, 5.5, 6, 4.5, r[1])
    ellipse(ab, 6, 4.5, 4.5, 3, r[2])
    for x, y in ((5, 4), (8, 5), (6, 7), (9, 3)):
        put(ab, x, y, r[3] if (x + y) % 2 else r[1])
    put(ab, 4, 2, r[3])
    put(ab, 5, 2, r[3])
    rect(ab, 2, 8, 10, 1, r[0])
    ink(ab)
    # Cabeza con ojos rojos grandes y colmillos. Fotogramas: 0 normal, 1 aturdida.
    frames = []
    for kind in ("normal", "aturdida"):
        c = blank(11, 10)
        ellipse(c, 5.5, 4.5, 4.5, 3.8, r[1])
        ellipse(c, 5, 3.5, 3, 2, r[2])
        if kind == "normal":
            rect(c, 5, 3, 2, 2, ojo)
            rect(c, 2, 3, 2, 2, ojo)
            put(c, 6, 3, (255, 210, 200, 255))
            put(c, 3, 3, (255, 210, 200, 255))
        else:
            for x, y in ((5, 3), (6, 4), (5, 5), (7, 3), (7, 5), (2, 3), (3, 4), (2, 5)):
                put(c, x, y, INK)
        put(c, 6, 8, hexc("#f4efdc"))
        put(c, 8, 7, hexc("#f4efdc"))
        frames.append(ink(c))
    cabeza = strip(frames)
    # Pata gruesa (2 px): sale del cuerpo, sube a la rodilla y baja al suelo.
    pata = blank(10, 9)
    leg = tuple((a + b) // 2 for a, b in zip(r[0], r[1]))
    for x, y in ((3, 1), (4, 1), (2, 2), (3, 2), (4, 2), (5, 2), (1, 3), (2, 3), (5, 3), (6, 3),
                 (1, 4), (6, 4), (7, 4), (6, 5), (7, 5), (7, 6), (8, 6), (8, 7)):
        put(pata, x, y, leg)
    for x, y in ((3, 1), (4, 1)):
        put(pata, x, y, r[1])
    ink(pata)
    return {"abdomen": ab, "cabeza": cabeza, "pata": pata, "pata_atras": tint(mirror(pata), 0.7),
            "pata_fondo": tint(pata, 0.7), "pata_trasera": mirror(pata)}


# Carpeta -> función. Las variantes de color (<enemigo>_<paleta>) usan la escena del
# enemigo base y solo cambian las texturas.
ENEMIGOS = {"limo": limo, "limo_azul": lambda: limo(LIMO_AZUL),
            "arana": arana, "arana_morada": lambda: arana("morada"), "arana_madre": lambda: arana("madre")}

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemigos_criaturas import CRIATURAS  # noqa: E402
ENEMIGOS.update(CRIATURAS)


def preview(name, parts, z=10):
    ims = [v[0] if isinstance(v, tuple) else v for v in parts.values()]
    w = sum(i.width for i in ims) + 20 * (len(ims) + 1)
    h = max(i.height for i in ims) + 40
    out = Image.new("RGBA", (w, h), (34, 30, 44, 255))
    x = 20
    for im in ims:
        out.alpha_composite(im, (x, 20))
        x += im.width + 20
    out = out.resize((out.width * z // 2, out.height * z // 2), Image.NEAREST)
    out.save("shots/enemigo_%s_piezas.png" % name)


if __name__ == "__main__":
    names = sys.argv[1:] or list(ENEMIGOS)
    for n in names:
        parts = ENEMIGOS[n]()
        d = os.path.join(OUT, n)
        os.makedirs(d, exist_ok=True)
        meta = {}
        for pn, im in parts.items():
            if isinstance(im, tuple):
                im, pivot, frames = im
                meta[pn] = {"pivot": list(pivot), "frames": frames}
            im.save(os.path.join(d, pn + ".png"))
        if meta:
            with open(os.path.join(d, "piezas.json"), "w", encoding="utf-8") as f:
                json.dump(meta, f, indent=1)
        os.makedirs("shots", exist_ok=True)
        preview(n, parts)
        print(n, "->", d, list(parts))
