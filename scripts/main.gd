extends Node
## Escena principal: título, creación de personaje, cooperativo, desbloqueos, opciones y final.
##
## La interfaz (480x270 lógicos, capa a escala x2) se dibuja a resolución nativa: texto y
## formas nítidas. El mundo va en el SubViewport de Run (320x180 x3), con píxel uniforme.

const BACK_BTN := Rect2(14, 242, 76, 18)
const CR_LEFT := Rect2(14, 42, 128, 188)
const CR_FORM := Rect2(150, 42, 186, 188)
const CR_INFO := Rect2(344, 42, 122, 188)
const CR_ROWS := ["nombre", "raza", "sombrero", "companero", "rasgo1", "rasgo2", "modo", "semilla"]
const CR_LABELS := {"nombre": "Nombre", "raza": "Raza", "sombrero": "Sombrero", "companero": "Compañero",
	"rasgo1": "Rasgo 1", "rasgo2": "Rasgo 2", "modo": "Modo", "semilla": "Semilla"}
const STAT_NAMES := {"runs": "Partidas jugadas", "wins": "Victorias", "kills": "Enemigos derrotados",
	"golden_chests": "Cofres dorados", "deaths": "Muertes", "best_district": "Mejor distrito"}

var screen := "titulo"      # titulo, crear, coop, galeria, opciones, controles, final, juego
var backdrop: TitleBackdrop
var logo_back: Node2D
var logo_fill: Node2D
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
var c_focus := "raza"
var editing := ""            # "nombre", "semilla", "ip"
var rng := RandomNumberGenerator.new()
var gallery_tab := 0
var rebinding := ""
var coop_ip := "127.0.0.1"
var title_sel := 0
var title_mouse := Vector2(-1, -1)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	Console.main = self
	c_rolled = HeroModel.roll_stats(rng)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 30
	ui_layer.scale = Vector2(2, 2)
	add_child(ui_layer)
	backdrop = TitleBackdrop.new()
	ui_layer.add_child(backdrop)
	logo_back = Node2D.new()
	logo_back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	logo_back.draw.connect(_draw_logo_back)
	ui_layer.add_child(logo_back)
	logo_fill = Node2D.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/logo.gdshader")
	logo_fill.material = mat
	logo_fill.draw.connect(_draw_logo_fill)
	ui_layer.add_child(logo_fill)
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
	if "--ui-audit" in args:
		_ui_audit.call_deferred()
	if "--chop-test" in args:
		_chop_test.call_deferred()
	if "--anim-test" in args:
		_anim_test.call_deferred()
	if "--host-test" in args:
		_net_test(true)
	if "--join-test" in args:
		_net_test(false)


func _process(dt: float) -> void:
	t += dt
	var menus := screen != "juego"
	backdrop.visible = menus
	backdrop.set_dimmed(screen != "titulo")
	logo_back.visible = screen == "titulo"
	logo_fill.visible = screen == "titulo"
	draw_node.visible = menus
	if menus:
		draw_node.queue_redraw()
		logo_back.queue_redraw()
		logo_fill.queue_redraw()


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


func _end_world() -> void:
	if run:
		run.queue_free()
		run = null
	if game_ui:
		game_ui.queue_free()
		game_ui = null


func _on_run_end(r: Dictionary) -> void:
	result = r
	await get_tree().create_timer(1.0).timeout
	screen = "final"
	if r["won"]:
		Sfx.play("victoria")
	_end_world()


func _to_title() -> void:
	_end_world()
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
	# Portada: también con teclado (flechas / W S y Enter o Espacio).
	if screen == "titulo" and ev is InputEventKey and ev.pressed and not ev.echo:
		var n := _title_items().size()
		match ev.keycode:
			KEY_UP, KEY_W:
				title_sel = wrapi(title_sel - 1, 0, n)
				Sfx.play("menu")
			KEY_DOWN, KEY_S:
				title_sel = wrapi(title_sel + 1, 0, n)
				Sfx.play("menu")
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				Sfx.play("menu")
				_title_pick(_title_items()[title_sel])
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
				_btn(out, _title_rect(k), func(_b): _title_pick(item))
		"crear":
			var races := _owned_list("race", Content.RACES)
			var hats := _owned_list("hat", Content.HATS)
			var comps := _owned_list("companion", Content.COMPANIONS)
			for id in CR_ROWS:
				var row := _cr_row(id)
				match id:
					"nombre": _btn(out, _cr_ctrl(row), func(_b): editing = "nombre"; c_focus = "nombre")
					"semilla": _btn(out, _cr_ctrl(row), func(_b): editing = "semilla"; c_focus = "semilla")
					"modo": _btn(out, _cr_ctrl(row), func(_b): c_madman = not c_madman; c_focus = "modo")
					_:
						var step := func(d: int) -> void:
							c_focus = id
							match id:
								"raza": c_race = wrapi(c_race + d, 0, races.size())
								"sombrero": c_hat = wrapi(c_hat + d, 0, hats.size())
								"companero": c_comp = wrapi(c_comp + d, 0, comps.size())
								"rasgo1": _cycle_trait(0, d)
								"rasgo2": _cycle_trait(1, d)
						_btn(out, _cr_arrow(row, -1), func(_b): step.call(-1))
						_btn(out, _cr_arrow(row, 1), func(_b): step.call(1))
						_btn(out, _cr_value(row), func(b): step.call(1 if b == MOUSE_BUTTON_LEFT else -1))
			_btn(out, _cr_reroll(), func(_b): c_rolled = HeroModel.roll_stats(rng))
			_btn(out, _cr_start(), func(_b): _start_single(int(c_seed) if c_seed != "" else rng.randi() % 1000000))
			_btn(out, BACK_BTN, func(_b): screen = "titulo")
		"coop":
			_btn(out, Rect2(72, 118, 146, 18), func(_b): Net.host(7777, _hero_config(1)))
			_btn(out, Rect2(262, 96, 146, 16), func(_b): editing = "ip")
			_btn(out, Rect2(262, 118, 146, 18), func(_b): Net.join(coop_ip, 7777, _hero_config(0)))
			if Net.is_host():
				_btn(out, Rect2(336, 242, 130, 18), func(_b): Net.start(rng.randi() % 1000000, c_madman))
			_btn(out, BACK_BTN, func(_b): Net.leave(); screen = "titulo")
		"galeria":
			for k in 4:
				var kk := k
				_btn(out, _tab_rect(k), func(_b): gallery_tab = kk)
			_btn(out, BACK_BTN, func(_b): screen = "titulo")
		"opciones":
			var rows := Menus.option_rows()
			for k in rows.size():
				var kk := k
				_btn(out, rows[k], func(b): _option_click(kk, b))
			_btn(out, BACK_BTN, func(_b): screen = "titulo")
		"controles":
			for e in Menus.control_rows():
				var a: String = e["a"]
				_btn(out, e["r"], func(_b): rebinding = a)
			_btn(out, BACK_BTN, func(_b): screen = "opciones")
		"final":
			_btn(out, Rect2(170, 242, 140, 18), func(_b): _to_title())
	return out


