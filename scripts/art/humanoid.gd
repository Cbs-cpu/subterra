class_name Humanoid
extends RefCounted
## Generador de personajes humanoides por "marioneta": piernas, brazos, torso y cabeza con
## animaciones completas (reposo 4, correr 6, salto, caída, ataque 3, daño, dash, abatido).
## Proporciones chibi: cabeza grande y cuerpo pequeño. Lienzo de 14x18 mirando a la derecha;
## los pies en y=17.

const W := 14
const H := 18
const ANIMS := {"idle": 4, "run": 6, "jump": 1, "fall": 1, "attack": 3, "hurt": 1, "dash": 1, "down": 1}

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

## Parámetros de pose por animación y fotograma.
static func pose(anim: String, i: int) -> Dictionary:
	var p := {"bob": 0, "fl": Vector2i(0, 0), "bl": Vector2i(0, 0), "fa": 0.3, "ba": -0.3, "lean": 0, "hy": 0}
	match anim:
		"idle":
			p["bob"] = 1 if i >= 2 else 0
			p["fa"] = 0.15
			p["ba"] = -0.15
		"run":
			var ph := i / 6.0 * TAU
			p["fl"] = Vector2i(roundi(sin(ph) * 2.0), roundi(maxf(0.0, cos(ph)) * 1.5))
			p["bl"] = Vector2i(roundi(-sin(ph) * 2.0), roundi(maxf(0.0, -cos(ph)) * 1.5))
			p["fa"] = -sin(ph) * 1.0
			p["ba"] = sin(ph) * 1.0
			p["bob"] = -1 if abs(sin(ph)) < 0.6 else 0
			p["lean"] = 0
		"jump":
			p["fl"] = Vector2i(1, 2)
			p["bl"] = Vector2i(-1, 1)
			p["fa"] = 2.5
			p["ba"] = 2.0
			p["bob"] = -1
		"fall":
			p["fl"] = Vector2i(1, 0)
			p["bl"] = Vector2i(-1, 1)
			p["fa"] = 1.4
			p["ba"] = -1.4
		"attack":
			p["fa"] = [2.8, 1.6, 0.5][clampi(i, 0, 2)]
			p["ba"] = -0.5
			p["fl"] = Vector2i(1, 0)
			p["bl"] = Vector2i(-1, 0)
			p["lean"] = [0, 1, 1][clampi(i, 0, 2)]
		"hurt":
			p["fa"] = 2.0
			p["ba"] = 2.2
			p["lean"] = -1
			p["hy"] = 1
		"dash":
			p["fl"] = Vector2i(-2, 1)
			p["bl"] = Vector2i(-3, 1)
			p["fa"] = -1.4
			p["ba"] = -1.2
			p["lean"] = 2
		"down":
			p["fl"] = Vector2i(0, 0)
			p["bl"] = Vector2i(0, 0)
	return p


static func _col(set: Dictionary, name: String, i: int, fallback: Dictionary) -> Color:
	var arr: Array = set.get(name, fallback.values()[0])
	return Color(arr[clampi(i, 0, arr.size() - 1)])


## look: {skin, hair, cloth, head, body}. body: "normal", "esqueleto", "tunica", "flotante".
static func build(look: Dictionary, anim: String, i: int) -> Dictionary:
	var c := Pix.new(W, H)
	var p := pose(anim, i)
	var skin_n: String = look.get("skin", "piel_clara")
	var cloth_n: String = look.get("cloth", "ropa_marron")
	var head: String = look.get("head", "normal")
	var body: String = look.get("body", "normal")
	var sk := [_col(SKINS, skin_n, 0, SKINS), _col(SKINS, skin_n, 1, SKINS), _col(SKINS, skin_n, 2, SKINS)]
	var cl := [_col(CLOTHS, cloth_n, 0, CLOTHS), _col(CLOTHS, cloth_n, 1, CLOTHS), _col(CLOTHS, cloth_n, 2, CLOTHS)]
	var hair := Color(HAIRS.get(look.get("hair", "pelo_castano"), "#5a3418"))
	var pants: Color = cl[0].darkened(0.25)
	var boots := Color("#2a1a14")
	if body == "esqueleto":
		pants = sk[1]
		boots = sk[0]
	var bob: int = p["bob"]
	var lean: int = p["lean"]
	var hip := Vector2i(7 + lean / 2, 12 + bob)
	var shoulder := Vector2i(7 + lean, 9 + bob)

	# Brazo trasero.
	_arm(c, shoulder + Vector2i(-1, 0), p["ba"], cl[0], sk[0])
	# Piernas.
	if body == "flotante":
		for k in 5:
			var wv := 3 - k / 2
			c.rect(6 - wv / 2 + roundi(sin(anim.hash() + i + k) * 0.8), hip.y + k, maxi(1, wv), 1, cl[1] if k % 2 == 0 else cl[2])
	elif body == "tunica":
		c.rect(4 + lean / 2, hip.y - 1, 6, 4, cl[1])
		c.rect(3 + lean / 2, hip.y + 3, 8, 2, cl[0])
		c.rect(5 + p["fl"].x / 2, 17, 2, 1, boots)
	else:
		_leg(c, hip + Vector2i(-1, 0), p["bl"], pants.darkened(0.2), boots)
		_leg(c, hip + Vector2i(1, 0), p["fl"], pants, boots)
	# Torso.
	var tx := 5 + lean
	var ty := 8 + bob
	c.rect(tx, ty, 5, 5, cl[1])
	c.rect(tx, ty, 5, 1, cl[2])
	c.rect(tx + 3, ty + 1, 2, 4, cl[0])
	c.rect(tx, ty + 4, 5, 1, cl[0].darkened(0.3))
	if body == "esqueleto":
		c.rect(tx, ty, 5, 5, Color(0, 0, 0, 0))
		for k in 3:
			c.rect(tx, ty + k * 2, 5, 1, sk[2])
		c.rect(tx + 2, ty, 1, 5, sk[1])
	# Cabeza.
	var hx := 3 + lean
	var hy := 1 + bob + int(p["hy"])
	_head(c, hx, hy, head, sk, hair, cl, look)
	# Brazo delantero (por encima).
	var hand := _arm(c, shoulder + Vector2i(1, 0), p["fa"], cl[2], sk[1])
	c.outline()
	return {"tex": c.tex(), "hand": hand, "head": Vector2i(hx + 4, hy)}


