extends Node
## Escena principal: título, creación de personaje, cooperativo, desbloqueos, opciones y final.

const COL_TXT := Color("#f0e8d8")
const COL_DIM := Color("#8a8098")
const COL_GOLD := Color("#f0c03a")

var screen := "titulo"      # titulo, crear, coop, galeria, opciones, controles, final
var draw_node: Node2D
var ui_layer: CanvasLayer
var game_ui: GameUI
var run: Run
var t := 0.0
var result := {}

# Creación de personaje.
var c_name := "Hero"
var c_race := 0
var c_hat := 0
var c_comp := 0
var c_traits := [0, 8]
var c_rolled := {}
var c_madman := false
var c_seed := ""
var editing := ""            # "nombre", "semilla", "ip"
var rng := RandomNumberGenerator.new()
var gallery_tab := 0
var rebinding := ""
var coop_ip := "127.0.0.1"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	Console.main = self
	c_rolled = HeroModel.roll_stats(rng)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 30
	ui_layer.scale = Vector2(2, 2)
	add_child(ui_layer)
	draw_node = Node2D.new()
	draw_node.draw.connect(_draw_screen)
	ui_layer.add_child(draw_node)
	Music.play_biome("titulo")
	if Net.has_signal("start_game"):
		Net.start_game.connect(_on_net_start)
	var args := OS.get_cmdline_user_args()
	if "--play" in args:
		_start_single(12345)
	if "--shots" in args:
		_shots.call_deferred()
	if "--anim-test" in args:
		_anim_test.call_deferred()
	if "--host-test" in args:
		_net_test(true)
	if "--join-test" in args:
		_net_test(false)


func _process(dt: float) -> void:
	t += dt
	draw_node.visible = screen != "juego"
	draw_node.queue_redraw()


# --- Partidas ------------------------------------------------------------------------------

func _hero_config(peer: int) -> Dictionary:
	var hats := _owned_list("hat", Content.HATS)
	var comps := _owned_list("companion", Content.COMPANIONS)
	var races := _owned_list("race", Content.RACES)
	return {"peer": peer, "name": c_name, "race": races[c_race % races.size()]["id"],
		"hat": hats[c_hat % hats.size()]["id"], "companion": comps[c_comp % comps.size()]["id"],
		"traits": [Content.TRAITS[c_traits[0]]["id"], Content.TRAITS[c_traits[1]]["id"]], "rolled": c_rolled}


func _start_single(seed_value: int) -> void:
	_begin_run({"seed": seed_value, "madman": c_madman, "local_peer": 1, "heroes": [_hero_config(1)]})


func _begin_run(config: Dictionary) -> void:
	if run:
		run.queue_free()
	if game_ui:
		game_ui.queue_free()
	game_ui = GameUI.new()
	add_child(game_ui)
	game_ui.quit_to_menu.connect(_to_title)
	run = Run.new()
	add_child(run)
	run.ended.connect(_on_run_end)
	run.setup(config, game_ui)
	screen = "juego"


func _on_net_start(config: Dictionary) -> void:
	_begin_run(config)


func _on_run_end(r: Dictionary) -> void:
	result = r
	await get_tree().create_timer(1.0).timeout
	screen = "final"
	if r["won"]:
		Sfx.play("victoria")
	if run:
		run.queue_free()
		run = null
	if game_ui:
		game_ui.queue_free()
		game_ui = null


func _to_title() -> void:
	if run:
		run.queue_free()
		run = null
	if game_ui:
		game_ui.queue_free()
		game_ui = null
	Net.leave()
	screen = "titulo"
	Music.play_biome("titulo")


func _owned_list(kind: String, list: Array) -> Array:
	return list.filter(func(e): return Game.is_owned(kind, e["id"]))


# --- Entrada --------------------------------------------------------------------------------

