extends SceneTree
## Hoja de revisión de las animaciones del personaje por piezas (scenes/pj_rig.tscn):
## una fila por animación y 8 muestras por fila, ampliado x4. Necesita ventana (no headless).
## Uso: godot --path . -s res://tools/rig_strip.gd   -> shots/rig_anims.png

const ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]
const ANIMS := ["idle", "run", "jump", "fall", "attack", "hurt", "dash", "down"]
const COLS := 8
const Z := 4.0

var rig: Node2D
var ap: AnimationPlayer
var cv: Node2D


func _init() -> void:
	rig = load("res://scenes/pj_rig.tscn").instantiate()
	rig.visible = false
	root.add_child(rig)
	ap = rig.get_node("AnimationPlayer")
	ap.speed_scale = 0.0
	cv = Node2D.new()
	root.add_child(cv)
	cv.draw.connect(_paint)
	_shoot.call_deferred()


func _paint() -> void:
	var cw := 960.0 / COLS
	var ch := 540.0 / ANIMS.size()
	cv.draw_rect(Rect2(0, 0, 960, 540), Color("#221e2c"))
	var r: Node2D = rig.get_node("Root")
	for row in ANIMS.size():
		var anim: String = ANIMS[row]
		ap.play(anim)
		var length := ap.current_animation_length
		for col in COLS:
			ap.seek(length * col / COLS, true)
			var feet := Vector2(col * cw + cw / 2.0, row * ch + ch - 4)
			cv.draw_set_transform(Vector2.ZERO)
			cv.draw_rect(Rect2(feet.x - 36, feet.y, 72, 2), Color("#4a8a3a"))
			var base := Transform2D(0.0, Vector2(Z, Z), 0.0, feet)
			for n in ORDER:
				var s: Sprite2D = r.get_node(n)
				var t := RigPose.pixel_tr(r.transform * s.transform)
				t.origin = t.origin.round()
				cv.draw_set_transform_matrix(base * t)
				cv.draw_texture(s.texture, s.offset)
	cv.draw_set_transform(Vector2.ZERO)


func _shoot() -> void:
	for i in 4:
		await process_frame
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	img.save_png("res://shots/rig_anims.png")
	print("rig_strip -> shots/rig_anims.png ", img.get_size())
	quit()
