extends TestCase


func test_stacks_up_to_99() -> void:
	var inv := Inventory.new()
	check_eq(inv.add(Inventory.make("madera", 150)), 0)
	check_eq(inv.slots[0]["n"], 99)
	check_eq(inv.slots[1]["n"], 51)


func test_tools_do_not_stack() -> void:
	var inv := Inventory.new()
	inv.add(Inventory.make("hacha_madera", 1))
	inv.add(Inventory.make("hacha_madera", 1))
	check(inv.slots[0] != null and inv.slots[1] != null, "dos ranuras")


func test_split_and_place_one() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("piedra", 10)
	inv.split(0, 5)
	check_eq(inv.slots[0]["n"], 5)
	check_eq(inv.slots[5]["n"], 5)
	inv.place_one(0, 6)
	check_eq(inv.slots[6]["n"], 1)
	check_eq(inv.slots[0]["n"], 4)


func test_move_merges_same_stacks() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("piedra", 90)
	inv.slots[1] = Inventory.make("piedra", 20)
	inv.move(1, 0)
	check_eq(inv.slots[0]["n"], 99)
	check_eq(inv.slots[1]["n"], 11)


func test_wear_breaks_tools() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("hacha_madera", 1)
	inv.slots[0]["dur"] = 1
	check(inv.wear(0), "se rompe")
	check(inv.slots[0] == null, "desaparece")


func test_equip_adds_stats() -> void:
	var inv := Inventory.new()
	inv.slots[3] = Inventory.make("armadura_hierro", 1)
	inv.equip_from(3)
	var s := inv.gear_stats()
	check_eq(s["hp"], 2)
	check_eq(s["atk"], 4)


func test_held_weapon_counts_but_equipment_in_hand_does_not() -> void:
	var inv := Inventory.new()
	inv.slots[0] = Inventory.make("espada_madera", 1)
	check_eq(inv.gear_stats()["atk"], 2)
	inv.slots[0] = Inventory.make("casco_hierro", 1)
	check_eq(inv.gear_stats()["atk"], 0)


func test_best_arrow() -> void:
	var inv := Inventory.new()
	inv.add(Inventory.make("flecha_piedra", 5))
	inv.add(Inventory.make("flecha_hierro", 5))
	check_eq(inv.best_arrow(), "flecha_hierro")