func _unhandled_input(ev: InputEvent) -> void:
	if screen == "juego":
		return
	if rebinding != "":
		if ev is InputEventKey and ev.pressed:
			if ev.physical_keycode != KEY_ESCAPE:
				Game.rebind(rebinding, ev.physical_keycode)
			rebinding = ""
		return
	if editing != "" and ev is InputEventKey and ev.pressed:
		var k: int = ev.keycode
		if k == KEY_ENTER or k == KEY_ESCAPE or k == KEY_KP_ENTER:
			editing = ""
		elif k == KEY_BACKSPACE:
			match editing:
				"nombre": c_name = c_name.substr(0, c_name.length() - 1)
				"semilla": c_seed = c_seed.substr(0, c_seed.length() - 1)
				"ip": coop_ip = coop_ip.substr(0, coop_ip.length() - 1)
		elif ev.unicode > 31:
			var ch := char(ev.unicode)
			match editing:
				"nombre":
					if c_name.length() < 12:
						c_name += ch
				"semilla":
					if ch.is_valid_int() and c_seed.length() < 9:
						c_seed += ch
				"ip":
					if coop_ip.length() < 40:
						coop_ip += ch
		get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("pause") and screen != "titulo":
		screen = "titulo" if screen != "controles" else "opciones"
		return
	if ev is InputEventMouseButton and ev.pressed:
		var m := draw_node.get_local_mouse_position()
		for b in _buttons():
			if b["r"].has_point(m):
				Sfx.play("menu")
				b["f"].call(ev.button_index)
				return
		editing = ""


func _btn(out: Array, r: Rect2, f: Callable) -> void:
	out.append({"r": r, "f": f})


func _buttons() -> Array:
	var out := []
	match screen:
		"titulo":
			var items := _title_items()
			for k in items.size():
				var item: String = items[k]
				_btn(out, Rect2(180, 120 + k * 18, 120, 16), func(_b): _title_pick(item))
		"crear":
			var races := _owned_list("race", Content.RACES)
			var hats := _owned_list("hat", Content.HATS)
			var comps := _owned_list("companion", Content.COMPANIONS)
			_btn(out, Rect2(170, 34, 120, 12), func(_b): editing = "nombre")
			_btn(out, Rect2(150, 54, 14, 12), func(_b): c_race = wrapi(c_race - 1, 0, races.size()))
			_btn(out, Rect2(296, 54, 14, 12), func(_b): c_race = wrapi(c_race + 1, 0, races.size()))
			_btn(out, Rect2(150, 72, 14, 12), func(_b): c_hat = wrapi(c_hat - 1, 0, hats.size()))
			_btn(out, Rect2(296, 72, 14, 12), func(_b): c_hat = wrapi(c_hat + 1, 0, hats.size()))
			_btn(out, Rect2(150, 90, 14, 12), func(_b): c_comp = wrapi(c_comp - 1, 0, comps.size()))
			_btn(out, Rect2(296, 90, 14, 12), func(_b): c_comp = wrapi(c_comp + 1, 0, comps.size()))
			for k in 2:
				var kk := k
				_btn(out, Rect2(170, 110 + k * 16, 140, 13), func(b): _cycle_trait(kk, 1 if b == MOUSE_BUTTON_LEFT else -1))
			_btn(out, Rect2(330, 176, 70, 13), func(_b): c_rolled = HeroModel.roll_stats(rng))
			_btn(out, Rect2(170, 150, 140, 13), func(_b): c_madman = not c_madman)
			_btn(out, Rect2(170, 166, 140, 13), func(_b): editing = "semilla")
			_btn(out, Rect2(180, 226, 120, 18), func(_b): _start_single(int(c_seed) if c_seed != "" else rng.randi() % 1000000))
			_btn(out, Rect2(20, 240, 70, 14), func(_b): screen = "titulo")
		"coop":
			_btn(out, Rect2(120, 70, 110, 16), func(_b): Net.host(7777, _hero_config(1)))
			_btn(out, Rect2(250, 90, 110, 16), func(_b): Net.join(coop_ip, 7777, _hero_config(0)))
			_btn(out, Rect2(250, 70, 110, 16), func(_b): editing = "ip")
			if Net.is_host():
				_btn(out, Rect2(180, 220, 120, 16), func(_b): Net.start(rng.randi() % 1000000, c_madman))
			_btn(out, Rect2(20, 240, 70, 14), func(_b): Net.leave(); screen = "titulo")
		"galeria":
			for k in 4:
				var kk := k
				_btn(out, Rect2(60 + k * 92, 26, 88, 14), func(_b): gallery_tab = kk)
			_btn(out, Rect2(20, 240, 70, 14), func(_b): screen = "titulo")
		"opciones":
			for k in 5:
				var kk := k
				_btn(out, Rect2(130, 70 + k * 18, 220, 16), func(b): _option(kk, b))
			_btn(out, Rect2(20, 240, 70, 14), func(_b): screen = "titulo")
		"controles":
			var keys := Game.LABELS.keys()
			for k in keys.size():
				var a: String = keys[k]
				_btn(out, Rect2(120, 36 + k * 13, 240, 12), func(_b): rebinding = a)
			_btn(out, Rect2(20, 240, 70, 14), func(_b): screen = "opciones")
		"final":
			_btn(out, Rect2(180, 228, 120, 16), func(_b): _to_title())
	return out


