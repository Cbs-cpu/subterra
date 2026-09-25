class_name TownDecor
extends Node2D
## Decoración del pueblo, detrás de los puestos y los vecinos: casitas de madera o piedra
## con tejados de colores, ventanas iluminadas y chimeneas que echan humo, farolas con la
## llama que parpadea, banderines que se mecen entre ellas, vallas, barriles, cajas,
## flores y setas luminosas. Todo en pixel art con contorno negro, como los personajes.

const T := 16
## Casas: [x en tiles, ancho, alto, pared, tejado, piedra].
const HOUSES := [
	[4, 44, 42, "#9c6a3c", "#c0302a", false], [16, 40, 38, "#8b8b9c", "#2a5ab0", true],
	[28, 46, 44, "#a8744a", "#3a8a2a", false], [39, 40, 40, "#9c6a3c", "#8a4ac0", false],
	[49, 44, 38, "#8b8b9c", "#c0801e", true], [59, 42, 44, "#a8744a", "#c0302a", false],
	[69, 40, 40, "#9c6a3c", "#2a5ab0", false],
]

var world: Node
var ground := 0.0
var map_w := 0.0
var t := 0.0
var _houses: Array = []      # [{tex, pos, chimney}]
var _posts: Array = []       # x de cada farola
var _props: Array = []       # [{tex, pos}]
var _flowers: Array = []     # [{p, c}]
var _shrooms: Array = []     # [{p, ph}]


func setup(w: Node, ground_y: float, width_px: float, lamp_xs: Array) -> void:
	world = w
	ground = ground_y
	map_w = width_px
	_posts = lamp_xs
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210 + int(width_px)
	for h in HOUSES:
		var tex := _house(h[1], h[2], Color(h[3]), Color(h[4]), h[5], rng.randi())
		var pos := Vector2(h[0] * T, ground - h[2])
		_houses.append({"tex": tex, "pos": pos, "chimney": pos + Vector2(h[1] - 12, 0)})
		# Luz cálida de las ventanas.
		var l := Art.make_light(Color("#ffc86a"), 40.0, 0.9)
		l.position = pos + Vector2(h[1] / 2.0, h[2] * 0.55)
		w.light_root.add_child(l)
	var barrel := _barrel()
	var crate := _crate()
	var fence := _fence()
	for i in 14:
		var x := rng.randf_range(40, width_px - 60)
		var k := rng.randi() % 3
		var tex: Texture2D = [barrel, crate, fence][k]
		_props.append({"tex": tex, "pos": Vector2(roundf(x), ground - tex.get_height())})
	for i in 40:
		_flowers.append({"p": Vector2(roundf(rng.randf_range(10, width_px - 10)), ground - 1),
			"c": [Color("#f7d552"), Color("#e7574d"), Color("#ffffff"), Color("#c77af5"), Color("#4fa9ec")][rng.randi() % 5]})
	for i in 8:
		_shrooms.append({"p": Vector2(roundf(rng.randf_range(20, width_px - 20)), ground), "ph": rng.randf() * TAU})
		var sl := Art.make_light(Color("#6ae8d8"), 20.0, 0.6)
		sl.position = _shrooms[-1]["p"] + Vector2(0, -3)
		w.light_root.add_child(sl)


func _process(dt: float) -> void:
	t += dt
	queue_redraw()


# --- Texturas (una vez) -------------------------------------------------------------------

static func _house(w: int, h: int, wall: Color, roof: Color, stone: bool, seed_value: int) -> ImageTexture:
	var c := Pix.new(w, h)
	var roof_h := int(h * 0.42)
	# Pared: tablones horizontales o sillares.
	c.rect(3, roof_h - 2, w - 6, h - roof_h + 2, wall)
	for y in range(roof_h, h, 4):
		c.rect(3, y, w - 6, 1, wall.darkened(0.25))
		if stone:
			for x in range(3 + ((y / 4) % 2) * 4, w - 3, 8):
				c.rect(x, y, 1, 4, wall.darkened(0.25))
	c.rect(3, roof_h - 2, 2, h - roof_h + 2, wall.lightened(0.15))
	c.rect(w - 6, roof_h - 2, 3, h - roof_h + 2, wall.darkened(0.2))
	# Tejado a dos aguas con tejas en filas.
	for y in roof_h:
		var inset := int(float(roof_h - y) * (w / 2.0 - 3.0) / roof_h)
		var col := roof if (y / 3) % 2 == 0 else roof.darkened(0.15)
		c.rect(inset, y + 1, w - inset * 2, 1, col)
	c.rect(1, roof_h, w - 2, 2, roof.darkened(0.3))
	# Chimenea.
	c.rect(w - 14, 2, 5, roof_h / 2, Color("#6e6878"))
	c.rect(w - 15, 1, 7, 2, Color("#8b8b9c"))
	# Puerta con pomo.
	var dx := int(w * 0.3)
	c.rect(dx, h - 13, 8, 13, Color("#5a3a22"))
	c.rect(dx + 1, h - 12, 6, 1, Color("#7a5232"))
	c.px(dx + 6, h - 7, Color("#f0b93a"))
	# Ventana con luz y cruceta.
	var wx := dx + 13
	var wy := roof_h + 4
	c.rect(wx, wy, 8, 7, Color("#ffd46a"))
	c.rect(wx, wy, 8, 1, Color("#fff2b0"))
	c.rect(wx + 3, wy, 1, 7, Color("#5a3a22"))
	c.rect(wx, wy + 3, 8, 1, Color("#5a3a22"))
	c.rect(wx - 1, wy + 7, 10, 1, Color("#5a3a22"))
	c.ink()
	return c.tex()


