class_name Run
extends Node
## Una partida completa: distritos, pueblos, héroes, contadores y final. En cooperativo solo el
## anfitrión simula; los clientes reciben el estado (ver Net).

signal ended(result: Dictionary)

var seed_value := 0
var madman := false
var district := 1
var biome := "bosque"
var next_biome := ""
var models := {}              # peer_id -> HeroModel
var counters := {}            # peer_id -> {clave: valor}
var world: World
var ui: GameUI
var state := "district"
var rng := RandomNumberGenerator.new()
var time_total := 0.0
var remote_inputs := {}       # peer_id -> InputState
var party_dead_t := -1.0
var finished := false
var visited := {}
var biome_kills := {}
var local_peer := 1
## El mundo se dibuja a 320x180 dentro de un SubViewport ampliado x3 (zoom 1,5x respecto a la
## interfaz, que va a 480x270 x2); así todos los píxeles del juego son del mismo tamaño.
const WORLD_RES := Vector2i(320, 180)
const WORLD_SCALE := 3
var world_box: SubViewportContainer
var world_vp: SubViewport


func _ensure_viewport() -> void:
	if world_vp != null:
		return
	world_box = SubViewportContainer.new()
	world_box.stretch = true
	world_box.stretch_shrink = WORLD_SCALE
	world_box.size = Vector2(WORLD_RES * WORLD_SCALE)
	world_box.mouse_filter = Control.MOUSE_FILTER_PASS
	world_box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(world_box)
	world_vp = SubViewport.new()
	world_vp.size = WORLD_RES
	world_vp.snap_2d_transforms_to_pixel = true
	world_vp.snap_2d_vertices_to_pixel = true
	world_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	world_vp.handle_input_locally = false
	world_box.add_child(world_vp)


func setup(config: Dictionary, p_ui: GameUI) -> void:
	_ensure_viewport()
	ui = p_ui
	ui.run = self
	seed_value = config["seed"]
	madman = config.get("madman", false)
	rng.seed = seed_value
	local_peer = config.get("local_peer", 1)
	for h in config["heroes"]:
		var m := HeroModel.new()
		var r := RandomNumberGenerator.new()
		r.seed = seed_value + int(h["peer"]) * 17
		m.setup(h["race"], h["traits"], h["hat"], h["companion"], h["rolled"], r)
		m.name = h["name"]
		models[int(h["peer"])] = m
		counters[int(h["peer"])] = {"name": h["name"].to_lower()}
	if config.has("saved"):
		_load_saved(config["saved"])
		enter_town(biome)
	else:
		enter_district("bosque")


func _process(dt: float) -> void:
	if world and not world.paused:
		time_total += dt
	if party_dead_t >= 0.0:
		party_dead_t -= dt
		if party_dead_t < 0.0:
			end(false)


# --- Transiciones ------------------------------------------------------------------------

func _clear_world() -> void:
	if world:
		world.queue_free()
		world = null


func enter_district(b: String) -> void:
	_clear_world()
	biome = b
	state = "district"
	visited[b] = true
	for pid in counters:
		counters[pid]["visit_" + b] = 1
		counters[pid]["district"] = max(int(counters[pid].get("district", 0)), district)
	var drng := RandomNumberGenerator.new()
	drng.seed = seed_value * 1009 + district
	var doors := [] if b == "nido" else Content.door_choices(district + 1, drng)
	var map := DistrictGen.generate(seed_value * 97 + district * 13, b, district, doors, madman)
	world = World.new()
	world_vp.add_child(world)
	world.setup(self, map, seed_value + district * 7)
	_spawn_heroes(map["spawn"])
	if Net.is_client():
		ui.show_title_card(Content.biome(b)["name"], "Distrito %d" % district if b != "nido" else "El final")
		Net.run_ref = self
		return
	for pid in models:
		var m: HeroModel = models[pid]
		m.reset_cooldowns()
		var f := m.fx()
		if f.has("tiki"):
			if rng.randf() < 0.5:
				m.heal(3)
			else:
				m.hp = maxi(1, m.hp - 1)
	ui.show_title_card(Content.biome(b)["name"], "Distrito %d" % district if b != "nido" else "El final")
	Net.on_world_changed(self)


