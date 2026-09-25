class_name GameUI
extends CanvasLayer
## Interfaz durante la partida: HUD, inventario con crafteo, pueblo (tiendas, artesanos,
## comprador, altares), elección de habilidad, mapa, avisos y pausa.
##
## Se dibuja a resolución nativa con UiKit (texto nítido). Cada elemento tiene su zona fija
## y los textos variables se apilan o se recortan, así que nunca se pisan entre sí. Los
## rótulos del mundo (nombres, diálogos, números de daño) también se dibujan aquí, colocados
## sobre la entidad y apartados si chocan con otro rótulo.

signal quit_to_menu

const SLOT := 20
const GAP := 3
const INV_PANEL := Rect2(60, 56, 360, 166)
const BACK_BTN := Rect2(14, 242, 76, 18)
const HUD_TOP := 44.0                  # alto de las zonas superiores del HUD
const PROMPT_W := 196.0                # ancho máximo de los avisos centrales (no llegan a las notas)
const NOTES_W := 128.0                 # ancho de la columna de notificaciones (derecha)
const EQUIP_NAMES := ["Cab", "Cue", "Esc", "Ani", "Ani"]
const STAT_KEYS := ["hp", "atk", "dex", "mag"]
const STAT_LABELS := ["Vida", "Ataque", "Destreza", "Magia"]
const SKILL_TYPES := ["guerrero", "mago", "explorador"]
const SKILL_NAMES := {"guerrero": "Guerrero", "mago": "Mago", "explorador": "Explorador"}
const SKILL_COLS := {"guerrero": Color("#c8483c"), "mago": Color("#4a78d8"), "explorador": Color("#4aa84a")}

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
var held_key := ""
var held_t := 0.0
# Animaciones de la interfaz.
var panel_t := 1.0            # tiempo desde que se abrió el panel actual
var last_panel := ""
var hp_ghost := 1.0           # estela de la barra de vida
var hp_hold := 0.0
var coins_shown := 0.0        # las monedas cuentan hacia arriba
var coin_flash := 0.0
var hand_t := 1.0             # salto de la ranura al cambiar de objeto
var last_hand := -1
var level_t := 1.0            # destello del nivel al subir
var last_level := -1


func _ready() -> void:
	layer = 20
	scale = Vector2(2, 2)
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
	return (panel != "" and panel != "mapa") or Console.open


func _process(dt: float) -> void:
	t += dt
	msg_t = maxf(0.0, msg_t - dt)
	held_t = maxf(0.0, held_t - dt)
	panel_t += dt
	hand_t += dt
	level_t += dt
	coin_flash = maxf(0.0, coin_flash - dt)
	if panel != last_panel:
		last_panel = panel
		panel_t = 0.0
	for n in notes:
		n["t"] -= dt
	notes = notes.filter(func(n): return n["t"] > 0.0)
	if card.size() > 0:
		card["t"] -= dt
		if card["t"] <= 0.0:
			card = {}
	if Input.is_action_just_pressed("map") and (panel == "" or panel == "mapa"):
		panel = "mapa" if panel == "" else ""
	# El nombre del objeto en la mano aparece un momento al cambiarlo.
	var h := local_hero()
	if h:
		_animate_hud(h, dt)
		var s = h.model.inv.held()
		var k := "%d:%s" % [h.model.inv.hand, s["id"] if s != null else ""]
		if k != held_key:
			held_key = k
			held_t = 2.2 if s != null else 0.0
	draw_node.queue_redraw()


func _animate_hud(h: Hero, dt: float) -> void:
	var m := h.model
	var k := float(m.hp) / m.max_hp()
	if k >= hp_ghost:
		hp_ghost = k
		hp_hold = 0.0
	else:
		hp_hold += dt
		if hp_hold > 0.35:
			hp_ghost = move_toward(hp_ghost, k, dt * 1.2)
	if last_level >= 0 and m.level > last_level:
		level_t = 0.0
	last_level = m.level
	if m.inv.hand != last_hand:
		if last_hand >= 0:
			hand_t = 0.0
		last_hand = m.inv.hand
	if absf(coins_shown - m.coins) > 0.5:
		if m.coins > coins_shown:
			coin_flash = 0.3
		coins_shown = move_toward(coins_shown, m.coins, maxf(1.0, absf(m.coins - coins_shown) * dt * 8.0))
	else:
		coins_shown = m.coins


func notify(text: String, col: Color) -> void:
	notes.append({"s": text, "c": col, "t": 3.5})
	if notes.size() > 6:
		notes = notes.slice(notes.size() - 6)


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
		var total := shop_items.size() if panel == "tienda" else _npc_list().size()
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll = mini(scroll + 1, maxi(0, total - 8))
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll = maxi(0, scroll - 1)
	if ev is InputEventMouseButton and ev.pressed and panel == "" and local_hero() != null:
		if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			act({"op": "hand", "i": (local_hero().model.inv.hand + 1) % Inventory.HOTBAR})
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			act({"op": "hand", "i": (local_hero().model.inv.hand + Inventory.HOTBAR - 1) % Inventory.HOTBAR})


func _click(m: Vector2, button: int, shift: bool) -> void:
	for b in _buttons():
		if b["r"].has_point(m):
			if panel in ["pausa", "opciones", "controles", "habilidad", "altar", "tienda", "artesano"]:
				Sfx.play("menu")
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
				out.append({"r": _list_row(k - scroll), "f": func(_b, _s): act({"op": "buy", "id": id})})
		"artesano":
			var list := _npc_list()
			for k in range(scroll, mini(scroll + 8, list.size())):
				var r2: Dictionary = list[k]
				out.append({"r": _list_row(k - scroll), "f": func(_b, _s): act({"op": "npc_craft", "npc": npc.kind, "out": r2["out"]})})
		"altar":
			out.append({"r": _altar_btn(), "f": func(_b, _s): act({"op": "altar", "id": npc.altar_id})})
		"habilidad":
			for k in 3:
				var tp: String = SKILL_TYPES[k]
				out.append({"r": _skill_card(k), "f": func(_b, _s): _pick_path(tp)})
		"pausa":
			var items := _pause_items()
			for k in items.size():
				var kk := k
				out.append({"r": _pause_rect(k), "f": func(_b, _s): _pause_pick(kk)})
		"opciones":
			var rows := Menus.option_rows()
			for k in rows.size():
				var kk2 := k
				out.append({"r": rows[k], "f": func(b, _s): _option_pick(kk2, b)})
			out.append({"r": BACK_BTN, "f": func(_b, _s): panel = "pausa"})
		"controles":
			for e in Menus.control_rows():
				var a: String = e["a"]
				out.append({"r": e["r"], "f": func(_b, _s): rebinding = a})
			out.append({"r": BACK_BTN, "f": func(_b, _s): panel = "opciones"})
	return out


func _pick_path(tp: String) -> void:
	var h := hero if hero else local_hero()
	var pool := []
	for sk in Content.SKILLS:
		if sk["type"] == tp and (not h.model.skills.has(sk["id"]) or sk["id"] == "lobo"):
			pool.append(sk["id"])
	if pool.is_empty():
		for sk in Content.SKILLS:
			if not h.model.skills.has(sk["id"]):
				pool.append(sk["id"])
	_pick_skill(pool[run.rng.randi() % pool.size()])


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
	if Menus.option_click(k, button, draw_node.get_local_mouse_position()):
		panel = "controles"


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

func _inv_rect() -> Rect2:
	return INV_PANEL


