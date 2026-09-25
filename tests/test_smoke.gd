extends TestCase
## Smoke tests: partidas reales en headless (sin ventana), simulando ticks de física.

var ui: GameUI
var run: Run


func _make(seed_value := 7, race := "minero") -> Run:
	ui = GameUI.new()
	tree.root.add_child(ui)
	run = Run.new()
	tree.root.add_child(run)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	run.setup({"seed": seed_value, "madman": false, "local_peer": 1, "heroes": [{"peer": 1, "name": "Test",
		"race": race, "hat": "ninguno", "companion": "ninguno", "traits": ["lenador", "robusto"], "rolled": HeroModel.roll_stats(r)}]}, ui)
	run.world.god_mode = true
	return run


func _sim(frames: int) -> void:
	for i in frames:
		if run.world:
			run.world._physics_process(1.0 / 60.0)


func _free() -> void:
	run.free()
	ui.free()


func _hero() -> Hero:
	return run.world.players[0]


func test_every_biome_and_town_runs() -> void:
	_make()
	for b in Content.DOOR_BIOMES:
		run.district = 1 + Content.DOOR_BIOMES.find(b) * 2
		run.enter_district(b)
		_sim(120)
		check(run.world.players.size() == 1, "héroe en %s" % b)
		check(not _hero()._overlaps_solid(), "héroe libre en %s" % b)
		run.enter_town(b)
		_sim(60)
		check(run.world.is_town, "pueblo %s" % b)
	_free()


func test_every_enemy_and_boss_ticks() -> void:
	_make()
	var w := run.world
	for id in Content.ENEMIES:
		w.spawn_enemy(id, _hero().position + Vector2(60, -30))
	_sim(240)
	for e in w.enemies:
		e.take_damage(99999, Vector2.ZERO, _hero())
	for e in w.enemies:
		if e.id != "guardian":
			e.die(_hero())
	_sim(2)
	check(w.enemies.filter(func(e): return e.id != "guardian" and not e.dead).is_empty(), "todos muertos salvo guardianes")
	_free()


func test_hero_actions_do_not_crash() -> void:
	_make(3, "elfo_roca")
	var h := _hero()
	var inv := h.model.inv
	for id in ["espada_hierro", "hacha_hierro", "pico_oro", "arco", "baston_fuego", "baston_rayo", "baston_hielo",
			"baston_zombi", "red_bichos", "vial_veneno", "esquirla_ceniza", "pocion_misteriosa", "tambor_fuerza", "carne_asada"]:
		inv.slots[0] = Inventory.make(id, 3 if ItemDB.stackable(id) else 1)
		inv.hand = 0
		h.input = InputState.new()
		h.input.use = true
		h.input.use_pressed = true
		h.input.aim = h.center() + Vector2(50, 0)
		h.use_cd = 0.0
		h._use(1.0 / 60.0, h.input)
		h.model.mana = 20
		run.world._physics_process(1.0 / 60.0)
		_sim(30)
	for s in Content.SKILLS:
		h.model.skill_cd.clear()
		h._skill(s["id"])
		_sim(10)
	_sim(120)
	check(true, "sin cuelgues")
	_free()


func test_crafting_and_town_actions() -> void:
	_make()
	var h := _hero()
	var m := h.model
	m.inv.slots[3] = Inventory.make("madera", 4)
	InvOps.apply(run, m, {"op": "craft", "a": 3, "b": 3}, h)
	check(m.inv.count("tablon") == 1, "tablón por acción")
	m.coins = 5000
	check(InvOps.apply(run, m, {"op": "buy", "id": "llave"}, h).begins_with("Comprado"), "comprar")
	var msg := InvOps.apply(run, m, {"op": "altar", "id": "aelyn"}, h)
	check(msg != "" and m.coins < 5000, "altar")
	m.inv.add(Inventory.make("mena_hierro", 6))
	InvOps.apply(run, m, {"op": "npc_craft", "npc": "herrero", "out": "lingote_hierro"}, h)
	check(m.inv.count("lingote_hierro") == 1, "herrero")
	var before := m.coins
	var i := -1
	for k in m.inv.slots.size():
		if m.inv.slots[k] != null and m.inv.slots[k]["id"] == "mena_hierro":
			i = k
	InvOps.apply(run, m, {"op": "sell", "i": i}, h)
	check(m.coins > before, "vender")
	_free()


