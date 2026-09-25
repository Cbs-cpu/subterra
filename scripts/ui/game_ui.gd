class_name GameUI
extends CanvasLayer
## Interfaz durante la partida: HUD, inventario con crafteo, pueblo (tiendas, artesanos,
## comprador, altares), elección de habilidad, mapa, avisos y pausa.

signal quit_to_menu

const SLOT := 18
const COL_BG := Color("#1a1420")
const COL_BORDER := Color("#6a5a8a")
const COL_TXT := Color("#f0e8d8")
const COL_DIM := Color("#8a8098")
const COL_GOLD := Color("#f0c03a")
const QCOL := [Color("#f0e8d8"), Color("#5a9af0"), Color("#f0d03a"), Color("#c05af0")]

var run: Node
var draw_node: Node2D
var panel := ""               # "", inventario, tienda, artesano, comprador, altar, habilidad, pausa, opciones, controles, mapa
var npc: Npc
var hero: Hero
var selected := -1            # ranura seleccionada (índice) o -10-k para equipo
var craft_a := -1
var msg := ""
var msg_t := 0.0
var notes: Array = []
var card := {}
var skill_opts: Array = []
var shop_items: Array = []
var scroll := 0
var hover_tip := ""
var menu_i := 0
var rebinding := ""
var t := 0.0


func _ready() -> void:
	layer = 20
	draw_node = Node2D.new()
	draw_node.draw.connect(_draw_ui)
	add_child(draw_node)


func local_hero() -> Hero:
	if run == null or run.world == null:
		return null
	for p in run.world.players:
		if p.is_local:
			return p
	return null


func blocks_game_input() -> bool:
	return panel != "" and panel != "mapa"


func _process(dt: float) -> void:
	t += dt
	msg_t = maxf(0.0, msg_t - dt)
	for n in notes:
		n["t"] -= dt
	notes = notes.filter(func(n): return n["t"] > 0.0)
	if card.size() > 0:
		card["t"] -= dt
		if card["t"] <= 0.0:
			card = {}
	if Input.is_action_just_pressed("map") and (panel == "" or panel == "mapa"):
		panel = "mapa" if panel == "" else ""
	draw_node.queue_redraw()


func notify(text: String, col: Color) -> void:
	notes.append({"s": text, "c": col, "t": 3.5})


func show_title_card(title: String, sub: String) -> void:
	card = {"title": title, "sub": sub, "t": 2.6}


func say(s: String) -> void:
	if s != "":
		msg = s
		msg_t = 2.5


# --- Apertura de paneles -----------------------------------------------------------------

func open_npc(n: Npc, h: Hero) -> void:
	npc = n
	hero = h
	scroll = 0
	selected = -1
	match n.kind:
		"tendero":
			panel = "tienda"
			var r := RandomNumberGenerator.new()
			r.seed = run.seed_value + run.district * 3 + (1 if n.shop == "herramientas" else 2)
			shop_items = InvOps.shop_stock(n.shop, run.district, r)
		"herrero", "sastra", "peletero":
			panel = "artesano"
		"comprador":
			panel = "comprador"
		"altar":
			panel = "altar"
	Sfx.play("abrir")


func open_skill_pick(h: Hero) -> void:
	hero = h
	skill_opts = h.model.roll_skill_offer(run.rng)
	panel = "habilidad"
	_set_paused(true)


func toggle_inventory() -> void:
	if panel == "inventario":
		close()
	elif panel == "":
		hero = local_hero()
		if hero:
			panel = "inventario"
			selected = -1
			craft_a = -1
			Sfx.play("abrir", 0.0, -8.0)


func close() -> void:
	if panel == "habilidad":
		return
	panel = ""
	selected = -1
	craft_a = -1
	_set_paused(false)


func _set_paused(p: bool) -> void:
	if run and run.world and not Net.is_online():
		run.world.paused = p


func act(a: Dictionary) -> void:
	var h := local_hero() if hero == null else hero
	if h == null:
		return
	if Net.is_client():
		Net.send_action(a)
		return
	say(InvOps.apply(run, h.model, a, h))


# --- Entrada --------------------------------------------------------------------------------

func _unhandled_input(ev: InputEvent) -> void:
	if run == null:
		return
	if rebinding != "":
		if ev is InputEventKey and ev.pressed:
			if ev.physical_keycode != KEY_ESCAPE:
				Game.rebind(rebinding, ev.physical_keycode)
			rebinding = ""
			get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("pause"):
		if panel == "":
			panel = "pausa"
			menu_i = 0
			_set_paused(true)
		elif panel in ["opciones", "controles"]:
			panel = "pausa"
		elif panel != "habilidad":
			close()
		get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("inventory") and panel in ["", "inventario"]:
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventMouseButton and ev.pressed and panel != "" and panel != "mapa":
		_click(draw_node.get_local_mouse_position(), ev.button_index, ev.shift_pressed)
		get_viewport().set_input_as_handled()
	if ev is InputEventMouseButton and ev.pressed and panel in ["tienda", "artesano"]:
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll += 1
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll = maxi(0, scroll - 1)
	if ev is InputEventMouseButton and ev.pressed and panel == "" and local_hero() != null:
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			act({"op": "hand", "i": (local_hero().model.inv.hand + 1) % 8})
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			act({"op": "hand", "i": (local_hero().model.inv.hand + 7) % 8})


