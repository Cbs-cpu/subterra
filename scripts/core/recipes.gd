class_name Recipes
extends RefCounted
## Crafteo combinando dos objetos (pares NO ordenados) y recetas de artesanos del pueblo.

## Clave "a|b" (ordenada) -> {out, n, tool}. Si tool == true, el segundo ingrediente es una
## herramienta que pierde 1 de durabilidad en vez de consumirse.
static var _pairs := {}
## Artesanos: npc -> lista de {out, needs: {id: n}}
static var _npc := {}

const QUALITY_BASE := [0.80, 0.14, 0.05, 0.01]
const QUALITY_NAMES := ["normal", "azul", "amarilla", "morada"]


static func key(a: String, b: String) -> String:
	return a + "|" + b if a <= b else b + "|" + a


static func _p(a: String, b: String, out: String, n: int = 1, tool := "") -> void:
	_pairs[key(a, b)] = {"out": out, "n": n, "tool": tool}


static func pairs() -> Dictionary:
	if _pairs.is_empty():
		_build()
	return _pairs


static func npc_recipes(npc: String) -> Array:
	if _pairs.is_empty():
		_build()
	return _npc.get(npc, [])


static func _build() -> void:
	_p("madera", "madera", "tablon")
	_p("palo", "tablon", "empunadura")
	_p("palo", "palo", "mango_hacha")
	_p("palo", "mango_hacha", "mango_pico")
	_p("mango_pico", "palo", "arco_sin")
	_p("tablon", "tablon", "hoja_madera")
	_p("piedra", "piedra", "lingote_piedra")
	_p("hueso", "hueso", "lingote_hueso")
	for mat in ItemDB.MATS:
		var m: String = mat["id"]
		if m != "madera":
			_p("lingote_" + m, "lingote_" + m, "hoja_" + m)
		_p("hoja_" + m, "hoja_" + m, "granhoja_" + m)
		_p("hoja_" + m, "mango_hacha", "hacha_" + m)
		_p("hoja_" + m, "mango_pico", "pico_" + m)
		_p("hoja_" + m, "empunadura", "espada_" + m)
		_p("granhoja_" + m, "mango_hacha", "granhacha_" + m)
	for m in ItemDB.ARROW_BONUS:
		_p("lingote_" + m, "palo", "flecha_" + m, 5)
	_p("telarana", "telarana", "cuerda")
	_p("cuerda", "cuerda", "red")
	_p("red", "palo", "red_bichos")
	_p("arco_sin", "cuerda", "arco")
	_p("piel", "piel", "tela_refinada")
	_p("pellejo", "pellejo", "cuero_refinado")
	_p("cuero_refinado", "tablon", "tambor")
	_p("tambor", "bicho_fuego", "tambor_fuerza")
	_p("tambor", "bicho_hielo", "tambor_sabiduria")
	_p("tambor", "bicho_rayo", "tambor_destreza")
	for e in ItemDB.ELEMENTS:
		_p("bicho_" + e, "bicho_" + e, "gema_" + e)
		_p("gema_" + e, "palo", "baston_" + e)
		_p("mandoble", "gema_" + e, "mandoble_" + e)
	_p("hierba", "hierba", "pocion_vida")
	_p("seta", "seta", "pocion_mana")
	_p("hierba", "seta", "pocion_misteriosa")
	_p("seta", "raiz", "pocion_misteriosa")
	_p("hierba", "raiz", "pocion_misteriosa")
	_p("pocion_vida", "pocion_vida", "pocion_vida_g")
	_p("pocion_mana", "pocion_mana", "pocion_mana_g")
	_p("pocion_misteriosa", "pocion_misteriosa", "pocion_misteriosa_g")
	_p("carbon", "carbon", "encendedor")
	_p("carbon", "piedra", "encendedor")
	_p("carne_cruda", "encendedor", "carne_asada", 1, "encendedor")
	_p("pollo_crudo", "encendedor", "pollo_asado", 1, "encendedor")
	_p("fragmento_ceniza", "fragmento_ceniza", "esquirla_ceniza", 2)

	# Artesanos del pueblo.
	var herrero := []
	for m in ItemDB.ORE_MATS:
		herrero.append({"out": "lingote_" + m, "needs": {"mena_" + m: 2}})
	for m in ItemDB.BAR_MATS:
		for piece in ["casco", "armadura", "escudo"]:
			herrero.append({"out": piece + "_" + m, "needs": {"lingote_" + m: 3}})
	_npc["herrero"] = herrero
	var sastra := []
	var peletero := []
	for m in ItemDB.BAR_MATS:
		sastra.append({"out": "tela_" + m, "needs": {"lingote_" + m: 1, "tela_refinada": 1}})
		peletero.append({"out": "cuero_" + m, "needs": {"lingote_" + m: 1, "cuero_refinado": 1}})
		for piece in ["capucha", "tunica"]:
			sastra.append({"out": piece + "_" + m, "needs": {"tela_" + m: 3}})
		for piece in ["gorro", "capa"]:
			peletero.append({"out": piece + "_" + m, "needs": {"cuero_" + m: 3}})
	_npc["sastra"] = sastra
	_npc["peletero"] = peletero


## Resultado de combinar a y b, o {} si no hay receta.
static func lookup(a: String, b: String) -> Dictionary:
	return pairs().get(key(a, b), {})


## ¿El objeto resultante puede salir con calidad superior?
static func has_quality(id: String) -> bool:
	var it := ItemDB.get_item(id)
	var c: String = it.get("cat", "")
	return c == "arma" or c == "equipo" or (c == "herramienta" and it.get("tool", "") in ["hacha", "pico"])


## Tira la calidad (0..3). luck en puntos (Artesano = +10).
static func roll_quality(luck: float, rng: RandomNumberGenerator) -> int:
	var p := QUALITY_BASE.duplicate()
	var shift := luck / 100.0
	p[0] = max(0.0, p[0] - shift)
	p[1] += shift * 0.6
	p[2] += shift * 0.3
	p[3] += shift * 0.1
	var r := rng.randf()
	var acc := 0.0
	for q in 4:
		acc += p[q]
		if r < acc:
			return q
	return 3


## Bonificaciones por calidad: q puntos repartidos al azar entre hp/atk/dex/mag (×2 en morada).
static func quality_bonus(q: int, rng: RandomNumberGenerator) -> Dictionary:
	var b := {}
	var pts := q * (2 if q == 3 else 1)
	var stats := ["hp", "atk", "dex", "mag"]
	for i in pts:
		var s: String = stats[rng.randi() % 4]
		b[s] = b.get(s, 0) + 1
	return b


## Busca una receta de artesano por su resultado.
static func npc_recipe(npc: String, out: String) -> Dictionary:
	for r in npc_recipes(npc):
		if r["out"] == out:
			return r
	return {}
