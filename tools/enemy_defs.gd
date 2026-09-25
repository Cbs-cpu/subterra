extends RefCounted
## Definición de los enemigos por piezas: qué piezas tiene cada uno (tira de fotogramas de
## assets/sprites/enemigos/<id>/<pieza>.png), dónde va su pivote y sus animaciones.
##
## Formato de una animación: [duración, bucle, [[tiempo, {pieza: {"p": posición,
## "r": giro, "f": fotograma}}], ...]]. Lo que no se indica en una clave toma el valor de
## reposo de la pieza. Las posiciones de las piezas marcadas con "snap" y todos los
## fotogramas cambian de golpe (sin interpolar); el resto se interpola en cúbica.
## Todo se mide en píxeles del sprite, con el origen en el suelo y mirando a la derecha.

const DEFS := {
	"limo": {
		"parts": [
			# Cuerpo: 0 normal, 1 aplastado, 2 estirado, 3 muy aplastado. Pivote abajo al centro.
			{"name": "Cuerpo", "tex": "cuerpo", "hframes": 4, "offset": Vector2(-9, -14), "p": Vector2(0, 0)},
			# Ojos: 0 abiertos, 1 cerrados, 2 aturdidos. Siguen la altura del cuerpo.
			{"name": "Ojos", "tex": "ojos", "hframes": 3, "offset": Vector2(-4, -1), "p": Vector2(2, -6), "snap": true, "parent": "Cuerpo"},
		],
		"anims": {
			# Respira despacio (se aplasta un momento) y parpadea.
			"idle": [2.4, true, [
				[0.0, {}],
				[0.9, {"Cuerpo": {"f": 1}, "Ojos": {"p": Vector2(2, -5)}}],
				[1.4, {}],
				[2.0, {"Ojos": {"f": 1}}],
				[2.12, {}],
				[2.4, {}],
			]],
			# Saltito: se encoge, se estira al despegar, vuela, cae estirado y aterriza aplastado.
			"move": [0.9, true, [
				[0.0, {"Cuerpo": {"f": 1}, "Ojos": {"p": Vector2(2, -5)}}],
				[0.12, {"Cuerpo": {"f": 2, "p": Vector2(0, -1)}, "Ojos": {"p": Vector2(1, -7)}}],
				[0.24, {"Cuerpo": {"p": Vector2(0, -5)}}],
				[0.42, {"Cuerpo": {"p": Vector2(0, -6)}}],
				[0.6, {"Cuerpo": {"f": 2, "p": Vector2(0, -3)}, "Ojos": {"p": Vector2(1, -7)}}],
				[0.7, {"Cuerpo": {"f": 3, "p": Vector2(0, 0)}, "Ojos": {"p": Vector2(3, -4)}}],
				[0.8, {"Cuerpo": {"f": 1}, "Ojos": {"p": Vector2(2, -5)}}],
				[0.9, {"Cuerpo": {"f": 1}, "Ojos": {"p": Vector2(2, -5)}}],
			]],
			# Embestida: se agacha mirando al objetivo, salta hacia delante y vuelve.
			"attack": [0.7, false, [
				[0.0, {"Cuerpo": {"f": 1}, "Ojos": {"p": Vector2(3, -5)}}],
				[0.25, {"Cuerpo": {"f": 3}, "Ojos": {"p": Vector2(3, -4)}}],
				[0.32, {"Cuerpo": {"f": 2, "p": Vector2(3, -2)}, "Ojos": {"p": Vector2(1, -7)}}],
				[0.44, {"Cuerpo": {"p": Vector2(5, -3)}}],
				[0.54, {"Cuerpo": {"f": 3, "p": Vector2(5, 0)}, "Ojos": {"p": Vector2(3, -4)}}],
				[0.62, {"Cuerpo": {"f": 1, "p": Vector2(3, 0)}, "Ojos": {"p": Vector2(2, -5)}}],
				[0.7, {}],
			]],
			# Golpe recibido: se aplasta con los ojos en X y se recupera.
			"hurt": [0.35, false, [
				[0.0, {"Cuerpo": {"f": 3, "p": Vector2(-1, 0)}, "Ojos": {"f": 2, "p": Vector2(2, -4)}}],
				[0.14, {"Cuerpo": {"f": 2, "p": Vector2(-1, 0)}, "Ojos": {"f": 2, "p": Vector2(1, -7)}}],
				[0.26, {"Cuerpo": {"f": 0}, "Ojos": {"f": 2}}],
				[0.35, {}],
			]],
		},
	},
}
