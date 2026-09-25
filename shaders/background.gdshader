shader_type canvas_item;
// Fondo parallax procedural de cueva: degradado + 3 capas de siluetas (estalactitas y colinas).

uniform vec2 cam = vec2(0.0);
uniform vec4 sky_top : source_color = vec4(0.05, 0.04, 0.08, 1.0);
uniform vec4 sky_bot : source_color = vec4(0.12, 0.1, 0.16, 1.0);
uniform vec4 far : source_color = vec4(0.14, 0.12, 0.2, 1.0);
uniform vec4 mid : source_color = vec4(0.1, 0.08, 0.14, 1.0);
uniform vec4 glow : source_color = vec4(0.3, 0.5, 0.3, 1.0);
uniform float time = 0.0;
uniform vec2 screen = vec2(480.0, 270.0);

float hash(float x) { return fract(sin(x * 127.1) * 43758.5453); }
float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	vec2 p = floor(UV * screen);
	vec3 col = mix(sky_top.rgb, sky_bot.rgb, UV.y);
	// Capa lejana: colinas.
	float x1 = (p.x + cam.x * 0.15) / 60.0;
	float h1 = screen.y * 0.55 + noise(x1) * 50.0 + noise(x1 * 3.0) * 12.0 - cam.y * 0.05;
	if (p.y > h1) col = far.rgb;
	// Estalactitas lejanas.
	float x2 = (p.x + cam.x * 0.2) / 14.0;
	float s2 = noise(x2) * 70.0 * step(0.4, hash(floor(x2)));
	if (p.y < s2 - cam.y * 0.05) col = far.rgb;
	// Capa media.
	float x3 = (p.x + cam.x * 0.4) / 40.0;
	float h3 = screen.y * 0.75 + noise(x3) * 40.0 - cam.y * 0.12;
	if (p.y > h3) col = mid.rgb;
	float x4 = (p.x + cam.x * 0.45) / 10.0;
	float s4 = noise(x4) * 45.0 * step(0.5, hash(floor(x4) + 3.0));
	if (p.y < s4 - cam.y * 0.1) col = mid.rgb;
	// Luciérnagas / motas de luz.
	vec2 q = floor((p + vec2(cam.x * 0.3, cam.y * 0.1)) / 3.0);
	float h = hash(q.x * 13.0 + q.y * 7.0);
	if (h > 0.9985) col = mix(col, glow.rgb, 0.7 + 0.3 * sin(time * 2.0 + h * 50.0));
	// Pared del fondo: textura de roca en bloques de 4 px, muy oscura.
	vec2 w = floor((p + cam * 0.5) / 4.0);
	float wn = hash(w.x * 7.0 + w.y * 131.0);
	col *= 0.8 + 0.25 * wn;
	col *= 0.75;
	COLOR = vec4(col, 1.0);
}
