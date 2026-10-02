# Renderiza base.blend de frente y de lado para medir articulaciones.
import bpy, os, sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import rlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "base.blend"))
rlib.setup()
rlib.render(os.path.join(ROOT, "render"), "base", ("front", "side", "back"))
print("DONE")
