extends SceneTree
## Hornea fotogramas del caballero 3D (KnightView) a PNG para las vistas 2D que no tienen héroe
## vivo (creación de personaje, retrato del HUD, estela del dash): assets/sprites/caballero/
## <anim>_<i>.png y anchors.json con los pies, la mano y la coronilla de cada fotograma.
## Necesita ventana (no headless): godot --path . -s res://tools/bake_knight.gd
## Escribe también shots/caballero_hoja.png (todo ampliado x4) para revisar.

const OUT := "res://assets/sprites/caballero/"
## anim: [fotogramas, duración que se recorre, velocidad simulada (px/s)]
const BAKE := {
	"idle": [4, 2.0, Vector2.ZERO], "run": [8, 0.56, Vector2(150, 0)], "dash": [2, 0.2, Vector2(300, 0)],
	"attack": [4, 0.3, Vector2.ZERO], "jump": [2, 0.4, Vector2(60, -300)], "fall": [2, 0.4, Vector2(60, 250)],
	"hurt": [2, 0.24, Vector2(-80, -100)], "down": [1, 2.0, Vector2.ZERO],
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	var kv := KnightView.new()
	root.add_child(kv)
	await process_frame
	var anchors := {}
	var sheet_rows := []
	for anim in BAKE:
		var spec: Array = BAKE[anim]
		var n: int = spec[0]
		var row := []
		anchors[anim] = []
		for i in n:
			var t: float = spec[1] * (float(i) / n if anim in ["idle", "run", "dash"] else (1.0 if n == 1 else float(i) / (n - 1)))
			# Deja que las telas se asienten con la velocidad de la animación.
			for k in 40:
				kv.set_pose(anim, t)
				kv.move(spec[2], 1, 1.0 / 60.0)
				await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = kv.texture.get_image()
			img.save_png(OUT + "%s_%d.png" % [anim, i])
			row.append(img)
			var hp := kv.hand_pos().round()
			var hd := kv.head_top().round()
			anchors[anim].append({"hand": [hp.x, hp.y], "head": [hd.x, hd.y]})
		sheet_rows.append(row)
	var f := FileAccess.open(OUT + "anchors.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"feet": [KnightView.FEET.x, KnightView.FEET.y], "frames": anchors}, "\t"))
	f.close()
	# Hoja de revisión ampliada x4 sobre fondo oscuro.
	var w := KnightView.SIZE.x
	var h := KnightView.SIZE.y
	var sheet := Image.create(w * 8, h * sheet_rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#26222c"))
	for r in sheet_rows.size():
		for c in sheet_rows[r].size():
			var im: Image = sheet_rows[r][c]
			im.convert(Image.FORMAT_RGBA8)
			sheet.blend_rect(im, Rect2i(0, 0, w, h), Vector2i(c * w, r * h))
	sheet.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://shots/caballero_hoja.png")
	print("bake_knight: ", anchors.size(), " animaciones -> ", OUT)
	quit()
