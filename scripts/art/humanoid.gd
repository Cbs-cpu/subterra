class_name Humanoid
extends RefCounted
## Humanoides por piezas (otras razas, vecinos, tenderos y enemigos con forma de persona),
## con la misma estética que el Minero: cabeza cuadrada de 6x6, torso de 6x4, manos de 2x2
## flotantes y botitas, todo con contorno negro. Las piezas se montan con las poses del
## esqueleto de scenes/pj_rig.tscn (RigPose), así que se mueven igual que el protagonista.
## Lienzo de 24x24 mirando a la derecha; los pies en ORIGIN.

const W := 24
const H := 24
const ORIGIN := Vector2i(12, 24)
## Fotogramas que se sacan de cada animación del esqueleto.
const ANIMS := {"idle": 6, "run": 8, "jump": 2, "fall": 2, "attack": 4, "hurt": 2, "dash": 2, "down": 1}
## Pivote de cada pieza dentro de su lienzo (offset = -pivote).
const OFFSET := {"cabeza": Vector2(-8, -12), "mano": Vector2(-3, -3), "pie": Vector2(-3, -5)}

const SKINS := {
	"piel_clara": ["#b0704a", "#e0a070", "#f8cc98"], "piel_morena": ["#6a3a1e", "#9a5a30", "#c8844a"],
	"piel_verde": ["#2e5a2a", "#4e8a3a", "#7ab45a"], "piel_gris": ["#5a5a6a", "#8a8a9a", "#b8b8c8"],
	"piel_azul": ["#2a4a8a", "#4a7ac0", "#8ab0e8"], "plumas": ["#8a5a1a", "#d09a3a", "#f0d07a"],
	"piel_roca": ["#4a4038", "#766a5a", "#a09484"], "piel_rosa": ["#b05a6a", "#e08a98", "#ffc0c8"],
	"piel_rana": ["#2a6a4a", "#4aa06a", "#8ad89a"], "piel_humo": ["#3a2a6a", "#6a4ab0", "#a88ae8"],
	"piel_lagarto": ["#3a5a1a", "#6a8a2a", "#a0c04a"], "piel_ceniza": ["#2a1a2e", "#4a2e4e", "#7a4a7a"],
	"piel_fantasma": ["#6a8ab0", "#a8c8e8", "#e8f4ff"], "hueso": ["#8a8068", "#cfc6a8", "#f4efdc"],
	"madera": ["#5a3a1e", "#8a5a30", "#b8844a"], "piel_zombi": ["#3a5a3a", "#5a8a5a", "#8ab08a"],
	"pelaje_blanco": ["#8a9ab0", "#c8d4e4", "#ffffff"], "pelaje_marron": ["#3a2414", "#6a4226", "#9a6a3e"],
	"cristal": ["#1a6a6a", "#3ab0a8", "#8ae8e0"], "cosmico": ["#2a1a4a", "#5a3a9a", "#9a7ae0"],
}
const CLOTHS := {
	"ropa_marron": ["#4a2e1a", "#7a4e2a", "#a8744a"], "ropa_morada": ["#3a1a5a", "#6a2aa0", "#9a5ad0"],
	"ropa_piel": ["#4a2a14", "#7a4a24", "#a87040"], "ropa_verde": ["#1e4a2a", "#2e7a3e", "#5ab05a"],
	"ropa_roja": ["#6a1a1a", "#a82a2a", "#e05050"], "ropa_azul": ["#1a2a6a", "#2a4ab0", "#5a80e0"],
	"ropa_amarilla": ["#7a5a0a", "#c0901e", "#f0c04a"], "ropa_negra": ["#141018", "#2a2432", "#48405a"],
	"ropa_armadura": ["#3c4652", "#667685", "#a8b8c8"], "ropa_hielo": ["#2a4e8a", "#6aa0e0", "#c0e4ff"],
	"ropa_tribal": ["#5a2a1a", "#8a4a2a", "#c07a4a"], "ropa_espacial": ["#3a3a4a", "#8a8aa0", "#e0e0f0"],
	"ropa_pirata": ["#1a1a3a", "#2a2a6a", "#c0302a"], "ropa_cristal": ["#1a6a6a", "#3ab0a8", "#bafff4"],
	"ropa_cosmica": ["#1a0a2a", "#3a1a5a", "#a05ae0"], "ropa_blanca": ["#8a8a9a", "#c8c8d4", "#f4f4ff"],
	"ropa_hueso": ["#6e6450", "#a89a78", "#d6ccae"], "ropa_fantasma": ["#4a6a9a", "#8ab0e0", "#dcecff"],
}
const HAIRS := {
	"pelo_castano": "#5a3418", "pelo_rubio": "#e0b84a", "pelo_negro": "#1e1a22", "pelo_blanco": "#e8e8f0",
	"pelo_gris": "#8a8a94", "pelo_rosa": "#e07a8a", "pelo_musgo": "#4a7a2a", "plumas": "#c07a2a",
}

