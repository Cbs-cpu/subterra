class_name TitleBackdrop
extends Node2D
## Fondo animado de la portada y los menús en pixel art gordito (rejilla de 240x135, cada
## píxel ocupa 2x2 píxeles lógicos): cielo nocturno con luna, estrellas que titilan y nubes,
## montañas, bosque lejano, bosque cercano con contorno negro, suelo de hierba y tierra, una
## hoguera y el Minero descansando a su lado, y luciérnagas. Las capas se desplazan con el
## ratón a saltos de un píxel (paralaje).

const W := 480.0
const H := 270.0
const LW := 240                  # ancho de la rejilla de píxeles
const LH := 135
const PX := 2.0                  # píxeles lógicos por píxel de la rejilla
const MARGIN := 10               # margen de las capas para el paralaje
const GROUND := 116              # altura del suelo en la rejilla
const INK := Color("#0e0a0a")
const FIRE := Vector2(74, GROUND)
const HERO := Vector2(58, GROUND)
const RIG_ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]

var t := 0.0
var dim := 0.0               # 0 = portada, 1 = submenús (fondo más apagado)
var _dim_to := 0.0
var _par := Vector2.ZERO
var _sky: ImageTexture
var _clouds: ImageTexture
var _far: ImageTexture
var _forest_far: ImageTexture
var _forest: ImageTexture
var _front: ImageTexture
var _stars: Array = []
var _flies: Array = []
var _rng := RandomNumberGenerator.new()
var _rig: Node2D
var _rig_ap: AnimationPlayer


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_rng.seed = 20260925
	_build()
	_rig = load("res://scenes/pj_rig.tscn").instantiate()
	_rig.visible = false
	add_child(_rig)
	_rig_ap = _rig.get_node("AnimationPlayer")
	_rig_ap.speed_scale = 0.0
	_rig_ap.play("idle")


func set_dimmed(on: bool) -> void:
	_dim_to = 1.0 if on else 0.0


func _process(dt: float) -> void:
	t += dt
	dim = move_toward(dim, _dim_to, dt * 3.0)
	var m := get_local_mouse_position()
	var want := Vector2(clampf((m.x - W / 2.0) / (W / 2.0), -1.0, 1.0), clampf((m.y - H / 2.0) / (H / 2.0), -1.0, 1.0))
	_par = _par.lerp(want, clampf(dt * 2.5, 0.0, 1.0))
	for f in _flies:
		f["p"] += f["v"] * dt
		f["v"] = f["v"].rotated(sin(t * f["f"] + f["ph"]) * dt * 1.5)
		if f["p"].x < 0 or f["p"].x > LW or f["p"].y < 40 or f["p"].y > GROUND:
			f["v"] = -f["v"]
			f["p"] = f["p"].clamp(Vector2(0, 40), Vector2(LW, GROUND))
	queue_redraw()


# --- Construcción de las capas (una vez) --------------------------------------------------

func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx in range(maxi(x, 0), mini(x + w, img.get_width())):
			img.set_pixel(xx, yy, c)


func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for yy in range(int(cy - r) - 1, int(cy + r) + 2):
		for xx in range(int(cx - r) - 1, int(cx + r) + 2):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				if Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length() <= r:
					img.set_pixel(xx, yy, c)


## Contorno negro de 1 px alrededor de todo lo opaco.
func _ink(img: Image) -> void:
	var src := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + d
				if n.x >= 0 and n.y >= 0 and n.x < img.get_width() and n.y < img.get_height() and src.get_pixelv(n).a > 0.0:
					img.set_pixel(x, y, INK)
					break


