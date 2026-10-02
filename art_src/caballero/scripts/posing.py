# Ayudas para posar huesos con ejes del mundo (de la pose de reposo) desde scripts.
import math
from mathutils import Matrix, Quaternion, Vector

AX = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}


def world_rot(arm, name, axis, deg):
    """Quaternion local del hueso equivalente a girar `deg` grados alrededor del eje del mundo
    `axis` ('X', 'Y', 'Z' o Vector) en su pose de reposo. +X: inclinar hacia delante/abajo según
    el hueso; se compone con la rotación de los padres."""
    b = arm.data.bones[name]
    R = b.matrix_local.to_3x3()
    a = AX[axis] if isinstance(axis, str) else Vector(axis)
    q = Quaternion(a, math.radians(deg)).to_matrix()
    return (R.inverted() @ q @ R).to_quaternion()


def pose(arm, rots):
    """rots: {hueso: [(eje, grados), ...]} -> pone rotation_quaternion (compuesta en orden)."""
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    for name, lst in rots.items():
        q = Quaternion()
        for axis, deg in lst:
            q = world_rot(arm, name, axis, deg) @ q
        arm.pose.bones[name].rotation_quaternion = q


def key(arm, rots, frame, loc=None):
    pose(arm, rots)
    for name in rots:
        arm.pose.bones[name].keyframe_insert("rotation_quaternion", frame=frame)
    if loc is not None:
        arm.pose.bones["Hips"].location = loc
        arm.pose.bones["Hips"].keyframe_insert("location", frame=frame)
