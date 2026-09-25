import re


def replace_func(src, name, new):
    i = src.index("\nfunc %s(" % name)
    j = src.find("\nfunc ", i + 1)
    if j == -1:
        j = len(src)
    return src[:i] + "\n" + new.rstrip("\n") + "\n\n" + src[j + 1:]


p = 'scripts/core/inventory.gd'
s = open(p, encoding='utf-8').read()
s = s.replace("## Inventario: 32 ranuras (las 8 primeras son la barra rápida) + equipo.", "## Inventario: 20 ranuras (las 5 primeras son la barra rápida) + equipo.")
s = s.replace("const SIZE := 32\nconst HOTBAR := 8", "const SIZE := 20\nconst HOTBAR := 5")
open(p, 'w', encoding='utf-8').write(s)

p = 'scripts/game/input_state.gd'
s = open(p, encoding='utf-8').read()
s = s.replace('\tfor i in 8:\n\t\tif Input.is_action_just_pressed("hot%d" % (i + 1)):', '\tfor i in Inventory.HOTBAR:\n\t\tif Input.is_action_just_pressed("hot%d" % (i + 1)):')
open(p, 'w', encoding='utf-8').write(s)

p = 'scripts/ui/game_ui.gd'
s = open(p, encoding='utf-8').read()
s = s.replace('const SLOT := 18\nconst COL_BG := Color("#1a1420")\nconst COL_BORDER := Color("#6a5a8a")',
              'const SLOT := 20\nconst COL_BG := Color("#2a1e16")\nconst COL_BORDER := Color("#5a4030")\nconst COL_DARK := Color("#120c08")\nconst COL_SLOT := Color("#1c140e")')
s = s.replace('act({"op": "hand", "i": (local_hero().model.inv.hand + 1) % 8})', 'act({"op": "hand", "i": (local_hero().model.inv.hand + 1) % Inventory.HOTBAR})')
s = s.replace('act({"op": "hand", "i": (local_hero().model.inv.hand + 7) % 8})', 'act({"op": "hand", "i": (local_hero().model.inv.hand + Inventory.HOTBAR - 1) % Inventory.HOTBAR})')

s = replace_func(s, "_inv_origin", '''func _inv_origin() -> Vector2:
	return Vector2(8, 118)''')
s = replace_func(s, "_inv_rect", '''func _inv_rect() -> Rect2:
	return Rect2(4, 14, 120, 216)''')
s = replace_func(s, "_slot_rect", '''func _slot_rect(i: int) -> Rect2:
	if i < Inventory.HOTBAR:
		return Rect2(6 + i * (SLOT + 2), 16, SLOT, SLOT)
	var k := i - Inventory.HOTBAR
	var o := _inv_origin()
	return Rect2(o.x + (k % 5) * (SLOT + 2) - 2, o.y + (k / 5) * (SLOT + 2), SLOT, SLOT)''')
s = replace_func(s, "_equip_rect", '''func _equip_rect(k: int) -> Rect2:
	# Columna izquierda: cabeza, cuerpo, escudo. Columna derecha: anillos.
	if k < 3:
		return Rect2(6, 44 + k * 22, SLOT, SLOT)
	return Rect2(102, 44 + (k - 3) * 22, SLOT, SLOT)''')
s = replace_func(s, "_panel", '''func _panel(r: Rect2, title := "") -> void:
	var c := draw_node
	c.draw_rect(r.grow(2), COL_DARK)
	c.draw_rect(r.grow(1), COL_BORDER)
	c.draw_rect(r, COL_BG)
	c.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), COL_BORDER.lightened(0.25))
	c.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), COL_BORDER.lightened(0.15))
	c.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), COL_DARK)
	if title != "":
		PixelFont.draw_centered(c, r.get_center().x, r.position.y + 5, title, COL_TXT)''')
s = replace_func(s, "_slot_box", '''func _slot_box(r: Rect2, hl := false, sel := false) -> void:
	var c := draw_node
	c.draw_rect(r.grow(1), COL_DARK)
	c.draw_rect(r, COL_SLOT if not hl else Color("#241a12"))
	c.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), COL_BORDER.darkened(0.2))
	if sel:
		c.draw_rect(r.grow(1), Color("#d8c8a0"), false, 1.0)''')
