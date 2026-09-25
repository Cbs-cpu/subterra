class_name DistrictGen
extends RefCounted
## Genera distritos (mapas de plataformas hechos de salas de 32x18 tiles) y pueblos.
## Determinista por semilla. Tiles: 0 aire, 1 sólido, 2 plataforma de un sentido.

const TILE := 16
const RW := 32
const RH := 18
const AIR := 0
const SOLID := 1
const ONEWAY := 2
const JUMP_TILES := 4
const DIRS := {"L": Vector2i(-1, 0), "R": Vector2i(1, 0), "U": Vector2i(0, -1), "D": Vector2i(0, 1)}
const OPP := {"L": "R", "R": "L", "U": "D", "D": "U"}


static func size_for(district: int) -> Vector2i:
	var w := 5 + mini(4, district / 4)
	var h := 2 + (1 if district > 6 else 0) + (1 if district > 13 else 0)
	return Vector2i(w, h)


## door_biomes: biomas de las puertas de salida (1 en el penúltimo, [] en el Nido).
static func generate(seed_value: int, biome_id: String, district: int, door_biomes: Array, madman := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var biome := Content.biome(biome_id)
	var final := biome_id == "nido"
	var gs := Vector2i(6, 1) if final else size_for(district)
	# --- Grafo de salas -------------------------------------------------------
	var start := Vector2i(0, 0 if final else rng.randi() % gs.y)
	var rooms := {start: {"open": {}}}
	var path := [start]
	var cur := start
	var vert_run := 0
	while cur.x < gs.x - 1:
		var moves := ["R", "R", "R"]
		if vert_run < 2:
			if cur.y > 0:
				moves.append("U")
			if cur.y < gs.y - 1:
				moves.append("D")
		var m: String = moves[rng.randi() % moves.size()]
		var nxt: Vector2i = cur + DIRS[m]
		if rooms.has(nxt):
			m = "R"
			nxt = cur + DIRS["R"]
		vert_run = vert_run + 1 if m != "R" else 0
		_link(rooms, cur, nxt, m)
		path.append(nxt)
		cur = nxt
	var exit_room: Vector2i = cur
	# Salas extra conectadas a las existentes.
	var fill := 0.75 if not final else 0.0
	var added := true
	while added:
		added = false
		for y in gs.y:
			for x in gs.x:
				var c := Vector2i(x, y)
				if rooms.has(c) or rng.randf() > fill:
					continue
				var opts := []
				for d in DIRS:
					if rooms.has(c + DIRS[d]):
						opts.append(d)
				if opts.is_empty():
					continue
				var d: String = opts[rng.randi() % opts.size()]
				rooms[c] = {"open": {}}
				_link(rooms, c + DIRS[d], c, OPP[d])
				# A veces, un segundo enlace para crear bucles.
				if opts.size() > 1 and rng.randf() < 0.3:
					var d2: String = opts[(opts.find(d) + 1) % opts.size()]
					_link(rooms, c + DIRS[d2], c, OPP[d2])
				added = true
	# --- Tiles ----------------------------------------------------------------
	var w := gs.x * RW
	var h := gs.y * RH
	var tiles := PackedByteArray()
	tiles.resize(w * h)
	tiles.fill(SOLID)
	var grounds := {}
	for c in rooms:
		grounds[c] = _carve_room(tiles, w, c, rooms[c]["open"], rng, c == exit_room or c == start or final)
	var out := {"w": w, "h": h, "tiles": tiles, "rooms": rooms, "grid": gs, "biome": biome_id,
		"district": district, "start_room": start, "exit_room": exit_room, "path": path, "entities": [], "doors": [], "boss": {}}
	out["spawn"] = Vector2((start.x * RW + (3 if not final else 40)) * TILE + 8, (start.y * RH + 15) * TILE)
	# --- Puertas de salida ----------------------------------------------------
	var doors_x := [8, 16, 24] if door_biomes.size() == 3 else [16]
	for i in door_biomes.size():
		var tx: int = exit_room.x * RW + doors_x[i]
		out["doors"].append({"pos": Vector2(tx * TILE + 8, (exit_room.y * RH + 15) * TILE), "biome": door_biomes[i]})
	# --- Entidades --------------------------------------------------------------
	_place_entities(out, grounds, biome, district, rng, madman)
	return out


static func _link(rooms: Dictionary, a: Vector2i, b: Vector2i, dir: String) -> void:
	if not rooms.has(b):
		rooms[b] = {"open": {}}
	rooms[a]["open"][dir] = true
	rooms[b]["open"][OPP[dir]] = true


static func _st(tiles: PackedByteArray, w: int, x: int, y: int, v: int) -> void:
	tiles[y * w + x] = v


static func _carve_room(tiles: PackedByteArray, w: int, c: Vector2i, open: Dictionary, rng: RandomNumberGenerator, flat: bool) -> Array:
	var ox := c.x * RW
	var oy := c.y * RH
	var ground := []
	ground.resize(RW)
	ground.fill(15)
	if not flat:
		var hgt := 15
		for x in range(4, RW - 4):
			if rng.randf() < 0.18:
				hgt = clampi(hgt + (1 if rng.randf() < 0.5 else -1), 13, 15)
			ground[x] = hgt
	var shaft_down: bool = open.has("D")
	var shaft_up: bool = open.has("U")
	if shaft_down or shaft_up:
		for x in range(10, 22):
			ground[x] = 15
	for x in range(1, RW - 1):
		for y in range(1, ground[x]):
			_st(tiles, w, ox + x, oy + y, AIR)
	if open.has("L"):
		for y in range(11, 15):
			_st(tiles, w, ox, oy + y, AIR)
	if open.has("R"):
		for y in range(11, 15):
			_st(tiles, w, ox + RW - 1, oy + y, AIR)
	if shaft_up:
		for x in range(14, 18):
			_st(tiles, w, ox + x, oy, AIR)
		var steps := [[13, 10, 14], [10, 17, 21], [7, 10, 14], [4, 17, 21], [1, 14, 17]]
		for s in steps:
			for x in range(s[1], s[2] + 1):
				_st(tiles, w, ox + x, oy + s[0], ONEWAY)
	if shaft_down:
		for x in range(14, 18):
			for y in range(15, RH):
				_st(tiles, w, ox + x, oy + y, AIR)
			_st(tiles, w, ox + x, oy + 15, ONEWAY)
	if not flat:
		# Plataformas flotantes.
		for i in rng.randi_range(2, 4):
			var y := rng.randi_range(6, 11)
			var len := rng.randi_range(3, 6)
			var x0 := rng.randi_range(2, RW - 3 - len)
			if shaft_up and x0 + len >= 9 and x0 <= 22:
				continue
			var ok := true
			for x in range(x0, x0 + len):
				if tiles[(oy + y) * w + ox + x] != AIR or tiles[(oy + y - 1) * w + ox + x] != AIR:
					ok = false
			if ok:
				for x in range(x0, x0 + len):
					_st(tiles, w, ox + x, oy + y, ONEWAY)
		# Bloques (pilares bajos).
		if rng.randf() < 0.45:
			var x := rng.randi_range(5, 24)
			if not (x >= 9 and x <= 22 and (shaft_up or shaft_down)):
				var g: int = min(ground[x], ground[x + 1])
				for yy in range(g - 2, g):
					_st(tiles, w, ox + x, oy + yy, SOLID)
					_st(tiles, w, ox + x + 1, oy + yy, SOLID)
				ground[x] = g - 2
				ground[x + 1] = g - 2
	return ground


static func tile_at(d: Dictionary, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= d["w"] or y >= d["h"]:
		return SOLID
	return d["tiles"][y * d["w"] + x]


static func standable(d: Dictionary, x: int, y: int) -> bool:
	return tile_at(d, x, y) == AIR and tile_at(d, x, y - 1) != SOLID and tile_at(d, x, y + 1) != AIR


static func _place_entities(out: Dictionary, grounds: Dictionary, biome: Dictionary, district: int, rng: RandomNumberGenerator, madman: bool) -> void:
	var ents: Array = out["entities"]
	var final: bool = out["biome"] == "nido"
	var start: Vector2i = out["start_room"]
	var exit_room: Vector2i = out["exit_room"]
	var enemy_table: Array = biome["enemies"]
	var total_w := 0
	for e in enemy_table:
		total_w += int(e[1])
	# Sala del jefe: la más lejana al inicio que no sea la de salida.
	var boss_room := Vector2i(-1, -1)
	if not biome["bosses"].is_empty() and rng.randf() < float(biome["boss_chance"]):
		var best := -1
		for c in out["rooms"]:
			if c == start or c == exit_room:
				continue
			var dd: int = abs(c.x - start.x) + abs(c.y - start.y)
			if dd > best:
				best = dd
				boss_room = c
	var rooms_sorted: Array = out["rooms"].keys()
	rooms_sorted.sort()
	for c in rooms_sorted:
		var ox: int = c.x * RW
		var oy: int = c.y * RH
		var spots := []
		for x in range(2, RW - 2):
			for y in range(1, RH - 1):
				if standable(out, ox + x, oy + y):
					spots.append(Vector2i(ox + x, oy + y))
		if spots.is_empty():
			continue
		var used := {}
		var take := func() -> Vector2i:
			for _i in 20:
				var s: Vector2i = spots[rng.randi() % spots.size()]
				if not used.has(s.x) and not used.has(s.x - 1) and not used.has(s.x + 1):
					used[s.x] = true
					return s
			return Vector2i(-1, -1)
		var is_start: bool = c == start
		var is_exit: bool = c == exit_room
		# Decoración de fondo (no interactiva).
		for i in rng.randi_range(2, 5):
			var sd: Vector2i = spots[rng.randi() % spots.size()]
			ents.append({"kind": "planta", "pos": _px(sd), "h": rng.randi_range(40, 120), "v": rng.randi() % 5})
		for i in rng.randi_range(1, 4):
			var vx := ox + rng.randi_range(2, RW - 3)
			for vy in range(oy + 1, oy + RH - 2):
				if tile_at(out, vx, vy) == AIR and tile_at(out, vx, vy - 1) == SOLID:
					ents.append({"kind": "enredadera", "pos": Vector2(vx * TILE + 8, vy * TILE), "h": rng.randi_range(12, 40), "v": rng.randi() % 5})
					break
		# Árboles, rocas, hierba.
		if biome["trees"] and not is_exit:
			for i in rng.randi_range(1, 3):
				var s: Vector2i = take.call()
				if s.x >= 0 and tile_at(out, s.x, s.y + 1) == SOLID:
					ents.append({"kind": "arbol", "pos": _px(s)})
		for i in rng.randi_range(1, 3 if not final else 4):
			var s: Vector2i = take.call()
			if s.x < 0 or is_exit:
				continue
			ents.append({"kind": "roca", "pos": _px(s), "ore": _pick_ore(district, final, rng)})
		if biome["grass"]:
			for i in rng.randi_range(1, 3):
				var s: Vector2i = take.call()
				if s.x >= 0:
					ents.append({"kind": "hierba", "pos": _px(s)})
		if rng.randf() < 0.55:
			var s: Vector2i = spots[rng.randi() % spots.size()]
			ents.append({"kind": "luz_bicho", "pos": _px(s) + Vector2(0, -rng.randi_range(24, 56)),
				"elem": ItemDB.ELEMENTS[rng.randi() % 3]})
		if not is_start and rng.randf() < 0.14 * float(biome.get("chest_mult", 1.0)):
			var s: Vector2i = take.call()
			if s.x >= 0:
				ents.append({"kind": "cofre", "pos": _px(s), "golden": rng.randf() < 0.25})
		if is_start or final and c.x == 0:
			continue
		# Enemigos.
		var n := rng.randi_range(1, 3) + district / 7 + (1 if madman else 0)
		if is_exit:
			n = max(1, n - 1)
		for i in n:
			var roll: int = rng.randi() % maxi(total_w, 1)
			var id: String = enemy_table[0][0]
			for e in enemy_table:
				roll -= int(e[1])
				if roll < 0:
					id = e[0]
					break
			var s: Vector2i = take.call()
			if s.x < 0:
				s = spots[rng.randi() % spots.size()]
			var pos := _px(s)
			if Content.enemy(id).get("flying", false):
				pos += Vector2(0, -rng.randi_range(20, 60))
			ents.append({"kind": "enemigo", "id": id, "pos": pos})
		for p in biome["passive"]:
			if rng.randf() < 0.5:
				var s: Vector2i = take.call()
				if s.x >= 0:
					ents.append({"kind": "enemigo", "id": p, "pos": _px(s)})
		# Trampas.
		var hz: String = biome["hazard"]
		if hz != "" and not is_exit:
			for i in rng.randi_range(0, 2):
				var s: Vector2i = spots[rng.randi() % spots.size()]
				ents.append({"kind": "trampa", "id": hz, "pos": _px(s) + Vector2(0, -48 if hz in ["bola_pinchos", "cuchilla_cristal"] else 0)})
		for sp in biome["special"]:
			if sp == "colmena" and rng.randf() < 0.2:
				var s: Vector2i = take.call()
				if s.x >= 0:
					ents.append({"kind": "colmena", "pos": _px(s)})
			if sp == "huevo_arana":
				for i in rng.randi_range(0, 2):
					var s: Vector2i = take.call()
					if s.x >= 0:
						ents.append({"kind": "huevo_arana", "pos": _px(s)})
		if c == boss_room:
			var bid: String = biome["bosses"][rng.randi() % biome["bosses"].size()]
			var s: Vector2i = spots[spots.size() / 2]
			out["boss"] = {"id": bid, "pos": _px(s) + Vector2(0, -8)}
			ents.append({"kind": "enemigo", "id": bid, "pos": _px(s) + Vector2(0, -8)})
	if final:
		out["boss"] = {"id": "muro_ceniza", "pos": Vector2(-40, out["h"] * TILE / 2.0)}


static func _px(s: Vector2i) -> Vector2:
	return Vector2(s.x * TILE + 8, (s.y + 1) * TILE)


static func _pick_ore(district: int, final: bool, rng: RandomNumberGenerator) -> String:
	if final:
		return "ceniza" if rng.randf() < 0.5 else "diamante"
	var r := rng.randf()
	if r < 0.55:
		return "piedra"
	if r < 0.68:
		return "carbon"
	var opts := ["hierro"]
	if district >= 5:
		opts.append("oro")
	if district >= 10:
		opts.append("diamante")
	return opts[rng.randi() % opts.size()]


# --- Alcanzabilidad (tests y validación) ------------------------------------------

## BFS sobre posiciones donde se puede estar de pie, con saltos de hasta JUMP_TILES de alto.
static func reachable_set(d: Dictionary, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue := [from]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for n in _neighbors(d, p):
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen


static func _fall(d: Dictionary, x: int, y: int) -> Vector2i:
	var yy := y
	while yy < d["h"] - 1 and tile_at(d, x, yy + 1) == AIR:
		yy += 1
	if tile_at(d, x, yy) == AIR and tile_at(d, x, yy - 1) != SOLID:
		return Vector2i(x, yy)
	return Vector2i(-1, -1)


static func _neighbors(d: Dictionary, p: Vector2i) -> Array:
	var out := []
	for dx in [-1, 1]:
		var nx: int = p.x + dx
		if tile_at(d, nx, p.y) != SOLID and tile_at(d, nx, p.y - 1) != SOLID:
			if standable(d, nx, p.y):
				out.append(Vector2i(nx, p.y))
			else:
				var f := _fall(d, nx, p.y)
				if f.x >= 0:
					out.append(f)
	# Bajar de una plataforma de un sentido.
	if tile_at(d, p.x, p.y + 1) == ONEWAY:
		var f2 := _fall(d, p.x, p.y + 1)
		if f2.x >= 0:
			out.append(f2)
	# Saltos: sube hasta JUMP_TILES por la columna actual y avanza en horizontal.
	var top := 0
	for k in range(1, JUMP_TILES + 1):
		if tile_at(d, p.x, p.y - k - 1) == SOLID:
			break
		top = k
	for dy in range(0, top + 1):
		var y := p.y - dy
		for dx in range(-5, 6):
			if dx == 0 and dy == 0:
				continue
			var x: int = p.x + dx
			var clear := true
			var step := 1 if dx > 0 else -1
			if dx != 0:
				for xx in range(p.x + step, x + step, step):
					if tile_at(d, xx, y - 1) == SOLID or tile_at(d, xx, y) == SOLID:
						clear = false
						break
			if not clear:
				continue
			if standable(d, x, y):
				out.append(Vector2i(x, y))
			elif dy > 0 or dx != 0:
				var f3 := _fall(d, x, y)
				if f3.x >= 0 and tile_at(d, x, y) == AIR:
					out.append(f3)
	return out


static func px_to_tile(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori((p.y - 1) / TILE))


# --- Pueblo -------------------------------------------------------------------------

## Pueblo: una calle plana de 3 salas de ancho con edificios y vecinos.
static func generate_town(seed_value: int, biome_id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := RW * 3
	var h := RH
	var tiles := PackedByteArray()
	tiles.resize(w * h)
	tiles.fill(SOLID)
	for x in range(1, w - 1):
		for y in range(1, 15):
			tiles[y * w + x] = AIR
	# Salida a la derecha.
	for y in range(11, 15):
		tiles[y * w + w - 1] = AIR
	var ground_y := 15 * TILE
	var npcs := [
		{"kind": "tendero", "shop": "herramientas", "x": 10},
		{"kind": "tendero", "shop": "materiales", "x": 22},
		{"kind": "herrero", "x": 34},
		{"kind": "sastra", "x": 44},
		{"kind": "peletero", "x": 54},
		{"kind": "comprador", "x": 64},
	]
	var ents := []
	for n in npcs:
		ents.append({"kind": "npc", "npc": n["kind"], "shop": n.get("shop", ""), "pos": Vector2(n["x"] * TILE + 8, ground_y)})
	var altar_x := [72, 76, 80, 84]
	for i in 4:
		ents.append({"kind": "altar", "altar": Content.ALTARS[i]["id"], "pos": Vector2(altar_x[i] * TILE + 8, ground_y)})
	for i in rng.randi_range(4, 6):
		ents.append({"kind": "enemigo", "id": "gallina", "pos": Vector2(rng.randi_range(4, w - 6) * TILE, ground_y)})
	for i in rng.randi_range(2, 4):
		ents.append({"kind": "vecino", "pos": Vector2(rng.randi_range(4, w - 6) * TILE, ground_y)})
	return {"w": w, "h": h, "tiles": tiles, "biome": biome_id, "town": true, "entities": ents,
		"spawn": Vector2(3 * TILE, ground_y), "exit": Vector2((w - 2) * TILE, ground_y), "doors": [], "boss": {}}