func enter_town(b: String) -> void:
	_clear_world()
	state = "town"
	next_biome = b
	var map := DistrictGen.generate_town(seed_value * 31 + district, b)
	world = World.new()
	world_vp.add_child(world)
	world.setup(self, map, seed_value + district * 11)
	_spawn_heroes(map["spawn"])
	if Net.is_client():
		ui.show_title_card("Pueblo", "Rumbo a: " + Content.biome(b)["name"])
		Net.run_ref = self
		return
	for pid in models:
		var m: HeroModel = models[pid]
		if m.fx().has("regen_district"):
			m.heal(1)
	ui.show_title_card("Pueblo", "Rumbo a: " + Content.biome(b)["name"])
	save_to_disk()
	Net.on_world_changed(self)


func _spawn_heroes(at: Vector2) -> void:
	var i := 0
	for pid in models:
		var h := Hero.new()
		h.setup_hero(world, models[pid], pid, pid == local_peer)
		if models[pid].hp <= 0:
			models[pid].hp = 1
		world.add_hero(h, at + Vector2(i * 14, 0))
		i += 1


## Puerta elegida al final del distrito.
func choose_door(b: String) -> void:
	if state != "district":
		return
	Sfx.play("puerta")
	district += 1
	if b == "nido":
		enter_district("nido")
	else:
		enter_town(b)


func leave_town() -> void:
	if state != "town":
		return
	enter_district(next_biome)


# --- Entrada ----------------------------------------------------------------------------

func gather_inputs(w: World) -> void:
	for h in w.players:
		if h.is_local:
			h.input = InputState.from_local(w.mouse_world(), ui.blocks_game_input())
		else:
			var inp: InputState = remote_inputs.get(h.peer_id, InputState.new())
			h.input = inp
			var cont := InputState.new()
			cont.move = inp.move
			cont.jump = inp.jump
			cont.use = inp.use
			cont.aim = inp.aim
			remote_inputs[h.peer_id] = cont


func after_world_tick(w: World) -> void:
	Net.after_tick(w)


# --- Eventos -------------------------------------------------------------------------------

func counters_add(hero: Node, key: String, n: int) -> void:
	var c: Dictionary = counters.get(hero.peer_id, {})
	c[key] = int(c.get(key, 0)) + n
	counters[hero.peer_id] = c


func counters_max(hero: Node, key: String, v: int) -> void:
	var c: Dictionary = counters.get(hero.peer_id, {})
	c[key] = maxi(int(c.get(key, 0)), v)


func global_add(key: String, n: int) -> void:
	Game.global_stats[key] = int(Game.global_stats.get(key, 0)) + n


func on_enemy_killed(e: Node, by: Node, b: String) -> void:
	var pid: int = by.peer_id if by != null and by is Hero else (by.owner_hero.peer_id if by != null and "owner_hero" in by and by.owner_hero else local_peer)
	var c: Dictionary = counters.get(pid, {})
	if e.data["ai"] != "pasivo" and e.id != "guardian":
		c["kills"] = int(c.get("kills", 0)) + 1
		var bk := "biome_kills_" + b
		c[bk] = int(c.get(bk, 0)) + 1
		c["max_biome_kills"] = maxi(int(c.get("max_biome_kills", 0)), c[bk])
		global_add("kills", 1)
	if e.boss:
		var key = "kill_" + e.id
		if e.id == "corsario":
			key = "kill_corsario"
		c[key] = 1


func on_pickup(hero: Node, stack: Dictionary) -> void:
	pass


func on_craft(hero_model: HeroModel, out_id: String) -> void:
	for pid in models:
		if models[pid] == hero_model:
			var c: Dictionary = counters[pid]
			c["crafts"] = int(c.get("crafts", 0)) + 1
			if out_id.begins_with("baston_"):
				c["staffs"] = int(c.get("staffs", 0)) + 1
			if out_id.begins_with("mandoble_"):
				var got: Dictionary = c.get("brand_set", {})
				got[out_id] = true
				c["brand_set"] = got
				c["brands"] = got.size()