func _click(m: Vector2, button: int, shift: bool) -> void:
	for b in _buttons():
		if b["r"].has_point(m):
			b["f"].call(button, shift)
			return
	if panel == "inventario" and selected >= 0 and not _inv_rect().has_point(m):
		act({"op": "drop", "i": selected})
		selected = -1


## Zonas clicables del panel activo: [{r: Rect2, f: Callable(button, shift)}].
func _buttons() -> Array:
	var out := []
	var h := hero if hero else local_hero()
	match panel:
		"inventario", "comprador":
			if h == null:
				return out
			for i in Inventory.SIZE:
				var r := _slot_rect(i)
				var idx := i
				out.append({"r": r, "f": func(b, s): _slot_click(idx, b, s)})
			if panel == "inventario":
				var eq := Inventory.EQUIP_SLOTS
				for k in eq.size():
					var slot: String = eq[k]
					out.append({"r": _equip_rect(k), "f": func(_b, _s): _equip_click(slot)})
		"tienda":
			for k in range(scroll, mini(scroll + 8, shop_items.size())):
				var id: String = shop_items[k]
				out.append({"r": Rect2(110, 62 + (k - scroll) * 18, 260, 16), "f": func(_b, _s): act({"op": "buy", "id": id})})
		"artesano":
			var list := _npc_list()
			for k in range(scroll, mini(scroll + 8, list.size())):
				var r2: Dictionary = list[k]
				out.append({"r": Rect2(90, 62 + (k - scroll) * 18, 300, 16), "f": func(_b, _s): act({"op": "npc_craft", "npc": npc.kind, "out": r2["out"]})})
		"altar":
			out.append({"r": Rect2(170, 150, 140, 16), "f": func(_b, _s): act({"op": "altar", "id": npc.altar_id})})
		"habilidad":
			for k in skill_opts.size():
				var sid: String = skill_opts[k]
				out.append({"r": Rect2(60 + k * 125, 80, 115, 110), "f": func(_b, _s): _pick_skill(sid)})
		"pausa":
			var items := _pause_items()
			for k in items.size():
				var kk := k
				out.append({"r": Rect2(170, 90 + k * 18, 140, 16), "f": func(_b, _s): _pause_pick(kk)})
		"opciones":
			for k in 6:
				var kk2 := k
				out.append({"r": Rect2(130, 70 + k * 18, 220, 16), "f": func(b, _s): _option_pick(kk2, b)})
		"controles":
			var keys := Game.LABELS.keys()
			for k in keys.size():
				var a: String = keys[k]
				out.append({"r": Rect2(120, 36 + k * 13, 240, 12), "f": func(_b, _s): rebinding = a})
	return out


func _pick_skill(id: String) -> void:
	act({"op": "skill", "id": id})
	panel = ""
	_set_paused(false)
	var h := hero if hero else local_hero()
	if h and h.model.pending_skill_offers > 0:
		open_skill_pick(h)


func _slot_click(i: int, button: int, shift: bool) -> void:
	var h := hero if hero else local_hero()
	var inv := h.model.inv
	if panel == "comprador":
		if inv.slots[i] != null:
			act({"op": "sell", "i": i})
		return
	if shift:
		if craft_a == -1:
			if inv.slots[i] != null:
				craft_a = i
		else:
			act({"op": "craft", "a": craft_a, "b": i})
			craft_a = -1
		return
	craft_a = -1
	if selected == -1:
		if inv.slots[i] != null:
			if button == MOUSE_BUTTON_RIGHT and ItemDB.get_item(inv.slots[i]["id"]).has("slot"):
				act({"op": "equip", "i": i})
			else:
				selected = i
		return
	if button == MOUSE_BUTTON_RIGHT:
		if inv.slots[i] == null and inv.slots[selected] != null and inv.slots[selected]["n"] > 1 and false:
			act({"op": "split", "a": selected, "b": i})
		else:
			act({"op": "one", "a": selected, "b": i})
		if inv.slots[selected] == null:
			selected = -1
		return
	act({"op": "move", "a": selected, "b": i})
	selected = -1


func _equip_click(slot: String) -> void:
	var h := hero if hero else local_hero()
	if selected >= 0 and h.model.inv.slots[selected] != null:
		act({"op": "equip", "i": selected})
		selected = -1
	else:
		act({"op": "unequip", "slot": slot})


