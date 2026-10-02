# Escanea la malla con rayos desde fuera hacia el eje vertical: para cada altura z y ángulo,
# la distancia radial de la superficie exterior. Sirve para colocar las cadenas de la capa.
import bpy, os, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "base.blend"))
ob = bpy.data.objects["Caballero"]
bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())
# ángulo 0 = espalda (+Y), 90 = izquierda del personaje (+X), 180/-180 = frente (-Y)
for z0 in [1.5, 1.45, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.15]:
    row = []
    for a in range(-180, 181, 15):
        d = Vector((math.sin(math.radians(a)), math.cos(math.radians(a)), 0))
        hit = bvh.ray_cast(Vector((0, 0, z0)) + d * 1.5, -d, 1.5)
        r = (hit[0] - Vector((0, 0, z0))).length if hit[0] else 0.0
        row.append(f"{a:4d}:{r:.2f}")
    print(f"Z {z0:.2f} | " + " ".join(row))