func _build() -> void:
	var lw := LW + MARGIN * 2
	# Cielo: bandas de color con tramado en las transiciones.
	var sky := _img(LW, LH)
	var bands := [Color("#0a0e24"), Color("#101a38"), Color("#16284a"), Color("#1e3a52"), Color("#2a5058"), Color("#3a6a5c")]
	for y in LH:
		var k := clampf(float(y) / GROUND, 0.0, 0.999) * (bands.size() - 1)
		var i := int(k)
		var f := k - i
		for x in LW:
			var dither = f > [0.2, 0.6, 0.4, 0.8][(x % 2) + (y % 2) * 2]
			sky.set_pixel(x, y, bands[mini(i + 1, bands.size() - 1)] if dither else bands[i])
	# Luna con cráteres y halo tramado.
	var mc := Vector2(220, 20)
	for y in range(int(mc.y) - 16, int(mc.y) + 17):
		for x in range(int(mc.x) - 16, int(mc.x) + 17):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(mc)
			if d < 15.0 and d > 9.0 and (x + y) % 2 == 0:
				sky.set_pixel(x, y, sky.get_pixel(x, y).lightened(0.12))
	_disc(sky, mc.x, mc.y, 9.0, Color("#f4efc8"))
	_disc(sky, mc.x + 2, mc.y - 1, 7.5, Color("#fffbe0"))
	for cr in [Vector2(-3, 2), Vector2(2, 4), Vector2(-1, -4)]:
		_rect(sky, int(mc.x + cr.x), int(mc.y + cr.y), 2, 2, Color("#d8d0a0"))
	_sky = ImageTexture.create_from_image(sky)
	for i in 70:
		_stars.append({"p": Vector2i(_rng.randi_range(0, LW - 1), _rng.randi_range(0, 70)), "ph": _rng.randf() * TAU, "b": _rng.randf_range(0.4, 1.0)})
	# Nubes: capa que se desplaza sola.
	var cl := _img(LW, 60)
	for i in 5:
		var cx := _rng.randi_range(10, LW - 30)
		var cy := _rng.randi_range(12, 50)
		for k in 4:
			_disc(cl, cx + k * 6, cy - (2 if k % 2 else 0), 4.0 + (k % 2) * 1.5, Color("#2a3e5e"))
		_rect(cl, cx - 3, cy, 26, 3, Color("#2a3e5e"))
	_clouds = ImageTexture.create_from_image(cl)
	# Montañas lejanas: dos crestas dentadas.
	var far := _img(lw, LH)
	for x in lw:
		var h1 := 70 + int(sin(x * 0.045) * 12.0 + sin(x * 0.13 + 1.0) * 5.0 + abs(sin(x * 0.021)) * 10.0)
		var h2 := 86 + int(sin(x * 0.07 + 2.0) * 8.0 + sin(x * 0.19) * 3.0)
		for y in range(h1, LH):
			far.set_pixel(x, y, Color("#1a2c40"))
		for y in range(h2, LH):
			far.set_pixel(x, y, Color("#1e3844"))
		if h1 < 66:
			far.set_pixel(x, h1, Color("#6a86a0"))       # nieve en las cumbres
	_far = ImageTexture.create_from_image(far)
	# Bosque lejano: copas redondas oscuras, sin contorno.
	var ff := _img(lw, LH)
	var x0 := -4
	while x0 < lw + 8:
		var th := _rng.randi_range(18, 30)
		_rect(ff, x0 + 3, GROUND - th, 2, th, Color("#1a2a22"))
		for k in 3:
			_disc(ff, x0 + 4 + _rng.randi_range(-2, 2), GROUND - th - 2 + k * 6, 6.0 - k * 0.5, Color("#1c3a2e"))
		x0 += _rng.randi_range(9, 14)
	_rect(ff, 0, GROUND - 6, lw, 8, Color("#1c3a2e"))
	_forest_far = ImageTexture.create_from_image(ff)
	# Bosque cercano: árboles de tronco grueso y copas por pisos, con contorno negro.
	var fo := _img(lw, LH)
	for tx in [8, 34, 150, 176, 212, 236]:
		_tree(fo, tx, GROUND, _rng.randi_range(34, 50))
	_ink(fo)
	_forest = ImageTexture.create_from_image(fo)
	# Suelo: hierba con matas y tierra con piedras.
	var fr := _img(lw, LH)
	for x in lw:
		var gt := GROUND - (1 if (x * 7) % 5 == 0 else 0) - (1 if (x * 13) % 11 == 0 else 0)
		for y in range(gt, LH):
			var c := Color("#6b4226")
			if y < GROUND + 2:
				c = Color("#6ac04a") if y == gt else Color("#3a8a2a")
			elif y < GROUND + 3:
				c = Color("#2a5a24")
			elif (x / 3 + y / 3) % 7 == 0:
				c = Color("#4a2e1a")
			fr.set_pixel(x, y, c)
	for i in 26:
		var sx := _rng.randi_range(0, lw - 4)
		var sy := _rng.randi_range(GROUND + 5, LH - 3)
		_rect(fr, sx, sy, 3, 2, Color("#8b8b9c"))
		_rect(fr, sx, sy, 3, 1, Color("#bdbdc9"))
	for i in 18:
		var gx := _rng.randi_range(0, lw - 1)
		for k in _rng.randi_range(2, 4):
			fr.set_pixel(gx, GROUND - 1 - k, Color("#5ab04a"))
			if k == 2:
				fr.set_pixel(gx + 1, GROUND - 2, Color("#5ab04a"))
	# Setas y flores.
	for m in [Vector2i(22, 0), Vector2i(128, 0), Vector2i(204, 0)]:
		_rect(fr, m.x + 1, GROUND - 3, 2, 3, Color("#f0e0c8"))
		_rect(fr, m.x - 1, GROUND - 5, 6, 2, Color("#c0302a"))
		fr.set_pixel(m.x + 1, GROUND - 5, Color.WHITE)
	for fl in [Vector2i(98, 0), Vector2i(118, 0), Vector2i(186, 0)]:
		fr.set_pixel(fl.x, GROUND - 1, Color("#3a8a2a"))
		fr.set_pixel(fl.x, GROUND - 2, Color("#f7d552"))
	# Leños de la hoguera.
	var fx := int(FIRE.x) + MARGIN
	_rect(fr, fx - 5, GROUND - 2, 10, 2, Color("#6b4226"))
	_rect(fr, fx - 3, GROUND - 3, 6, 1, Color("#9c6a3c"))
	for s in [-7, -4, 5, 7]:
		_rect(fr, fx + s - 1, GROUND - 1, 2, 1, Color("#8b8b9c"))
	_ink(fr)
	_front = ImageTexture.create_from_image(fr)
	for i in 16:
		_flies.append({"p": Vector2(_rng.randf_range(0, LW), _rng.randf_range(50, GROUND - 6)),
			"v": Vector2(_rng.randf_range(4, 10), 0).rotated(_rng.randf() * TAU), "f": _rng.randf_range(0.6, 1.6), "ph": _rng.randf() * TAU})


