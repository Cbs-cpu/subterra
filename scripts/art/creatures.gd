class_name Creatures
extends RefCounted
## Criaturas no humanoides generadas por código, con animación. Miran a la derecha.
## build() devuelve una textura; anim: "move" (4 fotogramas), "attack" (2), "idle" (2).

const FRAMES := {"move": 4, "attack": 2, "idle": 2}


static func frame_count(anim: String) -> int:
	return FRAMES.get(anim, 2)


static func build(spr: String, pal: String, anim: String, i: int) -> ImageTexture:
	var t := float(i) / float(frame_count(anim))
	var c: Pix
	match spr:
		"limo": c = _limo(pal if pal != "" else "verde", anim, t)
		"arana": c = _arana(pal if pal != "" else "verde", anim, t)
		"cerdo": c = _cuadrupedo("#e8909a", "#b0606a", anim, t, "cerdo")
		"jabali": c = _cuadrupedo(Pix.ramp(pal, 2).to_html() if pal != "" else "#7a5a3a", Pix.ramp(pal, 1).to_html() if pal != "" else "#4a3422", anim, t, "jabali")
		"oveja": c = _cuadrupedo("#f0f0f4", "#b8b8c4", anim, t, "oveja")
		"conejo": c = _conejo(anim, t)
		"gallina": c = _gallina(pal, anim, t)
		"babosa": c = _babosa(pal if pal != "" else "morada", anim, t)
		"avispa": c = _insecto("#f0c03a", "#1a1320", anim, t, false)
		"mariposa": c = _insecto("#a05ae0", "#ff9ae0", anim, t, true)
		"murcielago": c = _murcielago(pal if pal != "" else "gris", anim, t)
		"hada": c = _hada(pal if pal != "" else "hielo", anim, t, false)
		"diablillo": c = _hada("fuego", anim, t, true)
		"cangrejo": c = _cangrejo(anim, t)
		"mimico": c = _mimico(anim, t)
		"seta_bicho": c = _seta(anim, t)
		"medusa": c = _medusa(anim, t)
		"dragon": c = _dragon(pal if pal != "" else "fuego", anim, t)
		"golem": c = _golem(anim, t)
		"calavera": c = _calavera(pal, anim, t)
		"gusano": c = _gusano(anim, t)
		"tiranodonte": c = _tiranodonte(anim, t)
		_:
			c = Pix.new(12, 12)
			c.ellipse(6, 6, 5, 5, Color.MAGENTA)
	c.outline()
	return c.tex()


