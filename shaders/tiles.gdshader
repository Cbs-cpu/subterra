shader_type canvas_item;
// Terreno al estilo de las piezas del personaje: contorno negro de 1 px donde el sólido da
// al aire, capa de hierba de 3 px con matas que sobresalen (también con contorno), tierra de
// grumos grandes (4 px) que se oscurece en profundidad, piedras sueltas y musgo colgando de
// los techos. Plataformas de tablón con contorno.
// data.r*255: 0 aire, 1 sólido, 2 plataforma.

uniform sampler2D data : filter_nearest;
uniform vec2 map_size = vec2(160.0, 36.0);
uniform vec4 c_top : source_color = vec4(0.29, 0.6, 0.23, 1.0);
uniform vec4 c_top2 : source_color = vec4(0.2, 0.45, 0.16, 1.0);
uniform vec4 c_dirt : source_color = vec4(0.36, 0.24, 0.15, 1.0);
uniform vec4 c_dirt2 : source_color = vec4(0.28, 0.18, 0.11, 1.0);
uniform vec4 c_deep : source_color = vec4(0.16, 0.11, 0.09, 1.0);
uniform vec4 c_plat : source_color = vec4(0.55, 0.37, 0.2, 1.0);
uniform vec4 c_speck : source_color = vec4(0.45, 0.32, 0.2, 1.0);

const vec3 INK = vec3(0.055, 0.04, 0.04);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

int tile(vec2 t) {
	if (t.x < 0.0 || t.y < 0.0 || t.x >= map_size.x || t.y >= map_size.y) return 1;
	return int(texture(data, (t + 0.5) / map_size).r * 255.0 + 0.5);
}

// Altura (0-2 px) de la mata de hierba de la columna de 2 px que contiene px.x.
float tuft(float x, float ty) {
	float h = hash(vec2(floor(x / 2.0), ty * 7.0));
	return h > 0.72 ? 2.0 : (h > 0.45 ? 1.0 : 0.0);
}

vec4 shade(vec2 px) {
	vec2 t = floor(px / 16.0);
	vec2 lp = mod(px, 16.0);
	int m = tile(t);

	if (m == 0 || (m == 2 && lp.y > 5.0)) {
		// Matas de hierba sobre el suelo de debajo (con contorno encima).
		if (tile(t + vec2(0.0, 1.0)) == 1 && lp.y >= 13.0) {
			float h = tuft(px.x, t.y + 1.0);
			float up = 16.0 - lp.y;
			if (h > 0.0 && up <= h) return vec4(up == h ? c_top.rgb : c_top2.rgb, 1.0);
			if (h > 0.0 && up == h + 1.0) return vec4(INK, 1.0);
		}
		// Musgo que cuelga de los techos, con la punta oscura.
		if (tile(t + vec2(0.0, -1.0)) == 1) {
			float len = floor(hash(vec2(floor(px.x / 2.0), t.y * 3.1)) * 6.0) - 2.0;
			if (lp.y < len) return vec4(c_top2.rgb * 0.75, 1.0);
			if (len > 0.0 && lp.y == len) return vec4(INK, 1.0);
		}
		return vec4(0.0);
	}
	if (m == 2) {
		// Tablón: contorno arriba y abajo, hierba encima y vetas cada 8 px.
		if (lp.y == 0.0 || lp.y == 5.0) return vec4(INK, 1.0);
		vec3 pc = c_plat.rgb;
		if (lp.y == 1.0) pc = c_top.rgb;
		else if (lp.y == 4.0) pc *= 0.6;
		else if (mod(px.x, 8.0) == 0.0) pc *= 0.7;
		return vec4(pc, 1.0);
	}
	bool up_air = tile(t + vec2(0.0, -1.0)) != 1;
	bool down_air = tile(t + vec2(0.0, 1.0)) != 1;
	bool left_air = tile(t + vec2(-1.0, 0.0)) != 1;
	bool right_air = tile(t + vec2(1.0, 0.0)) != 1;
	// Contorno negro hacia el aire (bajo una mata, la fila de arriba es hierba).
	if (up_air && lp.y == 0.0) {
		return vec4(tuft(px.x, t.y) > 0.0 ? c_top2.rgb : INK, 1.0);
	}
	if ((left_air && lp.x == 0.0) || (right_air && lp.x == 15.0) || (down_air && lp.y == 15.0)) return vec4(INK, 1.0);
	// Capa de hierba.
	if (up_air && lp.y <= 3.0) {
		if (lp.y == 1.0) return vec4(c_top.rgb, 1.0);
		return vec4(c_top2.rgb, 1.0);
	}
	if (up_air && lp.y == 4.0 && hash(vec2(floor(px.x / 2.0), t.y + 0.5)) > 0.5) return vec4(c_top2.rgb * 0.75, 1.0);
	// Tierra: grumos de 4 px en dos tonos, más oscura en profundidad.
	float depth = 0.0;
	for (int k = 1; k <= 3; k++) {
		if (tile(t + vec2(0.0, -float(k))) == 1) depth += 1.0; else break;
	}
	vec2 g = floor(px / 4.0);
	float n = hash(g);
	vec3 col = n > 0.6 ? c_dirt2.rgb : c_dirt.rgb;
	if (n > 0.93) col = c_speck.rgb;
	col = mix(col, c_deep.rgb, clamp(depth / 3.0, 0.0, 1.0) * 0.6);
	// Piedras sueltas de 4x3 con luz arriba y contorno, en sitios al azar de cada celda de 12 px.
	vec2 sc = floor(px / 12.0);
	if (hash(sc + t * 1.7) > 0.8) {
		vec2 so = floor(vec2(hash(sc + 3.1), hash(sc + 5.7)) * vec2(6.0, 7.0)) + 1.0;
		vec2 sp = mod(px, 12.0) - so;
		if (sp.x >= -1.0 && sp.x <= 4.0 && sp.y >= -1.0 && sp.y <= 3.0) {
			bool inside = sp.x >= 0.0 && sp.x <= 3.0 && sp.y >= 0.0 && sp.y <= 2.0;
			bool corner = (sp.x == -1.0 || sp.x == 4.0) && (sp.y == -1.0 || sp.y == 3.0);
			if (inside) {
				vec3 stone = mix(vec3(0.5, 0.5, 0.56), c_deep.rgb, clamp(depth / 3.0, 0.0, 1.0) * 0.4);
				return vec4(sp.y == 0.0 ? stone * 1.25 : (sp.y == 2.0 ? stone * 0.8 : stone), 1.0);
			}
			if (!corner) return vec4(mix(col, INK, 0.7), 1.0);
		}
	}
	return vec4(col, 1.0);
}

void fragment() {
	vec4 c = shade(floor(UV * map_size * 16.0));
	if (c.a < 0.5) {
		discard;
	}
	COLOR = c;
}