func _tree(img: Image, x: int, ground: int, h: int) -> void:
	var trunk := Color("#5a3a22")
	_rect(img, x - 2, ground - h, 4, h, trunk)
	_rect(img, x - 2, ground - h, 1, h, Color("#3a2414"))
	_rect(img, x + 1, ground - h, 1, h, Color("#7a5232"))
	_rect(img, x - 3, ground - 2, 6, 2, trunk)
	var leaf := [Color("#1e4a26"), Color("#2d6a34"), Color("#4a9a44")]
	var floors := 3
	for k in floors:
		var cy := ground - h + k * 9
		var r := 7.0 + k * 1.5
		_disc(img, x, cy, r, leaf[0])
		_disc(img, x - 1, cy - 1, r - 1.5, leaf[1])
		_disc(img, x - 2, cy - 3, r - 4.5, leaf[2])


# --- Dibujo -----------------------------------------------------------------------------

## Dibuja una capa de la rejilla desplazada `shift` píxeles de rejilla (enteros).
func _layer(tex: Texture2D, shift: Vector2, y := 0, tint := Color.WHITE) -> void:
	var p := Vector2(round(shift.x) - MARGIN, round(shift.y) + y) * PX
	draw_texture_rect(tex, Rect2(p, tex.get_size() * PX), false, tint)