func _pause_items() -> Array:
	var items := ["Continuar", "Opciones"]
	if run.state == "town" and not Net.is_online():
		items.append("Guardar y salir")
	items.append("Abandonar partida")
	return items


func _pause_pick(k: int) -> void:
	var item: String = _pause_items()[k]
	match item:
		"Continuar":
			close()
		"Opciones":
			panel = "opciones"
		"Guardar y salir":
			run.save_to_disk()
			close()
			quit_to_menu.emit()
		"Abandonar partida":
			close()
			Game.clear_run()
			quit_to_menu.emit()


func _option_pick(k: int, button: int) -> void:
	var d := 0.1 if button == MOUSE_BUTTON_LEFT else -0.1
	match k:
		0: Game.settings["sfx"] = clampf(Game.settings["sfx"] + d, 0.0, 1.0)
		1: Game.settings["music"] = clampf(Game.settings["music"] + d, 0.0, 1.0)
		2: Game.settings["fullscreen"] = not Game.settings["fullscreen"]
		3: Game.settings["shake"] = not Game.settings["shake"]
		4: panel = "controles"
		5: panel = "pausa"
	Game.apply_settings()
	Game.save_profile()
	Sfx.play("menu")


func _npc_list() -> Array:
	var h := hero if hero else local_hero()
	var all := Recipes.npc_recipes(npc.kind)
	var can := []
	var rest := []
	for r in all:
		var any := false
		for id in r["needs"]:
			if h.model.inv.count(id) > 0:
				any = true
		if h.model.inv.can_npc(npc.kind, r["out"]):
			can.append(r)
		elif any:
			rest.append(r)
	return can + rest


# --- Geometría -------------------------------------------------------------------------------

func _inv_origin() -> Vector2:
	return Vector2(160, 70)


func _inv_rect() -> Rect2:
	return Rect2(20, 30, 440, 200)


func _slot_rect(i: int) -> Rect2:
	var o := _inv_origin()
	var x := i % 8
	var y := i / 8
	return Rect2(o.x + x * (SLOT + 2), o.y + y * (SLOT + 2) + (4 if y > 0 else 0), SLOT, SLOT)


func _equip_rect(k: int) -> Rect2:
	return Rect2(40 + (k % 2) * 22, 70 + (k / 2) * 22, SLOT, SLOT)


# --- Dibujo -----------------------------------------------------------------------------------

func _panel(r: Rect2, title := "") -> void:
	var c := draw_node
	c.draw_rect(r.grow(2), Color("#0e0a12"))
	c.draw_rect(r.grow(1), COL_BORDER)
	c.draw_rect(r, COL_BG)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), COL_BORDER.lightened(0.3))
	if title != "":
		PixelFont.draw_centered(c, r.get_center().x, r.position.y + 5, title, COL_GOLD, 2)


func _draw_stack(pos: Vector2, s, show_n := true) -> void:
	var c := draw_node
	if s == null:
		return
	c.draw_texture(Art.icon(s["id"]), pos + Vector2(3, 3))
	var q: int = s.get("q", 0)
	if q > 0:
		c.draw_rect(Rect2(pos, Vector2(SLOT, 1)), QCOL[q])
	if show_n and s["n"] > 1:
		PixelFont.draw(c, pos + Vector2(SLOT - PixelFont.width(str(s["n"])) - 1, SLOT - 6), str(s["n"]), COL_TXT)
	if s.has("dur"):
		var maxd: int = ItemDB.get_item(s["id"]).get("dur", 1)
		var k := clampf(float(s["dur"]) / maxd, 0.0, 1.0)
		c.draw_rect(Rect2(pos + Vector2(2, SLOT - 2), Vector2((SLOT - 4) * k, 1)), Color("#5ae05a").lerp(Color("#e05a5a"), 1.0 - k))


func _slot_box(r: Rect2, hl := false, sel := false) -> void:
	var c := draw_node
	c.draw_rect(r, Color("#2a2232") if not hl else Color("#3a3050"))
	c.draw_rect(r, Color("#4a3e5a") if not sel else COL_GOLD, false, 1.0)


func _draw_ui() -> void:
	var h := local_hero()
	if run == null:
		return
	if h and not run.finished:
		_draw_hud(h)
	_draw_notes()
	match panel:
		"inventario": _draw_inventory()
		"tienda": _draw_shop()
		"artesano": _draw_crafter()
		"comprador": _draw_buyer()
		"altar": _draw_altar()
		"habilidad": _draw_skill_pick()
		"pausa": _draw_pause()
		"opciones": _draw_options()
		"controles": _draw_controls()
		"mapa": _draw_map()
	if msg_t > 0.0:
		var w := PixelFont.width(msg) + 10
		draw_node.draw_rect(Rect2(240 - w / 2.0, 236, w, 11), Color(0, 0, 0, 0.7))
		PixelFont.draw_centered(draw_node, 240, 239, msg, COL_TXT)