func _title_items() -> Array:
	var items := ["Nueva partida"]
	if Game.has_saved_run():
		items.append("Continuar")
	items.append_array(["Cooperativo", "Desbloqueos", "Opciones", "Salir"])
	return items


func _title_pick(item: String) -> void:
	match item:
		"Nueva partida":
			screen = "crear"
		"Continuar":
			var d := Game.load_run()
			if d.is_empty():
				return
			var cfg := {"seed": int(d["seed"]), "madman": d["madman"], "local_peer": 1, "saved": d, "heroes": []}
			for k in d["heroes"]:
				var h: Dictionary = d["heroes"][k]
				cfg["heroes"].append({"peer": int(k), "name": h["name"], "race": h["race"], "hat": h["hat"],
					"companion": h["companion"], "traits": h["traits"], "rolled": {"base": h["base"], "growth": h["growth"]}})
			_begin_run(cfg)
		"Cooperativo":
			screen = "coop"
		"Desbloqueos":
			screen = "galeria"
		"Opciones":
			screen = "opciones"
		"Salir":
			get_tree().quit()


func _cycle_trait(k: int, d: int) -> void:
	var other: int = c_traits[1 - k]
	var v: int = c_traits[k]
	for i in Content.TRAITS.size():
		v = wrapi(v + d, 0, Content.TRAITS.size())
		if v != other:
			break
	c_traits[k] = v


func _option(k: int, button: int) -> void:
	var d := 0.1 if button == MOUSE_BUTTON_LEFT else -0.1
	match k:
		0: Game.settings["sfx"] = clampf(Game.settings["sfx"] + d, 0.0, 1.0)
		1: Game.settings["music"] = clampf(Game.settings["music"] + d, 0.0, 1.0)
		2: Game.settings["fullscreen"] = not Game.settings["fullscreen"]
		3: Game.settings["shake"] = not Game.settings["shake"]
		4: screen = "controles"
	Game.apply_settings()
	Game.save_profile()


# --- Dibujo ----------------------------------------------------------------------------------

