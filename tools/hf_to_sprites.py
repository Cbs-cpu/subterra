"""Convierte el render de HyperFrames del personaje (art_src/pj_hf) en sprites de pixel art.

Uso (desde la raíz del repo):
    cd art_src/pj_hf
    npx hyperframes render --format png-sequence --fps 24 --output ../../.hf_out/sprite
    npx hyperframes render --format png-sequence --fps 24 --variables '{"markers":true}' --output ../../.hf_out/markers
    cd ../.. && python tools/hf_to_sprites.py

Muestrea el centro de cada bloque de 10x10 (el SVG se dibujó x10), umbraliza la transparencia,
aplica el mismo sombreado de bordes que el arte del juego (Pix.outline) y guarda un fotograma de
cada dos (24 fps -> 12 fps). La pasada de marcadores da la posición de la mano (magenta) y de la
parte alta de la cabeza (cian) en cada fotograma, para colocar armas y sombreros.
"""
import glob
import json
import os

from PIL import Image

SCALE = 10
W, H = 24, 24
SEGMENTS = [("idle", 16), ("run", 16), ("jump", 4), ("fall", 4),
            ("attack", 12), ("hurt", 4), ("dash", 4), ("down", 4)]
SRC = ".hf_out/sprite"
MARK = ".hf_out/markers"
OUT = "assets/sprites/pj"


def downsample(img):
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x * SCALE + SCALE // 2, y * SCALE + SCALE // 2]
            if a >= 128:
                out.putpixel((x, y), (r, g, b, 255))
    return out


def shade(img):
    """Oscurece los bordes que dan al vacío por abajo/derecha y aclara los de arriba/izquierda."""
    src = img.copy()
    s = src.load()
    d = img.load()

    def empty(x, y):
        return x < 0 or y < 0 or x >= W or y >= H or s[x, y][3] == 0

    for y in range(H):
        for x in range(W):
            r, g, b, a = s[x, y]
            if a == 0:
                continue
            if empty(x, y + 1) or empty(x + 1, y):
                f = 0.68
                d[x, y] = (int(r * f), int(g * f), int(b * f), 255)
            elif empty(x, y - 1) or empty(x - 1, y):
                d[x, y] = (min(255, int(r + (255 - r) * 0.14)), min(255, int(g + (255 - g) * 0.14)),
                           min(255, int(b + (255 - b) * 0.14)), 255)
    return img


def anchor(img, target):
    """Centro (en píxeles del sprite) de los píxeles cercanos al color clave."""
    px = img.load()
    xs, ys = [], []
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a > 100 and abs(r - target[0]) < 70 and abs(g - target[1]) < 70 and abs(b - target[2]) < 70:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return [round(sum(xs) / len(xs) / SCALE - 0.5), round(sum(ys) / len(ys) / SCALE - 0.5)]


def main():
    frames = sorted(glob.glob(os.path.join(SRC, "*.png")))
    marks = sorted(glob.glob(os.path.join(MARK, "*.png")))
    total = sum(n for _, n in SEGMENTS)
    assert len(frames) >= total and len(marks) >= total, "faltan fotogramas: %d/%d" % (len(frames), total)
    os.makedirs(OUT, exist_ok=True)
    # Los pies están en y=19 del lienzo original (viewBox desplazado 4): y=23 aquí.
    meta = {"size": [W, H], "origin": [12, 23], "fps": 12, "anims": {}}
    i = 0
    sheet = []
    for name, n in SEGMENTS:
        meta["anims"][name] = []
        for k in range(0, n, 2):
            spr = shade(downsample(Image.open(frames[i + k]).convert("RGBA")))
            mk = Image.open(marks[i + k]).convert("RGBA")
            hand = anchor(mk, (255, 0, 255)) or [13, 16]
            head = anchor(mk, (0, 255, 255)) or [12, 4]
            fname = "%s_%d.png" % (name, k // 2)
            spr.save(os.path.join(OUT, fname))
            meta["anims"][name].append({"file": fname, "hand": hand, "head": head})
            sheet.append(spr)
        i += n
    with open(os.path.join(OUT, "anims.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    # Hoja de revisión ampliada.
    cols = 8
    rows = (len(sheet) + cols - 1) // cols
    prev = Image.new("RGBA", (cols * (W + 2), rows * (H + 2)), (40, 34, 48, 255))
    for j, s in enumerate(sheet):
        prev.alpha_composite(s, ((j % cols) * (W + 2) + 1, (j // cols) * (H + 2) + 1))
    prev.resize((prev.width * 8, prev.height * 8), Image.NEAREST).save(".hf_out/revision.png")
    print("sprites:", len(sheet), "->", OUT)


if __name__ == "__main__":
    main()
