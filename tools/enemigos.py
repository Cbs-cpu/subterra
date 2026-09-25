"""Piezas de pixel art de los enemigos (estilo del Minero: gordito y con contorno negro).

Cada enemigo se monta en Godot con estas piezas y se anima con un AnimationPlayer
(tools/build_enemy_rig.gd). Una pieza con varios fotogramas se guarda como tira horizontal
(Sprite2D.hframes) y el AnimationPlayer cambia de fotograma: así se aplasta o parpadea sin
deformar los píxeles.

Uso: python tools/enemigos.py [enemigo]
Escribe assets/sprites/enemigos/<enemigo>/<pieza>.png y shots/enemigo_<enemigo>_piezas.png.
"""
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


def limo():
    # Cuerpo: 0 normal, 1 aplastado, 2 estirado, 3 muy aplastado (aterrizaje).
    cuerpo = strip([limo_cuerpo(12, 9), limo_cuerpo(14, 7), limo_cuerpo(10, 11), limo_cuerpo(16, 6)])
    return {"cuerpo": cuerpo, "ojos": limo_ojos()}


ENEMIGOS = {"limo": limo}


def preview(name, parts, z=10):
    ims = list(parts.values())
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
        for pn, im in parts.items():
            im.save(os.path.join(d, pn + ".png"))
        os.makedirs("shots", exist_ok=True)
        preview(n, parts)
        print(n, "->", d, list(parts))
