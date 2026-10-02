# Animaciones del caballero, en fotogramas a 100 fps (1 fotograma = 0,01 s) para que las
# duraciones coincidan con las que usa hero.gd (idle 2 s, run 0,56 s, attack 0,3 s...).
#
# Cada pose es {hueso: [(eje_mundo, grados), ...]} y se suma a la postura base STANCE.
# Convenciones (ejes del mundo en reposo; el personaje mira a -Y, +X es su izquierda):
#   muslo/brazo colgando: -X = hacia delante, +X = hacia atrás
#   rodilla: +X = flexionar · pie: -X = punta arriba · torso/cabeza: +X = inclinarse adelante
#   Z+ = girar hacia su izquierda · brazo izquierdo +Y = bajarlo (derecho: -Y)
#   dedos izquierdos +Y = cerrar (derechos: -Y)
# Los huesos de física (capa, capucha, pelaje, penacho, faldar) no se animan: los mueve Godot.

FPS = 100

FING = ("Index", "Middle", "Ring", "Little")


def fist(side, deg):
    s = 1 if side == "Left" else -1
    r = {}
    for f in FING:
        r[f"{side}{f}Proximal"] = [("Y", s * deg)]
        r[f"{side}{f}Intermediate"] = [("Y", s * deg * 1.1)]
        r[f"{side}{f}Distal"] = [("Y", s * deg * 0.8)]
    r[f"{side}ThumbProximal"] = [("Y", s * deg * 0.4)]
    r[f"{side}ThumbDistal"] = [("Y", s * deg * 0.4)]
    return r


# Postura base: brazos bajados del A-pose, codos algo doblados, mano derecha cerrada (empuña
# el objeto que dibuja el juego), izquierda relajada.
STANCE = {
    "LeftUpperArm": [("Y", 30)],
    "RightUpperArm": [("Y", -30)],
    "LeftLowerArm": [("X", -12)],
    "RightLowerArm": [("X", -18)],
    "LeftHand": [("Y", 5)],
    "RightHand": [("Y", -5)],
}
STANCE.update(fist("Right", 75))
STANCE.update(fist("Left", 22))


def M(*dicts):
    out = {}
    for d in dicts:
        for k, v in d.items():
            out[k] = out.get(k, []) + list(v)
    return out


def L(r, s):
    """Refleja una pose de lado izquierdo a derecho (s='Right') invirtiendo los ejes Y y Z."""
    out = {}
    for k, v in r.items():
        k2 = k.replace("Left", s) if s == "Right" else k
        out[k2] = [(a, -d if (s == "Right" and a in ("Y", "Z")) else d) for a, d in v]
    return out


ANIMS = {}

# --- idle (2 s): respiración, peso que oscila, mirada que se mueve un poco ---------------------
ANIMS["idle"] = {
    "loop": True,
    "keys": [
        (0, {"UpperChest": [("X", -1)], "Neck": [("X", 2)], "Head": [("Z", 0)], "Hips": [("Y", 1.5)], "Spine": [("Y", -1)],
             "LeftUpperArm": [("Y", -1)], "RightUpperArm": [("Y", 1)], "LeftUpperLeg": [("Y", -1.5)], "RightUpperLeg": [("Y", -1.5)]}, (0, 0, 0)),
        (50, {"UpperChest": [("X", -3)], "Neck": [("X", 0)], "Head": [("Z", 6), ("X", -2)], "Hips": [("Y", 0)],
              "LeftUpperArm": [("Y", -3)], "RightUpperArm": [("Y", 3)]}, (0, 0.006, 0)),
        (100, {"UpperChest": [("X", -1)], "Neck": [("X", 2)], "Head": [("Z", 2)], "Hips": [("Y", -1.5)], "Spine": [("Y", 1)],
               "LeftUpperArm": [("Y", -1)], "RightUpperArm": [("Y", 1)], "LeftUpperLeg": [("Y", 1.5)], "RightUpperLeg": [("Y", 1.5)]}, (0, 0, 0)),
        (150, {"UpperChest": [("X", -3)], "Neck": [("X", 0)], "Head": [("Z", -5), ("X", 1)], "Hips": [("Y", 0)],
               "LeftUpperArm": [("Y", -3)], "RightUpperArm": [("Y", 3)]}, (0, 0.006, 0)),
        (200, None, None),  # = fotograma 0
    ],
}

