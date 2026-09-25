extends CanvasLayer
## Consola de depuración. Se abre con ` (acento grave) o F12.
## Tab autocompleta, ↑/↓ recorren el historial, "help" lista los comandos.

const MAX_LINES := 200
const COMMANDS := {
	"help": "help [comando] · lista de comandos",
	"clear": "clear · limpia la consola",
	"give": "give <objeto> [cantidad] · da un objeto",
	"spawn": "spawn <enemigo> [cantidad] · genera enemigos junto a ti",
	"kill": "kill [all|jefe] · mata a los enemigos (no a los guardianes)",
	"heal": "heal · vida, maná, estamina y hambre al máximo",
	"god": "god · invulnerabilidad on/off",
	"noclip": "noclip · atravesar paredes y volar on/off",
	"level": "level <n> · sube hasta ese nivel",
	"xp": "xp <n> · da experiencia",
	"coins": "coins <n> · da monedas",
	"stat": "stat <hp|atk|dex|mag> <n> · suma a una estadística",
	"skill": "skill <id> · aprende una habilidad",
	"district": "district <bioma> [n] · va a un distrito de ese bioma",
	"town": "town [bioma] · va a un pueblo",
	"door": "door <n> · cruza la puerta n (1-3) del distrito",
	"final": "final · va al Nido de Ceniza (jefe final)",
	"time": "time <segundos> · fija el tiempo pasado en el distrito (guardianes a los 300)",
	"speed": "speed <x> · velocidad del juego (1 = normal)",
	"tp": "tp <x> <y> · teletransporte (en tiles)",
	"exit": "exit · teletransporte a la sala de salida",
	"reveal": "reveal · muestra dónde está el jefe y la salida",
	"unlock": "unlock all · desbloquea razas, sombreros y compañeros",
	"hat": "hat <id> · cambia de sombrero",
	"companion": "companion <id> · cambia de compañero",
	"race": "race <id> · cambia de raza",
	"list": "list <items|enemies|biomes|skills|hats|companions|races>",
	"info": "info · estado de la partida",
	"stats": "stats · panel de FPS y entidades on/off",
	"win": "win · gana la partida",
	"die": "die · pierde la partida",
	"seed": "seed · muestra la semilla",
	"fx": "fx <shake|explosion> · prueba un efecto",
}

var main: Node
var open := false
var input := ""
var lines: Array = []
var history: Array = []
var hist_i := -1
var show_stats := false
var draw_node: Node2D
var t := 0.0
var noclip := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_node = Node2D.new()
	draw_node.draw.connect(_draw_console)
	add_child(draw_node)
	log_line("Consola de Subterra. Escribe 'help'.", Color("#8aff9a"))


func log_line(s: String, col: Color = Color("#e0d8c8")) -> void:
	for l in s.split("\n"):
		lines.append({"s": l, "c": col})
	while lines.size() > MAX_LINES:
		lines.pop_front()


func _process(dt: float) -> void:
	t += dt
	if open or show_stats:
		draw_node.queue_redraw()
	if noclip:
		var h := _hero()
		if h:
			h.noclip = true
			h.use_gravity = false
			var m := Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
			h.vel = m * 220.0


func _input(ev: InputEvent) -> void:
	if not ev is InputEventKey or not ev.pressed:
		return
	var k: InputEventKey = ev
	# ` según la distribución del teclado (en español es tecla muerta: se detecta por el
	# código lógico o por el carácter).
	if k.keycode == KEY_QUOTELEFT or k.unicode == 96 or k.keycode == KEY_F12:
		open = not open
		draw_node.queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	get_viewport().set_input_as_handled()
	match k.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			if input.strip_edges() != "":
				history.append(input)
				hist_i = -1
				log_line("> " + input, Color("#fff08a"))
				exec(input)
			input = ""
		KEY_BACKSPACE:
			input = input.substr(0, input.length() - 1)
		KEY_ESCAPE:
			open = false
		KEY_TAB:
			_complete()
		KEY_UP:
			if not history.is_empty():
				hist_i = history.size() - 1 if hist_i == -1 else maxi(0, hist_i - 1)
				input = history[hist_i]
		KEY_DOWN:
			if hist_i != -1:
				hist_i += 1
				if hist_i >= history.size():
					hist_i = -1
					input = ""
				else:
					input = history[hist_i]
		_:
			if k.unicode > 31 and k.unicode != 96:
				input += char(k.unicode)
	draw_node.queue_redraw()


