class_name Hero
extends Actor
## Personaje jugable: control fluido (aceleración, coyote, búfer de salto, salto variable,
## doble salto, dash), uso del objeto en la mano, habilidades e interacción.

const ACCEL_GROUND := 1300.0
const ACCEL_AIR := 800.0
const DECEL_GROUND := 1600.0
const JUMP_V := 385.0
const DOUBLE_JUMP_V := 340.0
const COYOTE := 0.1
const BUFFER := 0.12
const DASH_SPEED := 300.0
## Personaje principal por piezas (cabeza, torso, manos y pies) animado con un
## AnimationPlayer. Solo para la raza Minero; el resto usa los sprites de Humanoid.
const RIG_SCENE := preload("res://scenes/pj_rig.tscn")
const RIG_ORDER := ["PieB", "PieF", "ManoB", "Torso", "Cabeza", "ManoF"]

var model: HeroModel
var input := InputState.new()
var peer_id := 1
var is_local := true
var coyote_t := 0.0
var buffer_t := 0.0
var jumps_used := 0
var jump_held := false
var dash_t := 0.0
var dash_dir := 0
var dash_cd := 0.0
var use_cd := 0.0
var attack_t := 0.0
var attack_len := 0.3
var attack_hit := false
var attack_kind := ""
## El golpe en curso es un tajo horizontal de hacha contra un árbol.
var chop := false
var invuln := 0.0
var hurt_t := 0.0
var downed := false
var revive_t := 0.0
var anim_t := 0.0
var run_dist := 0.0
var squash := Vector2.ONE
var triple_next := false
var companion_t := 0.0
var spit_t := 0.0
var rig: Node2D
var rig_ap: AnimationPlayer
var aim_angle := 0.0
var last_hit_by := ""
var pickpocket_cd := 0.0


func _init() -> void:
	size = Vector2(8, 15)


func setup_hero(w: Node, m: HeroModel, pid: int, local: bool) -> void:
	world = w
	model = m
	peer_id = pid
	is_local = local
	net_id = pid
	var l := Art.make_light(Color("#fff4e0"), 140.0 if local else 100.0, 1.8)
	l.position = Vector2(0, -8)
	add_child(l)


# --- Tick -----------------------------------------------------------------------

func tick(dt: float) -> void:
	queue_redraw()
	anim_t += dt
	companion_t += dt
	flash_t = maxf(0.0, flash_t - dt)
	invuln = maxf(0.0, invuln - dt)
	hurt_t = maxf(0.0, hurt_t - dt)
	use_cd = maxf(0.0, use_cd - dt)
	dash_cd = maxf(0.0, dash_cd - dt)
	pickpocket_cd = maxf(0.0, pickpocket_cd - dt)
	squash = squash.lerp(Vector2.ONE, clampf(dt * 12.0, 0.0, 1.0))
	if dead:
		return
	if downed:
		vel.x = move_toward(vel.x, 0.0, DECEL_GROUND * dt)
		physics_move(dt)
		return
	var inp := input
	if inp.hotbar >= 0:
		model.inv.hand = inp.hotbar
	# Efectos de tiempo (hambre, maná...).
	for ev in model.tick(dt, world.is_town):
		match ev:
			"starve":
				hurt(1, "hambre", position, true)
			"drain":
				hurt(1, "mascara", position, true)
			"frost_heal":
				model.heal(1)
	_companion(dt)
	_move(dt, inp)
	_use(dt, inp)
	if inp.skill >= 0 and inp.skill < model.skills.size():
		_skill(model.skills[inp.skill])
	if inp.interact:
		world.interact(self)
	if inp.drop:
		var h = model.inv.held()
		if h != null:
			world.drop_item(model.inv.drop_slot(model.inv.hand), position + Vector2(facing * 12, -10), Vector2(facing * 80, -120))
	var was_floor := on_floor
	var vy_before := vel.y
	physics_move(dt)
	if on_floor and not was_floor:
		jumps_used = 0
		if vy_before > 180.0:
			squash = Vector2(1.08, 0.93)
			world.fx.dust(position, 4)
			Sfx.play("aterrizar", 0.1, -12.0)
	if absf(vel.x) > 5.0 and on_floor:
		run_dist += absf(vel.x) * dt


