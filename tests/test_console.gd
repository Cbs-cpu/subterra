extends TestCase
## La consola de depuración ejecuta sus comandos sobre una partida real.

var ui: GameUI
var run: Run
var fake_main: Node


func _setup() -> void:
	ui = GameUI.new()
	tree.root.add_child(ui)
	run = Run.new()
	tree.root.add_child(run)
	var r := RandomNumberGenerator.new()
	r.seed = 3
	run.setup({"seed": 3, "madman": false, "local_peer": 1, "heroes": [{"peer": 1, "name": "T", "race": "minero",
		"hat": "ninguno", "companion": "ninguno", "traits": ["lenador", "robusto"], "rolled": HeroModel.roll_stats(r)}]}, ui)
	fake_main = Node.new()
	fake_main.set_script(load("res://tests/fake_main.gd"))
	fake_main.run = run
	tree.root.get_node("Console").main = fake_main


func _teardown() -> void:
	tree.root.get_node("Console").main = null
	run.free()
	ui.free()
	fake_main.free()


func test_commands_affect_the_game() -> void:
	_setup()
	var con = tree.root.get_node("Console")
	var h: Hero = run.world.players[0]
	check(con.exec("give espada_oro 2"), "give existe")
	check_eq(h.model.inv.count("espada_oro"), 2)
	con.exec("coins 250")
	check(h.model.coins >= 250, "monedas")
	con.exec("level 6")
	check(h.model.level >= 6, "nivel")
	con.exec("spawn limo_verde 3")
	check(run.world.enemies.filter(func(e): return e.id == "limo_verde").size() >= 3, "spawn")
	con.exec("kill all")
	for i in 20:
		run.world._physics_process(1.0 / 60.0)
	check(run.world.enemies.filter(func(e): return e.id == "limo_verde").is_empty(), "kill")
	con.exec("god")
	check(run.world.god_mode, "god")
	con.exec("district tundra 5")
	check(run.biome == "tundra" and run.district == 5, "district")
	con.exec("town volcan")
	check(run.state == "town", "town")
	check(not con.exec("noexiste"), "comando desconocido")
	con.exec("speed 1")
	_teardown()
