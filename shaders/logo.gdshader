shader_type canvas_item;
// Relleno del logotipo: degradado vertical dorado y un destello diagonal que lo recorre.
// Usa la cobertura de la letra (alfa de la textura) y sustituye el color.

uniform vec4 top_col : source_color = vec4(1.0, 0.95, 0.62, 1.0);
uniform vec4 mid_col : source_color = vec4(0.97, 0.80, 0.30, 1.0);
uniform vec4 bot_col : source_color = vec4(0.62, 0.40, 0.08, 1.0);
uniform float y_top = 0.0;
uniform float y_bot = 40.0;
uniform float shine_x = -100.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	float k = clamp((local.y - y_top) / max(y_bot - y_top, 0.001), 0.0, 1.0);
	vec3 c = k < 0.5 ? mix(top_col.rgb, mid_col.rgb, k * 2.0) : mix(mid_col.rgb, bot_col.rgb, (k - 0.5) * 2.0);
	float d = abs((local.x - shine_x) + (local.y - y_top) * 0.6);
	c += vec3(1.0, 0.97, 0.8) * smoothstep(9.0, 0.0, d) * 0.55;
	COLOR = vec4(c, texture(TEXTURE, UV).a * COLOR.a);
}