func _move(dt: float, inp: InputState) -> void:
	var fxs := model.fx()
	var flying: bool = fxs.has("fly") or fxs.has("no_gravity") or model.has_buff("levitar")
	var max_speed := model.move_speed()
	if dash_t > 0.0:
		dash_t -= dt
		vel = Vector2(dash_dir * DASH_SPEED * float(fxs.get("dash_mult", 1.0)) ** 0.5, 0.0)
		use_gravity = false
		if int(dash_t * 60.0) % 3 == 0:
			world.fx.afterimage(self)
		if dash_t <= 0.0:
			use_gravity = true
			vel.x *= 0.5
		return
	use_gravity = not flying
	# Horizontal con aceleración.
	var target := inp.move.x * max_speed
	var accel := ACCEL_GROUND if on_floor else ACCEL_AIR
	if absf(target) < 1.0:
		vel.x = move_toward(vel.x, 0.0, (DECEL_GROUND if on_floor else ACCEL_AIR * 0.6) * dt)
	else:
		vel.x = move_toward(vel.x, target, accel * dt)
		if attack_t <= 0.0:
			facing = 1 if target > 0.0 else -1
	if flying:
		var ty := inp.move.y * max_speed
		if inp.jump:
			ty = -max_speed
		vel.y = move_toward(vel.y, ty, ACCEL_AIR * dt)
		return
	# Salto.
	coyote_t = COYOTE if on_floor else maxf(0.0, coyote_t - dt)
	buffer_t = BUFFER if inp.jump_pressed else maxf(0.0, buffer_t - dt)
	if inp.down_pressed and on_floor and standing_on_oneway():
		drop_t = 0.25
		on_floor = false
	elif buffer_t > 0.0:
		if coyote_t > 0.0:
			_jump(JUMP_V)
			coyote_t = 0.0
		elif _can_air_jump():
			if fxs.has("infinite_jump") or model.use_stamina():
				jumps_used += 1
				_jump(DOUBLE_JUMP_V)
				world.fx.ring(position, Color(1, 1, 1, 0.6))
	jump_held = inp.jump
	# Salto variable: al soltar sube menos; al caer, más gravedad.
	if vel.y < 0.0 and not jump_held:
		gravity_scale = 2.2
	elif vel.y > 0.0:
		gravity_scale = 0.35 if fxs.has("slow_fall") and jump_held else 1.5
	else:
		gravity_scale = 1.0
	# Dash.
	if inp.dash != 0 and dash_cd <= 0.0 and model.use_stamina():
		dash_dir = inp.dash
		facing = dash_dir
		dash_t = (0.16 if not on_floor else 0.12) * sqrt(float(fxs.get("dash_mult", 1.0)))
		dash_cd = 0.2
		invuln = maxf(invuln, dash_t + 0.05)
		Sfx.play("dash", 0.1, -8.0)
		world.fx.dust(position, 3)
		if not on_floor and fxs.has("air_dash_blade"):
			world.spawn_blade(self)


func _can_air_jump() -> bool:
	var fxs := model.fx()
	if fxs.has("infinite_jump"):
		return true
	var extra := 1 + int(fxs.get("extra_jumps", 0))
	return jumps_used < extra


func _jump(v: float) -> void:
	vel.y = -v
	buffer_t = 0.0
	on_floor = false
	squash = Vector2(0.95, 1.05)
	world.fx.dust(position, 3)
	Sfx.play("salto", 0.1, -10.0)


# --- Usar el objeto en la mano ------------------------------------------------------

func _use(dt: float, inp: InputState) -> void:
	aim_angle = (inp.aim - center()).angle()
	if attack_t > 0.0:
		attack_t -= dt
		if not attack_hit and attack_t <= attack_len * 0.55:
			attack_hit = true
			world.melee(self, attack_kind)
	if not inp.use or use_cd > 0.0 or dash_t > 0.0:
		return
	var h = model.inv.held()
	var id: String = "" if h == null else h["id"]
	var it := ItemDB.get_item(id)
	var wc: String = it.get("wclass", "")
	var cat: String = it.get("cat", "")
	if inp.aim.x != center().x:
		facing = 1 if inp.aim.x > center().x else -1
	var speed: float = it.get("speed", 0.3)
	match wc:
		"espada", "granhacha", "hacha", "pico", "red":
			_swing(wc, speed)
		"arco":
			if inp.use_pressed or use_cd <= 0.0:
				_shoot_arrow(it)
				use_cd = speed
		"baston":
			_cast(it.get("spell", "bola_fuego"), float(it.get("mana", 1)))
			use_cd = speed
		"lanzable":
			if inp.use_pressed:
				world.throw_item(self, id, inp.aim)
				model.inv.remove(id, 1)
				use_cd = speed
		_:
			if cat == "consumible" and inp.use_pressed:
				_consume(id)
				use_cd = 0.3
			elif (h == null or cat in ["material", "municion", "equipo"]) and not (cat == "equipo" and inp.use_pressed and _try_equip()):
				var spell: String = model.fx().get("fist_spell", "")
				if spell != "" and h == null:
					_cast(spell, 1.0)
					use_cd = 0.5
				else:
					_swing("puño", 0.28)


