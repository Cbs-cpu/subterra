class_name HeroModel
extends RefCounted
## Todo lo que es un personaje excepto su cuerpo físico: estadísticas, crecimiento, nivel,
## inventario, hambre, maná, estamina, habilidades, mejoras temporales y efectos de
## raza/rasgos/sombrero/compañero. Lógica pura: se puede testear sin escena.

signal leveled_up(level: int, gains: Dictionary)
signal skill_offer(options: Array)

const STATS := ["hp", "atk", "dex", "mag"]

var name := "Héroe"
var race_id := "minero"
var hat_id := "ninguno"
var companion_id := "ninguno"
var traits: Array = []
var base := {"hp": 4, "atk": 2, "dex": 2, "mag": 2}   # sin raza ni rasgos
var growth := {"hp": 1, "atk": 1, "dex": 1, "mag": 1}  # 0 bajo, 1 normal, 2 alto
var extra := {"hp": 0, "atk": 0, "dex": 0, "mag": 0}   # altares, etc.
var level := 1
var xp := 0
var hp := 5
var mana := 3.0
var stamina := 2.0
var hunger := 8.0
var coins := 0
var skills: Array = []          # ids (máx. 3)
var skill_cd := {}              # id -> segundos restantes
var buffs: Array = []           # {stat, amount, t} o {flag, t}
var inv := Inventory.new()
var pending_skill_offers := 0
var starve_t := 0.0
var mana_t := 0.0
var stamina_t := 0.0
var drain_t := 0.0


# --- Creación ------------------------------------------------------------------

## Reparto aleatorio de 15 puntos: Vida 4..6, resto 2..4. Crecimientos: 1-2 altos, 0-1 bajo.
static func roll_stats(rng: RandomNumberGenerator) -> Dictionary:
	var b := {"hp": 4, "atk": 2, "dex": 2, "mag": 2}
	var caps := {"hp": 6, "atk": 4, "dex": 4, "mag": 4}
	var left := 5
	var guard := 0
	while left > 0 and guard < 200:
		guard += 1
		var s: String = STATS[rng.randi() % 4]
		if b[s] < caps[s]:
			b[s] += 1
			left -= 1
	var g := {"hp": 1, "atk": 1, "dex": 1, "mag": 1}
	g[STATS[rng.randi() % 4]] = 2
	if rng.randf() < 0.5:
		g[STATS[rng.randi() % 4]] = 2
	if rng.randf() < 0.5:
		var bad: String = STATS[rng.randi() % 4]
		g[bad] = 1 if g[bad] == 2 else 0
	return {"base": b, "growth": g}


func setup(p_race: String, p_traits: Array, p_hat: String, p_companion: String, rolled: Dictionary, rng: RandomNumberGenerator) -> void:
	race_id = p_race
	traits = p_traits.duplicate()
	hat_id = p_hat
	companion_id = p_companion
	base = rolled["base"].duplicate()
	growth = rolled["growth"].duplicate()
	var r := Content.race(race_id)
	for id in r["items"]:
		inv.add(Inventory.make(id, 1))
	var randoms := ["pocion_vida", "carne_cruda", "pico_madera", "espada_madera", "hierba", "seta", "red_bichos", "tablon"]
	for i in int(r.get("random_items", 0)):
		inv.add(Inventory.make(randoms[rng.randi() % randoms.size()], 1))
	hp = max_hp()
	mana = max_mana()
	stamina = max_stamina()
	hunger = 8.0


# --- Efectos acumulados ---------------------------------------------------------

## Suma de efectos (fx) de rasgos, sombrero y compañero.
func fx() -> Dictionary:
	var out := {}
	var sources := []
	for t in traits:
		sources.append(Content.find(Content.TRAITS, t)["fx"])
	sources.append(Content.find(Content.HATS, hat_id)["fx"])
	sources.append(Content.find(Content.COMPANIONS, companion_id)["fx"])
	for f in sources:
		for k in f:
			var v = f[k]
			if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
				if k.ends_with("_mult"):
					out[k] = out.get(k, 1.0) * float(v)
				elif k in ["hunger_max", "mana_regen", "hp_drain", "spit_item"]:
					out[k] = v
				else:
					out[k] = out.get(k, 0.0) + float(v)
			else:
				out[k] = v
	return out


func has_fx(k: String) -> bool:
	return fx().has(k)


## Estadística total: base + raza + rasgos + extra + equipo + mejoras.
func stat(s: String) -> int:
	var v: int = base[s] + extra[s]
	v += int(Content.race(race_id)["stats"].get(s, 0))
	var f := fx()
	v += int(f.get(s, 0))
	v += int(inv.gear_stats()[s])
	for b in buffs:
		if b.get("stat", "") == s:
			v += int(b["amount"])
	return v


func max_hp() -> int:
	return max(1, stat("hp"))


func max_mana() -> int:
	return max(1, stat("mag") + 1)


func max_stamina() -> int:
	return clampi(1 + stat("dex") / 3, 2, 8)


func max_hunger() -> int:
	return int(fx().get("hunger_max", 8))


func luck() -> float:
	return float(fx().get("luck", 0.0))


func crit_chance() -> float:
	return 0.05 + float(fx().get("crit", 0.0))


func move_speed() -> float:
	var s := 96.0 * (1.0 + stat("dex") * 0.008)
	s *= float(fx().get("speed_mult", 1.0))
	if has_buff("carga"):
		s *= 1.35
	return s


func has_buff(flag: String) -> bool:
	for b in buffs:
		if b.get("flag", "") == flag:
			return true
	return false


func add_buff(b: Dictionary) -> void:
	buffs.append(b)


# --- Tiempo ---------------------------------------------------------------------

