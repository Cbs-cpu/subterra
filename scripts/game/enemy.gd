class_name Enemy
extends Actor
## Enemigos, animales, aliados y jefes. La IA se elige por el campo "ai" de sus datos.

var id := ""
var data := {}
var hp := 10.0
var max_hp := 10.0
var dmg := 1
var speed := 40.0
var armor := 0
var state := "idle"
var state_t := 1.0
var anim_t := 0.0
var attacking := false
var boss := false
var flying := false
var invulnerable := false
var hurt_flee := 0.0
var knock := Vector2.ZERO
var knock_res := 1.0
var target: Node = null
var owner_hero: Node = null     # aliados invocados
var life := -1.0                 # aliados temporales
var ally_dmg := 0
var concealed := false              # mímico cerrado, gusano enterrado
var orbit_t := 0.0
var home := Vector2.ZERO
var shots := 0
var scale_draw := 1.0
var phase2 := false
var contact_cd := 0.0
var land_t := 0.0
## Enemigos por piezas (EnemyRig): animación actual, tiempo dentro de ella y golpe reciente.
var rig_anim := ""
var rig_t := 0.0
var rig_hurt := 0.0
var was_floor := true


func setup_enemy(w: Node, enemy_id: String, district: int, madman: bool) -> void:
	world = w
	id = enemy_id
	data = Content.enemy(id)
	boss = data.get("boss", false)
	var hm := Combat.enemy_hp_mult(district, madman)
	var dm := Combat.enemy_dmg_mult(district, madman)
	if boss:
		hm = 1.0 + (district - 1) * 0.05 + (0.5 if madman else 0.0)
	max_hp = float(data["hp"]) * hm
	hp = max_hp
	dmg = maxi(0, int(round(float(data["dmg"]) * dm)))
	speed = float(data["speed"])
	armor = int(data.get("armor", 0))
	flying = data.get("flying", false)
	noclip = data.get("noclip", false)
	invulnerable = data.get("invulnerable", false)
	use_gravity = not flying
	var sz: Array = data["size"]
	size = Vector2(sz[0], sz[1])
	scale_draw = float(data.get("scale", 1.0))
	knock_res = 0.15 if boss else 1.0
	home = position
	if data["ai"] == "mimico":
		concealed = true
	if data["ai"] == "gusano":
		concealed = true
	state_t = world.rng.randf_range(0.5, 1.5)


func tick(dt: float) -> void:
	anim_t += dt
	rig_t += dt
	rig_hurt = maxf(0.0, rig_hurt - dt)
	flash_t = maxf(0.0, flash_t - dt)
	contact_cd = maxf(0.0, contact_cd - dt)
	hurt_flee = maxf(0.0, hurt_flee - dt)
	if life > 0.0:
		life -= dt
		if life <= 0.0:
			die(null, true)
			return
	state_t -= dt
	attacking = false
	target = _nearest_target()
	var ai: String = data["ai"]
	if has_method("_ai_" + ai):
		call("_ai_" + ai, dt)
	vel += knock
	knock = knock.move_toward(Vector2.ZERO, 900.0 * dt)
	physics_move(dt)
	vel -= knock
	if on_floor and not was_floor:
		land_t = 0.15
	was_floor = on_floor
	land_t = maxf(0.0, land_t - dt)
	if ai != "aliado" and ai != "pasivo" and not concealed and dmg > 0:
		_contact()


func _nearest_target() -> Node:
	if data["ai"] == "aliado":
		var best: Node = null
		var bd := 220.0
		for e in world.enemies:
			if e != self and not e.dead and e.data["ai"] != "aliado" and e.data["ai"] != "pasivo" and not e.invulnerable:
				var d := position.distance_to(e.position)
				if d < bd:
					bd = d
					best = e
		return best
	var bp: Node = null
	var bdist := INF
	for p in world.players:
		if p.dead or p.downed:
			continue
		var d2 := position.distance_to(p.position)
		if d2 < bdist:
			bdist = d2
			bp = p
	return bp


func _dir_to(t: Node) -> Vector2:
	if t == null:
		return Vector2.ZERO
	return (t.center() - center())


func _contact() -> void:
	if contact_cd > 0.0:
		return
	for p in world.players:
		if p.dead or p.downed:
			continue
		if rect().grow(-1).intersects(p.rect()):
			p.hurt(dmg, id, center())
			contact_cd = 0.3


