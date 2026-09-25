class_name TitleBackdrop
extends Node2D
## Fondo animado de la portada y los menús, dibujado en vectorial (no pixel art):
## una caverna musgosa con una grieta en el techo por la que entra luz dorada, raíces y
## lianas colgando, esporas brillantes que suben, setas luminosas y hierba que se mece.
## Las capas se desplazan un poco con el ratón (paralaje).

const W := 480.0
const H := 270.0

var t := 0.0
var dim := 0.0               # 0 = portada, 1 = submenús (fondo más apagado)
var _dim_to := 0.0
var _par := Vector2.ZERO
var _far := PackedVector2Array()
var _mid_l := PackedVector2Array()
var _mid_r := PackedVector2Array()
var _ceil := PackedVector2Array()
var _floor := PackedVector2Array()
var _vines: Array = []
var _spores: Array = []
var _shrooms: Array = []
var _blades: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rng.seed = 20260925
	_build()


func set_dimmed(on: bool) -> void:
	_dim_to = 1.0 if on else 0.0


func _process(dt: float) -> void:
	t += dt
	dim = move_toward(dim, _dim_to, dt * 3.0)
	var m := get_local_mouse_position()
	var want := Vector2(clampf((m.x - W / 2.0) / (W / 2.0), -1.0, 1.0), clampf((m.y - H / 2.0) / (H / 2.0), -1.0, 1.0))
	_par = _par.lerp(want, clampf(dt * 2.5, 0.0, 1.0))
	for s in _spores:
		s["p"].y -= s["v"] * dt
		s["p"].x += sin(t * s["f"] + s["ph"]) * 6.0 * dt
		if s["p"].y < -6.0:
			s["p"] = Vector2(_rng.randf_range(0, W), H + 4.0)
	queue_redraw()


# --- Construcción de las formas (una vez) --------------------------------------------------