func _complete() -> void:
	var parts := input.split(" ")
	var opts := []
	if parts.size() <= 1:
		opts = COMMANDS.keys()
	else:
		opts = _args_for(parts[0])
	var last: String = parts[parts.size() - 1]
	var m := opts.filter(func(o): return str(o).begins_with(last))
	if m.size() == 1:
		parts[parts.size() - 1] = m[0]
		input = " ".join(parts) + " "
	elif m.size() > 1:
		log_line(", ".join(m.slice(0, 40)), Color("#a0c0ff"))
		var pre: String = m[0]
		for o in m:
			while not str(o).begins_with(pre):
				pre = pre.substr(0, pre.length() - 1)
		parts[parts.size() - 1] = pre
		input = " ".join(parts)


func _args_for(cmd: String) -> Array:
	match cmd:
		"give": return ItemDB.all().keys()
		"spawn": return Content.ENEMIES.keys()
		"district", "town": return Content.BIOMES.keys()
		"skill": return Content.SKILLS.map(func(s): return s["id"])
		"hat": return Content.HATS.map(func(s): return s["id"])
		"companion": return Content.COMPANIONS.map(func(s): return s["id"])
		"race": return Content.RACES.map(func(s): return s["id"])
		"list": return ["items", "enemies", "biomes", "skills", "hats", "companions", "races"]
		"stat": return ["hp", "atk", "dex", "mag"]
		"help": return COMMANDS.keys()
		"kill": return ["all", "jefe"]
		"fx": return ["shake", "explosion"]
		"unlock": return ["all"]
	return []


# --- Acceso a la partida ------------------------------------------------------------------------

func _run() -> Node:
	if main and is_instance_valid(main) and main.run and is_instance_valid(main.run):
		return main.run
	return null


func _world() -> Node:
	var r := _run()
	return r.world if r and r.world and is_instance_valid(r.world) else null


func _hero() -> Node:
	var w := _world()
	if w == null:
		return null
	for p in w.players:
		if p.is_local:
			return p
	return w.players[0] if not w.players.is_empty() else null


func _need_game() -> bool:
	if _hero() == null:
		log_line("No hay ninguna partida en curso.", Color("#ff8a8a"))
		return false
	if Net.is_client():
		log_line("En cooperativo solo el anfitrión puede usar trucos.", Color("#ff8a8a"))
		return false
	return true


# --- Comandos --------------------------------------------------------------------------------------

## Ejecuta una línea de comando. Devuelve true si el comando existe.
func exec(line: String) -> bool:
	var parts := Array(line.strip_edges().split(" ", false))
	if parts.is_empty():
		return false
	var cmd: String = parts.pop_front().to_lower()
	if not COMMANDS.has(cmd):
		log_line("Comando desconocido: %s (escribe help)" % cmd, Color("#ff8a8a"))
		return false
	var a := parts
	match cmd:
		"help":
			if a.size() > 0 and COMMANDS.has(a[0]):
				log_line(COMMANDS[a[0]])
			else:
				var keys := COMMANDS.keys()
				keys.sort()
				for k in keys:
					log_line(COMMANDS[k], Color("#c0d8ff"))
		"clear":
			lines.clear()
		"seed":
			var r := _run()
			log_line("Semilla: %s" % (str(r.seed_value) if r else "-"))
		"list":
			var what: String = a[0] if a.size() > 0 else ""
			var l: Array = []
			match what:
				"items": l = ItemDB.all().keys()
				"enemies": l = Content.ENEMIES.keys()
				"biomes": l = Content.BIOMES.keys()
				"skills": l = Content.SKILLS.map(func(s): return s["id"])
				"hats": l = Content.HATS.map(func(s): return s["id"])
				"companions": l = Content.COMPANIONS.map(func(s): return s["id"])
				"races": l = Content.RACES.map(func(s): return s["id"])
				_:
					log_line(COMMANDS["list"])
					return true
			l.sort()
			log_line(PixelFont.wrap(", ".join(l), 74), Color("#c0d8ff"))
		"stats":
			show_stats = not show_stats
			log_line("Panel de estadísticas: %s" % ("sí" if show_stats else "no"))
		"unlock":
			for pair in [["race", Content.RACES], ["hat", Content.HATS], ["companion", Content.COMPANIONS]]:
				for e in pair[1]:
					if not Game.owned[pair[0]].has(e["id"]):
						Game.owned[pair[0]].append(e["id"])
			Game.save_profile()
			log_line("Todo desbloqueado.", Color("#8aff9a"))
		_:
			if not _need_game():
				return true
			_game_cmd(cmd, a)
	return true


func _int(a: Array, i: int, def: int) -> int:
	return int(a[i]) if a.size() > i and str(a[i]).is_valid_int() else def


