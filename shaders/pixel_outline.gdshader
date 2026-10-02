// Contorno negro de 1 px alrededor de lo opaco (como las piezas del resto de personajes) y
// alfa duro: cada píxel es opaco o transparente.
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a >= 0.5) {
		COLOR = vec4(c.rgb, 1.0);
	} else {
		vec2 p = TEXTURE_PIXEL_SIZE;
		float n = texture(TEXTURE, UV + vec2(p.x, 0.0)).a + texture(TEXTURE, UV - vec2(p.x, 0.0)).a
			+ texture(TEXTURE, UV + vec2(0.0, p.y)).a + texture(TEXTURE, UV - vec2(0.0, p.y)).a;
		COLOR = n >= 0.5 ? outline_color : vec4(0.0);
	}
}
