extends TestCase


func _rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_every_recipe_output_and_input_exists() -> void:
	for k in Recipes.pairs():
		var parts: PackedStringArray = k.split("|")
		check(ItemDB.has(parts[0]), "ingrediente %s existe" % parts[0])
		check(ItemDB.has(parts[1]), "ingrediente %s existe" % parts[1])
		check(ItemDB.has(Recipes.pairs()[k]["out"]), "resultado %s existe" % Recipes.pairs()[k]["out"])
	for npc in ["herrero", "sastra", "peletero"]:
		for r in Recipes.npc_recipes(npc):
			check(ItemDB.has(r["out"]), "artesano %s: %s existe" % [npc, r["out"]])


func test_recipes_are_commutative() -> void:
	check_eq(Recipes.lookup("palo", "tablon"), Recipes.lookup("tablon", "palo"))
	check_eq(Recipes.lookup("palo", "tablon")["out"], "empunadura")


func test_wooden_axe_chain_from_raw_materials() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("madera", 4)
	inv.slots[1] = Inventory.make("palo", 2)
	var r := _rng()
	inv.craft(0, 0, 0, r)                        # madera + madera = tablón
	inv.craft(0, 0, 0, r)
	var tab := _find(inv, "tablon")
	check_eq(inv.count("tablon"), 2, "tablones")
	inv.craft(tab, tab, 0, r)                    # tablón + tablón = hoja de madera
	check_eq(inv.count("hoja_madera"), 1, "hoja")
	inv.craft(1, 1, 0, r)                        # palo + palo = mango de hacha
	check_eq(inv.count("mango_hacha"), 1, "mango")
	inv.craft(_find(inv, "hoja_madera"), _find(inv, "mango_hacha"), 0, r)
	check_eq(inv.count("hacha_madera"), 1, "hacha")
	check_eq(inv.count("madera") + inv.count("palo"), 0, "consume todo")


func test_invalid_combination_does_nothing() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("madera", 1)
	inv.slots[1] = Inventory.make("pocion_vida", 1)
	var res := inv.craft(0, 1, 0, _rng())
	check(res.is_empty(), "sin receta")
	check_eq(inv.count("madera"), 1)


func test_arrows_come_in_fives() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("lingote_piedra", 1)
	inv.slots[1] = Inventory.make("palo", 1)
	inv.craft(0, 1, 0, _rng())
	check_eq(inv.count("flecha_piedra"), 5)


func test_tool_ingredient_loses_durability() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("carne_cruda", 2)
	inv.slots[1] = Inventory.make("encendedor", 1)
	inv.craft(0, 1, 0, _rng())
	check_eq(inv.count("carne_asada"), 1, "asada")
	check_eq(inv.slots[1]["dur"], 9, "encendedor gastado")


func test_quality_distribution_improves_with_luck() -> void:
	var r := _rng(7)
	var base := 0
	var lucky := 0
	for i in 4000:
		if Recipes.roll_quality(0, r) > 0:
			base += 1
		if Recipes.roll_quality(10, r) > 0:
			lucky += 1
	check(base > 600 and base < 1000, "base ~20 %% (%d)" % base)
	check(lucky > base + 200, "artesano mejora (%d vs %d)" % [lucky, base])


func test_npc_crafting_needs_materials() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("mena_hierro", 2)
	check(inv.can_npc("herrero", "lingote_hierro"), "puede")
	check(not inv.can_npc("herrero", "casco_hierro"), "no puede casco")
	inv.craft_npc("herrero", "lingote_hierro", 0, _rng())
	check_eq(inv.count("lingote_hierro"), 1)
	check_eq(inv.count("mena_hierro"), 0)


func test_brewer_can_make_big_potions() -> void:
	var big := 0
	for s in 40:
		var inv := Inventory.new()
		inv.slots[0] = Inventory.make("hierba", 2)
		inv.craft(0, 0, 0, _rng(s), true)
		big += inv.count("pocion_vida_g")
	check(big > 5 and big < 35, "alquimista ~50 %% (%d)" % big)


func _find(inv: Inventory, id: String) -> int:
	for i in inv.slots.size():
		if inv.slots[i] != null and inv.slots[i]["id"] == id:
			return i
	return -1