## Rejilla del inventario: fila 0 = barra rápida, filas 1-3 = mochila.
func _slot_rect(i: int) -> Rect2:
	var x0 := INV_PANEL.end.x - 12 - (5 * SLOT + 4 * GAP)
	if i < Inventory.HOTBAR:
		return Rect2(x0 + i * (SLOT + GAP), INV_PANEL.position.y + 36, SLOT, SLOT)
	var k := i - Inventory.HOTBAR
	return Rect2(x0 + (k % 5) * (SLOT + GAP), INV_PANEL.position.y + 76 + (k / 5) * (SLOT + GAP), SLOT, SLOT)


## Equipo: cabeza, cuerpo y escudo a la izquierda del retrato; anillos a la derecha.
func _equip_rect(k: int) -> Rect2:
	var x := INV_PANEL.position.x + 12
	var y := INV_PANEL.position.y + 36
	if k < 3:
		return Rect2(x, y + k * (SLOT + GAP), SLOT, SLOT)
	return Rect2(x + SLOT + 60, y + (k - 3) * (SLOT + GAP), SLOT, SLOT)


func _hat_rect() -> Rect2:
	return Rect2(INV_PANEL.position.x + 12 + SLOT + 60, INV_PANEL.position.y + 36 + 2 * (SLOT + GAP), SLOT, SLOT)


func _portrait_rect() -> Rect2:
	var x := INV_PANEL.position.x + 12 + SLOT + 4
	return Rect2(x, INV_PANEL.position.y + 36, 52, 3 * SLOT + 2 * GAP)


## Barra rápida del HUD y habilidades, centradas abajo.
func _hud_group_w(n_skills: int) -> float:
	var w := 5.0 * SLOT + 4.0 * GAP
	if n_skills > 0:
		w += 10.0 + n_skills * 18.0 + (n_skills - 1) * GAP
	return w


func _hud_slot(i: int, n_skills: int) -> Rect2:
	var x0 := 240.0 - _hud_group_w(n_skills) / 2.0
	return Rect2(x0 + i * (SLOT + GAP), 270 - 8 - SLOT, SLOT, SLOT)


func _hud_skill(k: int, n_skills: int) -> Rect2:
	var x0 := 240.0 - _hud_group_w(n_skills) / 2.0 + 5.0 * SLOT + 4.0 * GAP + 10.0
	return Rect2(x0 + k * (18 + GAP), 270 - 8 - 19, 18, 18)


func _list_panel() -> Rect2:
	return Rect2(80, 50, 320, 188)


func _list_row(i: int) -> Rect2:
	var p := _list_panel()
	return Rect2(p.position.x + 10, p.position.y + 36 + i * 18, p.size.x - 20, 16)


func _altar_btn() -> Rect2:
	return Rect2(170, 166, 140, 18)


func _skill_card(k: int) -> Rect2:
	return Rect2(120 + k * 82, 92, 76, 92)


func _pause_rect(k: int) -> Rect2:
	return Rect2(170, 96 + k * 22, 140, 18)


# --- Piezas de dibujo ------------------------------------------------------------------------------

func _mouse() -> Vector2:
	return draw_node.get_local_mouse_position()


func _draw_stack(pos: Vector2, s, show_n := true) -> void:
	var c := draw_node
	if s == null:
		return
	c.draw_texture(Art.icon(s["id"]), pos + Vector2(4, 4))
	var q: int = s.get("q", 0)
	if q > 0:
		c.draw_circle(pos + Vector2(3.5, 3.5), 1.6, UiKit.QUALITY[q], true, -1.0, true)
	if show_n and s["n"] > 1:
		UiKit.text(c, Vector2(pos.x + SLOT - 1.5, pos.y + SLOT - UiKit.line_h(UiKit.XS, "bold") + 0.5), str(s["n"]),
			UiKit.XS, UiKit.TEXT, 2, {"kind": "bold", "outline": 2})
	if s.has("dur"):
		var maxd: int = ItemDB.get_item(s["id"]).get("dur", 1)
		var k := clampf(float(s["dur"]) / maxd, 0.0, 1.0)
		if k < 1.0:
			var br := Rect2(pos + Vector2(3, SLOT - 3), Vector2(SLOT - 6, 1.2))
			c.draw_rect(br, Color(0, 0, 0, 0.6))
			c.draw_rect(Rect2(br.position, Vector2(br.size.x * k, br.size.y)), UiKit.GREEN.lerp(UiKit.RED, 1.0 - k))


func _slot_box(r: Rect2, hl := false, sel := false) -> void:
	var c := draw_node
	UiKit.box(c, r, Color("#08170e", 0.92) if not hl else Color("#0e2616", 0.95), Color(UiKit.LINE, 0.9), 3)
	if sel:
		UiKit.box(c, r.grow(0.8), Color(0, 0, 0, 0), UiKit.YELLOW, 4)


func _draw_ui() -> void:
	var h := local_hero()
	if run == null:
		return
	var full := panel != "" and panel != "mapa"
	_draw_world_labels(h)
	if h and not run.finished:
		_draw_hud(h, full)
	if not full:
		_draw_notes()
		_draw_prompts(h)
	# Los paneles aparecen con un pequeño zoom desde el centro.
	var e := ease(clampf(panel_t / 0.14, 0.0, 1.0), 0.4)
	var sc := lerpf(0.94, 1.0, e)
	if panel != "" and sc < 1.0:
		draw_node.draw_set_transform(Vector2(240, 135) * (1.0 - sc) + Vector2(0, (1.0 - e) * 4.0), 0.0, Vector2(sc, sc))
	match panel:
		"inventario": _draw_inventory()
		"tienda": _draw_shop()
		"artesano": _draw_crafter()
		"comprador": _draw_buyer()
		"altar": _draw_altar()
		"habilidad": _draw_skill_pick()
		"pausa": _draw_pause()
		"opciones": _draw_overlay_menu("opciones")
		"controles": _draw_overlay_menu("controles")
		"mapa": _draw_map()
	draw_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- HUD -------------------------------------------------------------------------------------------

