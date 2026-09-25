class_name ItemDB
extends RefCounted
## Catálogo de objetos. Se genera a partir de materiales, piezas y tablas para no escribir
## cientos de entradas a mano. Cada objeto es un Dictionary con campos opcionales:
## id, name, cat, stack, dur, atk, dex, mag, hp, crit, tool, tier, wclass, slot, icon, pal,
## sell, buy, food{hunger, heal}, potion{hp, mp, kind}, spell, arrow_bonus, speed, desc.

const MATS := [
	{"id": "madera", "name": "madera", "tier": 0, "pal": "madera", "dur": 50, "atk": 2},
	{"id": "piedra", "name": "piedra", "tier": 1, "pal": "piedra", "dur": 80, "atk": 4},
	{"id": "hueso", "name": "hueso", "tier": 1, "pal": "hueso", "dur": 110, "atk": 5},
	{"id": "hierro", "name": "hierro", "tier": 2, "pal": "hierro", "dur": 160, "atk": 8},
	{"id": "oro", "name": "oro", "tier": 3, "pal": "oro", "dur": 220, "atk": 12},
	{"id": "diamante", "name": "diamante", "tier": 4, "pal": "diamante", "dur": 320, "atk": 18},
]
## Nombre del set de equipo por material (tela, cuero y adjetivo).
const SET_NAMES := {"hueso": "tribal", "piedra": "tosco", "hierro": "elegante", "oro": "real", "diamante": "luminoso"}
## Bonificaciones de equipo (del original): [vida_escudo, vida_pieza, stat_pieza].
const EQUIP_STATS := {
	"hueso": [1, 1, 2], "piedra": [2, 1, 2], "hierro": [2, 2, 4], "oro": [3, 3, 6], "diamante": [6, 6, 10],
}
const EQUIP_STATS_CLOTH := {"diamante": [4, 9]}
const ARROW_BONUS := {"piedra": 2, "hueso": 3, "hierro": 5, "oro": 8, "diamante": 12}
const BAR_MATS := ["piedra", "hueso", "hierro", "oro", "diamante"]
const ORE_MATS := ["hierro", "oro", "diamante"]
const ELEMENTS := ["fuego", "hielo", "rayo"]
const ELEMENT_NAMES := {"fuego": "fuego", "hielo": "hielo", "rayo": "rayo"}

static var _items := {}


static func all() -> Dictionary:
	if _items.is_empty():
		_build()
	return _items


static func get_item(id: String) -> Dictionary:
	return all().get(id, {})


static func has(id: String) -> bool:
	return all().has(id)


static func stackable(id: String) -> bool:
	return int(get_item(id).get("stack", 99)) > 1


static func _add(d: Dictionary) -> void:
	var it := {"stack": 99, "cat": "material", "sell": 2, "buy": 0, "pal": "neutro"}
	it.merge(d, true)
	if int(it.get("dur", 0)) > 0 or it.has("slot"):
		it["stack"] = 1
	if int(it["buy"]) == 0:
		it["buy"] = max(10, int(it["sell"]) * 6)
	_items[it["id"]] = it