func _title_items() -> Array:
	var items := ["Nueva partida"]
	if Game.has_saved_run():
		items.append("Continuar")
	items.append_array(["Cooperativo", "Desbloqueos", "Opciones", "Salir"])
	return items


func _title_rect(k: int) -> Rect2:
	return Rect2(170, 128 + k * 18, 140, 16)


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


func _option_click(k: int, button: int) -> void:
	if Menus.option_click(k, button, _mouse()):
		screen = "controles"


func _cycle_trait(k: int, d: int) -> void:
	var other: int = c_traits[1 - k]
	var v: int = c_traits[k]
	for i in Content.TRAITS.size():
		v = wrapi(v + d, 0, Content.TRAITS.size())
		if v != other:
			break
	c_traits[k] = v


# --- Geometría de la creación de personaje ------------------------------------------------------

func _cr_row(id: String) -> Rect2:
	var k := CR_ROWS.find(id)
	return Rect2(CR_FORM.position.x + 8, CR_FORM.position.y + 26 + k * 19.5, CR_FORM.size.x - 16, 16)

func _cr_ctrl(row: Rect2) -> Rect2:
	return Rect2(row.position.x + 58, row.position.y, row.size.x - 58, row.size.y)

func _cr_arrow(row: Rect2, dir: int) -> Rect2:
	var c := _cr_ctrl(row)
	return Rect2(c.position.x if dir < 0 else c.end.x - 15, c.position.y, 15, c.size.y)

func _cr_value(row: Rect2) -> Rect2:
	var c := _cr_ctrl(row)
	return Rect2(c.position.x + 17, c.position.y, c.size.x - 34, c.size.y)

func _cr_reroll() -> Rect2:
	return Rect2(CR_INFO.position.x + 8, CR_INFO.end.y - 24, CR_INFO.size.x - 16, 16)

func _cr_start() -> Rect2:
	return Rect2(326, 242, 140, 18)

func _tab_rect(k: int) -> Rect2:
	return Rect2(48 + k * 98, 38, 92, 16)


# --- Dibujo ----------------------------------------------------------------------------------

func _mouse() -> Vector2:
	return draw_node.get_local_mouse_position()


func _heading(s: String, y: float = 10.0) -> void:
	UiKit.text(draw_node, Vector2(240, y), s, UiKit.H, UiKit.YELLOW, 1, {"kind": "display", "shadow": true, "max_w": 440})
	UiKit.ornament(draw_node, Vector2(240, y + UiKit.line_h(UiKit.H, "display") + 3), 70, Color(UiKit.GOLD, 0.8))


func _back_button() -> void:
	UiKit.button(draw_node, BACK_BTN, "‹  Volver", BACK_BTN.has_point(_mouse()))


func _draw_screen() -> void:
	match screen:
		"titulo": _draw_title()
		"crear": _draw_create()
		"coop": _draw_coop()
		"galeria": _draw_gallery()
		"opciones":
			Menus.draw_options(draw_node, _mouse())
			_back_button()
		"controles":
			Menus.draw_controls(draw_node, _mouse(), rebinding)
			_back_button()
		"final": _draw_final()


## Dibuja un fotograma de personaje con los pies en `feet` y la escala dada.
func _draw_frame(f: Dictionary, feet: Vector2, s: int) -> void:
	var tex: Texture2D = f["tex"]
	var og: Vector2 = Vector2(f.get("origin", Vector2i(7, 18)))
	draw_node.draw_texture_rect(tex, Rect2(feet - og * s, tex.get_size() * s), false)


# Logotipo: halo, sombra y contorno (capa de atrás) + relleno dorado con shader (delante).
const LOGO := "SUBTERRA"
const LOGO_SIZE := 46
const LOGO_SPACING := 3.0
const LOGO_Y := 34.0


func _logo_opts(extra: Dictionary) -> Dictionary:
	var o := {"kind": "display", "spacing": LOGO_SPACING, "no_audit": true}
	o.merge(extra, true)
	return o


func _draw_logo_back() -> void:
	var c := logo_back
	var breathe := 0.85 + 0.15 * sin(t * 1.3)
	UiKit.glow(c, Vector2(240, LOGO_Y + 26), 170.0, Color(0.98, 0.78, 0.25, 0.16 * breathe))
	UiKit.glow(c, Vector2(240, LOGO_Y + 26), 90.0, Color(0.7, 0.95, 0.4, 0.10 * breathe))
	UiKit.text(c, Vector2(240, LOGO_Y + 2.2), LOGO, LOGO_SIZE, Color(0, 0.02, 0.01, 0.55), 1, _logo_opts({}))
	UiKit.text(c, Vector2(240, LOGO_Y), LOGO, LOGO_SIZE, Color("#0c2a16"), 1, _logo_opts({"outline": 4, "outline_col": Color("#0c2a16")}))


