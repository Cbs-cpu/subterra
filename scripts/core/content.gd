class_name Content
extends RefCounted
## Todo el contenido del juego como datos. Nombres y textos propios; la mecánica equivale a la
## del juego original (ver docs/SPEC.md).

# --- Razas -----------------------------------------------------------------
## look: parámetros del generador de personajes (piel, pelo, ropa, rasgo de cabeza).
const RACES := [
	{"id": "minero", "name": "Minero", "stats": {"hp": 1}, "items": ["hacha_madera"], "random_items": 2,
		"desc": "Gente sencilla de Hondura que cava, cultiva y fabrica. Sueñan con volver a ver el sol.",
		"unlock": {}, "look": {"skin": "piel_clara", "hair": "pelo_castano", "cloth": "ropa_marron", "head": "normal"}},
	{"id": "linajudo", "name": "Linajudo", "stats": {"hp": 1, "mag": 1}, "items": ["hacha_piedra"],
		"desc": "Descendientes de reyes de la Superficie. Aún conservan su influencia... y su nariz alta.",
		"unlock": {"cond": [["kills", ">=", 15]], "chance": 0.2, "text": "20 % al matar 15 enemigos en una partida"},
		"look": {"skin": "piel_clara", "hair": "pelo_rubio", "cloth": "ropa_morada", "head": "corona"}},
	{"id": "ciclope", "name": "Cíclope", "stats": {"hp": -1, "atk": 2}, "items": ["espada_hueso", "pico_hueso"],
		"desc": "Brutos gigantescos expulsados de sus montañas. Poca cabeza, mucho brazo.",
		"unlock": {"cond": [["ores", ">=", 20]], "chance": 0.2, "text": "20 % al minar 20 menas en una partida"},
		"look": {"skin": "piel_verde", "hair": "pelo_negro", "cloth": "ropa_piel", "head": "ciclope"}},
	{"id": "elfo_roca", "name": "Elfo de roca", "stats": {"hp": -1, "dex": 4}, "items": ["hacha_madera", "arco", "flecha_piedra"], "random_items": 1,
		"desc": "Pueblo ágil y pacífico, letal con arcos. Buscan unir a todas las razas contra la Ceniza.",
		"unlock": {"cond": [["skills", ">=", 1]], "chance": 0.2, "text": "20 % al conseguir tu primera habilidad"},
		"look": {"skin": "piel_gris", "hair": "pelo_blanco", "cloth": "ropa_verde", "head": "orejas"}},
	{"id": "veterano", "name": "Veterano", "stats": {"atk": 1}, "items": ["hacha_madera", "granhacha_piedra"], "random_items": 1,
		"desc": "Lo que queda de la Gran Guerra. Criminales, muchos; soldados, todos.",
		"unlock": {"cond": [["skills", ">=", 2]], "chance": 0.2, "text": "20 % al conseguir tu segunda habilidad"},
		"look": {"skin": "piel_morena", "hair": "pelo_gris", "cloth": "ropa_roja", "head": "cicatriz"}},
	{"id": "antiguo", "name": "Antiguo", "stats": {"hp": -1, "mag": 4}, "items": ["hacha_madera", "baston_rayo"],
		"desc": "Una raza anterior a esta era de caos. Vivían recluidos en los yermos helados.",
		"unlock": {"cond": [["won", ">=", 1]], "chance": 0.2, "text": "20 % al ganar una partida"},
		"look": {"skin": "piel_azul", "hair": "pelo_blanco", "cloth": "ropa_azul", "head": "runas"}},
	{"id": "alado", "name": "Alado", "stats": {"dex": 1}, "items": ["hacha_madera", "pocion_vida_g", "pocion_mana_g"],
		"desc": "Pueblo pájaro de mercaderes. Llevan mercancías por los pasadizos más peligrosos.",
		"unlock": {"cond": [["won", ">=", 1], ["time", "<", 3600]], "chance": 1.0, "text": "Ganar en menos de una hora"},
		"look": {"skin": "plumas", "hair": "plumas", "cloth": "ropa_amarilla", "head": "pico"}},
	{"id": "terrano", "name": "Terrano", "stats": {"atk": 1, "dex": 1, "mag": 1}, "items": ["hacha_madera", "armadura_hueso"], "random_items": 1,
		"desc": "Nacidos en lo más hondo. Nadie sabe gran cosa de ellos, ni ellos mismos.",
		"unlock": {"cond": [["district", ">=", 10]], "chance": 0.2, "text": "20 % al llegar al distrito 10"},
		"look": {"skin": "piel_roca", "hair": "pelo_musgo", "cloth": "ropa_marron", "head": "normal"}},
	{"id": "porcino", "name": "Porcino", "stats": {"hp": -1, "atk": -1, "dex": -1, "mag": -1}, "items": ["carne_cruda", "carne_cruda", "carne_cruda"],
		"desc": "Despreciados por todos. Muy cortos, muy buenos, muy dispuestos a ayudar.",
		"unlock": {"cond": [["won", ">=", 1], ["potions_hp", "==", 0]], "chance": 1.0, "text": "Ganar sin usar pociones de vida"},
		"look": {"skin": "piel_rosa", "hair": "pelo_rosa", "cloth": "ropa_marron", "head": "hocico"}},
	{"id": "batracio", "name": "Batracio", "stats": {"atk": 2, "dex": 2}, "items": ["hacha_madera", "red_bichos"], "random_items": 1,
		"desc": "Vivían en los ríos subterráneos antes que nadie. Tardaron en aceptar a los invasores.",
		"unlock": {"cond": [["won", ">=", 1], ["crafts", "==", 0]], "chance": 1.0, "text": "Ganar sin craftear nada"},
		"look": {"skin": "piel_rana", "hair": "piel_rana", "cloth": "ropa_azul", "head": "rana"}},
	{"id": "urraca", "name": "Urraca", "stats": {"atk": 1, "dex": 3}, "items": ["hacha_madera", "anillo_equilibrio", "anillo_poder"],
		"desc": "Listos, rápidos y codiciosos. Siguieron a todos bajo tierra para acaparar lo ajeno.",
		"unlock": {"cond": [["visit_crater", ">=", 1]], "chance": 0.5, "text": "50 % al visitar el Cráter Estelar"},
		"look": {"skin": "piel_gris", "hair": "pelo_negro", "cloth": "ropa_negra", "head": "antifaz"}},
	{"id": "genio", "name": "Genio de humo", "stats": {"mag": 3}, "items": ["hacha_madera", "mazo_sermon", "baston_fuego"],
		"desc": "Entidades de humo que llevan millones de años jugando con la magia.",
		"unlock": {"cond": [["won", ">=", 1], ["kills", "<=", 2]], "chance": 1.0, "text": "Ganar matando a un solo enemigo"},
		"look": {"skin": "piel_humo", "hair": "pelo_negro", "cloth": "ropa_morada", "head": "turbante"}},
	{"id": "escamado", "name": "Escamado", "stats": {"atk": 1, "dex": 3, "mag": 1}, "items": ["pico_piedra", "katana_esmeralda"],
		"desc": "Cazadores nómadas de sangre fría. Nunca se quedan mucho en un sitio.",
		"unlock": {"cond": [["name", "==", "escamas"]], "chance": 1.0, "text": "Llama a tu personaje por su contraseña secreta"},
		"look": {"skin": "piel_lagarto", "hair": "piel_lagarto", "cloth": "ropa_verde", "head": "cresta"}},
	{"id": "engendro", "name": "Engendro", "stats": {"mag": 4}, "items": ["baston_zombi"],
		"desc": "Nacido de la Ceniza. Enemigo de todos... salvo hoy.",
		"unlock": {"cond": [["g_golden_chests", ">=", 20]], "chance": 1.0, "text": "Abrir 20 cofres dorados en total"},
		"look": {"skin": "piel_ceniza", "hair": "pelo_negro", "cloth": "ropa_negra", "head": "cuernos"}},
	{"id": "fantasma", "name": "Caballero fantasma", "stats": {"hp": 7, "atk": 3}, "items": ["espada_oro", "hacha_madera"],
		"desc": "Eco del gran caballero Sir Ventolín, el único que abatió a un guiverno blanco.",
		"unlock": {"cond": [["kill_ventolin", ">=", 1]], "chance": 1.0, "text": "Vencer al jefe secreto de la gema espiritual"},
		"look": {"skin": "piel_fantasma", "hair": "piel_fantasma", "cloth": "ropa_armadura", "head": "yelmo"}},
]