static func _build() -> void:
	# --- Materiales básicos ------------------------------------------------
	_add({"id": "madera", "name": "Madera", "icon": "madera", "pal": "madera", "sell": 1})
	_add({"id": "palo", "name": "Palo", "icon": "palo", "pal": "madera", "sell": 1})
	_add({"id": "tablon", "name": "Tablón", "icon": "tablon", "pal": "madera", "sell": 1})
	_add({"id": "piedra", "name": "Piedra", "icon": "piedra", "pal": "piedra"})
	_add({"id": "hueso", "name": "Hueso", "icon": "hueso", "pal": "hueso"})
	_add({"id": "carbon", "name": "Carbón", "icon": "piedra", "pal": "carbon", "sell": 3})
	for m in ORE_MATS:
		_add({"id": "mena_" + m, "name": "Mena de " + m, "icon": "mena", "pal": m, "sell": 4 + ORE_MATS.find(m) * 4})
	_add({"id": "fragmento_ceniza", "name": "Fragmento de ceniza", "icon": "gema", "pal": "ceniza", "sell": 20})
	_add({"id": "hierba", "name": "Hierba", "icon": "hierba", "pal": "hierba"})
	_add({"id": "seta", "name": "Seta", "icon": "seta", "pal": "seta"})
	_add({"id": "raiz", "name": "Raíz", "icon": "raiz", "pal": "madera"})
	_add({"id": "telarana", "name": "Telaraña", "icon": "telarana", "pal": "tela"})
	_add({"id": "piel", "name": "Piel de monstruo", "icon": "piel", "pal": "piel", "sell": 4})
	_add({"id": "pellejo", "name": "Pellejo de monstruo", "icon": "piel", "pal": "cuero", "sell": 4})
	_add({"id": "cuerda", "name": "Cuerda", "icon": "cuerda", "pal": "tela", "sell": 3})
	_add({"id": "red", "name": "Red", "icon": "red", "pal": "tela", "sell": 4})
	_add({"id": "tela_refinada", "name": "Tela refinada", "icon": "tela", "pal": "piel", "sell": 6})
	_add({"id": "cuero_refinado", "name": "Cuero refinado", "icon": "tela", "pal": "cuero", "sell": 6})
	_add({"id": "llave", "name": "Llave dorada", "icon": "llave", "pal": "oro", "sell": 10, "buy": 60})
	for e in ELEMENTS:
		_add({"id": "bicho_" + e, "name": "Bicho de " + e, "icon": "bicho", "pal": e, "sell": 5})
		_add({"id": "gema_" + e, "name": "Gema de " + e, "icon": "gema", "pal": e, "sell": 15})

	# --- Piezas ------------------------------------------------------------
	_add({"id": "empunadura", "name": "Empuñadura", "icon": "empunadura", "pal": "madera"})
	_add({"id": "mango_hacha", "name": "Mango de hacha", "icon": "mango", "pal": "madera"})
	_add({"id": "mango_pico", "name": "Mango de pico", "icon": "mango", "pal": "madera"})
	_add({"id": "arco_sin", "name": "Arco sin tensar", "icon": "arco", "pal": "madera", "sell": 4})
	_add({"id": "tambor", "name": "Tambor tribal", "icon": "tambor", "pal": "cuero", "sell": 8})

	# --- Por material ------------------------------------------------------
	for mat in MATS:
		var m: String = mat["id"]
		var t: int = mat["tier"]
		var base_atk: int = mat["atk"]
		var dur: int = mat["dur"]
		var price := 6 + t * 12
		var nm: String = mat["name"]
		if m != "madera":
			var bar_name := "Lingote de " + nm if m in ORE_MATS else nm.capitalize() + " refinado" if m == "hueso" else "Piedra refinada"
			_add({"id": "lingote_" + m, "name": bar_name, "icon": "lingote", "pal": m, "sell": price / 2 + 2})
		_add({"id": "hoja_" + m, "name": "Hoja de " + nm, "icon": "hoja", "pal": m, "sell": price})
		_add({"id": "granhoja_" + m, "name": "Gran hoja de " + nm, "icon": "granhoja", "pal": m, "sell": price * 2})
		_add({"id": "hacha_" + m, "name": "Hacha de " + nm, "cat": "herramienta", "icon": "hacha", "pal": m,
			"tool": "hacha", "tier": t, "wclass": "hacha", "atk": max(1, base_atk / 2), "dur": dur,
			"sell": price + 4, "buy": 60 + t * 60, "speed": 0.4})
		_add({"id": "pico_" + m, "name": "Pico de " + nm, "cat": "herramienta", "icon": "pico", "pal": m,
			"tool": "pico", "tier": t, "wclass": "pico", "atk": max(1, base_atk / 2), "dur": dur,
			"sell": price + 4, "buy": 90 + t * 70, "speed": 0.4})
		_add({"id": "espada_" + m, "name": "Espada de " + nm, "cat": "arma", "icon": "espada", "pal": m,
			"wclass": "espada", "atk": base_atk, "dur": dur, "sell": price + 6, "buy": 70 + t * 70, "speed": 0.32})
		_add({"id": "granhacha_" + m, "name": ("Garrote" if m == "madera" else "Gran hacha de " + nm), "cat": "arma",
			"icon": "granhacha", "pal": m, "wclass": "granhacha", "atk": int(base_atk * 1.9), "dur": dur,
			"sell": price * 2 + 6, "buy": 120 + t * 90, "speed": 0.62})
	for m in ARROW_BONUS:
		_add({"id": "flecha_" + m, "name": "Flecha de " + m, "cat": "municion", "icon": "flecha", "pal": m,
			"arrow_bonus": ARROW_BONUS[m], "sell": 1, "buy": 4 + ARROW_BONUS[m]})
	for m in ORE_MATS:
		pass

	# --- Equipo (herrero, sastra, peletero) --------------------------------
	for m in BAR_MATS:
		var s: Array = EQUIP_STATS[m]
		var cloth: Array = EQUIP_STATS_CLOTH.get(m, [s[1], s[2]])
		var sn: String = SET_NAMES[m]
		var t: int = ["piedra", "hueso", "hierro", "oro", "diamante"].find(m) + 1
		var price := 10 + t * 15
		_add({"id": "tela_" + m, "name": "Tela " + sn, "icon": "tela", "pal": m, "sell": price / 3})
		_add({"id": "cuero_" + m, "name": "Cuero " + sn, "icon": "tela", "pal": "cuero_" + m, "sell": price / 3})
		_add({"id": "escudo_" + m, "name": "Escudo de " + m, "cat": "equipo", "slot": "escudo", "icon": "escudo",
			"pal": m, "hp": s[0], "sell": price})
		_add({"id": "casco_" + m, "name": "Casco de " + m, "cat": "equipo", "slot": "cabeza", "icon": "casco",
			"pal": m, "hp": s[1], "atk": s[2], "sell": price})
		_add({"id": "armadura_" + m, "name": "Armadura de " + m, "cat": "equipo", "slot": "cuerpo", "icon": "armadura",
			"pal": m, "hp": s[1], "atk": s[2], "sell": price})
		_add({"id": "capucha_" + m, "name": "Capucha " + sn, "cat": "equipo", "slot": "cabeza", "icon": "capucha",
			"pal": m, "hp": cloth[0], "mag": cloth[1], "sell": price})
		_add({"id": "tunica_" + m, "name": "Túnica " + sn, "cat": "equipo", "slot": "cuerpo", "icon": "tunica",
			"pal": m, "hp": cloth[0], "mag": cloth[1], "sell": price})
		_add({"id": "gorro_" + m, "name": "Gorro " + sn, "cat": "equipo", "slot": "cabeza", "icon": "gorro",
			"pal": "cuero_" + m, "hp": cloth[0], "dex": cloth[1], "sell": price})
		_add({"id": "capa_" + m, "name": "Capa " + sn, "cat": "equipo", "slot": "cuerpo", "icon": "capa",
			"pal": "cuero_" + m, "hp": cloth[0], "dex": cloth[1], "sell": price})

	# --- Arcos, bastones y armas especiales --------------------------------
	_add({"id": "arco", "name": "Arco de madera", "cat": "arma", "icon": "arco", "pal": "madera", "wclass": "arco",
		"dur": 0, "stack": 1, "sell": 10, "buy": 80, "speed": 0.45})
	_add({"id": "arco_fuego", "name": "Arco ígneo", "cat": "arma", "icon": "arco", "pal": "fuego", "wclass": "arco",
		"dex": 6, "stack": 1, "elem": "fuego", "sell": 60, "speed": 0.4})
	_add({"id": "arco_cristal", "name": "Arco de cristal", "cat": "arma", "icon": "arco", "pal": "diamante",
		"wclass": "arco", "dex": 10, "stack": 1, "sell": 80, "speed": 0.35})
	_add({"id": "ballesta_laser", "name": "Ballesta de luz", "cat": "arma", "icon": "arco", "pal": "laser",
		"wclass": "arco", "dex": 20, "stack": 1, "no_ammo": true, "sell": 150, "speed": 0.3})
	_add({"id": "baston_fuego", "name": "Bastón de bola de fuego", "cat": "arma", "icon": "baston", "pal": "fuego",
		"wclass": "baston", "spell": "bola_fuego", "mana": 1, "stack": 1, "sell": 30, "speed": 0.45})
	_add({"id": "baston_hielo", "name": "Bastón de escarcha", "cat": "arma", "icon": "baston", "pal": "hielo",
		"wclass": "baston", "spell": "escarcha", "mana": 2, "stack": 1, "sell": 30, "speed": 0.6})
	_add({"id": "baston_rayo", "name": "Bastón de rayo", "cat": "arma", "icon": "baston", "pal": "rayo",
		"wclass": "baston", "spell": "rayo", "mana": 2, "stack": 1, "sell": 30, "speed": 0.55})
	_add({"id": "baston_zombi", "name": "Bastón de invocar muerto", "cat": "arma", "icon": "baston", "pal": "ceniza",
		"wclass": "baston", "spell": "zombi", "mana": 3, "stack": 1, "sell": 40, "speed": 0.8})
	_add({"id": "mandoble", "name": "Mandoble", "cat": "arma", "icon": "granhacha", "pal": "hierro",
		"wclass": "granhacha", "atk": 25, "dur": 250, "sell": 60, "speed": 0.6})
	for e in ELEMENTS:
		_add({"id": "mandoble_" + e, "name": "Mandoble de " + e, "cat": "arma", "icon": "granhacha", "pal": e,
			"wclass": "granhacha", "atk": 35, "dur": 300, "elem": e, "sell": 120, "speed": 0.55})
	_add({"id": "katana_esmeralda", "name": "Katana esmeralda", "cat": "arma", "icon": "espada", "pal": "esmeralda",
		"wclass": "espada", "atk": 14, "dur": 300, "sell": 60, "speed": 0.22})
	_add({"id": "espada_gelatina", "name": "Espada de gelatina", "cat": "arma", "icon": "espada", "pal": "gelatina",
		"wclass": "espada", "atk": 100, "hp": -3, "dur": 60, "sell": 90, "speed": 0.32})
	_add({"id": "espada_laser", "name": "Espada de luz", "cat": "arma", "icon": "espada", "pal": "laser",
		"wclass": "espada", "atk": 75, "dur": 0, "stack": 1, "sell": 200, "speed": 0.18, "reach": 0.7})
	_add({"id": "espada_obsidiana", "name": "Espada de obsidiana", "cat": "arma", "icon": "espada", "pal": "obsidiana",
		"wclass": "espada", "atk": 30, "dur": 400, "sell": 90, "speed": 0.3})
	_add({"id": "portaluz", "name": "Portaluz", "cat": "arma", "icon": "espada", "pal": "oro",
		"wclass": "espada", "atk": 45, "mag": 5, "dur": 500, "sell": 140, "speed": 0.28})
	_add({"id": "hoja_ceniza", "name": "Hoja de la Ceniza", "cat": "arma", "icon": "espada", "pal": "ceniza",
		"wclass": "espada", "atk": 60, "dur": 500, "sell": 160, "speed": 0.28})
	_add({"id": "mazo_sermon", "name": "Mazo sermoneador", "cat": "arma", "icon": "granhacha", "pal": "obsidiana",
		"wclass": "granhacha", "atk": 20, "mag": 5, "dur": 300, "sell": 80, "speed": 0.55})
	_add({"id": "esquirla_ceniza", "name": "Esquirla de ceniza", "cat": "arma", "icon": "esquirla", "pal": "ceniza",
		"wclass": "lanzable", "throw_damage": 150, "sell": 30, "speed": 0.5})
	_add({"id": "escudo_escama", "name": "Escama de Karvoth", "cat": "equipo", "slot": "escudo", "icon": "escudo",
		"pal": "fuego", "hp": 8, "sell": 120})
	_add({"id": "escudo_ceniza", "name": "Escudo de ceniza", "cat": "equipo", "slot": "escudo", "icon": "escudo",
		"pal": "ceniza", "hp": 10, "sell": 150})
	_add({"id": "guarda_paladin", "name": "Guarda del paladín", "cat": "equipo", "slot": "escudo", "icon": "escudo",
		"pal": "diamante", "hp": 12, "sell": 160})

	# --- Anillos ---------------------------------------------------------------
	var rings := [
		["anillo_poder", "Anillo de poder", {"atk": 3}, "fuego"],
		["anillo_sabiduria", "Anillo de sabiduría", {"mag": 3}, "hielo"],
		["anillo_naturaleza", "Anillo de naturaleza", {"dex": 3}, "hierba"],
		["anillo_vida", "Anillo de vida", {"hp": 3}, "gelatina"],
		["anillo_furia", "Anillo de furia", {"atk": 6, "hp": -2}, "ceniza"],
		["anillo_locura", "Anillo de locura", {"mag": 6, "hp": -2}, "laser"],
		["anillo_arquero", "Anillo del arquero", {"dex": 5}, "esmeralda"],
		["anillo_equilibrio", "Anillo de equilibrio", {"atk": 1, "dex": 1, "mag": 1, "hp": 1}, "oro"],
	]
	for r in rings:
		var d := {"id": r[0], "name": r[1], "cat": "equipo", "slot": "anillo", "icon": "anillo", "pal": r[3], "sell": 40}
		d.merge(r[2])
		_add(d)

	# --- Consumibles -------------------------------------------------------
	_add({"id": "pocion_vida", "name": "Poción de vida", "cat": "consumible", "icon": "pocion", "pal": "vida",
		"potion": {"hp": 2}, "sell": 6, "buy": 30})
	_add({"id": "pocion_vida_g", "name": "Poción grande de vida", "cat": "consumible", "icon": "pocion_g", "pal": "vida",
		"potion": {"hp": 5}, "sell": 14, "buy": 70})
	_add({"id": "pocion_mana", "name": "Poción de maná", "cat": "consumible", "icon": "pocion", "pal": "mana",
		"potion": {"mp": 3}, "sell": 6, "buy": 30})
	_add({"id": "pocion_mana_g", "name": "Poción grande de maná", "cat": "consumible", "icon": "pocion_g", "pal": "mana",
		"potion": {"mp": 7}, "sell": 14, "buy": 70})
	_add({"id": "pocion_misteriosa", "name": "Poción misteriosa", "cat": "consumible", "icon": "pocion", "pal": "misterio",
		"potion": {"kind": "misterio", "power": 1}, "sell": 5})
	_add({"id": "pocion_misteriosa_g", "name": "Poción misteriosa grande", "cat": "consumible", "icon": "pocion_g",
		"pal": "misterio", "potion": {"kind": "misterio", "power": 2}, "sell": 12})
	_add({"id": "vial_veneno", "name": "Vial de veneno", "cat": "arma", "icon": "pocion", "pal": "veneno",
		"wclass": "lanzable", "throw_damage": 25, "poison": true, "sell": 8, "speed": 0.5})
	_add({"id": "carne_cruda", "name": "Carne cruda", "cat": "consumible", "icon": "carne", "pal": "carne_cruda",
		"food": {"hunger": 2, "heal": 0.0}, "sell": 2})
	_add({"id": "pollo_crudo", "name": "Pollo crudo", "cat": "consumible", "icon": "pollo", "pal": "carne_cruda",
		"food": {"hunger": 2, "heal": 0.0}, "sell": 2})
	_add({"id": "carne_asada", "name": "Carne asada", "cat": "consumible", "icon": "carne", "pal": "carne_asada",
		"food": {"hunger": 4, "heal": 0.5}, "sell": 4, "buy": 20})
	_add({"id": "pollo_asado", "name": "Pollo asado", "cat": "consumible", "icon": "pollo", "pal": "carne_asada",
		"food": {"hunger": 4, "heal": 0.5}, "sell": 4, "buy": 20})
	_add({"id": "galleta", "name": "Galleta de viaje", "cat": "consumible", "icon": "tambor", "pal": "madera",
		"food": {"hunger": 8, "heal": 0.0}, "sell": 10, "buy": 60})
	_add({"id": "tambor_fuerza", "name": "Tambor de fuerza", "cat": "consumible", "icon": "tambor", "pal": "fuego",
		"buff": {"atk": 5, "time": 60.0}, "sell": 15})
	_add({"id": "tambor_sabiduria", "name": "Tambor de sabiduría", "cat": "consumible", "icon": "tambor", "pal": "hielo",
		"buff": {"mag": 5, "time": 60.0}, "sell": 15})
	_add({"id": "tambor_destreza", "name": "Tambor de destreza", "cat": "consumible", "icon": "tambor", "pal": "rayo",
		"buff": {"dex": 5, "time": 60.0}, "sell": 15})
	_add({"id": "gema_espiritual", "name": "Gema espiritual", "cat": "consumible", "icon": "gema", "pal": "espiritu",
		"summon": "ventolin", "sell": 100, "buy": 2000})

	# --- Herramientas especiales -----------------------------------------------
	_add({"id": "red_bichos", "name": "Red para bichos", "cat": "herramienta", "icon": "red_bichos", "pal": "tela",
		"tool": "red", "wclass": "red", "dur": 20, "sell": 8, "buy": 60, "speed": 0.35})
	_add({"id": "encendedor", "name": "Encendedor", "cat": "herramienta", "icon": "encendedor", "pal": "carbon",
		"tool": "encendedor", "wclass": "ninguna", "dur": 10, "sell": 6, "buy": 40})


static func is_weapon_like(id: String) -> bool:
	var w: String = get_item(id).get("wclass", "")
	return w != "" and w != "ninguna"


static func tint_name(q: int) -> String:
	return ["", "(azul)", "(amarilla)", "(morada)"][clampi(q, 0, 3)]
