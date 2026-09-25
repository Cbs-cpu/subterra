extends SceneTree
## Vídeo de revisión de las animaciones del esqueleto: las 8 animaciones a la vez, en
## bucle y a velocidad real (24 fps), ampliadas x5. Guarda los fotogramas en
## shots/rig_gif/ y tools/frames_to_gif.py los junta en shots/rig_anims.gif.
## Uso: godot --path . -s res://tools/rig_gif.gd   (necesita ventana)

const ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]
const ANIMS := ["idle", "run", "jump", "fall", "attack", "hurt", "dash", "down"]
const NAMES := ["Reposo", "Correr", "Salto", "Caída", "Ataque", "Daño", "Dash", "Abatido"]
const Z := 5.0
const FPS := 24
const SECONDS := 2.0

var rig: Node2D
var ap: AnimationPlayer
var cv: Node2D
var t := 0.0


func _init() -> void:
	rig = load("res://scenes/pj_rig.tscn").instantiate()
	rig.visible = false
	root.add_child(rig)
	ap = rig.get_node("AnimationPlayer")
	ap.speed_scale = 0.0
	cv = Node2D.new()
	root.add_child(cv)
	cv.draw.connect(_paint)
	_run.call_deferred()


func _paint() -> void:
	cv.draw_rect(Rect2(0, 0, 960, 540), Color("#221e2c"))
	var r: Node2D = rig.get_node("Root")
	for k in ANIMS.size():
		ap.play(ANIMS[k])
		var length := ap.current_animation_length
		# Las animaciones sin bucle se repiten con una pausa para verlas enteras.
		var lt := fmod(t, maxf(length, 0.6))
		ap.seek(minf(lt, length), true)
		var feet := Vector2(120 + (k % 4) * 240, 220 + (k / 4) * 260)
		cv.draw_set_transform(Vector2.ZERO)
		cv.draw_rect(Rect2(feet.x - 60, feet.y, 120, 3), Color("#4a8a3a"))
		UiKit.text(cv, Vector2(feet.x, feet.y + 10), NAMES[k], 12, UiKit.TEXT_DIM, 1)
		var base := Transform2D(0.0, Vector2(Z, Z), 0.0, feet)
		for n in ORDER:
			var s: Sprite2D = r.get_node(n)
			var tr := RigPose.pixel_tr(r.transform * s.transform)
			tr.origin = tr.origin.round()
			cv.draw_set_transform_matrix(base * tr)
			cv.draw_texture(s.texture, s.offset)
	cv.draw_set_transform(Vector2.ZERO)


func _run() -> void:
	var dir := "res://shots/rig_gif"
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
	print("rig_gif: ", n, " fotogramas en ", dir)
	quit()
