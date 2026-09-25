class_name Fx
extends Node2D
## Partículas, textos flotantes, anillos, estelas y explosiones.

var parts: Array = []
var texts: Array = []
var rings: Array = []
var ghosts: Array = []


func tick(dt: float) -> void:
	for p in parts:
		p["life"] -= dt
		p["v"].y += p["g"] * dt
		p["p"] += p["v"] * dt
	parts = parts.filter(func(p): return p["life"] > 0.0)
	for tx in texts:
		tx["life"] -= dt
		tx["p"].y -= 18.0 * dt
	texts = texts.filter(func(tx): return tx["life"] > 0.0)
	for r in rings:
		r["life"] -= dt
	rings = rings.filter(func(r): return r["life"] > 0.0)
	for g in ghosts:
		g["life"] -= dt
	ghosts = ghosts.filter(func(g): return g["life"] > 0.0)
	queue_redraw()


func _add(p: Vector2, v: Vector2, col: Color, life: float, g := 300.0, s := 1.0) -> void:
	if parts.size() > 600:
		return
	parts.append({"p": p, "v": v, "col": col, "life": life, "max": life, "g": g, "s": s})


func burst(p: Vector2, col: Color, n := 6) -> void:
	for i in n:
		_add(p, Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30, 110), col, randf_range(0.25, 0.55))


func dust(p: Vector2, n := 3) -> void:
	for i in n:
		_add(p + Vector2(randf_range(-4, 4), -1), Vector2(randf_range(-40, 40), randf_range(-30, -5)),
			Color(0.8, 0.75, 0.65, 0.8), randf_range(0.2, 0.4), 40.0, 1.0)


func leaves(p: Vector2, biome: String) -> void:
	var col := Color(PropsArt.GRASS.get(biome, "#4a9a3a"))
	for i in 5:
		_add(p + Vector2(randf_range(-8, 8), randf_range(-8, 4)), Vector2(randf_range(-40, 40), randf_range(-60, -10)), col, 0.8, 120.0)


func sparkle(p: Vector2, col: Color) -> void:
	for i in 8:
		_add(p, Vector2.RIGHT.rotated(i * TAU / 8.0) * 50.0, col, 0.4, 0.0)


func ring(p: Vector2, col: Color) -> void:
	rings.append({"p": p, "col": col, "life": 0.3, "max": 0.3, "r": 14.0})


func explosion(p: Vector2, r: float) -> void:
	rings.append({"p": p, "col": Color("#ffd24a"), "life": 0.35, "max": 0.35, "r": r})
	burst(p, Color("#f58a2a"), 14)
	burst(p, Color("#56566b"), 8)


func text(p: Vector2, s: String, col: Color) -> void:
	texts.append({"p": p, "s": s, "col": col, "life": 0.9})


func afterimage(a: Node2D) -> void:
	ghosts.append({"node": a, "p": a.position, "life": 0.2, "facing": a.facing})


func _draw() -> void:
	for g in ghosts:
		var a = g["node"]
		if not is_instance_valid(a):
			continue
		var fr: Dictionary = Art.hero_frame(a.model.race_id, "dash", 0)
		draw_set_transform(g["p"], 0.0, Vector2(g["facing"], 1))
		draw_texture(fr["tex"], -Vector2(fr["origin"]), Color(0.6, 0.8, 1.0, g["life"] * 2.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for r in rings:
		var k: float = 1.0 - r["life"] / r["max"]
		var c: Color = r["col"]
		c.a *= 1.0 - k
		draw_arc(r["p"], r["r"] * (0.3 + k), 0.0, TAU, 20, c, 2.0)
	for p in parts:
		var c2: Color = p["col"]
		c2.a *= clampf(p["life"] / p["max"] * 2.0, 0.0, 1.0)
		draw_rect(Rect2(p["p"].round(), Vector2(p["s"], p["s"])), c2)
	# Los textos flotantes (`texts`) los dibuja GameUI en alta resolución, sin solaparse.
