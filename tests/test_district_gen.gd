extends TestCase


func test_exit_reachable_for_many_seeds_and_biomes() -> void:
	var biomes := Content.DOOR_BIOMES
	for s in range(1, 121):
		var b: String = biomes[s % biomes.size()]
		var district := 1 + s % 20
		var d := DistrictGen.generate(s, b, district, ["bosque", "cienaga", "tundra"])
		var start := DistrictGen.px_to_tile(d["spawn"])
		check(DistrictGen.standable(d, start.x, start.y), "inicio de pie (semilla %d)" % s)
		var reach := DistrictGen.reachable_set(d, start)
		for door in d["doors"]:
			var t := DistrictGen.px_to_tile(door["pos"])
			check(reach.has(t), "puerta alcanzable (semilla %d, %s, %s)" % [s, b, t])


func test_final_district_has_wall_and_no_doors() -> void:
	var d := DistrictGen.generate(5, "nido", 21, [])
	check_eq(d["doors"].size(), 0)
	check_eq(d["boss"]["id"], "muro_ceniza")


func test_deterministic() -> void:
	var a := DistrictGen.generate(99, "bosque", 3, ["bosque", "cienaga", "pradera"])
	var b := DistrictGen.generate(99, "bosque", 3, ["bosque", "cienaga", "pradera"])
	check(a["tiles"] == b["tiles"], "mismos tiles")
	check_eq(a["entities"].size(), b["entities"].size(), "mismas entidades")


func test_content_is_placed() -> void:
	var d := DistrictGen.generate(11, "bosque", 2, ["bosque", "cienaga", "pradera"])
	var kinds := {}
	for e in d["entities"]:
		kinds[e["kind"]] = true
	for k in ["arbol", "roca", "hierba", "enemigo"]:
		check(kinds.has(k), "hay %s" % k)


func test_town_has_all_services() -> void:
	var t := DistrictGen.generate_town(3, "bosque")
	var npcs := {}
	var altars := 0
	for e in t["entities"]:
		if e["kind"] == "npc":
			npcs[e["npc"]] = true
		if e["kind"] == "altar":
			altars += 1
	for n in ["tendero", "herrero", "sastra", "peletero", "comprador"]:
		check(npcs.has(n), "hay %s" % n)
	check_eq(altars, 4)