static func _barrel() -> ImageTexture:
	var c := Pix.new(12, 13)
	c.rect(2, 1, 8, 11, Color("#9c6a3c"))
	c.rect(1, 3, 10, 7, Color("#9c6a3c"))
	c.rect(2, 1, 2, 11, Color("#c9975e"))
	for y in [3, 8]:
		c.rect(1, y, 10, 1, Color("#5d5d6e"))
	c.ink()
	return c.tex()


static func _crate() -> ImageTexture:
	var c := Pix.new(12, 11)
	c.rect(1, 1, 10, 9, Color("#a8744a"))
	c.rect(1, 1, 10, 1, Color("#c9975e"))
	c.rect(1, 5, 10, 1, Color("#6b4226"))
	c.line(1, 1, 10, 9, Color("#6b4226"))
	c.ink()
	return c.tex()


static func _fence() -> ImageTexture:
	var c := Pix.new(20, 10)
	for x in [1, 8, 15]:
		c.rect(x, 1, 3, 8, Color("#c9975e"))
		c.px(x + 1, 0, Color("#c9975e"))
	c.rect(1, 3, 18, 2, Color("#9c6a3c"))
	c.rect(1, 6, 18, 1, Color("#9c6a3c"))
	c.ink()
	return c.tex()


# --- Dibujo --------------------------------------------------------------------------------

func _draw() -> void:
	# Humo de las chimeneas (detrás de las casas).
	for i in _houses.size():
		var ch: Vector2 = _houses[i]["chimney"]
		for k in 4:
			var f := fmod(t * 0.35 + k * 0.25 + i * 0.13, 1.0)
			var p := ch + Vector2(roundf(sin(t * 1.3 + k + i) * 2.0 + f * 6.0), -f * 26.0)
			var s := 2.0 + f * 3.0
			draw_rect(Rect2(p.round() - Vector2(s, s) / 2.0, Vector2(s, s)), Color(0.75, 0.75, 0.8, 0.45 * (1.0 - f)))
	for hs in _houses:
		draw_texture(hs["tex"], hs["pos"])
	for pr in _props:
		draw_texture(pr["tex"], pr["pos"])
	# Flores: tallo y un píxel de color que se mece.
	for fl in _flowers:
		var sway := roundf(sin(t * 1.5 + fl["p"].x * 0.1) * 0.6)
		draw_rect(Rect2(fl["p"] + Vector2(0, -2), Vector2(1, 2)), Color("#3a8a2a"))
		draw_rect(Rect2(fl["p"] + Vector2(sway, -3), Vector2(1, 1)), fl["c"])
	# Setas luminosas.
	for sh in _shrooms:
		var g := 0.7 + 0.3 * sin(t * 2.0 + sh["ph"])
		var p0: Vector2 = sh["p"]
		draw_rect(Rect2(p0 + Vector2(-1, -3), Vector2(2, 3)), Color("#e0f0e8"))
		draw_rect(Rect2(p0 + Vector2(-3, -5), Vector2(6, 2)), Color(0.42 * g, 0.9 * g, 0.85 * g))
		draw_rect(Rect2(p0 + Vector2(-2, -6), Vector2(4, 1)), Color(0.6 * g, 1.0 * g, 0.95 * g))
	# Banderines entre farolas: cuerda que cuelga y triángulos de colores que se mecen.
	var cols := [Color("#e7574d"), Color("#f7d552"), Color("#5fbf48"), Color("#4fa9ec"), Color("#c77af5")]
	for i in range(_posts.size() - 1):
		var a := Vector2(_posts[i], ground - 30)
		var b := Vector2(_posts[i + 1], ground - 30)
		var n := int((b.x - a.x) / 8.0)
		for k in n + 1:
			var f2 := float(k) / n
			var p2 := a.lerp(b, f2) + Vector2(0, roundf(sin(f2 * PI) * 12.0 + sin(t * 1.4 + k * 0.5) * 0.8))
			draw_rect(Rect2(p2.round(), Vector2(1, 1)), Color("#3a2a1e"))
			if k % 2 == 1:
				var c: Color = cols[(k / 2 + i) % cols.size()]
				draw_colored_polygon(PackedVector2Array([p2.round() + Vector2(-2, 1), p2.round() + Vector2(3, 1), p2.round() + Vector2(0, 6)]), c)
	# Farolas: poste, farol y llama que parpadea.
	for x in _posts:
		var base := Vector2(roundf(x), ground)
		draw_rect(Rect2(base + Vector2(-2, -32), Vector2(4, 32)), Color("#0e0a0a"))
		draw_rect(Rect2(base + Vector2(-1, -31), Vector2(2, 31)), Color("#3a3a46"))
		draw_rect(Rect2(base + Vector2(-4, -40), Vector2(8, 9)), Color("#0e0a0a"))
		draw_rect(Rect2(base + Vector2(-3, -39), Vector2(6, 7)), Color("#ffd46a"))
		var fl2 := 0.8 + 0.2 * sin(t * 12.0 + x) * sin(t * 7.0)
		draw_rect(Rect2(base + Vector2(-1, -37), Vector2(2, 3)), Color(1.0, 0.55 * fl2 + 0.3, 0.2))
		draw_rect(Rect2(base + Vector2(-5, -41), Vector2(10, 2)), Color("#0e0a0a"))
