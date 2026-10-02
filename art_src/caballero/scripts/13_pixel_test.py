# Render a tamaño de juego: el personaje mide PX píxeles de alto (render pequeño, sin suavizado).
import bpy, os, sys
from mathutils import Vector
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
import rlib

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "render", "pixel")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "anim.blend"))
scn = bpy.context.scene
arm = bpy.data.objects["Rig"]
rlib.setup()
scn.render.film_transparent = True
scn.render.filter_size = 0.0
for tr in arm.animation_data.nla_tracks:
    tr.mute = True
cam = bpy.data.objects["cam"]
d = Vector((1, -0.45, 0.12)).normalized()
cam.location = Vector((0, 0, 0.95)) + d * 6
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
for px in (40, 30):
    S = 64
    scn.render.resolution_x = scn.render.resolution_y = S
    cam.data.ortho_scale = 1.9 * S / px
    for anim, f in (("idle", 0), ("run", 7), ("run", 35), ("attack", 15), ("chop", 13), ("jump", 30)):
        arm.animation_data.action = bpy.data.actions[anim]
        scn.frame_set(f)
        scn.render.filepath = os.path.join(OUT, f"px{px}_{anim}{f}.png")
        bpy.ops.render.render(write_still=True)
print("DONE")
