class_name Projectile
extends Node2D
## Proyectil genérico (flechas, hechizos, disparos enemigos, lanzables).

var world: Node
var owner_node: Node
var team := "player"
var kind := "flecha"
var pal := "madera"
var vel := Vector2.ZERO
var grav := 0.0
var dmg := 1
var crit := false
var walls := false        # atraviesa paredes
var pierce := false
var radius := 3.0
var life := 2.0
var item := ""            # flecha recuperable
var elem := ""
var cause := ""
var orbit: Node = null
var orbit_a := 0.0
var hit := {}
var dead := false
var t := 0.0
var net_id := 0
var boosted := false


func setup(w: Node, d: Dictionary) -> void:
	world = w
	owner_node = d.get("owner")
	team = d.get("team", "player")
	kind = d.get("kind", "flecha")
	pal = d.get("pal", "madera")
	position = d.get("pos", Vector2.ZERO)
	vel = d.get("vel", Vector2.ZERO)
	grav = d.get("grav", 0.0)
	dmg = d.get("dmg", 1)
	crit = d.get("crit", false)
	walls = d.get("walls", false)
	pierce = d.get("pierce", false)
	radius = d.get("radius", 3.0)
	life = d.get("life", 2.0)
	item = d.get("item", "")
	elem = d.get("elem", "")
	cause = d.get("cause", kind)
	orbit = d.get("orbit")
	orbit_a = d.get("orbit_a", 0.0)


func tick(dt: float) -> void:
	t += dt
	life -= dt
	if life <= 0.0:
		_end(false)
		return
	if orbit != null:
		if not is_instance_valid(orbit) or orbit.dead:
			_end(false)
			return
		position = orbit.center() + Vector2(22, 0).rotated(orbit_a + t * 4.0)
		hit = {} if int(t * 3.0) != int((t - dt) * 3.0) else hit
	else:
		vel.y += Actor.GRAVITY * grav * dt
		var steps := maxi(1, int(ceil(vel.length() * dt / 4.0)))
		for _i in steps:
			position += vel * dt / steps
			if not walls and world.solid_at(position):
				_end(true)
				return
			if _check_hits():
				return
	queue_redraw()


func _check_hits() -> bool:
	if team == "player" or team == "ally":
		for e in world.enemies:
			if e.dead or hit.has(e) or e.invulnerable or e.data["ai"] in ["aliado"]:
				continue
			if e.data["ai"] == "pasivo" and team == "ally":
				continue
			if e.rect().grow(radius).has_point(position):
				var dd := dmg
				if boosted:
					dd *= 2
				e.take_damage(dd, vel.normalized() * 80.0, owner_node, crit)
				_on_hit_fx(e)
				if not pierce:
					_end(false)
					return true
				hit[e] = true
		# Las flechas también cosechan: cortan la hierba y abren colmenas/huevos.
		for n in world.nodes:
			if not n.dead and n.kind in ["hierba", "colmena", "huevo_arana"] and n.rect().has_point(position):
				n.hit_by(owner_node, "proyectil", 0)
	else:
		for p in world.players:
			if p.dead or p.downed or hit.has(p):
				continue
			if p.rect().grow(radius).has_point(position):
				p.hurt(dmg, cause, position)
				if not pierce:
					_end(false)
					return true
				hit[p] = true
	return false


func _on_hit_fx(e: Node) -> void:
	match elem:
		"fuego":
			world.fx.burst(position, Color("#f58a2a"), 5)
		"hielo":
			e.vel.x *= 0.3
			world.fx.burst(position, Color("#8ac4f0"), 5)
		"rayo":
			world.fx.burst(position, Color("#f0e03a"), 5)
		"veneno":
			world.fx.burst(position, Color("#7ac02a"), 5)


func _end(hit_wall: bool) -> void:
	if dead:
		return
	dead = true
	if kind == "veneno_nube" or kind == "vial":
		world.poison_cloud(position, dmg, team)
	elif kind == "esquirla_ceniza":
		world.fx.explosion(position, 20.0)
	if item != "" and world.rng.randf() < 0.75:
		world.drop_item(Inventory.make(item, 1), position - vel.normalized() * 4.0, Vector2.ZERO, true)
	if hit_wall:
		world.fx.burst(position, Color(0.8, 0.8, 0.8), 2)


