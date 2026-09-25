class_name Creatures
extends RefCounted
## Criaturas no humanoides generadas por código, con animación. Miran a la derecha.
## Estilo rechoncho: cuerpos redondos y anchos, patas cortas y ojos grandes de 2x2 con brillo.
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
		"cerdo": c = _cuadrupedo("#f4a8bc", "#d07890", anim, t, "cerdo")
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
	# Contorno negro como el del personaje (el lienzo crece 1 px por lado).
	c.ink(Pix.INK, true)
	return c.tex()


## Ojo grande de 2x2 con un píxel de brillo (arriba a la derecha).
static func _eye(c: Pix, x: int, y: int, col: Color = Pix.OUTLINE, shine: Color = Color.WHITE) -> void:
	c.rect(x, y, 2, 2, col)
	c.px(x + 1, y, shine)


static func _limo(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(16, 14)
	var squash := sin(t * TAU) * 1.5 if anim == "move" else sin(t * TAU) * 0.6
	var w := int(round(13.0 + squash))
	var hgt := int(round(9.0 - squash))
	var x0 := 8 - w / 2
	var y0 := 14 - hgt
	var body := Pix.ramp(pal, 2).lightened(0.15)
	# Gota ancha y baja: redonda arriba, plana abajo.
	c.ellipse(8, y0 + hgt * 0.62, w / 2.0, hgt * 0.62, body)
	c.rect(x0, y0 + hgt / 2, w, hgt - hgt / 2, body)
	c.ellipse(6, y0 + 2.5, 3, 1.4, Pix.ramp(pal, 3).lightened(0.25))
	c.rect(x0, 13, w, 1, Pix.ramp(pal, 1))
	_eye(c, x0 + w - 6, y0 + 4)
	_eye(c, x0 + w - 3, y0 + 4)
	return c


static func _arana(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(18, 12)
	var body := Pix.ramp(pal, 1)
	var leg := Pix.ramp(pal, 0)
	# Patitas cortas y gruesas.
	for k in 4:
		var ph := t * TAU + k * 1.6
		var lift := roundi(sin(ph) * 1.2) if anim == "move" else 0
		c.rect(3 + k * 3, 9 - maxi(0, lift), 2, 3, leg)
	c.ellipse(7, 6, 6.5, 4.8, body)
	c.ellipse(6, 4, 3, 1.6, Pix.ramp(pal, 2))
	c.ellipse(13.5, 7, 3.8, 3.4, Pix.ramp(pal, 2))
	_eye(c, 13, 6, Color("#ff3a3a"), Color("#ffb0a0"))
	_eye(c, 15, 6, Color("#ff3a3a"), Color("#ffb0a0"))
	return c


static func _cuadrupedo(main_hex: String, dark_hex: String, anim: String, t: float, kind: String) -> Pix:
	var c := Pix.new(20, 15)
	var main := Color(main_hex)
	var dark := Color(dark_hex)
	var ph := t * TAU
	var run := anim == "move"
	# Patas cortas y gordas.
	for k in 4:
		var lx: int = [4, 7, 11, 14][k]
		var sw := roundi(sin(ph + (PI if k % 2 == 0 else 0.0)) * 1.0) if run else 0
		c.rect(lx + sw, 11, 3, 3, dark if k % 2 == 0 else main.darkened(0.15))
	var bob := -1 if run and sin(ph * 2.0) > 0.0 else 0
	if kind == "oveja":
		for k in 7:
			c.ellipse(3.5 + k * 2, 7.5 + bob + (k % 2), 3.4, 3.6, main)
		c.ellipse(10, 5 + bob, 6, 2.5, main.lightened(0.3))
		c.rect(14, 4 + bob, 6, 6, Color("#3a3a44"))
		_eye(c, 16, 6 + bob, Color("#101018"))
		return c
	# Barriga redonda y ancha.
	c.ellipse(9.5, 8.5 + bob, 8.5, 5.2, main)
	c.ellipse(9.5, 11 + bob, 6.5, 2, main.darkened(0.12))
	c.ellipse(8, 5.5 + bob, 5, 1.5, main.lightened(0.18))
	# Cabeza grande.
	c.ellipse(16, 7 + bob, 3.8, 3.6, main)
	_eye(c, 16, 5 + bob)
	if kind == "cerdo":
		c.rect(18, 7 + bob, 2, 3, Color("#f0a0b0"))
		c.px(19, 8 + bob, Color("#c06078"))
		c.rect(14, 3 + bob, 2, 1, main.darkened(0.2))
		c.px(1, 7 + bob, dark)
	elif kind == "jabali":
		c.rect(18, 7 + bob, 2, 3, dark)
		c.px(18, 10 + bob, Color("#f4efdc"))
		c.px(19, 9 + bob, Color("#f4efdc"))
		for k in 5:
			c.px(5 + k * 2, 3 + bob, dark)
	return c


static func _conejo(anim: String, t: float) -> Pix:
	var c := Pix.new(12, 12)
	var hop := roundi(abs(sin(t * TAU)) * 2.0) if anim == "move" else 0
	var fur := Color("#f0f0f4")
	c.ellipse(5, 8.5 - hop, 4.8, 3.6, fur)
	c.ellipse(8.2, 5.5 - hop, 3, 2.8, fur)
	c.rect(6, 1 - hop, 2, 3, Color("#e0e0e8"))
	c.rect(9, 1 - hop, 2, 3, Color("#f0c0c8"))
	_eye(c, 9, 5 - hop)
	c.px(0, 7 - hop, Color.WHITE)
	return c


static func _gallina(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(12, 12)
	var body := Color("#f4f4f8") if pal != "rey" else Pix.ramp("rey", 2)
	var peck := 1 if anim == "move" and sin(t * TAU) > 0.5 else 0
	c.ellipse(5, 7, 4.8, 3.8, body)
	c.ellipse(8, 4 + peck, 2.6, 2.6, body)
	c.rect(10, 4 + peck, 2, 2, Color("#f0a02a"))
	c.rect(7, 1 + peck, 2, 1, Color("#e0303a"))
	c.px(8, 0 + peck, Color("#e0303a"))
	_eye(c, 8, 3 + peck)
	var sw := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	c.rect(3 + sw, 10, 2, 2, Color("#f0a02a"))
	c.rect(6 - sw, 10, 2, 2, Color("#f0a02a"))
	if pal == "rey":
		c.rect(5, 0 + peck, 5, 1, Color("#fff08a"))
	return c


static func _babosa(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(18, 10)
	var stretch := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	c.ellipse(8, 7, 7.5 + stretch, 3.2, Pix.ramp(pal, 2))
	c.ellipse(7, 4.5, 5, 3.6, Pix.ramp(pal, 1))
	c.ellipse(6, 3, 2.5, 1.2, Pix.ramp(pal, 3))
	c.rect(13 + stretch, 2, 2, 3, Pix.ramp(pal, 2))
	_eye(c, 14 + stretch, 1)
	return c


static func _insecto(body_hex: String, stripe_hex: String, anim: String, t: float, butterfly: bool) -> Pix:
	var c := Pix.new(14, 12)
	var up := sin(t * TAU * 2.0) > 0.0
	if butterfly:
		var col := Color(body_hex)
		var ry := 4.5 if up else 2.5
		c.ellipse(3.8, 5, 3.8, ry, col)
		c.ellipse(10.2, 5, 3.8, ry, col)
		c.rect(3, 4, 2, 2, Color(stripe_hex))
		c.rect(9, 4, 2, 2, Color(stripe_hex))
		c.rect(6, 3, 2, 7, Color("#1a1320"))
		return c
	c.ellipse(4, 3 if up else 5, 3.2, 2 if up else 1.2, Color(1, 1, 1, 0.8))
	# Abdomen gordo a rayas y cabeza redonda.
	c.ellipse(5.5, 7, 5, 3.8, Color(body_hex))
	c.rect(3, 4, 2, 7, Color(stripe_hex))
	c.rect(7, 4, 2, 7, Color(stripe_hex))
	c.ellipse(11, 6, 2.8, 2.8, Color(stripe_hex))
	c.px(0, 8, Color(stripe_hex))
	_eye(c, 11, 5, Color("#ff3a3a"), Color("#ffc0a0"))
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
	c.ellipse(8.5, 5.5, 4, 3.8, Pix.ramp(pal, 2))
	c.px(6, 1, Pix.ramp(pal, 2))
	c.px(11, 1, Pix.ramp(pal, 2))
	_eye(c, 7, 4, Color("#ff3a3a"), Color("#ffc0a0"))
	_eye(c, 9, 4, Color("#ff3a3a"), Color("#ffc0a0"))
	return c


static func _hada(pal: String, anim: String, t: float, imp: bool) -> Pix:
	var c := Pix.new(14, 14)
	var up := sin(t * TAU * 2.0) > 0.0
	var wing := Color(1, 1, 1, 0.7) if not imp else Pix.ramp("ceniza", 1)
	c.ellipse(3.5, 5 if up else 7, 3.2, 2.2, wing)
	c.ellipse(10.5, 5 if up else 7, 3.2, 2.2, wing)
	c.ellipse(7, 9.5, 3.2, 2.8, Pix.ramp(pal, 1))
	c.ellipse(7, 5, 3.4, 3.2, Pix.ramp(pal, 3) if not imp else Pix.ramp("fuego", 1))
	_eye(c, 8, 4)
	if imp:
		c.px(4, 1, Pix.ramp("hueso", 2))
		c.px(10, 1, Pix.ramp("hueso", 2))
		c.line(5, 11, 2, 13, Pix.ramp("fuego", 0))
	return c


static func _cangrejo(anim: String, t: float) -> Pix:
	var c := Pix.new(18, 12)
	var sw := roundi(sin(t * TAU) * 1.0) if anim == "move" else 0
	for k in 3:
		c.rect(4 + k * 3 + sw, 9, 2, 3, Pix.ramp("piedra", 1))
		c.rect(9 + k * 3 - sw, 9, 2, 3, Pix.ramp("piedra", 1))
	c.ellipse(9, 7, 7, 4.5, Pix.ramp("piedra", 2))
	c.ellipse(8, 4.5, 4.5, 1.8, Pix.ramp("piedra", 3))
	var claw := 1 if anim == "attack" else 0
	c.ellipse(2.5, 4 - claw, 2.5, 2.5, Pix.ramp("piedra", 1))
	c.ellipse(15.5, 4 - claw, 2.5, 2.5, Pix.ramp("piedra", 1))
	_eye(c, 6, 4)
	_eye(c, 10, 4)
	return c


static func _mimico(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 14)
	var open := 3 if anim == "move" and sin(t * TAU) > 0.0 else (1 if anim == "move" else 0)
	c.rect(0, 7, 16, 7, Pix.ramp("madera", 1))
	c.rect(0, 7, 16, 1, Pix.ramp("madera", 2))
	c.rect(0, 2 - open, 16, 5, Pix.ramp("madera", 2))
	c.rect(1, 1 - open, 14, 1, Pix.ramp("madera", 3))
	c.rect(7, 6 - open, 2, 3, Pix.ramp("oro", 2))
	if open > 0:
		c.rect(1, 7 - open, 14, open, Color("#6a0e1e"))
		for k in 7:
			c.px(1 + k * 2, 7 - open, Color.WHITE)
		_eye(c, 3, 3 - open, Color("#ff3a3a"), Color("#ffc0a0"))
		_eye(c, 11, 3 - open, Color("#ff3a3a"), Color("#ffc0a0"))
	return c


static func _seta(anim: String, t: float) -> Pix:
	var c := Pix.new(14, 14)
	var hop := roundi(abs(sin(t * TAU)) * 2.0) if anim == "move" else 0
	c.ellipse(7, 9.5 - hop, 4.5, 3, Color("#f0e0c8"))
	c.ellipse(7, 5 - hop, 7, 4.2, Color("#c0302a"))
	c.rect(0, 6 - hop, 14, 1, Color("#8a1a1a"))
	c.rect(3, 2 - hop, 2, 2, Color.WHITE)
	c.px(8, 1 - hop, Color.WHITE)
	c.rect(10, 4 - hop, 2, 1, Color.WHITE)
	_eye(c, 6, 8 - hop)
	_eye(c, 9, 8 - hop)
	c.rect(3, 12, 3, 2, Color("#6a4226"))
	c.rect(8, 12, 3, 2, Color("#6a4226"))
	return c


static func _medusa(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 18)
	var pulse := sin(t * TAU)
	c.ellipse(8, 5.5, 7 + pulse * 0.8, 5.2 - pulse * 0.5, Color(0.95, 0.6, 0.95, 0.9))
	c.ellipse(8, 7, 5, 2.2, Color(1, 0.8, 1, 0.9))
	for k in 4:
		var x := 3.5 + k * 2.8
		for y in range(10, 17):
			c.rect(int(x + sin(y * 0.8 + t * TAU + k) * 1.0), y, 2, 1, Color(0.9, 0.5, 0.9, 0.8))
	_eye(c, 5, 5)
	_eye(c, 9, 5)
	return c


static func _dragon(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(28, 18)
	var up := sin(t * TAU * 2.0) > 0.0
	var body := Pix.ramp(pal, 1)
	var belly := Pix.ramp(pal, 3)
	c.line(2, 10, 8, 9, body, 3)
	c.ellipse(12, 10, 8, 5.5, body)
	c.ellipse(12, 12.5, 6, 2.5, belly)
	if up:
		c.line(10, 7, 6, 1, Pix.ramp(pal, 0), 2)
		c.line(10, 7, 14, 1, Pix.ramp(pal, 0), 2)
		c.line(6, 1, 14, 1, Pix.ramp(pal, 2))
	else:
		c.line(10, 7, 5, 14, Pix.ramp(pal, 0), 2)
		c.line(10, 7, 15, 15, Pix.ramp(pal, 0), 2)
	c.line(18, 8, 21, 6, body, 4)
	c.ellipse(23, 5.5, 4.5, 3.8, body)
	c.rect(25, 7, 3, 2, Pix.ramp(pal, 0))
	_eye(c, 23, 3, Color("#1a1320"), Color("#fff27a"))
	c.px(20, 1, Pix.ramp(pal, 3))
	c.rect(8, 15, 3, 3, Pix.ramp(pal, 0))
	c.rect(14, 15, 3, 3, Pix.ramp(pal, 0))
	if anim == "attack":
		c.px(27, 6, Color("#ffd24a"))
	return c


static func _golem(anim: String, t: float) -> Pix:
	var c := Pix.new(24, 26)
	var sw := roundi(sin(t * TAU) * 1.5) if anim == "move" else 0
	var slam := 3 if anim == "attack" and t > 0.4 else 0
	var r := "cristal"
	c.rect(5 + sw, 21, 6, 5, Pix.ramp(r, 1))
	c.rect(13 - sw, 21, 6, 5, Pix.ramp(r, 1))
	c.ellipse(12, 14, 10, 8, Pix.ramp(r, 2))
	c.ellipse(11, 9, 7, 2.5, Pix.ramp(r, 3))
	c.ellipse(12, 5, 5.5, 4.5, Pix.ramp(r, 2))
	_eye(c, 13, 4, Color("#ffffff"), Color("#bafff4"))
	c.rect(0, 10 + slam, 4, 9, Pix.ramp(r, 1))
	c.rect(20, 10 + slam, 4, 9, Pix.ramp(r, 1))
	c.px(7, 14, Pix.ramp(r, 3))
	c.px(15, 17, Pix.ramp(r, 3))
	return c


static func _calavera(pal: String, anim: String, t: float) -> Pix:
	var c := Pix.new(16, 16)
	var bone := Pix.ramp("hueso", 2) if pal != "guardian" else Pix.ramp("guardian", 1)
	var glow := Color("#e05a9a") if pal != "guardian" else Color("#ff2a4a")
	var bob := roundi(sin(t * TAU) * 1.0)
	c.ellipse(8, 7 + bob, 7, 6, bone)
	c.rect(4, 10 + bob, 8, 4, bone)
	c.rect(3, 6 + bob, 4, 3, Pix.OUTLINE)
	c.rect(9, 6 + bob, 4, 3, Pix.OUTLINE)
	c.rect(4, 7 + bob, 2, 1, glow)
	c.rect(10, 7 + bob, 2, 1, glow)
	for k in 3:
		c.px(5 + k * 2, 13 + bob, Pix.OUTLINE)
	if pal == "guardian":
		for k in 5:
			c.px(2 + k * 3, 0 + (k % 2) + bob, glow)
	return c


static func _gusano(anim: String, t: float) -> Pix:
	var c := Pix.new(16, 22)
	var up := 0 if anim == "move" else roundi((1.0 - t) * 4.0)
	for k in 5:
		var y := 4 + k * 4 + up
		c.ellipse(8 + sin(k + t * TAU) * 1.0, y, 6.5 - k * 0.3, 3.4, Pix.ramp("ceniza", 2 if k % 2 == 0 else 1))
	c.rect(3, 2 + up, 10, 3, Pix.ramp("ceniza", 0))
	for k in 5:
		c.px(3 + k * 2, 5 + up, Color.WHITE)
	_eye(c, 4, 2 + up, Color("#ff2a4a"), Color("#ffc0a0"))
	_eye(c, 10, 2 + up, Color("#ff2a4a"), Color("#ffc0a0"))
	return c


static func _tiranodonte(anim: String, t: float) -> Pix:
	var c := Pix.new(36, 28)
	var ph := t * TAU
	var run := anim == "move"
	var sw := roundi(sin(ph) * 2.0) if run else 0
	var green := Color("#4a8a3a")
	var dark := Color("#2a5a24")
	var belly := Color("#c0d08a")
	c.line(1, 12, 10, 14, green, 4)
	c.ellipse(16, 15.5, 10.5, 8.5, green)
	c.ellipse(17, 19, 7, 3.5, belly)
	c.rect(10 + sw, 22, 5, 6, dark)
	c.rect(19 - sw, 22, 5, 6, green)
	c.rect(9 + sw, 26, 7, 2, dark)
	c.rect(18 - sw, 26, 7, 2, dark)
	var jaw := 3 if anim == "attack" else 1
	c.ellipse(27, 8, 8, 6, green)
	c.rect(25, 12, 10, 2 + jaw, dark)
	c.rect(26, 12, 9, 1, Color.WHITE)
	_eye(c, 29, 5, Color("#1a1320"), Color("#ffd24a"))
	c.line(23, 17, 25, 20, dark, 3)
	for k in 5:
		c.rect(8 + k * 4, 6 + (k % 2), 2, 1, Color("#e05a3a"))
	return c