func _bg() -> void:
	var c := draw_node
	c.draw_rect(Rect2(0, 0, 480, 270), Color("#0e0a14"))
	for k in 40:
		var x := fmod(k * 53.0 + t * (4.0 + k % 5), 500.0) - 10.0
		var y := fmod(k * 37.0, 270.0)
		c.draw_rect(Rect2(x, y, 1, 1), Color(0.6, 0.9, 0.6, 0.3 + 0.3 * sin(t * 2.0 + k)))
	for k in 12:
		var h := 30.0 + fmod(k * 71.0, 60.0)
		c.draw_rect(Rect2(k * 42 - 6, 0, 28, h), Color("#1a1422"))
		c.draw_rect(Rect2(k * 42 + 4, h, 8, 12), Color("#1a1422"))
	c.draw_rect(Rect2(0, 230, 480, 40), Color("#1a1422"))
	c.draw_rect(Rect2(0, 230, 480, 3), Color("#2e6a2a"))


func _button(r: Rect2, label: String, hl := false, col := COL_TXT) -> void:
	var hov := r.has_point(draw_node.get_local_mouse_position())
	draw_node.draw_rect(r, Color("#3a2e50") if hov or hl else Color("#221c2e"))
	draw_node.draw_rect(r, Color("#6a5a8a"), false, 1.0)
	PixelFont.draw_centered(draw_node, r.get_center().x, r.position.y + (r.size.y - 5) / 2.0, label, col)


func _draw_screen() -> void:
	match screen:
		"titulo": _draw_title()
		"crear": _draw_create()
		"coop": _draw_coop()
		"galeria": _draw_gallery()
		"opciones": _draw_options()
		"controles": _draw_controls()
		"final": _draw_final()


func _draw_title() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 36, "Subterra", COL_GOLD, 5)
	PixelFont.draw_centered(draw_node, 240, 72, "tala, mina, combina y baja más hondo", COL_DIM)
	var f := Art.hero_frame("minero", "run", int(t * 10.0))
	draw_node.draw_texture_rect(f["tex"], Rect2(60, 150, 40, 52), false)
	var items := _title_items()
	for k in items.size():
		_button(Rect2(180, 120 + k * 18, 120, 16), items[k])
	PixelFont.draw(draw_node, Vector2(6, 262), "partidas %d  ·  victorias %d  ·  mejor distrito %d" % [Game.global_stats["runs"], Game.global_stats["wins"], Game.global_stats["best_district"]], COL_DIM)