static func _col(set: Dictionary, name: String, i: int, fallback: Dictionary) -> Color:
	var arr: Array = set.get(name, fallback.values()[0])
	return Color(arr[clampi(i, 0, arr.size() - 1)])


## Fotograma completo: se montan las piezas del aspecto con la pose de la animación del
## esqueleto en ese instante. Devuelve {tex, hand, head, origin}.
static func build(look: Dictionary, anim: String, i: int) -> Dictionary:
	var n: int = ANIMS.get(anim, 1)
	var alen = RigPose.length(anim)
	var time = alen * float(i) / float(n)
	if n == 1:
		time = alen * 0.5
	var pose = RigPose.pose(anim, time)
	var parts := parts_for(look)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var o := Vector2(ORIGIN)
	var body: String = look.get("body", "normal")
	for pn in RigPose.PARTS:
		if pn.begins_with("Pie") and body in ["tunica", "flotante"]:
			continue
		var kind: String = {"PieB": "pie", "PieF": "pie", "ManoB": "mano", "ManoF": "mano", "Torso": "torso", "Cabeza": "cabeza"}[pn]
		var part: Image = parts[kind]
		var tr: Transform2D = pose[pn]
		tr.origin = (tr.origin + o).round()
		var off: Vector2 = Vector2(parts["torso_off"]) if kind == "torso" else OFFSET[kind]
		_blit(img, part, tr * Transform2D(0.0, off))
	var hand: Transform2D = pose["ManoF"]
	var head: Transform2D = pose["Cabeza"]
	return {"tex": ImageTexture.create_from_image(img), "hand": Vector2i((hand.origin + o).round()),
		"head": Vector2i((head * Vector2(0, -7) + o).round()), "origin": ORIGIN}


## Copia `src` en `dst` con la transformación dada (vecino más cercano, sin mezclar bordes).
static func _blit(dst: Image, src: Image, tr: Transform2D) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	if is_zero_approx(tr.get_rotation()) and tr.get_scale().is_equal_approx(Vector2.ONE):
		dst.blend_rect(src, Rect2i(0, 0, sw, sh), Vector2i(tr.origin.round()))
		return
	var inv := tr.affine_inverse()
	var corners := [tr * Vector2(0, 0), tr * Vector2(sw, 0), tr * Vector2(0, sh), tr * Vector2(sw, sh)]
	var mn: Vector2 = corners[0]
	var mx: Vector2 = corners[0]
	for c in corners:
		mn = mn.min(c)
		mx = mx.max(c)
	for y in range(maxi(0, int(floor(mn.y))), mini(dst.get_height(), int(ceil(mx.y)) + 1)):
		for x in range(maxi(0, int(floor(mn.x))), mini(dst.get_width(), int(ceil(mx.x)) + 1)):
			var sp := inv * Vector2(x + 0.5, y + 0.5)
			var sx := int(floor(sp.x))
			var sy := int(floor(sp.y))
			if sx >= 0 and sy >= 0 and sx < sw and sy < sh:
				var c2 := src.get_pixel(sx, sy)
				if c2.a > 0.0:
					dst.set_pixel(x, y, c2)


