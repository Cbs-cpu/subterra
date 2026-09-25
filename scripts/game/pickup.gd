class_name Pickup
extends Actor
## Objeto, moneda u orbe de experiencia en el suelo. Se atrae hacia el jugador cercano.

var kind := "item"        # item, coin, xp
var stack := {}
var value := 1
var t := 0.0
var pickup_delay := 0.4
var no_magnet := false


func _init() -> void:
	size = Vector2(8, 8)


func tick(dt: float) -> void:
	t += dt
	pickup_delay -= dt
	var near: Node = null
	var bd := 44.0 if kind != "item" else 26.0
	for p in world.players:
		if p.dead or p.downed:
			continue
		var d: float = p.center().distance_to(position)
		if d < bd:
			bd = d
			near = p
	if near and pickup_delay <= 0.0 and not no_magnet:
		var dir: Vector2 = near.center() - position
		use_gravity = false
		vel = vel.move_toward(dir.normalized() * 220.0, 900.0 * dt)
		position += vel * dt
		if dir.length() < 8.0:
			_collect(near)
		queue_redraw()
		return
	use_gravity = true
	vel.x = move_toward(vel.x, 0.0, 200.0 * dt)
	physics_move(dt)
	if near and pickup_delay <= 0.0 and near.rect().grow(2).intersects(rect()):
		_collect(near)
	queue_redraw()


func _collect(p: Node) -> void:
	match kind:
		"coin":
			var mult: float = p.model.fx().get("gold_mult", 1.0)
			p.model.coins += int(value * mult)
			Sfx.play("moneda", 0.15, -10.0)
		"xp":
			world.give_xp(p, value)
			Sfx.play("xp", 0.2, -14.0)
		_:
			var got: int = stack["n"]
			var left: int = p.model.inv.add(stack)
			if left > 0:
				stack["n"] = left
				no_magnet = true
				pickup_delay = 1.5
				return
			Sfx.play("recoger", 0.1, -8.0)
			world.fx.gain(p.center() + Vector2(0, -14), stack["id"], got)
			world.on_pickup(p, stack)
	dead = true


func _draw() -> void:
	var bob := sin(t * 4.0) * 1.5 if on_floor else 0.0
	match kind:
		"coin":
			var w := absf(cos(t * 6.0)) * 3.0 + 1.0
			draw_rect(Rect2(-w, -7 + bob, w * 2, 6), Color("#c0801e"))
			draw_rect(Rect2(-w + 0.5, -6.5 + bob, w * 2 - 1, 5), Color("#f0b93a"))
		"xp":
			draw_circle(Vector2(0, -4 + bob), 3.0, Color(0.4, 1.0, 0.5, 0.35))
			draw_circle(Vector2(0, -4 + bob), 1.8, Color("#8aff9a"))
		_:
			draw_texture(Art.icon(stack["id"]), Vector2(-6, -12 + bob))
			if stack.get("q", 0) > 0:
				var qc = [Color.WHITE, Color("#5a9af0"), Color("#f0d03a"), Color("#c05af0")][stack["q"]]
				draw_rect(Rect2(-6, -13 + bob, 12, 1), qc)
