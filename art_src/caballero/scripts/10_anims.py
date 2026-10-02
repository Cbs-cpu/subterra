# Crea una acción de Blender por animación de anims.py sobre raw/rig.blend y guarda raw/anim.blend.
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
import importlib
import anims, posing, rlib, rig_def
importlib.reload(anims)

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "render")
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "rig.blend"))
scn = bpy.context.scene
scn.render.fps = anims.FPS
arm = bpy.data.objects["Rig"]
BODY = [b.name for b in arm.data.bones if not b.name.startswith(rig_def.PHYSICS_PREFIXES)]
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
arm.animation_data_create()


def apply(rots, loc):
    full = {n: [] for n in BODY}
    for k, v in anims.M(anims.STANCE, rots).items():
        full[k] = full.get(k, []) + v
    posing.pose(arm, full)
    arm.pose.bones["Hips"].location = loc or (0, 0, 0)


for name, spec in anims.ANIMS.items():
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    arm.animation_data.action = act
    first = spec["keys"][0]
    for frame, rots, loc in spec["keys"]:
        if rots is None:
            rots, loc = first[1], first[2]
        apply(rots, loc)
        for n in BODY:
            arm.pose.bones[n].keyframe_insert("rotation_quaternion", frame=frame, group=n)
        arm.pose.bones["Hips"].keyframe_insert("location", frame=frame, group="Hips")
    end = spec["keys"][-1][0]
    act.frame_range = (0, end)
    act.use_frame_range = True
    tr = arm.animation_data.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 0, act)
    tr.mute = True
    print("ANIM", name, "frames", end)
arm.animation_data.action = None
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "raw", "anim.blend"))
print("SAVED")

