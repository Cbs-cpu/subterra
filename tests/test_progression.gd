extends TestCase


func _rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _ids(list: Array) -> Array:
	return list.map(func(u): return u["id"])


func test_nothing_unlocks_with_empty_run() -> void:
	var u := Progression.evaluate({}, {}, Progression.default_owned(), _rng())
	check(not _ids(u).has("alado"), "alado no")


func test_guaranteed_unlocks_trigger() -> void:
	var c := {"won": 1, "time": 1800, "potions_hp": 0, "crafts": 5, "kills": 300, "level": 12}
	var u := _ids(Progression.evaluate(c, {}, Progression.default_owned(), _rng()))
	check(u.has("alado"), "ganar en <1h")
	check(u.has("porcino"), "sin pociones")
	check(u.has("corona"), "corona de héroe")
	check(not u.has("batracio"), "ha crafteado")


func test_chance_unlocks_are_probabilistic() -> void:
	var got := 0
	for s in 200:
		var u := _ids(Progression.evaluate({"kills": 20}, {}, Progression.default_owned(), _rng(s)))
		if u.has("linajudo"):
			got += 1
	check(got > 20 and got < 70, "~20 %% (%d)" % got)


func test_owned_are_not_repeated() -> void:
	var owned := Progression.default_owned()
	owned["race"].append("alado")
	var u := _ids(Progression.evaluate({"won": 1, "time": 10}, {}, owned, _rng()))
	check(not u.has("alado"), "ya tenía alado")


func test_global_stats_and_names() -> void:
	var u := _ids(Progression.evaluate({"name": "Escamas"}, {"golden_chests": 25}, Progression.default_owned(), _rng()))
	check(u.has("escamado"), "nombre secreto")
	check(u.has("engendro"), "cofres dorados globales")


func test_door_choices_rules() -> void:
	var r := _rng(4)
	for d in range(2, 21):
		var ch := Content.door_choices(d, r)
		check_eq(ch.size(), 3, "3 puertas en %d" % d)
		var uniq := {}
		var has_easy := false
		for b in ch:
			uniq[b] = true
			check(Content.allowed_biomes(d).has(b), "%s permitido en %d" % [b, d])
			if int(Content.BIOMES[b]["tier"]) <= 2:
				has_easy = true
		check_eq(uniq.size(), 3, "distintas")
		check(has_easy, "hay opción fácil")
	check_eq(Content.door_choices(21, r), ["nido"], "final")


func test_every_enemy_in_biomes_exists() -> void:
	for b in Content.BIOMES:
		var bio: Dictionary = Content.BIOMES[b]
		for e in bio["enemies"]:
			check(Content.ENEMIES.has(e[0]), "enemigo %s" % e[0])
		for e in bio["passive"] + bio["bosses"]:
			check(Content.ENEMIES.has(e), "enemigo %s" % e)
	for id in Content.ENEMIES:
		for d in Content.ENEMIES[id]["drops"]:
			check(ItemDB.has(d[0]), "drop %s de %s" % [d[0], id])
	for r in Content.RACES:
		for it in r["items"]:
			check(ItemDB.has(it), "objeto inicial %s" % it)
