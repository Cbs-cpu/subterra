class_name Hazard
extends Node2D
## Trampas ambientales de cada bioma.

const DAMAGE := {"bloque_pinchos": 1, "espora": 1, "bola_pinchos": 4, "carambano": 2, "columna_fuego": 6,
	"cuchilla_cristal": 5, "bola_cosmica": 6}

var world: Node
var kind := ""
var origin := Vector2.ZERO
var t := 0.0
var phase := 0.0
var fall_v := 0.0
var falling := false
var dead := false
var cd := 0.0
var net_id := 0


func setup(w: Node, d: Dictionary) -> void:
	world = w
	kind = d["id"]
	position = d["pos"]
	origin = position
	phase = world.rng.randf() * TAU
	var glow := {"columna_fuego": "#ff8a2a", "bola_cosmica": "#e05aff", "cuchilla_cristal": "#6af0e0", "espora": "#a05ae0"}
	if glow.has(kind):
		add_child(Art.make_light(Color(glow[kind]), 60.0, 1.0))
	if kind == "carambano":
		# Se cuelga del techo más cercano.
		var y := position.y - 8.0
		while y > 0.0 and not world.solid_at(Vector2(position.x, y)):
			y -= 4.0
		position.y = y + 18.0
		origin = position
	elif kind == "bloque_pinchos":
		position.y -= 24.0
		origin = position


func rect() -> Rect2:
	match kind:
		"bloque_pinchos": return Rect2(position.x - 8, position.y - 8, 16, 16)
		"espora": return Rect2(position.x - 5, position.y - 10, 10, 10)
		"bola_pinchos", "cuchilla_cristal": return Rect2(position.x - 7, position.y - 7, 14, 14)
		"carambano": return Rect2(position.x - 3, position.y - 16, 6, 16)
	return Rect2(position.x - 6, position.y - 6, 12, 12)


func tick(dt: float) -> void:
	t += dt
	cd = maxf(0.0, cd - dt)
	match kind:
		"bloque_pinchos":
			position = origin + Vector2(sin(t * 0.9 + phase) * 40.0, 0)
		"bola_pinchos":
			position = origin + Vector2(34, 0).rotated(t * 1.6 + phase)
		"cuchilla_cristal":
			position = origin + Vector2(sin(t * 1.2 + phase) * 30.0, cos(t * 0.8 + phase) * 16.0)
		"columna_fuego", "bola_cosmica":
			position = origin + Vector2(0, -abs(sin(t * 1.4 + phase)) * 90.0)
		"espora":
			if fmod(t + phase, 3.0) < dt:
				world.spawn_projectile({"owner": self, "team": "enemy", "kind": "espora", "pos": position + Vector2(0, -10),
					"vel": Vector2(world.rng.randf_range(-20, 20), -200), "grav": 0.5, "dmg": 1, "radius": 3.0, "life": 2.0, "cause": "espora"})
		"carambano":
			if not falling:
				for p in world.players:
					if absf(p.position.x - position.x) < 14.0 and p.position.y > position.y and p.position.y - position.y < 160.0:
						falling = true
						Sfx.play("crujido", 0.1, -8.0)
			else:
				fall_v += Actor.GRAVITY * dt
				position.y += fall_v * dt
				if world.solid_at(position + Vector2(0, 1)):
					world.fx.burst(position, Color("#e0f4ff"), 6)
					dead = true
					return
	if cd <= 0.0:
		var r := rect()
		for p in world.players:
			if not p.dead and not p.downed and r.intersects(p.rect()):
				p.hurt(DAMAGE.get(kind, 1), kind, position)
				cd = 0.4
	queue_redraw()


func _draw() -> void:
	match kind:
		"bola_pinchos":
			var o := origin - position
			draw_line(o, Vector2.ZERO, Color("#56566b"), 1.0)
			draw_circle(o, 2.0, Color("#3a3a46"))
			draw_texture(Art.hazard(kind, 0), Vector2(-9, -9))
		"bloque_pinchos":
			draw_texture(Art.hazard(kind, 0), Vector2(-9, -9))
		"espora":
			draw_texture(Art.hazard(kind, 1 if fmod(t + phase, 3.0) < 0.4 else 0), Vector2(-7, -14))
		"carambano":
			draw_texture(Art.hazard(kind, 0), Vector2(-5, -17))
		"cuchilla_cristal":
			draw_texture(Art.hazard(kind, int(t * 10.0)), Vector2(-10, -10))
		"columna_fuego", "bola_cosmica":
			draw_texture(Art.hazard(kind, int(t * 8.0)), Vector2(-7, -7))
