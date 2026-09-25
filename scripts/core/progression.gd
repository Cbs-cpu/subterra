class_name Progression
extends RefCounted
## Desbloqueos permanentes. Se evalúan al terminar la partida con los contadores de la partida
## y las estadísticas globales (prefijo "g_").

static func check_cond(cond: Array, counters: Dictionary, global_stats: Dictionary) -> bool:
	for c in cond:
		var key: String = c[0]
		var op: String = c[1]
		var target = c[2]
		var v
		if key.begins_with("g_"):
			v = global_stats.get(key.substr(2), 0)
		else:
			v = counters.get(key, "" if typeof(target) == TYPE_STRING else 0)
		if typeof(target) == TYPE_STRING:
			v = str(v).to_lower()
		var ok := false
		match op:
			">=": ok = v >= target
			"<=": ok = v <= target
			">": ok = v > target
			"<": ok = v < target
			"==": ok = v == target
		if not ok:
			return false
	return true


## Devuelve [{kind, id, name}] desbloqueados ahora (no los que ya se tenían).
static func evaluate(counters: Dictionary, global_stats: Dictionary, owned: Dictionary, rng: RandomNumberGenerator) -> Array:
	var out := []
	for pair in [["race", Content.RACES], ["hat", Content.HATS], ["companion", Content.COMPANIONS]]:
		var kind: String = pair[0]
		for e in pair[1]:
			var u: Dictionary = e.get("unlock", {})
			if u.is_empty() or owned.get(kind, []).has(e["id"]):
				continue
			if check_cond(u["cond"], counters, global_stats) and rng.randf() < float(u["chance"]):
				out.append({"kind": kind, "id": e["id"], "name": e["name"]})
	return out


static func default_owned() -> Dictionary:
	return {"race": ["minero"], "hat": ["ninguno"], "companion": ["ninguno"]}