static func _limo(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(16, 14)
	var squash := sin(t * TAU) * 1.5 if anim == "move" else sin(t * TAU) * 0.5
	var rx := 6.0 + squash
	var ry := 5.0 - squash
	var cy := 13.0 - ry
	c.ellipse(8, cy, rx, ry, Pix.ramp(pal, 2))
	c.ellipse(8, cy + 1, rx - 1, ry - 1.5, Pix.ramp(pal, 1))
	c.ellipse(6.5, cy - ry * 0.4, 1.8, 1.2, Pix.ramp(pal, 3))
	c.rect(9, int(cy) - 1, 1, 2, Pix.OUTLINE)
	c.rect(11, int(cy) - 1, 1, 2, Pix.OUTLINE)
	return c


static func _arana(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(18, 12)
	var body := Pix.ramp(pal, 1)
	var leg := Pix.ramp(pal, 0)
	for k in 4:
		var ph := t * TAU + k * 1.6
		var lift := roundi(sin(ph) * 1.5) if anim == "move" else 0
		var bx := 5 + k * 3
		c.line(bx, 7, bx - 2, 11 - max(0, lift), leg)
		c.line(bx + 1, 7, bx + 3, 11 - max(0, -lift), leg)
	c.ellipse(7, 6, 5, 3.5, body)
	c.ellipse(13, 7, 3, 2.5, Pix.ramp(pal, 2))
	c.ellipse(6, 5, 2, 1.2, Pix.ramp(pal, 2))
	c.px(14, 6, Color("#ff3a3a"))
	c.px(15, 7, Color("#ff3a3a"))
	return c


static func _cuadrupedo(main_hex: String, dark_hex: String, anim: String, t: float, kind: String) -> Pix:
	var c := Pix.new(20, 15)
	var main := Color(main_hex)
	var dark := Color(dark_hex)
	var ph := t * TAU
	var run := anim == "move"
	for k in 4:
		var lx: int = [5, 8, 12, 15][k]
		var sw := roundi(sin(ph + (PI if k % 2 == 0 else 0.0)) * 1.5) if run else 0
		c.rect(lx + sw, 10, 2, 4, dark if k % 2 == 0 else main.darkened(0.15))
	var bob := -1 if run and sin(ph * 2.0) > 0.0 else 0
	if kind == "oveja":
		for k in 6:
			c.ellipse(5 + k * 2, 7 + bob + (k % 2), 3, 3, main)
		c.rect(14, 5 + bob, 5, 5, Color("#3a3a44"))
		c.px(17, 6 + bob, Color.WHITE)
		return c
	c.ellipse(10, 8 + bob, 7, 4, main)
	c.ellipse(10, 10 + bob, 6, 2, main.darkened(0.12))
	c.rect(14, 4 + bob, 5, 5, main)
	c.px(17, 5 + bob, Pix.OUTLINE)
	if kind == "cerdo":
		c.rect(18, 6 + bob, 2, 2, Color("#f0a0b0"))
		c.px(15, 3 + bob, main.darkened(0.2))
		c.px(3, 7 + bob, dark)
	elif kind == "jabali":
		c.rect(18, 6 + bob, 2, 2, dark)
		c.px(18, 8 + bob, Color("#f4efdc"))
		c.px(19, 7 + bob, Color("#f4efdc"))
		for k in 5:
			c.px(6 + k * 2, 3 + bob, dark)
	return c


static func _conejo(anim: String, t: float) -> Pix:
	var c := Pix.new(12, 12)
	var hop := roundi(abs(sin(t * TAU)) * 2.0) if anim == "move" else 0
	c.ellipse(5, 8 - hop, 4, 3, Color("#f0f0f4"))
	c.ellipse(8, 5 - hop, 2.5, 2.5, Color("#f0f0f4"))
	c.rect(7, 0 - hop, 1, 4, Color("#e0e0e8"))
	c.rect(9, 0 - hop, 1, 4, Color("#f0c0c8"))
	c.px(9, 5 - hop, Pix.OUTLINE)
	c.px(1, 7 - hop, Color.WHITE)
	return c


static func _gallina(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(12, 12)
	var body := Color("#f4f4f8") if pal != "rey" else Pix.ramp("rey", 2)
	var peck := 1 if anim == "move" and sin(t * TAU) > 0.5 else 0
	c.ellipse(5, 7, 4, 3, body)
	c.ellipse(8, 4 + peck, 2, 2, body)
	c.rect(10, 4 + peck, 2, 1, Color("#f0a02a"))
	c.px(8, 1 + peck, Color("#e0303a"))
	c.px(9, 2 + peck, Color("#e0303a"))
	c.px(9, 4 + peck, Pix.OUTLINE)
	var sw := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	c.rect(4 + sw, 10, 1, 2, Color("#f0a02a"))
	c.rect(6 - sw, 10, 1, 2, Color("#f0a02a"))
	if pal == "rey":
		c.rect(6, 0 + peck, 4, 1, Color("#fff08a"))
		c.px(6, -1 + peck, Color("#fff08a"))
	return c


static func _babosa(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(18, 10)
	var stretch := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	c.ellipse(8, 7, 7 + stretch, 2.5, Pix.ramp(pal, 2))
	c.ellipse(7, 5, 4, 3, Pix.ramp(pal, 1))
	c.line(13 + stretch, 5, 15 + stretch, 1, Pix.ramp(pal, 2))
	c.px(15 + stretch, 1, Pix.OUTLINE)
	c.px(6, 4, Pix.ramp(pal, 3))
	return c


static func _insecto(body_hex: String, stripe_hex: String, anim: String, t: float, butterfly: bool) -> Pix:
	var c := Pix.new(14, 12)
	var up := sin(t * TAU * 2.0) > 0.0
	if butterfly:
		var col := Color(body_hex)
		var ry := 4.0 if up else 2.0
		c.ellipse(4, 5, 3.5, ry, col)
		c.ellipse(9, 5, 3.5, ry, col)
		c.px(4, 5, Color(stripe_hex))
		c.px(9, 5, Color(stripe_hex))
		c.rect(6, 3, 2, 7, Color("#1a1320"))
		return c
	c.ellipse(4, 3 if up else 5, 3, 2 if up else 1.2, Color(1, 1, 1, 0.8))
	c.ellipse(6, 7, 4, 3, Color(body_hex))
	c.rect(4, 5, 1, 5, Color(stripe_hex))
	c.rect(7, 5, 1, 5, Color(stripe_hex))
	c.ellipse(11, 6, 2, 2, Color(stripe_hex))
	c.px(1, 8, Color(stripe_hex))
	c.px(12, 5, Color("#ff3a3a"))
	return c


static func _murcielago(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(18, 10)
	var up := sin(t * TAU * 2.0) > 0.0
	var wing := Pix.ramp(pal, 1)
	if up:
		c.line(8, 5, 1, 1, wing, 2)
		c.line(9, 5, 16, 1, wing, 2)
	else:
		c.line(8, 5, 2, 8, wing, 2)
		c.line(9, 5, 15, 8, wing, 2)
	c.ellipse(8.5, 5, 3, 3, Pix.ramp(pal, 2))
	c.px(7, 2, Pix.ramp(pal, 2))
	c.px(10, 2, Pix.ramp(pal, 2))
	c.px(9, 5, Color("#ff3a3a"))
	c.px(10, 5, Color("#ff3a3a"))
	return c


static func _hada(pal: String, anim: String, t: float, imp: bool) -> Pix:
	var c := Pix.new(14, 14)
	var up := sin(t * TAU * 2.0) > 0.0
	var wing := Color(1, 1, 1, 0.7) if not imp else Pix.ramp("ceniza", 1)
	c.ellipse(4, 5 if up else 7, 3, 2, wing)
	c.ellipse(10, 5 if up else 7, 3, 2, wing)
	c.ellipse(7, 5, 2.5, 2.5, Pix.ramp(pal, 3) if not imp else Pix.ramp("fuego", 1))
	c.rect(6, 7, 3, 5, Pix.ramp(pal, 1))
	c.px(8, 5, Pix.OUTLINE)
	if imp:
		c.px(5, 2, Pix.ramp("hueso", 2))
		c.px(9, 2, Pix.ramp("hueso", 2))
		c.line(6, 11, 3, 13, Pix.ramp("fuego", 0))
	return c


static func _cangrejo(anim: String, t: float) -> Pix:
	var c := Pix.new(18, 12)
	var sw := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	for k in 3:
		c.line(5 + k * 3, 8, 3 + k * 3 + sw, 11, Pix.ramp("piedra", 1))
		c.line(7 + k * 3, 8, 9 + k * 3 - sw, 11, Pix.ramp("piedra", 1))
	c.ellipse(9, 7, 6, 3.5, Pix.ramp("piedra", 2))
	c.ellipse(8, 5, 4, 2, Pix.ramp("piedra", 3))
	var claw := 1 if anim == "attack" else 0
	c.ellipse(3, 4 - claw, 2, 2, Pix.ramp("piedra", 1))
	c.ellipse(15, 4 - claw, 2, 2, Pix.ramp("piedra", 1))
	c.px(7, 4, Pix.OUTLINE)
	c.px(11, 4, Pix.OUTLINE)
	return c


static func _mimico(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 14)
	var open := 3 if anim == "move" and sin(t * TAU) > 0.0 else (1 if anim == "move" else 0)
	c.rect(1, 7, 14, 7, Pix.ramp("madera", 1))
	c.rect(1, 7, 14, 1, Pix.ramp("madera", 2))
	c.rect(1, 2 - open, 14, 5, Pix.ramp("madera", 2))
	c.rect(1, 2 - open, 14, 1, Pix.ramp("madera", 3))
	c.rect(7, 6 - open, 2, 3, Pix.ramp("oro", 2))
	if open > 0:
		c.rect(2, 7 - open, 12, open, Color("#6a0e1e"))
		for k in 6:
			c.px(2 + k * 2, 7 - open, Color.WHITE)
		c.px(4, 4 - open, Color("#ff3a3a"))
		c.px(11, 4 - open, Color("#ff3a3a"))
	return c


static func _seta(anim: String, t: float) -> Pix:
	var c := Pix.new(14, 14)
	var hop := roundi(abs(sin(t * TAU)) * 2.0) if anim == "move" else 0
	c.rect(4, 7 - hop, 6, 5, Color("#f0e0c8"))
	c.ellipse(7, 5 - hop, 6, 4, Color("#c0302a"))
	c.px(4, 3 - hop, Color.WHITE)
	c.px(8, 2 - hop, Color.WHITE)
	c.px(10, 5 - hop, Color.WHITE)
	c.px(8, 9 - hop, Pix.OUTLINE)
	c.px(10, 9 - hop, Pix.OUTLINE)
	c.rect(4, 12, 2, 2, Color("#6a4226"))
	c.rect(8, 12, 2, 2, Color("#6a4226"))
	return c


static func _medusa(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 18)
	var pulse := sin(t * TAU)
	c.ellipse(8, 5, 6 + pulse * 0.8, 4.5 - pulse * 0.5, Color(0.95, 0.6, 0.95, 0.9))
	c.ellipse(8, 6, 4, 2, Color(1, 0.8, 1, 0.9))
	for k in 4:
		var x := 4 + k * 2.7
		for y in range(9, 17):
			c.px(int(x + sin(y * 0.8 + t * TAU + k) * 1.2), y, Color(0.9, 0.5, 0.9, 0.8))
	c.px(6, 5, Pix.OUTLINE)
	c.px(10, 5, Pix.OUTLINE)
	return c


static func _dragon(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(28, 18)
	var up := sin(t * TAU * 2.0) > 0.0
	var body := Pix.ramp(pal, 1)
	var belly := Pix.ramp(pal, 3)
	c.line(3, 10, 8, 9, body, 2)
	c.px(1, 11, body)
	c.ellipse(12, 10, 7, 4, body)
	c.ellipse(12, 12, 5, 2, belly)
	if up:
		c.line(10, 8, 6, 1, Pix.ramp(pal, 0), 2)
		c.line(10, 8, 14, 1, Pix.ramp(pal, 0), 2)
		c.line(6, 1, 14, 1, Pix.ramp(pal, 2))
	else:
		c.line(10, 8, 5, 14, Pix.ramp(pal, 0), 2)
		c.line(10, 8, 15, 15, Pix.ramp(pal, 0), 2)
	c.line(17, 8, 21, 5, body, 3)
	c.ellipse(23, 5, 3.5, 2.5, body)
	c.rect(25, 6, 3, 1, Pix.ramp(pal, 0))
	c.px(23, 4, Color("#fff27a"))
	c.px(21, 2, Pix.ramp(pal, 3))
	c.line(9, 14, 9, 17, Pix.ramp(pal, 0))
	c.line(14, 14, 14, 17, Pix.ramp(pal, 0))
	if anim == "attack":
		c.px(27, 5, Color("#ffd24a"))
	return c


static func _golem(anim: String, t: float) -> Pix:
	var c := Pix.new(24, 26)
	var sw := roundi(sin(t * TAU) * 1.5) if anim == "move" else 0
	var slam := 3 if anim == "attack" and t > 0.4 else 0
	var r := "cristal"
	c.rect(6 + sw, 19, 5, 7, Pix.ramp(r, 1))
	c.rect(13 - sw, 19, 5, 7, Pix.ramp(r, 1))
	c.rect(4, 8, 16, 12, Pix.ramp(r, 2))
	c.rect(4, 8, 16, 2, Pix.ramp(r, 3))
	c.rect(7, 2, 10, 7, Pix.ramp(r, 2))
	c.rect(12, 4, 3, 2, Color("#ffffff"))
	c.rect(0, 9 + slam, 4, 10, Pix.ramp(r, 1))
	c.rect(20, 9 + slam, 4, 10, Pix.ramp(r, 1))
	c.px(8, 12, Pix.ramp(r, 3))
	c.px(15, 15, Pix.ramp(r, 3))
	return c


static func _calavera(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(16, 16)
	var bone := Pix.ramp("hueso", 2) if pal != "guardian" else Pix.ramp("guardian", 1)
	var glow := Color("#e05a9a") if pal != "guardian" else Color("#ff2a4a")
	var bob := roundi(sin(t * TAU) * 1.0)
	c.ellipse(8, 7 + bob, 6, 5.5, bone)
	c.rect(4, 10 + bob, 8, 4, bone)
	c.rect(4, 6 + bob, 3, 3, Pix.OUTLINE)
	c.rect(9, 6 + bob, 3, 3, Pix.OUTLINE)
	c.px(5, 7 + bob, glow)
	c.px(10, 7 + bob, glow)
	for k in 3:
		c.px(5 + k * 2, 13 + bob, Pix.OUTLINE)
	if pal == "guardian":
		for k in 5:
			c.px(2 + k * 3, 1 + (k % 2) + bob, glow)
	return c


static func _gusano(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 22)
	var up := 0 if anim == "move" else roundi((1.0 - t) * 4.0)
	for k in 5:
		var y := 4 + k * 4 + up
		c.ellipse(8 + sin(k + t * TAU) * 1.5, y, 5 - k * 0.3, 3, Pix.ramp("ceniza", 2 if k % 2 == 0 else 1))
	c.rect(4, 2 + up, 8, 3, Pix.ramp("ceniza", 0))
	for k in 4:
		c.px(4 + k * 2, 5 + up, Color.WHITE)
	c.px(6, 3 + up, Color("#ff2a4a"))
	c.px(10, 3 + up, Color("#ff2a4a"))
	return c


static func _tiranodonte(anim: String, t: float) -> Pix:
	var c := Pix.new(36, 28)
	var ph := t * TAU
	var run := anim == "move"
	var sw := roundi(sin(ph) * 2.0) if run else 0
	var green := Color("#4a8a3a")
	var dark := Color("#2a5a24")
	var belly := Color("#c0d08a")
	c.line(2, 12, 10, 14, green, 3)
	c.ellipse(16, 15, 9, 7, green)
	c.ellipse(17, 18, 6, 3, belly)
	c.rect(11 + sw, 20, 4, 8, dark)
	c.rect(19 - sw, 20, 4, 8, green)
	c.rect(10 + sw, 26, 6, 2, dark)
	c.rect(18 - sw, 26, 6, 2, dark)
	var jaw := 3 if anim == "attack" else 1
	c.ellipse(27, 8, 7, 5, green)
	c.rect(26, 12, 9, 2 + jaw, dark)
	c.rect(27, 12, 8, 1, Color.WHITE)
	c.px(29, 6, Color("#ffd24a"))
	c.px(30, 6, Pix.OUTLINE)
	c.line(22, 16, 24, 19, dark, 2)
	for k in 5:
		c.px(8 + k * 4, 8 + (k % 2), Color("#e05a3a"))
	return c
