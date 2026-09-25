extends Node
## Punto de acceso único al arte generado (con caché).

var _cache := {}
var _light_tex: Texture2D


## Textura radial para las luces 2D.
func light_tex() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.55))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 128
		gt.height = 128
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		_light_tex = gt
	return _light_tex


## Crea una luz puntual de radio aproximado en píxeles.
func make_light(col: Color, radius: float, energy: float = 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_tex()
	l.texture_scale = radius / 64.0
	l.color = col
	l.energy = energy
	return l


func _c(key: String, fn: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = fn.call()
	return _cache[key]


## Aspecto de una raza (con el sombrero se dibuja aparte).
func race_look(race_id: String) -> Dictionary:
	return Content.race(race_id)["look"]


## Fotograma de humanoide: {tex, hand, head}. look_key identifica el aspecto para la caché.
func humanoid(look_key: String, look: Dictionary, anim: String, i: int) -> Dictionary:
	var n: int = Humanoid.ANIMS.get(anim, 1)
	var fi := i % n
	return _c("hum|%s|%s|%d" % [look_key, anim, fi], func(): return Humanoid.build(look, anim, fi))


## Número de fotogramas de una animación del héroe (sprites de Humanoid).
func hero_count(_race_id: String, anim: String) -> int:
	return Humanoid.ANIMS.get(anim, 1)


## Fotograma del héroe: {tex, hand, head, origin}. El Minero se anima por piezas en el
## juego (scenes/pj_rig.tscn); aquí se da su pose de reposo montada en una sola imagen para
## los retratos de los menús.
func hero_frame(race_id: String, anim: String, i: int) -> Dictionary:
	if race_id == "minero":
		return _c("pj_partes", _pj_portrait)
	var d: Dictionary = humanoid("race_" + race_id, race_look(race_id), anim, i)
	if not d.has("origin"):
		d["origin"] = Vector2i(7, 18)
	return d


## Monta las piezas del Minero en reposo (mismas posiciones que REST en tools/build_pj_rig.gd).
func _pj_portrait() -> Dictionary:
	var dir := "res://assets/sprites/pj_partes/"
	var origin := Vector2i(8, 16)
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	# [pieza, esquina superior izquierda relativa a los pies], de atrás hacia delante.
	for p in [["pie", Vector2i(-4, -4)], ["pie", Vector2i(0, -4)], ["mano", Vector2i(-8, -6)],
			["torso", Vector2i(-4, -8)], ["cabeza", Vector2i(-6, -16)], ["mano", Vector2i(4, -6)]]:
		var tex: Texture2D = load(dir + p[0] + ".png")
		var part := tex.get_image()
		part.convert(Image.FORMAT_RGBA8)
		img.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), origin + p[1])
	return {"tex": ImageTexture.create_from_image(img), "hand": origin + Vector2i(6, -4), "head": origin + Vector2i(0, -16), "origin": origin}


func npc_frame(kind: String, anim: String, i: int) -> Dictionary:
	return humanoid("npc_" + kind, Humanoid.ENEMY_LOOKS.get(kind, Humanoid.ENEMY_LOOKS["vecino"]), anim, i)


## Sprite de enemigo. spr "humano:x" usa el generador de humanoides.
func enemy_frame(spr: String, pal: String, anim: String, i: int) -> Dictionary:
	if spr.begins_with("humano:"):
		var k := spr.substr(7)
		var hanim := {"move": "run", "attack": "attack", "idle": "idle", "hurt": "hurt"}.get(anim, "idle")
		return npc_frame(k, hanim, i)
	var n := Creatures.frame_count(anim)
	var fi := i % n
	return _c("cr|%s|%s|%s|%d" % [spr, pal, anim, fi], func(): return {"tex": Creatures.build(spr, pal, anim, fi)})


func icon(item_id: String) -> ImageTexture:
	var it := ItemDB.get_item(item_id)
	return _c("icon|" + item_id, func(): return Icons.build(it.get("icon", "piedra"), it.get("pal", "neutro")))