func _game_cmd(cmd: String, a: Array) -> void:
	var r := _run()
	var w := _world()
	var h := _hero()
	var m: HeroModel = h.model
	match cmd:
		"give":
			if a.is_empty() or not ItemDB.has(a[0]):
				log_line("Objeto desconocido. Usa Tab o 'list items'.", Color("#ff8a8a"))
				return
			var n := _int(a, 1, 1)
			var left := 0
			for i in n:
				left += m.inv.add(Inventory.make(a[0], 1))
			log_line("Dado: %s x%d%s" % [a[0], n - left, " (inventario lleno)" if left > 0 else ""], Color("#8aff9a"))
		"spawn":
			if a.is_empty() or not Content.ENEMIES.has(a[0]):
				log_line("Enemigo desconocido. Usa Tab o 'list enemies'.", Color("#ff8a8a"))
				return
			for i in _int(a, 1, 1):
				w.spawn_enemy(a[0], h.position + Vector2(h.facing * (50 + i * 18), -20))
			log_line("Generado: %s x%d" % [a[0], _int(a, 1, 1)], Color("#8aff9a"))
		"kill":
			var n := 0
			for e in w.enemies:
				if e.id == "guardian" or e.data["ai"] == "aliado":
					continue
				if a.size() > 0 and a[0] == "jefe" and not e.boss:
					continue
				e.die(h)
				n += 1
			w._cleanup()
			log_line("Eliminados: %d" % n)
		"heal":
			m.hp = m.max_hp()
			m.mana = m.max_mana()
			m.stamina = m.max_stamina()
			m.hunger = m.max_hunger()
			if h.downed:
				h.revive()
			log_line("Curado.", Color("#8aff9a"))
		"god":
			w.god_mode = not w.god_mode
			log_line("Modo dios: %s" % ("sí" if w.god_mode else "no"))
		"noclip":
			noclip = not noclip
			if not noclip:
				h.noclip = false
				h.use_gravity = true
				h.unstuck()
			log_line("Noclip: %s (muévete con WASD)" % ("sí" if noclip else "no"))
		"level":
			var target := _int(a, 0, m.level + 1)
			while m.level < target:
				w.give_xp(h, HeroModel.xp_to_next(m.level) - m.xp)
			log_line("Nivel %d" % m.level)
		"xp":
			w.give_xp(h, _int(a, 0, 10))
		"coins":
			m.coins += _int(a, 0, 100)
			log_line("Monedas: %d" % m.coins)
		"stat":
			if a.size() < 1 or not a[0] in ["hp", "atk", "dex", "mag"]:
				log_line(COMMANDS["stat"], Color("#ff8a8a"))
				return
			m.extra[a[0]] += _int(a, 1, 1)
			if a[0] == "hp":
				m.hp = m.max_hp()
			log_line("%s = %d" % [a[0], m.stat(a[0])])
		"skill":
			var ids: Array = Content.SKILLS.map(func(s): return s["id"])
			if a.is_empty() or not ids.has(a[0]):
				log_line("Habilidad desconocida.", Color("#ff8a8a"))
				return
			if m.skills.size() >= 3:
				m.skills.pop_front()
			m.learn_skill(a[0])
			log_line("Habilidad: %s" % a[0])
		"hat", "companion", "race":
			var list: Array = {"hat": Content.HATS, "companion": Content.COMPANIONS, "race": Content.RACES}[cmd]
			var ids2: Array = list.map(func(s): return s["id"])
			if a.is_empty() or not ids2.has(a[0]):
				log_line("Id desconocido. Usa Tab.", Color("#ff8a8a"))
				return
			match cmd:
				"hat": m.hat_id = a[0]
				"companion": m.companion_id = a[0]
				"race": m.race_id = a[0]
			log_line("%s = %s" % [cmd, a[0]])
		"district":
			var b: String = a[0] if a.size() > 0 else r.biome
			if not Content.BIOMES.has(b):
				log_line("Bioma desconocido.", Color("#ff8a8a"))
				return
			r.district = _int(a, 1, r.district)
			r.enter_district(b)
			log_line("Distrito %d: %s" % [r.district, b])
		"town":
			var b2: String = a[0] if a.size() > 0 else "bosque"
			r.enter_town(b2)
		"door":
			var doors: Array = w.npcs.filter(func(n): return n.kind == "puerta")
			var i := _int(a, 0, 1) - 1
			if doors.is_empty() or i < 0 or i >= doors.size():
				log_line("No hay esa puerta aquí.", Color("#ff8a8a"))
				return
			r.choose_door(doors[i].biome)
		"final":
			r.district = Content.FINAL_DISTRICT
			r.enter_district("nido")
		"time":
			w.time_in = float(_int(a, 0, 0))
			w.guardian_warned = w.time_in > World.GUARDIAN_TIME - 30.0
			w.guardian_next = maxf(w.time_in, World.GUARDIAN_TIME)
			log_line("Tiempo del distrito: %ds" % int(w.time_in))
		"speed":
			var sp := float(a[0]) if a.size() > 0 and str(a[0]).is_valid_float() else 1.0
			Engine.time_scale = clampf(sp, 0.1, 5.0)
			log_line("Velocidad: x%.2f" % Engine.time_scale)
		"tp":
			if a.size() < 2:
				log_line(COMMANDS["tp"], Color("#ff8a8a"))
				return
			h.teleport(Vector2(_int(a, 0, 0) * World.T + 8, _int(a, 1, 0) * World.T))
			h.unstuck()
		"exit":
			if w.is_town:
				h.teleport(w.map["exit"])
			else:
				var ex: Vector2i = w.map["exit_room"]
				h.teleport(Vector2((ex.x * DistrictGen.RW + 4) * World.T, (ex.y * DistrictGen.RH + 15) * World.T))
				h.unstuck()
		"reveal":
			if w.is_town:
				log_line("En el pueblo la salida está a la derecha.")
				return
			log_line("Sala de salida: %s" % str(w.map["exit_room"]))
			if w.boss_node and is_instance_valid(w.boss_node):
				log_line("Jefe: %s en tile %s" % [w.boss_node.id, str((w.boss_node.position / World.T).floor())])
			else:
				log_line("No hay jefe en este distrito.")
		"info":
			var bi: String = r.biome if r.state == "district" else "pueblo hacia " + r.next_biome
			log_line("Distrito %d · %s · tiempo %ds · semilla %d" % [r.district, bi, int(w.time_in), r.seed_value])
			log_line("%s (%s) nv %d · vida %d/%d · maná %d/%d · monedas %d" % [m.name, m.race_id, m.level, m.hp, m.max_hp(), int(m.mana), m.max_mana(), m.coins])
			log_line("ATQ %d · DES %d · MAG %d · habilidades %s" % [m.stat("atk"), m.stat("dex"), m.stat("mag"), str(m.skills)])
			log_line("Posición (tiles): %s · enemigos %d · proyectiles %d" % [str((h.position / World.T).floor()), w.enemies.size(), w.projectiles.size()])
		"win":
			r.win()
		"die":
			w.god_mode = false
			h.hurt(99999, "consola", h.position, true)
		"fx":
			if a.size() > 0 and a[0] == "explosion":
				w.fx.explosion(h.center() + Vector2(h.facing * 30, 0), 20.0)
			w.shake(6.0)


