class_name PixelFont
extends RefCounted
## Fuente pixelada de 3x5 (nítida a 320x180). Solo mayúsculas; los acentos se simplifican.

const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"], "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"Ñ": ["###", "...", "##.", "#.#", "#.#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."], "Q": [".#.", "#.#", "#.#", "##.", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"], "S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	".": ["...", "...", "...", "...", ".#."], ",": ["...", "...", "...", ".#.", "#.."],
	"!": [".#.", ".#.", ".#.", "...", ".#."], "¡": [".#.", "...", ".#.", ".#.", ".#."],
	"?": ["##.", "..#", ".#.", "...", ".#."], "¿": [".#.", "...", ".#.", "#..", ".##"],
	":": ["...", ".#.", "...", ".#.", "..."], "-": ["...", "...", "###", "...", "..."],
	"+": ["...", ".#.", "###", ".#.", "..."], "'": [".#.", ".#.", "...", "...", "..."],
	"\"": ["#.#", "#.#", "...", "...", "..."], "/": ["..#", "..#", ".#.", "#..", "#.."],
	"(": [".#.", "#..", "#..", "#..", ".#."], ")": [".#.", "..#", "..#", "..#", ".#."],
	"%": ["#.#", "..#", ".#.", "#..", "#.#"], "#": ["#.#", "###", "#.#", "###", "#.#"],
	"<": ["..#", ".#.", "#..", ".#.", "..#"], ">": ["#..", ".#.", "..#", ".#.", "#.."],
	"=": ["...", "###", "...", "###", "..."], "_": ["...", "...", "...", "...", "###"],
	"[": ["##.", "#..", "#..", "#..", "##."], "]": [".##", "..#", "..#", "..#", ".##"],
	" ": ["...", "...", "...", "...", "..."],
}
const ACCENTS := {"Á": "A", "À": "A", "É": "E", "È": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "×": "X"}
const ADV := 4
const LINE := 7

static var _tex: ImageTexture
static var _index := {}


static func _ensure() -> void:
	if _tex != null:
		return
	var keys := GLYPHS.keys()
	var img := Image.create(keys.size() * ADV, 5, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in keys.size():
		var rows: Array = GLYPHS[keys[i]]
		_index[keys[i]] = i
		for y in 5:
			for x in 3:
				if rows[y][x] == "#":
					img.set_pixel(i * ADV + x, y, Color.WHITE)
	_tex = ImageTexture.create_from_image(img)


static func normalize(text: String) -> String:
	var t := text.to_upper()
	var out := ""
	for ch in t:
		out += ACCENTS.get(ch, ch)
	return out


static func width(text: String, scale: int = 1) -> int:
	var longest := 0
	for line in normalize(text).split("\n"):
		longest = max(longest, line.length())
	return max(0, longest * ADV - 1) * scale


static func draw(ci: CanvasItem, pos: Vector2, text: String, color: Color = Color.WHITE,
		scale: int = 1, shadow: bool = true) -> void:
	_ensure()
	var t := normalize(text)
	var lines := t.split("\n")
	for li in lines.size():
		var line: String = lines[li]
		for i in line.length():
			var ch := line[i]
			if ch == " " or not _index.has(ch):
				continue
			var src := Rect2(_index[ch] * ADV, 0, 3, 5)
			var dst := Rect2(pos + Vector2(i * ADV * scale, li * LINE * scale), Vector2(3, 5) * scale)
			if shadow:
				ci.draw_texture_rect_region(_tex, Rect2(dst.position + Vector2(scale, scale), dst.size), src, Color(0.06, 0.04, 0.09, color.a))
			ci.draw_texture_rect_region(_tex, dst, src, color)


static func draw_centered(ci: CanvasItem, center_x: float, y: float, text: String,
		color: Color = Color.WHITE, scale: int = 1, shadow: bool = true) -> void:
	for li in normalize(text).split("\n").size():
		var line: String = text.split("\n")[li]
		draw(ci, Vector2(round(center_x - width(line, scale) / 2.0), y + li * LINE * scale), line, color, scale, shadow)


## Parte un texto en líneas de como mucho `max_chars` caracteres.
static func wrap(text: String, max_chars: int) -> String:
	var words := text.split(" ")
	var lines := []
	var cur := ""
	for w in words:
		if cur == "":
			cur = w
		elif (cur + " " + w).length() <= max_chars:
			cur += " " + w
		else:
			lines.append(cur)
			cur = w
	if cur != "":
		lines.append(cur)
	return "\n".join(lines)
