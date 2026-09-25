extends RefCounted
## Criaturas por piezas (mismo formato que tools/enemy_defs.gd). Los pivotes y el número
## de fotogramas de cada pieza salen de assets/sprites/enemigos/<id>/piezas.json.
## Animaciones calmadas: movimientos de 1-2 píxeles, giros pequeños.

## Cuadrúpedo (cerdo, jabalí, oveja): mismas piezas y animaciones.
const QUAD := {
	"parts": [
		{"name": "Cola", "tex": "cola", "p": Vector2(-8, -10)},
		{"name": "PataB1", "tex": "pata_fondo", "p": Vector2(-3, -4)},
		{"name": "PataB2", "tex": "pata_fondo", "p": Vector2(5, -4)},
		{"name": "PataF1", "tex": "pata", "p": Vector2(-5, -4)},
		{"name": "PataF2", "tex": "pata", "p": Vector2(3, -4)},
		{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -3)},
		{"name": "Cabeza", "tex": "cabeza", "p": Vector2(5, -9)},
	],
	"anims": {
		# Respira, baja la cabeza a pastar y mueve la cola.
		"idle": [2.8, true, [
			[0.0, {}],
			[0.9, {"Cuerpo": {"p": Vector2(0, -4)}}],
			[1.4, {"Cabeza": {"p": Vector2(5, -8), "r": 0.12}}],
			[2.0, {"Cabeza": {"p": Vector2(5, -8), "r": 0.12}, "Cola": {"r": 0.4}}],
			[2.2, {"Cola": {"r": -0.2}}],
			[2.4, {"Cola": {"r": 0.3}}],
			[2.8, {}],
		]],
		# Trote: patas cruzadas que se levantan, cuerpo y cabeza que suben un píxel.
		"move": [0.4, true, [
			[0.0, {"PataF1": {"p": Vector2(-4, -5)}, "PataB2": {"p": Vector2(6, -5)}, "PataF2": {"p": Vector2(2, -4)}, "PataB1": {"p": Vector2(-4, -4)}}],
			[0.1, {"Cuerpo": {"p": Vector2(0, -4)}, "Cabeza": {"p": Vector2(5, -10)}, "Cola": {"r": 0.2}}],
			[0.2, {"PataF2": {"p": Vector2(4, -5)}, "PataB1": {"p": Vector2(-2, -5)}, "PataF1": {"p": Vector2(-6, -4)}, "PataB2": {"p": Vector2(4, -4)}}],
			[0.3, {"Cuerpo": {"p": Vector2(0, -4)}, "Cabeza": {"p": Vector2(5, -10)}, "Cola": {"r": -0.2}}],
			[0.4, {"PataF1": {"p": Vector2(-4, -5)}, "PataB2": {"p": Vector2(6, -5)}, "PataF2": {"p": Vector2(2, -4)}, "PataB1": {"p": Vector2(-4, -4)}}],
		]],
		# Embestida: agacha la cabeza, espera y se lanza.
		"attack": [0.7, false, [
			[0.0, {"Cabeza": {"p": Vector2(6, -8), "r": 0.25}, "Cuerpo": {"p": Vector2(-1, -3)}}],
			[0.3, {"Cabeza": {"p": Vector2(6, -8), "r": 0.28}, "Cuerpo": {"p": Vector2(-1, -3)}}],
			[0.36, {"Root": {"p": Vector2(4, 0)}, "Cabeza": {"p": Vector2(6, -8), "r": 0.2}}],
			[0.5, {"Root": {"p": Vector2(5, 0)}, "Cabeza": {"p": Vector2(6, -8), "r": 0.15}}],
			[0.7, {}],
		]],
		"hurt": [0.3, false, [
			[0.0, {"Root": {"p": Vector2(-1, 0)}, "Cabeza": {"f": 1, "r": -0.15}}],
			[0.18, {"Cabeza": {"f": 1}}],
			[0.3, {}],
		]],
	},
}

## Voladores con alas que baten sin parar y el cuerpo flotando.
const WINGS_FAST := {"cycle": {"Alas": [0.05, [0, 1]]}}