func on_hero_down(h: Hero) -> void:
	var all_down := true
	for p in world.players:
		if not p.downed and not p.dead:
			all_down = false
	if all_down:
		party_dead_t = 2.5
		for p in world.players:
			p.dead = false


func offer_skill(hero: Node) -> void:
	if hero.is_local:
		ui.open_skill_pick(hero)
	else:
		Net.send_skill_offer(hero)


func open_npc(npc: Npc, hero: Hero) -> void:
	if hero.is_local:
		ui.open_npc(npc, hero)
	else:
		Net.send_open_npc(hero, npc)


func notify(text: String, col: Color) -> void:
	ui.notify(text, col)
	Net.send_notify(text, col)


func win() -> void:
	end(true)


func end(won: bool) -> void:
	if finished:
		return
	finished = true
	var owned_before := Game.owned.duplicate(true)
	var result := {"won": won, "district": district, "biome": biome, "time": time_total, "seed": seed_value,
		"madman": madman, "heroes": [], "unlocks": []}
	for pid in models:
		var m: HeroModel = models[pid]
		var c: Dictionary = counters.get(pid, {}).duplicate()
		c["won"] = 1 if won else 0
		c["time"] = time_total
		c["level"] = maxi(int(c.get("level", 1)), m.level)
		c["skills"] = m.skills.size()
		c["district"] = district
		c["won_madman"] = 1 if won and madman else 0
		var mage := 0
		var warrior := 0
		for s in m.skills:
			var t: String = Content.find(Content.SKILLS, s)["type"]
			if t == "mago":
				mage += 1
			elif t == "guerrero":
				warrior += 1
		c["mage_skills"] = mage
		c["warrior_skills"] = warrior
		var sh = m.inv.equip.get("escudo")
		c["win_with_scale"] = 1 if won and sh != null and sh["id"] == "escudo_escama" else 0
		for k in ["potions_hp", "crafts", "trees", "npc_talks", "damage_taken"]:
			c[k] = int(c.get(k, 0))
		if pid == local_peer:
			var unl := Progression.evaluate(c, Game.global_stats, owned_before, rng)
			Game.grant(unl)
			result["unlocks"] = unl
		result["heroes"].append({"name": m.name, "race": m.race_id, "level": m.level, "kills": int(c.get("kills", 0)),
			"cause": world.players.filter(func(p): return p.peer_id == pid)[0].last_hit_by if world and not world.players.filter(func(p): return p.peer_id == pid).is_empty() else ""})
	Game.global_stats["runs"] = int(Game.global_stats.get("runs", 0)) + 1
	if won:
		Game.global_stats["wins"] = int(Game.global_stats.get("wins", 0)) + 1
	else:
		Game.global_stats["deaths"] = int(Game.global_stats.get("deaths", 0)) + 1
	Game.global_stats["best_district"] = maxi(int(Game.global_stats.get("best_district", 0)), district)
	Game.save_profile()
	Game.clear_run()
	Music.play_biome("fin")
	Net.send_end(result)
	ended.emit(result)


# --- Guardado ----------------------------------------------------------------------------

func save_to_disk() -> void:
	if Net.is_online():
		return
	var heroes := {}
	for pid in models:
		heroes[str(pid)] = models[pid].to_data()
	Game.save_run({"seed": seed_value, "madman": madman, "district": district, "next_biome": next_biome,
		"time": time_total, "counters": counters, "heroes": heroes})


func _load_saved(d: Dictionary) -> void:
	district = int(d["district"])
	biome = d["next_biome"]
	time_total = float(d["time"])
	for k in d["heroes"]:
		var pid := int(k)
		if models.has(pid):
			models[pid].from_data(d["heroes"][k])
	for k in d["counters"]:
		counters[int(k)] = d["counters"][k]
