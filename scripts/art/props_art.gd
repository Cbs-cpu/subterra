class_name PropsArt
extends RefCounted
## Arte del mundo: árboles, rocas, hierba, cofres, colmenas, trampas, puertas, puestos del
## pueblo, altares, sombreros y compañeros.

const TREE_COLORS := {
	"bosque": ["#1e4a1e", "#2e7a2e", "#5ab04a", "#6b4226"], "cienaga": ["#2e1a4a", "#5a2a8a", "#8a4ac0", "#3a2a22"],
	"pradera": ["#6a1a2a", "#b03a4a", "#e0707a", "#5a3a2a"], "tundra": ["#1a3a3a", "#2a5a5a", "#e8f4ff", "#4a3a2a"],
	"volcan": ["#6a2a0a", "#c05a1a", "#f0a02a", "#2a1a14"], "cantera": ["#1a5a5a", "#2aa8a0", "#8ae8e0", "#4a5a6a"],
	"crater": ["#2a1a4a", "#6a3aa0", "#c08af0", "#2a2a3a"],
}
const ORE_COLORS := {"piedra": "", "carbon": "#141418", "hierro": "#d0b090", "oro": "#f0c03a", "diamante": "#6ae8f0", "ceniza": "#e05a9a"}
const GRASS := {
	"bosque": "#4a9a3a", "cienaga": "#7a4aa0", "pradera": "#d05a6a", "tundra": "#e0ecf4", "volcan": "#e0802a",
	"cantera": "#5ad0c0", "crater": "#a07ae0", "cavernas": "#6a6a7a", "mazmorra": "#5a5a4a", "nido": "#6a3a5a",
}