func _edge_ahead() -> bool:
	var t: int = world.T
	var fx := position.x + facing * (size.x / 2.0 + 2.0)
	return world.tile(floori(fx / t), floori((position.y + 2.0) / t)) == 0


func _walk(dir: float, spd: float) -> void:
	vel.x = dir * spd
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	if on_floor and on_wall != 0 and on_wall == int(signf(dir)):
		vel.y = -300.0


func _shoot(kind: String, dir: Vector2, spd: float, extra := {}) -> void:
	var d := {"owner": self, "team": "enemy", "kind": kind, "pos": center() + dir.normalized() * 6.0,
		"vel": dir.normalized() * spd, "dmg": dmg, "radius": 4.0, "life": 3.0, "cause": id}
	d.merge(extra, true)
	world.spawn_projectile(d)


# --- IA de enemigos normales -----------------------------------------------------------

func _ai_pasivo(_dt: float) -> void:
	if hurt_flee > 0.0 and target:
		_walk(-signf(_dir_to(target).x), speed * 2.2)
		return
	if state_t <= 0.0:
		state_t = world.rng.randf_range(1.5, 3.5)
		state = ["idle", "walk"][world.rng.randi() % 2]
		facing = 1 if world.rng.randf() < 0.5 else -1
	if state == "walk":
		if on_wall != 0 or (on_floor and _edge_ahead()):
			facing = -facing
		vel.x = facing * speed
	else:
		vel.x = 0.0


func _ai_saltador(_dt: float) -> void:
	if on_floor:
		vel.x = move_toward(vel.x, 0.0, 30.0)
		if state_t <= 0.0 and target and position.distance_to(target.position) < 260.0:
			var dx := signf(_dir_to(target).x)
			facing = int(dx) if dx != 0.0 else facing
			vel = Vector2(dx * speed, -230.0 - world.rng.randf() * 60.0)
			state_t = world.rng.randf_range(1.2, 2.0)


func _ai_embestidor(_dt: float) -> void:
	var range_px: float = data.get("range", 120.0)
	match state:
		"idle", "walk":
			if target and absf(_dir_to(target).y) < 50.0 and position.distance_to(target.position) < range_px:
				state = "windup"
				state_t = 0.4
				facing = 1 if _dir_to(target).x > 0.0 else -1
				vel.x = 0.0
			else:
				if state_t <= 0.0:
					state_t = 2.0
					facing = -facing if world.rng.randf() < 0.4 else facing
				if on_wall != 0 or (on_floor and _edge_ahead()):
					facing = -facing
				vel.x = facing * speed * 0.3
				if data.get("jumps", false) and on_floor and target and world.rng.randf() < 0.01:
					vel.y = -260.0
		"windup":
			vel.x = 0.0
			if state_t <= 0.0:
				state = "charge"
				state_t = 0.9
				Sfx.play("embestida", 0.1, -8.0)
		"charge":
			attacking = true
			vel.x = facing * speed
			if on_wall != 0 or state_t <= 0.0:
				state = "rest"
				state_t = 0.8
				if on_wall != 0:
					world.fx.dust(position + Vector2(facing * 6, 0), 3)
		"rest":
			vel.x = move_toward(vel.x, 0.0, 20.0)
			if state_t <= 0.0:
				state = "walk"
				state_t = 1.5


func _ai_caminante(_dt: float) -> void:
	if target == null:
		vel.x = 0.0
		return
	var d := _dir_to(target)
	match state:
		"windup":
			vel.x = 0.0
			if state_t <= 0.0:
				state = "strike"
				state_t = 0.25
				world.enemy_melee(self, Rect2(center() + Vector2(facing * 4 - (0 if facing > 0 else 22), -12), Vector2(22, 24)))
		"strike":
			attacking = true
			if state_t <= 0.0:
				state = "cool"
				state_t = 0.8
		"cool":
			vel.x = 0.0
			if state_t <= 0.0:
				state = "idle"
		_:
			if absf(d.x) < 22.0 and absf(d.y) < 24.0:
				facing = 1 if d.x > 0.0 else -1
				state = "windup"
				state_t = 0.35
			elif d.length() < 300.0:
				_walk(signf(d.x), speed)
			else:
				vel.x = 0.0


