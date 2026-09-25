shader_type canvas_item;
// Dibuja el mapa de tiles de un distrito con autotile por vecinos.
// data.r*255: 0 aire, 1 sólido, 2 plataforma. Paleta por bioma.

uniform sampler2D data : filter_nearest;
uniform vec2 map_size = vec2(160.0, 36.0);
uniform vec4 c_top : source_color = vec4(0.29, 0.6, 0.23, 1.0);     // hierba/nieve del borde
uniform vec4 c_top2 : source_color = vec4(0.2, 0.45, 0.16, 1.0);
uniform vec4 c_dirt : source_color = vec4(0.36, 0.24, 0.15, 1.0);
uniform vec4 c_dirt2 : source_color = vec4(0.28, 0.18, 0.11, 1.0);
uniform vec4 c_deep : source_color = vec4(0.16, 0.11, 0.09, 1.0);
uniform vec4 c_plat : source_color = vec4(0.55, 0.37, 0.2, 1.0);
uniform vec4 c_speck : source_color = vec4(0.45, 0.32, 0.2, 1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

int tile(vec2 t) {
	if (t.x < 0.0 || t.y < 0.0 || t.x >= map_size.x || t.y >= map_size.y) return 1;
	return int(texture(data, (t + 0.5) / map_size).r * 255.0 + 0.5);
}

void fragment() {
	vec2 px = floor(UV * map_size * 16.0);
	vec2 t = floor(px / 16.0);
	vec2 lp = mod(px, 16.0);
	int m = tile(t);
	if (m == 0) {
		discard;
	}
	if (m == 2) {
		// Plataforma de un sentido: tablón de 4 px con remaches.
		if (lp.y > 4.0) discard;
		vec3 col = c_plat.rgb;
		if (lp.y == 0.0) col = mix(col, vec3(1.0), 0.25);
		if (lp.y >= 3.0) col *= 0.65;
		if (mod(px.x, 16.0) == 1.0 && lp.y == 1.0) col *= 0.6;
		if (lp.y == 4.0) col = vec3(0.1, 0.07, 0.12);
		COLOR = vec4(col, 1.0);
	} else {
		bool air_up = tile(t + vec2(0.0, -1.0)) != 1;
		bool air_dn = tile(t + vec2(0.0, 1.0)) != 1;
		bool air_l = tile(t + vec2(-1.0, 0.0)) != 1;
		bool air_r = tile(t + vec2(1.0, 0.0)) != 1;
		// Profundidad: cuántos tiles sólidos hay encima.
		float depth = 0.0;
		for (int k = 1; k <= 3; k++) {
			if (tile(t + vec2(0.0, -float(k))) == 1) depth += 1.0; else break;
		}
		float n = hash(px);
		float blob = hash(floor(px / 4.0) + t * 7.0);
		vec3 col = mix(c_dirt.rgb, c_dirt2.rgb, step(0.6, blob));
		if (depth >= 3.0) col = mix(col, c_deep.rgb, 0.6);
		if (n > 0.965) col = c_speck.rgb;
		// Piedras incrustadas.
		if (blob > 0.93 && depth >= 1.0) col = mix(col, vec3(0.55, 0.55, 0.6), 0.5);
		// Borde superior con hierba y flecos.
		if (air_up) {
			float fringe = 4.0 + floor(hash(vec2(px.x, t.y)) * 3.0);
			if (lp.y < fringe) col = lp.y < 2.0 ? c_top.rgb : c_top2.rgb;
			if (lp.y == 0.0) col = mix(col, vec3(1.0), 0.2);
		}
		// Contornos hacia el aire.
		if ((air_up && lp.y == 0.0 && false) || (air_l && lp.x == 0.0) || (air_r && lp.x == 15.0) || (air_dn && lp.y == 15.0)) {
			col = vec3(0.1, 0.07, 0.12);
		} else {
			if (air_l && lp.x == 1.0) col *= 1.15;
			if (air_r && lp.x == 14.0) col *= 0.75;
			if (air_dn && lp.y == 14.0) col *= 0.7;
		}
		COLOR = vec4(col, 1.0);
	}
}