func _draw_create() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 12, "Nuevo personaje", COL_GOLD, 2)
	var races := _owned_list("race", Content.RACES)
	var hats := _owned_list("hat", Content.HATS)
	var comps := _owned_list("companion", Content.COMPANIONS)
	var race: Dictionary = races[c_race % races.size()]
	var hat: Dictionary = hats[c_hat % hats.size()]
	var comp: Dictionary = comps[c_comp % comps.size()]
	_button(Rect2(170, 34, 120, 12), c_name + ("_" if editing == "nombre" and int(t * 3.0) % 2 == 0 else ""), editing == "nombre")
	PixelFont.draw(draw_node, Vector2(120, 37), "Nombre", COL_DIM)
	for row in [[54, "Raza", race["name"]], [72, "Sombrero", hat["name"]], [90, "Compañero", comp["name"]]]:
		PixelFont.draw(draw_node, Vector2(100, row[0] + 3), row[1], COL_DIM)
		_button(Rect2(150, row[0], 14, 12), "<")
		_button(Rect2(296, row[0], 14, 12), ">")
		PixelFont.draw_centered(draw_node, 230, row[0] + 3, row[2], COL_TXT)
	for k in 2:
		var tr: Dictionary = Content.TRAITS[c_traits[k]]
		PixelFont.draw(draw_node, Vector2(118, 113 + k * 16), "Rasgo %d" % (k + 1), COL_DIM)
		_button(Rect2(170, 110 + k * 16, 140, 13), tr["name"])
		PixelFont.draw(draw_node, Vector2(316, 113 + k * 16), tr["desc"], COL_DIM)
	_button(Rect2(170, 150, 140, 13), "Modo: " + ("DEMENTE" if c_madman else "Normal"), c_madman, Color("#ff7a9a") if c_madman else COL_TXT)
	_button(Rect2(170, 166, 140, 13), "Semilla: " + (c_seed if c_seed != "" else "aleatoria") + ("_" if editing == "semilla" and int(t * 3.0) % 2 == 0 else ""), editing == "semilla")
	# Estadísticas.
	var b: Dictionary = c_rolled["base"]
	var g: Dictionary = c_rolled["growth"]
	var y := 180
	PixelFont.draw(draw_node, Vector2(330, 164), "Estadísticas", COL_GOLD)
	var rs: Dictionary = race["stats"]
	var x := 170
	for pair in [["Vida", "hp"], ["Ataque", "atk"], ["Destreza", "dex"], ["Magia", "mag"]]:
		var gc = [Color("#e05a5a"), COL_TXT, Color("#6ae05a")][g[pair[1]]]
		var v: int = b[pair[1]] + int(rs.get(pair[1], 0))
		PixelFont.draw(draw_node, Vector2(x, 196), "%s %d" % [pair[0], v], gc)
		x += 50
	_button(Rect2(330, 176, 70, 13), "Volver a tirar")
	PixelFont.draw(draw_node, Vector2(170, 206), "verde: crece rápido  ·  rojo: crece despacio", COL_DIM)
	# Vista previa.
	var f := Art.hero_frame(race["id"], "run", int(t * 10.0))
	draw_node.draw_texture_rect(f["tex"], Rect2(30, 70, 60, 78), false)
	var ht = Art.hat(hat["id"])
	if ht:
		var hd: Vector2i = f["head"]
		draw_node.draw_texture_rect(ht, Rect2(30 + (hd.x - 7 + 1) * 3.0, 70 + (hd.y - 9) * 3.0, 42, 36), false)
	var cp = Art.companion(comp["id"], int(t * 6.0))
	if cp:
		draw_node.draw_texture_rect(cp, Rect2(88, 60 + sin(t * 3.0) * 4.0, 24, 24), false)
	PixelFont.draw_centered(draw_node, 60, 156, PixelFont.wrap(race["desc"], 24), COL_DIM)
	var items: Array = race["items"]
	PixelFont.draw_centered(draw_node, 60, 205, "Empieza con:", COL_GOLD)
	for i in items.size():
		draw_node.draw_texture(Art.icon(items[i]), Vector2(60 - items.size() * 7 + i * 14, 213))
	PixelFont.draw(draw_node, Vector2(330, 54), PixelFont.wrap(hat["desc"], 32), Color("#c0b8f0"))
	PixelFont.draw(draw_node, Vector2(330, 90), PixelFont.wrap(comp["desc"], 32), Color("#c0f0b8"))
	_button(Rect2(180, 226, 120, 18), "¡Bajar a Hondura!", false, COL_GOLD)
	_button(Rect2(20, 240, 70, 14), "Volver")


func _draw_coop() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 20, "Cooperativo online", COL_GOLD, 2)
	PixelFont.draw_centered(draw_node, 240, 44, "Hasta 4 jugadores. Usa el personaje de la pantalla de creación.", COL_DIM)
	_button(Rect2(120, 70, 110, 16), "Crear partida")
	_button(Rect2(250, 70, 110, 16), "IP: " + coop_ip + ("_" if editing == "ip" and int(t * 3.0) % 2 == 0 else ""), editing == "ip")
	_button(Rect2(250, 90, 110, 16), "Unirse")
	PixelFont.draw_centered(draw_node, 240, 118, Net.status_text(), Color("#8aff9a"))
	var y := 134
	for p in Net.lobby_list():
		PixelFont.draw_centered(draw_node, 240, y, "%s  ·  %s" % [p["name"], Content.race(p["race"])["name"]], COL_TXT)
		y += 10
	if Net.is_host():
		_button(Rect2(180, 220, 120, 16), "Empezar", false, COL_GOLD)
	_button(Rect2(20, 240, 70, 14), "Volver")


