extends SceneTree
## Monta los enemigos por piezas de tools/enemy_defs.gd en escenas de Godot con su
## AnimationPlayer: scenes/enemigos/<id>.tscn. La escena se puede abrir y retocar en el
## editor; si se regenera con este script se sobrescribe.
## Uso: godot --headless --path . -s res://tools/build_enemy_rig.gd [-- id ...]

const Defs := preload("res://tools/enemy_defs.gd")
const Defs2 := preload("res://tools/enemy_defs_criaturas.gd")


func _init() -> void:
	var all := Defs.DEFS.duplicate()
	all.merge(Defs2.DEFS)
	var ids: Array = OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = all.keys()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/enemigos"))
	for id in ids:
		_build(id, all[id])
	quit()


func _build(id: String, def: Dictionary) -> void:
	var rig := Node2D.new()
	rig.name = id.capitalize().replace(" ", "")
	var root := Node2D.new()
	root.name = "Root"
	rig.add_child(root)
	root.owner = rig
	var nodes := {}
	var rest := {}
	# Pivote de cada pieza (lo escribe tools/enemigos.py): el offset por defecto es -pivote.
	var pivots := {}
	var jp := "res://assets/sprites/enemigos/%s/piezas.json" % id
	if FileAccess.file_exists(jp):
		pivots = JSON.parse_string(FileAccess.get_file_as_string(jp))
	for p in def["parts"]:
		var s := Sprite2D.new()
		s.name = p["name"]
		s.texture = load("res://assets/sprites/enemigos/%s/%s.png" % [id, p["tex"]])
		s.hframes = p.get("hframes", int(pivots.get(p["tex"], {}).get("frames", 1)))
		s.centered = false
		if p.has("offset"):
			s.offset = p["offset"]
		elif pivots.has(p["tex"]):
			var pv: Array = pivots[p["tex"]]["pivot"]
			s.offset = -Vector2(pv[0], pv[1])
		s.position = p["p"]
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var parent: Node = nodes.get(p.get("parent", ""), root)
		parent.add_child(s)
		s.owner = rig
		nodes[p["name"]] = s
		rest[p["name"]] = {"p": p["p"], "r": 0.0, "f": 0, "snap": p.get("snap", false), "path": String(rig.get_path_to(s))}
	# El cuerpo entero (Root) también se puede animar: posición y giro.
	rest["Root"] = {"p": Vector2.ZERO, "r": 0.0, "f": -1, "snap": false, "path": "Root"}
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	rig.add_child(ap)
	ap.owner = rig
	var lib := AnimationLibrary.new()
	for an in def["anims"]:
		lib.add_animation(an, _anim(def["anims"][an], rest))
	ap.add_animation_library("", lib)
	ap.autoplay = "idle"
	var ps := PackedScene.new()
	var err := ps.pack(rig)
	var out := "res://scenes/enemigos/%s.tscn" % id
	if err == OK:
		err = ResourceSaver.save(ps, out)
	print("enemigo ", id, ": ", error_string(err), " -> ", out, " (", def["anims"].size(), " animaciones)")
	rig.free()


## d = [duración, bucle, claves, opciones]. Opciones: {"cycle": {pieza: [segundos por
## fotograma, [fotogramas]]}} para piezas que recorren sus fotogramas sin parar (alas).
func _anim(d: Array, rest: Dictionary) -> Animation:
	var cycle: Dictionary = d[3].get("cycle", {}) if d.size() > 3 else {}
	var a := Animation.new()
	a.length = d[0]
	a.loop_mode = Animation.LOOP_LINEAR if d[1] else Animation.LOOP_NONE
	for part in rest:
		var r: Dictionary = rest[part]
		for prop in (["p", "r"] if part == "Root" else ["p", "r", "f"]):
			var ti := a.add_track(Animation.TYPE_VALUE)
			a.track_set_path(ti, r["path"] + ":" + {"p": "position", "r": "rotation", "f": "frame"}[prop])
			var discrete: bool = prop == "f" or (prop == "p" and r["snap"])
			a.value_track_set_update_mode(ti, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
			a.track_set_interpolation_type(ti, Animation.INTERPOLATION_NEAREST if discrete else Animation.INTERPOLATION_CUBIC)
			if prop == "f" and cycle.has(part):
				var per: float = cycle[part][0]
				var seq: Array = cycle[part][1]
				var k := 0
				while k * per < a.length - 0.0001:
					a.track_insert_key(ti, k * per, seq[k % seq.size()])
					k += 1
				continue
			for key in d[2]:
				var over: Dictionary = key[1].get(part, {})
				a.track_insert_key(ti, key[0], over.get(prop, r[prop]))
	return a
