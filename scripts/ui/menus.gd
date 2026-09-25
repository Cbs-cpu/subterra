class_name Menus
extends RefCounted
## Pantallas de Opciones y Controles compartidas por el menú principal y la pausa.
## Una sola geometría para dibujar y para detectar clics, así nunca se desalinean.

const OPT_PANEL := Rect2(110, 60, 260, 136)
const CTRL_PANEL := Rect2(36, 52, 408, 170)


static func option_rows() -> Array:
	var out := []
	for k in 5:
		out.append(Rect2(OPT_PANEL.position.x + 12, OPT_PANEL.position.y + 14 + k * 21, OPT_PANEL.size.x - 24, 18))
	return out


static func _slider(row: Rect2) -> Rect2:
	return Rect2(row.end.x - 118, row.get_center().y - 2.5, 84, 5)


## Aplica un clic en la fila k. Devuelve true si hay que abrir los controles.
static func option_click(k: int, button: int, m: Vector2) -> bool:
	var d := 0.1 if button == MOUSE_BUTTON_LEFT else -0.1
	var row: Rect2 = option_rows()[k]
	match k:
		0, 1:
			var key := "sfx" if k == 0 else "music"
			var sl := _slider(row).grow_individual(4, 6, 4, 6)
			if button == MOUSE_BUTTON_LEFT and sl.has_point(m):
				Game.settings[key] = snappedf(clampf((m.x - sl.position.x - 4) / (sl.size.x - 8), 0.0, 1.0), 0.05)
			else:
				Game.settings[key] = clampf(snappedf(Game.settings[key] + d, 0.05), 0.0, 1.0)
		2: Game.settings["fullscreen"] = not Game.settings["fullscreen"]
		3: Game.settings["shake"] = not Game.settings["shake"]
		4: return true
	Game.apply_settings()
	Game.save_profile()
	return false


static func draw_options(ci: CanvasItem, m: Vector2) -> void:
	UiKit.text(ci, Vector2(240, OPT_PANEL.position.y - 30), "Opciones", UiKit.H, UiKit.YELLOW, 1, {"kind": "display", "shadow": true})
	UiKit.panel(ci, OPT_PANEL)
	UiKit.new_layer()
	var rows := option_rows()
	var labels := ["Efectos de sonido", "Música", "Pantalla completa", "Temblor de pantalla", "Controles"]
	for k in rows.size():
		var r: Rect2 = rows[k]
		var hov := r.has_point(m)
		UiKit.box(ci, r, UiKit.PANEL_SEL if hov else Color(UiKit.PANEL_HI, 0.6), UiKit.LINE_HI if hov else Color(0, 0, 0, 0), 3)
		var ty := r.position.y + (r.size.y - UiKit.line_h(UiKit.M)) / 2.0
		UiKit.text(ci, Vector2(r.position.x + 8, ty), labels[k], UiKit.M, UiKit.TEXT, 0, {"max_w": 118})
		match k:
			0, 1:
				var v: float = Game.settings["sfx" if k == 0 else "music"]
				var sl := _slider(r)
				UiKit.bar(ci, sl, v, UiKit.GREEN if k == 0 else UiKit.LIME)
				ci.draw_circle(Vector2(sl.position.x + sl.size.x * v, sl.get_center().y), 3.2, UiKit.YELLOW, true, -1.0, true)
				UiKit.text(ci, Vector2(r.end.x - 8, ty), "%d%%" % roundi(v * 100), UiKit.M, UiKit.TEXT_DIM, 2, {"kind": "bold"})
			2, 3:
				_switch(ci, Vector2(r.end.x - 30, r.get_center().y), Game.settings["fullscreen" if k == 2 else "shake"])
			4:
				UiKit.text(ci, Vector2(r.end.x - 8, ty), "›", UiKit.L, UiKit.YELLOW, 2, {"kind": "bold"})
	UiKit.text(ci, Vector2(240, OPT_PANEL.end.y - 17), "Clic izquierdo sube · clic derecho baja", UiKit.S, UiKit.TEXT_MUTE, 1)


static func _switch(ci: CanvasItem, c: Vector2, on: bool) -> void:
	var r := Rect2(c - Vector2(11, 4.5), Vector2(22, 9))
	UiKit.box(ci, r, UiKit.GREEN_DEEP if on else Color(UiKit.INK, 0.7), UiKit.LIME if on else UiKit.LINE, 5)
	ci.draw_circle(Vector2(r.end.x - 4.5 if on else r.position.x + 4.5, c.y), 3.2, UiKit.YELLOW if on else UiKit.TEXT_MUTE, true, -1.0, true)
	UiKit.text(ci, Vector2(r.position.x - 5, c.y - UiKit.line_h(UiKit.S) / 2.0), "Sí" if on else "No", UiKit.S, UiKit.TEXT_DIM, 2, {"kind": "bold"})


static func control_rows() -> Array:
	var out := []
	var keys := Game.LABELS.keys()
	var per_col := int(ceil(keys.size() / 2.0))
	for k in keys.size():
		var col := k / per_col
		var row := k % per_col
		out.append({"a": keys[k], "r": Rect2(CTRL_PANEL.position.x + 12 + col * 196, CTRL_PANEL.position.y + 14 + row * 19, 188, 16)})
	return out


static func draw_controls(ci: CanvasItem, m: Vector2, rebinding: String) -> void:
	UiKit.text(ci, Vector2(240, CTRL_PANEL.position.y - 32), "Controles", UiKit.H, UiKit.YELLOW, 1, {"kind": "display", "shadow": true})
	UiKit.panel(ci, CTRL_PANEL)
	UiKit.new_layer()
	for e in control_rows():
		var r: Rect2 = e["r"]
		var a: String = e["a"]
		var hov := r.has_point(m)
		var waiting := rebinding == a
		UiKit.box(ci, r, UiKit.PANEL_SEL if hov or waiting else Color(UiKit.PANEL_HI, 0.6), UiKit.LIME if waiting else (UiKit.LINE_HI if hov else Color(0, 0, 0, 0)), 3)
		var ty := r.position.y + (r.size.y - UiKit.line_h(UiKit.S)) / 2.0
		var key := "pulsa una tecla…" if waiting else Game.key_label(a)
		var kw := UiKit.text_w(key, UiKit.S, "bold") + 6.0
		UiKit.text(ci, Vector2(r.position.x + 7, ty), Game.LABELS[a], UiKit.S, UiKit.TEXT, 0, {"max_w": r.size.x - kw - 18})
		if waiting:
			UiKit.text(ci, Vector2(r.end.x - 7, ty), key, UiKit.S, UiKit.YELLOW, 2, {"kind": "bold"})
		else:
			UiKit.keycap(ci, Vector2(r.end.x - 6, r.position.y + (r.size.y - UiKit.line_h(UiKit.S, "bold") - 1.0) / 2.0), key, UiKit.S, 2)
	UiKit.text(ci, Vector2(240, CTRL_PANEL.end.y - 15), "Clic en una acción y pulsa la tecla nueva · Esc: volver", UiKit.S, UiKit.TEXT_MUTE, 1)
	UiKit.text(ci, Vector2(240, CTRL_PANEL.end.y + 6), "Ratón: apuntar y usar · 1-5 o rueda: barra rápida", UiKit.S, UiKit.TEXT_DIM, 1)
