extends SceneTree
## Vídeo de revisión de un enemigo por piezas: todas sus animaciones en bucle a velocidad
## real (ampliadas x6) y una casilla a tamaño de juego (x3) junto al Minero para comparar.
## Guarda los fotogramas en shots/enemigo_<id>/ (tools/frames_to_gif.py hace el GIF).
## Uso: godot --path . -s res://tools/enemy_gif.gd -- <id>   (necesita ventana)

const NAMES := {"idle": "Reposo", "move": "Moverse", "attack": "Ataque", "hurt": "Daño"}
const HERO_ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]
const FPS := 24
const SECONDS := 3.0

var id := ""
var rig: Node2D
var ap: AnimationPlayer
var hero: Node2D
var hero_ap: AnimationPlayer
var cv: Node2D
var t := 0.0
var anims: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	id = args[0] if args.size() > 0 else "limo"
	rig = load("res://scenes/enemigos/%s.tscn" % id).instantiate()
	rig.visible = false
	root.add_child(rig)
	ap = rig.get_node("AnimationPlayer")
	ap.speed_scale = 0.0
	for a in ["idle", "move", "attack", "hurt"]:
		if ap.has_animation(a):
			anims.append(a)
	hero = load("res://scenes/pj_rig.tscn").instantiate()
	hero.visible = false
	root.add_child(hero)
	hero_ap = hero.get_node("AnimationPlayer")
	hero_ap.speed_scale = 0.0
	cv = Node2D.new()
	root.add_child(cv)
	cv.draw.connect(_paint)
	_run.call_deferred()


## Dibuja todas las Sprite2D bajo `n` (en orden de árbol) con la transformación dada.
func _draw_parts(n: Node, base: Transform2D) -> void:
	for ch in n.get_children():
		if ch is Sprite2D:
			var s: Sprite2D = ch
			var tr := base * Transform2D(s.rotation, Vector2.ONE, 0.0, s.position.round())
			var fw := s.texture.get_width() / s.hframes
			var src := Rect2(s.frame * fw, 0, fw, s.texture.get_height())
			cv.draw_set_transform_matrix(tr)
			cv.draw_texture_rect_region(s.texture, Rect2(s.offset, src.size), src)
			_draw_parts(s, tr)
		elif ch is Node2D and ch.name == "Root":
			var r: Node2D = ch
			_draw_parts(r, base * Transform2D(r.rotation, Vector2.ONE, 0.0, r.position.round()))


func _paint() -> void:
	cv.draw_rect(Rect2(0, 0, 960, 540), Color("#221e2c"))
	var cols := anims.size() + 1
	var cw := 960.0 / cols
	for k in anims.size():
		ap.play(anims[k])
		var length := ap.current_animation_length
		ap.seek(minf(fmod(t, maxf(length, 0.9)), length), true)
		var feet := Vector2(cw * k + cw / 2.0, 330)
		cv.draw_set_transform(Vector2.ZERO)
		cv.draw_rect(Rect2(feet.x - cw * 0.4, feet.y, cw * 0.8, 3), Color("#4a8a3a"))
		UiKit.text(cv, Vector2(feet.x, feet.y + 12), NAMES.get(anims[k], anims[k]), 12, UiKit.TEXT_DIM, 1)
		_draw_parts(rig, Transform2D(0.0, Vector2(6, 6), 0.0, feet))
	# A tamaño de juego junto al Minero.
	var gx := cw * anims.size() + cw / 2.0
	var gfeet := Vector2(gx, 330)
	cv.draw_set_transform(Vector2.ZERO)
	cv.draw_rect(Rect2(gfeet.x - cw * 0.4, gfeet.y, cw * 0.8, 3), Color("#4a8a3a"))
	UiKit.text(cv, Vector2(gfeet.x, gfeet.y + 12), "En el juego", 12, UiKit.TEXT_DIM, 1)
	hero_ap.play("idle")
	hero_ap.seek(fmod(t, 2.0), true)
	var hr: Node2D = hero.get_node("Root")
	var hb := Transform2D(0.0, Vector2(3, 3), 0.0, gfeet + Vector2(-30, 0))
	for n in HERO_ORDER:
		var s: Sprite2D = hr.get_node(n)
		var tr := RigPose.pixel_tr(hr.transform * s.transform)
		tr.origin = tr.origin.round()
		cv.draw_set_transform_matrix(hb * tr)
		cv.draw_texture(s.texture, s.offset)
	ap.play("move")
	ap.seek(fmod(t, ap.current_animation_length), true)
	_draw_parts(rig, Transform2D(0.0, Vector2(-3, 3), 0.0, gfeet + Vector2(30, 0)))
	cv.draw_set_transform(Vector2.ZERO)


func _run() -> void:
	var dir := "res://shots/enemigo_%s" % id
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
	print("enemy_gif ", id, ": ", n, " fotogramas en ", dir)
	quit()