func _draw_logo_fill() -> void:
	var r := UiKit.text(logo_fill, Vector2(240, LOGO_Y), LOGO, LOGO_SIZE, Color.WHITE, 1, _logo_opts({"no_audit": false}))
	var f := UiKit.font("display")
	var mat: ShaderMaterial = logo_fill.material
	var base := r.position.y + f.get_ascent(UiKit.px(LOGO_SIZE))
	mat.set_shader_parameter("y_top", base - f.get_ascent(UiKit.px(LOGO_SIZE)) * 0.72)
	mat.set_shader_parameter("y_bot", base)
	mat.set_shader_parameter("shine_x", lerpf(r.position.x - 80.0, r.end.x + 160.0, fmod(t * 0.22, 1.0)))


func _draw_title() -> void:
	var c := draw_node
	var m := _mouse()
	var logo_bottom := LOGO_Y + UiKit.line_h(LOGO_SIZE, "display")
	UiKit.ornament(c, Vector2(240, logo_bottom + 4), 96, Color(UiKit.GOLD, 0.85))
	UiKit.text(c, Vector2(240, logo_bottom + 10), "TALA  ·  MINA  ·  COMBINA  ·  DESCIENDE", UiKit.S, UiKit.LIME, 1, {"spacing": 0.8, "shadow": true})
	var items := _title_items()
	if m != title_mouse:
		title_mouse = m
		for k in items.size():
			if _title_rect(k).has_point(m):
				title_sel = k
	title_sel = clampi(title_sel, 0, items.size() - 1)
	for k in items.size():
		var r := _title_rect(k)
		var on := k == title_sel
		var ty := r.position.y + (r.size.y - UiKit.line_h(UiKit.L, "bold")) / 2.0
		if on:
			UiKit.box(c, r, Color(UiKit.GOLD, 0.10), Color(UiKit.GOLD, 0.35), 8)
			var tw := UiKit.text_w(items[k], UiKit.L, "bold")
			var bob := sin(t * 5.0) * 1.2
			UiKit.diamond(c, Vector2(240 - tw / 2.0 - 9 - bob, r.get_center().y), 2.4, UiKit.YELLOW)
			UiKit.diamond(c, Vector2(240 + tw / 2.0 + 9 + bob, r.get_center().y), 2.4, UiKit.YELLOW)
		UiKit.text(c, Vector2(240, ty), items[k], UiKit.L, UiKit.YELLOW if on else UiKit.TEXT, 1, {"kind": "bold", "shadow": true})
	# Pie: estadísticas globales en fichas.
	var chips := ["Partidas  %d" % Game.global_stats["runs"], "Victorias  %d" % Game.global_stats["wins"],
		"Mejor distrito  %d" % Game.global_stats["best_district"]]
	var widths := chips.map(func(s): return UiKit.text_w(s, UiKit.S) + 14.0)
	var total: float = widths.reduce(func(a, b): return a + b, 0.0) + 8.0 * (chips.size() - 1)
	var x := 240.0 - total / 2.0
	for i in chips.size():
		var r2 := Rect2(x, 248, widths[i], 13)
		UiKit.box(c, r2, Color(UiKit.INK, 0.55), Color(UiKit.LINE, 0.8), 6)
		UiKit.text(c, Vector2(r2.get_center().x, r2.position.y + (13 - UiKit.line_h(UiKit.S)) / 2.0), chips[i], UiKit.S, UiKit.TEXT_DIM, 1)
		x += widths[i] + 8.0


