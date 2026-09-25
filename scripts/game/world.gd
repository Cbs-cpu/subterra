class_name World
extends Node2D
## Un distrito o un pueblo en marcha: tiles, entidades, reglas y cámara.

const T := 16
const GUARDIAN_TIME := 300.0
const LOOT_COMMON := ["pocion_vida", "pocion_mana", "flecha_piedra", "carne_asada", "hierba", "seta", "telarana",
	"piel", "pellejo", "carbon", "llave", "bicho_fuego", "bicho_hielo", "bicho_rayo"]
const LOOT_GOLD := ["anillo_poder", "anillo_sabiduria", "anillo_naturaleza", "anillo_vida", "anillo_arquero",
	"anillo_equilibrio", "anillo_furia", "anillo_locura", "katana_esmeralda", "espada_obsidiana", "portaluz",
	"arco_fuego", "mandoble", "escudo_escama", "pocion_vida_g", "pocion_mana_g", "baston_zombi"]

var run: Node
var map := {}
var tiles := PackedByteArray()
var mw := 0
var mh := 0
var map_w_px := 0.0
var map_h_px := 0.0
var biome := "bosque"
var district := 1
var is_town := false
var rng := RandomNumberGenerator.new()
var god_mode := false

var players: Array = []
var enemies: Array = []
var projectiles: Array = []
var pickups: Array = []
var nodes: Array = []
var hazards: Array = []
var npcs: Array = []
var summons: Array = []

var layer_back: Node2D
var layer_mid: Node2D
var layer_actors: Node2D
var layer_front: Node2D
var fx: Fx
var camera: Camera2D
var bg_mat: ShaderMaterial
var tile_rect: ColorRect
var time_in := 0.0
var guardian_next := GUARDIAN_TIME
var guardian_warned := false
var hitstop_t := 0.0
var shake_amt := 0.0
var eggs_broken := 0
var next_net_id := 1000
var boss_node: Node = null
var cam_target: Node = null
var paused := false
var sprite_layer: CanvasLayer
var light_root: Node2D
var lights: Array = []          # [{light, target, offset}]


func setup(r: Node, m: Dictionary, seed_value: int) -> void:
	run = r
	map = m
	rng.seed = seed_value
	tiles = m["tiles"]
	mw = m["w"]
	mh = m["h"]
	map_w_px = mw * T
	map_h_px = mh * T
	biome = m["biome"]
	district = m.get("district", 1)
	is_town = m.get("town", false)
	_build_view()
	for e in m["entities"]:
		_spawn_from_data(e)
	if is_town:
		var lamp_xs := []
		for x in range(6, mw - 4, 10):
			var lamp := Art.make_light(Color("#ffd28a"), 110.0, 1.4)
			lamp.position = Vector2(x * T + 8, 15 * T - 36)
			light_root.add_child(lamp)
			lamp_xs.append(x * T + 8)
		# Casas, farolas, banderines y detalles del pueblo, detrás de todo lo demás.
		var deco := TownDecor.new()
		deco.setup(self, 15 * T, map_w_px, lamp_xs)
		layer_back.add_child(deco)
		layer_back.move_child(deco, 0)
	for d in m.get("doors", []):
		var n := Npc.new()
		n.setup(self, {"kind": "puerta", "biome": d["biome"], "pos": d["pos"]})
		_add_npc(n)
	if m.get("biome", "") == "nido" and m.get("boss", {}).has("id"):
		boss_node = spawn_enemy("muro_ceniza", Vector2(-20, map_h_px - 16))
	Music.play_biome("pueblo" if is_town else biome)