func _draw_hud(h: Hero, full: bool) -> void:
	var c := draw_node
	var m := h.model
	# --- Arriba a la izquierda: nivel, vida, maná, hambre, estamina y monedas.
	UiKit.box(c, Rect2(4, 3, 142, HUD_TOP), Color(UiKit.BG_DEEP, 0.55), Color(UiKit.LINE, 0.35), 5)
	var bc := Vector2(18, 17)
	var need := HeroModel.xp_to_next(m.level)
	c.draw_circle(bc, 11.0, Color("#0a1d11"), true, -1.0, true)
	c.draw_arc(bc, 10.0, 0.0, TAU, 40, Color(UiKit.GOLD_DEEP, 0.45), 1.8, true)
	if m.xp > 0:
		c.draw_arc(bc, 10.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(float(m.xp) / need, 0.0, 1.0), 40, UiKit.YELLOW, 1.8, true)
	if level_t < 0.8:
		var lk := level_t / 0.8
		c.draw_arc(bc, 11.0 + lk * 10.0, 0.0, TAU, 40, Color(UiKit.YELLOW, 1.0 - lk), 2.0, true)
	UiKit.text(c, Vector2(bc.x, bc.y - UiKit.line_h(UiKit.L, "bold") / 2.0), str(m.level), UiKit.L, UiKit.YELLOW, 1, {"kind": "bold", "max_w": 17})
	var hp_r := Rect2(34, 7, 104, 9)
	UiKit.bar(c, hp_r, float(m.hp) / m.max_hp(), UiKit.RED if float(m.hp) / m.max_hp() > 0.3 or int(t * 4.0) % 2 == 0 else Color("#ff8a7a"),
		Color(UiKit.INK, 0.75), hp_ghost)
	UiKit.text(c, Vector2(hp_r.end.x - 4, hp_r.get_center().y - UiKit.line_h(UiKit.S, "bold") / 2.0), "%d/%d" % [m.hp, m.max_hp()],
		UiKit.S, UiKit.TEXT, 2, {"kind": "bold", "outline": 2})
	var mp_r := Rect2(34, 18.5, 104, 7)
	UiKit.bar(c, mp_r, m.mana / m.max_mana(), UiKit.BLUE)
	UiKit.text(c, Vector2(mp_r.end.x - 4, mp_r.get_center().y - UiKit.line_h(UiKit.XS, "bold") / 2.0), "%d/%d" % [int(m.mana), m.max_mana()],
		UiKit.XS, UiKit.TEXT, 2, {"kind": "bold", "outline": 2})
	var starving := m.hunger <= 0.0
	c.draw_texture_rect(Art.icon("carne_asada"), Rect2(33, 27, 8, 8), false)
	UiKit.bar(c, Rect2(43, 29.5, 40, 3), m.hunger / m.max_hunger(), UiKit.ORANGE if not starving or int(t * 4.0) % 2 == 0 else UiKit.RED)
	_bolt(Vector2(92, 31))
	UiKit.bar(c, Rect2(98, 29.5, 40, 3), m.stamina / m.max_stamina(), UiKit.YELLOW)
	c.draw_texture_rect(Art.coin_icon(), Rect2(33, 36.5, 8, 8), false)
	UiKit.text(c, Vector2(44, 40.5 - UiKit.line_h(UiKit.S, "bold") / 2.0), str(roundi(coins_shown)), UiKit.S,
		UiKit.YELLOW.lerp(Color.WHITE, coin_flash / 0.3), 0, {"kind": "bold", "max_w": 90})
	# --- Arriba a la derecha: lugar y temporizador de la Ceniza.
	var w: World = run.world
	var place: String = "Pueblo" if w.is_town else Content.biome(w.biome)["name"]
	var sub: String = "Zona segura" if w.is_town else ("El final" if w.biome == "nido" else "Distrito %d de %d" % [run.district, Content.FINAL_DISTRICT - 1])
	var tl := w.time_left()
	var ash := ""
	if tl >= 0.0:
		ash = "Guardianes en %d:%02d" % [int(maxf(tl, 0.0)) / 60, int(maxf(tl, 0.0)) % 60] if tl > 0.0 else "¡Guardianes!"
	var right_w := maxf(UiKit.text_w(place, UiKit.M, "bold"), UiKit.text_w(sub, UiKit.XS))
	right_w = minf(maxf(right_w, UiKit.text_w(ash, UiKit.S, "bold") + 12.0), 150.0) + 14.0
	UiKit.box(c, Rect2(476 - right_w, 3, right_w, HUD_TOP if ash != "" else 26), Color(UiKit.BG_DEEP, 0.55), Color(UiKit.LINE, 0.35), 5)
	UiKit.text(c, Vector2(469, 5), place, UiKit.M, UiKit.TEXT, 2, {"kind": "bold", "max_w": 150})
	UiKit.text(c, Vector2(469, 5 + UiKit.line_h(UiKit.M, "bold")), sub, UiKit.XS, UiKit.TEXT_DIM, 2, {"max_w": 150})
	if ash != "":
		var urgent := tl <= 30.0
		var ac := (UiKit.RED if int(t * 4.0) % 2 == 0 else Color("#ffd0c8")) if urgent else UiKit.LIME
		var ar := Rect2(469 - UiKit.text_w(ash, UiKit.S, "bold") - 10, 29, UiKit.text_w(ash, UiKit.S, "bold") + 10, 12)
		UiKit.box(c, ar, Color(ac, 0.14), Color(ac, 0.6), 6)
		UiKit.text(c, Vector2(ar.get_center().x, ar.position.y + (12 - UiKit.line_h(UiKit.S, "bold")) / 2.0), ash, UiKit.S, ac, 1, {"kind": "bold"})
	# --- Jefe (arriba en el centro).
	var bn = w.boss_node
	if bn != null and is_instance_valid(bn) and not bn.dead and bn.center().distance_to(h.center()) < 420.0:
		UiKit.text(c, Vector2(240, 5), bn.data["name"], UiKit.S, Color("#ffc0b0"), 1, {"kind": "bold", "outline": 2, "max_w": 140})
		UiKit.bar(c, Rect2(172, 16, 136, 5), float(bn.hp) / bn.max_hp, Color("#d8402f"))
	if full:
		return
	# --- Mejoras activas (fichas) y compañeros de grupo, bajo el bloque izquierdo.
	var y := HUD_TOP + 7.0
	var bx := 6.0
	for b in m.buffs:
		var label := "%s · %ds" % [_buff_label(b), int(b["t"])]
		var bw := UiKit.text_w(label, UiKit.XS, "bold") + 8.0
		if bx + bw > 146.0:
			bx = 6.0
			y += 11.0
		UiKit.box(c, Rect2(bx, y, bw, 9), Color(UiKit.YELLOW, 0.15), Color(UiKit.YELLOW, 0.55), 4)
		UiKit.text(c, Vector2(bx + 4, y + (9 - UiKit.line_h(UiKit.XS, "bold")) / 2.0), label, UiKit.XS, UiKit.YELLOW, 0, {"kind": "bold"})
		bx += bw + 3.0
	if not m.buffs.is_empty():
		y += 13.0
	for p in w.players:
		if p == h:
			continue
		var nr := UiKit.text(c, Vector2(6, y), p.model.name, UiKit.XS, Color("#ffb0a0") if p.downed else UiKit.TEXT_DIM, 0, {"kind": "bold", "outline": 2, "max_w": 60})
		if p.downed:
			UiKit.text(c, Vector2(nr.end.x + 4, y), "abatido", UiKit.XS, UiKit.RED, 0, {"outline": 2})
		else:
			UiKit.bar(c, Rect2(70, y + 2.5, 40, 3), float(p.model.hp) / p.model.max_hp(), UiKit.RED)
		y += 10.0
	# --- Barra rápida y habilidades, abajo en el centro.
	var ns := m.skills.size()
	for i in Inventory.HOTBAR:
		var r := _hud_slot(i, ns)
		var on := i == m.inv.hand
		if on:
			r.position.y -= 2
			if hand_t < 0.18:
				r = r.grow((1.0 - hand_t / 0.18) * 2.0)
		_slot_box(r, on, on)
		_draw_stack(r.position, m.inv.slots[i])
	for k in ns:
		var sid: String = m.skills[k]
		var r2 := _hud_skill(k, ns)
		var sk := Content.find(Content.SKILLS, sid)
		var tc: Color = SKILL_COLS[sk["type"]]
		UiKit.box(c, r2, tc.darkened(0.45), tc.lightened(0.2), 4)
		c.draw_texture(Art.icon(_skill_icon(sk["type"])), r2.position + Vector2(3, 3))
		var cd: float = m.skill_cd.get(sid, 0.0)
		if cd > 0.0:
			var kcd := clampf(cd / float(sk["cd"]), 0.0, 1.0)
			c.draw_rect(Rect2(r2.position + Vector2(1, 1), Vector2(r2.size.x - 2, (r2.size.y - 2) * kcd)), Color(0, 0, 0, 0.6))
		UiKit.text(c, Vector2(r2.position.x + 2, r2.position.y + 0.5), ["Z", "X", "C"][k] if k < 3 else "", UiKit.XS, UiKit.TEXT, 0, {"kind": "bold", "outline": 2})
	# --- Cartel del distrito.
	if card.size() > 0 and panel == "":
		var a := minf(clampf(card["t"], 0.0, 1.0), clampf((2.6 - card["t"]) / 0.35, 0.0, 1.0))
		UiKit.vgrad(c, Rect2(0, 62, 480, 22), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45 * a))
		UiKit.vgrad(c, Rect2(0, 84, 480, 22), Color(0, 0, 0, 0.45 * a), Color(0, 0, 0, 0))
		var tr := UiKit.text(c, Vector2(240, 64), card["title"], UiKit.H, Color(UiKit.YELLOW, a), 1, {"kind": "display", "shadow": true, "max_w": 300})
		UiKit.ornament(c, Vector2(240, tr.end.y + 3), 50, Color(UiKit.GOLD, 0.8 * a))
		UiKit.text(c, Vector2(240, tr.end.y + 7), card["sub"], UiKit.S, Color(UiKit.TEXT, a), 1, {"max_w": 300})
	if run.party_dead_t >= 0.0:
		UiKit.text(c, Vector2(240, 118), "Todo el grupo ha caído", 16, UiKit.RED, 1, {"kind": "display", "shadow": true, "outline": 2})