func _draw_create() -> void:
	var c := draw_node
	var m := _mouse()
	var races := _owned_list("race", Content.RACES)
	var hats := _owned_list("hat", Content.HATS)
	var comps := _owned_list("companion", Content.COMPANIONS)
	var race: Dictionary = races[c_race % races.size()]
	var hat: Dictionary = hats[c_hat % hats.size()]
	var comp: Dictionary = comps[c_comp % comps.size()]
	_heading("Nuevo personaje", 6)
	# --- Tarjeta izquierda: vista previa y raza.
	UiKit.panel(c, CR_LEFT)
	var pv := Rect2(CR_LEFT.position.x + 8, CR_LEFT.position.y + 8, CR_LEFT.size.x - 16, 86)
	UiKit.box(c, pv, Color(UiKit.BG_DEEP, 0.7), Color(UiKit.LINE, 0.6), 4)
	var f := Art.hero_frame(race["id"], "run", int(t * 10.0))
	var feet := Vector2(pv.get_center().x, pv.end.y - 6)
	_draw_frame(f, feet, 3)
	var ht = Art.hat(hat["id"])
	if ht:
		var hp: Vector2 = feet + (Vector2(f["head"]) - Vector2(f["origin"]) + Vector2(-6, -10)) * 3.0
		c.draw_texture_rect(ht, Rect2(hp, ht.get_size() * 3.0), false)
	var cp = Art.companion(comp["id"], int(t * 6.0))
	if cp:
		c.draw_texture_rect(cp, Rect2(Vector2(pv.end.x - 30, pv.position.y + 10 + sin(t * 3.0) * 3.0), Vector2(24, 24)), false)
	var y := pv.end.y + 5
	UiKit.text(c, Vector2(CR_LEFT.get_center().x, y), race["name"], UiKit.M, UiKit.YELLOW, 1, {"kind": "bold", "max_w": pv.size.x})
	y += UiKit.line_h(UiKit.M) + 3
	var items: Array = race["items"]
	var icons_y := CR_LEFT.end.y - 20
	UiKit.paragraph(c, Rect2(pv.position.x, y, pv.size.x, icons_y - 14 - y), race["desc"], UiKit.S, UiKit.TEXT_DIM, 1)
	UiKit.text(c, Vector2(CR_LEFT.get_center().x, icons_y - 11), "EMPIEZA CON", UiKit.XS, UiKit.TEXT_MUTE, 1, {"kind": "bold", "spacing": 0.6})
	for i in items.size():
		var ip := Vector2(CR_LEFT.get_center().x - items.size() * 8 + i * 16 + 2, icons_y)
		UiKit.box(c, Rect2(ip - Vector2(1, 1), Vector2(14, 14)), Color(UiKit.BG_DEEP, 0.7), Color(0, 0, 0, 0), 2)
		c.draw_texture(Art.icon(items[i]), ip)
	# --- Formulario central.
	UiKit.panel(c, CR_FORM, "Personaje")
	for id in CR_ROWS:
		var row := _cr_row(id)
		var ctrl := _cr_ctrl(row)
		var hov := row.has_point(m)
		if hov:
			c_focus = id
		var ly := row.position.y + (row.size.y - UiKit.line_h(UiKit.S)) / 2.0
		UiKit.text(c, Vector2(row.position.x, ly), CR_LABELS[id], UiKit.S, UiKit.YELLOW if c_focus == id else UiKit.TEXT_DIM, 0, {"max_w": 56})
		match id:
			"nombre", "semilla":
				var val: String = c_name if id == "nombre" else (c_seed if c_seed != "" else "aleatoria")
				var ed: bool = editing == id
				UiKit.box(c, ctrl, Color(UiKit.BG_DEEP, 0.8), UiKit.LIME if ed else (UiKit.LINE_HI if ctrl.has_point(m) else UiKit.LINE), 3)
				var r := UiKit.text(c, Vector2(ctrl.position.x + 6, ctrl.position.y + (ctrl.size.y - UiKit.line_h(UiKit.M)) / 2.0), val,
					UiKit.M, UiKit.TEXT if (id == "nombre" or c_seed != "") else UiKit.TEXT_MUTE, 0, {"max_w": ctrl.size.x - 14})
				if ed and int(t * 2.5) % 2 == 0:
					c.draw_rect(Rect2(r.end.x + 1, ctrl.position.y + 4, 0.8, ctrl.size.y - 8), UiKit.YELLOW)
			"modo":
				UiKit.button(c, ctrl, "Demente" if c_madman else "Normal", ctrl.has_point(m),
					{"sel": c_madman, "col": Color("#ff8aa8") if c_madman else UiKit.TEXT, "size": UiKit.S})
			_:
				var val2 := ""
				match id:
					"raza": val2 = race["name"]
					"sombrero": val2 = hat["name"]
					"companero": val2 = comp["name"]
					"rasgo1": val2 = Content.TRAITS[c_traits[0]]["name"]
					"rasgo2": val2 = Content.TRAITS[c_traits[1]]["name"]
				UiKit.box(c, ctrl, Color(UiKit.BG_DEEP, 0.55), Color(UiKit.LINE, 0.7), 3)
				for dir in [-1, 1]:
					var ar := _cr_arrow(row, dir)
					var ah := ar.has_point(m)
					UiKit.box(c, ar, UiKit.PANEL_SEL if ah else UiKit.PANEL_HI, UiKit.LINE_HI if ah else UiKit.LINE, 3)
					UiKit.text(c, Vector2(ar.get_center().x, ar.position.y + (ar.size.y - UiKit.line_h(UiKit.M, "bold")) / 2.0 - 0.5),
						"‹" if dir < 0 else "›", UiKit.M, UiKit.YELLOW if ah else UiKit.TEXT, 1, {"kind": "bold"})
				var vr := _cr_value(row)
				UiKit.text(c, Vector2(vr.get_center().x, vr.position.y + (vr.size.y - UiKit.line_h(UiKit.S)) / 2.0), val2,
					UiKit.S, UiKit.TEXT, 1, {"max_w": vr.size.x - 4, "min_size": UiKit.XS})
	# --- Panel derecho: detalles del campo enfocado y estadísticas.
	UiKit.panel(c, CR_INFO)
	var ix := CR_INFO.position.x + 8
	var iw := CR_INFO.size.x - 16
	var info := _focus_info(race, hat, comp)
	y = CR_INFO.position.y + 8
	UiKit.text(c, Vector2(ix, y), info[0].to_upper(), UiKit.XS, UiKit.TEXT_MUTE, 0, {"kind": "bold", "spacing": 0.6, "max_w": iw})
	y += UiKit.line_h(UiKit.XS) + 1
	UiKit.text(c, Vector2(ix, y), info[1], UiKit.M, UiKit.YELLOW, 0, {"kind": "bold", "max_w": iw})
	y += UiKit.line_h(UiKit.M) + 2
	var stats_y := CR_INFO.position.y + 94
	UiKit.paragraph(c, Rect2(ix, y, iw, stats_y - 6 - y), info[2], UiKit.S, UiKit.TEXT_DIM)
	c.draw_rect(Rect2(ix, stats_y - 3, iw, 0.6), Color(UiKit.LINE_HI, 0.6))
	UiKit.text(c, Vector2(ix, stats_y), "Estadísticas", UiKit.S, UiKit.LIME, 0, {"kind": "bold"})
	var b: Dictionary = c_rolled["base"]
	var g: Dictionary = c_rolled["growth"]
	var rs: Dictionary = race["stats"]
	y = stats_y + UiKit.line_h(UiKit.S) + 2
	for pair in [["Vida", "hp"], ["Ataque", "atk"], ["Destreza", "dex"], ["Magia", "mag"]]:
		var gi: int = g[pair[1]]
		var v: int = b[pair[1]] + int(rs.get(pair[1], 0))
		UiKit.text(c, Vector2(ix, y), pair[0], UiKit.S, UiKit.TEXT, 0)
		var vr2 := UiKit.text(c, Vector2(ix + iw - 10, y), str(v), UiKit.S, UiKit.TEXT, 2, {"kind": "bold"})
		_growth_arrow(Vector2(ix + iw - 4, vr2.get_center().y), gi)
		y += UiKit.line_h(UiKit.S) + 1.5
	_growth_arrow(Vector2(ix + 3, y + 4.5), 2)
	var lr := UiKit.text(c, Vector2(ix + 8, y), "rápido", UiKit.XS, UiKit.TEXT_MUTE, 0)
	_growth_arrow(Vector2(lr.end.x + 7, y + 4.5), 0)
	UiKit.text(c, Vector2(lr.end.x + 12, y), "lento", UiKit.XS, UiKit.TEXT_MUTE, 0)
	UiKit.button(c, _cr_reroll(), "Volver a tirar", _cr_reroll().has_point(m), {"size": UiKit.S})
	# --- Botones inferiores.
	_back_button()
	UiKit.button(c, _cr_start(), "¡Bajar a Hondura!", _cr_start().has_point(m), {"primary": true})


