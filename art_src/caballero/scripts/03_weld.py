# Suelda los vértices duplicados por las costuras UV y cuenta las piezas reales.
# Escala el personaje a 1,9 m de alto, con los pies en z=0.
import bpy, os, random, bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "raw", "caballero_tripo.glb")
OUT = os.path.join(ROOT, "render")
HEIGHT = 1.9

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
ob.name = "Caballero"
k = HEIGHT / ob.dimensions.z
ob.scale = (k, k, k)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

bm = bmesh.new()
bm.from_mesh(ob.data)
n0 = len(bm.verts)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
print("WELD", n0, "->", len(bm.verts))
bm.to_mesh(ob.data)
bm.free()

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
parts = [o for o in bpy.context.scene.objects if o.type == "MESH"]
print("PARTS", len(parts))
info = []
for o in parts:
    bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
    mn = Vector((min(p.x for p in bb), min(p.y for p in bb), min(p.z for p in bb)))
    mx = Vector((max(p.x for p in bb), max(p.y for p in bb), max(p.z for p in bb)))
    info.append((o, mn, mx, len(o.data.vertices)))
info.sort(key=lambda t: -t[3])
for o, mn, mx, n in info[:40]:
    print("PART", o.name, n, "min", tuple(round(x, 3) for x in mn), "max", tuple(round(x, 3) for x in mx))

random.seed(5)
for o, *_ in info:
    m = bpy.data.materials.new(o.name + "_c")
    m.diffuse_color = (random.random(), random.random(), random.random(), 1)
    o.data.materials.clear()
    o.data.materials.append(m)
scn = bpy.context.scene
scn.render.engine = "BLENDER_WORKBENCH"
scn.display.shading.color_type = "MATERIAL"
scn.render.resolution_x, scn.render.resolution_y = 600, 900
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = HEIGHT * 1.1
scn.collection.objects.link(cam)
scn.camera = cam
c = Vector((0, 0, HEIGHT / 2))
for name, (x, y) in {"front": (0, -1), "side": (1, 0), "back": (0, 1)}.items():
    d = Vector((x, y, 0))
    cam.location = c + d * 5
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scn.render.filepath = os.path.join(OUT, f"weld_{name}.png")
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "raw", "weld.blend"))
print("DONE")
