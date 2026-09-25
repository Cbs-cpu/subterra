"""Junta una carpeta de fotogramas PNG en un GIF animado.

Uso: python tools/frames_to_gif.py shots/rig_gif shots/rig_anims.gif [fps]
"""
import glob
import os
import sys

from PIL import Image


def main():
    src, out = sys.argv[1], sys.argv[2]
    fps = int(sys.argv[3]) if len(sys.argv) > 3 else 24
    files = sorted(glob.glob(os.path.join(src, "*.png")))
    frames = [Image.open(f).convert("RGB").quantize(colors=128, method=Image.Quantize.MEDIANCUT) for f in files]
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=int(1000 / fps), loop=0, optimize=True)
    print(out, len(frames), "fotogramas")


if __name__ == "__main__":
    main()