static var _parts := {}


## Piezas (Image) de un aspecto: cabeza, torso, mano y pie, con contorno negro.
static func parts_for(look: Dictionary) -> Dictionary:
	var key := str(look)
	if _parts.has(key):
		return _parts[key]
	var skin_n: String = look.get("skin", "piel_clara")
	var cloth_n: String = look.get("cloth", "ropa_marron")
	var sk := [_col(SKINS, skin_n, 0, SKINS), _col(SKINS, skin_n, 1, SKINS), _col(SKINS, skin_n, 2, SKINS)]
	var cl := [_col(CLOTHS, cloth_n, 0, CLOTHS), _col(CLOTHS, cloth_n, 1, CLOTHS), _col(CLOTHS, cloth_n, 2, CLOTHS)]
	var hair := Color(HAIRS.get(look.get("hair", "pelo_castano"), "#5a3418"))
	var body: String = look.get("body", "normal")
	var out := {}
	out["cabeza"] = _head_img(look.get("head", "normal"), sk, hair, cl, look)
	var t := _torso_img(body, sk, cl)
	out["torso"] = t[0]
	out["torso_off"] = t[1]
	# Mano: cuadradito de piel de 2x2 (hueso en los esqueletos).
	var m := Pix.new(6, 6)
	m.rect(2, 2, 2, 2, sk[2])
	m.px(2, 3, sk[1])
	m.ink()
	out["mano"] = m.img
	# Pie: botita con la punta hacia delante.
	var boot = Color("#3a2618") if body != "esqueleto" else sk[1]
	var boot_hi = boot.lightened(0.25)
	var f := Pix.new(7, 6)
	f.rect(2, 2, 2, 2, boot)
	f.px(3, 2, boot_hi)
	f.px(4, 3, boot_hi)
	f.ink()
	out["pie"] = f.img
	_parts[key] = out
	return out


## Torso de 6x4 por dentro (camisa, cinturón y pantalón) o sus variantes. Devuelve
## [imagen, offset del pivote de la cadera].
static func _torso_img(body: String, sk: Array, cl: Array) -> Array:
	match body:
		"tunica":
			# Túnica que baja hasta el suelo y tapa los pies.
			var c := Pix.new(12, 10)
			c.rect(3, 2, 6, 6, cl[1])
			c.rect(2, 6, 8, 2, cl[1])
			c.rect(3, 2, 1, 6, cl[0])
			c.rect(7, 2, 2, 4, cl[2])
			c.rect(2, 7, 8, 1, cl[0])
			c.rect(5, 3, 2, 1, Color("#f0c040"))
			c.ink()
			return [c.img, Vector2i(-6, -7)]
		"flotante":
			# Sin piernas: una estela que se estrecha.
			var c2 := Pix.new(12, 12)
			c2.rect(3, 2, 6, 3, cl[1])
			c2.rect(7, 2, 2, 2, cl[2])
			c2.rect(3, 2, 1, 3, cl[0])
			c2.rect(4, 5, 4, 2, cl[1])
			c2.rect(5, 7, 2, 1, cl[2])
			c2.px(6, 8, cl[2])
			c2.ink()
			return [c2.img, Vector2i(-6, -7)]
		"esqueleto":
			var c3 := Pix.new(12, 10)
			c3.rect(3, 2, 6, 1, sk[2])
			c3.rect(3, 4, 6, 1, sk[2])
			c3.rect(5, 2, 2, 4, sk[1])
			c3.rect(4, 5, 4, 1, sk[1])
			c3.ink()
			return [c3.img, Vector2i(-6, -7)]
	var c4 := Pix.new(12, 10)
	c4.rect(3, 2, 6, 2, cl[1])
	c4.rect(3, 2, 1, 2, cl[0])
	c4.rect(7, 2, 2, 2, cl[2])
	c4.rect(3, 4, 6, 1, Color("#3a281c"))
	c4.rect(5, 4, 2, 1, Color("#aab0b8"))
	c4.rect(3, 5, 6, 1, cl[0].darkened(0.35))
	c4.ink()
	return [c4.img, Vector2i(-6, -7)]