func coin_icon() -> ImageTexture:
	return _c("icon|moneda", func(): return Icons.build("moneda", "oro"))


func tree(biome: String, variant: int) -> ImageTexture:
	return _c("tree|%s|%d" % [biome, variant % 3], func(): return PropsArt.tree(biome, variant % 3))


func rock(ore: String, biome: String) -> ImageTexture:
	return _c("rock|%s|%s" % [ore, biome], func(): return PropsArt.rock(ore, biome))


func grass(biome: String, frame: int) -> ImageTexture:
	return _c("grass|%s|%d" % [biome, frame % 2], func(): return PropsArt.grass(biome, frame % 2))


func chest(golden: bool, open: bool) -> ImageTexture:
	return _c("chest|%s|%s" % [golden, open], func(): return PropsArt.chest(golden, open))


func plant(biome: String, h: int, variant: int) -> ImageTexture:
	return _c("plant|%s|%d|%d" % [biome, h, variant % 5], func(): return PropsArt.plant(biome, h, variant % 5))


func vine(biome: String, h: int, variant: int) -> ImageTexture:
	return _c("vine|%s|%d|%d" % [biome, h, variant % 5], func(): return PropsArt.vine(biome, h, variant % 5))


func egg() -> ImageTexture:
	return _c("egg", func(): return PropsArt.egg())


func hive() -> ImageTexture:
	return _c("hive", func(): return PropsArt.hive())


func hazard(id: String, frame: int) -> ImageTexture:
	return _c("hz|%s|%d" % [id, frame % 4], func(): return PropsArt.hazard(id, frame % 4))


func door(color_hex: String, frame: int) -> ImageTexture:
	return _c("door|%s|%d" % [color_hex, frame % 4], func(): return PropsArt.door(color_hex, frame % 4))


func stall(kind: String) -> ImageTexture:
	return _c("stall|" + kind, func(): return PropsArt.stall(kind))


func altar(i: int) -> ImageTexture:
	return _c("altar|%d" % i, func(): return PropsArt.altar(i))


func hat(id: String) -> Variant:
	return _c("hat|" + id, func(): return PropsArt.hat(id))


func companion(id: String, frame: int) -> Variant:
	return _c("comp|%s|%d" % [id, frame % 2], func(): return PropsArt.companion(id, frame % 2))


## Vuelca todo el arte a PNG para revisarlo o editarlo.
func export_all(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for r in Content.RACES:
		for anim in Humanoid.ANIMS:
			for i in Humanoid.ANIMS[anim]:
				hero_frame(r["id"], anim, i)["tex"].get_image().save_png("%s/raza_%s_%s_%d.png" % [dir, r["id"], anim, i])
	for k in Humanoid.ENEMY_LOOKS:
		for i in 6:
			npc_frame(k, "run", i)["tex"].get_image().save_png("%s/hum_%s_run_%d.png" % [dir, k, i])
	for id in Content.ENEMIES:
		var e: Dictionary = Content.ENEMIES[id]
		var spr: String = e["spr"]
		if spr.begins_with("humano:") or spr == "muro":
			continue
		for i in 4:
			enemy_frame(spr, e.get("pal", ""), "move", i)["tex"].get_image().save_png("%s/enemigo_%s_%d.png" % [dir, id, i])
	for id in ItemDB.all():
		icon(id).get_image().save_png("%s/objeto_%s.png" % [dir, id])
	for h in Content.HATS:
		var t = hat(h["id"])
		if t:
			t.get_image().save_png("%s/sombrero_%s.png" % [dir, h["id"]])
	for cp in Content.COMPANIONS:
		var t2 = companion(cp["id"], 0)
		if t2:
			t2.get_image().save_png("%s/companero_%s.png" % [dir, cp["id"]])
	for b in PropsArt.TREE_COLORS:
		tree(b, 0).get_image().save_png("%s/arbol_%s.png" % [dir, b])
	for o in PropsArt.ORE_COLORS:
		rock(o, "bosque").get_image().save_png("%s/roca_%s.png" % [dir, o])
