class_name Inventory
extends RefCounted
## Inventario: 32 ranuras (las 8 primeras son la barra rápida) + equipo.
## Una ranura es null o {id, n, dur, q, bonus}. Los objetos con durabilidad o calidad no se apilan.

signal changed

const SIZE := 32
const HOTBAR := 8
const MAX_STACK := 99
const EQUIP_SLOTS := ["cabeza", "cuerpo", "escudo", "anillo1", "anillo2"]

var slots: Array = []
var equip := {}
var hand := 0          # índice de la barra rápida seleccionada


func _init() -> void:
	slots.resize(SIZE)
	for s in EQUIP_SLOTS:
		equip[s] = null


static func make(id: String, n: int = 1) -> Dictionary:
	var it := ItemDB.get_item(id)
	var d := {"id": id, "n": n}
	if int(it.get("dur", 0)) > 0:
		d["dur"] = int(it["dur"])
	return d


static func is_stackable_stack(s: Dictionary) -> bool:
	return ItemDB.stackable(s["id"]) and not s.has("q") and not s.has("dur")


func held() -> Variant:
	return slots[hand]


func held_id() -> String:
	var h = slots[hand]
	return "" if h == null else h["id"]


## Añade un objeto (auto-apila). Devuelve lo que no cupo.
func add(stack: Dictionary) -> int:
	var left: int = stack["n"]
	if is_stackable_stack(stack):
		for i in SIZE:
			var s = slots[i]
			if s != null and s["id"] == stack["id"] and is_stackable_stack(s) and s["n"] < MAX_STACK:
				var put: int = min(MAX_STACK - s["n"], left)
				s["n"] += put
				left -= put
				if left == 0:
					changed.emit()
					return 0
	for i in SIZE:
		if slots[i] == null:
			var ns := stack.duplicate(true)
			if is_stackable_stack(stack):
				ns["n"] = min(left, MAX_STACK)
				left -= ns["n"]
			else:
				ns["n"] = 1
				left -= 1
			slots[i] = ns
			if left <= 0:
				changed.emit()
				return 0
	changed.emit()
	return left


func count(id: String) -> int:
	var c := 0
	for s in slots:
		if s != null and s["id"] == id:
			c += s["n"]
	return c


func remove(id: String, n: int) -> bool:
	if count(id) < n:
		return false
	for i in range(SIZE - 1, -1, -1):
		var s = slots[i]
		if s != null and s["id"] == id:
			var take: int = min(n, s["n"])
			s["n"] -= take
			n -= take
			if s["n"] <= 0:
				slots[i] = null
			if n == 0:
				break
	changed.emit()
	return true


func take_one(i: int) -> Variant:
	var s = slots[i]
	if s == null:
		return null
	var one: Dictionary = s.duplicate(true)
	one["n"] = 1
	s["n"] -= 1
	if s["n"] <= 0:
		slots[i] = null
	changed.emit()
	return one


## Mueve/intercambia/apila la ranura a en la b.
func move(a: int, b: int) -> void:
	if a == b:
		return
	var sa = slots[a]
	var sb = slots[b]
	if sa != null and sb != null and sa["id"] == sb["id"] and is_stackable_stack(sa) and is_stackable_stack(sb):
		var put: int = min(MAX_STACK - sb["n"], sa["n"])
		sb["n"] += put
		sa["n"] -= put
		if sa["n"] <= 0:
			slots[a] = null
	else:
		slots[a] = sb
		slots[b] = sa
	changed.emit()


## Divide: mueve la mitad del montón a (a una ranura vacía b).
func split(a: int, b: int) -> void:
	var sa = slots[a]
	if sa == null or slots[b] != null or sa["n"] < 2:
		return
	var half: int = sa["n"] / 2
	sa["n"] -= half
	var nb: Dictionary = sa.duplicate(true)
	nb["n"] = half
	slots[b] = nb
	changed.emit()


## Pone uno de a en b (vacía o del mismo tipo).
func place_one(a: int, b: int) -> void:
	var sa = slots[a]
	if sa == null:
		return
	var sb = slots[b]
	if sb == null:
		var one = take_one(a)
		slots[b] = one
	elif sb["id"] == sa["id"] and is_stackable_stack(sb) and sb["n"] < MAX_STACK:
		sa["n"] -= 1
		sb["n"] += 1
		if sa["n"] <= 0:
			slots[a] = null
	changed.emit()


func drop_slot(i: int) -> Variant:
	var s = slots[i]
	slots[i] = null
	changed.emit()
	return s


## Consume una unidad de durabilidad del objeto en la ranura i. Devuelve true si se rompió.
func wear(i: int, amount: int = 1) -> bool:
	var s = slots[i]
	if s == null or not s.has("dur"):
		return false
	s["dur"] -= amount
	if s["dur"] <= 0:
		slots[i] = null
		changed.emit()
		return true
	changed.emit()
	return false


