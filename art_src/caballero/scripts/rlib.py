# Utilidades de render para revisar el caballero desde scripts en modo background.
import bpy, os, math
from mathutils import Vector

HEIGHT = 1.9
ORTHO = HEIGHT * 1.1
RES = (600, 900)
VIEWS = {"front": (0, -1), "side": (1, 0), "back": (0, 1), "q34": (0.7, -0.7)}


def setup(engine="EEVEE"):
    scn = bpy.context.scene
    engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    if engine == "EEVEE":
        scn.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
    else:
        scn.render.engine = "BLENDER_WORKBENCH"
    scn.render.resolution_x, scn.render.resolution_y = RES
    scn.render.film_transparent = False
    if scn.world is None:
        scn.world = bpy.data.worlds.new("w")
    scn.world.use_nodes = True
    bg = scn.world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.35, 0.35, 0.38, 1)
    if "sun" not in bpy.data.objects:
        sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
        sun.data.energy = 3
        sun.rotation_euler = (math.radians(50), 0, math.radians(30))
        scn.collection.objects.link(sun)
    if "cam" not in bpy.data.objects:
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        scn.collection.objects.link(cam)
    cam = bpy.data.objects["cam"]
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ORTHO
    scn.camera = cam
    return cam


def render(out_dir, prefix, views=("front", "side", "back"), center=None, ortho=None):
    cam = bpy.data.objects["cam"]
    c = center or Vector((0, 0, HEIGHT / 2))
    cam.data.ortho_scale = ortho or ORTHO
    paths = []
    for name in views:
        x, y = VIEWS[name]
        d = Vector((x, y, 0)).normalized()
        cam.location = c + d * 6
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        p = os.path.join(out_dir, f"{prefix}_{name}.png")
        bpy.context.scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    return paths
