class_name WorldNode
extends Node2D
## Recursos y objetos estáticos del distrito: árbol, roca/veta, hierba, luz de bichos, cofre,
## huevo de araña y colmena.

const ORE_REQ := {"piedra": 0, "carbon": 0, "hierro": 1, "oro": 2, "diamante": 3, "ceniza": 4}

var world: Node
var kind := ""
var hp := 3
var ore := "piedra"
var elem := "fuego"
var golden := false
var open := false
var dead := false
var t := 0.0
var shake_t := 0.0
var variant := 0
var net_id := 0
## Árbol alto con dibujo de planta (0 = árbol normal): altura en píxeles y variante.
var plant_h := 0
var plant_v := 0


func setup(w: Node, d: Dictionary) -> void:
	world = w
	kind = d["kind"]
	position = d["pos"]
	ore = d.get("ore", "piedra")
	elem = d.get("elem", "fuego")
	golden = d.get("golden", false)
	variant = int(position.x) % 7
	plant_h = d.get("plant_h", 0)
	plant_v = d.get("v", 0)
	if kind == "luz_bicho":
		var l := Art.make_light(_elem_col(), 46.0, 1.1)
		add_child(l)
	elif kind == "roca" and ore in ["diamante", "ceniza", "oro"]:
		var l2 := Art.make_light(Color(PropsArt.ORE_COLORS[ore]), 26.0, 0.7)
		l2.position = Vector2(0, -6)
		add_child(l2)
	elif kind == "cofre" and golden:
		var l3 := Art.make_light(Color("#ffd04a"), 30.0, 0.7)
		l3.position = Vector2(0, -6)
		add_child(l3)
	match kind:
		"arbol": hp = 4 if plant_h == 0 else 2 + plant_h / 40
		"roca": hp = 3 + ORE_REQ.get(ore, 0)
		"hierba": hp = 1
		"colmena": hp = 3
		"huevo_arana": hp = 2
		"cofre": hp = 1
		"luz_bicho": hp = 1


func rect() -> Rect2:
	match kind:
		"arbol":
			var th := 40 if plant_h == 0 else plant_h
			return Rect2(position.x - 8, position.y - th, 16, th)
		"roca": return Rect2(position.x - 9, position.y - 15, 18, 15)
		"hierba": return Rect2(position.x - 7, position.y - 10, 14, 10)
		"luz_bicho": return Rect2(position.x - 7, position.y - 7, 14, 14)
		"colmena": return Rect2(position.x - 8, position.y - 18, 16, 18)
		"huevo_arana": return Rect2(position.x - 6, position.y - 14, 12, 14)
	return Rect2(position.x - 8, position.y - 12, 16, 12)


func tick(dt: float) -> void:
	t += dt
	shake_t = maxf(0.0, shake_t - dt)
	if kind == "luz_bicho" or shake_t > 0.0 or open:
		queue_redraw()
	elif kind in ["hierba", "arbol"] and int(t * 8.0) != int((t - dt) * 8.0):
		queue_redraw()