func _draw_gallery() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 10, "Desbloqueos", COL_GOLD, 2)
	var tabs := ["Razas", "Sombreros", "Compañeros", "Estadísticas"]
	for k in 4:
		_button(Rect2(60 + k * 92, 26, 88, 14), tabs[k], gallery_tab == k)
	var mp := draw_node.get_local_mouse_position()
	if gallery_tab == 3:
		var y := 60
		for k in Game.global_stats:
			PixelFont.draw_centered(draw_node, 240, y, "%s: %s" % [k, Game.global_stats[k]], COL_TXT)
			y += 12
		PixelFont.draw_centered(draw_node, 240, y + 8, "Recetas descubiertas: %d de %d" % [Game.known_recipes().size(), Recipes.pairs().size()], COL_GOLD)
		_button(Rect2(20, 240, 70, 14), "Volver")
		return
	var list: Array = [Content.RACES, Content.HATS, Content.COMPANIONS][gallery_tab]
	var kind: String = ["race", "hat", "companion"][gallery_tab]
	var tip := ""
	for i in list.size():
		var e: Dictionary = list[i]
		var r := Rect2(24 + (i % 9) * 48, 48 + (i / 9) * 56, 44, 52)
		var own := Game.is_owned(kind, e["id"])
		draw_node.draw_rect(r, Color("#221c2e") if own else Color("#140f1a"))
		draw_node.draw_rect(r, Color("#6a5a8a") if own else Color("#3a3048"), false, 1.0)
		var col := Color.WHITE if own else Color(0, 0, 0, 0.9)
		match kind:
			"race":
				draw_node.draw_texture(Art.hero_frame(e["id"], "idle", int(t * 3.0))["tex"], r.position + Vector2(12, 6), col)
			"hat":
				var ht = Art.hat(e["id"])
				if ht:
					draw_node.draw_texture_rect(ht, Rect2(r.position + Vector2(8, 8), Vector2(28, 24)), false, col)
			"companion":
				var cp = Art.companion(e["id"], int(t * 6.0))
				if cp:
					draw_node.draw_texture_rect(cp, Rect2(r.position + Vector2(10, 8), Vector2(24, 24)), false, col)
		PixelFont.draw_centered(draw_node, r.get_center().x, r.end.y - 10, e["name"].substr(0, 10), COL_TXT if own else COL_DIM)
		if r.has_point(mp):
			tip = e.get("desc", "")
			if not own:
				tip = "Bloqueado: " + e["unlock"].get("text", "?")
	if tip != "":
		PixelFont.draw_centered(draw_node, 240, 222, PixelFont.wrap(tip, 80), Color("#fff08a"))
	_button(Rect2(20, 240, 70, 14), "Volver")


func _draw_options() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 36, "Opciones", COL_GOLD, 2)
	var items := ["Efectos  %d%%" % int(Game.settings["sfx"] * 100), "Música  %d%%" % int(Game.settings["music"] * 100),
		"Pantalla completa: %s" % ("sí" if Game.settings["fullscreen"] else "no"),
		"Temblor de pantalla: %s" % ("sí" if Game.settings["shake"] else "no"), "Controles"]
	for k in items.size():
		_button(Rect2(130, 70 + k * 18, 220, 16), items[k])
	PixelFont.draw_centered(draw_node, 240, 170, "Clic izquierdo sube, derecho baja", COL_DIM)
	_button(Rect2(20, 240, 70, 14), "Volver")


