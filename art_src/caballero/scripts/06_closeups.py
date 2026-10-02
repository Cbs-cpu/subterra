# Primeros planos de mano izquierda (+X), pie y cabeza para colocar huesos.
import bpy, os, sys
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import rlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "render")
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "base.blend"))
rlib.setup()
bpy.context.scene.render.resolution_x = 900
# mano: centro (0.5, -0.05, 0.95); en vista lateral el eje horizontal es Y
rlib.render(OUT, "hand", ("front", "side"), center=Vector((0.5, -0.05, 0.95)), ortho=0.4)
rlib.render(OUT, "foot", ("front", "side"), center=Vector((0.12, -0.08, 0.15)), ortho=0.4)
rlib.render(OUT, "head", ("front", "side"), center=Vector((0.0, 0.0, 1.6)), ortho=0.6)
print("DONE")
