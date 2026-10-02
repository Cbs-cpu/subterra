# Cuenta las islas (partes sueltas) de la malla de Tripo y su tamaño/posición.
import bpy, os, bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(os.path.dirname(HERE), "raw", "caballero_tripo.glb")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
bm = bmesh.new()
bm.from_mesh(ob.data)
bm.verts.ensure_lookup_table()
seen = bytearray(len(bm.verts))
islands = []
for v0 in bm.verts:
    if seen[v0.index]:
        continue
    stack = [v0]
    seen[v0.index] = 1
    idx = []
    while stack:
        v = stack.pop()
        idx.append(v.index)
        for e in v.link_edges:
            w = e.other_vert(v)
            if not seen[w.index]:
                seen[w.index] = 1
                stack.append(w)
    islands.append(idx)
islands.sort(key=len, reverse=True)
print("ISLANDS", len(islands))
for i, idx in enumerate(islands[:25]):
    cs = [bm.verts[j].co for j in idx]
    mn = Vector((min(c.x for c in cs), min(c.y for c in cs), min(c.z for c in cs)))
    mx = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))
    print("ISL", i, len(idx), "min", tuple(round(x, 3) for x in mn), "max", tuple(round(x, 3) for x in mx))
# Bordes abiertos (no manifold)
nb = sum(1 for e in bm.edges if not e.is_manifold)
print("NONMANIFOLD_EDGES", nb, "of", len(bm.edges))