## Hada y diablillo: cabeza, vestido y alas.
const HADA := {
	"parts": [
		{"name": "Alas", "tex": "alas", "p": Vector2(-2, -11)},
		{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -9)},
		{"name": "Cabeza", "tex": "cabeza", "p": Vector2(0, -9)},
	],
	"anims": {
		"idle": [1.6, true, [[0.0, {}], [0.8, {"Root": {"p": Vector2(0, -2)}, "Cabeza": {"r": 0.08}}], [1.6, {}]], {"cycle": {"Alas": [0.08, [0, 1]]}}],
		"move": [1.2, true, [[0.0, {}], [0.6, {"Root": {"p": Vector2(0, -2)}}], [1.2, {}]], {"cycle": {"Alas": [0.06, [0, 1]]}}],
		"attack": [0.5, false, [[0.0, {"Cabeza": {"r": -0.2}}], [0.25, {"Root": {"p": Vector2(2, 0)}, "Cabeza": {"r": 0.15}}], [0.5, {}]], {"cycle": {"Alas": [0.05, [0, 1]]}}],
		"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.25}}], [0.3, {}]]],
	},
}

const DEFS := {
	"cerdo": QUAD,
	"jabali": QUAD,
	"oveja": QUAD,
	"conejo": {
		"parts": [
			{"name": "PieB", "tex": "pie", "p": Vector2(-3, 0)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -1)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(3, -6)},
			{"name": "PieF", "tex": "pie", "p": Vector2(2, 0)},
		],
		"anims": {
			# Mueve la nariz y, de vez en cuando, echa las orejas atrás.
			"idle": [2.6, true, [
				[0.0, {}], [0.2, {"Cabeza": {"r": 0.05}}], [0.35, {}], [0.5, {"Cabeza": {"r": 0.05}}], [0.65, {}],
				[1.8, {"Cabeza": {"f": 1}}], [2.2, {}], [2.6, {}],
			]],
			# Brinco: se encoge, salta con las orejas atrás y aterriza.
			"move": [0.5, true, [
				[0.0, {"Cabeza": {"p": Vector2(3, -5)}}],
				[0.1, {"Root": {"p": Vector2(0, -3)}, "PieB": {"p": Vector2(-5, 0)}, "Cabeza": {"f": 1}}],
				[0.25, {"Root": {"p": Vector2(0, -4)}, "PieB": {"p": Vector2(-4, -1)}, "PieF": {"p": Vector2(3, -1)}, "Cabeza": {"f": 1}}],
				[0.4, {"Root": {"p": Vector2(0, -1)}, "Cabeza": {"f": 1}}],
				[0.45, {"Cabeza": {"p": Vector2(3, -5)}}],
				[0.5, {"Cabeza": {"p": Vector2(3, -5)}}],
			]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Cabeza": {"f": 1, "r": -0.15}}], [0.3, {}]]],
		},
	},
	"gallina": {
		"parts": [
			{"name": "PataB", "tex": "pata", "p": Vector2(-1, -3)},
			{"name": "PataF", "tex": "pata", "p": Vector2(1, -3)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -3)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(3, -9)},
		],
		"anims": {
			# Mira a los lados y picotea el suelo.
			"idle": [3.0, true, [
				[0.0, {}], [0.8, {"Cabeza": {"p": Vector2(2, -9)}}], [1.2, {}],
				[1.8, {"Cabeza": {"p": Vector2(4, -6), "r": 0.5}}], [2.0, {"Cabeza": {"p": Vector2(4, -6), "r": 0.5}}],
				[2.3, {}], [3.0, {}],
			]],
			# Paso con la cabeza adelante y atrás.
			"move": [0.44, true, [
				[0.0, {"PataF": {"p": Vector2(2, -4)}, "Cabeza": {"p": Vector2(4, -9)}}],
				[0.11, {"Cuerpo": {"p": Vector2(0, -4)}}],
				[0.22, {"PataB": {"p": Vector2(0, -4)}, "Cabeza": {"p": Vector2(3, -9)}}],
				[0.33, {"Cuerpo": {"p": Vector2(0, -4)}}],
				[0.44, {"PataF": {"p": Vector2(2, -4)}, "Cabeza": {"p": Vector2(4, -9)}}],
			]],
			# Picotazo.
			"attack": [0.5, false, [
				[0.0, {"Cabeza": {"p": Vector2(2, -10), "r": -0.3}}],
				[0.25, {"Cabeza": {"p": Vector2(2, -10), "r": -0.3}}],
				[0.32, {"Root": {"p": Vector2(2, 0)}, "Cabeza": {"p": Vector2(6, -6), "r": 0.6}}],
				[0.5, {}],
			]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Cabeza": {"f": 1, "r": -0.2}}], [0.3, {}]]],
		},
	},
	"babosa": {
		"parts": [
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, 0)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(6, -3), "snap": true},
		],
		"anims": {
			"idle": [2.4, true, [[0.0, {}], [1.2, {"Cabeza": {"r": -0.1}}], [2.4, {}]]],
			# Se estira y se encoge para avanzar.
			"move": [1.0, true, [
				[0.0, {}],
				[0.3, {"Cuerpo": {"f": 1}, "Cabeza": {"p": Vector2(7, -2)}}],
				[0.6, {"Cuerpo": {"f": 2}, "Cabeza": {"p": Vector2(5, -4)}}],
				[0.8, {}],
				[1.0, {}],
			]],
			"attack": [0.5, false, [
				[0.0, {"Cuerpo": {"f": 2}, "Cabeza": {"p": Vector2(5, -4)}}],
				[0.25, {"Cuerpo": {"f": 1}, "Cabeza": {"p": Vector2(7, -2)}, "Root": {"p": Vector2(2, 0)}}],
				[0.5, {}],
			]],
			"hurt": [0.35, false, [[0.0, {"Cabeza": {"f": 1}, "Cuerpo": {"f": 2}}], [0.35, {}]]],
		},
	},
	"avispa": {
		"parts": [
			{"name": "Abdomen", "tex": "abdomen", "p": Vector2(-1, -7)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(0, -7)},
			{"name": "Alas", "tex": "alas", "p": Vector2(-2, -10)},
		],
		"anims": {
			"idle": [0.8, true, [[0.0, {}], [0.4, {"Root": {"p": Vector2(0, -1)}, "Abdomen": {"r": 0.1}}], [0.8, {}]], WINGS_FAST],
			"move": [0.8, true, [[0.0, {}], [0.4, {"Root": {"p": Vector2(0, -1)}, "Abdomen": {"r": 0.1}}], [0.8, {}]], WINGS_FAST],
			# Se echa atrás y se lanza con el aguijón por delante.
			"attack": [0.5, false, [
				[0.0, {"Root": {"r": -0.2}}], [0.2, {"Root": {"r": -0.25}, "Abdomen": {"r": -0.4}}],
				[0.3, {"Root": {"r": 0.3, "p": Vector2(3, 1)}, "Abdomen": {"r": 0.3}}], [0.5, {}],
			], WINGS_FAST],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.2}, "Cabeza": {"f": 1}}], [0.3, {}]], WINGS_FAST],
		},
	},
	"mariposa": {
		"parts": [
			{"name": "Alas", "tex": "alas", "p": Vector2(0, -8)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -8)},
		],
		"anims": {
			"idle": [1.2, true, [[0.0, {}], [0.6, {"Root": {"p": Vector2(0, -2)}}], [1.2, {}]], {"cycle": {"Alas": [0.1, [0, 1, 2, 1]]}}],
			"move": [1.2, true, [[0.0, {}], [0.6, {"Root": {"p": Vector2(0, -2)}}], [1.2, {}]], {"cycle": {"Alas": [0.08, [0, 1, 2, 1]]}}],
			"attack": [0.5, false, [[0.0, {}], [0.25, {"Root": {"p": Vector2(2, 1)}}], [0.5, {}]], {"cycle": {"Alas": [0.05, [0, 2]]}}],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.3}}], [0.3, {}]]],
		},
	},
	"murcielago": {
		"parts": [
			{"name": "Alas", "tex": "alas", "p": Vector2(0, -8)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -8)},
		],
		"anims": {
			"idle": [0.84, true, [[0.0, {}], [0.42, {"Root": {"p": Vector2(0, -2)}}], [0.84, {}]], {"cycle": {"Alas": [0.07, [0, 1, 2, 1]]}}],
			"move": [0.84, true, [[0.0, {}], [0.42, {"Root": {"p": Vector2(0, -2)}}], [0.84, {}]], {"cycle": {"Alas": [0.07, [0, 1, 2, 1]]}}],
			"attack": [0.5, false, [[0.0, {"Root": {"p": Vector2(0, -2)}}], [0.25, {"Root": {"p": Vector2(3, 2), "r": 0.2}}], [0.5, {}]], {"cycle": {"Alas": [0.05, [0, 2]]}}],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.25}}], [0.3, {}]]],
		},
	},
	"hada": HADA,
	"diablillo": HADA,
	"cangrejo": {
		"parts": [
			{"name": "Patas", "tex": "patas", "p": Vector2(0, -4)},
			{"name": "PinzaB", "tex": "pinza_fondo", "p": Vector2(-8, -6)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -2)},
			{"name": "PinzaF", "tex": "pinza", "p": Vector2(8, -6)},
		],
		"anims": {
			"idle": [2.4, true, [
				[0.0, {}], [1.0, {"PinzaF": {"f": 1}}], [1.2, {}], [1.4, {"PinzaF": {"f": 1}, "PinzaB": {"f": 1}}], [1.6, {}], [2.4, {}],
			]],
			# Anda de lado: patas alternas y cuerpo que se balancea.
			"move": [0.4, true, [
				[0.0, {"Patas": {"f": 0}}], [0.1, {"Cuerpo": {"p": Vector2(0, -3)}}],
				[0.2, {"Patas": {"f": 1}}], [0.3, {"Cuerpo": {"p": Vector2(0, -3)}}], [0.4, {"Patas": {"f": 0}}],
			]],
			# Levanta las pinzas y las cierra de golpe.
			"attack": [0.6, false, [
				[0.0, {"PinzaF": {"p": Vector2(8, -10), "f": 1}, "PinzaB": {"p": Vector2(-8, -10), "f": 1}}],
				[0.3, {"PinzaF": {"p": Vector2(8, -11), "f": 1}, "PinzaB": {"p": Vector2(-8, -11), "f": 1}}],
				[0.36, {"Root": {"p": Vector2(3, 0)}, "PinzaF": {"p": Vector2(10, -6)}}],
				[0.6, {}],
			]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "PinzaF": {"f": 1}, "PinzaB": {"f": 1}}], [0.3, {}]]],
		},
	},
	"mimico": {
		"parts": [
			{"name": "Base", "tex": "base", "p": Vector2(-8, 0)},
			{"name": "Tapa", "tex": "tapa", "p": Vector2(-8, -9)},
		],
		"anims": {
			"idle": [2.0, true, [[0.0, {}], [1.0, {"Tapa": {"r": -0.08}}], [2.0, {}]]],
			# Da saltitos abriendo y cerrando la tapa.
			"move": [0.5, true, [
				[0.0, {}], [0.2, {"Root": {"p": Vector2(0, -2)}, "Tapa": {"r": -0.5, "f": 1}}],
				[0.35, {"Tapa": {"r": -0.1, "f": 1}}], [0.5, {}],
			]],
			# Abre la tapa del todo y muerde.
			"attack": [0.6, false, [
				[0.0, {"Tapa": {"r": -0.3, "f": 1}}], [0.25, {"Tapa": {"r": -0.9, "f": 1}}],
				[0.33, {"Root": {"p": Vector2(3, 0)}, "Tapa": {"r": 0.0, "f": 1}}], [0.6, {"Tapa": {"f": 1}}],
			]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Tapa": {"r": -0.3}}], [0.3, {}]]],
		},
	},
	"seta_bicho": {
		"parts": [
			{"name": "Tallo", "tex": "tallo", "p": Vector2(0, 0)},
			{"name": "Sombrero", "tex": "sombrero", "p": Vector2(0, -7)},
		],
		"anims": {
			"idle": [2.2, true, [[0.0, {}], [1.1, {"Sombrero": {"p": Vector2(0, -6)}}], [2.2, {}]]],
			# Saltito: el sombrero se aplasta al aterrizar.
			"move": [0.6, true, [
				[0.0, {"Sombrero": {"f": 1, "p": Vector2(0, -6)}}], [0.12, {"Root": {"p": Vector2(0, -3)}}],
				[0.3, {"Root": {"p": Vector2(0, -4)}}], [0.48, {"Root": {"p": Vector2(0, -1)}}],
				[0.54, {"Sombrero": {"f": 1, "p": Vector2(0, -6)}}], [0.6, {"Sombrero": {"f": 1, "p": Vector2(0, -6)}}],
			]],
			"attack": [0.5, false, [[0.0, {"Sombrero": {"f": 1, "p": Vector2(0, -6)}}], [0.25, {"Root": {"p": Vector2(3, -3)}}], [0.5, {}]]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Sombrero": {"f": 1, "r": -0.15}}], [0.3, {}]]],
		},
	},
	"medusa": {
		"parts": [
			{"name": "T1", "tex": "tentaculo", "p": Vector2(-4, -9)},
			{"name": "T2", "tex": "tentaculo", "p": Vector2(0, -9)},
			{"name": "T3", "tex": "tentaculo", "p": Vector2(4, -9)},
			{"name": "Campana", "tex": "campana", "p": Vector2(0, -12)},
		],
		"anims": {
			# Late: la campana se cierra, sube un poco y se abre al bajar.
			"idle": [1.4, true, [
				[0.0, {}], [0.35, {"Campana": {"f": 1}, "T1": {"f": 1}, "T3": {"f": 1}}],
				[0.7, {"Root": {"p": Vector2(0, -2)}, "T2": {"f": 1}}], [1.05, {"T1": {"f": 1}, "T3": {"f": 1}}], [1.4, {}],
			]],
			"move": [1.0, true, [
				[0.0, {}], [0.25, {"Campana": {"f": 1}, "T1": {"f": 1}, "T3": {"f": 1}}],
				[0.5, {"Root": {"p": Vector2(0, -2)}, "T2": {"f": 1}}], [0.75, {"T1": {"f": 1}, "T3": {"f": 1}}], [1.0, {}],
			]],
			"attack": [0.5, false, [[0.0, {"Campana": {"f": 1}}], [0.25, {"Root": {"p": Vector2(2, 1)}}], [0.5, {}]]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.2}, "Campana": {"f": 1}}], [0.3, {}]]],
		},
	},
	"dragon": {
		"parts": [
			{"name": "AlaB", "tex": "ala_fondo", "p": Vector2(-3, -14)},
			{"name": "Cola", "tex": "cola", "p": Vector2(-7, -9)},
			{"name": "PataB", "tex": "pata", "p": Vector2(-3, -6)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -10)},
			{"name": "PataF", "tex": "pata", "p": Vector2(3, -6)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(7, -13)},
			{"name": "Ala", "tex": "ala", "p": Vector2(-1, -13)},
		],
		"anims": {
			"idle": [1.0, true, [
				[0.0, {}], [0.5, {"Root": {"p": Vector2(0, -2)}, "Cola": {"r": 0.15}, "Cabeza": {"r": -0.05}}], [1.0, {}],
			], {"cycle": {"Ala": [0.25, [0, 1]], "AlaB": [0.25, [0, 1]]}}],
			"move": [0.8, true, [
				[0.0, {}], [0.4, {"Root": {"p": Vector2(0, -2)}, "Cola": {"r": 0.15}}], [0.8, {}],
			], {"cycle": {"Ala": [0.2, [0, 1]], "AlaB": [0.2, [0, 1]]}}],
			# Echa fuego: abre la boca y adelanta la cabeza.
			"attack": [0.7, false, [
				[0.0, {"Cabeza": {"p": Vector2(6, -14), "r": -0.2}}], [0.3, {"Cabeza": {"p": Vector2(6, -14), "r": -0.25}}],
				[0.36, {"Cabeza": {"f": 1, "p": Vector2(8, -13), "r": 0.1}}], [0.6, {"Cabeza": {"f": 1, "p": Vector2(8, -13)}}], [0.7, {}],
			], {"cycle": {"Ala": [0.2, [0, 1]], "AlaB": [0.2, [0, 1]]}}],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.15}, "Cabeza": {"r": -0.2}}], [0.3, {}]]],
		},
	},
	"golem": {
		"parts": [
			{"name": "BrazoB", "tex": "brazo_fondo", "p": Vector2(-11, -17)},
			{"name": "PiernaB", "tex": "pierna", "p": Vector2(-4, -7)},
			{"name": "PiernaF", "tex": "pierna", "p": Vector2(4, -7)},
			{"name": "Torso", "tex": "torso", "p": Vector2(0, -6)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(1, -19)},
			{"name": "BrazoF", "tex": "brazo", "p": Vector2(11, -17)},
		],
		"anims": {
			"idle": [2.6, true, [[0.0, {}], [1.3, {"Torso": {"p": Vector2(0, -7)}, "Cabeza": {"p": Vector2(1, -20)}}], [2.6, {}]]],
			# Pasos pesados: una pierna sube, el cuerpo se balancea y los brazos siguen.
			"move": [1.0, true, [
				[0.0, {"PiernaF": {"p": Vector2(5, -9)}, "Torso": {"r": 0.03}, "BrazoF": {"r": -0.15}, "BrazoB": {"r": 0.15}}],
				[0.25, {"Torso": {"p": Vector2(0, -7)}}],
				[0.5, {"PiernaB": {"p": Vector2(-3, -9)}, "Torso": {"r": -0.03}, "BrazoF": {"r": 0.15}, "BrazoB": {"r": -0.15}}],
				[0.75, {"Torso": {"p": Vector2(0, -7)}}],
				[1.0, {"PiernaF": {"p": Vector2(5, -9)}, "Torso": {"r": 0.03}, "BrazoF": {"r": -0.15}, "BrazoB": {"r": 0.15}}],
			]],
			# Levanta los brazos y golpea el suelo.
			"attack": [0.9, false, [
				[0.0, {"BrazoF": {"p": Vector2(10, -20), "r": -2.6}, "BrazoB": {"p": Vector2(-10, -20), "r": 2.6}}],
				[0.45, {"BrazoF": {"p": Vector2(10, -21), "r": -2.8}, "BrazoB": {"p": Vector2(-10, -21), "r": 2.8}, "Torso": {"p": Vector2(0, -7)}}],
				[0.55, {"BrazoF": {"p": Vector2(12, -15), "r": -0.2}, "BrazoB": {"p": Vector2(-12, -15), "r": 0.2}, "Root": {"p": Vector2(0, 1)}}],
				[0.9, {}],
			]],
			"hurt": [0.35, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Cabeza": {"r": -0.12}}], [0.35, {}]]],
		},
	},
	"calavera": {
		"parts": [
			{"name": "Mandibula", "tex": "mandibula", "p": Vector2(0, -6), "snap": true},
			{"name": "Craneo", "tex": "craneo", "p": Vector2(0, -6)},
		],
		"anims": {
			"idle": [1.6, true, [
				[0.0, {}], [0.4, {"Mandibula": {"p": Vector2(0, -5)}}], [0.8, {"Root": {"p": Vector2(0, -2)}, "Craneo": {"f": 1}}],
				[1.2, {"Mandibula": {"p": Vector2(0, -5)}}], [1.6, {}],
			]],
			"move": [1.2, true, [[0.0, {}], [0.6, {"Root": {"p": Vector2(0, -2)}, "Mandibula": {"p": Vector2(0, -4)}}], [1.2, {}]]],
			"attack": [0.6, false, [
				[0.0, {"Mandibula": {"p": Vector2(0, -3)}, "Craneo": {"f": 1}}], [0.3, {"Mandibula": {"p": Vector2(0, -2)}, "Craneo": {"f": 1}}],
				[0.38, {"Root": {"p": Vector2(4, 0)}, "Mandibula": {"p": Vector2(0, -6)}}], [0.6, {}],
			]],
			"hurt": [0.3, false, [[0.0, {"Root": {"p": Vector2(-1, 0), "r": -0.2}, "Mandibula": {"p": Vector2(0, -3)}}], [0.3, {}]]],
		},
	},
	"gusano": {
		"parts": [
			{"name": "S4", "tex": "segmento", "p": Vector2(0, -4)},
			{"name": "S3", "tex": "segmento", "p": Vector2(0, -9)},
			{"name": "S2", "tex": "segmento", "p": Vector2(0, -14)},
			{"name": "S1", "tex": "segmento", "p": Vector2(0, -19)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(0, -21)},
		],
		"anims": {
			# Ondula: cada segmento se desplaza un píxel un poco después que el de abajo.
			"idle": [1.6, true, [
				[0.0, {"S3": {"p": Vector2(1, -9)}}],
				[0.4, {"S2": {"p": Vector2(1, -14)}}],
				[0.8, {"S1": {"p": Vector2(1, -19)}, "S3": {"p": Vector2(-1, -9)}}],
				[1.2, {"Cabeza": {"p": Vector2(1, -21)}, "S2": {"p": Vector2(-1, -14)}}],
				[1.6, {"S3": {"p": Vector2(1, -9)}}],
			]],
			"move": [1.2, true, [
				[0.0, {"S3": {"p": Vector2(1, -9)}}], [0.3, {"S2": {"p": Vector2(1, -14)}}],
				[0.6, {"S1": {"p": Vector2(1, -19)}, "S3": {"p": Vector2(-1, -9)}}],
				[0.9, {"Cabeza": {"p": Vector2(1, -21)}, "S2": {"p": Vector2(-1, -14)}}], [1.2, {"S3": {"p": Vector2(1, -9)}}],
			]],
			# Se estira y abre la boca.
			"attack": [0.7, false, [
				[0.0, {"Cabeza": {"p": Vector2(-1, -22), "r": -0.15}}],
				[0.3, {"Cabeza": {"f": 1, "p": Vector2(2, -24), "r": 0.2}, "S1": {"p": Vector2(1, -20)}}],
				[0.55, {"Cabeza": {"f": 1, "p": Vector2(2, -24), "r": 0.2}, "S1": {"p": Vector2(1, -20)}}], [0.7, {}],
			]],
			"hurt": [0.3, false, [[0.0, {"Cabeza": {"p": Vector2(-2, -21), "r": -0.2}, "S1": {"p": Vector2(-1, -19)}}], [0.3, {}]]],
		},
	},
	"tiranodonte": {
		"parts": [
			{"name": "Cola", "tex": "cola", "p": Vector2(-9, -18)},
			{"name": "PiernaB", "tex": "pierna_fondo", "p": Vector2(-3, -10)},
			{"name": "Cuerpo", "tex": "cuerpo", "p": Vector2(0, -8)},
			{"name": "PiernaF", "tex": "pierna", "p": Vector2(4, -10)},
			{"name": "Brazo", "tex": "brazo", "p": Vector2(8, -14)},
			{"name": "Cabeza", "tex": "cabeza", "p": Vector2(8, -22)},
		],
		"anims": {
			"idle": [2.4, true, [
				[0.0, {}], [1.2, {"Cuerpo": {"p": Vector2(0, -9)}, "Cabeza": {"p": Vector2(8, -23)}, "Cola": {"r": 0.08}}], [2.4, {}],
			]],
			# Zancadas pesadas.
			"move": [0.8, true, [
				[0.0, {"PiernaF": {"p": Vector2(6, -12)}, "Cola": {"r": 0.06}}],
				[0.2, {"Cuerpo": {"p": Vector2(0, -9)}, "Cabeza": {"p": Vector2(8, -23)}}],
				[0.4, {"PiernaB": {"p": Vector2(-1, -12)}, "Cola": {"r": -0.06}}],
				[0.6, {"Cuerpo": {"p": Vector2(0, -9)}, "Cabeza": {"p": Vector2(8, -23)}}],
				[0.8, {"PiernaF": {"p": Vector2(6, -12)}, "Cola": {"r": 0.06}}],
			]],
			# Rugido y mordisco.
			"attack": [0.9, false, [
				[0.0, {"Cabeza": {"f": 1, "p": Vector2(7, -24), "r": -0.3}}],
				[0.45, {"Cabeza": {"f": 1, "p": Vector2(7, -24), "r": -0.32}}],
				[0.55, {"Cabeza": {"f": 0, "p": Vector2(10, -20), "r": 0.15}, "Root": {"p": Vector2(3, 0)}}],
				[0.9, {}],
			]],
			"hurt": [0.35, false, [[0.0, {"Root": {"p": Vector2(-1, 0)}, "Cabeza": {"r": -0.15}}], [0.35, {}]]],
		},
	},
}