func _ai_tirador(_dt: float) -> void:
	if target == null:
		vel.x = 0.0
		return
	var d := _dir_to(target)
	var range_px: float = data.get("range", 160.0)
	facing = 1 if d.x > 0.0 else -1
	if flying:
		var want = target.center() + Vector2(-facing * 90.0, -50.0)
		vel = (want - center()).limit_length(speed) + Vector2(0, sin(anim_t * 3.0) * 12.0)
	else:
		if d.length() < 70.0:
			_walk(-signf(d.x), speed)
		elif d.length() > range_px:
			_walk(signf(d.x), speed)
		else:
			vel.x = 0.0
	if d.length() < range_px + 40.0:
		if state == "windup":
			attacking = true
			if state_t <= 0.0:
				_shoot(data.get("proj", "espora"), d, 150.0)
				state = "idle"
				state_t = world.rng.randf_range(1.6, 2.4)
		elif state_t <= 0.0:
			state = "windup"
			state_t = 0.4


func _ai_volador(_dt: float) -> void:
	if target == null:
		vel = vel.move_toward(Vector2.ZERO, 5.0)
		return
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	match state:
		"dash":
			attacking = true
			if state_t <= 0.0 or on_wall != 0:
				state = "rest"
				state_t = 0.6
		"rest":
			vel = vel.move_toward(Vector2.ZERO, 12.0)
			if state_t <= 0.0:
				state = "idle"
		"aim":
			vel = vel.move_toward(Vector2.ZERO, 20.0)
			if state_t <= 0.0:
				state = "dash"
				state_t = 0.45
				vel = d.normalized() * speed * 2.4
		_:
			if d.length() < 70.0:
				state = "aim"
				state_t = 0.3
			else:
				vel = vel.move_toward(d.normalized() * speed + Vector2(0, sin(anim_t * 5.0) * 20.0), 8.0)


func _ai_volador_tirador(dt: float) -> void:
	_ai_tirador(dt)


func _ai_babosa(_dt: float) -> void:
	if on_wall != 0 or (on_floor and _edge_ahead()):
		facing = -facing
	if target and position.distance_to(target.position) < 160.0 and state_t <= 0.0:
		facing = 1 if _dir_to(target).x > 0.0 else -1
		state_t = 2.0
	vel.x = facing * speed


func _ai_medusa(_dt: float) -> void:
	if target == null:
		return
	vel = _dir_to(target).normalized() * speed + Vector2(0, sin(anim_t * 2.0) * 25.0)
	facing = 1 if vel.x > 0.0 else -1


func _ai_mimico(dt: float) -> void:
	if concealed:
		vel.x = 0.0
		if target and position.distance_to(target.position) < 44.0:
			concealed = false
			Sfx.play("mimico")
			world.fx.text(center() + Vector2(0, -14), "¡!", Color("#ff5a5a"))
		return
	_ai_saltador(dt)


func _ai_golem(_dt: float) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	match state:
		"windup":
			vel.x = 0.0
			if state_t <= 0.0:
				state = "cool"
				state_t = 1.4
				world.enemy_melee(self, Rect2(position + Vector2(-34, -20), Vector2(68, 22)))
				world.shake(3.0)
				world.fx.dust(position + Vector2(-20, 0), 5)
				world.fx.dust(position + Vector2(20, 0), 5)
				Sfx.play("golpe_suelo")
		"cool":
			vel.x = 0.0
			if state_t <= 0.0:
				state = "idle"
		_:
			attacking = false
			if d.length() < 40.0:
				state = "windup"
				state_t = 0.6
			else:
				_walk(signf(d.x), speed)


func _ai_gusano(_dt: float) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	if concealed:
		noclip = true
		use_gravity = false
		vel = Vector2(signf(d.x) * speed, 0.0)
		position.y = move_toward(position.y, target.position.y + 30.0, 2.0)
		if absf(d.x) < 10.0 and state_t <= 0.0:
			concealed = false
			state = "rise"
			state_t = 1.4
			position.y = target.position.y + 8.0
			vel = Vector2(0, -220)
			world.fx.dust(position, 6)
			Sfx.play("golpe_suelo")
	else:
		attacking = true
		vel.y += 8.0
		if state_t <= 0.0:
			concealed = true
			state_t = 2.0