func _try_equip() -> bool:
	return model.inv.equip_from(model.inv.hand)


func _swing(kind: String, speed: float) -> void:
	# Con el hacha delante de un árbol se tala con un tajo horizontal; si no, golpe normal.
	chop = false
	if kind in ["hacha", "granhacha"]:
		for n in world.harvest_targets(self):
			if n.kind == "arbol":
				chop = true
	attack_kind = kind
	attack_len = speed
	attack_t = speed
	attack_hit = false
	use_cd = speed + 0.04
	Sfx.play("golpe_aire", 0.15, -10.0)


func _shoot_arrow(it: Dictionary) -> void:
	var no_ammo: bool = it.get("no_ammo", false)
	var arrow := model.inv.best_arrow()
	if arrow == "" and not no_ammo:
		world.fx.text(center() + Vector2(0, -14), "sin flechas", Color("#e0a0a0"))
		use_cd = 0.4
		return
	if not no_ammo:
		model.inv.remove(arrow, 1)
	world.counters_add(self, "arrows", 1)
	var dirs := [0.0]
	if triple_next:
		dirs = [0.0, -0.18, 0.18]
		triple_next = false
	for i in dirs.size():
		var bonus: int = ItemDB.get_item(arrow).get("arrow_bonus", 4) if arrow != "" else 12
		var dmg := Combat.arrow(model, bonus, world.rng, 2.0 if i > 0 else 1.0)
		world.spawn_projectile({"owner": self, "team": "player", "kind": "flecha", "pal": ItemDB.get_item(arrow).get("pal", "laser") if arrow != "" else "laser",
			"pos": center() + Vector2(facing * 6, -2), "vel": Vector2.RIGHT.rotated(aim_angle + dirs[i]) * 340.0,
			"grav": 0.25, "dmg": dmg["amount"], "crit": dmg["crit"], "item": arrow if not no_ammo else "",
			"elem": it.get("elem", ""), "radius": 3.0, "life": 2.0})
	Sfx.play("arco", 0.1, -6.0)


func _cast(spell: String, cost: float) -> void:
	if not model.use_mana(cost):
		world.fx.text(center() + Vector2(0, -14), "sin maná", Color("#8ab0ff"))
		use_cd = 0.3
		return
	var dmg := Combat.spell(model, spell, world.rng)
	var dir := Vector2.RIGHT.rotated(aim_angle)
	match spell:
		"bola_fuego":
			world.spawn_projectile({"owner": self, "team": "player", "kind": "bola_fuego", "pos": center() + dir * 8,
				"vel": dir * 230.0, "dmg": dmg["amount"], "crit": dmg["crit"], "walls": true, "radius": 5.0, "life": 1.6, "elem": "fuego"})
		"rayo":
			world.spawn_projectile({"owner": self, "team": "player", "kind": "rayo", "pos": Vector2(position.x + facing * 26, position.y - 120),
				"vel": Vector2(0, 520), "dmg": dmg["amount"], "crit": dmg["crit"], "walls": true, "pierce": true, "radius": 6.0, "life": 0.5, "elem": "rayo"})
		"escarcha":
			for k in 3:
				world.spawn_projectile({"owner": self, "team": "player", "kind": "escarcha", "orbit": self, "orbit_a": k * TAU / 3.0,
					"pos": center(), "vel": Vector2.ZERO, "dmg": dmg["amount"], "crit": false, "walls": true, "pierce": true,
					"radius": 5.0, "life": 6.0, "elem": "hielo"})
		"meteoro":
			for k in 3:
				world.spawn_projectile({"owner": self, "team": "player", "kind": "meteoro", "pos": center() + Vector2(facing * (10 + k * 14), -60 - k * 10),
					"vel": Vector2(facing * 40, 160), "dmg": dmg["amount"], "crit": false, "walls": true, "radius": 5.0, "life": 1.5, "elem": "veneno"})
		"zombi", "esqueleto":
			world.spawn_ally(self, "zombi_aliado", center() + Vector2(facing * 16, 0), dmg["amount"])
	Sfx.play("magia", 0.1, -6.0)
	world.counters_add(self, "spells", 1)