# --- run (0,56 s): zancada completa; contacto izquierdo en 0 y derecho en 28 ------------------
LEG_T = [0, 7, 14, 21, 28, 35, 42, 49, 56]
THIGH = [-32, -20, 0, 20, 32, 15, -20, -40, -32]
KNEE = [12, 38, 22, 15, 25, 70, 98, 45, 12]
FOOT = [-15, 6, 10, 15, 32, 20, 0, -15, -15]
BOB = [0.0, -0.045, -0.01, 0.03, 0.0, -0.045, -0.01, 0.03, 0.0]


def run_key(i):
    j = (i + 4) % 8
    r = {
        "LeftUpperLeg": [("X", THIGH[i])], "LeftLowerLeg": [("X", KNEE[i])], "LeftFoot": [("X", FOOT[i])],
        "RightUpperLeg": [("X", THIGH[j])], "RightLowerLeg": [("X", KNEE[j])], "RightFoot": [("X", FOOT[j])],
        # brazos al revés que las piernas, codos doblados de carrera
        "LeftUpperArm": [("Y", -12), ("X", -THIGH[j] * 1.1)], "LeftLowerArm": [("X", -70 - max(0, THIGH[i]) * 0.6)],
        "RightUpperArm": [("Y", 12), ("X", -THIGH[i] * 1.1)], "RightLowerArm": [("X", -75 - max(0, THIGH[j]) * 0.6)],
        # inclinación de carrera, giro de cadera y contragiro de hombros
        "Hips": [("X", 6), ("Z", THIGH[i] * 0.22)],
        "Spine": [("X", 6), ("Z", -THIGH[i] * 0.12)],
        "UpperChest": [("X", 4), ("Z", -THIGH[i] * 0.22)],
        "Neck": [("X", -8)], "Head": [("X", -4), ("Z", THIGH[i] * 0.08)],
        "LeftToes": [("X", -18 if i == 4 else 0)], "RightToes": [("X", -18 if j == 4 else 0)],
    }
    return r


ANIMS["run"] = {"loop": True, "keys": [(LEG_T[i], run_key(i), (0, BOB[i], 0)) for i in range(8)] + [(56, None, None)]}

# --- jump (0 = despegue estirado -> 0,4 = cima recogida) --------------------------------------
ANIMS["jump"] = {
    "loop": False,
    "keys": [
        (0, {"LeftUpperLeg": [("X", 12)], "RightUpperLeg": [("X", 4)], "LeftLowerLeg": [("X", 8)], "RightLowerLeg": [("X", 15)],
             "LeftFoot": [("X", 35)], "RightFoot": [("X", 30)],
             "LeftUpperArm": [("Y", -15), ("X", -70)], "RightUpperArm": [("Y", 15), ("X", -55)],
             "LeftLowerArm": [("X", -20)], "RightLowerArm": [("X", -30)],
             "Spine": [("X", -6)], "UpperChest": [("X", -6)], "Head": [("X", -10)]}, (0, 0.02, 0)),
        (20, {"LeftUpperLeg": [("X", -45)], "RightUpperLeg": [("X", -20)], "LeftLowerLeg": [("X", 75)], "RightLowerLeg": [("X", 85)],
              "LeftFoot": [("X", 10)], "RightFoot": [("X", 20)],
              "LeftUpperArm": [("Y", -35), ("X", -35)], "RightUpperArm": [("Y", 30), ("X", -40)],
              "LeftLowerArm": [("X", -50)], "RightLowerArm": [("X", -60)],
              "Spine": [("X", 8)], "UpperChest": [("X", 4)], "Head": [("X", -6)]}, (0, 0.05, 0)),
        (40, {"LeftUpperLeg": [("X", -60)], "RightUpperLeg": [("X", -35)], "LeftLowerLeg": [("X", 100)], "RightLowerLeg": [("X", 110)],
              "LeftFoot": [("X", 15)], "RightFoot": [("X", 20)],
              "LeftUpperArm": [("Y", -50), ("X", -20)], "RightUpperArm": [("Y", 45), ("X", -30)],
              "LeftLowerArm": [("X", -60)], "RightLowerArm": [("X", -70)],
              "Spine": [("X", 14)], "UpperChest": [("X", 8)], "Head": [("X", -10)]}, (0, 0.08, 0)),
    ],
}

