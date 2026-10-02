// Sombreado "pixel toon" del caballero 3D: luz en pocos escalones, color posterizado para que se
// lea a ~30 px, contraluz frío en el borde y los ojos rojos del visor brillando tenues.
// `albedo_tex` es la textura suavizada (manchas planas); `detail_tex` la original, solo para
// encontrar los píxeles rojos del visor.
shader_type spatial;
render_mode specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_linear;
uniform sampler2D detail_tex : source_color, filter_linear;
uniform float brightness = 2.1;
uniform float levels = 5.0;
uniform float bands = 3.0;
uniform vec3 rim_color : source_color = vec3(0.62, 0.72, 0.95);
uniform float rim_strength = 0.5;
uniform vec3 eye_color : source_color = vec3(1.0, 0.1, 0.05);
uniform float eye_glow = 2.0;

void fragment() {
	vec3 t = texture(albedo_tex, UV).rgb * brightness;
	// Posteriza la luminancia conservando el tono.
	float l = max(dot(t, vec3(0.3, 0.55, 0.15)), 0.001);
	float lq = floor(l * levels + 0.5) / levels;
	ALBEDO = clamp(t * (lq / l), 0.0, 1.0);
	vec3 d = texture(detail_tex, UV).rgb;
	float eye = step(0.4, d.r) * step(d.g * 2.0, d.r) * step(d.b * 2.0, d.r);
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = step(0.7, rim) * rim_strength;
	EMISSION = eye_color * eye * eye_glow + rim_color * rim;
}

void light() {
	float nl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float stepped = floor(nl * bands + 0.5) / bands;
	DIFFUSE_LIGHT += stepped * ATTENUATION * LIGHT_COLOR / PI;
}