func _px(p: Vector2, c: Color, s := 1.0) -> void:
	draw_rect(Rect2((p.floor()) * PX, Vector2(s, s) * PX), c)


func _draw() -> void:
	draw_texture_rect(_sky, Rect2(0, 0, W, H), false)
	# Estrellas que titilan.
	for s in _stars:
		var a: float = s["b"] * (0.55 + 0.45 * sin(t * 2.0 + s["ph"]))
		_px(Vector2(s["p"]), Color(1, 1, 0.9, a))
	# Nubes que pasan despacio.
	var cx := fmod(t * 3.0, float(LW))
	draw_texture_rect(_clouds, Rect2(Vector2(round(cx) - LW, 0) * PX, _clouds.get_size() * PX), false, Color(1, 1, 1, 0.6))
	draw_texture_rect(_clouds, Rect2(Vector2(round(cx), 0) * PX, _clouds.get_size() * PX), false, Color(1, 1, 1, 0.6))
	_layer(_far, -_par * 2.0)
	_layer(_forest_far, -_par * 4.0)
	_layer(_forest, -_par * 6.0)
	var front_shift := -_par * 8.0
	_layer(_front, front_shift)
	var off := Vector2(round(front_shift.x), round(front_shift.y))
	# Hoguera: resplandor y llamas.
	var fire := FIRE + off
	var flick := 0.85 + 0.15 * sin(t * 13.0) * sin(t * 7.3)
	UiKit.glow(self, (fire + Vector2(0, -5)) * PX, 70.0 * flick, Color(1.0, 0.55, 0.2, 0.22))
	var fl := [Color("#d0461e"), Color("#f58a2a"), Color("#ffd24a"), Color("#fff6c0")]
	for k in 4:
		var hgt := int(8 - k * 1.7 + sin(t * 11.0 + k) * 1.5)
		var wdt := 7 - k * 2
		for yy in hgt:
			var sway := int(round(sin(t * 9.0 + yy * 0.7 + k) * (yy / 5.0)))
			var ww := maxi(1, int(wdt * (1.0 - float(yy) / hgt)))
			draw_rect(Rect2((fire + Vector2(-ww / 2 + sway, -3 - yy)) * PX, Vector2(ww, 1) * PX), fl[k])
	for k in 3:
		var sp := fmod(t * 0.9 + k * 0.33, 1.0)
		_px(fire + Vector2(sin(t * 3.0 + k * 2.0) * 3.0, -8 - sp * 22.0), Color(1.0, 0.7, 0.3, 1.0 - sp))
	# El Minero descansando junto al fuego (mismas piezas y animación que en el juego).
	_draw_hero(HERO + off)
	# Luciérnagas.
	for f in _flies:
		var a2 := 0.5 + 0.5 * sin(t * 3.0 + f["ph"])
		UiKit.glow(self, f["p"] * PX + Vector2(1, 1), 7.0, Color(0.8, 1.0, 0.4, 0.25 * a2))
		_px(f["p"], Color(0.9, 1.0, 0.5, 0.5 + 0.5 * a2))
	# Viñeta y oscurecido de los submenús.
	draw_rect(Rect2(0, 0, W, H), Color(0, 0.02, 0.02, 0.18 + dim * 0.42))


func _draw_hero(feet: Vector2) -> void:
	_rig_ap.seek(fmod(t, 1.2), true)
	var r: Node2D = _rig.get_node("Root")
	var base := Transform2D(0.0, Vector2(PX, PX), 0.0, feet * PX)
	for n in RIG_ORDER:
		var s: Sprite2D = r.get_node(n)
		var tr := r.transform * s.transform
		tr.origin = tr.origin.round()
		draw_set_transform_matrix(base * tr)
		draw_texture(s.texture, s.offset)
	draw_set_transform_matrix(Transform2D.IDENTITY)