func _draw_controls() -> void:
	_bg()
	PixelFont.draw_centered(draw_node, 240, 16, "Controles", COL_GOLD, 2)
	var keys := Game.LABELS.keys()
	for k in keys.size():
		var r := Rect2(120, 36 + k * 13, 240, 12)
		var a: String = keys[k]
		draw_node.draw_rect(r, Color("#3a2e50") if r.has_point(draw_node.get_local_mouse_position()) else Color("#1e1828"))
		PixelFont.draw(draw_node, r.position + Vector2(4, 4), Game.LABELS[a], COL_TXT)
		var kl := "..." if rebinding == a else Game.key_label(a)
		PixelFont.draw(draw_node, r.position + Vector2(r.size.x - PixelFont.width(kl) - 4, 4), kl, COL_GOLD)
	PixelFont.draw_centered(draw_node, 240, 226, "Ratón: apuntar y usar  ·  1-8 / rueda: barra rápida", COL_DIM)
	_button(Rect2(20, 240, 70, 14), "Volver")


func _draw_final() -> void:
	_bg()
	var won: bool = result.get("won", false)
	PixelFont.draw_centered(draw_node, 240, 24, "¡La Ceniza ha caído!" if won else "Fin de la partida", COL_GOLD if won else Color("#ff7a7a"), 3)
	if won:
		PixelFont.draw_centered(draw_node, 240, 54, PixelFont.wrap("El Muro de Ceniza se desmorona. Por primera vez en generaciones, una brisa de la Superficie baja hasta Hondura.", 70), COL_TXT)
	var secs := int(result.get("time", 0.0))
	PixelFont.draw_centered(draw_node, 240, 80, "Distrito %d  ·  tiempo %d:%02d  ·  semilla %d%s" % [result.get("district", 1), secs / 60, secs % 60, result.get("seed", 0), "  ·  demente" if result.get("madman", false) else ""], COL_DIM)
	var y := 96
	for h in result.get("heroes", []):
		var line := "%s (%s) nivel %d, %d enemigos" % [h["name"], Content.race(h["race"])["name"], h["level"], h["kills"]]
		if not won and h.get("cause", "") != "":
			var cn: String = Content.enemy(h["cause"]).get("name", h["cause"])
			line += "  ·  cayó ante: " + cn
		PixelFont.draw_centered(draw_node, 240, y, line, COL_TXT)
		y += 10
	var unl: Array = result.get("unlocks", [])
	if not unl.is_empty():
		PixelFont.draw_centered(draw_node, 240, y + 10, "¡Desbloqueado!", Color("#8aff9a"), 2)
		y += 26
		for u in unl:
			var kn = {"race": "Raza", "hat": "Sombrero", "companion": "Compañero"}[u["kind"]]
			PixelFont.draw_centered(draw_node, 240, y, "%s: %s" % [kn, u["name"]], Color("#c8ffd0"))
			y += 10
	_button(Rect2(180, 228, 120, 16), "Menú principal")


func _anim_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	_start_single(4242)
	await get_tree().create_timer(0.8).timeout
	var h: Hero = game_ui.local_hero()
	h.is_local = false
	run.world.god_mode = true
	h.model.inv.slots[1] = Inventory.make("espada_hierro", 1)
	h.model.inv.slots[2] = Inventory.make("baston_fuego", 1)
	h.model.mana = 20
	for k in ["limo_verde", "arana_verde", "jabali", "avispa", "cerdo"]:
		run.world.spawn_enemy(k, h.position + Vector2(90 + ["limo_verde", "arana_verde", "jabali", "avispa", "cerdo"].find(k) * 30, -10))
	# Secuencia: correr, golpear con espada, saltar, lanzar bola de fuego.
	var plan := []
	for i in 4:
		plan.append({"move": Vector2(1, 0)})
	for i in 4:
		plan.append({"hot": 1, "use": true})
	for i in 4:
		plan.append({"jump": true, "move": Vector2(0.5, 0)})
	for i in 4:
		plan.append({"hot": 2, "use": true})
	for i in plan.size():
		var st: Dictionary = plan[i]
		var inp := InputState.new()
		inp.move = st.get("move", Vector2.ZERO)
		inp.jump = st.get("jump", false)
		inp.jump_pressed = st.get("jump", false) and i % 4 == 0
		inp.use = st.get("use", false)
		inp.use_pressed = inp.use
		inp.hotbar = st.get("hot", -1)
		inp.aim = h.center() + Vector2(60, -4)
		run.remote_inputs[h.peer_id] = inp
		await get_tree().create_timer(0.07).timeout
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var sp: Vector2 = (h.position - run.world.camera.get_screen_center_position() + Vector2(160, 90)) * 3.0
		var r := Rect2i(int(sp.x) - 120, int(sp.y) - 120, 240, 150).intersection(Rect2i(0, 0, 960, 540))
		img.get_region(r).save_png(ProjectSettings.globalize_path("res://shots/anim_%02d.png" % i))
	get_tree().quit()