## Nombre legible de una mejora activa ("Furia", "Ataque +3"…).
func _buff_label(b: Dictionary) -> String:
	if b.has("flag"):
		for sk in Content.SKILLS:
			if sk["id"] == b["flag"]:
				return sk["name"]
		return {"arcana": "Armas arcanas", "carga": "Carga"}.get(b["flag"], str(b["flag"]).capitalize())
	var stat: String = b.get("stat", "")
	return "%s +%d" % [{"atk": "Ataque", "dex": "Destreza", "mag": "Magia"}.get(stat, stat), int(b.get("amount", 0))]


func _bolt(p: Vector2) -> void:
	draw_node.draw_colored_polygon(PackedVector2Array([p + Vector2(0.5, -4), p + Vector2(-2.5, 0.5), p + Vector2(-0.3, 0.5),
		p + Vector2(-1, 4), p + Vector2(2.5, -1), p + Vector2(0.3, -1), p + Vector2(1.5, -4)]), UiKit.YELLOW)


func _skill_icon(kind: String) -> String:
	return {"guerrero": "espada_hierro", "mago": "baston_rayo", "explorador": "arco"}.get(kind, "espada_hierro")


## Líneas de los avisos de abajo en el centro (de abajo arriba): objeto en la mano, pista
## de interacción y mensajes.
func _prompt_lines(h: Hero) -> Array:
	var lines := []
	if panel != "" and panel != "mapa":
		return lines
	if h and held_t > 0.0 and panel == "":
		var held = h.model.inv.held()
		if held != null:
			lines.append({"s": ItemDB.get_item(held["id"]).get("name", ""), "col": UiKit.QUALITY[held.get("q", 0)], "a": clampf(held_t * 2.0, 0.0, 1.0)})
	if msg_t > 0.0:
		# Los mensajes largos se parten (como mucho 2 líneas) en vez de invadir los laterales.
		var parts := UiKit.wrap_lines(msg, UiKit.S, PROMPT_W - 12.0)
		if parts.size() > 2:
			parts = parts.slice(0, 2)
			parts[1] = UiKit.ellipsize(parts[1] + "…", UiKit.S, PROMPT_W - 12.0)
		for i in range(parts.size() - 1, -1, -1):
			lines.append({"s": parts[i], "col": UiKit.TEXT, "a": clampf(msg_t * 2.0, 0.0, 1.0)})
	return lines


func _prompt_lh() -> float:
	return UiKit.line_h(UiKit.S) + 3.0


## Zona que ocupan los avisos centrales (para que los rótulos del mundo no la pisen).
func _prompt_zone(n: int) -> Rect2:
	var bottom := 270.0 - 8.0 - SLOT - 6.0
	var hgt := n * (_prompt_lh() + 2.0)
	return Rect2(240 - PROMPT_W / 2.0, bottom - hgt, PROMPT_W, hgt)


## Zona de la columna de notificaciones.
func _notes_zone() -> Rect2:
	var hgt := notes.size() * (UiKit.line_h(UiKit.S) + 2.0)
	return Rect2(474 - NOTES_W, 262.0 - hgt, NOTES_W, hgt)


## Avisos de abajo en el centro, apilados hacia arriba sobre la barra rápida. Nunca se pisan.
func _draw_prompts(h: Hero) -> void:
	var c := draw_node
	var y := 270.0 - 8.0 - SLOT - 6.0
	var lh := _prompt_lh()
	for ln in _prompt_lines(h):
		y -= lh
		var a: float = ln["a"]
		var key: String = ln.get("key", "")
		var kw := 0.0 if key == "" else UiKit.text_w(key, UiKit.S, "bold") + 5.0 + 4.0
		var tw := minf(UiKit.text_w(ln["s"], UiKit.S), PROMPT_W - 12.0 - kw)
		var pw := tw + kw + 12.0
		var pr := Rect2(240 - pw / 2.0, y, pw, lh)
		UiKit.box(c, pr, Color(UiKit.BG_DEEP, 0.72 * a), Color(UiKit.LINE, 0.5 * a), 6)
		var x := pr.position.x + 6.0
		if key != "":
			var kr := UiKit.keycap(c, Vector2(x, y + 1), key, UiKit.S)
			x = kr.end.x + 4.0
		var col: Color = ln["col"]
		UiKit.text(c, Vector2(x, y + 1.5), ln["s"], UiKit.S, Color(col, a), 0, {"max_w": tw + 0.5})
		y -= 2.0


## Notificaciones (objetos recogidos, niveles…): abajo a la derecha, apiladas hacia arriba.
func _draw_notes() -> void:
	var y := 262.0
	var lh := UiKit.line_h(UiKit.S) + 2.0
	for i in range(notes.size() - 1, -1, -1):
		var n: Dictionary = notes[i]
		var col: Color = n["c"]
		# Entran con un fundido y una subida corta (sin salirse de su columna).
		var e := ease(clampf((3.5 - n["t"]) / 0.2, 0.0, 1.0), 0.4)
		col.a = minf(clampf(n["t"], 0.0, 1.0), e)
		y -= lh
		UiKit.text(draw_node, Vector2(474, y + (1.0 - e) * 5.0), n["s"], UiKit.S, col, 2, {"kind": "bold", "outline": 2, "max_w": NOTES_W})


# --- Rótulos sobre el mundo ------------------------------------------------------------------------

## Posición en la interfaz (480x270) de un punto local de un nodo del mundo. El mundo se
## dibuja en el SubViewport de Run (WORLD_RES, ampliado WORLD_SCALE) y esta capa va a escala x2.
func _to_screen(node: CanvasItem, p: Vector2) -> Vector2:
	var vp_pos := node.get_global_transform_with_canvas() * p
	var box_pos: Vector2 = run.world_box.position if run.world_box else Vector2.ZERO
	return (box_pos + vp_pos * Run.WORLD_SCALE) / scale.x


## Coloca una caja cerca de donde quiere estar, subiéndola hasta que no toque ninguna ya
## colocada. Devuelve Rect2() (vacío) si no cabe sin tapar el HUD.
func _place(r: Rect2, placed: Array) -> Rect2:
	r.position.x = clampf(r.position.x, 4.0, 476.0 - r.size.x)
	for _i in 16:
		var hit := false
		for p in placed:
			if p.grow(UiKit.MIN_GAP + 0.5).intersects(r):
				r.position.y = p.position.y - UiKit.MIN_GAP - 1.0 - r.size.y
				hit = true
		if not hit:
			break
	if r.position.y < HUD_TOP + 6.0 or r.end.y > 270.0 - 8.0 - SLOT - 4.0:
		return Rect2()
	placed.append(r)
	return r


