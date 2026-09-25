class_name Combat
extends RefCounted
## Fórmulas de daño. Puras: el RNG se inyecta.

## Daño cuerpo a cuerpo con el objeto en la mano (o puños). ctx: {furia, arcana_bonus}
static func melee(hero: HeroModel, rng: RandomNumberGenerator, ctx: Dictionary = {}) -> Dictionary:
	var dmg := float(hero.stat("atk"))
	if ctx.get("furia", false):
		dmg *= 2.0
	dmg += float(ctx.get("arcana_bonus", 0))
	return _finish(dmg, hero.crit_chance(), rng)


## Flecha: Destreza + bonificación de la flecha.
static func arrow(hero: HeroModel, arrow_bonus: int, rng: RandomNumberGenerator, mult := 1.0) -> Dictionary:
	var dmg := (float(hero.stat("dex")) + arrow_bonus) * mult
	return _finish(dmg, hero.crit_chance(), rng)


## Hechizo: Magia × factor del hechizo.
static func spell(hero: HeroModel, spell_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var factor := {"bola_fuego": 1.0, "rayo": 1.3, "escarcha": 0.5, "meteoro": 0.8, "zombi": 0.6, "esqueleto": 0.6}
	var dmg := float(hero.stat("mag")) * float(factor.get(spell_id, 1.0))
	return _finish(dmg, hero.crit_chance(), rng)


static func _finish(dmg: float, crit_chance: float, rng: RandomNumberGenerator) -> Dictionary:
	var crit := rng.randf() < crit_chance
	if crit:
		dmg *= 2.0
	return {"amount": max(1, int(round(dmg))), "crit": crit}


## Daño que recibe un enemigo con armadura.
static func vs_armor(amount: int, armor: int) -> int:
	return max(1, amount - armor)


## Multiplicadores por distrito y modo.
static func enemy_hp_mult(district: int, madman: bool) -> float:
	return (1.0 + (district - 1) * 0.12) * (1.5 if madman else 1.0)


static func enemy_dmg_mult(district: int, madman: bool) -> float:
	return (1.0 + (district - 1) * 0.04) * (1.5 if madman else 1.0)