func _ai_aliado(_dt: float) -> void:
	use_gravity = true
	if target == null:
		if owner_hero:
			var d2: Vector2 = owner_hero.position - position
			_walk(signf(d2.x) if absf(d2.x) > 24.0 else 0.0, speed)
		return
	var d := _dir_to(target)
	if absf(d.x) < 16.0 and absf(d.y) < 20.0:
		vel.x = 0.0
		if state_t <= 0.0:
			state_t = 0.4
			attacking = true
			target.take_damage(ally_dmg, Vector2(facing * 60, -40), owner_hero)
	else:
		_walk(signf(d.x), speed * 1.3)


func _ai_guardian(dt: float) -> void:
	if target == null:
		return
	speed += dt * 3.0
	vel = _dir_to(target).normalized() * speed
	facing = 1 if vel.x > 0.0 else -1


# --- Jefes ------------------------------------------------------------------------------

func _ai_jefe_tiranodonte(dt: float) -> void:
	_boss_ground(dt, ["charge", "leap", "meteors"])


func _ai_jefe_gallo(dt: float) -> void:
	_boss_ground(dt, ["charge", "meteors"])


func _ai_jefe_corsario(dt: float) -> void:
	_boss_ground(dt, ["slide", "leap"])


func _ai_jefe_yeti(dt: float) -> void:
	_boss_ground(dt, ["throw", "throw", "charge"])


func _ai_jefe_paladin(dt: float) -> void:
	_boss_ground(dt, ["slide", "shot", "leap"])


func _ai_jefe_capitan(dt: float) -> void:
	if hp < max_hp * 0.5 and not phase2:
		phase2 = true
		speed *= 1.5
		world.fx.text(center() + Vector2(0, -30), "¡modo demente!", Color("#ff5a9a"))
	_boss_ground(dt, ["shot", "shot", "leap"] if not phase2 else ["shotgun", "shot", "leap"])


## Patrón común de jefe terrestre: camina hacia el jugador y elige ataques.
func _boss_ground(_dt: float, moves: Array) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	match state:
		"windup":
			vel.x = 0.0
			if state_t <= 0.0:
				_boss_attack()
		"charge", "slide":
			attacking = true
			vel.x = facing * speed * (4.0 if state == "slide" else 3.2)
			if on_wall != 0 or state_t <= 0.0:
				state = "rest"
				state_t = 0.9
				if on_wall != 0:
					world.shake(4.0)
		"leap":
			attacking = true
			if on_floor and state_t < 0.8:
				state = "rest"
				state_t = 0.7
				world.shake(4.0)
				world.fx.dust(position, 8)
				world.enemy_melee(self, Rect2(position + Vector2(-30, -16), Vector2(60, 18)))
		"rest":
			vel.x = move_toward(vel.x, 0.0, 30.0)
			if state_t <= 0.0:
				state = "idle"
				state_t = world.rng.randf_range(0.6, 1.4)
		_:
			facing = 1 if d.x > 0.0 else -1
			var keep: float = 150.0 if id == "capitan_estelar" else 0.0
			if keep > 0.0 and d.length() < keep:
				_walk(-signf(d.x), speed)
			elif absf(d.x) > 40.0:
				_walk(signf(d.x), speed)
			else:
				vel.x = 0.0
			if state_t <= 0.0:
				state = "windup"
				state_t = 0.45
				set_meta("next", moves[world.rng.randi() % moves.size()])
				Sfx.play("jefe_aviso", 0.1, -6.0)


func _boss_attack() -> void:
	var mv: String = get_meta("next", "charge")
	var d := _dir_to(target) if target else Vector2(facing, 0)
	facing = 1 if d.x > 0.0 else -1
	match mv:
		"charge", "slide":
			state = mv
			state_t = 1.0
		"leap":
			state = "leap"
			state_t = 1.4
			vel = Vector2(clampf(d.x * 1.6, -220.0, 220.0), -360.0)
		"meteors":
			for k in 4:
				world.spawn_projectile({"owner": self, "team": "enemy", "kind": "meteoro",
					"pos": target.center() + Vector2(world.rng.randf_range(-70, 70), -150 - k * 30),
					"vel": Vector2(0, 90), "dmg": dmg, "walls": true, "radius": 6.0, "life": 4.0, "cause": id})
			state = "rest"
			state_t = 1.0
		"throw":
			_shoot("bola_nieve", d + Vector2(0, -40), 200.0, {"grav": 0.5})
			state = "rest"
			state_t = 0.6
		"shot":
			_shoot("bola_magica" if id != "capitan_estelar" else "laser", d, 260.0)
			state = "rest"
			state_t = 0.5
		"shotgun":
			for k in 5:
				_shoot("laser", d.rotated((k - 2) * 0.18), 260.0)
			state = "rest"
			state_t = 0.7