func _bar(pos: Vector2, w: float, k: float, col: Color, label: String) -> void:
	var c := draw_node
	c.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(w + 2, 7)), Color("#0e0a12"))
	c.draw_rect(Rect2(pos, Vector2(w, 5)), col.darkened(0.6))
	c.draw_rect(Rect2(pos, Vector2(w * clampf(k, 0.0, 1.0), 5)), col)
	c.draw_rect(Rect2(pos, Vector2(w * clampf(k, 0.0, 1.0), 1)), col.lightened(0.4))
	PixelFont.draw(c, pos + Vector2(w + 4, 0), label, COL_TXT)


func _draw_hud(h: Hero) -> void:
	var c := draw_node
	var m := h.model
	_bar(Vector2(6, 6), 70, float(m.hp) / m.max_hp(), Color("#e0304a"), "%d/%d" % [m.hp, m.max_hp()])
	_bar(Vector2(6, 15), 54, m.mana / m.max_mana(), Color("#3a7ae0"), "%d/%d" % [int(m.mana), m.max_mana()])
	# Estamina.
	for k in m.max_stamina():
		var full := k < int(m.stamina)
		c.draw_rect(Rect2(6 + k * 6, 24, 5, 3), Color("#6ae05a") if full else Color("#2a4a2a"))
	# Hambre.
	for k in m.max_hunger():
		var on := k < int(ceil(m.hunger))
		var col := Color("#d07a3a") if on else Color("#3a2a22")
		if m.hunger <= 0.0 and int(t * 4.0) % 2 == 0:
			col = Color("#e0304a")
		c.draw_rect(Rect2(6 + k * 6, 30, 5, 4), col)
		c.draw_rect(Rect2(7 + k * 6, 30, 2, 1), col.lightened(0.3))
	# Nivel y experiencia.
	var need := HeroModel.xp_to_next(m.level)
	c.draw_rect(Rect2(6, 37, 70, 2), Color("#1a3a1e"))
	c.draw_rect(Rect2(6, 37, 70.0 * m.xp / need, 2), Color("#8aff9a"))
	PixelFont.draw(c, Vector2(6, 42), "nv %d" % m.level, Color("#8aff9a"))
	c.draw_texture(Art.coin_icon(), Vector2(34, 39))
	PixelFont.draw(c, Vector2(47, 42), str(m.coins), COL_GOLD)
	# Distrito y temporizador de la Ceniza.
	var w: World = run.world
	var title: String = "Pueblo" if w.is_town else "%s  ·  distrito %d" % [Content.biome(w.biome)["name"], run.district]
	PixelFont.draw(c, Vector2(474 - PixelFont.width(title), 6), title, COL_TXT)
	var tl := w.time_left()
	if tl >= 0.0:
		var col2 := Color("#c0b8d0") if tl > 30.0 else (Color("#ff5a7a") if int(t * 4.0) % 2 == 0 else Color("#ffd0d8"))
		var s := "ceniza %d:%02d" % [int(maxf(tl, 0.0)) / 60, int(maxf(tl, 0.0)) % 60] if tl > 0.0 else "¡los guardianes!"
		PixelFont.draw(c, Vector2(474 - PixelFont.width(s), 15), s, col2)
	# Barra rápida.
	var ox := 240 - 4 * (SLOT + 2)
	for i in 8:
		var r := Rect2(ox + i * (SLOT + 2), 247, SLOT, SLOT)
		_slot_box(r, false, i == m.inv.hand)
		_draw_stack(r.position, m.inv.slots[i])
		PixelFont.draw(c, r.position + Vector2(1, 1), str(i + 1), Color(1, 1, 1, 0.35))
	var held = m.inv.held()
	if held != null:
		var nm: String = ItemDB.get_item(held["id"]).get("name", "")
		PixelFont.draw_centered(c, 240, 238, nm, QCOL[held.get("q", 0)])
	# Habilidades.
	for k in m.skills.size():
		var sid: String = m.skills[k]
		var r2 := Rect2(6 + k * 22, 247, SLOT, SLOT)
		var sk := Content.find(Content.SKILLS, sid)
		var tc = {"guerrero": Color("#c0302a"), "mago": Color("#3a5ae0"), "explorador": Color("#3aa04a")}[sk["type"]]
		c.draw_rect(r2, tc.darkened(0.3))
		c.draw_rect(r2, tc.lightened(0.2), false, 1.0)
		PixelFont.draw_centered(c, r2.get_center().x, r2.position.y + 3, sk["name"].substr(0, 3), COL_TXT)
		PixelFont.draw_centered(c, r2.get_center().x, r2.position.y + 11, ["Z", "X", "C"][k], Color(1, 1, 1, 0.6))
		var cd: float = m.skill_cd.get(sid, 0.0)
		if cd > 0.0:
			var k2 := cd / float(sk["cd"])
			c.draw_rect(Rect2(r2.position, Vector2(SLOT, SLOT * k2)), Color(0, 0, 0, 0.6))
	# Mejoras activas.
	var bx := 6
	for b in m.buffs:
		var label: String = b.get("flag", b.get("stat", ""))
		PixelFont.draw(c, Vector2(bx, 52), "%s %d" % [label, int(b["t"])], Color("#fff08a"))
		bx += PixelFont.width(label) + 16
	# Jefe.
	var bn = w.boss_node
	if bn != null and is_instance_valid(bn) and not bn.dead and bn.center().distance_to(h.center()) < 420.0:
		c.draw_rect(Rect2(139, 21, 202, 7), Color("#0e0a12"))
		c.draw_rect(Rect2(140, 22, 200.0 * bn.hp / bn.max_hp, 5), Color("#c0302a"))
		PixelFont.draw_centered(c, 240, 30, bn.data["name"], Color("#ffb0a0"))
	# Cooperativo: compañeros abatidos.
	var y := 60
	for p in w.players:
		if p != h:
			PixelFont.draw(c, Vector2(6, y), "%s %d/%d%s" % [p.model.name, p.model.hp, p.model.max_hp(), " ABATIDO" if p.downed else ""],
				Color("#ff8a8a") if p.downed else COL_DIM)
			y += 8
	# Pista de interacción.
	var hint := _hint(h)
	if hint != "":
		PixelFont.draw_centered(c, 240, 222, hint, Color("#fff08a"))
	# Cartel de entrada.
	if card.size() > 0:
		var a := clampf(card["t"], 0.0, 1.0)
		PixelFont.draw_centered(c, 240, 90, card["title"], Color(1, 0.9, 0.6, a), 3)
		PixelFont.draw_centered(c, 240, 116, card["sub"], Color(0.9, 0.85, 0.95, a))
	if run.party_dead_t >= 0.0:
		PixelFont.draw_centered(c, 240, 120, "Todo el grupo ha caído", Color("#ff5a5a"), 2)


