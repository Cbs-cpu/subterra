# Importa el GLB de Tripo, lo escala a 1,9 m, suelda costuras y lo reduce a ~TARGET triángulos
# conservando UV y material. Guarda raw/base.blend y vistas de medida con rejilla.
import bpy, os, sys, bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "raw", "caballero_tripo.glb")
OUT = os.path.join(ROOT, "render")
HEIGHT = 1.9
TARGET = int(os.environ.get("TARGET", "30000"))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
for o in list(bpy.context.scene.objects):
    if o != ob:
        bpy.data.objects.remove(o)
ob.parent = None
ob.name = "Caballero"
ob.data.name = "Caballero"
k = HEIGHT / ob.dimensions.z
ob.scale = (k, k, k)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
bm.to_mesh(ob.data)
bm.free()

tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
mod = ob.modifiers.new("dec", "DECIMATE")
mod.decimate_type = "COLLAPSE"
mod.ratio = TARGET / tris
mod.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier="dec")
print("TRIS", tris, "->", len(ob.data.polygons), "verts", len(ob.data.vertices))
bpy.ops.object.shade_smooth()

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "raw", "base.blend"))
print("DONE")
