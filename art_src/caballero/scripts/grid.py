# Dibuja una rejilla métrica sobre renders ortográficos y los une en una tira.
# python grid.py salida.png [--c cx cz ortho step] a.png b.png ...
# (cx = coordenada horizontal del centro de la imagen, cz = vertical, ortho = alto visible)
import sys
from PIL import Image, ImageDraw

args = sys.argv[1:]
out = args.pop(0)
cx, cz, ortho, step = 0.0, 0.95, 1.9 * 1.1, 0.1
if args and args[0] == "--c":
    cx, cz, ortho, step = map(float, args[1:5])
    args = args[5:]


def grid(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    ppm = h / ortho
    d = ImageDraw.Draw(im)
    n = int(ortho / step) + 2
    for i in range(-n, n + 1):
        vz = round(cz / step) * step + i * step
        y = h / 2 - (vz - cz) * ppm
        if 0 <= y < h:
            d.line([(0, y), (w, y)], fill=(150, 150, 0), width=1)
            d.text((2, y - 10), f"{vz:.2f}", fill=(255, 255, 0))
        vx = round(cx / step) * step + i * step
        x = w / 2 + (vx - cx) * ppm
        if 0 <= x < w:
            d.line([(x, 0), (x, h)], fill=(0, 130, 130), width=1)
            d.text((x + 2, 2 + (i % 2) * 10), f"{vx:.2f}", fill=(0, 255, 255))
    return im


ims = [grid(p) for p in args]
s = Image.new("RGB", (sum(i.size[0] for i in ims), ims[0].size[1]))
x = 0
for i in ims:
    s.paste(i, (x, 0))
    x += i.size[0]
s.save(out)
