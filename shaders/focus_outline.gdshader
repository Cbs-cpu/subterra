shader_type canvas_item;
// Contorno dorado que late alrededor del sprite enfocado (lo que el jugador tiene "a un
// clic"). Pinta de dorado los píxeles transparentes que tocan un píxel opaco y da un leve
// brillo dorado al propio sprite.

uniform vec4 gold : source_color = vec4(1.0, 0.84, 0.3, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	float n = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
		+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float edge = step(0.05, n) * (1.0 - step(0.05, c.a));
	float pulse = 0.7 + 0.3 * sin(TIME * 5.0);
	vec4 base = c * COLOR;
	base.rgb += gold.rgb * 0.12 * pulse * c.a;
	COLOR = mix(base, vec4(gold.rgb, pulse * COLOR.a), edge);
}