func test_door_to_town_to_next_district() -> void:
	_make()
	var doors := run.world.npcs.filter(func(n): return n.kind == "puerta")
	check_eq(doors.size(), 3, "3 puertas")
	var b: String = doors[0].biome
	run.choose_door(b)
	check(run.state == "town", "pueblo")
	check_eq(run.district, 2)
	run.leave_town()
	check(run.state == "district" and run.biome == b, "distrito del bioma elegido")
	_free()


func test_final_wall_gives_victory() -> void:
	_make()
	var won := [false]
	run.ended.connect(func(r): won[0] = r["won"])
	run.district = 21
	run.enter_district("nido")
	check(run.world.boss_node != null and run.world.boss_node.id == "muro_ceniza", "muro presente")
	_sim(60)
	run.world.boss_node.take_damage(999999, Vector2.ZERO, _hero())
	_sim(10)
	check(won[0], "victoria")
	_free()


func test_guardians_arrive_when_time_runs_out() -> void:
	_make()
	run.world.time_in = World.GUARDIAN_TIME - 0.1
	_sim(30)
	check(run.world.enemies.filter(func(e): return e.id == "guardian").size() >= 5, "guardianes")
	_free()


func test_death_ends_run() -> void:
	_make()
	var ended := [false]
	run.ended.connect(func(_r): ended[0] = true)
	run.world.god_mode = false
	_hero().hurt(999, "test", Vector2.ZERO)
	check(_hero().downed, "abatido")
	for i in 200:
		run._process(1.0 / 60.0)
	check(ended[0], "fin de partida")
	_free()


func _feed(h: Hero, inp: InputState, frames: int) -> float:
	var min_y := h.position.y
	for i in frames:
		run.remote_inputs[h.peer_id] = inp
		run.world._physics_process(1.0 / 60.0)
		min_y = minf(min_y, h.position.y)
		inp.jump_pressed = false
		inp.dash = 0
	return min_y


func _flat_start() -> Hero:
	_make(12)
	run.district = 21
	run.enter_district("nido")   # suelo plano
	for e in run.world.enemies:
		e.dead = true
	var h := _hero()
	h.is_local = false
	_sim(30)
	return h


func test_jump_height_and_double_jump() -> void:
	var h := _flat_start()
	check(h.on_floor, "en el suelo")
	var y0 := h.position.y
	var inp := InputState.new()
	inp.jump = true
	inp.jump_pressed = true
	var top := _feed(h, inp, 50)
	var hgt := y0 - top
	check(hgt > 64.0 and hgt < 90.0, "salto completo ~4-5 tiles (%.1f)" % hgt)
	_feed(h, InputState.new(), 60)
	# Salto corto al soltar pronto.
	var inp2 := InputState.new()
	inp2.jump = true
	inp2.jump_pressed = true
	var top2 := _feed(h, inp2, 4)
	inp2.jump = false
	top2 = minf(top2, _feed(h, inp2, 40))
	check(y0 - top2 < hgt * 0.7, "salto variable (%.1f)" % (y0 - top2))
	_feed(h, InputState.new(), 60)
	# Doble salto.
	var inp3 := InputState.new()
	inp3.jump = true
	inp3.jump_pressed = true
	_feed(h, inp3, 20)
	inp3.jump_pressed = true
	var top3 := _feed(h, inp3, 50)
	check(y0 - top3 > hgt + 20.0, "doble salto sube más (%.1f)" % (y0 - top3))
	_free()


func test_jump_buffer_and_dash() -> void:
	var h := _flat_start()
	var inp := InputState.new()
	inp.jump = true
	inp.jump_pressed = true
	_feed(h, inp, 30)
	inp.jump = false
	# Pulsar salto justo antes de aterrizar: debe saltar al tocar suelo.
	var landed_jump := false
	for i in 90:
		var pre := InputState.new()
		if not h.on_floor and h.vel.y > 0.0 and h.position.y > run.world.map["spawn"].y - 10.0 and not landed_jump:
			pre.jump = true
			pre.jump_pressed = true
			landed_jump = true
		run.remote_inputs[h.peer_id] = pre
		run.world._physics_process(1.0 / 60.0)
	check(landed_jump, "se pulsó en el aire")
	_feed(h, InputState.new(), 90)
	var x0 := h.position.x
	var d := InputState.new()
	d.dash = 1
	_feed(h, d, 20)
	var dist := h.position.x - x0
	check(dist > 30.0 and dist < 70.0, "dash (%.1f px)" % dist)
	_free()