# --- Rasgos (se eligen 2) ----------------------------------------------------
const TRAITS := [
	{"id": "lenador", "name": "Leñador", "desc": "50 % de que el hacha no se desgaste", "fx": {"axe_save": 0.5}},
	{"id": "vetero", "name": "Minero de vetas", "desc": "50 % de que el pico no se desgaste", "fx": {"pick_save": 0.5}},
	{"id": "recolector", "name": "Recolector", "desc": "50 % de doble cosecha en la hierba", "fx": {"gather_double": 0.5}},
	{"id": "alquimista", "name": "Alquimista", "desc": "50 % de poción grande con ingredientes básicos", "fx": {"brewer": true}},
	{"id": "artesano", "name": "Artesano", "desc": "+10 % de calidad al fabricar", "fx": {"luck": 10}},
	{"id": "agresivo", "name": "Agresivo", "desc": "+2 Ataque, -2 Destreza", "fx": {"atk": 2, "dex": -2}},
	{"id": "defensivo", "name": "Defensivo", "desc": "+4 Vida, -2 Ataque", "fx": {"hp": 4, "atk": -2}},
	{"id": "veloz", "name": "Veloz", "desc": "+4 Destreza", "fx": {"dex": 4}},
	{"id": "robusto", "name": "Robusto", "desc": "+4 Vida", "fx": {"hp": 4}},
	{"id": "tragon", "name": "Tragón", "desc": "Hambre máxima 12", "fx": {"hunger_max": 12}},
	{"id": "listo", "name": "Listo", "desc": "+8 Magia", "fx": {"mag": 8}},
	{"id": "cerrajero", "name": "Cerrajero", "desc": "Abre cofres dorados sin llave", "fx": {"lockmaster": true}},
	{"id": "carterista", "name": "Carterista", "desc": "Roba monedas a los vecinos al pasar", "fx": {"pickpocket": true}},
]