# --- fall (0 = recién empieza a caer -> 0,4 = cayendo rápido, brazos arriba) -----------------
ANIMS["fall"] = {
    "loop": False,
    "keys": [
        (0, {"LeftUpperLeg": [("X", -40)], "RightUpperLeg": [("X", -15)], "LeftLowerLeg": [("X", 70)], "RightLowerLeg": [("X", 60)],
             "LeftUpperArm": [("Y", -45), ("X", -20)], "RightUpperArm": [("Y", 40), ("X", -25)],
             "LeftLowerArm": [("X", -45)], "RightLowerArm": [("X", -55)], "Spine": [("X", 8)], "Head": [("X", 4)]}, (0, 0.04, 0)),
        (40, {"LeftUpperLeg": [("X", -12), ("Y", -6)], "RightUpperLeg": [("X", 10), ("Y", 6)], "LeftLowerLeg": [("X", 25)], "RightLowerLeg": [("X", 35)],
              "LeftFoot": [("X", 20)], "RightFoot": [("X", 25)],
              "LeftUpperArm": [("Y", -85), ("X", -15)], "RightUpperArm": [("Y", 80), ("X", -20)],
              "LeftLowerArm": [("X", -25)], "RightLowerArm": [("X", -30)], "Spine": [("X", -6)], "UpperChest": [("X", -8)],
              "Head": [("X", 18)]}, (0, 0.0, 0)),
    ],
}

# --- attack (0,3 s): espada/hacha de arriba abajo. Carga hasta 0,25·0,3, golpe hasta 0,5·0,3 --
ATK_READY = {"LeftUpperLeg": [("X", -22)], "LeftLowerLeg": [("X", 20)], "RightUpperLeg": [("X", 14)], "RightLowerLeg": [("X", 12)]}
ANIMS["attack"] = {
    "loop": False,
    "keys": [
        (0, M(ATK_READY, {"RightUpperArm": [("Y", 20), ("X", -60)], "RightLowerArm": [("X", -50)],
                          "LeftUpperArm": [("X", -20)], "Spine": [("Z", 8)]}), (0, -0.01, 0)),
        (8, M(ATK_READY, {"RightUpperArm": [("Y", 25), ("X", -165)], "RightLowerArm": [("X", -70)], "RightHand": [("X", 20)],
                          "LeftUpperArm": [("X", -35), ("Y", -10)], "LeftLowerArm": [("X", -30)],
                          "Spine": [("X", -10), ("Z", 15)], "UpperChest": [("X", -8), ("Z", 10)], "Head": [("X", 6)]}), (0, 0.0, 0)),
        (10, M(ATK_READY, {"RightUpperArm": [("Y", 25), ("X", -170)], "RightLowerArm": [("X", -75)], "RightHand": [("X", 25)],
                           "LeftUpperArm": [("X", -38), ("Y", -10)], "LeftLowerArm": [("X", -30)],
                           "Spine": [("X", -12), ("Z", 16)], "UpperChest": [("X", -9), ("Z", 11)], "Head": [("X", 6)]}), (0, 0.0, 0)),
        (15, M(ATK_READY, {"RightUpperArm": [("Y", 15), ("X", -45)], "RightLowerArm": [("X", -10)], "RightHand": [("X", -25)],
                           "LeftUpperArm": [("X", 25)], "LeftLowerArm": [("X", -40)],
                           "Spine": [("X", 18), ("Z", -12)], "UpperChest": [("X", 12), ("Z", -10)], "Head": [("X", -10)]}), (0, -0.05, 0)),
        (20, M(ATK_READY, {"RightUpperArm": [("Y", 15), ("X", -30)], "RightLowerArm": [("X", -8)], "RightHand": [("X", -20)],
                           "LeftUpperArm": [("X", 30)], "LeftLowerArm": [("X", -35)],
                           "Spine": [("X", 20), ("Z", -14)], "UpperChest": [("X", 12), ("Z", -12)], "Head": [("X", -12)]}), (0, -0.06, 0)),
        (30, M(ATK_READY, {"RightUpperArm": [("Y", 10), ("X", -35)], "RightLowerArm": [("X", -25)],
                           "LeftUpperArm": [("X", 10)], "Spine": [("X", 8), ("Z", -4)], "Head": [("X", -4)]}), (0, -0.03, 0)),
    ],
}

