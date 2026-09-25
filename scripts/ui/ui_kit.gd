class_name UiKit
extends RefCounted
## Kit de la interfaz en alta resolución (portada, menús, HUD y rótulos del mundo).
##
## - Paleta principal verde y amarilla.
## - Fuente pixelada gruesa propia (assets/fonts, generada por tools/make_font.py) con sombra
##   dura de un píxel.
## - Texto que nunca se pisa: todo se mide antes de dibujarse y se reduce, se parte en
##   líneas o se recorta con "…" para caber en su caja.
## - Auditoría: con `audit = true` se guarda la caja de cada texto dibujado y
##   `audit_issues()` avisa de textos que se solapan o quedan a menos de MIN_GAP.
##
## Las coordenadas son las lógicas de la pantalla (480x270); el motor las escala.

# --- Paleta ---------------------------------------------------------------------------------
const BG_DEEP := Color("#040b07")
const BG := Color("#0a1a11")
const PANEL := Color("#0d2216")
const PANEL_HI := Color("#153522")
const PANEL_SEL := Color("#1d4a2c")
const LINE := Color("#285a37")
const LINE_HI := Color("#4c9a57")
const GREEN := Color("#5fbf48")
const GREEN_DEEP := Color("#2f7a34")
const LIME := Color("#b6e35c")
const YELLOW := Color("#f7d552")
const GOLD := Color("#e6ac2c")
const GOLD_DEEP := Color("#9a6814")
const TEXT := Color("#eef5e2")
const TEXT_DIM := Color("#a6bfa0")
const TEXT_MUTE := Color("#6f8a6b")
const INK := Color("#020604")
const RED := Color("#e7574d")
const BLUE := Color("#4fa9ec")
const ORANGE := Color("#e8903a")
const QUALITY := [Color("#eef5e2"), Color("#62a8f5"), Color("#f7d552"), Color("#c77af5")]

# --- Tamaños de letra (px lógicos) ----------------------------------------------------------
const XS := 6
const S := 7
const M := 8
const L := 10
const XL := 13
const H := 18

const MIN_GAP := 1.5          # separación mínima entre dos textos (px lógicos)
const SCREEN := Rect2(0, 0, 480, 270)

static var audit := false
static var _rects: Array = []
static var _layer := 0
static var _fonts := {}
static var _boxes := {}
static var _soft: GradientTexture2D


# --- Tipografías -------------------------------------------------------------------------------

## Todas las tipografías son la fuente pixelada gruesa del juego (tools/make_font.py). Se
## mantiene `kind` ("ui", "bold", "display") por compatibilidad: solo cambia el tamaño que
## se le pide.
const FONT_PATH := "res://assets/fonts/subterra_pixel.ttf"


static func font(_kind: String = "ui") -> Font:
	if _fonts.has("px"):
		return _fonts["px"]
	var f: FontFile = load(FONT_PATH).duplicate()
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	f.allow_system_fallback = true
	_fonts["px"] = f
	return f


## Tamaño real con el que se dibuja: la fuente mide 8 px de em, así que solo se usan
## múltiplos de 4 (cada píxel de la fuente ocupa 1, 1,5, 2… píxeles lógicos y queda nítido
## en la pantalla x2). El mínimo es 8 (un píxel de fuente por píxel lógico).
static func px(size: int) -> int:
	return maxi(8, int(round(size / 4.0)) * 4)


static func line_h(size: int, kind: String = "ui") -> float:
	return font(kind).get_height(px(size))


static func text_w(s: String, size: int, kind: String = "ui") -> float:
	return font(kind).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px(size)).x


## Recorta con "…" hasta que el texto quepa en max_w.
static func ellipsize(s: String, size: int, max_w: float, kind: String = "ui") -> String:
	if max_w <= 0.0 or text_w(s, size, kind) <= max_w:
		return s
	var lo := 0
	var hi := s.length()
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if text_w(s.substr(0, mid).strip_edges() + "…", size, kind) <= max_w:
			lo = mid
		else:
			hi = mid - 1
	return s.substr(0, lo).strip_edges() + "…"


## Parte el texto en líneas que caben en max_w (respeta los saltos de línea explícitos).
static func wrap_lines(s: String, size: int, max_w: float, kind: String = "ui") -> PackedStringArray:
	var out := PackedStringArray()
	for para in s.split("\n"):
		var cur := ""
		for w in para.split(" ", false):
			var cand := w if cur == "" else cur + " " + w
			if cur != "" and text_w(cand, size, kind) > max_w:
				out.append(cur)
				cur = w
			else:
				cur = cand
			# Palabra suelta más ancha que la caja: se recorta.
			if text_w(cur, size, kind) > max_w:
				cur = ellipsize(cur, size, max_w, kind)
		out.append(cur)
	return out