## Cabeza cuadrada de 6x6 por dentro (como la del Minero) con sus variantes.
## Lienzo de 16x14: el bloque va de (5,6) a (10,11) y el cuello queda en (8,12).
static func _head_img(kind: String, sk: Array, hair: Color, cl: Array, look: Dictionary) -> Image:
	var c := Pix.new(16, 14)
	var x := 5
	var y := 6
	var eye := Color(look.get("eye", "#0e0a0a"))
	var face: Color = sk[2]
	var shade: Color = sk[1]
	var gold := Color("#f0b93a")
	match kind:
		"seta":
			c.rect(x + 1, y + 2, 4, 4, Color("#f0e0c8"))
			c.px(x + 2, y + 3, eye)
			c.px(x + 4, y + 3, eye)
			c.ellipse(x + 3, y + 1, 5.5, 3.5, Color("#c0302a"))
			c.rect(x - 2, y + 1, 10, 1, Color("#8a1a1a"))
			c.rect(x, y - 2, 2, 1, Color.WHITE)
			c.px(x + 4, y - 1, Color.WHITE)
			c.px(x + 6, y, Color.WHITE)
			c.ink()
			return c.img
		"tiki":
			c.rect(x, y, 6, 6, Color("#b8844a"))
			c.rect(x, y, 1, 6, Color("#8a5a30"))
			c.rect(x + 1, y + 2, 2, 1, Color.WHITE)
			c.rect(x + 4, y + 2, 2, 1, Color.WHITE)
			c.px(x + 2, y + 2, eye)
			c.px(x + 5, y + 2, eye)
			c.rect(x + 1, y + 4, 4, 1, Color("#c0302a"))
			c.rect(x, y - 3, 2, 3, Color("#3aa04a"))
			c.rect(x + 4, y - 3, 2, 3, Color("#e0c03a"))
			c.ink()
			return c.img
		"casco_espacial":
			c.rect(x - 1, y - 1, 8, 8, Color("#c8c8d8"))
			c.rect(x - 1, y - 1, 1, 8, Color("#8a8a9a"))
			c.rect(x + 2, y + 1, 4, 4, Color("#3a8ad0"))
			c.px(x + 4, y + 1, Color.WHITE)
			c.ink()
			return c.img
		"yelmo":
			c.rect(x, y, 6, 6, cl[1])
			c.rect(x, y, 1, 6, cl[0])
			c.rect(x + 4, y, 2, 2, cl[2])
			c.rect(x + 1, y + 3, 5, 1, Color("#0e0a0a"))
			c.rect(x + 2, y - 2, 2, 2, Color("#c0302a"))
			c.ink()
			return c.img
	# Cara base.
	c.rect(x, y, 6, 6, face)
	c.rect(x, y, 2, 6, shade)
	var hairy := kind in ["normal", "orejas", "cicatriz", "runas", "antifaz", "corona", "ciclope", "pico", "reina", "zombi"]
	if hairy:
		c.rect(x, y, 6, 2, hair)
		c.rect(x, y + 2, 1, 1, hair)
		c.rect(x + 4, y, 2, 1, hair.lightened(0.2))
		if kind == "normal":
			c.rect(x + 3, y - 1, 2, 1, hair)            # mechón
	# Ojos (1 px) y boca.
	if kind not in ["ciclope", "esqueleto", "antifaz"]:
		c.px(x + 1, y + 3, eye)
		c.px(x + 4, y + 3, eye)
	if kind not in ["esqueleto", "hocico", "minotauro", "morsa", "yeti"]:
		c.px(x + 3, y + 5, shade.darkened(0.25))
	match kind:
		"orejas":
			c.rect(x - 2, y + 2, 2, 2, face)
			c.rect(x + 6, y + 2, 1, 2, face)
		"ciclope":
			c.rect(x + 2, y + 2, 2, 2, Color.WHITE)
			c.px(x + 3, y + 3, eye)
		"pico":
			c.rect(x + 6, y + 3, 2, 2, Color("#f0a02a"))
			c.px(x + 7, y + 4, Color("#c06a1a"))
		"hocico":
			c.rect(x + 4, y + 3, 3, 3, Color("#f0a0b0"))
			c.px(x + 6, y + 4, Color("#6a2a3a"))
			c.rect(x, y - 2, 2, 2, shade)
			c.rect(x + 4, y - 2, 2, 2, shade)
		"rana":
			c.rect(x, y - 2, 2, 2, face)
			c.rect(x + 4, y - 2, 2, 2, face)
			c.px(x + 1, y - 2, eye)
			c.px(x + 5, y - 2, eye)
			c.rect(x + 1, y + 4, 5, 1, shade.darkened(0.3))
		"corona":
			c.rect(x, y - 2, 6, 2, gold)
			c.px(x, y - 3, gold)
			c.px(x + 3, y - 3, gold)
			c.px(x + 5, y - 3, gold)
			c.px(x + 3, y - 2, Color("#e0304a"))
		"cuernos":
			c.rect(x - 1, y - 2, 2, 2, Color("#d6ccae"))
			c.rect(x + 5, y - 2, 2, 2, Color("#d6ccae"))
		"turbante":
			c.rect(x - 1, y - 2, 8, 4, cl[2])
			c.rect(x - 1, y, 8, 1, cl[1])
			c.px(x + 3, y - 1, Color("#e0304a"))
		"antifaz":
			c.rect(x, y + 3, 6, 1, Color("#1a1a22"))
			c.px(x + 1, y + 3, Color.WHITE)
			c.px(x + 4, y + 3, Color.WHITE)
		"cresta":
			for k in 3:
				c.rect(x + k * 2, y - 2 + (k % 2), 1, 2 - (k % 2), face)
		"runas":
			c.px(x + 2, y + 4, Color("#8ae0ff"))
			c.px(x + 5, y + 5, Color("#8ae0ff"))
		"cicatriz":
			c.px(x + 3, y + 2, Color("#c03a3a"))
			c.px(x + 4, y + 4, Color("#c03a3a"))
			c.px(x + 3, y + 3, Color("#c03a3a"))
		"esqueleto":
			c.rect(x + 1, y + 2, 2, 2, Color("#0e0a0a"))
			c.rect(x + 4, y + 2, 2, 2, Color("#0e0a0a"))
			c.px(x + 2, y + 3, Color(look.get("glow", "#e0304a")))
			c.px(x + 5, y + 3, Color(look.get("glow", "#e0304a")))
			c.rect(x + 1, y + 5, 4, 1, Color("#0e0a0a"))
			c.px(x + 2, y + 5, face)
			c.px(x + 4, y + 5, face)
		"minotauro":
			c.rect(x + 3, y + 3, 4, 3, shade)
			c.px(x + 6, y + 4, Color("#0e0a0a"))
			c.rect(x - 1, y - 2, 2, 2, Color("#e8e0c8"))
			c.rect(x + 5, y - 2, 2, 2, Color("#e8e0c8"))
		"morsa":
			c.rect(x + 3, y + 4, 3, 1, sk[2].lightened(0.2))
			c.px(x + 4, y + 5, Color.WHITE)
			c.px(x + 4, y + 6, Color.WHITE)
			c.rect(x - 1, y - 2, 8, 3, Color("#1a1a2a"))
			c.rect(x + 1, y - 4, 4, 2, Color("#1a1a2a"))
			c.px(x + 3, y - 2, Color.WHITE)
		"reina":
			c.rect(x - 1, y, 1, 6, hair)
			c.rect(x, y + 2, 1, 4, hair)
			for k in 3:
				c.px(x + k * 2 + 1, y - 2 + (k % 2), Color("#e0f4ff"))
			c.rect(x, y - 1, 6, 1, Color("#8ac4f0"))
		"yeti":
			c.rect(x, y, 6, 2, sk[2])
			c.rect(x, y + 4, 6, 2, sk[2])
			c.rect(x + 2, y + 2, 4, 2, Color("#6a8ab0"))
			c.px(x + 2, y + 2, eye)
			c.px(x + 5, y + 2, eye)
		"cristal":
			c.rect(x + 1, y - 2, 1, 2, Color("#bafff4"))
			c.rect(x + 4, y - 3, 1, 3, Color("#bafff4"))
		"zombi":
			c.rect(x + 3, y, 3, 1, face)
			c.px(x + 4, y + 3, Color("#e0e04a"))
			c.rect(x + 2, y + 5, 3, 1, Color("#2a1a1a"))
	c.ink()
	return c.img