func _ai_jefe_madre_arana(_dt: float) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	if state == "move":
		vel = d.normalized() * speed
		if state_t <= 0.0:
			state = "pause"
			state_t = 1.0
	else:
		vel = vel.move_toward(Vector2.ZERO, 10.0)
		if state_t <= 0.0:
			state = "move"
			state_t = 1.4
			shots += 1
			if shots % 3 == 0:
				world.spawn_enemy("arana_morada", center())


func _ai_jefe_rey_esqueleto(_dt: float) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	match state:
		"shoot":
			vel = vel.move_toward(Vector2.ZERO, 20.0)
			if state_t <= 0.0:
				_shoot("bola_fuego_enemiga", d, 280.0)
				state = "charge"
				state_t = 0.9
				vel = d.normalized() * speed * 3.0
		"charge":
			attacking = true
			if state_t <= 0.0:
				state = "rest"
				state_t = 1.0
		"rest":
			vel = vel.move_toward(Vector2.ZERO, 15.0)
			if state_t <= 0.0:
				state = "idle"
				state_t = 0.6
		_:
			vel = vel.move_toward((target.center() + Vector2(-facing * 80, -50) - center()).limit_length(speed), 10.0)
			if state_t <= 0.0:
				state = "shoot"
				state_t = 0.5


func _ai_jefe_reina(dt: float) -> void:
	if target == null:
		return
	orbit_t += dt
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	vel = (target.center() + Vector2(-facing * 110, -70) - center()).limit_length(speed)
	# Esquirlas orbitando: dañan al tocar.
	for k in 3:
		var p := center() + Vector2(24, 0).rotated(orbit_t * 2.5 + k * TAU / 3.0)
		for pl in world.players:
			if not pl.dead and not pl.downed and pl.rect().has_point(p):
				pl.hurt(dmg, id, p)
	if state_t <= 0.0:
		state_t = 2.0
		_shoot("esquirla", d, 220.0)


func _ai_jefe_dragon(_dt: float) -> void:
	if target == null:
		return
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	vel = vel.move_toward(d.normalized() * speed, 6.0)
	if state_t <= 0.0:
		state_t = 2.5
		for k in 3:
			_shoot("bola_oscura", d.rotated(world.rng.randf_range(-0.3, 0.3)), world.rng.randf_range(90.0, 220.0))


func _ai_jefe_ventolin(dt: float) -> void:
	if target == null:
		return
	orbit_t += dt
	var d := _dir_to(target)
	facing = 1 if d.x > 0.0 else -1
	if state == "move":
		vel = d.normalized() * speed
		if state_t <= 0.0:
			state = "pause"
			state_t = 0.5
	else:
		vel = Vector2.ZERO
		if state_t <= 0.0:
			state = "move"
			state_t = 1.2
	for k in 2:
		var p := center() + Vector2(34, 0).rotated(orbit_t * 3.0 + k * PI)
		for pl in world.players:
			if not pl.dead and not pl.downed and pl.rect().grow(4).has_point(p):
				pl.hurt(dmg, id, p)


func _ai_jefe_muro(dt: float) -> void:
	vel = Vector2(speed, 0)
	if position.x > world.map_w_px - 40:
		vel.x = 0.0
	if state_t <= 0.0:
		state_t = world.rng.randf_range(0.7, 1.3)
		var eyes := 5
		for k in eyes:
			if world.rng.randf() < 0.5:
				var p := Vector2(position.x + 30, 40 + k * (world.map_h_px - 80) / float(eyes - 1))
				var tg: Vector2 = target.center() if target else p + Vector2(100, 0)
				world.spawn_projectile({"owner": self, "team": "enemy", "kind": "bola_oscura", "pos": p,
					"vel": (tg - p).normalized() * world.rng.randf_range(80.0, 200.0), "dmg": 5, "walls": true,
					"radius": 5.0, "life": 6.0, "cause": id})
	# Aplasta a quien toque el muro.
	for pl in world.players:
		if not pl.dead and not pl.downed and pl.position.x < position.x + 30:
			pl.hurt(int(data["dmg"]), id, pl.position + Vector2(-10, 0), true)


