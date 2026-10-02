# Crea el esqueleto del caballero sobre raw/base.blend y calcula los pesos por distancia
# geodésica (a lo largo de la superficie) desde cada hueso. Guarda raw/rig.blend y renderiza
# una pose de prueba.
import bpy, os, sys, math, heapq
import numpy as np
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.append(HERE)
import rig_def as D
import rlib

ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "render")
bpy.ops.wm.open_mainfile(filepath=os.path.join(ROOT, "raw", "base.blend"))
body = bpy.data.objects["Caballero"]


# --- Definición completa de huesos -------------------------------------------------------
def mirror(p):
    return (-p[0], p[1], p[2])


bones = {}
for n, (h, t, par) in D.CORE.items():
    bones[n] = (Vector(h), Vector(t), par)
for side, sgn in (("Left", 1), ("Right", -1)):
    def S(p):
        return Vector(p) if sgn > 0 else Vector(mirror(p))
    for n, (h, t, par) in D.SIDE.items():
        p2 = None if par is None else (par if par in D.CORE else side + par)
        bones[side + n] = (S(h), S(t), p2)
    bx, bz = D.FINGER_BASE
    for f, fy in D.FINGERS.items():
        tx, tz = D.FINGER_TIP[f]
        a = Vector((bx, fy, bz))
        b = Vector((tx, fy, tz))
        k1, k2 = D.FINGER_SPLIT
        pts = [a, a.lerp(b, k1), a.lerp(b, k2), b]
        names = ["Proximal", "Intermediate", "Distal"]
        for i, nm in enumerate(names):
            par = side + "Hand" if i == 0 else side + f + names[i - 1]
            bones[side + f + nm] = (S(pts[i]), S(pts[i + 1]), par)

# Capa: cadenas sobre la superficie exterior real (rayos hacia el eje).
bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())


def surface(a, z):
    d = Vector((math.sin(math.radians(a)), math.cos(math.radians(a)), 0))
    o = Vector((0, 0, z))
    hit = bvh.ray_cast(o + d * 1.5, -d, 1.5)
    if hit[0] is None:
        return None
    r = (hit[0] - o).length
    return r


for ci, a in enumerate(D.CAPE_ANGLES):
    rs = []
    for z in D.CAPE_ROWS:
        r = surface(a, z)
        rs.append(r if (r and 0.08 < r < 0.5) else None)
    # huecos: interpolar o prolongar
    for i in range(len(rs)):
        if rs[i] is None:
            prev = next((rs[j] for j in range(i - 1, -1, -1) if rs[j] is not None), None)
            nxt = next((rs[j] for j in range(i + 1, len(rs)) if rs[j] is not None), None)
            rs[i] = (prev + nxt) / 2 if prev and nxt else (prev or nxt or 0.2) + 0.02
    # de la cintura para abajo la capa se abre: el radio no baja (si baja, el rayo dio en la bota)
    for i in range(3, len(rs)):
        rs[i] = max(rs[i], rs[i - 1] + 0.01)
    d = lambda r, z: Vector((math.sin(math.radians(a)) * (r - D.CAPE_INSET), math.cos(math.radians(a)) * (r - D.CAPE_INSET), z))
    pts = [d(r, z) for r, z in zip(rs, D.CAPE_ROWS)]
    print("CAPE", a, [round(r, 3) for r in rs])
    for i in range(len(pts) - 1):
        par = "UpperChest" if i == 0 else f"Cape{ci}_{i - 1}"
        bones[f"Cape{ci}_{i}"] = (pts[i], pts[i + 1], par)

print("BONES", len(bones))

# --- Armature -------------------------------------------------------------------------------
arm_data = bpy.data.armatures.new("Rig")
arm = bpy.data.objects.new("Rig", arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
for o in bpy.context.selected_objects:
    o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_data.edit_bones
order = []
pending = dict(bones)
while pending:  # padres antes que hijos
    for n, (h, t, par) in list(pending.items()):
        if par is None or par in eb:
            b = eb.new(n)
            b.head, b.tail = h, t
            if par:
                b.parent = eb[par]
                b.use_connect = (eb[par].tail - h).length < 1e-4
            fwd = (t - h).normalized()
            ref = Vector((0, -1, 0)) if abs(fwd.y) < 0.8 else Vector((0, 0, 1))
            b.align_roll(ref)
            order.append(n)
            del pending[n]
bpy.ops.object.mode_set(mode="OBJECT")

# --- Pesos geodésicos ------------------------------------------------------------------------
me = body.data
N = len(me.vertices)
V = np.array([v.co[:] for v in me.vertices])
adj = [[] for _ in range(N)]
for e in me.edges:
    a, b = e.vertices
    l = float(np.linalg.norm(V[a] - V[b]))
    adj[a].append((b, l))
    adj[b].append((a, l))


def seg_dist(h, t):
    h = np.array(h[:]); t = np.array(t[:])
    ab = t - h
    tt = np.clip(((V - h) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(V - (h + tt[:, None] * ab), axis=1)


CAP = 0.45
G = {}
for n in order:
    h, t, _ = bones[n]
    dseg = seg_dist(h, t)
    dmin = dseg.min()
    tol = max(0.012, 0.6 * dmin)
    seeds = np.nonzero(dseg < dmin + tol)[0]
    dist = np.full(N, np.inf)
    pq = []
    for s in seeds:
        dist[s] = dseg[s] - dmin
        pq.append((dist[s], int(s)))
    heapq.heapify(pq)
    while pq:
        d0, u = heapq.heappop(pq)
        if d0 > dist[u] or d0 > CAP:
            continue
        for w, l in adj[u]:
            nd = d0 + l
            if nd < dist[w]:
                dist[w] = nd
                heapq.heappush(pq, (nd, w))
    G[n] = dist

names = order
Gm = np.stack([G[n] for n in names], axis=1)          # N x B
score = 1.0 / (Gm + 0.015) ** 4
score[~np.isfinite(Gm)] = 0
# suavizado laplaciano de las puntuaciones normalizadas
W = score / np.maximum(score.sum(1, keepdims=True), 1e-12)
for _ in range(2):
    W2 = W.copy()
    for i in range(N):
        if adj[i]:
            W2[i] = 0.5 * W[i] + 0.5 * np.mean([W[j] for j, _ in adj[i]], axis=0)
    W = W2
K = 4
idx = np.argsort(-W, axis=1)[:, :K]
for n in names:
    body.vertex_groups.new(name=n)
vg = {n: body.vertex_groups[n] for n in names}
for i in range(N):
    ws = W[i, idx[i]]
    ws = np.where(ws < 0.02, 0, ws)
    s = ws.sum()
    if s <= 0:
        continue
    for j, w in zip(idx[i], ws / s):
        if w > 0:
            vg[names[j]].add([i], float(w), "REPLACE")
unweighted = int((W.sum(1) == 0).sum())
print("UNWEIGHTED", unweighted)

body.parent = arm
mod = body.modifiers.new("Armature", "ARMATURE")
mod.object = arm
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "raw", "rig.blend"))
print("SAVED")
