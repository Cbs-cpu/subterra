# Exporta raw/anim.blend a assets/models/caballero/caballero.glb (malla con piel, esqueleto,
# todas las animaciones y texturas reducidas a TEX px).
import bpy, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GAME = os.path.dirname(os.path.dirname(ROOT))
DST = os.path.join(GAME, "assets", "models", "caballero")
os.makedirs(DST, exist_ok=True)
TEX = int(os.environ.get("TEX", "1024"))

bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "anim.blend"))
for o in list(bpy.data.objects):
    if o.name not in ("Rig", "Caballero"):
        bpy.data.objects.remove(o)
for img in bpy.data.images:
    if img.size[0] > TEX:
        img.scale(TEX, TEX)
arm = bpy.data.objects["Rig"]
arm.animation_data.action = None
for tr in arm.animation_data.nla_tracks:
    tr.mute = False
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(
    filepath=os.path.join(DST, "caballero.glb"),
    export_format="GLB",
    use_selection=True,
    export_yup=True,
    export_apply=False,
    export_skins=True,
    export_all_influences=False,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
    export_frame_step=2,
    export_optimize_animation_size=True,
    export_image_format="JPEG",
    export_jpeg_quality=90,
)
print("EXPORTED", os.path.getsize(os.path.join(DST, "caballero.glb")))
