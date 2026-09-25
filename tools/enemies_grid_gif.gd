extends SceneTree
## Vídeo de revisión con todos los enemigos por piezas a la vez (rejilla), en la animación
## pedida. Fotogramas en shots/enemigos_<anim>/ (tools/frames_to_gif.py hace el GIF).
## Uso: godot --path . -s res://tools/enemies_grid_gif.gd -- [anim] [zoom]   (con ventana)

const FPS := 24
const SECONDS := 2.0
const COLS := 6

var anim := "move"
var z := 3.0
var ids: Array = []
var cv: Node2D
var t := 0.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		anim = args[0]
	if args.size() > 1:
		z = float(args[1])
	for f in DirAccess.get_files_at("res://scenes/enemigos"):
		if f.ends_with(".tscn"):
			ids.append(f.get_basename())
	ids.sort()
	cv = Node2D.new()
	root.add_child(cv)
	cv.draw.connect(_paint)
	_run.call_deferred()


func _paint() -> void:
	cv.draw_rect(Rect2(0, 0, 960, 540), Color("#221e2c"))
	var rows := int(ceil(ids.size() / float(COLS)))
	var cw := 960.0 / COLS
	var ch := 540.0 / rows
	for i in ids.size():
		var id: String = ids[i]
		var a := anim if EnemyRig.length(id, anim) > 0.0 else "idle"
		var l := EnemyRig.length(id, a)
		var tt := fmod(t, maxf(l, 0.9))
		var feet := Vector2((i % COLS) * cw + cw / 2.0, (i / COLS) * ch + ch - 18)
		cv.draw_set_transform(Vector2.ZERO)
		cv.draw_rect(Rect2(feet.x - cw * 0.42, feet.y, cw * 0.84, 2), Color("#4a8a3a"))
		UiKit.text(cv, Vector2(feet.x, feet.y + 4), id, 8, UiKit.TEXT_DIM, 1)
		var base := Transform2D(0.0, Vector2(z, z), 0.0, feet)
		for p in EnemyRig.pose(id, a, minf(tt, l)):
			var tex: Texture2D = EnemyRig.texture(id, "", p["tex"])
			var fw: int = tex.get_width() / p["hframes"]
			var src := Rect2(p["frame"] * fw, 0, fw, tex.get_height())
			cv.draw_set_transform_matrix(base * (p["tr"] as Transform2D))
			cv.draw_texture_rect_region(tex, Rect2(p["offset"], src.size), src)
	cv.draw_set_transform(Vector2.ZERO)


func _run() -> void:
	var dir := "res://shots/enemigos_%s" % anim
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var n := int(SECONDS * FPS)
	for i in n:
		t = float(i) / FPS
		cv.queue_redraw()
		await process_frame
		await process_frame
		var img := root.get_texture().get_image()
		img.resize(960, 540, Image.INTERPOLATE_NEAREST)
		img.save_png("%s/%03d.png" % [dir, i])
	print("enemies_grid_gif ", anim, ": ", n, " fotogramas en ", dir)
	quit()