func _hint(h: Hero) -> String:
	var hc := h.center()
	for n in run.world.npcs:
		if n.rect().grow(10).has_point(hc):
			match n.kind:
				"puerta": return "[%s] entrar: %s" % [Game.key_label("interact"), n.label()]
				"vecino": return "[%s] hablar" % Game.key_label("interact")
				_: return "[%s] %s" % [Game.key_label("interact"), n.label()]
	for nd in run.world.nodes:
		if not nd.dead and nd.kind == "cofre" and not nd.open and nd.rect().grow(10).has_point(hc):
			return "[%s] abrir cofre%s" % [Game.key_label("interact"), " (llave)" if nd.golden else ""]
	for p in run.world.players:
		if p != h and p.downed and p.center().distance_to(hc) < 26.0:
			return "[%s] revivir a %s" % [Game.key_label("interact"), p.model.name]
	return ""


func _draw_notes() -> void:
	var y := 64
	for n in notes:
		var col: Color = n["c"]
		col.a = clampf(n["t"], 0.0, 1.0)
		PixelFont.draw_centered(draw_node, 240, y, n["s"], col, 1)
		y += 9


func _tooltip(pos: Vector2, s) -> void:
	if s == null:
		return
	var it := ItemDB.get_item(s["id"])
	var lines := [it.get("name", s["id"])]
	var q: int = s.get("q", 0)
	if q > 0:
		lines[0] += " (" + Recipes.QUALITY_NAMES[q] + ")"
	var st := []
	for k in ["hp", "atk", "dex", "mag"]:
		var v := int(it.get(k, 0)) + int(s.get("bonus", {}).get(k, 0))
		if v != 0:
			st.append("%s %+d" % [{"hp": "vida", "atk": "ataque", "dex": "destreza", "mag": "magia"}[k], v])
	if not st.is_empty():
		lines.append(", ".join(st))
	if s.has("dur"):
		lines.append("durabilidad %d/%d" % [s["dur"], it.get("dur", 0)])
	if it.has("tool"):
		lines.append("herramienta: %s nivel %d" % [it["tool"], it.get("tier", 0)])
	if it.has("food"):
		lines.append("hambre +%d" % it["food"]["hunger"])
	if it.has("potion") and it["potion"].has("hp"):
		lines.append("cura %d" % it["potion"]["hp"])
	if it.has("spell"):
		lines.append("hechizo (%d maná)" % it.get("mana", 1))
	if it.has("slot"):
		lines.append("clic derecho: equipar")
	var w := 0
	for l in lines:
		w = maxi(w, PixelFont.width(l))
	var r := Rect2(pos + Vector2(10, 4), Vector2(w + 8, lines.size() * 8 + 4))
	if r.end.x > 478:
		r.position.x -= r.size.x + 20
	draw_node.draw_rect(r, Color(0.05, 0.03, 0.08, 0.95))
	draw_node.draw_rect(r, QCOL[q], false, 1.0)
	for i in lines.size():
		PixelFont.draw(draw_node, r.position + Vector2(4, 3 + i * 8), lines[i], QCOL[q] if i == 0 else COL_TXT)


