# Definición del esqueleto del caballero (coordenadas de Blender, metros, personaje de 1,9 m).
# +X = izquierda del personaje, -Y = frente, Z = arriba. Los nombres siguen el perfil humanoide
# de Godot (SkeletonProfileHumanoid) para poder redirigir animaciones; los huesos de física
# (capa, capucha, pelaje, penacho, faldar) cuelgan de ellos y los mueve SpringBoneSimulator3D.

# nombre: (cabeza, cola, padre)
CORE = {
    "Hips": ((0, 0.0, 0.96), (0, 0.0, 1.08), None),
    "Spine": ((0, 0.0, 1.08), (0, 0.0, 1.20), "Hips"),
    "Chest": ((0, 0.0, 1.20), (0, 0.0, 1.32), "Spine"),
    "UpperChest": ((0, 0.0, 1.32), (0, 0.0, 1.46), "Chest"),
    "Neck": ((0, -0.01, 1.46), (0, -0.03, 1.56), "UpperChest"),
    "Head": ((0, -0.03, 1.56), (0, -0.05, 1.86), "Neck"),
    # Penacho de pelo del yelmo
    "Plume1": ((0, 0.02, 1.83), (0, 0.07, 1.82), "Head"),
    "Plume2": ((0, 0.07, 1.82), (0, 0.12, 1.78), "Plume1"),
    "Plume3": ((0, 0.12, 1.78), (0, 0.15, 1.73), "Plume2"),
    # Capucha caída
    "Hood1": ((0, 0.09, 1.62), (0, 0.16, 1.58), "UpperChest"),
    "Hood2": ((0, 0.16, 1.58), (0, 0.17, 1.49), "Hood1"),
    # Pelaje del manto (delante y detrás)
    "FurBack": ((0, 0.14, 1.48), (0, 0.19, 1.27), "UpperChest"),
    # Taparrabos delantero
    "LoinF1": ((0, -0.14, 1.05), (0, -0.16, 0.78), "Hips"),
    "LoinF2": ((0, -0.16, 0.78), (0, -0.15, 0.50), "LoinF1"),
}

# Lado izquierdo (+X); el derecho se genera en espejo.
SIDE = {
    "Shoulder": ((0.03, -0.01, 1.43), (0.17, 0.0, 1.43), "UpperChest"),
    "UpperArm": ((0.17, 0.0, 1.43), (0.335, -0.05, 1.235), "Shoulder"),
    "LowerArm": ((0.335, -0.05, 1.235), (0.475, -0.13, 1.04), "UpperArm"),
    "Hand": ((0.475, -0.13, 1.04), (0.525, -0.145, 0.975), "LowerArm"),
    "ThumbMetacarpal": ((0.485, -0.165, 1.02), (0.478, -0.19, 0.99), "Hand"),
    "ThumbProximal": ((0.478, -0.19, 0.99), (0.472, -0.195, 0.965), "ThumbMetacarpal"),
    "ThumbDistal": ((0.472, -0.195, 0.965), (0.468, -0.195, 0.94), "ThumbProximal"),
    "UpperLeg": ((0.095, 0.0, 0.95), (0.11, -0.03, 0.52), "Hips"),
    "LowerLeg": ((0.11, -0.03, 0.52), (0.12, -0.01, 0.10), "UpperLeg"),
    "Foot": ((0.12, -0.01, 0.10), (0.12, -0.14, 0.03), "LowerLeg"),
    "Toes": ((0.12, -0.14, 0.03), (0.12, -0.25, 0.01), "Foot"),
    "FurFront": ((0.12, -0.12, 1.47), (0.15, -0.17, 1.30), "UpperChest"),
    "FurShoulder": ((0.18, 0.0, 1.50), (0.30, 0.0, 1.38), "Shoulder"),
    "SkirtF1": ((0.10, -0.14, 1.05), (0.12, -0.16, 0.78), "Hips"),
    "SkirtF2": ((0.12, -0.16, 0.78), (0.13, -0.15, 0.52), "SkirtF1"),
    "SkirtS1": ((0.19, 0.0, 1.05), (0.21, 0.0, 0.80), "Hips"),
    "SkirtS2": ((0.21, 0.0, 0.80), (0.22, 0.0, 0.58), "SkirtS1"),
    "SkirtB1": ((0.10, 0.12, 1.05), (0.12, 0.14, 0.78), "Hips"),
    "SkirtB2": ((0.12, 0.14, 0.78), (0.13, 0.13, 0.52), "SkirtB1"),
}

# Dedos (índice, corazón, anular, meñique): base en los nudillos, punta abajo.
FINGERS = {"Index": -0.185, "Middle": -0.16, "Ring": -0.135, "Little": -0.11}
FINGER_BASE = (0.525, 0.975)   # x, z
FINGER_TIP = {"Index": (0.55, 0.885), "Middle": (0.552, 0.88), "Ring": (0.55, 0.887), "Little": (0.545, 0.90)}
FINGER_SPLIT = (0.42, 0.75)    # fracciones donde acaban proximal / intermedia

# Capa: columnas por ángulo (0 = espalda, + = izquierda) y filas por altura.
CAPE_ANGLES = [-75, -50, -25, 0, 25, 50, 75]
CAPE_ROWS = [1.42, 1.18, 0.94, 0.70, 0.46, 0.22]
CAPE_INSET = 0.015

# Huesos que mueve la física (SpringBoneSimulator3D): prefijos de cadena.
PHYSICS_PREFIXES = ("Cape", "Hood", "Plume", "Fur", "Skirt", "Loin")