## Aspecto de enemigos y vecinos humanoides.
const ENEMY_LOOKS := {
	"tiki_chaman": {"skin": "madera", "cloth": "ropa_tribal", "head": "tiki", "body": "tunica"},
	"tiki_porrero": {"skin": "madera", "cloth": "ropa_tribal", "head": "tiki"},
	"seta_soldado": {"skin": "piel_clara", "cloth": "ropa_roja", "head": "seta"},
	"seta_maga": {"skin": "piel_clara", "cloth": "ropa_morada", "head": "seta", "body": "tunica"},
	"esqueleto": {"skin": "hueso", "cloth": "ropa_hueso", "head": "esqueleto", "body": "esqueleto"},
	"esqueleto_arquero": {"skin": "hueso", "cloth": "ropa_hueso", "head": "esqueleto", "body": "esqueleto", "glow": "#4ae04a"},
	"esqueleto_cosmico": {"skin": "cosmico", "cloth": "ropa_cosmica", "head": "esqueleto", "body": "esqueleto", "glow": "#e0a0ff"},
	"rey_esqueleto": {"skin": "hueso", "cloth": "ropa_morada", "head": "esqueleto", "body": "tunica", "glow": "#ffb000"},
	"minotauro": {"skin": "pelaje_marron", "cloth": "ropa_piel", "head": "minotauro"},
	"genio": {"skin": "piel_azul", "cloth": "ropa_morada", "head": "turbante", "body": "flotante"},
	"caballero_hielo": {"skin": "piel_azul", "cloth": "ropa_hielo", "head": "yelmo"},
	"necrofago": {"skin": "piel_zombi", "cloth": "ropa_negra", "head": "zombi", "hair": "pelo_negro"},
	"zombi": {"skin": "piel_zombi", "cloth": "ropa_marron", "head": "zombi", "hair": "pelo_negro"},
	"corsario": {"skin": "pelaje_marron", "cloth": "ropa_pirata", "head": "morsa"},
	"yeti": {"skin": "pelaje_blanco", "cloth": "ropa_blanca", "head": "yeti"},
	"reina_escarcha": {"skin": "piel_azul", "cloth": "ropa_hielo", "head": "reina", "hair": "pelo_blanco", "body": "tunica"},
	"paladin": {"skin": "cristal", "cloth": "ropa_cristal", "head": "cristal"},
	"capitan": {"skin": "piel_clara", "cloth": "ropa_espacial", "head": "casco_espacial"},
	"ventolin": {"skin": "piel_fantasma", "cloth": "ropa_fantasma", "head": "yelmo", "body": "flotante"},
	"vecino": {"skin": "piel_clara", "cloth": "ropa_verde", "head": "normal", "hair": "pelo_gris"},
	"tendero": {"skin": "piel_morena", "cloth": "ropa_amarilla", "head": "normal", "hair": "pelo_negro"},
	"herrero": {"skin": "piel_clara", "cloth": "ropa_negra", "head": "cicatriz", "hair": "pelo_rubio"},
	"sastra": {"skin": "piel_clara", "cloth": "ropa_morada", "head": "normal", "hair": "pelo_rosa", "body": "tunica"},
	"peletero": {"skin": "piel_verde", "cloth": "ropa_piel", "head": "orejas", "hair": "pelo_musgo"},
	"comprador": {"skin": "piel_gris", "cloth": "ropa_roja", "head": "antifaz", "hair": "pelo_negro"},
}