s = replace_func(s, "_draw_stack", '''func _draw_stack(pos: Vector2, s, show_n := true) -> void:
	var c := draw_node
	if s == null:
		return
	c.draw_texture(Art.icon(s["id"]), pos + Vector2(4, 4))
	var q: int = s.get("q", 0)
	if q > 0:
		c.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(2, 2)), QCOL[q])
	if show_n and s["n"] > 1:
		PixelFont.draw(c, pos + Vector2(SLOT - PixelFont.width(str(s["n"])), SLOT - 7), str(s["n"]), COL_TXT)
	if s.has("dur"):
		var maxd: int = ItemDB.get_item(s["id"]).get("dur", 1)
		var k := clampf(float(s["dur"]) / maxd, 0.0, 1.0)
		if k < 1.0:
			c.draw_rect(Rect2(pos + Vector2(3, SLOT - 3), Vector2(SLOT - 6, 1)), Color(0, 0, 0, 0.6))
			c.draw_rect(Rect2(pos + Vector2(3, SLOT - 3), Vector2((SLOT - 6) * k, 1)), Color("#5ae05a").lerp(Color("#e05a5a"), 1.0 - k))''')
s = replace_func(s, "_bar", '''func _bar(pos: Vector2, w: float, k: float, col: Color, label: String) -> void:
	var c := draw_node
	PixelFont.draw(c, pos + Vector2(w - PixelFont.width(label), -9), label, COL_TXT)
	c.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(w + 2, 6)), COL_DARK)
	c.draw_rect(Rect2(pos, Vector2(w, 4)), col.darkened(0.7))
	c.draw_rect(Rect2(pos, Vector2(w * clampf(k, 0.0, 1.0), 4)), col)
	c.draw_rect(Rect2(pos, Vector2(w * clampf(k, 0.0, 1.0), 1)), col.lightened(0.35))''')
s = replace_func(s, "_draw_hud", open('tools/ui_hud.gd.txt', encoding='utf-8').read())
s = replace_func(s, "_draw_inventory", open('tools/ui_inv.gd.txt', encoding='utf-8').read())
s = replace_func(s, "_draw_skill_pick", '''func _draw_skill_pick() -> void:
	var r := Rect2(300, 70, 170, 64)
	_panel(r, "Elige una rama")
	var types := ["guerrero", "mago", "explorador"]
	var cols := [Color("#b02a2a"), Color("#2a4ab0"), Color("#2a902a")]
	var mp := draw_node.get_local_mouse_position()
	for k in 3:
		var b := Rect2(r.position.x + 14 + k * 52, r.position.y + 20, 36, 30)
		var hov := b.has_point(mp)
		draw_node.draw_rect(b.grow(1), COL_DARK)
		draw_node.draw_rect(b, cols[k].lightened(0.15) if hov else cols[k])
		draw_node.draw_rect(Rect2(b.position, Vector2(b.size.x, 2)), cols[k].lightened(0.45))
		draw_node.draw_texture_rect(Art.icon(_skill_icon(types[k])), Rect2(b.position + Vector2(6, 3), Vector2(24, 24)), false)
		if hov:
			PixelFont.draw_centered(draw_node, 385, r.end.y + 6, types[k].capitalize(), cols[k].lightened(0.5))''')
s = s.replace('''		"habilidad":
			for k in skill_opts.size():
				var sid: String = skill_opts[k]
				out.append({"r": Rect2(60 + k * 125, 80, 115, 110), "f": func(_b, _s): _pick_skill(sid)})''', '''		"habilidad":
			var types := ["guerrero", "mago", "explorador"]
			for k in 3:
				var tp: String = types[k]
				out.append({"r": Rect2(314 + k * 52, 90, 36, 30), "f": func(_b, _s): _pick_path(tp)})''')
s = s.replace('''func _pick_skill(id: String) -> void:''', '''func _pick_path(tp: String) -> void:
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


func _pick_skill(id: String) -> void:''')
s = s.replace("\t\t_slot_box(r, i < 8, i == selected or i == craft_a)", "\t\t_slot_box(r, i < Inventory.HOTBAR, i == selected or i == craft_a)")
open(p, 'w', encoding='utf-8').write(s)
print("ok")
