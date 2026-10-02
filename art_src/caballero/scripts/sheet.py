# Monta las tiras de render/frames/<anim>_NN.png en render/anim_<anim>.png (una fila por animación).
import os, sys, glob, re
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FR = os.path.join(ROOT, "render", "frames")
names = sorted({re.sub(r"_\d\d\.png$", "", os.path.basename(p)) for p in glob.glob(os.path.join(FR, "*_??.png"))})
if len(sys.argv) > 1:
    names = [n for n in names if n in sys.argv[1].split(",")]
rows = []
for n in names:
    fs = sorted(glob.glob(os.path.join(FR, f"{n}_??.png")))
    ims = [Image.open(f).convert("RGB") for f in fs]
    w, h = ims[0].size
    row = Image.new("RGB", (w * len(ims), h))
    for i, im in enumerate(ims):
        row.paste(im, (i * w, 0))
    ImageDraw.Draw(row).text((4, 4), n, fill=(255, 255, 0))
    rows.append(row)
W = max(r.size[0] for r in rows)
out = Image.new("RGB", (W, sum(r.size[1] for r in rows)))
y = 0
for r in rows:
    out.paste(r, (0, y))
    y += r.size[1]
p = os.path.join(ROOT, "render", "anims_" + ("_".join(names) if len(names) < 4 else "all") + ".png")
out.save(p)
print(p)