# --- Sombreros -----------------------------------------------------------------
const HATS := [
	{"id": "ninguno", "name": "Sin sombrero", "desc": "Nada en la cabeza, ni por dentro ni por fuera.", "fx": {}, "unlock": {}},
	{"id": "cinta", "name": "Cinta de recolector", "desc": "25 % de objeto extra al recolectar", "fx": {"gather_item": 0.25},
		"unlock": {"cond": [["plants", ">=", 10]], "chance": 0.2, "text": "20 % al recolectar 10 plantas"}},
	{"id": "casco_minero", "name": "Casco de minero", "desc": "25 % de mena extra al minar", "fx": {"ore_extra": 0.25},
		"unlock": {"cond": [["ores", ">=", 10]], "chance": 0.2, "text": "20 % al minar 10 menas"}},
	{"id": "bufanda", "name": "Bufanda berserker", "desc": "33 % de Ataque extra al subir de nivel", "fx": {"lvl_atk": 0.33},
		"unlock": {"cond": [["max_biome_kills", ">=", 10]], "chance": 1.0, "text": "Matar 10 enemigos en un mismo bioma"}},
	{"id": "arquero", "name": "Sombrero de arquero", "desc": "33 % de Destreza extra al subir de nivel", "fx": {"lvl_dex": 0.33},
		"unlock": {"cond": [["arrows", ">=", 100]], "chance": 0.2, "text": "20 % al disparar 100 flechas"}},
	{"id": "mago", "name": "Sombrero de mago", "desc": "33 % de Magia extra al subir de nivel", "fx": {"lvl_mag": 0.33},
		"unlock": {"cond": [["staffs", ">=", 1]], "chance": 0.2, "text": "20 % al fabricar un bastón"}},
	{"id": "orejas", "name": "Orejas de conejo", "desc": "Triple salto", "fx": {"extra_jumps": 1},
		"unlock": {"cond": [["visit_tundra", ">=", 1]], "chance": 0.2, "text": "20 % al visitar la Tundra"}},
	{"id": "ala", "name": "Ala de murciélago", "desc": "Dash el doble de largo", "fx": {"dash_mult": 2.0},
		"unlock": {"cond": [["visit_cavernas", ">=", 1]], "chance": 0.2, "text": "20 % al visitar las Cavernas"}},
	{"id": "tiranodonte", "name": "Gorro de tiranodonte", "desc": "Sin arma: lluvia de meteoros tóxicos (1 maná)", "fx": {"fist_spell": "meteoro"},
		"unlock": {"cond": [["kill_tiranodonte", ">=", 1]], "chance": 0.2, "text": "20 % al vencer a un Tiranodonte"}},
	{"id": "gafas", "name": "Gafas de avispa", "desc": "Caída lenta y más velocidad", "fx": {"slow_fall": true, "speed_mult": 1.2},
		"unlock": {"cond": [["hives", ">=", 1]], "chance": 0.2, "text": "20 % al destruir una colmena"}},
	{"id": "tiki", "name": "Máscara tiki", "desc": "Al entrar en un distrito: 50 % +3 Vida o 50 % -1 Vida", "fx": {"tiki": true},
		"unlock": {"cond": [["visit_cienaga", ">=", 1]], "chance": 0.2, "text": "20 % al visitar la Ciénaga"}},
	{"id": "barba", "name": "Barba de mago", "desc": "66 % de lanzar hechizos gratis", "fx": {"spell_free": 0.66},
		"unlock": {"cond": [["mage_skills", ">=", 3]], "chance": 1.0, "text": "Elegir 3 habilidades de mago"}},
	{"id": "corona", "name": "Corona de héroe", "desc": "33 % de un punto extra al subir de nivel", "fx": {"lvl_any": 0.33},
		"unlock": {"cond": [["won", ">=", 1]], "chance": 1.0, "text": "Ganar una partida"}},
	{"id": "seta", "name": "Sombrero de seta", "desc": "20 % de soltar un ingrediente al recibir daño", "fx": {"hit_ingredient": 0.2},
		"unlock": {"cond": [["visit_pradera", ">=", 1]], "chance": 0.2, "text": "20 % al visitar la Pradera Roja"}},
	{"id": "huevo", "name": "Huevo de araña", "desc": "10 % de que aparezca una Madre Araña al recibir daño", "fx": {"spider_egg": 0.1},
		"unlock": {"cond": [["kill_madre_arana", ">=", 1]], "chance": 0.2, "text": "20 % al vencer a la Madre Araña"}},
	{"id": "mascara_esqueleto", "name": "Máscara de esqueleto", "desc": "25 % de crítico", "fx": {"crit": 0.25},
		"unlock": {"cond": [["visit_mazmorra", ">=", 1]], "chance": 0.2, "text": "20 % al visitar la Mazmorra"}},
	{"id": "dragon", "name": "Gorro de dragón", "desc": "Sin arma: bola de fuego (1 maná)", "fx": {"fist_spell": "bola_fuego"},
		"unlock": {"cond": [["visit_volcan", ">=", 1]], "chance": 0.2, "text": "20 % al visitar el Volcán"}},
	{"id": "mascara_ceniza", "name": "Máscara de ceniza", "desc": "Pierdes 1 Vida cada 2 minutos", "fx": {"hp_drain": 120.0},
		"unlock": {"cond": [["visit_nido", ">=", 1]], "chance": 0.2, "text": "20 % al visitar el Nido de Ceniza"}},
	{"id": "corona_escarcha", "name": "Corona de escarcha", "desc": "20 % de curar al regenerar maná", "fx": {"frost_regen": 0.2},
		"unlock": {"cond": [["kill_reina_escarcha", ">=", 1]], "chance": 0.2, "text": "20 % al vencer a la Reina de Escarcha"}},
	{"id": "vikingo", "name": "Yelmo vikingo", "desc": "10 % de invocar un hacha gigante al atacar", "fx": {"viking": 0.1},
		"unlock": {"cond": [["warrior_skills", ">=", 3]], "chance": 1.0, "text": "Elegir 3 habilidades de guerrero"}},
	{"id": "yelmo_dragon", "name": "Yelmo de dragón negro", "desc": "Dash y saltos no gastan estamina", "fx": {"free_stamina": true},
		"unlock": {"cond": [["kill_dragon_negro", ">=", 1]], "chance": 1.0, "text": "Vencer al Dragón Negro"}},
	{"id": "capucha_rey", "name": "Capucha del rey esqueleto", "desc": "Sin arma: invoca esqueletos (1 maná)", "fx": {"fist_spell": "esqueleto"},
		"unlock": {"cond": [["kill_rey_esqueleto", ">=", 1]], "chance": 1.0, "text": "Vencer al Rey Esqueleto"}},
	{"id": "tricornio", "name": "Tricornio", "desc": "Monedas x2", "fx": {"gold_mult": 2.0},
		"unlock": {"cond": [["kill_corsario", ">=", 1]], "chance": 1.0, "text": "Vencer al Corsario Morsa"}},
	{"id": "autor", "name": "Cabeza del autor", "desc": "No hace nada. Pero qué guapo.", "fx": {},
		"unlock": {"cond": [["name", "==", "autor"]], "chance": 1.0, "text": "Un nombre muy concreto"}},
	{"id": "yelmo_real", "name": "Yelmo real", "desc": "Recibes la mitad de daño", "fx": {"dmg_half": true},
		"unlock": {"cond": [["won", ">=", 1], ["damage_taken", "==", 0]], "chance": 1.0, "text": "Ganar sin recibir daño"}},
]

