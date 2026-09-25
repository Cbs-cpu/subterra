class_name InvOps
extends RefCounted
## Operaciones de inventario, tienda y pueblo expresadas como acciones (diccionarios).
## El anfitrión las aplica; en cooperativo los clientes solo las envían.

## Artículos de las tiendas según el distrito.
static func shop_stock(shop: String, district: int, rng: RandomNumberGenerator) -> Array:
	var tier := clampi(district / 4, 0, 4)
	var mats := ["madera", "piedra", "hierro", "oro", "diamante"]
	var out := []
	if shop == "herramientas":
		var m: String = mats[clampi(tier, 0, 4)]
		var m2: String = mats[clampi(tier + 1, 0, 4)]
		out = ["hacha_" + m, "pico_" + m, "pico_" + m2, "espada_" + m2, "arco", "red_bichos", "encendedor",
			"pocion_vida", "pocion_mana", "llave", "galleta", "gema_espiritual"]
	else:
		var bar: String = ["piedra", "hueso", "hierro", "oro", "diamante"][clampi(tier, 0, 4)]
		out = ["lingote_" + bar, "mena_hierro", "piel", "pellejo", "telarana", "cuerda", "hierba", "seta",
			"carbon", "flecha_" + ("piedra" if tier < 2 else bar), "carne_asada"]
		if tier >= 2:
			out.append("mena_oro")
		if tier >= 3:
			out.append("mena_diamante")
	return out


static func price(id: String) -> int:
	return int(ItemDB.get_item(id).get("buy", 20))


static func sell_price(stack: Dictionary, rng: RandomNumberGenerator) -> int:
	var id: String = stack["id"]
	var base := 1 if id in ["madera", "palo", "tablon"] else rng.randi_range(2, 4)
	var it := ItemDB.get_item(id)
	base = maxi(base, int(it.get("sell", 2)) / 2)
	return base * int(stack["n"]) + int(stack.get("q", 0)) * 10


## Aplica una acción al modelo del héroe. Devuelve un mensaje (vacío si nada que decir).
static func apply(run: Node, model: HeroModel, a: Dictionary, hero: Node) -> String:
	var inv := model.inv
	var rng: RandomNumberGenerator = run.rng
	match a["op"]:
		"hand":
			inv.hand = clampi(int(a["i"]), 0, Inventory.HOTBAR - 1)
		"move":
			inv.move(int(a["a"]), int(a["b"]))
		"split":
			inv.split(int(a["a"]), int(a["b"]))
		"one":
			inv.place_one(int(a["a"]), int(a["b"]))
		"craft":
			var sa = inv.slots[int(a["a"])]
			var sb = inv.slots[int(a["b"])]
			if sa == null or sb == null:
				return ""
			var r := inv.craft(int(a["a"]), int(a["b"]), model.luck(), rng, model.fx().has("brewer"))
			if r.is_empty():
				return "Eso no se puede combinar"
			run.on_craft(model, r["item"]["id"])
			Game.learn_recipe(sa["id"], sb["id"])
			Sfx.play("craftear")
			var q: int = r["item"].get("q", 0)
			return "Creado: " + ItemDB.get_item(r["item"]["id"])["name"] + (" (" + Recipes.QUALITY_NAMES[q] + ")" if q > 0 else "")
		"equip":
			if not inv.equip_from(int(a["i"])):
				return "No se puede equipar"
			Sfx.play("equipar")
		"unequip":
			inv.unequip(a["slot"])
		"drop":
			var s = inv.drop_slot(int(a["i"]))
			if s != null and hero != null:
				hero.world.drop_item(s, hero.center() + Vector2(hero.facing * 12, -6), Vector2(hero.facing * 90, -120))
		"buy":
			var p := price(a["id"])
			if model.coins < p:
				return "No tienes monedas suficientes"
			model.coins -= p
			inv.add(Inventory.make(a["id"], 1))
			Sfx.play("comprar")
			return "Comprado: " + ItemDB.get_item(a["id"])["name"]
		"sell":
			var st = inv.slots[int(a["i"])]
			if st == null:
				return ""
			var g := sell_price(st, rng)
			inv.drop_slot(int(a["i"]))
			model.coins += g
			Sfx.play("moneda")
			return "Vendido por %d monedas" % g
		"npc_craft":
			var res := inv.craft_npc(a["npc"], a["out"], model.luck(), rng)
			if res.is_empty():
				return "Te faltan materiales"
			run.on_craft(model, a["out"])
			Sfx.play("yunque")
			return "Fabricado: " + ItemDB.get_item(a["out"])["name"]
		"altar":
			if model.coins < Content.ALTAR_PRICE:
				return "Hacen falta %d monedas" % Content.ALTAR_PRICE
			model.coins -= Content.ALTAR_PRICE
			var al := Content.find(Content.ALTARS, a["id"])
			var good := rng.randf() < 0.5
			var fx: Dictionary = al["good"] if good else al["bad"]
			for k in fx:
				match k:
					"atk", "dex", "mag":
						model.extra[k] += int(fx[k])
					"max_hp":
						model.extra["hp"] += int(fx[k])
						model.hp = clampi(model.hp + maxi(0, int(fx[k])), 1, model.max_hp())
					"hp":
						model.hp = maxi(1, model.hp + int(fx[k]))
					"heal_full":
						model.hp = model.max_hp()
			Sfx.play("altar_bien" if good else "altar_mal")
			return al["good_text"] if good else al["bad_text"]
		"skill":
			model.learn_skill(a["id"])
			Sfx.play("habilidad")
			return "Nueva habilidad: " + Content.find(Content.SKILLS, a["id"])["name"]
	return ""
