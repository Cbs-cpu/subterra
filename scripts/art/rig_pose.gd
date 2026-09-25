class_name RigPose
extends RefCounted
## Lee las animaciones del esqueleto por piezas (scenes/pj_rig.tscn) como datos: para una
## animación y un instante devuelve la transformación de cada pieza respecto a los pies.
## Así los humanoides generados por código (otras razas, vecinos y enemigos) se mueven con
## exactamente las mismas animaciones del AnimationPlayer que el Minero.

const SCENE := "res://scenes/pj_rig.tscn"
const PARTS := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]

static var _anims := {}
static var _rest := {}


static func _load() -> void:
	if not _anims.is_empty():
		return
	var rig: Node = load(SCENE).instantiate()
	var root: Node2D = rig.get_node("Root")
	_rest["Root"] = {"position": root.position, "rotation": root.rotation, "scale": root.scale}
	for n in PARTS:
		var s: Node2D = root.get_node(n)
		_rest[n] = {"position": s.position, "rotation": s.rotation, "scale": s.scale}
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for a in ap.get_animation_list():
		_anims[a] = ap.get_animation(a)
	rig.free()


static func length(anim: String) -> float:
	_load()
	return _anims[anim].length if _anims.has(anim) else 0.0


## {pieza: Transform2D respecto a los pies} para la animación y el instante dados.
static func pose(anim: String, time: float) -> Dictionary:
	_load()
	var vals := {}
	for k in _rest:
		vals[k] = _rest[k].duplicate()
	var a: Animation = _anims.get(anim, null)
	if a != null:
		for ti in a.get_track_count():
			var path := String(a.track_get_path(ti))
			var node := path.get_slice(":", 0).get_file()
			var prop := path.get_slice(":", 1)
			if vals.has(node) and vals[node].has(prop):
				vals[node][prop] = a.value_track_interpolate(ti, clampf(time, 0.0, a.length))
	var r: Dictionary = vals["Root"]
	var root_tr := Transform2D(r["rotation"], r["scale"], 0.0, r["position"])
	var out := {}
	for n in PARTS:
		var v: Dictionary = vals[n]
		out[n] = pixel_tr(root_tr * Transform2D(v["rotation"], v["scale"], 0.0, v["position"]))
	return out


## Quita la escala de una transformación: el aplastar y estirar del cuerpo mueve las piezas
## pero no deforma sus píxeles.
static func pixel_tr(t: Transform2D) -> Transform2D:
	return Transform2D(t.get_rotation(), Vector2.ONE, 0.0, t.origin)