func _growth_arrow(p: Vector2, g: int) -> void:
	if g == 1:
		draw_node.draw_circle(p, 1.2, UiKit.TEXT_MUTE, true, -1.0, true)
		return
	var up := g == 2
	var col := UiKit.GREEN if up else UiKit.RED
	var d := -1.0 if up else 1.0
	draw_node.draw_colored_polygon(PackedVector2Array([p + Vector2(-2.6, -d * 1.6), p + Vector2(2.6, -d * 1.6), p + Vector2(0, d * 2.2)]), col)


## [categoría, nombre, descripción] del campo enfocado en la creación de personaje.
func _focus_info(race: Dictionary, hat: Dictionary, comp: Dictionary) -> Array:
	match c_focus:
		"nombre":
			return ["Nombre", c_name if c_name != "" else "Sin nombre", "Hasta 12 letras. Haz clic en el campo y escribe."]
		"sombrero":
			return ["Sombrero", hat["name"], hat.get("desc", "")]
		"companero":
			return ["Compañero", comp["name"], comp.get("desc", "")]
		"rasgo1", "rasgo2":
			var tr: Dictionary = Content.TRAITS[c_traits[0 if c_focus == "rasgo1" else 1]]
			return ["Rasgo", tr["name"], tr["desc"]]
		"modo":
			if c_madman:
				return ["Modo", "Demente", "Enemigos con un 50 % más de vida y de daño, y grupos más numerosos."]
			return ["Modo", "Normal", "La experiencia equilibrada. Haz clic para cambiar a Demente."]
		"semilla":
			return ["Semilla", c_seed if c_seed != "" else "Aleatoria", "La misma semilla genera los mismos distritos. Vacía: una partida nueva."]
	var bonus := []
	for k in race["stats"]:
		var v := int(race["stats"][k])
		if v != 0:
			bonus.append("%s %+d" % [{"hp": "Vida", "atk": "Ataque", "dex": "Destreza", "mag": "Magia"}.get(k, k), v])
	return ["Raza", race["name"], "Sin bonificaciones de estadísticas." if bonus.is_empty() else "Bonificación: " + ", ".join(bonus) + "."]


func _draw_coop() -> void:
	var c := draw_node
	var m := _mouse()
	_heading("Cooperativo online")
	UiKit.paragraph(c, Rect2(80, 46, 320, 24), "Hasta 4 jugadores. Cada uno juega con el personaje de su pantalla de creación.", UiKit.S, UiKit.TEXT_DIM, 1)
	# Tarjeta: crear partida.
	var lc := Rect2(62, 74, 166, 72)
	UiKit.panel(c, lc, "Crear partida")
	UiKit.text(c, Vector2(lc.position.x + 10, lc.position.y + 24), "Serás el anfitrión (puerto 7777).", UiKit.S, UiKit.TEXT_DIM, 0, {"max_w": lc.size.x - 20})
	UiKit.button(c, Rect2(72, 118, 146, 18), "Crear", Rect2(72, 118, 146, 18).has_point(m), {"primary": true})
	# Tarjeta: unirse.
	var rc := Rect2(252, 74, 166, 72)
	UiKit.panel(c, rc, "Unirse")
	var ipr := Rect2(262, 96, 146, 16)
	var ed := editing == "ip"
	UiKit.box(c, ipr, Color(UiKit.BG_DEEP, 0.8), UiKit.LIME if ed else (UiKit.LINE_HI if ipr.has_point(m) else UiKit.LINE), 3)
	var lr := UiKit.text(c, Vector2(ipr.position.x + 6, ipr.position.y + (16 - UiKit.line_h(UiKit.S)) / 2.0), "IP", UiKit.S, UiKit.TEXT_MUTE, 0, {"kind": "bold"})
	var r := UiKit.text(c, Vector2(lr.end.x + 6, ipr.position.y + (16 - UiKit.line_h(UiKit.M)) / 2.0), coop_ip, UiKit.M, UiKit.TEXT, 0, {"max_w": ipr.end.x - lr.end.x - 16})
	if ed and int(t * 2.5) % 2 == 0:
		c.draw_rect(Rect2(r.end.x + 1, ipr.position.y + 4, 0.8, 8), UiKit.YELLOW)
	UiKit.button(c, Rect2(262, 118, 146, 18), "Unirse", Rect2(262, 118, 146, 18).has_point(m))
	# Estado y sala.
	UiKit.text(c, Vector2(240, 156), Net.status_text(), UiKit.M, UiKit.LIME, 1, {"kind": "bold", "max_w": 400})
	var y := 172.0
	for p in Net.lobby_list():
		UiKit.text(c, Vector2(240, y), "%s  ·  %s" % [p["name"], Content.race(p["race"])["name"]], UiKit.S, UiKit.TEXT, 1, {"max_w": 300})
		y += UiKit.line_h(UiKit.S) + 2
	if Net.is_host():
		var sr := Rect2(336, 242, 130, 18)
		UiKit.button(c, sr, "Empezar", sr.has_point(m), {"primary": true})
	_back_button()