## Mayor tamaño (entre size y min_size) con el que s cabe en max_w.
static func fit_size(s: String, size: int, max_w: float, min_size: int, kind: String = "ui") -> int:
	var sz := size
	while sz > min_size and text_w(s, sz, kind) > max_w:
		sz -= 1
		while sz > min_size and px(sz) == px(sz + 1):
			sz -= 1
	return sz


# --- Dibujo de texto -----------------------------------------------------------------------------

## Dibuja una línea de texto. `pos` es la esquina superior del renglón; `align` indica si
## pos.x es el borde izquierdo (0), el centro (1) o el borde derecho (2).
## Opciones: kind, max_w (reduce hasta min_size y luego recorta), min_size, outline
## (grosor del contorno), outline_col, shadow (sombra suave) y spacing (espaciado extra
## entre letras, solo sin max_w). Devuelve la caja ocupada.
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align: int = 0, opts: Dictionary = {}) -> Rect2:
	if s == "":
		return Rect2(pos, Vector2.ZERO)
	var kind: String = opts.get("kind", "ui")
	var max_w: float = opts.get("max_w", 0.0)
	var sz := size
	if max_w > 0.0:
		sz = fit_size(s, size, max_w, opts.get("min_size", maxi(size - 2, XS)), kind)
		s = ellipsize(s, sz, max_w, kind)
	var f := font(kind)
	var spacing: float = opts.get("spacing", 0.0)
	var w := text_w(s, sz, kind) + spacing * maxf(0.0, s.length() - 1)
	var h := f.get_height(px(sz))
	var x := pos.x - (w / 2.0 if align == 1 else (w if align == 2 else 0.0))
	# Centra verticalmente la caja de un tamaño menor dentro del renglón original.
	var y := pos.y + (f.get_height(px(size)) - h) / 2.0
	# Posiciones enteras: la fuente es de píxeles y no debe caer entre dos.
	x = roundf(x)
	y = roundf(y)
	var base := Vector2(x, y + f.get_ascent(px(sz)))
	var outline: int = opts.get("outline", 0)
	var oc: Color = opts.get("outline_col", Color(INK, 0.85))
	oc.a *= col.a
	var fs := px(sz)
	# Sombra dura de un píxel (la de siempre en los juegos de pixel art); "flat" la quita.
	if not opts.get("flat", false) or opts.get("shadow", false):
		_glyphs(ci, f, base + Vector2(1, 1), s, fs, Color(INK, 0.8 * col.a), spacing)
	if outline > 0:
		var r := maxi(1, int(round(outline / 2.0)))
		for oy in range(-r, r + 1):
			for ox in range(-r, r + 1):
				if (ox != 0 or oy != 0) and absi(ox) + absi(oy) <= r + 1:
					_glyphs(ci, f, base + Vector2(ox, oy), s, fs, oc, spacing)
	_glyphs(ci, f, base, s, fs, col, spacing)
	var rect := Rect2(x, y, w, h)
	if not opts.get("no_audit", false):
		_record(rect, s)
	return rect


