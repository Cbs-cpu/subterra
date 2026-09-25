"""Piezas sueltas del personaje principal (estilo "marioneta": se unirán en Godot con
un esqueleto y se animarán con el AnimationPlayer). Todavía NO se usan en el juego.

Cada pieza es un sprite pequeño y gordito con contorno oscuro, mirando a la derecha.
Uso: python tools/pj_partes.py [pieza]
Escribe art_src/pj_partes/<pieza>.png y una vista ampliada en shots/pj_<pieza>.png.
"""
import os
import sys

from PIL import Image, ImageDraw

OUT = "art_src/pj_partes"
PAL = {
    "O": (14, 10, 10),      # contorno negro
    "H": (107, 69, 38),     # pelo
    "h": (143, 98, 54),     # pelo con luz
    "G": (46, 154, 46),     # banda verde
    "g": (88, 184, 72),     # banda con luz
    "d": (28, 90, 28),      # banda en sombra
    "E": (10, 8, 8),        # ojo
    "S": (242, 201, 160),   # piel
    "s": (217, 168, 130),   # piel en sombra
    "m": (170, 96, 80),     # boca
}

PARTES = {
    # Cabeza cuadrada y frontal con pocos píxeles (6x6 por dentro): mechón de pelo arriba,
    # banda verde con los ojos y sus puntas ondeando detrás, y la cara con sombra a la
    # izquierda y una boquita.
    "cabeza": [
        "......OO..",
        "..OOOOHhOO",
        "..OHHHHhhO",
        "..OHHHHHhO",
        "OOOGGGGggO",
        "OGGGEGGEgO",
        "OdOssSSSSO",
        ".OOssSmSSO",
        "..OOOOOOOO",
    ],
}


def build(name):
    rows = PARTES[name]
    w, h = max(len(r) for r in rows), len(rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in PAL:
                im.putpixel((x, y), PAL[ch] + (255,))
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name + ".png"))
    return im


def preview(name, im, z=24):
    """Vista: la pieza ampliada con rejilla y, al lado, a tamaño de juego (x3) junto a un tile de 16 px."""
    w, h = im.size
    pad = 24
    big = im.resize((w * z, h * z), Image.NEAREST)
    game = im.resize((w * 3, h * 3), Image.NEAREST)
    W = pad * 3 + big.width + 16 * 3 + game.width + 20
    H = pad * 2 + max(big.height, 16 * 3 + game.height)
    out = Image.new("RGBA", (W, H), (34, 30, 44, 255))
    d = ImageDraw.Draw(out)
    # damero bajo la pieza ampliada para ver la transparencia
    for y in range(h):
        for x in range(w):
            c = (46, 42, 58, 255) if (x + y) % 2 else (40, 36, 52, 255)
            d.rectangle([pad + x * z, pad + y * z, pad + (x + 1) * z - 1, pad + (y + 1) * z - 1], fill=c)
    out.alpha_composite(big, (pad, pad))
    for x in range(w + 1):
        d.line([pad + x * z, pad, pad + x * z, pad + h * z], fill=(0, 0, 0, 60))
    for y in range(h + 1):
        d.line([pad, pad + y * z, pad + w * z, pad + y * z], fill=(0, 0, 0, 60))
    # tamaño real en el juego (x3) sobre un tile de tierra de 16 px
    gx = pad * 2 + big.width
    gy = pad + max(0, big.height - 16 * 3 - game.height)
    out.alpha_composite(game, (gx + 12, gy))
    d.rectangle([gx, gy + game.height, gx + 16 * 3 - 1, gy + game.height + 16 * 3 - 1], fill=(92, 62, 40, 255))
    d.rectangle([gx, gy + game.height, gx + 16 * 3 - 1, gy + game.height + 5], fill=(96, 170, 60, 255))
    os.makedirs("shots", exist_ok=True)
    out.save("shots/pj_%s.png" % name)


if __name__ == "__main__":
    names = sys.argv[1:] or list(PARTES)
    for n in names:
        preview(n, build(n))
        print(n, "->", os.path.join(OUT, n + ".png"))