func _draw_gallery() -> void:
	var c := draw_node
	var m := _mouse()
	_heading("Desbloqueos", 4)
	var tabs := ["Razas", "Sombreros", "Compañeros", "Estadísticas"]
	for k in 4:
		UiKit.button(c, _tab_rect(k), tabs[k], _tab_rect(k).has_point(m), {"sel": gallery_tab == k, "size": UiKit.S})
	if gallery_tab == 3:
		var pr := Rect2(110, 64, 260, 160)
		UiKit.panel(c, pr)
		var y := pr.position.y + 12
		for k in Game.global_stats:
			UiKit.text(c, Vector2(pr.position.x + 14, y), STAT_NAMES.get(k, k), UiKit.M, UiKit.TEXT_DIM, 0, {"max_w": 170})
			UiKit.text(c, Vector2(pr.end.x - 14, y), str(Game.global_stats[k]), UiKit.M, UiKit.TEXT, 2, {"kind": "bold"})
			y += UiKit.line_h(UiKit.M) + 5
		c.draw_rect(Rect2(pr.position.x + 14, y, pr.size.x - 28, 0.6), Color(UiKit.LINE_HI, 0.6))
		y += 6
		UiKit.text(c, Vector2(pr.position.x + 14, y), "Recetas descubiertas", UiKit.M, UiKit.YELLOW, 0, {"kind": "bold"})
		UiKit.text(c, Vector2(pr.end.x - 14, y), "%d / %d" % [Game.known_recipes().size(), Recipes.pairs().size()], UiKit.M, UiKit.YELLOW, 2, {"kind": "bold"})
		_back_button()
		return
	var list: Array = [Content.RACES, Content.HATS, Content.COMPANIONS][gallery_tab]
	var kind: String = ["race", "hat", "companion"][gallery_tab]
	var tip := ""
	var tip_name := ""
	for i in list.size():
		var e: Dictionary = list[i]
		var r := Rect2(24 + (i % 9) * 48, 62 + (i / 9) * 54, 44, 50)
		var own := Game.is_owned(kind, e["id"])
		var hov := r.has_point(m)
		UiKit.box(c, r, (UiKit.PANEL_SEL if hov else UiKit.PANEL) if own else Color(UiKit.BG_DEEP, 0.9),
			(UiKit.YELLOW if hov else UiKit.LINE) if own else Color(UiKit.LINE, 0.4), 4)
		var col := Color.WHITE if own else Color(0, 0, 0, 0.85)
		match kind:
			"race":
				var gf := Art.hero_frame(e["id"], "idle", int(t * 6.0))
				c.draw_texture(gf["tex"], (r.position + Vector2(22, 31) - Vector2(gf["origin"])).round(), col)
			"hat":
				var ht = Art.hat(e["id"])
				if ht:
					c.draw_texture_rect(ht, Rect2(r.position + Vector2(8, 5), Vector2(28, 24)), false, col)
			"companion":
				var cp = Art.companion(e["id"], int(t * 6.0))
				if cp:
					c.draw_texture_rect(cp, Rect2(r.position + Vector2(10, 5), Vector2(24, 24)), false, col)
		if not own:
			_lock_icon(r.get_center() + Vector2(0, -8))
		# Nombre en hasta dos líneas dentro de la ficha (el completo sale abajo al pasar el ratón).
		UiKit.paragraph(c, Rect2(r.position.x + 2, r.end.y - 17, r.size.x - 4, 16), e["name"], UiKit.XS,
			UiKit.TEXT if own else UiKit.TEXT_MUTE, 1, {"leading": 0.3})
		if hov:
			tip_name = e["name"]
			tip = e.get("desc", "")
			if not own:
				tip = "Bloqueado · " + e["unlock"].get("text", "?")
	if tip_name != "":
		var tr := Rect2(100, 226, 370, 12)
		var nr := UiKit.text(c, Vector2(tr.position.x, tr.position.y), tip_name, UiKit.S, UiKit.YELLOW, 0, {"kind": "bold", "max_w": 130})
		UiKit.text(c, Vector2(nr.end.x + 8, tr.position.y), tip, UiKit.S, UiKit.TEXT_DIM, 0, {"max_w": tr.end.x - nr.end.x - 8})
	_back_button()


func _lock_icon(p: Vector2) -> void:
	var c := draw_node
	c.draw_arc(p + Vector2(0, -2), 3.2, PI, TAU, 12, UiKit.TEXT_MUTE, 1.3, true)
	UiKit.box(c, Rect2(p + Vector2(-4.5, -1.5), Vector2(9, 7)), UiKit.TEXT_MUTE, Color(0, 0, 0, 0), 1)
	c.draw_circle(p + Vector2(0, 1.8), 1.0, UiKit.BG_DEEP, true, -1.0, true)


