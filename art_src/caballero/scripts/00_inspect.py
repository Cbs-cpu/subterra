# Importa el GLB de Tripo, informa de su estructura y renderiza vistas frontal/lateral/trasera.
# blender -b -P 00_inspect.py
import bpy, os, math
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "raw", "caballero_tripo.glb")
OUT = os.path.join(ROOT, "render")
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in bpy.context.scene.objects:
    print("OBJ", o.name, o.type, tuple(round(v, 3) for v in o.dimensions), o.parent.name if o.parent else "-")
for o in meshes:
    print("MESH", o.name, "verts", len(o.data.vertices), "faces", len(o.data.polygons), "uv", len(o.data.uv_layers))
    for m in o.data.materials:
        print("  MAT", m.name)
        for n in m.node_tree.nodes:
            if n.type == "TEX_IMAGE" and n.image:
                print("    TEX", n.image.name, n.image.size[:], n.label)

pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
print("BBOX min", tuple(round(v, 3) for v in mn), "max", tuple(round(v, 3) for v in mx))
center = (mn + mx) / 2
h = mx.z - mn.z

scn = bpy.context.scene
scn.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
scn.render.resolution_x = 600
scn.render.resolution_y = 900
scn.world = bpy.data.worlds.new("w")
scn.world.use_nodes = True
scn.world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.35, 0.38, 1)
scn.world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
scn.collection.objects.link(sun)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
cam.data.type = "ORTHO"
cam.data.ortho_scale = h * 1.1
scn.collection.objects.link(cam)
scn.camera = cam

views = {"front": (0, -1), "side": (1, 0), "back": (0, 1), "q34": (0.7, -0.7)}
for name, (x, y) in views.items():
    d = Vector((x, y, 0)).normalized()
    cam.location = center + d * h * 3
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scn.render.filepath = os.path.join(OUT, f"tripo_{name}.png")
    bpy.ops.render.render(write_still=True)
print("DONE")