func _ridge(y0: float, amp: float, step: float, freq: float, seed_off: float, top: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := -40.0
	while x <= W + 40.0:
		var y := y0 + sin(x * freq + seed_off) * amp + sin(x * freq * 2.7 + seed_off * 1.9) * amp * 0.45 \
			+ sin(x * freq * 6.1 + seed_off * 0.7) * amp * 0.18
		pts.append(Vector2(x, y))
		x += step
	if top:
		pts.append(Vector2(W + 40.0, -160.0))
		pts.append(Vector2(-40.0, -160.0))
	else:
		pts.append(Vector2(W + 40.0, H + 40.0))
		pts.append(Vector2(-40.0, H + 40.0))
	return pts


func _open(pts: PackedVector2Array, width: float, depth: float) -> PackedVector2Array:
	var out := pts.duplicate()
	for i in out.size() - 2:
		var p: Vector2 = out[i]
		p.y -= exp(-pow((p.x - W / 2.0) / width, 2.0)) * depth
		out[i] = p
	return out


func _side(x_edge: float, dir: float, seed_off: float) -> PackedVector2Array:
	# Pared lateral de la caverna (dir = 1 pared izquierda, -1 derecha).
	var pts := PackedVector2Array()
	var y := -30.0
	while y <= H + 30.0:
		var bulge := 40.0 + sin(y * 0.021 + seed_off) * 26.0 + sin(y * 0.063 + seed_off * 2.0) * 10.0
		pts.append(Vector2(x_edge + dir * bulge, y))
		y += 6.0
	pts.append(Vector2(x_edge - dir * 40.0, H + 30.0))
	pts.append(Vector2(x_edge - dir * 40.0, -30.0))
	return pts


func _build() -> void:
	_far = _ridge(58.0, 16.0, 6.0, 0.018, 1.3, true)
	_ceil = _ridge(20.0, 14.0, 5.0, 0.026, 4.1, true)
	# Grieta en el centro del techo por donde entra la luz.
	_far = _open(_far, 44.0, 40.0)
	_ceil = _open(_ceil, 30.0, 70.0)
	_mid_l = _side(-20.0, 1.0, 0.4)
	_mid_r = _side(W + 20.0, -1.0, 2.2)
	_floor = _ridge(236.0, 7.0, 5.0, 0.03, 2.6, false)
	# Lianas y raíces que cuelgan del techo (evitan la grieta central de luz).
	for i in 26:
		var x := _rng.randf_range(0, W)
		if absf(x - W / 2.0) < 50.0:
			continue
		_vines.append({"x": x, "len": _rng.randf_range(24, 110), "ph": _rng.randf() * TAU,
			"w": _rng.randf_range(0.8, 1.8), "leaves": _rng.randi_range(3, 7), "depth": _rng.randf_range(0.4, 1.0)})
	for i in 70:
		_spores.append({"p": Vector2(_rng.randf_range(0, W), _rng.randf_range(0, H)), "v": _rng.randf_range(4, 14),
			"f": _rng.randf_range(0.6, 1.6), "ph": _rng.randf() * TAU, "r": _rng.randf_range(0.5, 1.4),
			"gold": _rng.randf() < 0.55})
	for x in [36.0, 58.0, 84.0, 396.0, 420.0, 446.0, 118.0, 362.0]:
		_shrooms.append({"x": x + _rng.randf_range(-6, 6), "h": _rng.randf_range(6, 15), "r": _rng.randf_range(4, 8), "ph": _rng.randf() * TAU})
	var bx := -4.0
	while bx < W + 4.0:
		_blades.append({"x": bx, "h": _rng.randf_range(5, 16), "ph": _rng.randf() * TAU, "lean": _rng.randf_range(-0.3, 0.3)})
		bx += _rng.randf_range(2.0, 5.0)


# --- Dibujo ---------------------------------------------------------------------------------

func _shift(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = pts[i] + off
	return out


func _draw() -> void:
	# Fondo: verde profundo arriba, casi negro abajo.
	UiKit.vgrad(self, Rect2(0, 0, W, H * 0.55), Color("#123a24"), Color("#0a2216"))
	UiKit.vgrad(self, Rect2(0, H * 0.55, W, H * 0.45 + 1), Color("#0a2216"), Color("#030a06"))
	# Resplandor dorado de la grieta.
	var crack := Vector2(W / 2.0, 6.0) + _par * Vector2(-3, -1)
	UiKit.glow(self, crack + Vector2(0, 30), 190.0, Color(1.0, 0.82, 0.35, 0.22))
	UiKit.glow(self, crack + Vector2(0, 8), 80.0, Color(1.0, 0.9, 0.55, 0.35))
	# Rayos de luz (polígonos con degradado) que respiran despacio.
	for i in 7:
		var k := float(i) / 6.0
		var top_x := crack.x - 26.0 + k * 52.0
		var spread := lerpf(-150.0, 150.0, k) + sin(t * 0.3 + i) * 10.0
		var a := (0.07 + 0.05 * sin(t * 0.7 + i * 1.7)) * (1.0 - dim * 0.5)
		var wtop := 5.0 + (i % 3) * 3.0
		var wbot := 26.0 + (i % 2) * 20.0
		polygon_grad([Vector2(top_x - wtop, crack.y), Vector2(top_x + wtop, crack.y),
			Vector2(top_x + spread + wbot, H * 0.95), Vector2(top_x + spread - wbot, H * 0.95)],
			Color(1.0, 0.86, 0.42, a), Color(1.0, 0.86, 0.42, 0.0))
	# Capa lejana: bóveda con relieve.
	draw_colored_polygon(_shift(_far, _par * Vector2(-4, -2)), Color("#0f3020"))
	# Paredes laterales (capa media).
	draw_colored_polygon(_shift(_mid_l, _par * Vector2(-8, -3)), Color("#0a2518"))
	draw_colored_polygon(_shift(_mid_r, _par * Vector2(-8, -3)), Color("#0a2518"))
	_moss_edge(_shift(_mid_l, _par * Vector2(-8, -3)), true)
	_moss_edge(_shift(_mid_r, _par * Vector2(-8, -3)), false)
	# Techo cercano con la grieta de luz en el centro.
	var ceil := _shift(_ceil, _par * Vector2(-12, -4))
	draw_colored_polygon(ceil, Color("#06170e"))
	# Lianas.
	for v in _vines:
		_vine(v)
	# Esporas brillantes (detrás del suelo).
	for s in _spores:
		var p: Vector2 = s["p"] + _par * Vector2(-6, -2) * s["r"]
		var tw: float = 0.55 + 0.45 * sin(t * 2.2 + s["ph"])
		var col: Color = Color(1.0, 0.86, 0.38) if s["gold"] else Color(0.72, 0.95, 0.42)
		UiKit.glow(self, p, 3.5 + s["r"] * 3.0, Color(col, 0.28 * tw))
		draw_circle(p, s["r"] * 0.55, Color(col.lightened(0.4), 0.9 * tw), true, -1.0, true)
	# Suelo cercano con hierba y setas luminosas.
	var fl := _shift(_floor, _par * Vector2(-16, -5))
	for m in _shrooms:
		_shroom(m, _par * Vector2(-16, -5))
	draw_colored_polygon(fl, Color("#04110a"))
	for b in _blades:
		var bx: float = b["x"] + _par.x * -16.0
		var base := Vector2(bx, _floor_y(b["x"]) + _par.y * -5.0 + 1.0)
		var sway: float = sin(t * 1.4 + b["ph"] + b["x"] * 0.03) * 2.2 + b["lean"] * b["h"]
		draw_colored_polygon(PackedVector2Array([base + Vector2(-1.1, 0), base + Vector2(sway, -b["h"]), base + Vector2(1.1, 0)]),
			Color("#0b2a17").lerp(Color("#2c6b2e"), clampf(b["h"] / 16.0, 0.0, 1.0) * 0.6))
	# Viñeta.
	UiKit.vgrad(self, Rect2(0, 0, W, 60), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0))
	UiKit.vgrad(self, Rect2(0, H - 70, W, 70), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))
	if dim > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(0.01, 0.04, 0.02, 0.55 * dim))