func _draw_final() -> void:
	var c := draw_node
	var won: bool = result.get("won", false)
	UiKit.text(c, Vector2(240, 14), "¡La Ceniza ha caído!" if won else "Fin de la partida", 22,
		UiKit.YELLOW if won else Color("#ff8a7a"), 1, {"kind": "display", "shadow": true, "max_w": 440})
	UiKit.ornament(c, Vector2(240, 44), 90, Color(UiKit.GOLD, 0.8))
	var y := 52.0
	if won:
		y += UiKit.paragraph(c, Rect2(70, y, 340, 30), "El Muro de Ceniza se desmorona. Por primera vez en generaciones, una brisa de la Superficie baja hasta Hondura.", UiKit.S, UiKit.TEXT, 1) + 6
	# Fichas de resumen.
	var secs := int(result.get("time", 0.0))
	var chips := ["Distrito %d" % result.get("district", 1), "Tiempo %d:%02d" % [secs / 60, secs % 60], "Semilla %d" % result.get("seed", 0)]
	if result.get("madman", false):
		chips.append("Demente")
	var widths := chips.map(func(s): return UiKit.text_w(s, UiKit.S, "bold") + 14.0)
	var total: float = widths.reduce(func(a, b): return a + b, 0.0) + 6.0 * (chips.size() - 1)
	var x := 240.0 - total / 2.0
	for i in chips.size():
		var r := Rect2(x, y, widths[i], 13)
		UiKit.box(c, r, Color(UiKit.PANEL_HI, 0.9), UiKit.LINE, 6)
		UiKit.text(c, Vector2(r.get_center().x, r.position.y + (13 - UiKit.line_h(UiKit.S, "bold")) / 2.0), chips[i], UiKit.S, UiKit.TEXT, 1, {"kind": "bold"})
		x += widths[i] + 6.0
	y += 22
	# Héroes.
	var heroes: Array = result.get("heroes", [])
	var unl: Array = result.get("unlocks", [])
	var ph := 14.0 + heroes.size() * 12.0
	var pr := Rect2(80, y, 320, ph)
	UiKit.panel(c, pr)
	var hy := pr.position.y + 7
	for h in heroes:
		var line := "%s · %s · nivel %d · %d enemigos" % [h["name"], Content.race(h["race"])["name"], h["level"], h["kills"]]
		if not won and h.get("cause", "") != "":
			var cn: String = Content.enemy(h["cause"]).get("name", h["cause"])
			line += " · cayó ante " + cn
		UiKit.text(c, Vector2(240, hy), line, UiKit.S, UiKit.TEXT, 1, {"max_w": pr.size.x - 16, "min_size": UiKit.XS})
		hy += 12
	y = pr.end.y + 10
	if not unl.is_empty():
		UiKit.text(c, Vector2(240, y), "¡Desbloqueado!", UiKit.L, UiKit.LIME, 1, {"kind": "bold", "shadow": true})
		y += UiKit.line_h(UiKit.L) + 3
		var max_rows := int((236.0 - y) / 11.0)
		for i in mini(unl.size(), max_rows):
			var u: Dictionary = unl[i]
			var kn = {"race": "Raza", "hat": "Sombrero", "companion": "Compañero"}[u["kind"]]
			var s := "%s: %s" % [kn, u["name"]]
			if i == max_rows - 1 and unl.size() > max_rows:
				s = "y %d más…" % (unl.size() - i)
			UiKit.text(c, Vector2(240, y), s, UiKit.S, Color("#d4f5b0"), 1, {"max_w": 320})
			y += 11
	UiKit.button(c, Rect2(170, 242, 140, 18), "Menú principal", Rect2(170, 242, 140, 18).has_point(_mouse()), {"primary": true})


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
		# Se recorta del propio mundo (SubViewport de Run.WORLD_RES), no de la ventana.
		var img: Image = run.world_vp.get_texture().get_image()
		var sp: Vector2 = h.position - run.world.camera.get_screen_center_position() + Vector2(Run.WORLD_RES) / 2.0
		var r := Rect2i(int(sp.x) - 40, int(sp.y) - 40, 80, 50).intersection(Rect2i(Vector2i.ZERO, Run.WORLD_RES))
		img.get_region(r).save_png(ProjectSettings.globalize_path("res://shots/anim_%02d.png" % i))
	get_tree().quit()


## Tira de fotogramas del tajo horizontal junto a un árbol (shots/chop_<raza>.png), para
## revisar la animación. Una fila por raza: Minero (esqueleto por piezas) y otra con sprites.
func _chop_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	var rows: Array[Image] = []
	var races := _owned_list("race", Content.RACES)
	var other := 0
	for i in races.size():
		if races[i]["id"] != "minero":
			other = i
			break
	for ri in [0, other]:
		c_race = ri
		var race: String = races[ri]["id"]
		_start_single(4242)
		await get_tree().create_timer(0.6).timeout
		var w: World = run.world
		w.god_mode = true
		var h: Hero = game_ui.local_hero()
		var tree: WorldNode = null
		for n in w.nodes:
			if n.kind == "arbol" and n.plant_h == 0 and (tree == null or n.position.distance_to(h.position) < tree.position.distance_to(h.position)):
				tree = n
		h.teleport(tree.position + Vector2(-13, 0))
		h.facing = 1
		h.model.inv.slots[0] = Inventory.make("hacha_madera", 1)
		h.model.inv.hand = 0
		await get_tree().create_timer(0.3).timeout
		w.paused = true
		h._swing("hacha", 0.3)
		print("CHOP ", race, " tajo horizontal=", h.chop)
		var frames: Array[Image] = []
		for kk in [0.0, 0.2, 0.35, 0.45, 0.5, 0.56, 0.7, 0.95]:
			h.attack_t = 0.3 * (1.0 - kk)
			h.queue_redraw()
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var img: Image = run.world_vp.get_texture().get_image()
			var sp: Vector2 = h.position - w.camera.get_screen_center_position() + Vector2(Run.WORLD_RES) / 2.0
			var fr := img.get_region(Rect2i(int(sp.x) - 22, int(sp.y) - 26, 44, 30))
			fr.resize(44 * 6, 30 * 6, Image.INTERPOLATE_NEAREST)
			frames.append(fr)
		var strip := Image.create(frames.size() * 44 * 6, 30 * 6, false, frames[0].get_format())
		for i in frames.size():
			strip.blit_rect(frames[i], Rect2i(0, 0, 44 * 6, 30 * 6), Vector2i(i * 44 * 6, 0))
		rows.append(strip)
		w.paused = false
		# Golpe real contra el árbol: se inclina y saltan astillas.
		h.attack_t = 0.0
		h.use_cd = 0.0
		var inp := InputState.new()
		inp.use = true
		inp.use_pressed = true
		inp.aim = h.center() + Vector2(40, 0)
		run.remote_inputs[h.peer_id] = inp
		h.is_local = false
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		var hit_img: Image = run.world_vp.get_texture().get_image()
		hit_img.resize(Run.WORLD_RES.x * 3, Run.WORLD_RES.y * 3, Image.INTERPOLATE_NEAREST)
		hit_img.save_png(ProjectSettings.globalize_path("res://shots/chop_golpe_%s.png" % race))
	var out := Image.create(rows[0].get_width(), rows[0].get_height() * rows.size(), false, rows[0].get_format())
	for i in rows.size():
		out.blit_rect(rows[i], Rect2i(Vector2i.ZERO, rows[i].get_size()), Vector2i(0, i * rows[i].get_height()))
	out.save_png(ProjectSettings.globalize_path("res://shots/chop.png"))
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
	await _shot("00_titulo", 0.8)
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