func _consume(id: String) -> void:
	var it := ItemDB.get_item(id)
	if it.has("food"):
		model.eat(it["food"], world.rng)
		Sfx.play("comer")
	elif it.has("potion"):
		var p: Dictionary = it["potion"]
		if p.get("kind", "") == "misterio":
			var power := int(p.get("power", 1))
			var r = world.rng.randf()
			if r < 0.45:
				model.heal(2 * power + (1 if power > 1 else 0))
				world.fx.text(center() + Vector2(0, -16), "+vida", Color("#f05a6a"))
			elif r < 0.75:
				model.mana = minf(model.max_mana(), model.mana + 3 * power)
				world.fx.text(center() + Vector2(0, -16), "+maná", Color("#4a8af0"))
			else:
				hurt(2 * power, "veneno", position, true)
				world.fx.text(center() + Vector2(0, -16), "¡veneno!", Color("#7ac02a"))
		else:
			if p.has("hp"):
				model.heal(int(p["hp"]))
				world.counters_add(self, "potions_hp", 1)
			if p.has("mp"):
				model.mana = minf(model.max_mana(), model.mana + float(p["mp"]))
		Sfx.play("beber")
		world.fx.sparkle(center(), Color("#ffb0c0"))
	elif it.has("buff"):
		var b: Dictionary = it["buff"]
		for k in ["atk", "mag", "dex"]:
			if b.has(k):
				model.add_buff({"stat": k, "amount": b[k], "t": b["time"]})
		Sfx.play("tambor")
	elif it.has("summon"):
		if world.is_town:
			world.fx.text(center() + Vector2(0, -16), "aquí no", Color.WHITE)
			return
		world.spawn_enemy(it["summon"], center() + Vector2(facing * 90, -30))
	else:
		return
	model.inv.remove(id, 1)


# --- Habilidades -----------------------------------------------------------------------

func _skill(id: String) -> void:
	if model.skill_cd.get(id, 0.0) > 0.0:
		return
	var s := Content.find(Content.SKILLS, id)
	model.skill_cd[id] = float(s["cd"])
	var dur: float = s["dur"]
	Sfx.play("habilidad")
	world.fx.ring(center(), Color("#fff08a"))
	match id:
		"furia", "aura", "levitar":
			model.add_buff({"flag": id, "t": dur})
		"carga":
			world.party_buff({"flag": "carga", "t": dur})
		"rugido":
			world.party_buff({"stat": "dex", "amount": 10, "t": dur})
		"armas_arcanas":
			world.party_buff({"flag": "arcana", "amount": model.stat("mag"), "t": dur})
		"clarividencia":
			model.mana = minf(model.max_mana(), model.mana + 20.0)
		"hoja_caballero", "flecha_druida":
			_jump(DOUBLE_JUMP_V)
			var dmg: int = model.stat("atk") if id == "hoja_caballero" else model.stat("dex")
			world.spawn_projectile({"owner": self, "team": "player", "kind": "hoja_gigante", "pos": position,
				"vel": Vector2(0, 200), "dmg": dmg, "walls": true, "pierce": true, "radius": 9.0, "life": 1.2})
		"hacha_arrojadiza":
			world.spawn_projectile({"owner": self, "team": "player", "kind": "hacha", "pos": center(),
				"vel": Vector2(facing * 260, 0), "dmg": maxi(1, model.stat("atk") / 2), "walls": false, "pierce": true, "radius": 6.0, "life": 1.2})
		"subdito":
			world.spawn_minion(self, input.aim)
		"parpadeo":
			var best := position
			for k in range(8, 72, 4):
				var p := position + Vector2(facing * k, 0)
				var saved := position
				position = p
				var bad := _overlaps_solid()
				position = saved
				if bad:
					break
				best = p
			world.fx.sparkle(center(), Color("#a0c0ff"))
			teleport(best)
		"lobo":
			world.spawn_ally(self, "lobo", position + Vector2(facing * 12, 0), maxi(1, model.stat("dex") / 2), dur)
		"fuego_fatuo":
			world.spawn_wisp(self, input.aim, dur)
		"tiro_triple":
			triple_next = true


func _companion(dt: float) -> void:
	var f := model.fx()
	if f.has("spit_item"):
		spit_t += dt
		if spit_t >= float(f["spit_item"]):
			spit_t = 0.0
			var pool := ["hierba", "seta", "pocion_vida", "carne_cruda", "palo", "piedra", "llave", "bicho_fuego", "flecha_piedra"]
			world.drop_item(Inventory.make(pool[world.rng.randi() % pool.size()], 1), center() + Vector2(-facing * 14, -18), Vector2(0, -60))


# --- Daño y estados -----------------------------------------------------------------

