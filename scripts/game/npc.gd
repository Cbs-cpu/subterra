class_name Npc
extends Node2D
## Habitantes del pueblo: tenderos, artesanos, comprador, altares y vecinos que pasean.
## Las puertas de salida del distrito también son de esta clase (kind "puerta").

const LINES := [
	"Dicen que la Ceniza sube un palmo cada noche.",
	"Dos cosas iguales hacen una mejor. Así se fabrica todo aquí abajo.",
	"Si te quedas demasiado en un distrito, vendrán los guardianes. No preguntes cómo lo sé.",
	"Las puertas de colores llevan a sitios distintos. La verde es la más tranquila.",
	"¿Hambre? Una carne asada no se niega a nadie. Necesitarás un encendedor.",
	"Los picos de madera solo arañan la piedra. Para el hierro, algo mejor.",
	"Mi primo abrió un cofre dorado sin llave. Ahora es un cofre dorado.",
	"Los bichos de luz se cazan con red. Dos iguales hacen una gema.",
	"El herrero trabaja con tres lingotes iguales. Ni uno menos.",
	"Hay quien dice que ha visto un caballero fantasma. Hay quien dice muchas cosas.",
]

var world: Node
var kind := "vecino"          # tendero, herrero, sastra, peletero, comprador, altar, vecino, puerta
var shop := ""
var altar_id := ""
var biome := ""
var t := 0.0
var dead := false
var walk_dir := 0.0
var walk_t := 0.0
var line_i := 0
var talk_t := 0.0
var net_id := 0
var stolen := false


func setup(w: Node, d: Dictionary) -> void:
	world = w
	kind = d.get("npc", d["kind"])
	if d["kind"] == "altar":
		kind = "altar"
		altar_id = d["altar"]
	if d["kind"] == "puerta":
		kind = "puerta"
		biome = d["biome"]
	shop = d.get("shop", "")
	position = d["pos"]
	line_i = world.rng.randi() % LINES.size()
	if kind == "puerta":
		var l := Art.make_light(Color(Content.biome(biome)["door"]), 80.0, 1.2)
		l.position = Vector2(0, -24)
		add_child(l)
	elif kind == "altar":
		var l2 := Art.make_light(Color("#c0a0ff"), 50.0, 0.8)
		l2.position = Vector2(0, -30)
		add_child(l2)


func rect() -> Rect2:
	if kind == "puerta":
		return Rect2(position.x - 14, position.y - 44, 28, 44)
	if kind in ["tendero", "herrero", "sastra", "peletero", "comprador"]:
		return Rect2(position.x - 28, position.y - 40, 56, 40)
	return Rect2(position.x - 10, position.y - 26, 20, 26)


func label() -> String:
	match kind:
		"tendero": return "Tienda de herramientas" if shop == "herramientas" else "Tienda de materiales"
		"herrero": return "Herrero"
		"sastra": return "Sastra"
		"peletero": return "Peletero"
		"comprador": return "Comprador"
		"altar": return Content.find(Content.ALTARS, altar_id)["name"]
		"puerta": return Content.biome(biome)["name"]
	return "Vecino"


func tick(dt: float) -> void:
	t += dt
	talk_t = maxf(0.0, talk_t - dt)
	if kind == "vecino":
		walk_t -= dt
		if walk_t <= 0.0:
			walk_t = world.rng.randf_range(1.5, 4.0)
			walk_dir = [-1.0, 0.0, 1.0][world.rng.randi() % 3]
		position.x = clampf(position.x + walk_dir * 18.0 * dt, 40.0, world.map_w_px - 60.0)
		# Carterista: roba al pasar.
		for p in world.players:
			if not stolen and p.model.fx().has("pickpocket") and absf(p.position.x - position.x) < 12.0:
				stolen = true
				var n = world.rng.randi_range(2, 8)
				p.model.coins += n
				world.fx.text(position + Vector2(0, -30), "+%d (robado)" % n, Color("#f0d03a"))
	queue_redraw()


func talk() -> String:
	talk_t = 3.0
	line_i = (line_i + 1) % LINES.size()
	return LINES[line_i]


func _draw() -> void:
	match kind:
		"puerta":
			var col: String = Content.biome(biome)["door"]
			draw_texture(Art.door(col, int(t * 6.0)), Vector2(-18, -50))
			PixelFont.draw_centered(self, 0, -60, label(), Color(col).lightened(0.3))
		"altar":
			var idx := 0
			for i in Content.ALTARS.size():
				if Content.ALTARS[i]["id"] == altar_id:
					idx = i
			draw_texture(Art.altar(idx), Vector2(-12, -36))
			draw_circle(Vector2(0, -30), 7.0 + sin(t * 3.0), Color(1, 1, 1, 0.08))
		"vecino":
			var fr: Dictionary = Art.npc_frame("vecino", "run" if walk_dir != 0.0 else "idle", int(t * (9.0 if walk_dir != 0.0 else 3.0)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1 if walk_dir < 0.0 else 1, 1))
			draw_texture(fr["tex"], Vector2(-7, -18))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if talk_t > 0.0:
				PixelFont.draw_centered(self, 0, -40, PixelFont.wrap(LINES[line_i], 34), Color("#f4f0e0"))
		_:
			draw_texture(Art.stall(kind), Vector2(-28, -44))
			var fr2: Dictionary = Art.npc_frame(kind, "idle", int(t * 3.0))
			draw_texture(fr2["tex"], Vector2(-7, -22))
			PixelFont.draw_centered(self, 0, -54, label(), Color("#f4e0b0"))