func polygon_grad(pts: Array, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array(pts), PackedColorArray([top, top, bottom, bottom]))


func _floor_y(x: float) -> float:
	# Interpola la altura del suelo en x a partir de los puntos de la cresta.
	var i := clampi(int((x + 40.0) / 5.0), 0, _floor.size() - 4)
	var a := _floor[i]
	var b := _floor[i + 1]
	return lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))


func _moss_edge(pts: PackedVector2Array, left: bool) -> void:
	var edge := PackedVector2Array()
	for i in pts.size() - 2:
		edge.append(pts[i])
	draw_polyline(edge, Color("#2f7a34", 0.55), 1.4, true)
	for i in range(2, edge.size() - 2, 3):
		var p := edge[i]
		var d := 1.0 if left else -1.0
		draw_circle(p + Vector2(d * 1.2, 0), 1.6 + sin(i * 1.7) * 0.6, Color("#3f8f3c", 0.6), true, -1.0, true)


func _vine(v: Dictionary) -> void:
	var depth: float = v["depth"]
	var off := _par * Vector2(-12, -4) * depth
	var x: float = v["x"] + off.x
	var top := Vector2(x, _ceil_y(v["x"]) + off.y - 2.0)
	var pts := PackedVector2Array()
	var n := 10
	for i in n + 1:
		var k := float(i) / n
		var sway := sin(t * 0.9 + v["ph"] + k * 2.0) * 4.0 * k * k
		pts.append(top + Vector2(sway, k * v["len"]))
	var col := Color("#123f22").lerp(Color("#1f5a2c"), depth)
	draw_polyline(pts, col, v["w"] * depth + 0.4, true)
	for j in v["leaves"]:
		var k2: float = float(j + 1) / (v["leaves"] + 1)
		var idx := int(k2 * n)
		var p := pts[idx]
		var side := 1.0 if j % 2 == 0 else -1.0
		_leaf(p, side, 2.2 + depth * 1.6, col.lightened(0.15))
	# Gota de luz en la punta de algunas lianas.
	if int(v["x"]) % 3 == 0:
		var tip := pts[n]
		var a := 0.5 + 0.5 * sin(t * 1.8 + v["ph"])
		UiKit.glow(self, tip, 7.0, Color(0.95, 0.85, 0.4, 0.35 * a))
		draw_circle(tip, 1.1, Color(1.0, 0.92, 0.55, 0.9), true, -1.0, true)


func _ceil_y(x: float) -> float:
	var i := clampi(int((x + 40.0) / 5.0), 0, _ceil.size() - 4)
	var a := _ceil[i]
	var b := _ceil[i + 1]
	return lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))


func _leaf(p: Vector2, side: float, size: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 9:
		var a := float(i) / 8.0 * TAU
		pts.append(p + Vector2(side * (size * 0.9 + cos(a) * size), sin(a) * size * 0.45).rotated(side * 0.5))
	draw_colored_polygon(pts, col)


func _shroom(m: Dictionary, off: Vector2) -> void:
	var base := Vector2(m["x"] + off.x, _floor_y(m["x"]) + off.y + 2.0)
	var h: float = m["h"]
	var r: float = m["r"]
	var pulse := 0.7 + 0.3 * sin(t * 1.5 + m["ph"])
	var cap := base + Vector2(0, -h)
	UiKit.glow(self, cap, r * 4.5, Color(1.0, 0.85, 0.3, 0.22 * pulse))
	draw_line(base, cap + Vector2(0, 1), Color("#d9d0a8"), 1.6, true)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + float(i) / 12.0 * PI
		pts.append(cap + Vector2(cos(a) * r, sin(a) * r * 0.75))
	draw_colored_polygon(pts, Color("#f2c94a").lerp(Color("#fff0a0"), 0.3 * pulse))
	draw_circle(cap + Vector2(-r * 0.35, -r * 0.35), r * 0.16, Color(1, 1, 0.9, 0.8), true, -1.0, true)
	draw_circle(cap + Vector2(r * 0.3, -r * 0.2), r * 0.11, Color(1, 1, 0.9, 0.7), true, -1.0, true)