# --- Auditoría de la interfaz (desarrollo) --------------------------------------------------------
# Recorre todas las pantallas y paneles, guarda una captura de cada una en shots/ui_*.png e
# imprime cualquier texto que se solape con otro o se salga de la pantalla.

var _audit_total := 0


func _audit(name: String) -> void:
	UiKit.audit = true
	await RenderingServer.frame_post_draw
	UiKit.audit_begin()
	await RenderingServer.frame_post_draw
	var issues := UiKit.audit_issues()
	UiKit.audit = false
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/ui_%s.png" % name))
	_audit_total += issues.size()
	print("UI %-22s %s" % [name, "ok" if issues.is_empty() else "%d problemas" % issues.size()])
	for s in issues:
		print("     ", s)


func _ui_audit() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	await get_tree().create_timer(0.5).timeout
	for s in ["titulo", "crear", "coop", "opciones", "controles"]:
		screen = s
		await _audit(s)
	for k in ["nombre", "raza", "sombrero", "companero", "rasgo1", "modo", "semilla"]:
		screen = "crear"
		c_focus = k
		c_madman = k == "modo"
		await _audit("crear_" + k)
	c_madman = false
	# Nombres más largos posibles en la creación.
	c_name = "WWWWWWWWWWWW"
	c_hat = 0
	for i in Content.HATS.size():
		if Content.HATS[i]["name"].length() > Content.HATS[c_hat]["name"].length():
			c_hat = i
	screen = "crear"
	c_focus = "sombrero"
	await _audit("crear_largo")
	c_name = "Hero"
	c_hat = 0
	for k in 4:
		screen = "galeria"
		gallery_tab = k
		await _audit("galeria_%d" % k)
	result = {"won": true, "district": 21, "time": 3725.0, "seed": 123456, "madman": true,
		"heroes": [{"name": "WWWWWWWWWWWW", "race": "minero", "level": 20, "kills": 999, "cause": ""},
			{"name": "Cliente", "race": "minero", "level": 7, "kills": 12, "cause": ""}],
		"unlocks": [{"kind": "race", "name": "Caballero fantasma"}, {"kind": "hat", "name": "Capucha del rey esqueleto"}, {"kind": "companion", "name": "Dron de la cuarta era"}]}
	screen = "final"
	await _audit("final_victoria")
	result["won"] = false
	result["heroes"][0]["cause"] = "muro_ceniza"
	await _audit("final_derrota")
	# Partida.
	_start_single(4242)
	await get_tree().create_timer(1.2).timeout
	var h: Hero = game_ui.local_hero()
	run.world.god_mode = true
	h.model.coins = 99999
	h.model.hp = 7
	h.model.inv.add(Inventory.make("madera", 99))
	h.model.inv.add(Inventory.make("espada_hierro", 1))
	h.model.inv.add(Inventory.make("baston_fuego", 1))
	for i in 6:
		game_ui.notify("+%d objeto de prueba con nombre largo" % i, UiKit.LIME)
	game_ui.say("Mensaje de prueba bastante largo para comprobar que el aviso cabe en su sitio")
	await _audit("hud")
	# Aura dorada y pista junto a un árbol con el hacha en la mano.
	var tree: WorldNode = null
	for n in run.world.nodes:
		if n.kind == "arbol" and n.plant_h == 0 and (tree == null or n.position.distance_to(h.position) < tree.position.distance_to(h.position)):
			tree = n
	if tree:
		h.teleport(tree.position + Vector2(-13, 0))
		h.facing = 1
		h.model.inv.slots[0] = Inventory.make("hacha_madera", 1)
		h.model.inv.hand = 0
		await get_tree().create_timer(0.5).timeout
		print("UI foco árbol: ", run.world.focus.get("harvest", []).size(), " recurso(s)")
		await _audit("aura_arbol")
	game_ui.toggle_inventory()
	await get_tree().create_timer(0.2).timeout
	await _audit("inventario")
	game_ui.close()
	for p in ["pausa", "opciones", "controles", "mapa"]:
		game_ui.panel = p
		await _audit("juego_" + p)
	game_ui.panel = ""
	game_ui.open_skill_pick(h)
	await _audit("habilidad")
	game_ui.panel = ""
	run.world.paused = false
	run.enter_town("tundra")
	await get_tree().create_timer(1.0).timeout
	h = game_ui.local_hero()
	h.model.inv.add(Inventory.make("lingote_hierro", 9) if ItemDB.has("lingote_hierro") else Inventory.make("madera", 5))
	for n in run.world.npcs:
		if n.kind in ["tendero", "herrero", "comprador", "altar"]:
			game_ui.open_npc(n, h)
			await _audit("npc_" + n.kind + ("_" + n.shop if n.shop != "" else ""))
			game_ui.close()
	print("UI npcs del pueblo: ", run.world.npcs.map(func(n): return n.kind))
	for n in run.world.npcs:
		if n.kind == "vecino":
			n.talk()
			h.teleport(n.position + Vector2(-16, 0))
			break
	await get_tree().create_timer(0.4).timeout
	await _audit("pueblo_rotulos")
	for n in run.world.npcs:
		if n.kind == "tendero":
			h.teleport(n.position + Vector2(0, 0))
			break
	await get_tree().create_timer(0.5).timeout
	print("UI foco tienda: ", run.world.focus.get("interact", {}).get("verb", "(nada)"))
	await _audit("aura_tienda")
	print("UI TOTAL problemas: ", _audit_total)
	get_tree().quit()