static func tree(biome: String, variant: int) -> ImageTexture:
	var col: Array = TREE_COLORS.get(biome, TREE_COLORS["bosque"])
	var c := Pix.new(28, 44)
	var trunk := Color(col[3])
	c.rect(11, 20, 6, 24, trunk)
	c.rect(11, 20, 2, 24, trunk.lightened(0.2))
	c.rect(9, 41, 10, 3, trunk)
	if biome == "tundra":
		for k in 4:
			var wv := 6 + k * 3
			c.rect(14 - wv, 4 + k * 7, wv * 2, 7, Color(col[1]))
			c.rect(14 - wv, 4 + k * 7, wv * 2, 2, Color(col[2]))
		return _done(c)
	if biome == "volcan":
		c.rect(8, 8, 12, 34, Color(col[1]))
		c.rect(8, 8, 3, 34, Color(col[2]))
		for k in 5:
			c.px(12 + (k % 2) * 4, 12 + k * 6, Color(col[0]))
		return _done(c)
	if biome == "cantera":
		for k in 3:
			c.line(14, 22, 6 + k * 8, 4 + (k % 2) * 4, Color(col[2]), 3)
		c.ellipse(14, 10, 8, 7, Color(col[1]))
		c.ellipse(12, 8, 3, 3, Color(col[2]))
		return _done(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 31 + biome.hash()
	c.ellipse(14, 14, 12, 11, Color(col[0]))
	c.ellipse(13, 12, 10, 9, Color(col[1]))
	for k in 5:
		c.ellipse(rng.randi_range(6, 20), rng.randi_range(6, 16), 3, 2.5, Color(col[2]))
	return _done(c)


const PLANT_COLORS := {
	"bosque": ["#1e5a2a", "#3a9a3a", "#8ae05a", "#2a6a2a"], "cienaga": ["#3a1a5a", "#6a2aa0", "#b07ae0", "#2a5a2a"],
	"pradera": ["#6a1a3a", "#c03a5a", "#ff8aa0", "#4a6a2a"], "cavernas": ["#1a3a4a", "#2a6a7a", "#6ad0e0", "#2a4a4a"],
	"tundra": ["#2a4a6a", "#6a9ac0", "#e0f4ff", "#3a5a6a"], "mazmorra": ["#3a3a2a", "#6a6a3a", "#b0b06a", "#3a3a2a"],
	"volcan": ["#6a1a0a", "#c04a1a", "#ffb04a", "#3a1a14"], "cantera": ["#1a5a5a", "#2ab0a0", "#9af0e8", "#2a4a5a"],
	"crater": ["#3a1a6a", "#7a3ac0", "#e0a0ff", "#2a2a4a"], "nido": ["#4a0e2a", "#8a1a4a", "#ff4a8a", "#2a0e1a"],
}


## Árbol alto de fondo: tronco fino con cojines de hojas redondeados, alternando lados.
static func plant(biome: String, h: int, variant: int) -> ImageTexture:
	var col: Array = PLANT_COLORS.get(biome, PLANT_COLORS["bosque"])
	var c := Pix.new(24, h)
	var trunk := Color(col[3]).darkened(0.1)
	var leaf := Color(col[1])
	var leaf_hi := Color(col[2])
	var leaf_lo := Color(col[0])
	var x := 11
	for y in range(6, h):
		c.px(x, y, trunk)
		c.px(x + 1, y, trunk.darkened(0.35))
		if (y + variant) % 9 == 0:
			c.px(x - 1 if (y / 9) % 2 == 0 else x + 2, y, trunk.lightened(0.2))
	# Cojines de hojas.
	var k := 0
	for y in range(10 + variant % 4, h - 6, 9):
		var side := -1 if k % 2 == 0 else 1
		var cx := x + side * 5 + (1 if side > 0 else 0)
		c.ellipse(cx, y, 3.6, 2.2, leaf_lo)
		c.ellipse(cx, y - 0.6, 3.2, 1.7, leaf)
		c.rect(cx - 2, y - 2, 3, 1, leaf_hi)
		c.line(x + (1 if side > 0 else 0), y + 1, cx - side * 2, y, trunk)
		k += 1
	# Copa.
	c.ellipse(x + 0.5, 4, 5.5, 3.8, leaf_lo)
	c.ellipse(x + 0.5, 3.5, 5, 3.2, leaf)
	c.rect(x - 3, 1, 5, 1, leaf_hi)
	c.rect(x - 4, 2, 2, 1, leaf_hi)
	c.outline(Color(leaf_lo.darkened(0.6)))
	return c.tex()


## Enredadera que cuelga del techo.
static func vine(biome: String, h: int, variant: int) -> ImageTexture:
	var col: Array = PLANT_COLORS.get(biome, PLANT_COLORS["bosque"])
	var c := Pix.new(8, h)
	for y in h:
		var x := 3 + roundi(sin(y * 0.35 + variant) * 1.5)
		c.px(x, y, Color(col[0]))
		if (y + variant) % 4 == 0:
			c.px(x + 1, y, Color(col[1]))
			c.px(x - 1, y + 1, Color(col[1]))
	c.px(3, h - 1, Color(col[2]))
	return c.tex()


static func _done(c: Pix) -> ImageTexture:
	c.outline()
	return c.tex()


static func rock(ore: String, biome: String) -> ImageTexture:
	var c := Pix.new(18, 14)
	var base := "piedra"
	if biome in ["tundra"]:
		base = "hielo"
	elif biome in ["volcan", "nido"]:
		base = "obsidiana"
	elif biome == "cantera":
		base = "cristal"
	c.ellipse(9, 8, 8, 6, Pix.ramp(base, 1))
	c.ellipse(8, 7, 6, 4.5, Pix.ramp(base, 2))
	c.ellipse(6, 5, 2.5, 1.5, Pix.ramp(base, 3))
	var oc: String = ORE_COLORS.get(ore, "")
	if oc != "":
		for d in [Vector2i(10, 6), Vector2i(12, 9), Vector2i(6, 9), Vector2i(8, 4), Vector2i(13, 5)]:
			c.rect(d.x, d.y, 2, 1, Color(oc))
			c.px(d.x, d.y - 1, Color(oc).lightened(0.4))
	return _done(c)


static func grass(biome: String, frame: int) -> ImageTexture:
	var c := Pix.new(14, 10)
	var g := Color(GRASS.get(biome, "#4a9a3a"))
	for k in 5:
		var x := 2 + k * 2
		var sway := 1 if frame == 1 and k % 2 == 0 else 0
		c.line(x, 10, x + sway + (1 if k % 2 == 0 else -1), 3 + (k % 3), g if k % 2 == 0 else g.darkened(0.25))
	return _done(c)


static func chest(golden: bool, open: bool) -> ImageTexture:
	var c := Pix.new(16, 13)
	var r := "oro" if golden else "madera"
	c.rect(1, 6, 14, 7, Pix.ramp(r, 1))
	c.rect(1, 6, 14, 1, Pix.ramp(r, 2))
	if not open:
		c.rect(1, 1, 14, 5, Pix.ramp(r, 2))
		c.rect(1, 1, 14, 1, Pix.ramp(r, 3))
		c.rect(7, 4, 2, 3, Pix.ramp("hierro" if golden else "oro", 2))
	else:
		c.rect(1, 0, 14, 2, Pix.ramp(r, 2))
		c.rect(2, 6, 12, 2, Color("#1a1320"))
	c.rect(1, 9, 14, 1, Pix.ramp(r, 0))
	return _done(c)


static func egg() -> ImageTexture:
	var c := Pix.new(12, 14)
	c.ellipse(6, 8, 5, 6, Color("#e8e0d0"))
	c.ellipse(5, 6, 2, 3, Color("#ffffff"))
	c.line(2, 4, 10, 12, Color("#c0b8a8"))
	return _done(c)


static func hive() -> ImageTexture:
	var c := Pix.new(16, 18)
	for k in 4:
		c.ellipse(8, 4 + k * 3.5, 4 + k * 1.2, 2.5, Pix.ramp("oro", 2 if k % 2 == 0 else 1))
	c.rect(6, 12, 4, 3, Color("#1a1320"))
	return _done(c)


static func hazard(id: String, frame: int) -> ImageTexture:
	var c: Pix
	match id:
		"bloque_pinchos":
			c = Pix.new(18, 18)
			c.rect(3, 3, 12, 12, Pix.ramp("piedra", 2))
			c.rect(3, 3, 12, 2, Pix.ramp("piedra", 3))
			for k in 3:
				c.px(5 + k * 4, 1, Pix.ramp("hierro", 3))
				c.px(5 + k * 4, 16, Pix.ramp("hierro", 3))
				c.px(1, 5 + k * 4, Pix.ramp("hierro", 3))
				c.px(16, 5 + k * 4, Pix.ramp("hierro", 3))
				c.px(5 + k * 4, 2, Pix.ramp("hierro", 2))
				c.px(5 + k * 4, 15, Pix.ramp("hierro", 2))
				c.px(2, 5 + k * 4, Pix.ramp("hierro", 2))
				c.px(15, 5 + k * 4, Pix.ramp("hierro", 2))
		"espora":
			c = Pix.new(14, 14)
			var open := frame == 1
			c.rect(6, 7, 2, 7, Pix.ramp("hierba", 1))
			c.ellipse(7, 5, 5 if open else 4, 4 if open else 3, Pix.ramp("morada", 2))
			c.ellipse(7, 4, 2, 1.5 if open else 1, Pix.ramp("morada", 0) if open else Pix.ramp("morada", 3))
		"bola_pinchos":
			c = Pix.new(18, 18)
			c.ellipse(9, 9, 5, 5, Pix.ramp("hierro", 1))
			for a in 8:
				var v := Vector2(cos(a * PI / 4.0), sin(a * PI / 4.0))
				c.line(9, 9, 9 + roundi(v.x * 8), 9 + roundi(v.y * 8), Pix.ramp("hierro", 3))
			c.ellipse(8, 8, 2, 2, Pix.ramp("hierro", 2))
		"carambano":
			c = Pix.new(10, 18)
			for y in 16:
				var wv := maxi(1, 4 - y / 4)
				c.rect(5 - wv, y, wv * 2, 1, Pix.ramp("hielo", 3 if y % 5 == 0 else 2))
		"columna_fuego":
			c = Pix.new(14, 14)
			var f := frame % 2
			c.ellipse(7, 7, 6, 6, Pix.ramp("fuego", 1 + f))
			c.ellipse(7, 7, 4, 4, Pix.ramp("fuego", 2 + f))
			c.ellipse(6, 6, 2, 2, Color("#fff8c0"))
		"cuchilla_cristal":
			c = Pix.new(20, 20)
			var rot := frame * PI / 8.0
			for a in 4:
				var v := Vector2(cos(a * PI / 2.0 + rot), sin(a * PI / 2.0 + rot))
				c.line(10, 10, 10 + roundi(v.x * 9), 10 + roundi(v.y * 9), Pix.ramp("cristal", 3), 2)
			c.ellipse(10, 10, 3, 3, Pix.ramp("cristal", 2))
		"bola_cosmica":
			c = Pix.new(14, 14)
			c.ellipse(7, 7, 6, 6, Pix.ramp("ceniza", 3))
			c.ellipse(7, 7, 4, 4, Color("#ffc0e0"))
			c.px(5, 5, Color.WHITE)
		_:
			c = Pix.new(8, 8)
			c.rect(0, 0, 8, 8, Color.MAGENTA)
	return _done(c)


static func door(color_hex: String, frame: int) -> ImageTexture:
	var c := Pix.new(36, 50)
	var stone := Pix.ramp("piedra", 1)
	c.rect(2, 8, 32, 42, stone)
	c.ellipse(18, 10, 16, 10, stone)
	c.rect(6, 12, 24, 38, Color(color_hex).darkened(0.5))
	c.ellipse(18, 13, 12, 7, Color(color_hex).darkened(0.5))
	# Remolino interior.
	var col := Color(color_hex)
	for k in 6:
		var a := k * TAU / 6.0 + frame * 0.5
		c.ellipse(18 + cos(a) * 6.0, 30 + sin(a) * 9.0, 3, 3, col if k % 2 == 0 else col.lightened(0.3))
	c.ellipse(18, 30, 4, 6, col.lightened(0.5))
	for k in 5:
		c.rect(3, 12 + k * 8, 3, 1, Pix.ramp("piedra", 3))
		c.rect(30, 16 + k * 8, 3, 1, Pix.ramp("piedra", 3))
	return _done(c)


static func stall(kind: String) -> ImageTexture:
	var c := Pix.new(56, 44)
	var awn := {"tendero": "#c0302a", "herrero": "#3a3a46", "sastra": "#8a4ac0", "peletero": "#7a4e2a",
		"comprador": "#c0901e"}.get(kind, "#2a6a8a")
	var awning := Color(awn)
	c.rect(4, 14, 48, 30, Pix.ramp("madera", 1))
	c.rect(4, 14, 48, 2, Pix.ramp("madera", 2))
	c.rect(6, 30, 44, 4, Pix.ramp("madera", 2))
	c.rect(6, 34, 44, 10, Pix.ramp("madera", 0))
	for k in 7:
		c.rect(2 + k * 8, 4, 8, 8, awning if k % 2 == 0 else Color("#f0e8d0"))
	c.rect(2, 12, 52, 2, awning.darkened(0.3))
	c.rect(4, 14, 2, 30, Pix.ramp("madera", 0))
	c.rect(50, 14, 2, 30, Pix.ramp("madera", 0))
	match kind:
		"herrero":
			c.rect(40, 22, 8, 8, Pix.ramp("fuego", 1))
			c.rect(41, 24, 6, 4, Pix.ramp("fuego", 3))
			c.rect(12, 26, 10, 4, Pix.ramp("hierro", 1))
		"sastra":
			for k in 3:
				c.rect(12 + k * 8, 18, 5, 10, Pix.ramp(["piel", "tela", "misterio"][k], 2))
		"peletero":
			for k in 3:
				c.rect(12 + k * 8, 18, 6, 9, Pix.ramp("cuero", 2 + k % 2))
		"comprador":
			for k in 5:
				c.ellipse(14 + k * 5, 27, 2, 2, Pix.ramp("oro", 3))
	return _done(c)


static func altar(idx: int) -> ImageTexture:
	var c := Pix.new(24, 36)
	var gem: String = ["fuego", "ceniza", "hierba", "rayo"][idx % 4]
	c.rect(4, 26, 16, 10, Pix.ramp("piedra", 1))
	c.rect(4, 26, 16, 2, Pix.ramp("piedra", 3))
	c.rect(8, 8, 8, 18, Pix.ramp("piedra", 2))
	c.rect(8, 8, 2, 18, Pix.ramp("piedra", 3))
	c.ellipse(12, 6, 5, 5, Pix.ramp(gem, 2))
	c.ellipse(11, 5, 2, 2, Pix.ramp(gem, 3))
	return _done(c)


# --- Sombreros (se dibujan sobre la cabeza, 14x10, mirando a la derecha) --------

static func hat(id: String) -> ImageTexture:
	var c := Pix.new(14, 12)
	var b := 11
	match id:
		"cinta":
			c.rect(2, b - 3, 10, 2, Color("#3a8a3a"))
			c.rect(0, b - 3, 2, 4, Color("#3a8a3a"))
		"casco_minero":
			c.rect(2, b - 5, 10, 4, Color("#f0c03a"))
			c.rect(1, b - 1, 12, 1, Color("#c0901e"))
			c.rect(9, b - 4, 3, 2, Color("#fff8c0"))
		"bufanda":
			c.rect(2, b - 1, 10, 2, Color("#c0302a"))
			c.rect(0, b, 3, 2, Color("#c0302a"))
		"arquero":
			c.rect(3, b - 4, 8, 3, Color("#2e7a3e"))
			c.rect(1, b - 1, 12, 1, Color("#1e4a2a"))
			c.line(4, b - 4, 1, b - 9, Color("#e0304a"))
		"mago":
			for k in 7:
				c.rect(7 - k / 2 - 1, b - 2 - k, k + 2 - k / 3, 1, Color("#3a2aa0"))
			c.rect(1, b - 1, 12, 1, Color("#2a1a6a"))
			c.px(7, b - 5, Color("#f0e03a"))
		"orejas":
			c.rect(4, b - 10, 2, 8, Color("#f0f0f4"))
			c.rect(8, b - 10, 2, 8, Color("#f0f0f4"))
			c.rect(4, b - 9, 1, 6, Color("#f0c0c8"))
		"ala":
			c.line(2, b - 2, 0, b - 8, Color("#46404e"), 2)
			c.line(11, b - 2, 13, b - 8, Color("#46404e"), 2)
		"tiranodonte":
			c.rect(1, b - 5, 12, 5, Color("#4a8a3a"))
			c.rect(9, b - 1, 4, 1, Color.WHITE)
			c.px(10, b - 4, Color("#ffd24a"))
		"gafas":
			c.rect(4, b - 1, 3, 2, Color("#f0c03a"))
			c.rect(8, b - 1, 3, 2, Color("#f0c03a"))
			c.rect(2, b, 10, 1, Color("#1a1320"))
		"tiki":
			c.rect(4, b - 1, 8, 7, Color("#b8844a"))
			c.rect(5, b + 1, 2, 2, Color.WHITE)
			c.rect(9, b + 1, 2, 2, Color.WHITE)
			c.rect(6, b + 4, 5, 1, Color("#c0302a"))
			c.rect(5, b - 5, 2, 4, Color("#3aa04a"))
		"barba":
			c.rect(7, b + 5, 6, 5, Color("#f4f4f8"))
			c.rect(8, b + 9, 3, 2, Color("#f4f4f8"))
		"corona":
			c.rect(3, b - 3, 8, 3, Color("#f0b93a"))
			for k in 3:
				c.px(3 + k * 3, b - 4, Color("#f0b93a"))
			c.px(7, b - 2, Color("#e0304a"))
		"seta":
			c.ellipse(7, b - 3, 7, 3.5, Color("#c0302a"))
			c.px(4, b - 5, Color.WHITE)
			c.px(9, b - 4, Color.WHITE)
		"huevo":
			c.ellipse(7, b - 4, 4, 5, Color("#e8e0d0"))
		"mascara_esqueleto":
			c.rect(5, b, 8, 7, Color("#f4efdc"))
			c.rect(9, b + 2, 2, 2, Color("#1a1320"))
			c.rect(7, b + 5, 5, 1, Color("#1a1320"))
		"dragon":
			c.rect(1, b - 5, 12, 5, Color("#c0302a"))
			c.px(3, b - 7, Color("#f4efdc"))
			c.px(10, b - 7, Color("#f4efdc"))
			c.px(10, b - 3, Color("#ffd24a"))
		"mascara_ceniza":
			c.rect(4, b - 1, 9, 8, Color("#4a2a4e"))
			c.px(9, b + 2, Color("#ff2a4a"))
			c.px(6, b + 2, Color("#ff2a4a"))
		"corona_escarcha":
			for k in 4:
				c.rect(3 + k * 2, b - 2 - (k % 2) * 2, 1, 3 + (k % 2) * 2, Color("#c0e8ff"))
			c.rect(3, b - 1, 8, 1, Color("#8ac4f0"))
		"vikingo":
			c.rect(2, b - 4, 10, 4, Color("#8a8a9a"))
			c.line(2, b - 3, 0, b - 7, Color("#f4efdc"), 2)
			c.line(11, b - 3, 13, b - 7, Color("#f4efdc"), 2)
		"yelmo_dragon":
			c.rect(1, b - 5, 12, 6, Color("#2a1a2e"))
			c.rect(7, b - 2, 5, 1, Color("#ff2a4a"))
			c.line(2, b - 5, 0, b - 9, Color("#6a4a7a"), 2)
		"capucha_rey":
			c.rect(1, b - 5, 12, 12, Color("#5a2a8a"))
			c.rect(5, b - 1, 8, 6, Color("#1a1320"))
			c.px(9, b + 1, Color("#ffb000"))
		"tricornio":
			c.rect(0, b - 3, 14, 3, Color("#1a1a2a"))
			c.rect(3, b - 6, 8, 3, Color("#1a1a2a"))
			c.px(7, b - 5, Color.WHITE)
		"autor":
			c.rect(2, b - 6, 10, 6, Color("#f0c090"))
			c.rect(2, b - 7, 10, 2, Color("#3a2414"))
			c.px(9, b - 4, Color("#1a1320"))
			c.rect(7, b - 2, 4, 1, Color("#c0302a"))
		"yelmo_real":
			c.rect(1, b - 5, 12, 7, Color("#f0b93a"))
			c.rect(7, b - 2, 6, 1, Color("#1a1320"))
			c.rect(5, b - 8, 3, 3, Color("#e0304a"))
		_:
			return null
	return _done(c)


static func companion(id: String, frame: int) -> ImageTexture:
	var c := Pix.new(12, 12)
	var up := frame % 2 == 0
	match id:
		"hada":
			c.ellipse(3, 4 if up else 6, 2.5, 2, Color(1, 1, 1, 0.7))
			c.ellipse(9, 4 if up else 6, 2.5, 2, Color(1, 1, 1, 0.7))
			c.ellipse(6, 6, 2.5, 3, Color("#ff9ae0"))
		"murcielago":
			c.line(6, 5, 1, 2 if up else 8, Color("#6a4a2a"), 2)
			c.line(6, 5, 11, 2 if up else 8, Color("#6a4a2a"), 2)
			c.ellipse(6, 6, 2.5, 2.5, Color("#8a6a4a"))
			c.px(7, 5, Color("#ffd24a"))
		"escarabajo":
			c.ellipse(6, 6, 4, 3, Color("#2aa04a"))
			c.line(6, 3, 6, 9, Color("#1a5a2a"))
			c.px(10, 5, Color("#1a1320"))
			c.ellipse(4, 3 if up else 4, 3, 1, Color(1, 1, 1, 0.6))
		"guardia":
			c.rect(3, 3, 6, 6, Color("#9aaab8"))
			c.px(6, 5, Color("#ff2a4a") if up else Color("#ffd24a"))
			c.line(0, 6, 3, 6, Color("#667685"))
			c.line(9, 6, 11, 6, Color("#667685"))
		"limo":
			c.ellipse(6, 7 if up else 6, 5, 4, Color("#6ac04a"))
			c.px(7, 6, Color("#1a1320"))
			c.px(9, 6, Color("#1a1320"))
		"ojo":
			c.ellipse(6, 6, 5, 4, Color("#f4f4f8"))
			c.ellipse(7, 6, 2.5, 2.5, Color("#3ad07a"))
			c.px(7, 6, Color("#1a1320"))
		"fantasma":
			c.ellipse(6, 5, 4.5, 4.5, Color(0.8, 0.9, 1.0, 0.8))
			c.rect(2, 5, 9, 5, Color(0.8, 0.9, 1.0, 0.8))
			c.px(5, 5, Color("#1a1320"))
			c.px(8, 5, Color("#1a1320"))
		"llama":
			c.ellipse(6, 7, 4, 4, Pix.ramp("fuego", 2))
			c.ellipse(6, 5 if up else 4, 2.5, 3, Pix.ramp("fuego", 3))
		"dron":
			c.rect(2, 5, 8, 4, Color("#56566b"))
			c.rect(0, 3 if up else 4, 12, 1, Color("#bdbdc9"))
			c.px(8, 6, Color("#3ae0ff"))
		_:
			return null
	return _done(c)
