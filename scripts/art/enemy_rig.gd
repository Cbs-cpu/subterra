class_name EnemyRig
extends RefCounted
## Enemigos por piezas (scenes/enemigos/<spr>.tscn, generadas por tools/build_enemy_rig.gd):
## lee sus piezas y animaciones del AnimationPlayer como datos y da, para una animación y
## un instante, cada pieza con su fotograma y su transformación respecto a los pies.
## Las variantes de color usan las piezas de assets/sprites/enemigos/<spr>_<pal>/ si existen.

const SCENES := "res://scenes/enemigos/"
## Enemigos ya revisados que el juego dibuja por piezas. Los demás siguen con su sprite de
## siempre aunque su escena exista (se enseñan antes en un vídeo de revisión).
const ENABLED := ["limo", "arana"]
const SPRITES := "res://assets/sprites/enemigos/"

static var _defs := {}
static var _tex := {}


static func has(spr: String) -> bool:
	return spr in ENABLED and _def(spr) != null


## {parts: [{name, path, parent, tex, hframes, offset, rest: {position, rotation, frame}}], anims}
static func _def(spr: String) -> Variant:
	if _defs.has(spr):
		return _defs[spr]
	var path := SCENES + spr + ".tscn"
	if not ResourceLoader.exists(path):
		_defs[spr] = null
		return null
	var rig: Node = load(path).instantiate()
	var parts := []
	_collect(rig, rig, "", parts)
	var anims := {}
	var ap: AnimationPlayer = rig.get_node("AnimationPlayer")
	for a in ap.get_animation_list():
		anims[a] = ap.get_animation(a)
	var root: Node2D = rig.get_node("Root")
	var d := {"parts": parts, "anims": anims, "root": {"position": root.position, "rotation": root.rotation}}
	rig.free()
	_defs[spr] = d
	return d


static func _collect(rig: Node, n: Node, parent: String, out: Array) -> void:
	for ch in n.get_children():
		if ch is Sprite2D:
			var s: Sprite2D = ch
			var p := String(rig.get_path_to(s))
			out.append({"name": s.name, "path": p, "parent": parent, "tex": s.texture.resource_path.get_file().get_basename(),
				"hframes": s.hframes, "offset": s.offset, "rest": {"position": s.position, "rotation": s.rotation, "frame": s.frame}})
			_collect(rig, s, p, out)
		elif ch.name == "Root":
			_collect(rig, ch, "", out)


static func has_anim(spr: String, anim: String) -> bool:
	var d = _def(spr)
	return d != null and d["anims"].has(anim)


static func length(spr: String, anim: String) -> float:
	var d = _def(spr)
	return d["anims"][anim].length if d != null and d["anims"].has(anim) else 0.0


## Piezas en orden de dibujo: [{tex, hframes, frame, offset, tr}].
static func pose(spr: String, anim: String, time: float) -> Array:
	var d = _def(spr)
	var vals := {"Root": d["root"].duplicate()}
	for p in d["parts"]:
		vals[p["path"]] = p["rest"].duplicate()
	var a: Animation = d["anims"].get(anim, null)
	if a != null:
		for ti in a.get_track_count():
			var tp := String(a.track_get_path(ti))
			var node := tp.get_slice(":", 0)
			var prop := tp.get_slice(":", 1)
			if vals.has(node) and vals[node].has(prop):
				vals[node][prop] = a.value_track_interpolate(ti, clampf(time, 0.0, a.length))
	var rv: Dictionary = vals["Root"]
	var trs := {"": Transform2D(rv["rotation"], Vector2.ONE, 0.0, (rv["position"] as Vector2).round())}
	var out := []
	for p in d["parts"]:
		var v: Dictionary = vals[p["path"]]
		var local := Transform2D(v["rotation"], Vector2.ONE, 0.0, (v["position"] as Vector2).round())
		var tr: Transform2D = trs[p["parent"]] * local
		trs[p["path"]] = tr
		out.append({"tex": p["tex"], "hframes": p["hframes"], "frame": int(v["frame"]), "offset": p["offset"], "tr": tr})
	return out


## Textura de una pieza con la variante de color (si existe) o la normal.
static func texture(spr: String, pal: String, tex: String) -> Texture2D:
	var key := "%s|%s|%s" % [spr, pal, tex]
	if not _tex.has(key):
		var p := SPRITES + "%s_%s/%s.png" % [spr, pal, tex]
		if pal == "" or not ResourceLoader.exists(p):
			p = SPRITES + "%s/%s.png" % [spr, tex]
		_tex[key] = load(p)
	return _tex[key]
