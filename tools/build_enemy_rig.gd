extends SceneTree
## Monta los enemigos por piezas de tools/enemy_defs.gd en escenas de Godot con su
## AnimationPlayer: scenes/enemigos/<id>.tscn. La escena se puede abrir y retocar en el
## editor; si se regenera con este script se sobrescribe.
## Uso: godot --headless --path . -s res://tools/build_enemy_rig.gd [-- id ...]

const Defs := preload("res://tools/enemy_defs.gd")


func _init() -> void:
	var ids: Array = OS.get_cmdline_user_args()
	if ids.is_empty():
		ids = Defs.DEFS.keys()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/enemigos"))
	for id in ids:
		_build(id, Defs.DEFS[id])
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
	for p in def["parts"]:
		var s := Sprite2D.new()
		s.name = p["name"]
		s.texture = load("res://assets/sprites/enemigos/%s/%s.png" % [id, p["tex"]])
		s.hframes = p.get("hframes", 1)
		s.centered = false
		s.offset = p["offset"]
		s.position = p["p"]
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var parent: Node = nodes.get(p.get("parent", ""), root)
		parent.add_child(s)
		s.owner = rig
		nodes[p["name"]] = s
		rest[p["name"]] = {"p": p["p"], "r": 0.0, "f": 0, "snap": p.get("snap", false), "path": String(rig.get_path_to(s))}
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


func _anim(d: Array, rest: Dictionary) -> Animation:
	var a := Animation.new()
	a.length = d[0]
	a.loop_mode = Animation.LOOP_LINEAR if d[1] else Animation.LOOP_NONE
	for part in rest:
		var r: Dictionary = rest[part]
		for prop in ["p", "r", "f"]:
			var ti := a.add_track(Animation.TYPE_VALUE)
			a.track_set_path(ti, r["path"] + ":" + {"p": "position", "r": "rotation", "f": "frame"}[prop])
			var discrete: bool = prop == "f" or (prop == "p" and r["snap"])
			a.value_track_set_update_mode(ti, Animation.UPDATE_DISCRETE if discrete else Animation.UPDATE_CONTINUOUS)
			a.track_set_interpolation_type(ti, Animation.INTERPOLATION_NEAREST if discrete else Animation.INTERPOLATION_CUBIC)
			for key in d[2]:
				var over: Dictionary = key[1].get(part, {})
				a.track_insert_key(ti, key[0], over.get(prop, r[prop]))
	return a