# --- Compañeros ---------------------------------------------------------------
const COMPANIONS := [
	{"id": "ninguno", "name": "Sin compañero", "desc": "Solo ante el peligro.", "fx": {}, "unlock": {}},
	{"id": "hada", "name": "Hada regeneradora", "desc": "+1 Vida al terminar cada distrito", "fx": {"regen_district": 1},
		"unlock": {"cond": [["district", ">=", 15]], "chance": 1.0, "text": "Llegar al distrito 15"}},
	{"id": "murcielago", "name": "Murciélago anciano", "desc": "De vez en cuando escupe un objeto", "fx": {"spit_item": 90.0},
		"unlock": {"cond": [["won", ">=", 1]], "chance": 1.0, "text": "Ganar una partida"}},
	{"id": "escarabajo", "name": "Escarabajo veloz", "desc": "Velocidad x2", "fx": {"speed_mult": 2.0},
		"unlock": {"cond": [["level", ">=", 40]], "chance": 1.0, "text": "Llegar a nivel 40"}},
	{"id": "guardia", "name": "Guardia mecánico", "desc": "Cuchilla giratoria al hacer dash en el aire", "fx": {"air_dash_blade": true},
		"unlock": {"cond": [["won", ">=", 1], ["level", "<", 5]], "chance": 1.0, "text": "Ganar por debajo de nivel 5"}},
	{"id": "limo", "name": "Limo flotante", "desc": "Sin gravedad", "fx": {"no_gravity": true},
		"unlock": {"cond": [["won", ">=", 1], ["trees", "==", 0]], "chance": 1.0, "text": "Ganar sin talar árboles"}},
	{"id": "ojo", "name": "Ojo de gorgona", "desc": "+1 maná cada 1,5 s", "fx": {"mana_regen": 1.5},
		"unlock": {"cond": [["won", ">=", 1], ["npc_talks", "==", 0]], "chance": 1.0, "text": "Ganar sin hablar con los vecinos"}},
	{"id": "fantasma", "name": "Fantasma gelatinoso", "desc": "Saltos infinitos", "fx": {"infinite_jump": true},
		"unlock": {"cond": [["brands", ">=", 3]], "chance": 1.0, "text": "Fabricar los tres mandobles elementales"}},
	{"id": "llama", "name": "Llama de esperanza", "desc": "+1 punto extra al subir de nivel", "fx": {"lvl_extra": 1},
		"unlock": {"cond": [["won", ">=", 1], ["win_with_scale", ">=", 1]], "chance": 1.0, "text": "Ganar con la Escama de Karvoth equipada"}},
	{"id": "dron", "name": "Dron de la cuarta era", "desc": "Vuelas y vas el doble de rápido", "fx": {"fly": true, "speed_mult": 2.0},
		"unlock": {"cond": [["won_madman", ">=", 1]], "chance": 1.0, "text": "Ganar en modo Demente"}},
]

# --- Habilidades ------------------------------------------------------------------
const SKILLS := [
	{"id": "furia", "name": "Furia", "type": "guerrero", "desc": "Daño cuerpo a cuerpo x2", "dur": 10.0, "cd": 46.0},
	{"id": "carga", "name": "Carga", "type": "guerrero", "desc": "El grupo corre más rápido", "dur": 10.0, "cd": 46.0},
	{"id": "aura", "name": "Aura guardiana", "type": "guerrero", "desc": "Recibes 4 de daño menos", "dur": 10.0, "cd": 46.0},
	{"id": "hoja_caballero", "name": "Hoja del caballero", "type": "guerrero", "desc": "Salto extra con una hoja perforante hacia abajo", "dur": 0.0, "cd": 17.0},
	{"id": "hacha_arrojadiza", "name": "Hacha arrojadiza", "type": "guerrero", "desc": "Lanza un hacha perforante (mitad de Ataque)", "dur": 0.0, "cd": 23.0},
	{"id": "clarividencia", "name": "Clarividencia", "type": "mago", "desc": "Recupera 20 de maná", "dur": 0.0, "cd": 23.0},
	{"id": "levitar", "name": "Levitar", "type": "mago", "desc": "Sin gravedad durante 10 s", "dur": 10.0, "cd": 23.0},
	{"id": "armas_arcanas", "name": "Armas arcanas", "type": "mago", "desc": "El cuerpo a cuerpo del grupo suma tu Magia", "dur": 15.0, "cd": 46.0},
	{"id": "subdito", "name": "Súbdito nigromante", "type": "mago", "desc": "Invoca un súbdito que lanza 6 bolas de fuego", "dur": 7.0, "cd": 40.0},
	{"id": "parpadeo", "name": "Parpadeo", "type": "mago", "desc": "Teletransporte corto hacia delante", "dur": 0.0, "cd": 17.0},
	{"id": "lobo", "name": "Lobo huargo", "type": "explorador", "desc": "Invoca un lobo que empuja y muerde", "dur": 10.0, "cd": 17.0},
	{"id": "flecha_druida", "name": "Flecha druídica", "type": "explorador", "desc": "Salto extra con una flecha gigante hacia abajo", "dur": 0.0, "cd": 17.0},
	{"id": "fuego_fatuo", "name": "Fuego fatuo", "type": "explorador", "desc": "Un fuego que duplica el daño de las flechas que lo cruzan", "dur": 10.0, "cd": 17.0},
	{"id": "rugido", "name": "Rugido cazador", "type": "explorador", "desc": "El grupo gana +10 Destreza", "dur": 10.0, "cd": 46.0},
	{"id": "tiro_triple", "name": "Tiro triple", "type": "explorador", "desc": "El siguiente disparo lanza 3 flechas", "dur": 0.0, "cd": 17.0},
]

