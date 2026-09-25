extends TestCase


func _rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _hero(race := "minero", traits := ["lenador", "robusto"], hat := "ninguno", comp := "ninguno") -> HeroModel:
	var h := HeroModel.new()
	var r := _rng()
	h.setup(race, traits, hat, comp, HeroModel.roll_stats(r), r)
	return h


func test_rolled_stats_respect_ranges() -> void:
	var r := _rng(3)
	for i in 300:
		var st: Dictionary = HeroModel.roll_stats(r)["base"]
		check_eq(st["hp"] + st["atk"] + st["dex"] + st["mag"], 15, "15 puntos")
		check(st["hp"] >= 4 and st["hp"] <= 6, "vida en rango")
		for s in ["atk", "dex", "mag"]:
			check(st[s] >= 2 and st[s] <= 4, "%s en rango" % s)


func test_race_and_traits_modify_stats() -> void:
	var h := _hero("ciclope", ["robusto", "agresivo"])
	# Cíclope: vida -1, ataque +2. Robusto: vida +4. Agresivo: ataque +2, destreza -2.
	check_eq(h.stat("hp"), h.base["hp"] - 1 + 4)
	h.inv.hand = 7
	check_eq(h.stat("atk"), h.base["atk"] + 4, "sin arma en la mano")


func test_race_starting_items() -> void:
	var h := _hero("elfo_roca")
	check(h.inv.count("arco") == 1, "elfo con arco")


func test_level_up_always_gains_something() -> void:
	var h := _hero()
	var r := _rng(5)
	for i in 30:
		var before: int = h.base["hp"] + h.base["atk"] + h.base["dex"] + h.base["mag"]
		h.gain_xp(HeroModel.xp_to_next(h.level), r)
		var after: int = h.base["hp"] + h.base["atk"] + h.base["dex"] + h.base["mag"]
		check(after > before, "nivel %d suma" % h.level)


func test_skill_offers_every_five_levels_max_three() -> void:
	var h := _hero()
	var r := _rng(2)
	while h.level < 20:
		h.gain_xp(HeroModel.xp_to_next(h.level), r)
		while h.pending_skill_offers > 0:
			var offer := h.roll_skill_offer(r)
			check_eq(offer.size(), 3, "3 opciones")
			h.learn_skill(offer[0])
	check_eq(h.skills.size(), 3, "máximo 3 habilidades")


func test_hunger_drains_and_starving_hurts() -> void:
	var h := _hero()
	var ev := []
	for i in 400 * 60:
		ev.append_array(h.tick(1.0 / 60.0))
		if not ev.is_empty():
			break
	check(h.hunger <= 0.0, "hambre agotada")
	check(ev.has("starve"), "inanición")


func test_big_eater_raises_hunger_cap() -> void:
	check_eq(_hero("minero", ["tragon", "robusto"]).max_hunger(), 12)


func test_stamina_and_free_stamina_hat() -> void:
	var h := _hero()
	var n := 0
	while h.use_stamina():
		n += 1
		if n > 20:
			break
	check_eq(n, h.max_stamina(), "se agota")
	var h2 := _hero("minero", ["lenador", "robusto"], "yelmo_dragon")
	for i in 20:
		check(h2.use_stamina(), "yelmo de dragón: gratis")


func test_damage_reductions() -> void:
	var h := _hero("minero", ["lenador", "robusto"], "yelmo_real")
	var hp0 := h.hp
	check_eq(h.damage(7), 3, "yelmo real divide")
	h.add_buff({"flag": "aura", "t": 5.0})
	check_eq(h.damage(3), 1, "mínimo 1")
	check_eq(h.hp, hp0 - 4)


func test_combat_formulas() -> void:
	var h := _hero()
	var r := _rng(9)
	h.inv.hand = 7
	var m := Combat.melee(h, r)
	check(m["amount"] == h.stat("atk") or m["amount"] == h.stat("atk") * 2, "cuerpo a cuerpo")
	var f := Combat.melee(h, r, {"furia": true})
	check(f["amount"] >= h.stat("atk") * 2, "furia duplica")
	var a := Combat.arrow(h, 5, r)
	check(a["amount"] >= h.stat("dex") + 5, "flecha")
	check_eq(Combat.vs_armor(5, 13), 1, "mínimo 1 contra armadura")


func test_save_roundtrip() -> void:
	var h := _hero("alado")
	h.coins = 77
	var d := h.to_data()
	var h2 := HeroModel.new()
	h2.from_data(JSON.parse_string(JSON.stringify(d)))
	check_eq(h2.coins, 77)
	check_eq(h2.race_id, "alado")