static func _leg(c: Pix, hip: Vector2i, off: Vector2i, col: Color, boot: Color) -> void:
	var foot := Vector2i(hip.x + off.x, 17 - off.y)
	c.line(hip.x, hip.y, foot.x, foot.y - 1, col, 1)
	c.px(hip.x + 1, hip.y, col)
	c.rect(foot.x, foot.y, 2, 1, boot)


## Dibuja un brazo con el ángulo dado (0 = hacia abajo, positivo = hacia delante). Devuelve la mano.
static func _arm(c: Pix, sh: Vector2i, ang: float, sleeve: Color, skin: Color) -> Vector2i:
	var hand := Vector2i(sh.x + roundi(sin(ang) * 3.0), sh.y + roundi(cos(ang) * 3.0))
	c.line(sh.x, sh.y, hand.x, hand.y, sleeve, 1)
	c.px(hand.x, hand.y, skin)
	return hand


static func _head(c: Pix, x: int, y: int, kind: String, sk: Array, hair: Color, cl: Array, look: Dictionary) -> void:
	var eye := Color(look.get("eye", "#1a1320"))
	match kind:
		"seta":
			# Sombrero de seta en lugar de cabeza.
			c.rect(x + 2, y + 4, 5, 4, Color("#f0e0c8"))
			c.px(x + 5, y + 5, eye)
			c.ellipse(x + 4.5, y + 3, 7, 3.5, Color("#c0302a"))
			c.rect(x - 1, y + 3, 11, 1, Color("#8a1a1a"))
			for d in [Vector2i(1, 1), Vector2i(5, 0), Vector2i(8, 2), Vector2i(3, 3)]:
				c.px(x + d.x, y + d.y, Color.WHITE)
			return
		"tiki":
			c.rect(x - 1, y - 1, 10, 10, Color("#8a5a30"))
			c.rect(x, y, 8, 8, Color("#b8844a"))
			c.rect(x + 1, y + 2, 2, 2, Color.WHITE)
			c.rect(x + 5, y + 2, 2, 2, Color.WHITE)
			c.px(x + 2, y + 3, eye)
			c.px(x + 6, y + 3, eye)
			c.rect(x + 2, y + 6, 5, 1, Color("#c0302a"))
			c.rect(x + 1, y - 3, 2, 3, Color("#3aa04a"))
			c.rect(x + 5, y - 3, 2, 3, Color("#e0c03a"))
			return
	# Cabeza base (grande, estilo chibi).
	c.rect(x, y, 8, 7, sk[1])
	c.rect(x + 1, y, 6, 1, sk[2])
	c.rect(x + 6, y + 1, 2, 5, sk[2])
	c.rect(x, y + 6, 8, 1, sk[0])
	c.px(x, y, Color(0, 0, 0, 0))
	# Ojo mirando a la derecha.
	if kind != "ciclope" and kind != "yelmo":
		c.rect(x + 5, y + 3, 1, 2, eye)
		c.px(x + 6, y + 3, Color(1, 1, 1, 0.9) if kind != "esqueleto" else eye)
	# Pelo (arriba y nuca).
	if kind in ["normal", "orejas", "cicatriz", "runas", "antifaz", "corona", "ciclope"]:
		c.rect(x, y - 1, 8, 2, hair)
		c.rect(x - 1, y, 2, 5, hair)
		c.px(x + 7, y, hair)
	match kind:
		"orejas":
			c.px(x - 2, y + 2, sk[1])
			c.px(x - 3, y + 1, sk[2])
			c.px(x - 1, y + 3, sk[1])
		"ciclope":
			c.rect(x + 3, y + 2, 4, 3, Color.WHITE)
			c.rect(x + 5, y + 3, 2, 1, eye)
		"pico":
			c.rect(x + 8, y + 4, 2, 2, Color("#f0a02a"))
			c.px(x + 9, y + 5, Color("#c06a1a"))
			c.rect(x, y - 2, 3, 2, hair)
		"hocico":
			c.rect(x + 7, y + 4, 3, 3, Color("#f0a0b0"))
			c.px(x + 9, y + 5, Color("#6a2a3a"))
			c.px(x + 1, y - 1, sk[1])
			c.px(x + 2, y - 2, sk[1])
		"rana":
			c.rect(x + 3, y - 2, 3, 3, sk[2])
			c.px(x + 4, y - 1, eye)
			c.rect(x + 3, y + 5, 5, 1, sk[0].darkened(0.3))
		"corona":
			c.rect(x + 1, y - 3, 6, 2, Color("#f0b93a"))
			c.px(x + 1, y - 4, Color("#f0b93a"))
			c.px(x + 4, y - 4, Color("#f0b93a"))
			c.px(x + 6, y - 4, Color("#f0b93a"))
			c.px(x + 4, y - 3, Color("#e0304a"))
		"cuernos":
			c.px(x + 1, y - 1, Color("#d6ccae"))
			c.px(x, y - 2, Color("#d6ccae"))
			c.px(x + 6, y - 1, Color("#d6ccae"))
			c.px(x + 7, y - 2, Color("#d6ccae"))
		"yelmo":
			c.rect(x - 1, y - 1, 10, 9, cl[1])
			c.rect(x - 1, y - 1, 10, 1, cl[2])
			c.rect(x + 4, y + 3, 5, 1, Color("#1a1320"))
			c.rect(x + 3, y - 3, 2, 2, Color("#c0302a"))
		"turbante":
			c.rect(x - 1, y - 2, 10, 4, cl[2])
			c.rect(x - 1, y, 10, 1, cl[1])
			c.px(x + 4, y - 1, Color("#e0304a"))
		"antifaz":
			c.rect(x + 1, y + 2, 7, 3, Color("#1a1a22"))
			c.px(x + 5, y + 3, Color.WHITE)
		"cresta":
			for k in 4:
				c.px(x + 1 + k * 2, y - 1 - (k % 2), sk[2])
		"runas":
			c.px(x + 2, y + 4, Color("#8ae0ff"))
			c.px(x + 3, y + 5, Color("#8ae0ff"))
			c.px(x + 1, y + 1, Color("#8ae0ff"))
		"cicatriz":
			c.px(x + 4, y + 2, Color("#c03a3a"))
			c.px(x + 5, y + 5, Color("#c03a3a"))
			c.px(x + 4, y + 4, Color("#c03a3a"))
		"esqueleto":
			c.rect(x + 4, y + 2, 3, 3, Color("#1a1320"))
			c.px(x + 5, y + 3, Color(look.get("glow", "#e0304a")))
			c.rect(x + 3, y + 6, 5, 1, Color("#1a1320"))
			c.px(x + 4, y + 6, sk[2])
			c.px(x + 6, y + 6, sk[2])
		"minotauro":
			c.rect(x + 7, y + 3, 3, 4, sk[0])
			c.px(x + 9, y + 4, Color("#1a1320"))
			c.px(x + 1, y - 1, Color("#e8e0c8"))
			c.px(x, y - 2, Color("#e8e0c8"))
			c.px(x + 6, y - 1, Color("#e8e0c8"))
			c.px(x + 7, y - 2, Color("#e8e0c8"))
		"morsa":
			c.rect(x + 6, y + 4, 3, 2, sk[2])
			c.px(x + 7, y + 6, Color.WHITE)
			c.px(x + 7, y + 7, Color.WHITE)
			c.rect(x - 1, y - 3, 10, 3, Color("#1a1a2a"))
			c.rect(x + 2, y - 5, 4, 2, Color("#1a1a2a"))
			c.px(x + 4, y - 2, Color.WHITE)
		"casco_espacial":
			c.rect(x - 1, y - 1, 10, 9, Color("#c8c8d8"))
			c.rect(x + 3, y + 1, 6, 5, Color("#3a8ad0"))
			c.px(x + 7, y + 2, Color.WHITE)
		"reina":
			c.rect(x, y - 1, 8, 2, hair)
			c.rect(x - 1, y, 2, 8, hair)
			for k in 4:
				c.px(x + 1 + k * 2, y - 3 + (k % 2), Color("#e0f4ff"))
			c.rect(x + 1, y - 2, 7, 1, Color("#8ac4f0"))
		"yeti":
			c.rect(x - 1, y - 1, 10, 3, sk[2])
			c.rect(x + 3, y + 5, 4, 2, Color("#6a8ab0"))
		"cristal":
			c.rect(x + 2, y - 3, 1, 3, Color("#bafff4"))
			c.rect(x + 5, y - 4, 1, 4, Color("#bafff4"))
			c.px(x + 5, y + 3, Color("#ffffff"))
		"zombi":
			c.rect(x, y - 1, 5, 1, hair)
			c.px(x + 5, y + 3, Color("#e0e04a"))
			c.rect(x + 4, y + 6, 3, 1, Color("#2a1a1a"))


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