# --- attack_pick (0,3 s): pico bien alto, se aguanta y cae de golpe (daño hacia 0,45-0,55) ----
ANIMS["attack_pick"] = {
    "loop": False,
    "keys": [
        (0, M(ATK_READY, {"RightUpperArm": [("Y", 20), ("X", -50)], "RightLowerArm": [("X", -40)]}), (0, 0, 0)),
        (12, M(ATK_READY, {"RightUpperArm": [("Y", 15), ("X", -175)], "RightLowerArm": [("X", -60)], "RightHand": [("X", 25)],
                           "LeftUpperArm": [("Y", 10), ("X", -170)], "LeftLowerArm": [("X", -60)],
                           "Spine": [("X", -14)], "UpperChest": [("X", -10)], "Head": [("X", 8)]}), (0, 0.01, 0)),
        (16, M(ATK_READY, {"RightUpperArm": [("Y", 15), ("X", -178)], "RightLowerArm": [("X", -65)], "RightHand": [("X", 28)],
                           "LeftUpperArm": [("Y", 10), ("X", -172)], "LeftLowerArm": [("X", -65)],
                           "Spine": [("X", -16)], "UpperChest": [("X", -11)], "Head": [("X", 8)]}), (0, 0.015, 0)),
        (20, M(ATK_READY, {"RightUpperArm": [("Y", 10), ("X", -40)], "RightLowerArm": [("X", -5)], "RightHand": [("X", -25)],
                           "LeftUpperArm": [("Y", 5), ("X", -45)], "LeftLowerArm": [("X", -10)],
                           "Spine": [("X", 25)], "UpperChest": [("X", 14)], "Head": [("X", -12)]}), (0, -0.08, 0)),
        (30, M(ATK_READY, {"RightUpperArm": [("Y", 10), ("X", -35)], "RightLowerArm": [("X", -20)],
                           "LeftUpperArm": [("X", -25)], "LeftLowerArm": [("X", -30)], "Spine": [("X", 15)]}), (0, -0.05, 0)),
    ],
}

# --- punch (0,3 s): directo con la derecha --------------------------------------------------
ANIMS["punch"] = {
    "loop": False,
    "keys": [
        (0, M(ATK_READY, {"RightUpperArm": [("Y", 25), ("X", -30)], "RightLowerArm": [("X", -100)], "LeftUpperArm": [("X", -30)],
                          "LeftLowerArm": [("X", -90)]}, fist("Left", 60)), (0, -0.02, 0)),
        (6, M(ATK_READY, {"RightUpperArm": [("Y", 30), ("X", -10)], "RightLowerArm": [("X", -120)], "LeftUpperArm": [("X", -40)],
                          "LeftLowerArm": [("X", -95)], "Spine": [("Z", 18)], "UpperChest": [("Z", 10)]}, fist("Left", 60)), (0, -0.03, 0)),
        (12, M(ATK_READY, {"RightUpperArm": [("Y", 70), ("X", -80)], "RightLowerArm": [("X", -10)], "LeftUpperArm": [("X", -10)],
                           "LeftLowerArm": [("X", -100)], "Spine": [("X", 12), ("Z", -20)], "UpperChest": [("Z", -14)]}, fist("Left", 60)), (0, -0.05, 0)),
        (30, M(ATK_READY, {"RightUpperArm": [("Y", 25), ("X", -30)], "RightLowerArm": [("X", -95)], "LeftUpperArm": [("X", -30)],
                           "LeftLowerArm": [("X", -90)]}, fist("Left", 60)), (0, -0.02, 0)),
    ],
}

# --- chop (0,3 s): tajo horizontal a dos manos. Tiempos de hero.gd: carga 0-0,105, tensión
# hasta 0,13, impacto 0,155, seguimiento 0,21, vuelta 0,3 ---------------------------------------
CHOP_LEGS = {"LeftUpperLeg": [("X", -25), ("Y", -6)], "LeftLowerLeg": [("X", 25)], "RightUpperLeg": [("X", 15), ("Y", 6)], "RightLowerLeg": [("X", 20)]}


def chop_pose(twist, lean):
    # Las dos manos juntas en el mango, delante del pecho; el giro del tronco lleva el tajo.
    # twist > 0: cargado hacia su derecha-atrás; < 0: descargado hacia su izquierda.
    t = -twist
    return M(CHOP_LEGS, {
        "Hips": [("Z", t * 0.25)], "Spine": [("Z", t * 0.35), ("X", lean)], "UpperChest": [("Z", t * 0.4), ("X", lean * 0.5)],
        "Neck": [("Z", -t * 0.35)], "Head": [("Z", -t * 0.35)],
        "RightUpperArm": [("X", -65), ("Z", 20)], "RightLowerArm": [("Z", 55), ("X", -15)], "RightHand": [("Z", 15)],
        "LeftUpperArm": [("X", -60), ("Z", -30)], "LeftLowerArm": [("Z", -60), ("X", -15)], "LeftHand": [("Z", -10)],
    }, fist("Left", 75))