func _draw() -> void:
	var ang := vel.angle()
	match kind:
		"flecha", "flecha_enemiga":
			draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)
			var shaft := Color("#9c6a3c") if kind == "flecha" else Color("#d6ccae")
			draw_rect(Rect2(-7, -0.5, 10, 1), shaft)
			draw_rect(Rect2(3, -1.5, 3, 3), Pix.ramp(pal, 3) if kind == "flecha" else Color("#8b8b9c"))
			draw_rect(Rect2(-8, -1.5, 2, 3), Color("#f4f4f8"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bola_fuego", "bola_fuego_enemiga":
			draw_circle(Vector2.ZERO, radius + 1.5, Color(1, 0.5, 0.1, 0.35))
			draw_circle(Vector2.ZERO, radius, Color("#f58a2a"))
			draw_circle(Vector2(-1, -1), radius * 0.5, Color("#ffd24a"))
			draw_circle(-vel.normalized() * 5.0, radius * 0.6, Color(1, 0.4, 0.1, 0.5))
		"rayo":
			for k in 6:
				var y := -k * 12.0
				draw_line(Vector2(sin(t * 50.0 + k) * 3.0, y), Vector2(sin(t * 50.0 + k + 1.0) * 3.0, y - 12.0), Color("#fffcc0"), 2.0)
			draw_circle(Vector2.ZERO, 5.0, Color(1, 1, 0.6, 0.6))
		"escarcha", "esquirla":
			draw_set_transform(Vector2.ZERO, t * 6.0, Vector2.ONE)
			for k in 3:
				draw_line(Vector2.ZERO, Vector2(5, 0).rotated(k * TAU / 3.0), Color("#e0f4ff"), 2.0)
				draw_line(Vector2.ZERO, Vector2(-5, 0).rotated(k * TAU / 3.0), Color("#8ac4f0"), 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"meteoro":
			draw_circle(Vector2.ZERO, radius + 1.0, Color("#1a3a10"))
			draw_circle(Vector2.ZERO, radius, Color("#7ac02a"))
			draw_circle(-vel.normalized() * 6.0, radius * 0.7, Color(0.5, 0.8, 0.2, 0.5))
		"espora":
			draw_circle(Vector2.ZERO, radius, Color("#8a4ac0"))
			draw_circle(Vector2(-1, -1), 1.5, Color("#d0a0f0"))
		"bola_magica", "bola_cosmica_enemiga":
			draw_circle(Vector2.ZERO, radius + 1.0, Color(0.9, 0.5, 1.0, 0.4))
			draw_circle(Vector2.ZERO, radius, Color("#e05a9a") if kind == "bola_cosmica_enemiga" else Color("#a05ad8"))
		"bola_oscura":
			draw_circle(Vector2.ZERO, radius + 1.0, Color(0.5, 0.1, 0.4, 0.5))
			draw_circle(Vector2.ZERO, radius, Color("#4a1a5a"))
			draw_circle(Vector2(-1, -1), 1.5, Color("#e05a9a"))
		"bola_nieve":
			draw_circle(Vector2.ZERO, radius + 1.0, Color("#8ac4f0"))
			draw_circle(Vector2.ZERO, radius, Color("#f4f8ff"))
		"laser":
			draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)
			draw_rect(Rect2(-8, -1, 12, 2), Color("#ff6aa0"))
			draw_rect(Rect2(-6, -0.5, 10, 1), Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"hacha":
			draw_set_transform(Vector2.ZERO, t * 14.0, Vector2.ONE)
			draw_texture(Art.icon("hacha_hierro"), Vector2(-6, -6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"hoja_gigante":
			draw_set_transform(Vector2.ZERO, PI / 2.0 + PI / 4.0, Vector2(2, 2))
			draw_texture(Art.icon("espada_diamante"), Vector2(-6, -6), Color(1, 1, 1, 0.9))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"vial", "esquirla_ceniza":
			draw_set_transform(Vector2.ZERO, t * 10.0, Vector2.ONE)
			draw_texture(Art.icon("vial_veneno" if kind == "vial" else "esquirla_ceniza"), Vector2(-6, -6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"cuchilla":
			draw_set_transform(Vector2.ZERO, t * 20.0, Vector2.ONE)
			draw_texture(Art.hazard("cuchilla_cristal", 0), Vector2(-10, -10), Color(0.8, 0.9, 1.0, 0.9))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_:
			draw_circle(Vector2.ZERO, radius, Color.WHITE)