func _draw_inv_grid(h: Hero) -> void:
	var inv := h.model.inv
	for i in Inventory.SIZE:
		var r := _slot_rect(i)
		_slot_box(r, i < 8, i == selected or i == craft_a)
		if i == craft_a:
			draw_node.draw_rect(r.grow(1), Color("#6ae05a"), false, 1.0)
		_draw_stack(r.position, inv.slots[i])


func _draw_inventory() -> void:
	var h := hero if hero else local_hero()
	if h == null:
		return
	var m := h.model
	_panel(_inv_rect(), "Inventario")
	_draw_inv_grid(h)
	var eq := Inventory.EQUIP_SLOTS
	var names := ["cabeza", "cuerpo", "escudo", "anillo", "anillo"]
	PixelFont.draw(draw_node, Vector2(36, 60), "Equipo", COL_GOLD)
	for k in eq.size():
		var r := _equip_rect(k)
		_slot_box(r)
		if m.inv.equip[eq[k]] == null:
			PixelFont.draw_centered(draw_node, r.get_center().x, r.position.y + 7, names[k].substr(0, 3), Color(1, 1, 1, 0.25))
		_draw_stack(r.position, m.inv.equip[eq[k]])
	# Estadísticas.
	var y := 142
	PixelFont.draw(draw_node, Vector2(30, y), "%s  ·  %s" % [m.name, Content.race(m.race_id)["name"]], COL_TXT)
	y += 10
	for pair in [["Vida", "hp"], ["Ataque", "atk"], ["Destreza", "dex"], ["Magia", "mag"]]:
		var g: int = m.growth[pair[1]]
		var gc = [Color("#e05a5a"), COL_TXT, Color("#6ae05a")][g]
		PixelFont.draw(draw_node, Vector2(30, y), "%s %d" % [pair[0], m.stat(pair[1])], gc)
		y += 8
	PixelFont.draw(draw_node, Vector2(30, y + 2), "Rasgos: " + ", ".join(m.traits.map(func(tr): return Content.find(Content.TRAITS, tr)["name"])), COL_DIM)
	PixelFont.draw(draw_node, Vector2(160, 160), "Clic: mover  ·  Clic der.: poner uno / equipar", COL_DIM)
	PixelFont.draw(draw_node, Vector2(160, 168), "Mayús + clic en dos objetos: combinar", Color("#8aff9a"))
	PixelFont.draw(draw_node, Vector2(160, 176), "Clic fuera con algo seleccionado: tirar", COL_DIM)
	# Libro de recetas (conocidas).
	PixelFont.draw(draw_node, Vector2(160, 190), "Recetas descubiertas: %d/%d" % [Game.known_recipes().size(), Recipes.pairs().size()], COL_GOLD)
	var mp := draw_node.get_local_mouse_position()
	for i in Inventory.SIZE:
		if _slot_rect(i).has_point(mp):
			_tooltip(mp, m.inv.slots[i])
	for k in eq.size():
		if _equip_rect(k).has_point(mp):
			_tooltip(mp, m.inv.equip[eq[k]])


func _draw_shop() -> void:
	var h := hero if hero else local_hero()
	_panel(Rect2(90, 30, 300, 200), npc.label())
	PixelFont.draw(draw_node, Vector2(100, 50), "Tus monedas: %d   (rueda: desplazar)" % h.model.coins, COL_GOLD)
	for k in range(scroll, mini(scroll + 8, shop_items.size())):
		var id: String = shop_items[k]
		var r := Rect2(110, 62 + (k - scroll) * 18, 260, 16)
		var hov := r.has_point(draw_node.get_local_mouse_position())
		draw_node.draw_rect(r, Color("#2e2640") if hov else Color("#221c2e"))
		draw_node.draw_texture(Art.icon(id), r.position + Vector2(2, 2))
		PixelFont.draw(draw_node, r.position + Vector2(18, 5), ItemDB.get_item(id)["name"], COL_TXT)
		var p := InvOps.price(id)
		PixelFont.draw(draw_node, r.position + Vector2(r.size.x - PixelFont.width(str(p)) - 6, 5), str(p), COL_GOLD if h.model.coins >= p else Color("#a05a5a"))