# --- Altares ----------------------------------------------------------------
const ALTARS := [
	{"id": "karvoth", "name": "Karvoth, el dragón rojo", "good": {"atk": 5}, "bad": {"max_hp": -1},
		"good_text": "Karvoth alaba tu fuerza: +5 Ataque", "bad_text": "Karvoth ruge de furia: -1 Vida máxima"},
	{"id": "mhulruk", "name": "Mhul'ruk, devorador de almas", "good": {"atk": 2, "dex": 2, "mag": 2, "max_hp": 2}, "bad": {"hp": -1},
		"good_text": "Mhul'ruk aprueba tu poder: +2 a todo", "bad_text": "Mhul'ruk disfruta de tu dolor: -1 Vida"},
	{"id": "aelyn", "name": "Aelyn, la de los prados", "good": {"heal_full": true}, "bad": {},
		"good_text": "Aelyn te bendice: Vida al máximo", "bad_text": "Aelyn ignora tu petición"},
	{"id": "sera", "name": "Sera, jinete de grifo", "good": {"dex": 5}, "bad": {},
		"good_text": "Sera admira tu destreza: +5 Destreza", "bad_text": "Sera no te considera digno"},
]
const ALTAR_PRICE := 500

# --- Biomas -------------------------------------------------------------------------
## tier: 1 fácil, 2 medio, 3 difícil, 4 muy difícil. enemies: [id, peso].
const BIOMES := {
	"bosque": {"name": "Bosque Hundido", "tier": 1, "door": "#74d04a", "hazard": "bloque_pinchos",
		"enemies": [["limo_verde", 4], ["arana_verde", 3], ["jabali", 2], ["avispa", 2]],
		"passive": ["cerdo"], "bosses": ["tiranodonte", "corsario"], "boss_chance": 0.35, "special": ["colmena"],
		"trees": true, "grass": true},
	"cienaga": {"name": "Ciénaga", "tier": 1, "door": "#2e6b3a", "hazard": "espora",
		"enemies": [["babosa", 3], ["chaman_tiki", 2], ["porrero_tiki", 3], ["cangrejo_roca", 1], ["mimico", 1]],
		"passive": [], "bosses": [], "boss_chance": 0.0, "special": [], "trees": true, "grass": true},
	"pradera": {"name": "Pradera Roja", "tier": 2, "door": "#e0507a", "hazard": "",
		"enemies": [["seta_saltarina", 3], ["seta_soldado", 3], ["seta_maga", 2], ["medusa", 2]],
		"passive": ["oveja"], "bosses": [], "boss_chance": 0.0, "special": [], "trees": true, "grass": true},
	"cavernas": {"name": "Cavernas", "tier": 2, "door": "#8f8fa3", "hazard": "",
		"enemies": [["arana_morada", 4], ["murcielago", 3], ["mimico", 1], ["cangrejo_roca", 1]],
		"passive": [], "bosses": [], "boss_chance": 0.0, "special": ["huevo_arana"], "trees": false, "grass": false},
	"tundra": {"name": "Tundra", "tier": 2, "door": "#e8f4ff", "hazard": "carambano",
		"enemies": [["limo_azul", 3], ["caballero_hielo", 2], ["hada_hielo", 2], ["cangrejo_roca", 1]],
		"passive": ["conejo"], "bosses": ["yeti", "reina_escarcha"], "boss_chance": 0.35, "special": [],
		"trees": true, "grass": true},
	"mazmorra": {"name": "Mazmorra", "tier": 3, "door": "#56566b", "hazard": "bola_pinchos",
		"enemies": [["esqueleto_guerrero", 4], ["esqueleto_arquero", 3], ["minotauro", 1], ["genio", 2], ["mimico", 1]],
		"passive": [], "bosses": ["rey_esqueleto"], "boss_chance": 0.4, "special": [], "trees": false, "grass": false,
		"chest_mult": 3.0},
	"volcan": {"name": "Volcán", "tier": 3, "door": "#f08a2a", "hazard": "columna_fuego",
		"enemies": [["buey_fuego", 3], ["diablillo", 3], ["dragon", 2], ["cangrejo_roca", 1]],
		"passive": [], "bosses": ["dragon_negro"], "boss_chance": 0.35, "special": [], "trees": true, "grass": true},
	"cantera": {"name": "Cantera de Cristal", "tier": 3, "door": "#5fe0d0", "hazard": "cuchilla_cristal",
		"enemies": [["golem_cristal", 3], ["murcielago_cristal", 4], ["cangrejo_roca", 1]],
		"passive": ["babosa_cristal"], "bosses": ["paladin_cuarzo"], "boss_chance": 0.35, "special": [],
		"trees": true, "grass": true},
	"crater": {"name": "Cráter Estelar", "tier": 4, "door": "#a45ff0", "hazard": "bola_cosmica",
		"enemies": [["esqueleto_cosmico", 3], ["mariposa_cosmica", 3], ["cangrejo_roca", 1]],
		"passive": [], "bosses": ["capitan_estelar"], "boss_chance": 0.4, "special": [], "trees": false, "grass": true,
		"chest_mult": 2.0},
	"nido": {"name": "Nido de Ceniza", "tier": 5, "door": "#3a2a3a", "hazard": "",
		"enemies": [["cabeza_ceniza", 3], ["necrofago", 3], ["gusano_ceniza", 2]],
		"passive": [], "bosses": [], "boss_chance": 0.0, "special": [], "trees": false, "grass": false},
}
const DOOR_BIOMES := ["bosque", "cienaga", "pradera", "cavernas", "tundra", "mazmorra", "volcan", "cantera", "crater"]
const FINAL_DISTRICT := 21

