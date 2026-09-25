class_name Summon
extends Node2D
## Efectos invocados: súbdito nigromante, fuego fatuo, cuchilla del guardia mecánico y nube de veneno.

var world: Node
var kind := ""
var owner_hero: Node
var life := 5.0
var t := 0.0
var shot_t := 0.0
var shots_left := 6
var dmg := 1
var team := "player"
var dead := false
var hit_cd := {}
var net_id := 0


func tick(dt: float) -> void:
	t += dt
	life -= dt
	if life <= 0.0:
		dead = true
		return
	match kind:
		"subdito":
			shot_t -= dt
			if shot_t <= 0.0 and shots_left > 0:
				shot_t = 1.0
				shots_left -= 1
				var tg := _nearest_enemy()
				var dir = (tg.center() - position).normalized() if tg else Vector2.RIGHT
				world.spawn_projectile({"owner": owner_hero, "team": "player", "kind": "bola_fuego", "pos": position,
					"vel": dir * 220.0, "dmg": dmg, "walls": true, "radius": 5.0, "life": 1.8, "elem": "fuego"})
		"fatuo":
			for p in world.projectiles:
				if p.team == "player" and p.kind == "flecha" and not p.boosted and p.position.distance_to(position) < 12.0:
					p.boosted = true
					world.fx.sparkle(p.position, Color("#8affc0"))
		"cuchilla":
			if owner_hero and is_instance_valid(owner_hero):
				position = owner_hero.center()
			_area_damage(18.0)
		"nube":
			_area_damage(22.0)
	for k in hit_cd.keys():
		hit_cd[k] -= dt
	queue_redraw()


func _nearest_enemy() -> Node:
	var best: Node = null
	var bd := 260.0
	for e in world.enemies:
		if not e.dead and not e.invulnerable and e.data["ai"] not in ["aliado", "pasivo"]:
			var d := position.distance_to(e.center())
			if d < bd:
				bd = d
				best = e
	return best


func _area_damage(r: float) -> void:
	if team == "player":
		for e in world.enemies:
			if e.dead or e.invulnerable or e.data["ai"] == "aliado" or hit_cd.get(e, 0.0) > 0.0:
				continue
			if e.center().distance_to(position) < r + e.size.x / 2.0:
				e.take_damage(dmg, (e.center() - position).normalized() * 60.0, owner_hero)
				hit_cd[e] = 0.5
	else:
		for p in world.players:
			if p.dead or p.downed or hit_cd.get(p, 0.0) > 0.0:
				continue
			if p.center().distance_to(position) < r:
				p.hurt(dmg, "veneno", position)
				hit_cd[p] = 0.8


func _draw() -> void:
	match kind:
		"subdito":
			var fr: Dictionary = Art.npc_frame("rey_esqueleto", "idle", int(t * 4.0))
			draw_texture(fr["tex"], -Vector2(fr["origin"]) + Vector2(0, sin(t * 3.0) * 2.0), Color(0.7, 1.0, 0.8, 0.9))
		"fatuo":
			draw_circle(Vector2.ZERO, 9.0 + sin(t * 5.0), Color(0.4, 1.0, 0.6, 0.2))
			draw_circle(Vector2.ZERO, 4.0, Color(0.6, 1.0, 0.8, 0.8))
		"cuchilla":
			draw_set_transform(Vector2.ZERO, t * 20.0, Vector2.ONE)
			draw_texture(Art.hazard("cuchilla_cristal", 0), Vector2(-10, -10), Color(0.8, 0.9, 1.0))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"nube":
			for k in 5:
				var p := Vector2(sin(t * 2.0 + k) * 10.0, cos(t * 1.5 + k * 2.0) * 6.0)
				draw_circle(p, 8.0, Color(0.4, 0.8, 0.2, 0.25 * clampf(life, 0.0, 1.0)))