func hurt(amount: int, cause: String, from: Vector2, ignore_invuln := false) -> void:
	if dead or downed or (invuln > 0.0 and not ignore_invuln) or world.god_mode:
		return
	var taken := model.damage(amount)
	world.counters_add(self, "damage_taken", taken)
	last_hit_by = cause
	flash_t = 0.25
	hurt_t = 0.25
	if not ignore_invuln:
		invuln = 1.0
		var dir := signf(position.x - from.x)
		if dir == 0.0:
			dir = -facing
		vel = Vector2(dir * 150.0, -160.0)
	world.fx.text(center() + Vector2(0, -16), "-%d" % taken, Color("#ff5a5a"))
	world.fx.burst(center(), Color("#e0304a"), 6)
	Sfx.play("dolor")
	world.shake(3.0)
	world.hitstop(0.06)
	var f := model.fx()
	if f.has("hit_ingredient") and world.rng.randf() < float(f["hit_ingredient"]):
		var ing: String = ["hierba", "seta", "raiz"][world.rng.randi() % 3]
		world.drop_item(Inventory.make(ing, 1), center(), Vector2(0, -80))
	if f.has("spider_egg") and world.rng.randf() < float(f["spider_egg"]) and not world.is_town:
		world.spawn_enemy("madre_arana", center() + Vector2(0, -60))
	if model.hp <= 0:
		model.hp = 0
		world.on_hero_down(self)


func revive() -> void:
	downed = false
	model.hp = maxi(1, model.max_hp() / 2)
	invuln = 2.0
	world.fx.sparkle(center(), Color("#a0ffa0"))


# --- Dibujo -------------------------------------------------------------------------

func current_anim() -> Array:
	if downed or dead:
		return ["down", 0]
	var race := model.race_id
	if dash_t > 0.0:
		return ["dash", int(anim_t * 12.0)]
	if attack_t > 0.0 and chop:
		return ["idle", 0]
	if attack_t > 0.0:
		var k := 1.0 - attack_t / attack_len
		var n := Art.hero_count(race, "attack")
		return ["attack", clampi(int(k * n), 0, n - 1)]
	if hurt_t > 0.0:
		return ["hurt", 0 if hurt_t > 0.12 else 1]
	if not on_floor and use_gravity:
		if vel.y < 0.0:
			return ["jump", 0 if vel.y < -170.0 else 1]
		return ["fall", 0 if vel.y < 160.0 else 1]
	if absf(vel.x) > 12.0:
		# Una zancada completa cada ~48 px, sea cual sea el número de fotogramas.
		return ["run", int(run_dist / (48.0 / Art.hero_count(race, "run")))]
	return ["idle", int(anim_t * Art.hero_count(race, "idle") / 1.3)]


## Escena de piezas del personaje (se crea al primer uso; null si la raza no la tiene).
func _rig() -> Node2D:
	if model == null or model.race_id != "minero":
		if rig != null:
			rig.queue_free()
			rig = null
		return null
	if rig == null:
		rig = RIG_SCENE.instantiate()
		# Invisible: sus nodos solo guardan la pose; las piezas se dibujan en _draw para
		# conservar el orden con el arma, el sombrero, el destello y el aplastamiento.
		rig.visible = false
		add_child(rig)
		rig_ap = rig.get_node("AnimationPlayer")
		rig_ap.speed_scale = 0.0
		_add_chop_anim()
	return rig