# --- Daño ------------------------------------------------------------------------------

func take_damage(amount: int, knockv: Vector2, by: Node, crit := false) -> void:
	if dead or invulnerable or (concealed and data["ai"] == "gusano"):
		return
	if concealed and data["ai"] == "mimico":
		concealed = false
	var a := Combat.vs_armor(amount, armor)
	hp -= a
	flash_t = 0.12
	rig_hurt = 0.35
	knock += knockv * knock_res
	if data["ai"] == "pasivo":
		hurt_flee = 2.0
	world.fx.text(center() + Vector2(world.rng.randf_range(-4, 4), -size.y / 2.0 - 6), str(a),
		Color("#fff27a") if crit else Color.WHITE)
	world.fx.burst(center(), Color("#ffffff"), 3)
	Sfx.play("impacto", 0.2, -6.0)
	if hp <= 0.0:
		die(by)


func die(by: Node, silent := false) -> void:
	if dead:
		return
	dead = true
	if not silent:
		world.on_enemy_killed(self, by)
	world.fx.burst(center(), Pix.ramp(data.get("pal", "neutro"), 2) if data.get("pal", "") != "" else Color("#c8c0b0"), 10)


# --- Dibujo -----------------------------------------------------------------------------

## Animación del enemigo por piezas y el punto de la misma según su estado.
func _rig_state(spr: String, base: String) -> Array:
	var name := "idle"
	var tt := -1.0
	var ai: String = data["ai"]
	if rig_hurt > 0.0 and EnemyRig.has_anim(spr, "hurt"):
		name = "hurt"
		tt = EnemyRig.length(spr, "hurt") - rig_hurt
	elif base == "attack" and EnemyRig.has_anim(spr, "attack"):
		name = "attack"
	elif not on_floor and not flying and EnemyRig.has_anim(spr, "jump"):
		var l := EnemyRig.length(spr, "jump")
		if vel.y < 0.0:
			name = "jump"
			tt = (1.0 - clampf(-vel.y / 250.0, 0.0, 1.0)) * l
		else:
			name = "fall"
			tt = clampf(vel.y / 250.0, 0.0, 1.0) * l
	elif land_t > 0.0 and EnemyRig.has_anim(spr, "land"):
		name = "land"
		tt = (0.15 - land_t) * 2.0
	elif base == "move" and not (ai == "saltador" and on_floor):
		name = "move"
	if name != rig_anim:
		rig_anim = name
		rig_t = 0.0
	var l2 := EnemyRig.length(spr, name)
	if tt < 0.0:
		tt = fmod(rig_t, l2) if name in ["idle", "move"] else minf(rig_t, l2)
	return [name, tt]


func _draw_rig(spr: String, base: String, tr: Transform2D, col: Color) -> void:
	var st := _rig_state(spr, base)
	var pal: String = data.get("pal", "")
	for p in EnemyRig.pose(spr, st[0], st[1]):
		var tex: Texture2D = EnemyRig.texture(spr, pal, p["tex"])
		var fw: int = tex.get_width() / p["hframes"]
		var src := Rect2(p["frame"] * fw, 0, fw, tex.get_height())
		draw_set_transform_matrix(tr * (p["tr"] as Transform2D))
		draw_texture_rect_region(tex, Rect2(p["offset"], src.size), src, col)


