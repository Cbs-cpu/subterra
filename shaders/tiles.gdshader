shader_type canvas_item;
// Terreno con textura densa de píxeles (grumos de 2 px), musgo que cuelga del borde superior,
// raíces bajo los salientes y plataformas de tablón con musgo. Sin contornos negros.
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

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

int tile(vec2 t) {
	if (t.x < 0.0 || t.y < 0.0 || t.x >= map_size.x || t.y >= map_size.y) return 1;
	return int(texture(data, (t + 0.5) / map_size).r * 255.0 + 0.5);
}

vec4 shade(vec2 px) {
	vec2 t = floor(px / 16.0);
	vec2 lp = mod(px, 16.0);
	int m = tile(t);
	bool up_air = tile(t + vec2(0.0, -1.0)) != 1;

	if (m == 0 || (m == 2 && lp.y > 5.0)) {
		// Aire: borde de musgo "peludo" que sobresale de los sólidos vecinos (los 4 lados),
		// más musgo/raíces colgando bajo los techos.
		float hh = hash(floor(px / vec2(1.0, 1.0)) + t * 3.0);
		float col2 = floor(px.x / 2.0);
		if (tile(t + vec2(0.0, 1.0)) == 1 && lp.y >= 13.0) {
			float tuft = floor(hash(vec2(col2, t.y * 7.0)) * 4.0);
			if (16.0 - lp.y <= tuft) return vec4(tuft >= 3.0 ? c_top.rgb : c_top2.rgb, 1.0);
		}
		if (tile(t + vec2(0.0, -1.0)) == 1) {
			float len = floor(hash(vec2(col2, t.y * 3.1)) * 7.0) - 2.0;
			if (lp.y < len) return vec4(mix(c_dirt2.rgb, c_top2.rgb, 0.55) * (1.0 - lp.y * 0.07), 1.0);
		}
		if (tile(t + vec2(-1.0, 0.0)) == 1 && lp.x < 2.0 && hh > 0.45 + lp.x * 0.25) return vec4(c_top2.rgb * 0.8, 1.0);
		if (tile(t + vec2(1.0, 0.0)) == 1 && lp.x > 13.0 && hh > 0.45 + (15.0 - lp.x) * 0.25) return vec4(c_top2.rgb * 0.7, 1.0);
		return vec4(0.0);
	}
	if (m == 2) {
		// Plataforma de tablón con musgo encima.
		vec3 col = c_plat.rgb;
		if (lp.y == 0.0 || (lp.y == 1.0 && hash(vec2(floor(px.x / 2.0), t.y)) > 0.4)) col = c_top.rgb;
		else if (lp.y >= 4.0) col *= 0.55;
		else if (mod(px.x, 8.0) == 0.0) col *= 0.7;
		if (lp.y == 5.0) {
			if (hash(vec2(px.x, t.y)) > 0.6) col = c_top2.rgb * 0.8; else return vec4(0.0);
		}
		return vec4(col, 1.0);
	}
	// Sólido: textura de grumos de 2 px con tres tonos.
	vec2 g = floor(px / 2.0);
	float n = hash(g);
	float n2 = hash(g + 17.0);
	float depth = 0.0;
	for (int k = 1; k <= 3; k++) {
		if (tile(t + vec2(0.0, -float(k))) == 1) depth += 1.0; else break;
	}
	vec3 col = c_dirt.rgb;
	if (n > 0.55) col = c_dirt2.rgb;
	if (n > 0.88) col = c_speck.rgb;
	if (n < 0.08) col = c_deep.rgb;
	col = mix(col, c_deep.rgb, clamp(depth / 3.0, 0.0, 1.0) * 0.55);
	// Piedras incrustadas (grumos de 4 px).
	float st = hash(floor(px / 4.0) + t * 5.0);
	if (st > 0.94 && depth >= 1.0) col = mix(col, vec3(0.5, 0.5, 0.55), 0.45);
	// Borde superior: capa de hierba/musgo de altura irregular con hojas.
	if (up_air) {
		float h = 3.0 + floor(hash(vec2(floor(px.x / 2.0), t.y)) * 3.0);
		if (lp.y < h) {
			col = (n2 > 0.5) ? c_top.rgb : c_top2.rgb;
			if (lp.y == 0.0 && n2 > 0.3) col = mix(c_top.rgb, vec3(1.0), 0.18);
		} else if (lp.y < h + 2.0 && n2 > 0.5) {
			col = c_top2.rgb * 0.8;
		}
	}
	// Bordes laterales hacia el aire: algo más oscuros, sin contorno negro.
	if (tile(t + vec2(-1.0, 0.0)) != 1 && lp.x < 2.0 && n2 > 0.4) col = c_top2.rgb * 0.75;
	if (tile(t + vec2(1.0, 0.0)) != 1 && lp.x > 13.0 && n2 > 0.4) col = c_top2.rgb * 0.65;
	if (tile(t + vec2(0.0, 1.0)) != 1 && lp.y > 14.0) col *= 0.6;
	return vec4(col, 1.0);
}

void fragment() {
	vec4 c = shade(floor(UV * map_size * 16.0));
	if (c.a < 0.5) {
		discard;
	}
	COLOR = c;
}
