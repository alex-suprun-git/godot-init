// Painted wall that lights up its windows at night. The window mask comes from the
// facade picture itself (dark, not warm), so every facade works without extra art.
shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glow : source_color = vec3(1.0, 0.74, 0.4);
uniform float lit_share : hint_range(0.0, 1.0) = 0.38; // Share of windows with the light on.
uniform vec2 cell = vec2(2.6, 3.0); // Window pitch in metres: along the wall, per floor.

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(albedo_tex, UV * uv_scale).rgb;
	ALBEDO = c * tint.rgb;
	ROUGHNESS = 0.95;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float glass = (1.0 - smoothstep(0.24, 0.36, lum)) * step(c.r, c.b + 0.04);
	vec2 id = floor(vec2(world_pos.x + world_pos.z, world_pos.y) / cell);
	float on = step(hash(id), lit_share);
	float warm = 0.75 + 0.25 * hash(id + 7.0);
	EMISSION = glow * glass * on * warm * night * 1.1;
}