static func _glyphs(ci: CanvasItem, f: Font, base: Vector2, s: String, sz: int, col: Color, spacing: float) -> void:
	if spacing == 0.0:
		ci.draw_string(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
		return
	var x := base.x
	for ch in s:
		ci.draw_string(f, Vector2(roundf(x), base.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
		x += f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + spacing


## Párrafo dentro de una caja: parte en líneas y, si no cabe en alto, recorta la última
## línea con "…". Devuelve la altura usada.
static func paragraph(ci: CanvasItem, box: Rect2, s: String, size: int, col: Color, align: int = 0, opts: Dictionary = {}) -> float:
	var kind: String = opts.get("kind", "ui")
	var lh := line_h(size, kind) + float(opts.get("leading", 1.5))
	var lines := wrap_lines(s, size, box.size.x, kind)
	var max_lines := maxi(1, int(floor((box.size.y + 0.01 + opts.get("leading", 1.5)) / lh)))
	if lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
		lines[max_lines - 1] = ellipsize(lines[max_lines - 1] + "…", size, box.size.x, kind)
	var o := opts.duplicate()
	o.erase("max_w")
	for i in lines.size():
		var x := box.position.x + (box.size.x / 2.0 if align == 1 else (box.size.x if align == 2 else 0.0))
		text(ci, Vector2(x, box.position.y + i * lh), lines[i], size, col, align, o)
	return lines.size() * lh - float(opts.get("leading", 1.5))


static func paragraph_h(s: String, size: int, w: float, kind: String = "ui", leading: float = 1.5) -> float:
	var n := wrap_lines(s, size, w, kind).size()
	return n * (line_h(size, kind) + leading) - leading


# --- Auditoría de solapes -----------------------------------------------------------------------

## Empieza a contar desde cero (llamar al principio de cada frame auditado).
static func audit_begin() -> void:
	_rects.clear()
	_layer = 0


## Lo que se dibuja a partir de aquí queda encima de lo anterior (panel opaco, tooltip…) y
## no se compara con ello.
static func new_layer() -> void:
	_layer += 1


static func _record(r: Rect2, s: String) -> void:
	if audit:
		_rects.append({"r": r, "s": s, "layer": _layer})


## Lista de problemas: textos que se solapan o casi, y textos fuera de la pantalla.
static func audit_issues() -> Array:
	var out := []
	for i in _rects.size():
		var a: Dictionary = _rects[i]
		var ra: Rect2 = a["r"]
		if not SCREEN.grow(0.5).encloses(ra):
			out.append("fuera de pantalla: '%s' %s" % [a["s"], ra])
		for j in range(i + 1, _rects.size()):
			var b: Dictionary = _rects[j]
			if a["layer"] != b["layer"]:
				continue
			# Se descuenta el hueco interno de la fuente (la caja es algo más alta que las letras).
			var ga := _ink(ra)
			var gb := _ink(b["r"])
			if ga.grow(MIN_GAP / 2.0).intersects(gb.grow(MIN_GAP / 2.0)):
				out.append("solape: '%s' %s  <->  '%s' %s" % [a["s"], ra, b["s"], b["r"]])
	return out


## Caja de "tinta": la caja del renglón sin el aire de arriba y abajo que añade la fuente.
static func _ink(r: Rect2) -> Rect2:
	var pad := r.size.y * 0.12
	return Rect2(r.position.x, r.position.y + pad, r.size.x, r.size.y - pad * 2.0)


# --- Piezas ---------------------------------------------------------------------------------------

static func _box(key: String, bg: Color, border: Color, radius: int, bw: int = 1, shadow: int = 0) -> StyleBoxFlat:
	var k := "%s|%s|%s|%d|%d|%d" % [key, bg.to_html(), border.to_html(), radius, bw, shadow]
	if _boxes.has(k):
		return _boxes[k]
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = false
	sb.anti_aliasing_size = 0.4
	sb.corner_detail = maxi(1, radius)
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 1)
	_boxes[k] = sb
	return sb


## Caja redondeada con borde.
static func box(ci: CanvasItem, r: Rect2, bg: Color, border: Color = Color(0, 0, 0, 0), radius: int = 3, bw: int = 1, shadow: int = 0) -> void:
	ci.draw_style_box(_box("b", bg, border, radius, bw if border.a > 0.0 else 0, shadow), r)


## Panel de ventana: fondo verde muy oscuro, borde, sombra y filo dorado arriba.
static func panel(ci: CanvasItem, r: Rect2, title: String = "", alpha: float = 0.96) -> void:
	box(ci, r, Color(PANEL, alpha), LINE, 5, 1, 6)
	ci.draw_rect(Rect2(r.position.x + 6, r.position.y + 0.5, r.size.x - 12, 0.6), Color(GOLD, 0.55))
	if title != "":
		text(ci, Vector2(r.position.x + 10, r.position.y + 6), title, L, YELLOW, 0, {"kind": "bold", "max_w": r.size.x - 20})


## Botón. primary: dorado. sel: marcado (pestaña activa, campo en edición).
static func button(ci: CanvasItem, r: Rect2, label: String, hover: bool, opts: Dictionary = {}) -> void:
	var primary: bool = opts.get("primary", false)
	var sel: bool = opts.get("sel", false)
	var disabled: bool = opts.get("disabled", false)
	var bg := PANEL_HI
	var border := LINE
	var col: Color = opts.get("col", TEXT)
	if primary:
		bg = GOLD_DEEP.lerp(GOLD, 0.35 if hover else 0.15)
		border = YELLOW if hover else GOLD
		col = Color("#fff8dc")
	elif sel:
		bg = PANEL_SEL
		border = LIME
	elif hover:
		bg = PANEL_SEL
		border = LINE_HI
	if disabled:
		bg = Color(PANEL, 0.8)
		border = Color(LINE, 0.5)
		col = TEXT_MUTE
	box(ci, r, bg, border, int(opts.get("radius", 3)), 1, 2 if primary else 0)
	if hover and not disabled:
		ci.draw_rect(Rect2(r.position.x + 3, r.end.y - 1.6, r.size.x - 6, 0.7), Color(YELLOW, 0.8))
	var size: int = opts.get("size", M)
	var kind: String = opts.get("kind", "bold")
	var y := r.position.y + (r.size.y - line_h(size, kind)) / 2.0
	var align: int = opts.get("align", 1)
	var x := r.get_center().x if align == 1 else (r.position.x + 6.0 if align == 0 else r.end.x - 6.0)
	text(ci, Vector2(x, y), label, size, col, align, {"kind": kind, "max_w": r.size.x - 10})


## Barra de progreso redondeada.
## `ghost` (0-1, opcional): estela clara de lo que se acaba de perder (la vida al recibir daño).
static func bar(ci: CanvasItem, r: Rect2, k: float, col: Color, back: Color = Color(INK, 0.75), ghost: float = -1.0) -> void:
	var rad := int(minf(r.size.y / 2.0, 3.0))
	box(ci, r.grow(0.6), back, Color(0, 0, 0, 0), rad + 1)
	k = clampf(k, 0.0, 1.0)
	if ghost > k:
		box(ci, Rect2(r.position, Vector2(maxf(r.size.x * minf(ghost, 1.0), r.size.y), r.size.y)), Color(1.0, 0.93, 0.8, 0.85), Color(0, 0, 0, 0), rad)
	if k > 0.0:
		var fr := Rect2(r.position, Vector2(maxf(r.size.x * k, r.size.y), r.size.y))
		box(ci, fr, col, Color(0, 0, 0, 0), rad)
		ci.draw_rect(Rect2(fr.position + Vector2(rad * 0.5, 0.4), Vector2(fr.size.x - rad, minf(0.9, r.size.y * 0.3))), Color(1, 1, 1, 0.28))


## Tecla dibujada como una tecla física pequeña ("F", "Espacio"…). Devuelve su caja.
static func keycap(ci: CanvasItem, pos: Vector2, key: String, size: int = S, align: int = 0) -> Rect2:
	var w := maxf(text_w(key, size, "bold") + 5.0, line_h(size, "bold"))
	var h := line_h(size, "bold") + 1.0
	var x := pos.x - (w / 2.0 if align == 1 else (w if align == 2 else 0.0))
	var r := Rect2(x, pos.y, w, h)
	box(ci, r, Color("#e9e2c4"), Color("#8a7a44"), 2)
	ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 1.2, r.size.x - 2, 0.8), Color(0, 0, 0, 0.25))
	text(ci, Vector2(r.get_center().x, r.position.y + 0.3), key, size, Color("#2a2410"), 1, {"kind": "bold"})
	return r


## Textura de luz suave (degradado radial blanco -> transparente) para halos y brillos.
static func soft() -> GradientTexture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.45))
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 128
		_soft.height = 128
	return _soft


## Halo de luz centrado en p (el CanvasItem debe usar filtro lineal).
static func glow(ci: CanvasItem, p: Vector2, radius: float, col: Color) -> void:
	ci.draw_texture_rect(soft(), Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, col)


## Rectángulo con degradado vertical.
static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## Rombo pequeño (adorno y marcador de selección).
static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


## Separador con rombo central, estilo ornamento.
static func ornament(ci: CanvasItem, c: Vector2, half_w: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(-half_w, 0), c + Vector2(-4, 0)])
	ci.draw_polyline_colors(pts, PackedColorArray([Color(col, 0.0), col]), 0.7, true)
	pts = PackedVector2Array([c + Vector2(4, 0), c + Vector2(half_w, 0)])
	ci.draw_polyline_colors(pts, PackedColorArray([col, Color(col, 0.0)]), 0.7, true)
	diamond(ci, c, 2.4, col)
	diamond(ci, c + Vector2(-7, 0), 1.1, col)
	diamond(ci, c + Vector2(7, 0), 1.1, col)