func _draw_crafter() -> void:
	var h := hero if hero else local_hero()
	_panel(Rect2(80, 30, 320, 200), npc.label())
	var list := _npc_list()
	if list.is_empty():
		PixelFont.draw_centered(draw_node, 240, 110, PixelFont.wrap("No llevas nada con lo que pueda trabajar. Tráeme lingotes, menas, telas o cuero.", 50), COL_DIM)
	for k in range(scroll, mini(scroll + 8, list.size())):
		var rc: Dictionary = list[k]
		var r := Rect2(90, 62 + (k - scroll) * 18, 300, 16)
		var can := h.model.inv.can_npc(npc.kind, rc["out"])
		var hov := r.has_point(draw_node.get_local_mouse_position())
		draw_node.draw_rect(r, Color("#2e2640") if hov else Color("#221c2e"))
		draw_node.draw_texture(Art.icon(rc["out"]), r.position + Vector2(2, 2))
		PixelFont.draw(draw_node, r.position + Vector2(18, 5), ItemDB.get_item(rc["out"])["name"], COL_TXT if can else COL_DIM)
		var x := r.end.x - 4
		for id in rc["needs"]:
			var s := "x%d" % rc["needs"][id]
			x -= PixelFont.width(s) + 16
			draw_node.draw_texture(Art.icon(id), Vector2(x, r.position.y + 2))
			PixelFont.draw(draw_node, Vector2(x + 13, r.position.y + 5), s, Color("#8aff9a") if h.model.inv.count(id) >= rc["needs"][id] else Color("#e08a8a"))
	PixelFont.draw(draw_node, Vector2(90, 212), "Equipo: 3 materiales iguales. Rueda para desplazar.", COL_DIM)


func _draw_buyer() -> void:
	var h := hero if hero else local_hero()
	_panel(_inv_rect(), "Comprador")
	PixelFont.draw(draw_node, Vector2(40, 60), PixelFont.wrap("Te compro lo que sea. Clic en un montón para venderlo entero. Madera, palos y tablones: 1 moneda.", 26), COL_TXT)
	PixelFont.draw(draw_node, Vector2(40, 110), "Monedas: %d" % h.model.coins, COL_GOLD)
	_draw_inv_grid(h)
	var mp := draw_node.get_local_mouse_position()
	for i in Inventory.SIZE:
		if _slot_rect(i).has_point(mp):
			_tooltip(mp, h.model.inv.slots[i])


func _draw_altar() -> void:
	var al := Content.find(Content.ALTARS, npc.altar_id)
	_panel(Rect2(120, 60, 240, 120), "Altar")
	PixelFont.draw_centered(draw_node, 240, 84, al["name"], COL_GOLD)
	PixelFont.draw_centered(draw_node, 240, 100, PixelFont.wrap("Una ofrenda de %d monedas. Los dioses son caprichosos: pueden bendecirte... o no." % Content.ALTAR_PRICE, 48), COL_TXT)
	var r := Rect2(170, 150, 140, 16)
	draw_node.draw_rect(r, Color("#3a2e50") if r.has_point(draw_node.get_local_mouse_position()) else Color("#2a2238"))
	PixelFont.draw_centered(draw_node, 240, 155, "Ofrecer %d monedas" % Content.ALTAR_PRICE, COL_GOLD)


func _draw_skill_pick() -> void:
	draw_node.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.6))
	PixelFont.draw_centered(draw_node, 240, 50, "Elige una habilidad", COL_GOLD, 2)
	for k in skill_opts.size():
		var s := Content.find(Content.SKILLS, skill_opts[k])
		var r := Rect2(60 + k * 125, 80, 115, 110)
		var tc = {"guerrero": Color("#c0302a"), "mago": Color("#3a5ae0"), "explorador": Color("#3aa04a")}[s["type"]]
		var hov := r.has_point(draw_node.get_local_mouse_position())
		draw_node.draw_rect(r, tc.darkened(0.55 if not hov else 0.35))
		draw_node.draw_rect(r, tc.lightened(0.3), false, 1.0)
		PixelFont.draw_centered(draw_node, r.get_center().x, r.position.y + 8, s["name"], COL_TXT, 1)
		PixelFont.draw_centered(draw_node, r.get_center().x, r.position.y + 20, s["type"], tc.lightened(0.4))
		PixelFont.draw_centered(draw_node, r.get_center().x, r.position.y + 36, PixelFont.wrap(s["desc"], 26), COL_TXT)
		var info := "recarga %ds" % int(s["cd"])
		if float(s["dur"]) > 0.0:
			info += "  ·  dura %ds" % int(s["dur"])
		PixelFont.draw_centered(draw_node, r.get_center().x, r.end.y - 12, info, COL_DIM)