ANIMS["chop"] = {
    "loop": False,
    "keys": [
        (0, chop_pose(0, 6), (0, -0.03, 0)),
        (10.5, chop_pose(70, -4), (0, -0.05, 0)),
        (13, chop_pose(78, -5), (0, -0.05, 0)),
        (15.5, chop_pose(-55, 14), (0, -0.07, 0)),
        (21, chop_pose(-68, 16), (0, -0.07, 0)),
        (30, chop_pose(0, 6), (0, -0.03, 0)),
    ],
}

# --- hurt (0,25 s): golpe recibido, retroceso y recuperación ----------------------------------
ANIMS["hurt"] = {
    "loop": False,
    "keys": [
        (0, {}, (0, 0, 0)),
        (5, {"Spine": [("X", -16)], "UpperChest": [("X", -12)], "Neck": [("X", -10)], "Head": [("X", -18), ("Z", 10)],
             "LeftUpperArm": [("Y", -30), ("X", -30)], "RightUpperArm": [("Y", 25), ("X", -20)],
             "LeftLowerArm": [("X", -30)], "RightLowerArm": [("X", -25)],
             "LeftUpperLeg": [("X", -15)], "LeftLowerLeg": [("X", 30)], "RightUpperLeg": [("X", 8)], "RightLowerLeg": [("X", 25)]}, (0, -0.04, 0)),
        (14, {"Spine": [("X", 10)], "UpperChest": [("X", 6)], "Head": [("X", 8), ("Z", -4)],
              "LeftUpperArm": [("Y", -10), ("X", -10)], "RightUpperArm": [("Y", 10), ("X", -10)],
              "LeftUpperLeg": [("X", -20)], "LeftLowerLeg": [("X", 35)], "RightUpperLeg": [("X", 10)], "RightLowerLeg": [("X", 30)]}, (0, -0.06, 0)),
        (25, {}, (0, 0, 0)),
    ],
}

# --- dash (0,2 s en bucle): embestida baja, piernas abiertas, brazos atrás --------------------
DASH = {"Hips": [("X", 15)], "Spine": [("X", 20)], "UpperChest": [("X", 10)], "Neck": [("X", -18)], "Head": [("X", -12)],
        "LeftUpperLeg": [("X", -55)], "LeftLowerLeg": [("X", 50)], "LeftFoot": [("X", -5)],
        "RightUpperLeg": [("X", 40)], "RightLowerLeg": [("X", 35)], "RightFoot": [("X", 25)],
        "LeftUpperArm": [("Y", -10), ("X", 60)], "RightUpperArm": [("Y", 10), ("X", 55)],
        "LeftLowerArm": [("X", -15)], "RightLowerArm": [("X", -20)]}
ANIMS["dash"] = {
    "loop": True,
    "keys": [
        (0, DASH, (0, -0.12, 0)),
        (10, M(DASH, {"Spine": [("X", 3)], "LeftUpperArm": [("X", 6)], "RightUpperArm": [("X", 6)]}), (0, -0.13, 0)),
        (20, None, None),
    ],
}

# --- down (abatido): cae de rodillas y se apoya en la mano; se queda en el último fotograma ---
KNEEL = {"Hips": [("X", 10)], "Spine": [("X", 20)], "UpperChest": [("X", 10)], "Neck": [("X", 2)], "Head": [("X", 8), ("Z", -12)],
         "LeftUpperLeg": [("X", -80)], "LeftLowerLeg": [("X", 85)], "LeftFoot": [("X", -10)],
         "RightUpperLeg": [("X", 15)], "RightLowerLeg": [("X", 115)], "RightFoot": [("X", 50)], "RightToes": [("X", -40)],
         "LeftUpperArm": [("Y", -15), ("X", -50)], "LeftLowerArm": [("X", -20)],
         "RightUpperArm": [("Y", 5), ("X", -15)], "RightLowerArm": [("X", -5)]}
ANIMS["down"] = {
    "loop": False,
    "keys": [
        (0, {}, (0, 0, 0)),
        (18, M(KNEEL, {"Spine": [("X", 10)], "Head": [("X", 10)]}), (0, -0.48, -0.04)),
        (30, KNEEL, (0, -0.5, -0.05)),
        (200, M(KNEEL, {"UpperChest": [("X", 4)], "Head": [("X", 4)]}), (0, -0.51, -0.05)),
    ],
}