func _build_view() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var bg := ColorRect.new()
	bg.size = Vector2(Run.WORLD_RES)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = preload("res://shaders/background.gdshader")
	bg_mat.set_shader_parameter("screen", Vector2(Run.WORLD_RES))
	BiomeLook.apply_bg(bg_mat, "pueblo" if is_town else biome)
	bg.material = bg_mat
	bg_layer.add_child(bg)
	tile_rect = ColorRect.new()
	tile_rect.size = Vector2(map_w_px, map_h_px)
	tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/tiles.gdshader")
	var img := Image.create_from_data(mw, mh, false, Image.FORMAT_R8, tiles)
	mat.set_shader_parameter("data", ImageTexture.create_from_image(img))
	mat.set_shader_parameter("map_size", Vector2(mw, mh))
	BiomeLook.apply_tiles(mat, biome)
	tile_rect.material = mat
	# Como en el original: la penumbra solo afecta al terreno y al fondo; los sprites se ven
	# siempre con sus colores. Las entidades van en una capa aparte que sigue a la cámara y sus
	# luces se trasladan a la capa del terreno (ver _adopt_lights).
	add_child(tile_rect)
	light_root = Node2D.new()
	add_child(light_root)
	sprite_layer = CanvasLayer.new()
	sprite_layer.layer = 1
	sprite_layer.follow_viewport_enabled = true
	add_child(sprite_layer)
	layer_back = Node2D.new()
	layer_mid = Node2D.new()
	layer_actors = Node2D.new()
	layer_front = Node2D.new()
	for l in [layer_back, layer_mid, layer_actors, layer_front]:
		sprite_layer.add_child(l)
		l.child_entered_tree.connect(func(n): _adopt_lights.call_deferred(n))
	fx = Fx.new()
	sprite_layer.add_child(fx)
	var ff := Fireflies.new()
	ff.world = self
	sprite_layer.add_child(ff)
	sprite_layer.move_child(ff, 0)
	# Resplandor suave en lo brillante (hojas, luces), como el halo del original.
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.55
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.8)
	env.set_glow_level(3, 0.4)
	we.environment = env
	add_child(we)
	var cm := CanvasModulate.new()
	cm.color = BiomeLook.ambient("pueblo" if is_town else biome)
	add_child(cm)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(map_w_px)
	camera.limit_bottom = int(map_h_px)
	add_child(camera)
	camera.make_current()


## Mueve las luces hijas de una entidad a la capa del terreno y las hace seguirla.
func _adopt_lights(n: Node) -> void:
	if not is_instance_valid(n):
		return
	for ch in n.get_children():
		if ch is PointLight2D:
			var off: Vector2 = ch.position
			n.remove_child(ch)
			light_root.add_child(ch)
			ch.global_position = n.global_position + off
			lights.append({"light": ch, "target": n, "offset": off})


func _process(_dt: float) -> void:
	for i in range(lights.size() - 1, -1, -1):
		var e: Dictionary = lights[i]
		var tg = e["target"]
		var l: PointLight2D = e["light"]
		if not is_instance_valid(tg) or tg.get("dead") == true or not tg.visible:
			l.queue_free()
			lights.remove_at(i)
			continue
		l.global_position = tg.global_position + e["offset"]


func _nid() -> int:
	next_net_id += 1
	return next_net_id


func _spawn_from_data(e: Dictionary) -> void:
	match e["kind"]:
		"planta":
			# Los árboles altos de fondo también se talan: son árboles con el dibujo de planta.
			var tp := WorldNode.new()
			var d2 := e.duplicate()
			d2["kind"] = "arbol"
			d2["plant_h"] = e.get("h", 60)
			tp.setup(self, d2)
			tp.net_id = _nid()
			nodes.append(tp)
			layer_back.add_child(tp)
			layer_back.move_child(tp, 0)
		"enredadera":
			var dn := Deco.new()
			dn.setup(self, e)
			layer_back.add_child(dn)
			layer_back.move_child(dn, 0)
		"arbol", "roca", "hierba", "luz_bicho", "cofre", "colmena", "huevo_arana":
			var n := WorldNode.new()
			n.setup(self, e)
			n.net_id = _nid()
			nodes.append(n)
			layer_back.add_child(n)
		"enemigo":
			var en := spawn_enemy(e["id"], e["pos"])
			if en.boss:
				boss_node = en
		"trampa":
			var h := Hazard.new()
			h.setup(self, e)
			h.net_id = _nid()
			hazards.append(h)
			layer_mid.add_child(h)
		"npc", "altar", "vecino":
			var d := e.duplicate()
			if e["kind"] == "vecino":
				d["npc"] = "vecino"
			var np := Npc.new()
			np.setup(self, d)
			_add_npc(np)