## Tajo horizontal a dos manos: se lleva el hacha atrás a la altura del pecho girando el
## torso, se aguanta un instante y se descarga de lado con todo el cuerpo. Se crea por código
## a partir de la pose de reposo (Torso 0,-2 · Cabeza 0,-8 · manos ±6,-4 · pies ±2,0).
func _add_chop_anim() -> void:
	var lib: AnimationLibrary = rig_ap.get_animation_library(&"")
	if lib == null or lib.has_animation(&"chop"):
		return
	var a := Animation.new()
	a.length = 0.3
	# k (fracción del golpe) = 0, fin de la carga, tensión, impacto, seguimiento, vuelta.
	var times := [0.0, 0.105, 0.13, 0.155, 0.21, 0.3]
	var keys := {
		"Root/ManoF:position": [Vector2(3, -5), Vector2(-5, -7), Vector2(-5, -7), Vector2(7, -6), Vector2(8, -5), Vector2(6, -4)],
		"Root/ManoB:position": [Vector2(-2, -5), Vector2(-7, -6), Vector2(-7, -6), Vector2(4, -6), Vector2(5, -5), Vector2(-6, -4)],
		"Root/Torso:rotation": [0.0, -0.22, -0.24, 0.16, 0.2, 0.0],
		"Root/Cabeza:position": [Vector2(0, -8), Vector2(-1.5, -8), Vector2(-1.5, -8), Vector2(1.5, -7.5), Vector2(1.5, -7.5), Vector2(0, -8)],
		"Root/PieF:position": [Vector2(2, 0), Vector2(3, 0), Vector2(3, 0), Vector2(4, 0), Vector2(4, 0), Vector2(2, 0)],
		"Root/PieB:position": [Vector2(-2, 0), Vector2(-3, 0), Vector2(-3, 0), Vector2(-3, 0), Vector2(-3, 0), Vector2(-2, 0)],
		"Root:position": [Vector2.ZERO, Vector2(-1, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(1, 0), Vector2.ZERO],
	}
	# Pistas fijas: el resto de piezas en su pose de reposo (si no, heredarían la última
	# animación que se reprodujo).
	var fixed := {"Root:rotation": 0.0, "Root:scale": Vector2.ONE, "Root/Torso:position": Vector2(0, -2),
		"Root/Cabeza:rotation": 0.0, "Root/ManoF:rotation": 0.0, "Root/ManoB:rotation": 0.0,
		"Root/PieF:rotation": 0.0, "Root/PieB:rotation": 0.0}
	for path in keys:
		var tr := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(tr, NodePath(path))
		a.track_set_interpolation_type(tr, Animation.INTERPOLATION_CUBIC)
		for i in times.size():
			a.track_insert_key(tr, times[i], keys[path][i])
	for path in fixed:
		var tr2 := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(tr2, NodePath(path))
		a.track_insert_key(tr2, 0.0, fixed[path])
	lib.add_animation(&"chop", a)


## Animación del esqueleto y el punto de la misma según el estado del héroe.
func rig_state() -> Array:
	if downed or dead:
		return ["down", 0.0]
	if dash_t > 0.0:
		return ["dash", fmod(anim_t, 0.2)]
	if attack_t > 0.0:
		return ["chop" if chop else "attack", (1.0 - attack_t / attack_len) * 0.3]
	if hurt_t > 0.0:
		return ["hurt", clampf(0.25 - hurt_t, 0.0, 0.25)]
	if not on_floor and use_gravity:
		if vel.y < 0.0:
			# Del despegue (estirado) a la cima (recogido) según lo que queda de subida.
			return ["jump", (1.0 - clampf(-vel.y / JUMP_V, 0.0, 1.0)) * 0.4]
		return ["fall", clampf(vel.y / 400.0, 0.0, 1.0) * 0.4]
	if absf(vel.x) > 12.0:
		# Una zancada completa cada ~48 px.
		return ["run", fmod(run_dist / 44.0, 1.0) * 0.56]
	return ["idle", fmod(anim_t, 2.0)]


## Transformación de una pieza respecto a los pies del héroe.
func _rig_tr(part: String) -> Transform2D:
	var root: Node2D = rig.get_node("Root")
	return RigPose.pixel_tr(root.transform * (root.get_node(part) as Node2D).transform)


## `sq` aplasta o estira moviendo las piezas, sin deformar sus píxeles.
func _draw_rig(base_tr: Transform2D, col: Color, sq := Vector2.ONE) -> void:
	var st := rig_state()
	if rig_ap.current_animation != st[0]:
		rig_ap.play(st[0])
	rig_ap.seek(st[1], true)
	var root: Node2D = rig.get_node("Root")
	for n in RIG_ORDER:
		var s: Sprite2D = root.get_node(n)
		var t := RigPose.pixel_tr(root.transform * s.transform)
		t.origin = (t.origin * sq).round()
		t = base_tr * t
		draw_set_transform_matrix(t)
		draw_texture(s.texture, s.offset, col)
	draw_set_transform_matrix(base_tr)


func _draw() -> void:
	if dead:
		return
	if invuln > 0.0 and not downed and int(invuln * 20.0) % 2 == 0 and dash_t <= 0.0:
		return
	var rg := _rig()
	var a := current_anim()
	var fr: Dictionary = Art.hero_frame(model.race_id, a[0], a[1])
	var tex: Texture2D = fr["tex"]
	var col := Color.WHITE
	if flash_t > 0.0:
		col = Color(2.5, 2.5, 2.5)
	if downed:
		if rg:
			_draw_rig(Transform2D(-PI / 2.0 * facing, Vector2.ONE, 0.0, Vector2(0, -4)) * Transform2D(0.0, Vector2(facing, 1), 0.0, Vector2(0, 7)), Color(1, 1, 1, 0.8))
		else:
			draw_set_transform(Vector2(0, -4), -PI / 2.0 * facing, Vector2.ONE)
			var og0: Vector2 = Vector2(fr["origin"])
			draw_texture(tex, -og0 + Vector2(0, 9), Color(1, 1, 1, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var sc := Vector2(squash.x * facing, squash.y)
	# Saltitos al correr y respiración en reposo (el esqueleto ya los lleva en sus animaciones).
	var bob := 0.0
	if rg == null:
		if a[0] == "run":
			var ph := run_dist / 7.0 * PI / 3.0
			bob = -absf(sin(ph)) * 1.5
			sc.y *= 1.0 + cos(ph * 2.0) * 0.05
		elif a[0] == "idle":
			sc.y *= 1.0 + sin(anim_t * 3.0) * 0.04
		elif a[0] == "jump" or a[0] == "fall":
			sc.y *= 1.0 + clampf(-vel.y / 500.0, -0.15, 0.18)
			sc.x *= 1.0 - clampf(-vel.y / 500.0, -0.15, 0.18) * 0.5
	var base := Vector2(0, bob)
	draw_set_transform(base, 0.0, sc)
	# Brillo de habilidades activas.
	if model.has_buff("furia"):
		draw_rect(Rect2(-6, -17, 12, 17), Color(1, 0.2, 0.1, 0.18 + 0.1 * sin(anim_t * 10.0)))
	var og: Vector2 = Vector2(fr["origin"])
	var pose := _held_pose(rg, fr, og)
	# Durante la carga del tajo el hacha queda detrás del cuerpo.
	if pose.get("behind", false):
		_draw_held(pose, base, sc, Color(col.r * 0.72, col.g * 0.72, col.b * 0.72, col.a))
	if rg:
		_draw_rig(Transform2D(0.0, Vector2(facing, 1), 0.0, base), col, squash)
	else:
		draw_texture(tex, -og, col)
	# Sombrero.
	var hat = Art.hat(model.hat_id)
	if hat:
		var hd: Vector2 = (_rig_tr("Cabeza") * Vector2(0, -8)).round() if rg else Vector2(fr["head"]) - og
		draw_texture(hat, hd + Vector2(-6, -10), col)
	if not pose.is_empty() and not pose.get("behind", false):
		_draw_held(pose, base, sc, col)
	_draw_trail(pose, base, sc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Compañero.
	var cp = Art.companion(model.companion_id, int(companion_t * 6.0))
	if cp:
		var off := Vector2(-facing * 12.0, -24.0 + sin(companion_t * 3.0) * 3.0)
		draw_texture(cp, off - Vector2(6, 6))
	# El nombre (cooperativo) y el "¡Ayuda!" los dibuja GameUI en alta resolución.


# --- Arma en la mano y golpes --------------------------------------------------------------

## Fracción (0-1) de k dentro del tramo [a, b].
static func _seg(k: float, a: float, b: float) -> float:
	return clampf((k - a) / (b - a), 0.0, 1.0)


## Giro del hacha alrededor del eje vertical en el tajo horizontal: 0 = hacia delante,
## PI = detrás del cuerpo. Carga, tensión, descarga rápida y seguimiento.
static func _chop_turn(k: float) -> float:
	if k < 0.35:
		return lerpf(0.35, 2.9, ease(_seg(k, 0.0, 0.35), 0.4))
	if k < 0.45:
		return lerpf(2.9, 3.0, _seg(k, 0.35, 0.45))
	if k < 0.56:
		return lerpf(3.0, 0.0, ease(_seg(k, 0.45, 0.56), 2.2))
	return 0.0


## Inclinación del hacha en el tajo: sube un poco al cargar y baja al golpear.
static func _chop_tilt(k: float) -> float:
	if k < 0.45:
		return -0.3 * _seg(k, 0.0, 0.35)
	if k < 0.56:
		return lerpf(-0.3, 0.12, _seg(k, 0.45, 0.56))
	return lerpf(0.12, 0.0, _seg(k, 0.56, 1.0))


## Desplazamiento de la mano en el tajo para las razas sin esqueleto por piezas.
static func _chop_hand_x(k: float) -> float:
	if k < 0.45:
		return lerpf(0.0, -8.0, ease(_seg(k, 0.0, 0.35), 0.4))
	if k < 0.56:
		return lerpf(-8.0, 4.0, _seg(k, 0.45, 0.56))
	return lerpf(4.0, 0.0, _seg(k, 0.56, 1.0))


## Rotación del arma en los golpes normales, con anticipación, descarga y seguimiento
## propios de cada arma (el daño llega hacia k = 0,45).
static func _swing_rot(wc: String, k: float) -> float:
	match wc:
		"espada", "hacha", "granhacha":
			if k < 0.25:
				return lerpf(-1.1, -2.3, ease(_seg(k, 0.0, 0.25), 0.5))
			if k < 0.5:
				return lerpf(-2.3, 1.7, ease(_seg(k, 0.25, 0.5), -2.0))
			return lerpf(1.7, 1.2, _seg(k, 0.5, 1.0))
		"pico":
			# Se levanta bien alto, se aguanta y cae de golpe sobre la roca.
			if k < 0.4:
				return lerpf(-0.6, -2.6, ease(_seg(k, 0.0, 0.4), 0.5))
			if k < 0.55:
				return lerpf(-2.6, 1.3, ease(_seg(k, 0.4, 0.55), 2.0))
			return lerpf(1.3, 1.0, _seg(k, 0.55, 1.0))
		"red":
			return lerpf(-1.8, 1.4, smoothstep(0.0, 1.0, k))
	return lerpf(-1.5, 1.9, ease(k, 0.5))


## Postura del objeto en la mano, calculada mirando a la derecha (luego se voltea con
## `facing`). Vacío si no hay nada que dibujar.
func _held_pose(rg: Node2D, fr: Dictionary, og: Vector2) -> Dictionary:
	var h = model.inv.held()
	if not is_local and has_meta("held"):
		var mh: String = get_meta("held")
		h = null if mh == "" else {"id": mh, "n": 1}
	if h == null or ItemDB.get_item(h["id"]).get("slot", "") != "":
		return {}
	var hp: Vector2 = _rig_tr("ManoF").origin.round() if rg else Vector2(fr["hand"]) - og
	var wc: String = ItemDB.get_item(h["id"]).get("wclass", "")
	var rot := 0.0
	var sx := 1.0
	if attack_t > 0.0:
		var k := 1.0 - attack_t / attack_len
		if chop:
			# El hacha apunta de lado (PI/4 la pone horizontal) y "gira" alrededor del eje
			# vertical: en vista lateral eso es escalar en X, que es lo que hace que el tajo
			# se lea horizontal.
			rot = PI / 4.0 + _chop_tilt(k)
			sx = cos(_chop_turn(k))
			if rg == null:
				hp += Vector2(_chop_hand_x(k), 1)
		else:
			rot = _swing_rot(wc, k)
	elif wc == "arco" or wc == "baston":
		var ang := aim_angle if facing > 0 else PI - aim_angle
		rot = wrapf(ang + PI / 4.0, -PI, PI)
	elif not on_floor:
		rot = -0.4
	return {"id": h["id"], "hand": hp, "rot": rot, "sx": sx, "behind": sx < 0.0, "wc": wc}


func _draw_held(pose: Dictionary, base: Vector2, sc: Vector2, col: Color) -> void:
	var hp: Vector2 = pose["hand"]
	var tr := Transform2D(0.0, sc, 0.0, base) * Transform2D(Vector2(pose["sx"], 0), Vector2(0, 1), hp) * Transform2D(pose["rot"], Vector2.ZERO)
	draw_set_transform_matrix(tr)
	draw_texture(Art.icon(pose["id"]), Vector2(-2, -10), col)
	draw_set_transform(base, 0.0, sc)


## Estela del golpe: rayas horizontales en el tajo; arco que sigue al arma en el resto.
func _draw_trail(pose: Dictionary, base: Vector2, sc: Vector2) -> void:
	if attack_t <= 0.0 or attack_kind == "puño" or pose.is_empty():
		return
	var k := 1.0 - attack_t / attack_len
	var hp: Vector2 = pose["hand"]
	draw_set_transform(base, 0.0, sc)
	if chop:
		var s := _seg(k, 0.44, 0.66)
		if s <= 0.0 or s >= 1.0:
			return
		var head_x := hp.x + 11.0 * cos(_chop_turn(k))
		for i in 3:
			var y := hp.y - 1.0 + (i - 1) * 2.0
			var a := (1.0 - s) * (0.75 - i * 0.2)
			draw_line(Vector2(hp.x - 13.0 + i * 3.0, y), Vector2(head_x, y), Color(1, 1, 0.88, a), 1.0)
		return
	var wc: String = pose["wc"]
	var a_now := _swing_rot(wc, k) - PI / 4.0
	var a_prev := _swing_rot(wc, maxf(0.0, k - 0.16)) - PI / 4.0
	if absf(a_now - a_prev) < 0.35:
		return
	var fade := clampf(absf(a_now - a_prev) / 2.0, 0.3, 1.0)
	draw_arc(hp, 13.0, minf(a_prev, a_now), maxf(a_prev, a_now), 12, Color(1, 1, 1, 0.7 * fade), 2.0)
	draw_arc(hp, 10.0, minf(a_prev, a_now), maxf(a_prev, a_now), 10, Color(1, 1, 0.8, 0.35 * fade), 1.0)