## Golpe de un jugador con una herramienta. tool: hacha, pico, red, espada, puño, proyectil...
func hit_by(hero: Node, tool: String, tier: int) -> bool:
	if dead:
		return false
	match kind:
		"arbol":
			if tool != "hacha":
				return false
			shake_t = 0.2
			var h: Hero = hero
			var n := 1 + tier / 2
			world.drop_item(Inventory.make("madera", n), position + Vector2(0, -20), Vector2(world.rng.randf_range(-60, 60), -120))
			if world.rng.randf() < 0.6:
				world.drop_item(Inventory.make("palo", 1), position + Vector2(0, -20), Vector2(world.rng.randf_range(-60, 60), -100))
			world.fx.leaves(position + Vector2(0, -30), world.biome)
			Sfx.play("talar", 0.15, -4.0)
			hp -= 1
			if hp <= 0:
				_break()
				world.counters_add(h, "trees", 1)
			return true
		"roca":
			if tool != "pico":
				if tool in ["hacha", "espada"]:
					world.fx.text(position + Vector2(0, -18), "necesitas un pico", Color("#c0c0c0"))
				return false
			if tier < int(ORE_REQ.get(ore, 0)):
				world.fx.text(position + Vector2(0, -18), "pico demasiado débil", Color("#e0a0a0"))
				Sfx.play("tink", 0.1, -6.0)
				return true
			shake_t = 0.15
			Sfx.play("minar", 0.15, -4.0)
			world.fx.burst(position + Vector2(0, -8), Color("#8b8b9c"), 3)
			hp -= 1
			if hp <= 0:
				var drop := "piedra"
				match ore:
					"carbon": drop = "carbon"
					"hierro", "oro", "diamante": drop = "mena_" + ore
					"ceniza": drop = "fragmento_ceniza"
				var n2 := 1 + (1 if world.rng.randf() < 0.4 else 0)
				if hero.model.fx().has("ore_extra") and world.rng.randf() < 0.25:
					n2 += 1
				world.drop_item(Inventory.make(drop, n2), position + Vector2(0, -10), Vector2(0, -120))
				if ore == "piedra" and world.rng.randf() < 0.3:
					world.drop_item(Inventory.make("carbon", 1), position + Vector2(0, -10), Vector2(30, -120))
				if drop != "piedra":
					world.counters_add(hero, "ores", 1)
				_break()
			return true
		"hierba":
			var pool := ["hierba", "hierba", "seta", "raiz"]
			if world.rng.randf() < 0.55:
				var n3 := 2 if hero.model.fx().has("gather_double") and world.rng.randf() < 0.5 else 1
				world.drop_item(Inventory.make(pool[world.rng.randi() % pool.size()], n3), position + Vector2(0, -6), Vector2(0, -90))
				if hero.model.fx().has("gather_item") and world.rng.randf() < 0.25:
					world.drop_item(Inventory.make(pool[world.rng.randi() % pool.size()], 1), position, Vector2(20, -90))
			world.counters_add(hero, "plants", 1)
			world.fx.leaves(position, world.biome)
			Sfx.play("hierba", 0.2, -10.0)
			_break()
			return true
		"luz_bicho":
			if tool != "red":
				return false
			world.drop_item(Inventory.make("bicho_" + elem, 1), position, Vector2(0, -40))
			world.fx.sparkle(position, _elem_col())
			Sfx.play("recoger")
			_break()
			return true
		"colmena":
			hp -= 1
			shake_t = 0.2
			if hp <= 0:
				for k in 7:
					world.spawn_enemy("avispa", position + Vector2(world.rng.randf_range(-10, 10), -14))
				world.counters_add(hero, "hives", 1)
				_break()
			return true
		"huevo_arana":
			hp -= 1
			shake_t = 0.2
			if hp <= 0:
				world.egg_broken(position)
				_break()
			return true
		"cofre":
			return interact(hero)
	return false


func interact(hero: Node) -> bool:
	if kind != "cofre" or open:
		return false
	if golden and not hero.model.fx().has("lockmaster"):
		if hero.model.inv.count("llave") <= 0:
			world.fx.text(position + Vector2(0, -18), "necesitas una llave", Color("#f0d03a"))
			return true
		hero.model.inv.remove("llave", 1)
	open = true
	queue_redraw()
	Sfx.play("cofre")
	world.open_chest(self, hero)
	return true


func _break() -> void:
	dead = true
	pass
	world.fx.burst(position + Vector2(0, -8), Color("#9c6a3c") if kind == "arbol" else Color("#8b8b9c"), 8)


func _elem_col() -> Color:
	return {"fuego": Color("#f58a2a"), "hielo": Color("#8ac4f0"), "rayo": Color("#f0e03a")}.get(elem, Color.WHITE)


func _draw() -> void:
	var sx := sin(t * 60.0) * 1.5 if shake_t > 0.0 else 0.0
	if kind == "arbol" and shake_t <= 0.0:
		sx = roundf(sin(t * 1.3 + variant) * 0.6)
	match kind:
		"arbol":
			if plant_h > 0:
				draw_texture(Art.plant(world.biome, plant_h, plant_v), Vector2(-14 + sx, -plant_h))
			else:
				var tt := Art.tree(world.biome, variant)
				draw_texture(tt, Vector2(-tt.get_width() / 2.0 + sx, -tt.get_height()))
		"roca":
			draw_texture(Art.rock(ore, world.biome), Vector2(-9 + sx, -16))
		"hierba":
			draw_texture(Art.grass(world.biome, int(t * 1.5 + variant)), Vector2(-7, -10))
		"luz_bicho":
			var c := _elem_col()
			var p := Vector2(sin(t * 1.3 + variant) * 6.0, cos(t * 1.7 + variant) * 4.0)
			draw_circle(p, 3.5 + sin(t * 4.0) * 0.8, Color(c.r, c.g, c.b, 0.14))
			draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), Color(c.r, c.g, c.b, 0.9))
			if int(t * 3.0 + variant) % 3 == 0:
				draw_rect(Rect2(p.round() + Vector2(-2, 0), Vector2(1, 1)), Color(1, 1, 1, 0.7))
		"cofre":
			draw_texture(Art.chest(golden, open), Vector2(-8, -13))
			if golden and not open and int(t * 3.0) % 3 == 0:
				draw_rect(Rect2(4, -12, 1, 1), Color.WHITE)
		"colmena":
			draw_texture(Art.hive(), Vector2(-8 + sx, -18))
		"huevo_arana":
			draw_texture(Art.egg(), Vector2(-6 + sx, -14))