func _draw() -> void:
	if dead:
		return
	var ai: String = data["ai"]
	var spr: String = data["spr"]
	if spr == "muro":
		_draw_wall()
		return
	if concealed and ai == "gusano":
		if int(anim_t * 8.0) % 2 == 0:
			draw_rect(Rect2(-6, -2, 12, 2), Color("#6a3a5a"))
		return
	var anim := "move" if absf(vel.x) + absf(vel.y) > 8.0 else "idle"
	if flying or data["ai"] in ["saltador", "mimico"]:
		anim = "move" if not concealed else "idle"
	if attacking or state == "windup":
		anim = "attack"
	if ai == "mimico" and concealed:
		draw_texture(Art.chest(false, false), Vector2(-8, -13))
		return
	var fr: Dictionary = Art.enemy_frame(spr, data.get("pal", ""), anim, int(anim_t * (10.0 if anim == "move" else 4.0)))
	var tex: Texture2D = fr["tex"]
	var col := Color.WHITE
	if flash_t > 0.0:
		col = Color(3, 3, 3)
	if state == "windup" and int(anim_t * 20.0) % 2 == 0:
		col = Color(1.8, 1.2, 1.2)
	if ai == "aliado":
		col = col * Color(0.7, 1.2, 0.8)
	var sz := tex.get_size()
	var sc := scale_draw
	var shake_x := sin(anim_t * 60.0) if state == "windup" else 0.0
	# Animación "viva" como en el original: saltitos al andar, respiración en reposo,
	# estiramiento en el aire, aplastamiento al aterrizar o al recibir un golpe.
	var sx := 1.0
	var sy := 1.0
	var oy := 0.0
	var moving := absf(vel.x) > 8.0
	if flying:
		oy = sin(anim_t * 5.0) * 2.5
		sy = 1.0 + sin(anim_t * 10.0) * 0.05
	elif not on_floor:
		sy = 1.0 + clampf(-vel.y / 450.0, -0.22, 0.3)
		sx = 1.0 - (sy - 1.0) * 0.6
	elif moving:
		var ph := anim_t * (14.0 if speed > 60.0 else 10.0)
		oy = -absf(sin(ph)) * (2.0 if spr != "babosa" else 0.0)
		sy = 1.0 + cos(ph * 2.0) * 0.07
		sx = 1.0 - cos(ph * 2.0) * 0.05
	else:
		sy = 1.0 + sin(anim_t * 3.2) * 0.06
		sx = 1.0 - sin(anim_t * 3.2) * 0.04
	if land_t > 0.0:
		sy *= 0.75
		sx *= 1.2
	if state == "windup":
		sy *= 0.85
		sx *= 1.12
	if flash_t > 0.0:
		sy *= 0.85
		sx *= 1.15
	if concealed and ai == "mimico":
		sx = 1.0
		sy = 1.0
		oy = 0.0
	if EnemyRig.has(spr):
		# Por piezas: las animaciones ya llevan el rebote y el aplastamiento.
		_draw_rig(spr, anim, Transform2D(0.0, Vector2(facing * sc, sc), 0.0, Vector2(roundf(shake_x), 0)), col)
	else:
		draw_set_transform(Vector2(shake_x, oy), 0.0, Vector2(facing * sc * sx, sc * sy))
		draw_texture(tex, Vector2(-sz.x / 2.0, -sz.y), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if ai == "jefe_reina":
		for k in 3:
			var p := Vector2(0, -size.y / 2.0) + Vector2(24, 0).rotated(orbit_t * 2.5 + k * TAU / 3.0)
			draw_texture(Art.hazard("carambano", 0), p - Vector2(5, 9))
	if ai == "jefe_ventolin":
		for k in 2:
			var p2 := Vector2(0, -size.y / 2.0) + Vector2(34, 0).rotated(orbit_t * 3.0 + k * PI)
			draw_set_transform(p2, orbit_t * 8.0, Vector2.ONE)
			draw_texture(Art.icon("espada_diamante"), Vector2(-6, -6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not boss and hp < max_hp and ai != "pasivo" and ai != "aliado":
		var w := 14.0
		draw_rect(Rect2(-w / 2.0, -size.y * sc - 6, w, 2), Color(0.1, 0.05, 0.1, 0.8))
		draw_rect(Rect2(-w / 2.0, -size.y * sc - 6, w * hp / max_hp, 2), Color("#e0304a"))


func _draw_wall() -> void:
	var hpx: float = world.map_h_px
	var t := anim_t
	# El muro ocupa toda la altura: carne, costillas y ojos.
	draw_rect(Rect2(-400, -position.y, 430, hpx), Color("#2a0e1e"))
	for y in range(0, int(hpx), 8):
		var wob := sin(y * 0.1 + t * 2.0) * 4.0
		draw_rect(Rect2(20 + wob, y - position.y, 12, 8), Color("#4a1a34"))
		draw_rect(Rect2(28 + wob, y - position.y, 4, 8), Color("#6a2a4a"))
	for k in 5:
		var ey := 40 + k * (hpx - 80) / 4.0 - position.y
		draw_circle(Vector2(26, ey), 9.0, Color("#f4e0d0"))
		draw_circle(Vector2(28 + sin(t + k), ey), 4.0, Color("#e0304a") if flash_t <= 0.0 else Color.WHITE)
		draw_circle(Vector2(29 + sin(t + k), ey), 1.5, Color("#1a0a10"))