# --- Dibujo ------------------------------------------------------------------------------------------

func _draw_console() -> void:
	var c := draw_node
	if show_stats:
		var w := _world()
		var info := "FPS %d" % Engine.get_frames_per_second()
		if w:
			info += " ENE %d PRO %d OBJ %d LUZ %d" % [w.enemies.size(), w.projectiles.size(), w.pickups.size(), w.lights.size()]
			var h := _hero()
			if h:
				var tp: Vector2 = (h.position / World.T).floor()
				info += " TILE %d,%d" % [int(tp.x), int(tp.y)]
		c.draw_rect(Rect2(0, 262, 480, 8), Color(0, 0, 0, 0.6))
		PixelFont.draw(c, Vector2(2, 263), info, Color("#8aff9a"), 1, false)
	if not open:
		return
	var hgt := 150.0
	c.draw_rect(Rect2(0, 0, 480, hgt), Color(0.03, 0.02, 0.05, 0.9))
	c.draw_rect(Rect2(0, hgt, 480, 1), Color("#8a6a4a"))
	var max_visible := int((hgt - 14) / PixelFont.LINE)
	var start := maxi(0, lines.size() - max_visible)
	for i in range(start, lines.size()):
		PixelFont.draw(c, Vector2(4, 3 + (i - start) * PixelFont.LINE), lines[i]["s"], lines[i]["c"], 1, false)
	c.draw_rect(Rect2(0, hgt - 11, 480, 11), Color(0.1, 0.08, 0.12, 1))
	var cursor := "_" if int(t * 3.0) % 2 == 0 else " "
	PixelFont.draw(c, Vector2(4, hgt - 9), "> " + input + cursor, Color("#fff08a"), 1, false)