# --- Enemigos -------------------------------------------------------------------------
## ai: pasivo, saltador, embestidor, caminante, tirador, volador, babosa, medusa, mimico, golem, gusano,
##     y los específicos de jefe. size: hitbox en px. spr: plantilla de sprite + paleta.
const ENEMIES := {
	"cerdo": {"name": "Cerdo", "ai": "pasivo", "hp": 6, "dmg": 0, "speed": 30, "size": [14, 10], "xp": 4, "coins": [1, 3],
		"drops": [["carne_cruda", 1.0]], "spr": "cerdo"},
	"oveja": {"name": "Oveja", "ai": "pasivo", "hp": 10, "dmg": 0, "speed": 30, "size": [14, 11], "xp": 6, "coins": [2, 4],
		"drops": [["carne_cruda", 1.0], ["piel", 0.3]], "spr": "oveja"},
	"conejo": {"name": "Conejo", "ai": "pasivo", "hp": 8, "dmg": 0, "speed": 50, "size": [9, 9], "xp": 6, "coins": [2, 4],
		"drops": [["carne_cruda", 1.0], ["pellejo", 0.3]], "spr": "conejo"},
	"gallina": {"name": "Gallina", "ai": "pasivo", "hp": 4, "dmg": 0, "speed": 35, "size": [9, 9], "xp": 1, "coins": [0, 1],
		"drops": [["pollo_crudo", 1.0]], "spr": "gallina"},
	"babosa_cristal": {"name": "Babosa de cristal", "ai": "pasivo", "hp": 30, "dmg": 0, "speed": 12, "size": [14, 8], "xp": 20,
		"coins": [6, 12], "drops": [["mena_diamante", 0.3]], "spr": "babosa", "pal": "cristal"},
	"limo_verde": {"name": "Limo verde", "ai": "saltador", "hp": 8, "dmg": 1, "speed": 60, "size": [12, 9], "xp": 4,
		"coins": [1, 3], "drops": [["hierba", 0.15]], "spr": "limo", "pal": "verde"},
	"limo_azul": {"name": "Limo azul", "ai": "saltador", "hp": 26, "dmg": 2, "speed": 70, "size": [12, 9], "xp": 12,
		"coins": [3, 6], "drops": [["bicho_hielo", 0.1]], "spr": "limo", "pal": "azul"},
	"arana_verde": {"name": "Araña verde", "ai": "embestidor", "hp": 10, "dmg": 1, "speed": 110, "size": [14, 8], "xp": 6,
		"coins": [1, 3], "drops": [["telarana", 0.6]], "spr": "arana", "pal": "verde", "jumps": true},
	"arana_morada": {"name": "Araña morada", "ai": "embestidor", "hp": 22, "dmg": 3, "speed": 130, "size": [14, 8], "xp": 12,
		"coins": [3, 6], "drops": [["telarana", 0.7]], "spr": "arana", "pal": "morada", "jumps": true},
	"jabali": {"name": "Jabalí", "ai": "embestidor", "hp": 16, "dmg": 2, "speed": 150, "size": [16, 11], "xp": 8,
		"coins": [2, 4], "drops": [["carne_cruda", 0.6], ["pellejo", 0.3]], "spr": "jabali"},
	"avispa": {"name": "Avispa", "ai": "volador", "hp": 6, "dmg": 1, "speed": 70, "size": [9, 8], "xp": 6, "coins": [1, 2],
		"drops": [], "spr": "avispa", "flying": true},
	"babosa": {"name": "Babosa", "ai": "babosa", "hp": 12, "dmg": 1, "speed": 14, "size": [14, 8], "xp": 5, "coins": [1, 3],
		"drops": [["seta", 0.3], ["piel", 0.3]], "spr": "babosa", "pal": "morada"},
	"chaman_tiki": {"name": "Chamán de la tribu", "ai": "tirador", "hp": 12, "dmg": 2, "speed": 40, "size": [10, 20], "xp": 9,
		"coins": [2, 5], "drops": [["piel", 0.4], ["bicho_fuego", 0.05]], "spr": "humano:tiki_chaman", "proj": "espora", "range": 140},
	"porrero_tiki": {"name": "Porrero de la tribu", "ai": "caminante", "hp": 18, "dmg": 2, "speed": 45, "size": [10, 20], "xp": 9,
		"coins": [2, 5], "drops": [["pellejo", 0.4]], "spr": "humano:tiki_porrero"},
	"cangrejo_roca": {"name": "Cangrejo roca", "ai": "embestidor", "hp": 24, "dmg": 2, "speed": 90, "size": [14, 9], "xp": 10,
		"coins": [2, 6], "drops": [["piedra", 0.8], ["mena_hierro", 0.1]], "spr": "cangrejo", "range": 60},
	"mimico": {"name": "Mímico", "ai": "mimico", "hp": 40, "dmg": 3, "speed": 90, "size": [14, 11], "xp": 20, "coins": [10, 25],
		"drops": [["llave", 0.2], ["pocion_vida", 0.3]], "spr": "mimico"},
	"seta_saltarina": {"name": "Seta saltarina", "ai": "saltador", "hp": 14, "dmg": 2, "speed": 70, "size": [10, 11], "xp": 8,
		"coins": [2, 4], "drops": [["seta", 0.5]], "spr": "seta_bicho"},
	"seta_soldado": {"name": "Seta soldado", "ai": "caminante", "hp": 24, "dmg": 3, "speed": 45, "size": [10, 20], "xp": 12,
		"coins": [3, 6], "drops": [["pocion_vida", 0.25], ["seta", 0.3]], "spr": "humano:seta_soldado"},
	"seta_maga": {"name": "Seta maga", "ai": "tirador", "hp": 16, "dmg": 3, "speed": 40, "size": [10, 20], "xp": 12,
		"coins": [3, 6], "drops": [["pocion_mana", 0.25]], "spr": "humano:seta_maga", "proj": "espora", "range": 150},
	"medusa": {"name": "Medusa", "ai": "medusa", "hp": 26, "dmg": 3, "speed": 25, "size": [12, 12], "xp": 14, "coins": [3, 8],
		"drops": [["espada_gelatina", 0.03], ["pocion_vida", 0.25]], "spr": "medusa", "flying": true},
	"murcielago": {"name": "Murciélago", "ai": "volador", "hp": 14, "dmg": 2, "speed": 85, "size": [12, 8], "xp": 10,
		"coins": [2, 5], "drops": [["pocion_vida", 0.15]], "spr": "murcielago", "pal": "gris", "flying": true},
	"esqueleto_guerrero": {"name": "Esqueleto guerrero", "ai": "caminante", "hp": 36, "dmg": 4, "speed": 50, "size": [10, 20],
		"xp": 18, "coins": [5, 10], "drops": [["hueso", 0.8], ["mandoble", 0.02]], "spr": "humano:esqueleto"},
	"esqueleto_arquero": {"name": "Esqueleto arquero", "ai": "tirador", "hp": 28, "dmg": 4, "speed": 40, "size": [10, 20],
		"xp": 18, "coins": [5, 10], "drops": [["hueso", 0.8], ["flecha_hueso", 0.4]], "spr": "humano:esqueleto_arquero",
		"proj": "flecha_enemiga", "range": 200},
	"minotauro": {"name": "Minotauro", "ai": "embestidor", "hp": 80, "dmg": 6, "speed": 170, "size": [16, 24], "xp": 40,
		"coins": [10, 20], "drops": [["pellejo", 0.6], ["granhacha_hierro", 0.05]], "spr": "humano:minotauro", "range": 140},
	"genio": {"name": "Genio de la lámpara", "ai": "tirador", "hp": 40, "dmg": 4, "speed": 40, "size": [12, 18], "xp": 22,
		"coins": [8, 16], "drops": [["gema_rayo", 0.1], ["anillo_sabiduria", 0.03]], "spr": "humano:genio", "flying": true,
		"proj": "bola_magica", "range": 180},
	"caballero_hielo": {"name": "Caballero de hielo", "ai": "caminante", "hp": 50, "dmg": 4, "speed": 45, "size": [10, 20],
		"xp": 24, "coins": [6, 12], "drops": [["lingote_hierro", 0.15], ["bicho_hielo", 0.1]], "spr": "humano:caballero_hielo"},
	"hada_hielo": {"name": "Hada de hielo", "ai": "volador_tirador", "hp": 28, "dmg": 3, "speed": 60, "size": [10, 12],
		"xp": 18, "coins": [5, 10], "drops": [["bicho_hielo", 0.2], ["pocion_mana", 0.2]], "spr": "hada", "pal": "hielo",
		"flying": true, "proj": "esquirla", "range": 160},
	"buey_fuego": {"name": "Buey de fuego", "ai": "embestidor", "hp": 70, "dmg": 6, "speed": 160, "size": [20, 14], "xp": 34,
		"coins": [8, 16], "drops": [["carne_cruda", 0.8], ["pellejo", 0.5]], "spr": "jabali", "pal": "fuego", "scale": 1.3},
	"diablillo": {"name": "Diablillo", "ai": "volador_tirador", "hp": 38, "dmg": 5, "speed": 70, "size": [10, 12], "xp": 26,
		"coins": [8, 14], "drops": [["bicho_fuego", 0.2], ["carbon", 0.4]], "spr": "diablillo", "flying": true,
		"proj": "bola_fuego_enemiga", "range": 170},
	"dragon": {"name": "Dragón", "ai": "volador_tirador", "hp": 80, "dmg": 6, "speed": 60, "size": [22, 14], "xp": 42,
		"coins": [12, 24], "drops": [["gema_fuego", 0.12], ["mena_oro", 0.3]], "spr": "dragon", "flying": true,
		"proj": "bola_fuego_enemiga", "range": 200},
	"golem_cristal": {"name": "Gólem de cristal", "ai": "golem", "hp": 110, "dmg": 7, "speed": 30, "size": [18, 22], "xp": 50,
		"coins": [12, 24], "drops": [["mena_diamante", 0.25], ["mena_oro", 0.4]], "spr": "golem"},
	"murcielago_cristal": {"name": "Murciélago de cristal", "ai": "volador", "hp": 44, "dmg": 6, "speed": 100, "size": [12, 8],
		"xp": 30, "coins": [8, 14], "drops": [["mena_diamante", 0.1]], "spr": "murcielago", "pal": "cristal", "flying": true},
	"esqueleto_cosmico": {"name": "Esqueleto cósmico", "ai": "tirador", "hp": 110, "dmg": 8, "speed": 55, "size": [10, 20],
		"xp": 60, "coins": [15, 30], "drops": [["anillo_locura", 0.03], ["mena_diamante", 0.3]], "spr": "humano:esqueleto_cosmico",
		"proj": "bola_cosmica_enemiga", "range": 220},
	"mariposa_cosmica": {"name": "Mariposa cósmica", "ai": "volador_tirador", "hp": 70, "dmg": 8, "speed": 70, "size": [12, 10],
		"xp": 50, "coins": [15, 30], "drops": [["bicho_rayo", 0.3]], "spr": "mariposa", "flying": true,
		"proj": "bola_cosmica_enemiga", "range": 200},
	"cabeza_ceniza": {"name": "Cabeza de ceniza", "ai": "volador", "hp": 90, "dmg": 8, "speed": 90, "size": [14, 14], "xp": 60,
		"coins": [15, 30], "drops": [["fragmento_ceniza", 0.3]], "spr": "calavera", "flying": true},
	"necrofago": {"name": "Necrófago", "ai": "caminante", "hp": 140, "dmg": 9, "speed": 60, "size": [10, 20], "xp": 70,
		"coins": [15, 30], "drops": [["hoja_ceniza", 0.02], ["fragmento_ceniza", 0.3]], "spr": "humano:necrofago"},
	"gusano_ceniza": {"name": "Gusano de ceniza", "ai": "gusano", "hp": 160, "dmg": 9, "speed": 80, "size": [14, 14], "xp": 80,
		"coins": [20, 35], "drops": [["fragmento_ceniza", 0.5]], "spr": "gusano"},
	"zombi_aliado": {"name": "Muerto aliado", "ai": "aliado", "hp": 30, "dmg": 0, "speed": 60, "size": [10, 20], "xp": 0,
		"coins": [0, 0], "drops": [], "spr": "humano:zombi"},

	# --- Jefes ---------------------------------------------------------------
	"tiranodonte": {"name": "Tiranodonte", "ai": "jefe_tiranodonte", "hp": 140, "dmg": 3, "speed": 35, "size": [30, 22],
		"xp": 60, "coins": [20, 40], "drops": [["pocion_vida", 1.0], ["piel", 0.6], ["pellejo", 0.6]], "spr": "tiranodonte", "boss": true},
	"corsario": {"name": "Corsario Morsa", "ai": "jefe_corsario", "hp": 600, "dmg": 4, "speed": 70, "size": [14, 22], "xp": 200,
		"coins": [40, 80], "drops": [["vial_veneno", 1.0], ["piel", 0.6], ["anillo_poder", 0.2]], "spr": "humano:corsario", "boss": true},
	"madre_arana": {"name": "Madre Araña", "ai": "jefe_madre_arana", "hp": 400, "dmg": 4, "speed": 45, "size": [30, 18], "xp": 150,
		"coins": [30, 60], "drops": [["pocion_vida", 1.0], ["telarana", 1.0]], "spr": "arana", "pal": "madre", "scale": 2.2,
		"boss": true, "noclip": true, "flying": true},
	"rey_esqueleto": {"name": "Rey Esqueleto", "ai": "jefe_rey_esqueleto", "hp": 600, "dmg": 5, "speed": 60, "size": [16, 26],
		"xp": 250, "coins": [50, 100], "drops": [["mandoble", 0.4], ["hueso", 1.0], ["llave", 0.5]], "spr": "humano:rey_esqueleto",
		"boss": true, "flying": true},
	"yeti": {"name": "Yeti", "ai": "jefe_yeti", "hp": 150, "dmg": 4, "speed": 40, "size": [20, 26], "xp": 80, "coins": [20, 40],
		"drops": [["vial_veneno", 1.0], ["pellejo", 1.0]], "spr": "humano:yeti", "boss": true, "scale": 1.3},
	"reina_escarcha": {"name": "Reina de Escarcha", "ai": "jefe_reina", "hp": 850, "dmg": 4, "speed": 50, "size": [14, 22],
		"xp": 350, "coins": [60, 100], "drops": [["gema_hielo", 1.0], ["anillo_sabiduria", 0.3]], "spr": "humano:reina_escarcha",
		"boss": true, "flying": true, "armor": 13},
	"dragon_negro": {"name": "Dragón Negro", "ai": "jefe_dragon", "hp": 800, "dmg": 8, "speed": 45, "size": [40, 24], "xp": 400,
		"coins": [80, 140], "drops": [["escudo_escama", 0.25], ["gema_fuego", 1.0]], "spr": "dragon", "pal": "negro", "scale": 2.0,
		"boss": true, "flying": true, "noclip": true},
	"paladin_cuarzo": {"name": "Paladín de Cuarzo", "ai": "jefe_paladin", "hp": 300, "dmg": 7, "speed": 80, "size": [12, 22],
		"xp": 300, "coins": [60, 120], "drops": [["arco_cristal", 0.2], ["mena_diamante", 1.0]], "spr": "humano:paladin", "boss": true},
	"capitan_estelar": {"name": "Capitán Estelar", "ai": "jefe_capitan", "hp": 1700, "dmg": 8, "speed": 70, "size": [12, 22],
		"xp": 700, "coins": [120, 200], "drops": [["espada_laser", 1.0]], "spr": "humano:capitan", "boss": true},
	"gallo_rey": {"name": "Gallo Rey", "ai": "jefe_gallo", "hp": 300, "dmg": 2, "speed": 60, "size": [20, 20], "xp": 40,
		"coins": [6, 19], "drops": [["pocion_vida_g", 1.0]], "spr": "gallina", "pal": "rey", "scale": 2.2, "boss": true},
	"ventolin": {"name": "Sir Ventolín", "ai": "jefe_ventolin", "hp": 4000, "dmg": 7, "speed": 35, "size": [16, 26], "xp": 1500,
		"coins": [200, 400], "drops": [["guarda_paladin", 1.0]], "spr": "humano:ventolin", "boss": true, "flying": true, "noclip": true},
	"guardian": {"name": "Guardián de Ceniza", "ai": "guardian", "hp": 500000, "dmg": 9999, "speed": 70, "size": [14, 14], "xp": 0,
		"coins": [0, 0], "drops": [], "spr": "calavera", "pal": "guardian", "flying": true, "noclip": true, "boss": false,
		"invulnerable": true},
	"muro_ceniza": {"name": "Muro de Ceniza", "ai": "jefe_muro", "hp": 4000, "dmg": 75, "speed": 8, "size": [64, 288], "xp": 0,
		"coins": [0, 0], "drops": [], "spr": "muro", "boss": true, "noclip": true, "flying": true},
}