## Combina dos ranuras con la receta de crafteo. Devuelve el objeto creado ({} si no hay receta).
func craft(a: int, b: int, luck: float, rng: RandomNumberGenerator, brewer := false) -> Dictionary:
	var sa = slots[a]
	var sb = slots[b]
	if sa == null or sb == null or a == b and sa["n"] < 2:
		return {}
	var r := Recipes.lookup(sa["id"], sb["id"])
	if r.is_empty():
		return {}
	var out: String = r["out"]
	var n: int = r["n"]
	# Alquimista: 50 % de hacer la poción grande con los ingredientes básicos.
	if brewer and out in ["pocion_vida", "pocion_mana", "pocion_misteriosa"] and rng.randf() < 0.5:
		out += "_g"
	# Consume ingredientes.
	var tool_id: String = r["tool"]
	if tool_id != "":
		var ti := a if sa["id"] == tool_id else b
		var oi := b if ti == a else a
		_consume(oi, 1)
		wear(ti)
	elif a == b:
		_consume(a, 2)
	else:
		_consume(a, 1)
		_consume(b, 1)
	var result := make(out, n)
	if Recipes.has_quality(out):
		var q := Recipes.roll_quality(luck, rng)
		if q > 0:
			result["q"] = q
			result["bonus"] = Recipes.quality_bonus(q, rng)
	var left := add(result)
	changed.emit()
	return {"item": result, "overflow": left}


func _consume(i: int, n: int) -> void:
	var s = slots[i]
	if s == null:
		return
	s["n"] -= n
	if s["n"] <= 0:
		slots[i] = null


## Crea un objeto de artesano si hay materiales.
func craft_npc(npc: String, out: String, luck: float, rng: RandomNumberGenerator) -> Dictionary:
	var r := Recipes.npc_recipe(npc, out)
	if r.is_empty():
		return {}
	for id in r["needs"]:
		if count(id) < r["needs"][id]:
			return {}
	for id in r["needs"]:
		remove(id, r["needs"][id])
	var result := make(out, 1)
	if Recipes.has_quality(out):
		var q := Recipes.roll_quality(luck, rng)
		if q > 0:
			result["q"] = q
			result["bonus"] = Recipes.quality_bonus(q, rng)
	add(result)
	return result


func can_npc(npc: String, out: String) -> bool:
	var r := Recipes.npc_recipe(npc, out)
	if r.is_empty():
		return false
	for id in r["needs"]:
		if count(id) < r["needs"][id]:
			return false
	return true


## Equipa el objeto de la ranura i en su hueco (intercambia con lo que hubiera).
func equip_from(i: int) -> bool:
	var s = slots[i]
	if s == null:
		return false
	var slot: String = ItemDB.get_item(s["id"]).get("slot", "")
	if slot == "":
		return false
	if slot == "anillo":
		slot = "anillo1" if equip["anillo1"] == null or equip["anillo2"] != null else "anillo2"
	var prev = equip[slot]
	equip[slot] = s
	slots[i] = prev
	changed.emit()
	return true


func unequip(slot: String) -> bool:
	if equip[slot] == null:
		return false
	for i in SIZE:
		if slots[i] == null:
			slots[i] = equip[slot]
			equip[slot] = null
			changed.emit()
			return true
	return false


## Suma de estadísticas del equipo llevado + objeto en la mano.
func gear_stats() -> Dictionary:
	var t := {"hp": 0, "atk": 0, "dex": 0, "mag": 0}
	var worn := []
	for s in EQUIP_SLOTS:
		if equip[s] != null:
			worn.append(equip[s])
	var h = held()
	if h != null and ItemDB.get_item(h["id"]).get("slot", "") == "":
		worn.append(h)
	for s in worn:
		var it := ItemDB.get_item(s["id"])
		for k in t:
			t[k] += int(it.get(k, 0))
		if s.has("bonus"):
			for k in s["bonus"]:
				t[k] += int(s["bonus"][k])
	return t


## Mejor flecha disponible (id) o "".
func best_arrow() -> String:
	var best := ""
	var bb := -1
	for s in slots:
		if s != null:
			var it := ItemDB.get_item(s["id"])
			if it.has("arrow_bonus") and int(it["arrow_bonus"]) > bb:
				bb = it["arrow_bonus"]
				best = s["id"]
	return best


func to_data() -> Dictionary:
	return {"slots": slots.duplicate(true), "equip": equip.duplicate(true), "hand": hand}


func from_data(d: Dictionary) -> void:
	slots = d["slots"].duplicate(true)
	equip = d["equip"].duplicate(true)
	hand = d.get("hand", 0)
	changed.emit()