func _draw_world_labels(h: Hero) -> void:
	var w: World = run.world
	if w == null or panel in ["pausa", "opciones", "controles"]:
		return
	var c := draw_node
	# Zonas reservadas: avisos centrales y notificaciones. Los rótulos se apartan de ellas.
	var placed: Array = []
	var np := _prompt_lines(h).size()
	if np > 0:
		placed.append(_prompt_zone(np))
	if not notes.is_empty():
		placed.append(_notes_zone())
	# Cartel de entrada a la zona (título y subtítulo en el centro de arriba).
	if card.size() > 0 and panel == "":
		placed.append(Rect2(240 - 150, 60, 300, 56))
	var items: Array = []
	# Pista de lo que se tiene a un clic (lo mismo que marca el aura dorada): va la primera,
	# sobre el propio objeto, con su tecla. Es lo único que lleva nombre además de las puertas.
	var fc: Dictionary = w.focus
	var focused: Node = null
	if not fc.is_empty() and panel == "":
		var it: Dictionary = fc["interact"]
		if not it.is_empty():
			focused = it["node"]
			items.append({"kind": "prompt", "p": _to_screen(w, _top_of(focused)), "key": Game.key_label("interact"), "s": it["verb"]})
		elif not fc["harvest"].is_empty():
			var hn: Node = fc["harvest"][0]
			var verb: String = {"arbol": "Talar", "roca": "Minar", "luz_bicho": "Atrapar"}.get(hn.kind, "Usar")
			# Los árboles son altos: la pista va a la altura de la cabeza del héroe, junto al golpe.
			var hr: Rect2 = fc["hero"].rect()
			items.append({"kind": "prompt", "p": _to_screen(w, Vector2(hn.rect().get_center().x, minf(hr.position.y - 6.0, hn.rect().position.y - 2.0) if hn.kind != "arbol" else hr.position.y - 6.0)), "key": "Clic", "s": verb})
	# Diálogos de vecinos.
	for n in w.npcs:
		if n.kind == "vecino" and n.talk_t > 0.0:
			items.append({"kind": "bubble", "p": _to_screen(n, Vector2(0, -22)), "s": Npc.LINES[n.line_i], "a": clampf(n.talk_t * 2.0, 0.0, 1.0)})
	# Puertas: su bioma siempre a la vista, para elegir camino de un vistazo. El resto de
	# nombres (tiendas, artesanos…) solo aparece en la pista al acercarse.
	for n in w.npcs:
		if n.kind == "puerta" and n != focused:
			var dc := Color(Content.biome(n.biome)["door"]).lightened(0.35)
			items.append({"kind": "label", "p": _to_screen(n, Vector2(0, -54)), "s": n.label(), "col": dc, "size": UiKit.S})
	# Jugadores: nombre en cooperativo y petición de ayuda si están abatidos.
	for p in w.players:
		if p.downed:
			items.append({"kind": "label", "p": _to_screen(p, Vector2(0, -20)), "s": "¡Ayuda!", "col": UiKit.YELLOW if int(t * 3.0) % 2 == 0 else Color("#ffb070"), "size": UiKit.S})
		elif w.players.size() > 1:
			items.append({"kind": "label", "p": _to_screen(p, Vector2(0, -28)), "s": p.model.name, "col": Color("#cfefff") if p.is_local else Color("#ffe4a8"), "size": UiKit.XS})
	# Textos flotantes (daño, monedas…): los más recientes al final.
	if w.fx:
		for tx in w.fx.texts:
			var col: Color = tx["col"]
			col.a = clampf(tx["life"] * 3.0, 0.0, 1.0)
			items.append({"kind": "label", "p": _to_screen(w.fx, tx["p"]), "s": tx["s"], "col": col, "size": UiKit.S})
	for it in items:
		var p: Vector2 = it["p"]
		if p.x < -10.0 or p.x > 490.0 or p.y < 0.0 or p.y > 290.0:
			continue
		if it["kind"] == "prompt":
			var key: String = it["key"]
			var kw := UiKit.text_w(key, UiKit.S, "bold") + 5.0 + 4.0
			var tw2 := minf(UiKit.text_w(it["s"], UiKit.S, "bold"), 150.0)
			var ph := UiKit.line_h(UiKit.S, "bold") + 4.0
			var bob := sin(t * 4.0) * 1.0
			var pr := _place(Rect2(p.x - (tw2 + kw + 10.0) / 2.0, p.y - ph - 4.0 + bob, tw2 + kw + 10.0, ph), placed)
			if pr.size == Vector2.ZERO:
				continue
			UiKit.box(c, pr, Color(UiKit.BG_DEEP, 0.85), Color(UiKit.YELLOW, 0.8), 4)
			var kr := UiKit.keycap(c, Vector2(pr.position.x + 5.0, pr.position.y + 1.5), key, UiKit.S)
			UiKit.text(c, Vector2(kr.end.x + 4.0, pr.position.y + 2.0), it["s"], UiKit.S, UiKit.YELLOW, 0, {"kind": "bold", "max_w": tw2 + 0.5})
			continue
		if it["kind"] == "bubble":
			var s: String = it["s"]
			var bw := minf(UiKit.text_w(s, UiKit.S), 130.0)
			var th := UiKit.paragraph_h(s, UiKit.S, bw)
			var r := _place(Rect2(p.x - bw / 2.0 - 6.0, p.y - th - 8.0, bw + 12.0, th + 6.0), placed)
			if r.size == Vector2.ZERO:
				continue
			var a: float = it["a"]
			UiKit.box(c, r, Color("#f4efd8", 0.95 * a), Color("#8a7a44", a), 4, 1, 2)
			var tip := Vector2(clampf(p.x, r.position.x + 6.0, r.end.x - 6.0), r.end.y)
			c.draw_colored_polygon(PackedVector2Array([tip + Vector2(-3, -0.5), tip + Vector2(3, -0.5), tip + Vector2(0, 4)]), Color("#f4efd8", 0.95 * a))
			UiKit.paragraph(c, Rect2(r.position.x + 6.0, r.position.y + 3.0, bw, th + 1.0), s, UiKit.S, Color("#2a2410", a))
		else:
			var size: int = it["size"]
			var s2: String = it["s"]
			var tw := minf(UiKit.text_w(s2, size, "bold"), 160.0)
			var r2 := _place(Rect2(p.x - tw / 2.0, p.y - UiKit.line_h(size, "bold"), tw, UiKit.line_h(size, "bold")), placed)
			if r2.size == Vector2.ZERO:
				continue
			UiKit.text(c, Vector2(r2.get_center().x, r2.position.y), s2, size, it["col"], 1, {"kind": "bold", "outline": 2, "max_w": 160})


## Punto del mundo justo encima de un nodo (centro de su borde superior).
func _top_of(n: Node) -> Vector2:
	var r: Rect2 = n.rect()
	return Vector2(r.get_center().x, r.position.y - 2.0)


# --- Paneles ------------------------------------------------------------------------------------------