func _add_npc(n: Npc) -> void:
	n.net_id = _nid()
	npcs.append(n)
	layer_back.add_child(n)


func add_hero(h: Hero, at: Vector2) -> void:
	players.append(h)
	layer_actors.add_child(h)
	h.teleport(at)
	h.unstuck()
	if h.is_local:
		cam_target = h
		camera.position = h.center()
		camera.reset_smoothing()


# --- Consultas de mapa -------------------------------------------------------------

func tile(x: int, y: int) -> int:
	if x < 0 or x >= mw:
		return 1
	if y < 0:
		return 1 if not is_town else 0
	if y >= mh:
		return 1
	return tiles[y * mw + x]


func solid_at(p: Vector2) -> bool:
	return tile(floori(p.x / T), floori(p.y / T)) == 1


# --- Bucle ---------------------------------------------------------------------------

func _physics_process(dt: float) -> void:
	bg_mat.set_shader_parameter("time", time_in)
	if paused:
		return
	if Net.is_client():
		Net.apply_snapshot(self, dt)
		fx.tick(dt)
		_update_camera(dt)
		Net.after_tick(self)
		return
	if hitstop_t > 0.0:
		hitstop_t -= dt
		return
	time_in += dt
	run.gather_inputs(self)
	for p in players:
		p.tick(dt)
	for list in [enemies, projectiles, pickups, nodes, hazards, npcs, summons]:
		for e in list:
			if not e.dead:
				e.tick(dt)
	fx.tick(dt)
	_cleanup()
	if not is_town and biome != "nido":
		_guardians(dt)
	if is_town:
		for p in players:
			if not p.dead and p.position.x > map_w_px - 20.0:
				run.leave_town()
				return
	_update_camera(dt)
	run.after_world_tick(self)


func _cleanup() -> void:
	for list in [enemies, projectiles, pickups, nodes, hazards, summons]:
		var i: int = list.size() - 1
		while i >= 0:
			var e = list[i]
			if e.dead:
				list.remove_at(i)
				e.queue_free()
			i -= 1