## Avanza hambre, maná, estamina, recargas y mejoras. Devuelve eventos ("starve", "drain", "frost_heal").
func tick(dt: float, in_town := false) -> Array:
	var ev := []
	if not in_town:
		hunger = max(0.0, hunger - dt / 45.0)
	if hunger <= 0.0:
		starve_t += dt
		if starve_t >= 10.0:
			starve_t = 0.0
			ev.append("starve")
	else:
		starve_t = 0.0
	var f := fx()
	var regen_period: float = f.get("mana_regen", 3.0)
	mana_t += dt
	if mana_t >= regen_period and mana < max_mana():
		mana_t = 0.0
		mana = min(float(max_mana()), mana + 1.0)
		if f.has("frost_regen") and randf() < float(f["frost_regen"]):
			ev.append("frost_heal")
	stamina_t += dt
	if stamina_t >= 1.1 and stamina < max_stamina():
		stamina_t = 0.0
		stamina = min(float(max_stamina()), stamina + 1.0)
	if f.has("hp_drain"):
		drain_t += dt
		if drain_t >= float(f["hp_drain"]):
			drain_t = 0.0
			ev.append("drain")
	for k in skill_cd.keys():
		skill_cd[k] = max(0.0, skill_cd[k] - dt)
	for b in buffs:
		b["t"] -= dt
	buffs = buffs.filter(func(b): return b["t"] > 0.0)
	return ev


func use_stamina() -> bool:
	if has_fx("free_stamina"):
		return true
	if stamina >= 1.0:
		stamina -= 1.0
		stamina_t = 0.0
		return true
	return false


func use_mana(cost: float) -> bool:
	if has_fx("spell_free") and randf() < float(fx()["spell_free"]):
		return true
	if mana >= cost:
		mana -= cost
		return true
	return false


func damage(amount: int) -> int:
	var a := amount
	if has_buff("aura"):
		a -= 4
	if has_fx("dmg_half"):
		a = a / 2
	a = max(a, 1) if amount > 0 else 0
	hp -= a
	return a


func heal(amount: int) -> void:
	hp = min(max_hp(), hp + amount)


func eat(food: Dictionary, rng: RandomNumberGenerator) -> void:
	hunger = min(float(max_hunger()), hunger + float(food.get("hunger", 0)))
	if rng.randf() < float(food.get("heal", 0.0)):
		heal(1)


# --- Experiencia y nivel ------------------------------------------------------------

static func xp_to_next(lvl: int) -> int:
	return 8 + lvl * 7


func gain_xp(amount: int, rng: RandomNumberGenerator) -> int:
	xp += amount
	var ups := 0
	while xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		ups += 1
		_level_up(rng)
	return ups


func _level_up(rng: RandomNumberGenerator) -> void:
	var gains := {}
	var p := {0: 0.15, 1: 0.35, 2: 0.6}
	for s in STATS:
		if rng.randf() < p[growth[s]]:
			gains[s] = gains.get(s, 0) + 1
	if gains.is_empty():
		gains[STATS[rng.randi() % 4]] = 1
	var f := fx()
	for pair in [["lvl_atk", "atk"], ["lvl_dex", "dex"], ["lvl_mag", "mag"]]:
		if f.has(pair[0]) and rng.randf() < float(f[pair[0]]):
			gains[pair[1]] = gains.get(pair[1], 0) + 1
	if f.has("lvl_any") and rng.randf() < float(f["lvl_any"]):
		var s: String = STATS[rng.randi() % 4]
		gains[s] = gains.get(s, 0) + 1
	if f.has("lvl_extra"):
		var s2: String = STATS[rng.randi() % 4]
		gains[s2] = gains.get(s2, 0) + 1
	for s in gains:
		base[s] += gains[s]
	if gains.has("hp"):
		hp += gains["hp"]
	if level % 5 == 0 and skills.size() < 3:
		pending_skill_offers += 1
	leveled_up.emit(level, gains)


## 3 habilidades aleatorias que no se tengan.
func roll_skill_offer(rng: RandomNumberGenerator) -> Array:
	var pool := []
	for s in Content.SKILLS:
		if not skills.has(s["id"]) or s["id"] == "lobo":
			pool.append(s["id"])
	var out := []
	while out.size() < 3 and not pool.is_empty():
		var i := rng.randi() % pool.size()
		out.append(pool[i])
		pool.remove_at(i)
	return out


func learn_skill(id: String) -> void:
	if skills.size() < 3:
		skills.append(id)
		skill_cd[id] = 0.0
	pending_skill_offers = max(0, pending_skill_offers - 1)


func reset_cooldowns() -> void:
	for k in skill_cd:
		skill_cd[k] = 0.0


# --- Guardado ---------------------------------------------------------------------

func to_data() -> Dictionary:
	return {"name": name, "race": race_id, "hat": hat_id, "companion": companion_id, "traits": traits,
		"base": base, "growth": growth, "extra": extra, "level": level, "xp": xp, "hp": hp, "mana": mana,
		"hunger": hunger, "coins": coins, "skills": skills, "inv": inv.to_data()}


func from_data(d: Dictionary) -> void:
	name = d["name"]
	race_id = d["race"]
	hat_id = d["hat"]
	companion_id = d["companion"]
	traits = d["traits"].duplicate()
	base = d["base"].duplicate()
	growth = d["growth"].duplicate()
	extra = d["extra"].duplicate()
	level = d["level"]
	xp = d["xp"]
	hp = d["hp"]
	mana = d["mana"]
	hunger = d["hunger"]
	coins = d["coins"]
	skills = d["skills"].duplicate()
	for s in skills:
		skill_cd[s] = 0.0
	inv.from_data(d["inv"])
