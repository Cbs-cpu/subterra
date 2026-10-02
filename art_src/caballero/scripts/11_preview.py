# Renderiza fotogramas de cada animación de raw/anim.blend (vista lateral 3/4) en render/frames/.
# ANIMS=idle,run limita las animaciones; N=8 fotogramas por animación.
import bpy, os, sys
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
import rlib

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "render", "frames")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "anim.blend"))
scn = bpy.context.scene
arm = bpy.data.objects["Rig"]
rlib.setup()
scn.render.resolution_x, scn.render.resolution_y = 300, 450
cam = bpy.data.objects["cam"]
cam.data.ortho_scale = 2.3
# el personaje mira a -Y; en el juego mira a la derecha de la pantalla con giro 3/4 a cámara
d = Vector(tuple(map(float, os.environ.get("CAMDIR", "1,-0.55,0.15").split(",")))).normalized()
cam.location = Vector((0, 0, 0.95)) + d * 6
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
only = os.environ.get("ANIMS")
n = int(os.environ.get("N", "8"))
for tr in arm.animation_data.nla_tracks:
    tr.mute = True
for act in bpy.data.actions:
    if only and act.name not in only.split(","):
        continue
    arm.animation_data.action = act
    a, b = act.frame_range
    for i in range(n):
        f = a + (b - a) * i / (n - 1 if act.name in ("jump", "fall", "down", "attack", "attack_pick", "punch", "chop", "hurt") else n)
        scn.frame_set(int(f), subframe=f - int(f))
        scn.render.filepath = os.path.join(OUT, f"{act.name}{os.environ.get('TAG', '')}_{i:02d}.png")
        bpy.ops.render.render(write_still=True)
    print("PREVIEW", act.name)
