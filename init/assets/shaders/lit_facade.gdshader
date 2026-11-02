// Painted wall that lights up its windows at night. The window mask comes from the
// facade picture itself (dark, not warm), so every facade works without extra art.
shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform bool surface_detail = false;
uniform vec2 seam_blend = vec2(0.0); // Opt-in axes for generated repeating wall tiles.
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

float facade_height(vec3 colour) {
	float brightness = dot(colour, vec3(0.299, 0.587, 0.114));
	float glazing = (1.0 - smoothstep(0.24, 0.36, brightness)) * step(colour.r, colour.b + 0.04);
	return mix(0.45 + brightness * 0.15, 0.08, glazing);
}

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	vec3 c = texture(albedo_tex, uv).rgb;
	if (seam_blend.x > 0.0 || seam_blend.y > 0.0) {
		vec2 p = fract(uv);
		// A narrow 2% border mixes the two facing edges into a shared boundary.
		vec2 blend = 0.5 * (1.0 - smoothstep(vec2(0.0), vec2(0.02), min(p, 1.0 - p))) * seam_blend;
		vec3 across_x = texture(albedo_tex, vec2(1.0 - p.x, p.y)).rgb;
		vec3 across_y = texture(albedo_tex, vec2(p.x, 1.0 - p.y)).rgb;
		vec3 across_xy = texture(albedo_tex, 1.0 - p).rgb;
		c = mix(mix(c, across_x, blend.x), mix(across_y, across_xy, blend.x), blend.y);
	}
	ALBEDO = c * tint.rgb;
	ROUGHNESS = 0.95;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float glass = (1.0 - smoothstep(0.24, 0.36, lum)) * step(c.r, c.b + 0.04);
	// Opt-in material separation; the painted window shape remains authoritative.
	if (surface_detail) {
		ROUGHNESS = mix(0.95, 0.46, glass);
		vec2 sample_step = max(vec2(1.0) / vec2(textureSize(albedo_tex, 0)), fwidth(uv));
		float dx = facade_height(texture(albedo_tex, uv + vec2(sample_step.x, 0.0)).rgb) - facade_height(texture(albedo_tex, uv - vec2(sample_step.x, 0.0)).rgb);
		float dy = facade_height(texture(albedo_tex, uv + vec2(0.0, sample_step.y)).rgb) - facade_height(texture(albedo_tex, uv - vec2(0.0, sample_step.y)).rgb);
		NORMAL_MAP = normalize(vec3(-dx * 1.4, -dy * 1.4, 1.0)) * 0.5 + 0.5;
		NORMAL_MAP_DEPTH = 0.65;
	}
	vec2 id = floor(vec2(world_pos.x + world_pos.z, world_pos.y) / cell);
	float on = step(hash(id), lit_share);
	float warm = 0.75 + 0.25 * hash(id + 7.0);
	EMISSION = glow * glass * on * warm * night * 1.1;
}