func _update_camera(dt: float) -> void:
	if cam_target == null or not is_instance_valid(cam_target):
		return
	# Como en el original: el ratón desplaza la cámara hacia donde apuntas (mirar arriba/abajo
	# para ver amenazas), con un seguimiento suave que acelera si el jugador se aleja.
	var look := Vector2.ZERO
	if cam_target.is_local:
		var m := get_viewport().get_mouse_position() - Vector2(Run.WORLD_RES) / 2.0
		look = Vector2(m.x * 0.45, m.y * 0.6).limit_length(80.0)
	var want: Vector2 = cam_target.center() + look + Vector2(0, -10)
	var dist := camera.position.distance_to(want)
	var k := clampf(dt * (4.5 + dist * 0.02), 0.0, 1.0)
	camera.position = camera.position.lerp(want, k)
	shake_amt = maxf(0.0, shake_amt - dt * 18.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt if shake_amt > 0.2 else Vector2.ZERO
	bg_mat.set_shader_parameter("cam", camera.get_screen_center_position())


func mouse_world() -> Vector2:
	return get_global_mouse_position()


func shake(a: float) -> void:
	if Game.settings["shake"]:
		shake_amt = maxf(shake_amt, a)


func hitstop(t: float) -> void:
	hitstop_t = maxf(hitstop_t, t)


# --- Guardianes de Ceniza -------------------------------------------------------------

func _guardians(_dt: float) -> void:
	var limit := GUARDIAN_TIME * (0.6 if run.madman else 1.0)
	if not guardian_warned and time_in > limit - 30.0:
		guardian_warned = true
		run.notify("¡La Ceniza se acerca! Busca la salida.", Color("#ff5a7a"))
		Sfx.play("alarma")
	if time_in >= limit and time_in >= guardian_next - (GUARDIAN_TIME - limit):
		guardian_next = time_in + 20.0 + (GUARDIAN_TIME - limit)
		var n := 5 if enemies.filter(func(e): return e.id == "guardian").is_empty() else 2
		for k in n:
			spawn_enemy("guardian", map["spawn"] + Vector2(k * 10 - 20, -30 - k * 6))
		shake(5.0)
		Sfx.play("guardianes")


func time_left() -> float:
	if is_town or biome == "nido":
		return -1.0
	return GUARDIAN_TIME * (0.6 if run.madman else 1.0) - time_in


# --- Creación de entidades ------------------------------------------------------------

func spawn_enemy(id: String, pos: Vector2) -> Enemy:
	var e := Enemy.new()
	e.position = pos
	e.setup_enemy(self, id, district, run.madman)
	e.net_id = _nid()
	enemies.append(e)
	layer_actors.add_child(e)
	if not e.flying:
		e.unstuck()
	if e.boss and id != "guardian":
		boss_node = e
		if time_in > 1.0:
			run.notify("¡" + Content.enemy(id)["name"] + "!", Color("#ff9a5a"))
			Sfx.play("jefe_aviso")
	return e


func spawn_ally(hero: Node, id: String, pos: Vector2, dmg: int, life: float = 20.0) -> void:
	var e := spawn_enemy(id, pos)
	e.owner_hero = hero
	e.ally_dmg = dmg
	e.life = life
	e.dmg = 0


func spawn_projectile(d: Dictionary) -> Projectile:
	var p := Projectile.new()
	p.setup(self, d)
	p.net_id = _nid()
	projectiles.append(p)
	layer_front.add_child(p)
	return p


func spawn_minion(hero: Node, at: Vector2) -> void:
	var s := Summon.new()
	s.world = self
	s.kind = "subdito"
	s.owner_hero = hero
	s.position = at
	s.life = 7.0
	s.dmg = hero.model.stat("mag")
	_add_summon(s)


func spawn_wisp(hero: Node, at: Vector2, dur: float) -> void:
	var s := Summon.new()
	s.world = self
	s.kind = "fatuo"
	s.owner_hero = hero
	s.position = at
	s.life = dur
	_add_summon(s)


func spawn_blade(hero: Node) -> void:
	var s := Summon.new()
	s.world = self
	s.kind = "cuchilla"
	s.owner_hero = hero
	s.position = hero.center()
	s.life = 1.0
	s.dmg = maxi(1, hero.model.stat("atk") / 2)
	_add_summon(s)


func poison_cloud(pos: Vector2, dmg: int, team: String) -> void:
	var s := Summon.new()
	s.world = self
	s.kind = "nube"
	s.position = pos
	s.life = 3.0
	s.dmg = maxi(1, dmg / 4)
	s.team = team
	_add_summon(s)


func _add_summon(s: Summon) -> void:
	s.net_id = _nid()
	summons.append(s)
	layer_front.add_child(s)


func drop_item(stack, pos: Vector2, v: Vector2 = Vector2.ZERO, no_magnet := false) -> void:
	if stack == null:
		return
	var p := Pickup.new()
	p.world = self
	p.kind = "item"
	p.stack = stack
	p.position = pos
	p.vel = v if v != Vector2.ZERO else Vector2(rng.randf_range(-50, 50), -110)
	p.no_magnet = no_magnet
	p.net_id = _nid()
	pickups.append(p)
	layer_mid.add_child(p)


func drop_coins(total: int, pos: Vector2) -> void:
	while total > 0:
		var v := mini(total, 5 if total > 20 else 1)
		total -= v
		var p := Pickup.new()
		p.world = self
		p.kind = "coin"
		p.value = v
		p.position = pos
		p.vel = Vector2(rng.randf_range(-70, 70), rng.randf_range(-170, -90))
		p.net_id = _nid()
		pickups.append(p)
		layer_mid.add_child(p)


func drop_xp(total: int, pos: Vector2) -> void:
	var n := clampi(total / 4, 1, 8)
	for k in n:
		var p := Pickup.new()
		p.world = self
		p.kind = "xp"
		p.value = maxi(1, total / n)
		p.position = pos
		p.vel = Vector2(rng.randf_range(-60, 60), rng.randf_range(-150, -80))
		p.pickup_delay = 0.25
		p.net_id = _nid()
		pickups.append(p)
		layer_mid.add_child(p)


func throw_item(hero: Node, id: String, aim: Vector2) -> void:
	var it := ItemDB.get_item(id)
	var dir: Vector2 = (aim - hero.center()).normalized()
	spawn_projectile({"owner": hero, "team": "player", "kind": "vial" if id == "vial_veneno" else "esquirla_ceniza",
		"pos": hero.center(), "vel": dir * 260.0 + Vector2(0, -60), "grav": 0.6, "dmg": int(it.get("throw_damage", 10)),
		"radius": 5.0, "life": 2.5})


# --- Combate ---------------------------------------------------------------------------

func melee(hero: Hero, kind: String) -> void:
	var reach := {"espada": 22.0, "granhacha": 27.0, "hacha": 18.0, "pico": 18.0, "red": 20.0, "puño": 13.0}.get(kind, 16.0)
	var h = hero.model.inv.held()
	var it := ItemDB.get_item(h["id"]) if h != null else {}
	reach *= float(it.get("reach", 1.0))
	var c := hero.center()
	var r := Rect2(c.x if hero.facing > 0 else c.x - reach, c.y - 15, reach, 28)
	var ctx := {"furia": hero.model.has_buff("furia")}
	for b in hero.model.buffs:
		if b.get("flag", "") == "arcana":
			ctx["arcana_bonus"] = b["amount"]
	var hit_any := false
	for e in enemies:
		if e.dead or e.invulnerable or e.data["ai"] == "aliado":
			continue
		if r.intersects(e.rect()):
			var dmg := Combat.melee(hero.model, rng, ctx)
			var amount: int = dmg["amount"]
			if hero.model.fx().has("viking") and rng.randf() < 0.1:
				amount *= 2
				fx.text(e.center() + Vector2(0, -20), "¡hacha vikinga!", Color("#e0e0ff"))
			e.take_damage(amount, Vector2(hero.facing * 150.0, -90.0), hero, dmg["crit"])
			var el: String = it.get("elem", "")
			if el == "fuego":
				e.take_damage(maxi(1, amount / 4), Vector2.ZERO, hero)
			elif el == "hielo":
				e.vel.x *= 0.2
			elif el == "rayo":
				for e2 in enemies:
					if e2 != e and not e2.dead and not e2.invulnerable and e2.center().distance_to(e.center()) < 60.0:
						e2.take_damage(maxi(1, amount / 2), Vector2.ZERO, hero)
						break
			hit_any = true
	if hit_any:
		hitstop(0.035)
		shake(1.2)
		if kind in ["espada", "granhacha", "hacha", "pico"]:
			hero.model.inv.wear(hero.model.inv.hand)
	var tier: int = it.get("tier", 0)
	var tool: String = it.get("tool", kind if kind == "puño" else it.get("wclass", "puño"))
	for n in nodes:
		if n.dead or not r.intersects(n.rect()):
			continue
		if n.kind == "cofre":
			continue
		if n.hit_by(hero, tool, tier):
			var save_key := "axe_save" if tool == "hacha" else ("pick_save" if tool == "pico" else "")
			if tool in ["hacha", "pico", "red"] and n.kind != "hierba":
				if save_key == "" or rng.randf() >= float(hero.model.fx().get(save_key, 0.0)):
					hero.model.inv.wear(hero.model.inv.hand)
			break


func enemy_melee(e: Enemy, r: Rect2) -> void:
	for p in players:
		if not p.dead and not p.downed and r.intersects(p.rect()):
			p.hurt(e.dmg, e.id, e.center())
	fx.burst(r.get_center(), Color(1, 1, 1, 0.6), 3)


func party_buff(b: Dictionary) -> void:
	for p in players:
		if not p.dead:
			p.model.add_buff(b.duplicate())


func give_xp(hero: Node, n: int) -> void:
	var ups: int = hero.model.gain_xp(n, rng)
	if ups > 0:
		fx.text(hero.center() + Vector2(0, -24), "¡nivel %d!" % hero.model.level, Color("#8aff9a"))
		fx.sparkle(hero.center(), Color("#8aff9a"))
		Sfx.play("nivel")
		run.counters_max(hero, "level", hero.model.level)
		if hero.model.pending_skill_offers > 0:
			run.offer_skill(hero)


func on_pickup(hero: Node, stack: Dictionary) -> void:
	run.on_pickup(hero, stack)


func counters_add(hero: Node, key: String, n: int) -> void:
	run.counters_add(hero, key, n)


func on_enemy_killed(e: Enemy, by: Node) -> void:
	var d: Dictionary = e.data
	if d["ai"] == "aliado":
		return
	var coins: Array = d["coins"]
	var c := rng.randi_range(coins[0], coins[1])
	if c > 0:
		drop_coins(c, e.center())
	if int(d["xp"]) > 0:
		drop_xp(int(d["xp"]), e.center())
	for dr in d["drops"]:
		if rng.randf() < float(dr[1]):
			drop_item(Inventory.make(dr[0], 1), e.center())
	run.on_enemy_killed(e, by, biome)
	if e.boss:
		shake(8.0)
		hitstop(0.25)
		fx.explosion(e.center(), 30.0)
		Sfx.play("jefe_muere")
		if e == boss_node:
			boss_node = null
		if e.id == "muro_ceniza":
			run.win()
	else:
		Sfx.play("muerte_enemigo", 0.2, -6.0)


func egg_broken(pos: Vector2) -> void:
	eggs_broken += 1
	if eggs_broken % 3 == 0:
		spawn_enemy("madre_arana", pos + Vector2(0, -40))


func open_chest(n: WorldNode, hero: Node) -> void:
	var tier := clampi(district / 4, 0, 4)
	drop_coins(rng.randi_range(4, 12) * (tier + 1) * (3 if n.golden else 1), n.position + Vector2(0, -10))
	var count := 2 if n.golden else 1
	for k in count:
		var id: String
		if n.golden:
			id = LOOT_GOLD[rng.randi() % LOOT_GOLD.size()]
		else:
			id = LOOT_COMMON[rng.randi() % LOOT_COMMON.size()]
			if rng.randf() < 0.3:
				var mats := ["piedra", "hueso", "hierro", "oro", "diamante"]
				var m: String = mats[clampi(tier + rng.randi_range(-1, 0), 0, 4)]
				id = ["lingote_", "flecha_"][rng.randi() % 2] + m
		var st := Inventory.make(id, 1 if not id.begins_with("flecha") else 5)
		if Recipes.has_quality(id) and n.golden:
			st["q"] = rng.randi_range(1, 3)
			st["bonus"] = Recipes.quality_bonus(st["q"], rng)
		drop_item(st, n.position + Vector2(0, -12), Vector2(rng.randf_range(-50, 50), -150))
	if n.golden:
		run.global_add("golden_chests", 1)


func on_hero_down(h: Hero) -> void:
	h.downed = true
	h.vel = Vector2.ZERO
	Sfx.play("caer")
	run.on_hero_down(h)


# --- Interacción ------------------------------------------------------------------------

func interact(hero: Hero) -> void:
	var c := hero.center()
	# Revivir a un compañero.
	for p in players:
		if p != hero and p.downed and p.center().distance_to(c) < 26.0:
			p.revive()
			return
	var best: Node = null
	var bd := 30.0
	for n in npcs:
		var d: float = n.rect().get_center().distance_to(c)
		if n.rect().grow(10).has_point(c) and d < bd + 30.0:
			bd = d
			best = n
	if best == null:
		for n in nodes:
			if not n.dead and n.kind == "cofre" and n.rect().grow(10).has_point(c):
				n.interact(hero)
				return
		return
	var npc: Npc = best
	match npc.kind:
		"puerta":
			run.choose_door(npc.biome)
		"vecino":
			npc.talk()
			run.counters_add(hero, "npc_talks", 1)
			Sfx.play("hablar")
		_:
			run.open_npc(npc, hero)
			if npc.kind != "altar":
				run.counters_add(hero, "npc_talks", 1)