# --- Prueba de red (desarrollo) ----------------------------------------------------------------

func _net_test(as_host: bool) -> void:
	c_name = "Anfitrion" if as_host else "Cliente"
	if as_host:
		Net.host(7788, _hero_config(1))
		while Net.lobby.size() < 2:
			await get_tree().create_timer(0.2).timeout
		Net.start(777, false)
	else:
		Net.join("127.0.0.1", 7788, _hero_config(0))
	while run == null:
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(4.0).timeout
	var w: World = run.world
	print("NETTEST ", "host" if as_host else "client", " jugadores=", w.players.size(), " enemigos=", w.enemies.size(),
		" pos=", w.players.map(func(p): return p.position.round()), " biome=", w.biome)
	if as_host:
		run.choose_door(w.npcs.filter(func(n): return n.kind == "puerta")[0].biome)
		await get_tree().create_timer(2.0).timeout
		print("NETTEST host estado=", run.state)
	else:
		await get_tree().create_timer(2.0).timeout
		print("NETTEST client estado=", run.state, " pueblo=", run.world.is_town)
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


# --- Capturas automáticas (desarrollo) ----------------------------------------------------------

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	await _shot("00_titulo", 0.5)
	screen = "crear"
	await _shot("01_crear", 0.3)
	_start_single(4242)
	await _shot("02_bosque", 1.5)
	var hh: Hero = game_ui.local_hero()
	for k in ["limo_verde", "arana_verde", "jabali", "avispa", "cerdo"]:
		run.world.spawn_enemy(k, hh.position + Vector2(40 + ["limo_verde", "arana_verde", "jabali", "avispa", "cerdo"].find(k) * 26, -20))
	run.world.god_mode = true
	hh.model.inv.slots[1] = Inventory.make("baston_fuego", 1)
	hh.model.mana = 5
	hh.model.inv.hand = 1
	hh._cast("bola_fuego", 1.0)
	await _shot("02b_combate", 0.35)
	var h: Hero = game_ui.local_hero()
	h.model.inv.add(Inventory.make("madera", 10))
	h.model.inv.add(Inventory.make("espada_hierro", 1))
	game_ui.toggle_inventory()
	await _shot("03_inventario", 0.3)
	game_ui.close()
	run.district = 6
	run.enter_district("mazmorra")
	await _shot("04_mazmorra", 1.5)
	for b in ["volcan", "tundra", "cantera", "crater", "cienaga", "pradera", "cavernas"]:
		run.enter_district(b)
		await _shot("05_" + b, 1.0)
	run.enter_town("tundra")
	await _shot("06_pueblo", 1.0)
	Console.open = true
	Console.show_stats = true
	for c in ["info", "give espada_oro 1", "spawn limo_verde 2", "coins 500", "list biomes"]:
		Console.log_line("> " + c, Color("#fff08a"))
		Console.exec(c)
	Console.input = "spawn ara"
	await _shot("06b_consola", 0.4)
	Console.open = false
	Console.show_stats = false
	run.district = 21
	run.enter_district("nido")
	await _shot("07_nido", 1.5)
	get_tree().quit()


func _shot(name: String, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/%s.png" % name))