func _tooltip(pos: Vector2, s) -> void:
	if s == null:
		return
	var c := draw_node
	var it := ItemDB.get_item(s["id"])
	var q: int = s.get("q", 0)
	var title: String = it.get("name", s["id"])
	if q > 0:
		title += " (" + Recipes.QUALITY_NAMES[q] + ")"
	var lines := []
	var st := []
	for k in ["hp", "atk", "dex", "mag"]:
		var v := int(it.get(k, 0)) + int(s.get("bonus", {}).get(k, 0))
		if v != 0:
			st.append("%s %+d" % [{"hp": "Vida", "atk": "Ataque", "dex": "Destreza", "mag": "Magia"}[k], v])
	if not st.is_empty():
		lines.append(", ".join(st))
	if s.has("dur"):
		lines.append("Durabilidad %d/%d" % [s["dur"], it.get("dur", 0)])
	if it.has("tool"):
		lines.append("Herramienta: %s, nivel %d" % [it["tool"], it.get("tier", 0)])
	if it.has("food"):
		lines.append("Hambre +%d" % it["food"]["hunger"])
	if it.has("potion") and it["potion"].has("hp"):
		lines.append("Cura %d" % it["potion"]["hp"])
	if it.has("spell"):
		lines.append("Hechizo (%d de maná)" % it.get("mana", 1))
	var hint := "Clic derecho: equipar" if it.has("slot") else ""
	var w := UiKit.text_w(title, UiKit.M, "bold")
	for l in lines:
		w = maxf(w, UiKit.text_w(l, UiKit.S))
	w = minf(maxf(w, UiKit.text_w(hint, UiKit.XS)), 170.0)
	var lh := UiKit.line_h(UiKit.S) + 1.0
	var hh := UiKit.line_h(UiKit.M, "bold") + 2.0 + lines.size() * lh + (UiKit.line_h(UiKit.XS) + 3.0 if hint != "" else 0.0)
	var r := Rect2(pos + Vector2(12, 6), Vector2(w + 14, hh + 9))
	if r.end.x > 476.0:
		r.position.x = pos.x - r.size.x - 8.0
	if r.end.y > 266.0:
		r.position.y = 266.0 - r.size.y
	UiKit.new_layer()
	UiKit.box(c, r, Color("#07130c", 0.97), UiKit.QUALITY[q] if q > 0 else UiKit.LINE_HI, 4, 1, 4)
	var y := r.position.y + 4.0
	UiKit.text(c, Vector2(r.position.x + 7, y), title, UiKit.M, UiKit.QUALITY[q] if q > 0 else UiKit.YELLOW, 0, {"kind": "bold", "max_w": w})
	y += UiKit.line_h(UiKit.M, "bold") + 2.0
	for l in lines:
		UiKit.text(c, Vector2(r.position.x + 7, y), l, UiKit.S, UiKit.TEXT, 0, {"max_w": w})
		y += lh
	if hint != "":
		UiKit.text(c, Vector2(r.position.x + 7, y + 2.0), hint, UiKit.XS, UiKit.TEXT_MUTE, 0, {"max_w": w})


func _draw_inv_grid(h: Hero) -> void:
	var c := draw_node
	var inv := h.model.inv
	var x0 := _slot_rect(0).position.x
	UiKit.text(c, Vector2(x0, _slot_rect(0).position.y - UiKit.line_h(UiKit.XS, "bold") - 2), "BARRA RÁPIDA", UiKit.XS, UiKit.TEXT_MUTE, 0, {"kind": "bold", "spacing": 0.5})
	UiKit.text(c, Vector2(x0, _slot_rect(5).position.y - UiKit.line_h(UiKit.XS, "bold") - 2), "MOCHILA", UiKit.XS, UiKit.TEXT_MUTE, 0, {"kind": "bold", "spacing": 0.5})
	for i in Inventory.SIZE:
		var r := _slot_rect(i)
		_slot_box(r, i < Inventory.HOTBAR, i == selected)
		if i == craft_a:
			UiKit.box(c, r.grow(0.8), Color(0, 0, 0, 0), UiKit.LIME, 4)
		_draw_stack(r.position, inv.slots[i])


func _panel_open(r: Rect2, title: String) -> void:
	UiKit.new_layer()
	UiKit.panel(draw_node, r, title)


func _draw_inventory() -> void:
	var h := hero if hero else local_hero()
	if h == null:
		return
	var c := draw_node
	var m := h.model
	_panel_open(INV_PANEL, "Inventario")
	UiKit.text(c, Vector2(INV_PANEL.end.x - 12, INV_PANEL.position.y + 8), "Recetas  %d / %d" % [Game.known_recipes().size(), Recipes.pairs().size()],
		UiKit.S, UiKit.TEXT_DIM, 2, {"kind": "bold"})
	_draw_inv_grid(h)
	# Retrato con el equipo alrededor.
	var pr := _portrait_rect()
	UiKit.box(c, pr, Color(UiKit.BG_DEEP, 0.75), Color(UiKit.LINE, 0.6), 4)
	var fr: Dictionary = Art.hero_frame(m.race_id, "idle", int(t * 3.0))
	var tex: Texture2D = fr["tex"]
	# Los fotogramas se colocan por su anclaje de los pies (`origin`).
	var feet := Vector2(pr.get_center().x, pr.end.y - 5)
	var og: Vector2 = Vector2(fr.get("origin", Vector2i(7, 18)))
	c.draw_texture_rect(tex, Rect2(feet - og * 2, tex.get_size() * 2), false)
	var ht = Art.hat(m.hat_id)
	if ht:
		var hp: Vector2 = feet + (Vector2(fr["head"]) - og + Vector2(-6, -10)) * 2.0
		c.draw_texture_rect(ht, Rect2(hp, ht.get_size() * 2.0), false)
	var eq := Inventory.EQUIP_SLOTS
	for k in eq.size():
		var r := _equip_rect(k)
		_slot_box(r)
		if m.inv.equip[eq[k]] == null:
			UiKit.text(c, Vector2(r.get_center().x, r.get_center().y - UiKit.line_h(UiKit.XS) / 2.0), EQUIP_NAMES[k], UiKit.XS, Color(UiKit.TEXT_MUTE, 0.7), 1)
		_draw_stack(r.position, m.inv.equip[eq[k]])
	var hr := _hat_rect()
	_slot_box(hr)
	if ht:
		c.draw_texture(ht, hr.position + Vector2(3, 4))
	else:
		UiKit.text(c, Vector2(hr.get_center().x, hr.get_center().y - UiKit.line_h(UiKit.XS) / 2.0), "Som", UiKit.XS, Color(UiKit.TEXT_MUTE, 0.7), 1)
	# Ficha: nombre, estadísticas y rasgos.
	var sx := _hat_rect().end.x + 10.0
	var sw := _slot_rect(0).position.x - 14.0 - sx
	var y := INV_PANEL.position.y + 34.0
	UiKit.text(c, Vector2(sx, y), m.name, UiKit.M, UiKit.YELLOW, 0, {"kind": "bold", "max_w": sw})
	y += UiKit.line_h(UiKit.M, "bold") + 2.0
	for i in 4:
		var g: int = m.growth[STAT_KEYS[i]]
		var gc: Color = [Color("#ff9a8a"), UiKit.TEXT, Color("#a8f08a")][g]
		UiKit.text(c, Vector2(sx, y), STAT_LABELS[i], UiKit.S, UiKit.TEXT_DIM, 0, {"max_w": sw - 20})
		UiKit.text(c, Vector2(sx + sw, y), str(m.stat(STAT_KEYS[i])), UiKit.S, gc, 2, {"kind": "bold"})
		y += UiKit.line_h(UiKit.S) + 1.0
	var ty := _portrait_rect().end.y + 8.0
	var lw := _slot_rect(0).position.x - 14.0 - (INV_PANEL.position.x + 12.0)
	UiKit.text(c, Vector2(INV_PANEL.position.x + 12, ty), "RASGOS", UiKit.XS, UiKit.TEXT_MUTE, 0, {"kind": "bold", "spacing": 0.5})
	ty += UiKit.line_h(UiKit.XS, "bold") + 1.0
	for tr in m.traits:
		var td: Dictionary = Content.find(Content.TRAITS, tr)
		var nr := UiKit.text(c, Vector2(INV_PANEL.position.x + 12, ty), td["name"], UiKit.S, UiKit.LIME, 0, {"kind": "bold", "max_w": 70})
		# La descripción va debajo del nombre y se parte en líneas (la fuente pixelada es ancha).
		ty += UiKit.line_h(UiKit.S)
		ty += UiKit.paragraph(c, Rect2(INV_PANEL.position.x + 18, ty, lw - 6, (UiKit.line_h(UiKit.S) + 1.5) * 2.0), td.get("desc", ""), UiKit.S, UiKit.TEXT_DIM) + 3.0
	# Estado del crafteo.
	var cy := INV_PANEL.end.y - 20.0
	if craft_a >= 0 and m.inv.slots[craft_a] != null:
		UiKit.box(c, Rect2(INV_PANEL.position.x + 12, cy, lw, 13), Color(UiKit.LIME, 0.12), Color(UiKit.LIME, 0.5), 4)
		UiKit.text(c, Vector2(INV_PANEL.position.x + 18, cy + (13 - UiKit.line_h(UiKit.S)) / 2.0),
			"Combinar %s con…" % ItemDB.get_item(m.inv.slots[craft_a]["id"]).get("name", ""), UiKit.S, UiKit.LIME, 0, {"max_w": lw - 12})
	# Consejo inferior.
	_tip_bar("Mayús + clic en dos objetos: combinar  ·  Clic derecho: equipar  ·  Clic fuera: tirar")
	var mp := _mouse()
	for i in Inventory.SIZE:
		if _slot_rect(i).has_point(mp):
			_tooltip(mp, m.inv.slots[i])
	for k in eq.size():
		if _equip_rect(k).has_point(mp):
			_tooltip(mp, m.inv.equip[eq[k]])


