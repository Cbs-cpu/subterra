# Pose de prueba exagerada para revisar los pesos: brazos bajados y doblados, pierna adelantada
# con rodilla flexionada, torso girado, puño cerrado, capa y penacho al viento.
import bpy, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
import rlib, posing

ROOT = os.path.dirname(HERE)
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "rig.blend"))
arm = bpy.data.objects["Rig"]
rots = {
    "LeftUpperArm": [("Y", 40)],
    "LeftLowerArm": [("X", -45)],
    "RightUpperArm": [("Y", -35), ("X", -50)],
    "RightLowerArm": [("X", -60)],
    "LeftUpperLeg": [("X", -40)],
    "LeftLowerLeg": [("X", 55)],
    "RightUpperLeg": [("X", 15)],
    "Spine": [("Z", 12)],
    "Head": [("Z", -25)],
    "Plume1": [("X", 25)], "Plume2": [("X", 20)],
    "Hood1": [("X", 15)],
}
for f in ("Index", "Middle", "Ring", "Little"):
    for s in ("Proximal", "Intermediate", "Distal"):
        rots["Left" + f + s] = [("Y", 55)]
for c in range(7):
    for r in range(5):
        rots[f"Cape{c}_{r}"] = [("X", 12 + r * 4)]
posing.pose(arm, rots)
rlib.setup()
rlib.render(os.path.join(ROOT, "render"), "pose", ("front", "side", "q34"))
print("DONE")