func _draw_pause() -> void:
	draw_node.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.6))
	PixelFont.draw_centered(draw_node, 240, 50, "Pausa", COL_GOLD, 3)
	var items := _pause_items()
	for k in items.size():
		var r := Rect2(170, 90 + k * 18, 140, 16)
		var hov := r.has_point(draw_node.get_local_mouse_position())
		draw_node.draw_rect(r, Color("#3a2e50") if hov else Color("#221c2e"))
		PixelFont.draw_centered(draw_node, 240, r.position.y + 5, items[k], COL_TXT)
	PixelFont.draw_centered(draw_node, 240, 200, "Semilla %d%s" % [run.seed_value, "  ·  modo demente" if run.madman else ""], COL_DIM)


func _draw_options() -> void:
	draw_node.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.7))
	PixelFont.draw_centered(draw_node, 240, 40, "Opciones", COL_GOLD, 2)
	var items := [
		"Efectos  %d%%" % int(Game.settings["sfx"] * 100), "Música  %d%%" % int(Game.settings["music"] * 100),
		"Pantalla completa: %s" % ("sí" if Game.settings["fullscreen"] else "no"),
		"Temblor de pantalla: %s" % ("sí" if Game.settings["shake"] else "no"), "Controles", "Volver"]
	for k in items.size():
		var r := Rect2(130, 70 + k * 18, 220, 16)
		draw_node.draw_rect(r, Color("#3a2e50") if r.has_point(draw_node.get_local_mouse_position()) else Color("#221c2e"))
		PixelFont.draw_centered(draw_node, 240, r.position.y + 5, items[k], COL_TXT)
	PixelFont.draw_centered(draw_node, 240, 186, "Clic izquierdo sube, derecho baja", COL_DIM)


func _draw_controls() -> void:
	draw_node.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.8))
	PixelFont.draw_centered(draw_node, 240, 18, "Controles", COL_GOLD, 2)
	var keys := Game.LABELS.keys()
	for k in keys.size():
		var r := Rect2(120, 36 + k * 13, 240, 12)
		var a: String = keys[k]
		draw_node.draw_rect(r, Color("#3a2e50") if r.has_point(draw_node.get_local_mouse_position()) else Color("#1e1828"))
		PixelFont.draw(draw_node, r.position + Vector2(4, 4), Game.LABELS[a], COL_TXT)
		var kl := "..." if rebinding == a else Game.key_label(a)
		PixelFont.draw(draw_node, r.position + Vector2(r.size.x - PixelFont.width(kl) - 4, 4), kl, COL_GOLD)
	PixelFont.draw_centered(draw_node, 240, 236, "Clic en una acción y pulsa la nueva tecla. Esc: volver", COL_DIM)


func _draw_map() -> void:
	var w: World = run.world
	if w.is_town:
		return
	var m: Dictionary = w.map
	var gs: Vector2i = m["grid"]
	var cw := 40.0
	var ch := 22.0
	var o := Vector2(240 - gs.x * cw / 2.0, 135 - gs.y * ch / 2.0)
	draw_node.draw_rect(Rect2(o - Vector2(10, 20), Vector2(gs.x * cw + 20, gs.y * ch + 34)), Color(0.05, 0.03, 0.08, 0.85))
	PixelFont.draw_centered(draw_node, 240, o.y - 14, "Mapa del distrito", COL_GOLD)
	var h := local_hero()
	var hr := Vector2i(int(h.position.x / (32 * 16)), int((h.position.y - 1) / (18 * 16))) if h else Vector2i(-1, -1)
	for c in m["rooms"]:
		var r := Rect2(o + Vector2(c.x * cw + 2, c.y * ch + 2), Vector2(cw - 4, ch - 4))
		var col := Color("#3a3050")
		if c == m["exit_room"]:
			col = Color("#6a5a2a")
		if c == hr:
			col = Color("#8a7ab0") if int(t * 3.0) % 2 == 0 else Color("#6a5a90")
		draw_node.draw_rect(r, col)
		var op: Dictionary = m["rooms"][c]["open"]
		if op.has("R"):
			draw_node.draw_rect(Rect2(r.end.x, r.get_center().y - 2, 4, 4), col.lightened(0.2))
		if op.has("D"):
			draw_node.draw_rect(Rect2(r.get_center().x - 2, r.end.y, 4, 4), col.lightened(0.2))
	if m.get("boss", {}).has("pos") and w.boss_node != null:
		var bp: Vector2 = w.boss_node.position
		draw_node.draw_circle(o + Vector2(bp.x / 512.0 * cw, bp.y / 288.0 * ch), 2.5, Color("#e0304a"))
	for p in w.players:
		draw_node.draw_circle(o + Vector2(p.position.x / 512.0 * cw, p.position.y / 288.0 * ch), 2.0, Color.WHITE)
	PixelFont.draw_centered(draw_node, 240, o.y + gs.y * ch + 4, "amarillo: salida  ·  rojo: jefe", COL_DIM)