static func race(id: String) -> Dictionary:
	for r in RACES:
		if r["id"] == id:
			return r
	return RACES[0]


static func find(list: Array, id: String) -> Dictionary:
	for r in list:
		if r["id"] == id:
			return r
	return list[0]


static func biome(id: String) -> Dictionary:
	return BIOMES.get(id, BIOMES["bosque"])


static func enemy(id: String) -> Dictionary:
	return ENEMIES.get(id, {})


## Biomas que pueden ofrecer las puertas al salir del distrito `d` (el siguiente es d+1).
static func allowed_biomes(next_district: int) -> Array:
	var max_tier := 1
	if next_district >= 2:
		max_tier = 2
	if next_district >= 6:
		max_tier = 3
	if next_district >= 10:
		max_tier = 4
	var out := []
	for b in DOOR_BIOMES:
		if int(BIOMES[b]["tier"]) <= max_tier:
			out.append(b)
	return out


## Elige los biomas de las 3 puertas. Siempre hay al menos una opción de tier 1-2.
static func door_choices(next_district: int, rng: RandomNumberGenerator) -> Array:
	if next_district >= FINAL_DISTRICT:
		return ["nido"]
	var pool := allowed_biomes(next_district)
	var easy := pool.filter(func(b): return int(BIOMES[b]["tier"]) <= 2)
	var out := [easy[rng.randi() % easy.size()]]
	var rest := pool.filter(func(b): return b != out[0])
	while out.size() < 3 and not rest.is_empty():
		var i := rng.randi() % rest.size()
		out.append(rest[i])
		rest.remove_at(i)
	# Barajar para que la fácil no esté siempre a la izquierda.
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out
