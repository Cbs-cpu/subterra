extends SceneTree
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	var T = load("res://tests/test_smoke.gd").new()
	T.tree = self
	var h = T._flat_start()
	print("tiles ", h.world.tile(41,13), h.world.tile(41,14), h.world.tile(40,15), " same ", h.world == T.run.world, " mw ", h.world.mw, " biome ", h.world.biome, " size ", h.size)
	print("stamina ", h.model.stamina, " max ", h.model.max_stamina(), " floor ", h.on_floor, " x ", h.position.x)
	var d := InputState.new()
	d.dash = 1
	for i in 12:
		T.run.remote_inputs[h.peer_id] = d
		T.run.world._physics_process(1.0 / 60.0)
		print(i, " x=", h.position.x, " vel=", h.vel, " dash_t=", h.dash_t, " wall=", h.on_wall)
		d.dash = 0
	quit()
