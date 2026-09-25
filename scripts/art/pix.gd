class_name Pix
extends RefCounted
## Lienzo de pixel art: primitivas de dibujo sobre una Image y pase de contorno automático.
## Todo el arte del juego se genera con esto (original, sin assets externos).

const OUTLINE := Color("#1a1320")

## Paleta base (48 colores). Las rampas de material van de oscuro a claro.
const RAMPS := {
	"madera": ["#3b2417", "#6b4226", "#9c6a3c", "#c9975e"],
	"piedra": ["#3a3a46", "#5d5d6e", "#8b8b9c", "#bdbdc9"],
	"hueso": ["#6e6450", "#a89a78", "#d6ccae", "#f4efdc"],
	"hierro": ["#3c4652", "#667685", "#9aaab8", "#d5e0e8"],
	"oro": ["#7a4a12", "#c0801e", "#f0b93a", "#fff08a"],
	"diamante": ["#1f5c78", "#3aa3c4", "#7fe0f0", "#e8ffff"],
	"ceniza": ["#1e1422", "#4a2a4e", "#8a3a6e", "#e05a9a"],
	"fuego": ["#7a1c14", "#d0461e", "#f58a2a", "#ffd24a"],
	"hielo": ["#2a4e8a", "#4a8ad0", "#8ac4f0", "#e0f4ff"],
	"rayo": ["#6a5a10", "#c0a01e", "#f0e03a", "#fffcc0"],
	"carbon": ["#141418", "#26262e", "#3c3c48", "#5a5a68"],
	"tela": ["#6a6a72", "#9a9aa4", "#cacad2", "#f4f4f8"],
	"piel": ["#4a2a5a", "#7a4a8a", "#aa7aba", "#d8b0e0"],
	"cuero": ["#4a2e1a", "#7a4e2a", "#a8744a", "#d4a47a"],
	"hierba": ["#1e4a1e", "#2e7a2e", "#5ab04a", "#a0e07a"],
	"seta": ["#6a1e1e", "#b83a32", "#e8605a", "#ffd0c8"],
	"carne_cruda": ["#6a1e28", "#b04050", "#e07a88", "#ffd0d8"],
	"carne_asada": ["#4a2410", "#8a4a20", "#c07a3a", "#f0b870"],
	"vida": ["#6a0e1e", "#c0203a", "#f05a6a", "#ffc0c8"],
	"mana": ["#101e6a", "#2040c0", "#4a8af0", "#b0d8ff"],
	"misterio": ["#3a1a5a", "#6a2aa0", "#a05ad8", "#e0b8ff"],
	"veneno": ["#1a3a10", "#3a7a1a", "#7ac02a", "#d0ff8a"],
	"esmeralda": ["#0e4a2a", "#1a8a4a", "#3ad07a", "#b0ffd0"],
	"gelatina": ["#6a2a6a", "#c05ac0", "#f09af0", "#ffe0ff"],
	"laser": ["#6a0e3a", "#e01e6a", "#ff6aa0", "#ffffff"],
	"obsidiana": ["#0e0a14", "#221a30", "#3a2e52", "#6a5a8a"],
	"espiritu": ["#1a3a5a", "#3a7ab0", "#8ad0f0", "#ffffff"],
	"neutro": ["#3a3a3a", "#6a6a6a", "#9a9a9a", "#dadada"],
	"cuero_piedra": ["#3a3226", "#6a5a44", "#9a8468", "#c8b294"],
	"cuero_hueso": ["#5a4a2a", "#8a7244", "#b89c66", "#e2cc98"],
	"cuero_hierro": ["#2a3a3a", "#4a6a6a", "#7a9a9a", "#b4d0d0"],
	"cuero_oro": ["#6a3a0a", "#a86a1a", "#e0a03a", "#ffe08a"],
	"cuero_diamante": ["#1a4a6a", "#2a8ab0", "#6ad0e8", "#dcffff"],
	"cristal": ["#1a5a5a", "#2aa8a0", "#6ae8d8", "#e0fffa"],
	"verde": ["#1a4a1a", "#3a8a2a", "#6ac04a", "#b8f08a"],
	"azul": ["#1a2a6a", "#2a5ab0", "#5a9ae8", "#c0e0ff"],
	"morada": ["#2e1a4a", "#5a2a8a", "#8a4ac0", "#d0a0f0"],
	"gris": ["#26222e", "#46404e", "#6e6878", "#a8a2b0"],
	"negro": ["#0e0a10", "#1e1a24", "#3a2e44", "#6a4a7a"],
	"madre": ["#2a0e2a", "#5a1a4a", "#9a2a6a", "#e05aa0"],
	"rey": ["#6a1e10", "#c04a1a", "#f0a02a", "#fff0a0"],
	"guardian": ["#0a0608", "#2a0a14", "#6a0a24", "#ff2a4a"],
}

var img: Image
var w: int
var h: int


func _init(width: int, height: int) -> void:
	w = width
	h = height
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))


static func c(hex: String) -> Color:
	return Color(hex)


static func ramp(name: String, i: int) -> Color:
	var r: Array = RAMPS.get(name, RAMPS["neutro"])
	return Color(r[clampi(i, 0, 3)])


func px(x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < w and y < h:
		img.set_pixel(x, y, col)


func get_px(x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < w and y < h:
		return img.get_pixel(x, y)
	return Color(0, 0, 0, 0)


func rect(x: int, y: int, rw: int, rh: int, col: Color) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, col)


func ellipse(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for yy in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for xx in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx := (xx + 0.5 - cx) / maxf(rx, 0.01)
			var dy := (yy + 0.5 - cy) / maxf(ry, 0.01)
			if dx * dx + dy * dy <= 1.0:
				px(xx, yy, col)


func line(x0: int, y0: int, x1: int, y1: int, col: Color, thick: int = 1) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	while true:
		if thick <= 1:
			px(x, y, col)
		else:
			rect(x - thick / 2, y - thick / 2, thick, thick, col)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


## Sombreado: oscurece los píxeles opacos de la mitad inferior-derecha de una región.
func shade_region(x: int, y: int, rw: int, rh: int, amount: float = 0.2) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			var p := get_px(xx, yy)
			if p.a > 0.0 and (yy - y) > rh * 0.55:
				px(xx, yy, p.darkened(amount))


## Contorno de 1 px alrededor de todo lo opaco.
func outline(col: Color = OUTLINE) -> void:
	var src := img.duplicate()
	for yy in h:
		for xx in w:
			if src.get_pixel(xx, yy).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = xx + d.x
				var ny: int = yy + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.0 \
						and src.get_pixel(nx, ny) != col:
					img.set_pixel(xx, yy, col)
					break


## Dibuja texto en forma de filas con una leyenda de colores.
func stamp(rows: Array, ox: int, oy: int, legend: Dictionary) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if legend.has(ch):
				px(ox + x, oy + y, legend[ch])


func flip_h() -> void:
	img.flip_x()


func tex() -> ImageTexture:
	return ImageTexture.create_from_image(img)