func _tip_bar(s: String) -> void:
	var w := minf(UiKit.text_w(s, UiKit.S) + 16.0, 468.0)
	var r := Rect2(240 - w / 2.0, 250, w, 13)
	UiKit.box(draw_node, r, Color(UiKit.BG_DEEP, 0.8), Color(UiKit.LINE, 0.6), 6)
	UiKit.text(draw_node, Vector2(240, r.position.y + (13 - UiKit.line_h(UiKit.S)) / 2.0), s, UiKit.S, UiKit.TEXT_DIM, 1, {"max_w": w - 12})


func _scroll_marks(first: int, shown: int, total: int) -> void:
	var p := _list_panel()
	var x := p.end.x - 6.0
	if first > 0:
		draw_node.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, p.position.y + 38), Vector2(x + 3, p.position.y + 38), Vector2(x, p.position.y + 34)]), UiKit.YELLOW)
	if first + shown < total:
		var yb := _list_row(7).end.y + 2.0
		draw_node.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, yb), Vector2(x + 3, yb), Vector2(x, yb + 4)]), UiKit.YELLOW)


func _list_header(left: String, right: String, coins: int = -1) -> void:
	var p := _list_panel()
	var y := p.position.y + 22.0
	var x := p.position.x + 12.0
	if coins >= 0:
		draw_node.draw_texture_rect(Art.coin_icon(), Rect2(x, y + 1, 8, 8), false)
		x += 11.0
		var r := UiKit.text(draw_node, Vector2(x, y), str(coins), UiKit.S, UiKit.YELLOW, 0, {"kind": "bold"})
		x = r.end.x + 8.0
	if left != "":
		UiKit.text(draw_node, Vector2(x, y), left, UiKit.S, UiKit.TEXT_DIM, 0, {"max_w": p.end.x - 110.0 - x})
	UiKit.text(draw_node, Vector2(p.end.x - 12, y), right, UiKit.XS, UiKit.TEXT_MUTE, 2, {"max_w": 90})


func _draw_shop() -> void:
	var h := hero if hero else local_hero()
	var c := draw_node
	_panel_open(_list_panel(), npc.label())
	_list_header("", "Rueda: desplazar", h.model.coins)
	var mp := _mouse()
	var shown := mini(8, shop_items.size() - scroll)
	for k in range(scroll, scroll + shown):
		var id: String = shop_items[k]
		var r := _list_row(k - scroll)
		var hov := r.has_point(mp)
		UiKit.box(c, r, UiKit.PANEL_SEL if hov else Color(UiKit.PANEL_HI, 0.6), UiKit.LINE_HI if hov else Color(0, 0, 0, 0), 3)
		c.draw_texture(Art.icon(id), r.position + Vector2(3, 2))
		var p := InvOps.price(id)
		var ps := str(p)
		var pw := UiKit.text_w(ps, UiKit.S, "bold")
		var ty := r.position.y + (r.size.y - UiKit.line_h(UiKit.S)) / 2.0
		UiKit.text(c, Vector2(r.position.x + 20, ty), ItemDB.get_item(id)["name"], UiKit.S, UiKit.TEXT, 0, {"max_w": r.size.x - 20 - pw - 24})
		UiKit.text(c, Vector2(r.end.x - 6, ty), ps, UiKit.S, UiKit.YELLOW if h.model.coins >= p else Color("#c07a6a"), 2, {"kind": "bold"})
		c.draw_texture_rect(Art.coin_icon(), Rect2(r.end.x - 6 - pw - 11, r.get_center().y - 4, 8, 8), false)
	_scroll_marks(scroll, shown, shop_items.size())


func _draw_crafter() -> void:
	var h := hero if hero else local_hero()
	var c := draw_node
	_panel_open(_list_panel(), npc.label())
	_list_header("Equipo: 3 materiales iguales", "Rueda: desplazar")
	var list := _npc_list()
	if list.is_empty():
		UiKit.paragraph(c, Rect2(110, 120, 260, 40), "No llevas nada con lo que pueda trabajar. Tráeme lingotes, menas, telas o cuero.", UiKit.M, UiKit.TEXT_DIM, 1)
	var mp := _mouse()
	var shown := mini(8, list.size() - scroll)
	for k in range(scroll, scroll + shown):
		var rc: Dictionary = list[k]
		var r := _list_row(k - scroll)
		var can := h.model.inv.can_npc(npc.kind, rc["out"])
		var hov := r.has_point(mp)
		UiKit.box(c, r, UiKit.PANEL_SEL if hov else Color(UiKit.PANEL_HI, 0.6), UiKit.LINE_HI if hov else Color(0, 0, 0, 0), 3)
		c.draw_texture(Art.icon(rc["out"]), r.position + Vector2(3, 2))
		var ty := r.position.y + (r.size.y - UiKit.line_h(UiKit.S)) / 2.0
		# Materiales, de derecha a izquierda.
		var x := r.end.x - 6.0
		for id in rc["needs"]:
			var s := "x%d" % rc["needs"][id]
			var sw := UiKit.text_w(s, UiKit.S, "bold")
			UiKit.text(c, Vector2(x, ty), s, UiKit.S, UiKit.LIME if h.model.inv.count(id) >= rc["needs"][id] else Color("#f08a7a"), 2, {"kind": "bold"})
			x -= sw + 14.0
			c.draw_texture(Art.icon(id), Vector2(x, r.position.y + 2))
			x -= 6.0
		UiKit.text(c, Vector2(r.position.x + 20, ty), ItemDB.get_item(rc["out"])["name"], UiKit.S, UiKit.TEXT if can else UiKit.TEXT_MUTE, 0,
			{"max_w": x - r.position.x - 24})
	_scroll_marks(scroll, shown, list.size())


