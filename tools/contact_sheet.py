"""Hojas de revisión del arte exportado (art_export/ -> shots/hoja_*.png).

Uso: python tools/contact_sheet.py   (antes: godot --headless --path . -s res://tools/export_art.gd)
"""
import glob
import os

from PIL import Image

GROUPS = {
    "humanoides": ["art_export/raza_*_idle_0.png", "art_export/hum_*_run_0.png"],
    "correr": ["art_export/hum_vecino_run_*.png", "art_export/hum_esqueleto_run_*.png", "art_export/raza_*_run_*.png"],
    "criaturas": ["art_export/enemigo_*_0.png"],
    "objetos": ["art_export/objeto_*.png"],
    "props": ["art_export/arbol_*.png", "art_export/roca_*.png", "art_export/sombrero_*.png", "art_export/companero_*.png"],
}


def sheet(name, patterns, cols=12, z=4, limit=96):
    files = []
    for p in patterns:
        files += sorted(glob.glob(p))
    files = files[:limit]
    if not files:
        return
    ims = [Image.open(f).convert("RGBA") for f in files]
    cw = max(i.width for i in ims) + 4
    ch = max(i.height for i in ims) + 4
    rows = (len(ims) + cols - 1) // cols
    out = Image.new("RGBA", (cols * cw, rows * ch), (58, 54, 70, 255))
    for k, im in enumerate(ims):
        out.alpha_composite(im, ((k % cols) * cw + (cw - im.width) // 2, (k // cols) * ch + ch - 2 - im.height))
    out = out.resize((out.width * z, out.height * z), Image.NEAREST)
    os.makedirs("shots", exist_ok=True)
    out.save("shots/hoja_%s.png" % name)
    print(name, len(ims), out.size)


if __name__ == "__main__":
    for n, p in GROUPS.items():
        sheet(n, p)