func _draw_buyer() -> void:
	var h := hero if hero else local_hero()
	var c := draw_node
	_panel_open(INV_PANEL, "Comprador")
	var lw := _slot_rect(0).position.x - 14.0 - (INV_PANEL.position.x + 12.0)
	var y := INV_PANEL.position.y + 34.0
	y += UiKit.paragraph(c, Rect2(INV_PANEL.position.x + 12, y, lw, 60), "Te compro lo que sea. Haz clic en un montón para venderlo entero.", UiKit.S, UiKit.TEXT) + 6.0
	y += UiKit.paragraph(c, Rect2(INV_PANEL.position.x + 12, y, lw, 40), "Madera, palos y tablones: 1 moneda.", UiKit.S, UiKit.TEXT_DIM) + 10.0
	c.draw_texture_rect(Art.coin_icon(), Rect2(INV_PANEL.position.x + 12, y + 1, 10, 10), false)
	UiKit.text(c, Vector2(INV_PANEL.position.x + 26, y), str(h.model.coins), UiKit.L, UiKit.YELLOW, 0, {"kind": "bold"})
	_draw_inv_grid(h)
	var mp := _mouse()
	for i in Inventory.SIZE:
		if _slot_rect(i).has_point(mp):
			_tooltip(mp, h.model.inv.slots[i])


func _draw_altar() -> void:
	var c := draw_node
	var al := Content.find(Content.ALTARS, npc.altar_id)
	var pr := Rect2(130, 70, 220, 124)
	_panel_open(pr, "Altar")
	UiKit.text(c, Vector2(240, pr.position.y + 26), al["name"], UiKit.M, UiKit.YELLOW, 1, {"kind": "bold", "max_w": pr.size.x - 24})
	UiKit.paragraph(c, Rect2(pr.position.x + 14, pr.position.y + 42, pr.size.x - 28, 44),
		"Una ofrenda de %d monedas. Los dioses son caprichosos: pueden bendecirte… o no." % Content.ALTAR_PRICE, UiKit.S, UiKit.TEXT_DIM, 1)
	UiKit.button(c, _altar_btn(), "Ofrecer %d monedas" % Content.ALTAR_PRICE, _altar_btn().has_point(_mouse()), {"primary": true, "size": UiKit.S})


func _draw_skill_pick() -> void:
	var c := draw_node
	c.draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.45))
	var pr := Rect2(110, 62, 260, 132)
	_panel_open(pr, "¡Nuevo nivel! Elige una rama")
	var mp := _mouse()
	for k in 3:
		var tp: String = SKILL_TYPES[k]
		var r := _skill_card(k)
		var hov := r.has_point(mp)
		var col: Color = SKILL_COLS[tp]
		UiKit.box(c, r, col.darkened(0.55 if not hov else 0.4), col.lightened(0.3) if hov else col.darkened(0.1), 5, 1, 3 if hov else 0)
		c.draw_rect(Rect2(r.position.x + 4, r.position.y + 1, r.size.x - 8, 1.2), Color(col.lightened(0.5), 0.8))
		c.draw_texture_rect(Art.icon(_skill_icon(tp)), Rect2(r.get_center().x - 12, r.position.y + 10, 24, 24), false)
		UiKit.text(c, Vector2(r.get_center().x, r.position.y + 40), SKILL_NAMES[tp], UiKit.M, UiKit.TEXT, 1, {"kind": "bold", "max_w": r.size.x - 8})
		UiKit.paragraph(c, Rect2(r.position.x + 6, r.position.y + 54, r.size.x - 12, 32), "Una habilidad al azar de esta rama", UiKit.XS, UiKit.TEXT_DIM, 1)


func _draw_pause() -> void:
	var c := draw_node
	c.draw_rect(Rect2(0, 0, 480, 270), Color(0.01, 0.03, 0.02, 0.72))
	UiKit.new_layer()
	UiKit.text(c, Vector2(240, 44), "Pausa", 22, UiKit.YELLOW, 1, {"kind": "display", "shadow": true})
	UiKit.ornament(c, Vector2(240, 44 + UiKit.line_h(22, "display") + 3), 60, Color(UiKit.GOLD, 0.8))
	var items := _pause_items()
	var mp := _mouse()
	for k in items.size():
		UiKit.button(c, _pause_rect(k), items[k], _pause_rect(k).has_point(mp), {"primary": k == 0})
	UiKit.text(c, Vector2(240, 214), "Semilla %d%s" % [run.seed_value, "  ·  modo Demente" if run.madman else ""], UiKit.S, UiKit.TEXT_MUTE, 1)


func _draw_overlay_menu(which: String) -> void:
	var c := draw_node
	c.draw_rect(Rect2(0, 0, 480, 270), Color(0.01, 0.03, 0.02, 0.8))
	UiKit.new_layer()
	if which == "opciones":
		Menus.draw_options(c, _mouse())
	else:
		Menus.draw_controls(c, _mouse(), rebinding)
	UiKit.button(c, BACK_BTN, "‹  Volver", BACK_BTN.has_point(_mouse()))


func _draw_map() -> void:
	var w: World = run.world
	if w.is_town:
		return
	var c := draw_node
	var m: Dictionary = w.map
	var gs: Vector2i = m["grid"]
	var cw := 40.0
	var ch := 22.0
	var o := Vector2(240 - gs.x * cw / 2.0, 140 - gs.y * ch / 2.0)
	var pr := Rect2(o - Vector2(12, 26), Vector2(gs.x * cw + 24, gs.y * ch + 48))
	_panel_open(pr, "Mapa del distrito")
	var h := local_hero()
	var hr := Vector2i(int(h.position.x / (32 * 16)), int((h.position.y - 1) / (18 * 16))) if h else Vector2i(-1, -1)
	for cell in m["rooms"]:
		var r := Rect2(o + Vector2(cell.x * cw + 2, cell.y * ch + 2), Vector2(cw - 4, ch - 4))
		var col := UiKit.PANEL_HI.lightened(0.1)
		if cell == m["exit_room"]:
			col = UiKit.GOLD_DEEP
		if cell == hr:
			col = UiKit.GREEN if int(t * 3.0) % 2 == 0 else UiKit.GREEN_DEEP
		UiKit.box(c, r, col, col.lightened(0.25), 2)
		var op: Dictionary = m["rooms"][cell]["open"]
		if op.has("R"):
			c.draw_rect(Rect2(r.end.x, r.get_center().y - 2, 4, 4), col.lightened(0.15))
		if op.has("D"):
			c.draw_rect(Rect2(r.get_center().x - 2, r.end.y, 4, 4), col.lightened(0.15))
	if m.get("boss", {}).has("pos") and w.boss_node != null:
		var bp: Vector2 = w.boss_node.position
		c.draw_circle(o + Vector2(bp.x / 512.0 * cw, bp.y / 288.0 * ch), 2.8, UiKit.RED, true, -1.0, true)
	for p in w.players:
		c.draw_circle(o + Vector2(p.position.x / 512.0 * cw, p.position.y / 288.0 * ch), 2.2, Color.WHITE, true, -1.0, true)
	# Leyenda.
	var ly := pr.end.y - 13.0
	var items := [[UiKit.GOLD_DEEP, "Salida"], [UiKit.RED, "Jefe"], [UiKit.GREEN, "Estás aquí"]]
	var total := 0.0
	for it in items:
		total += UiKit.text_w(it[1], UiKit.XS) + 14.0
	var x := 240.0 - total / 2.0
	for it in items:
		UiKit.box(c, Rect2(x, ly + 2, 6, 6), it[0], Color(0, 0, 0, 0), 1)
		var r2 := UiKit.text(c, Vector2(x + 9, ly), it[1], UiKit.XS, UiKit.TEXT_DIM, 0)
		x = r2.end.x + 8.0
