shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform bool surface_detail = true;
varying vec2 world_xz;

float roof_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float roof_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(roof_hash(i), roof_hash(i + vec2(1.0, 0.0)), f.x),
		mix(roof_hash(i + vec2(0.0, 1.0)), roof_hash(i + vec2(1.0)), f.x), f.y);
}
float felt_seam(vec2 p) {
	float strip = floor(p.x / 1.2);
	vec2 phase = fract(vec2(p.x / 1.2, (p.y + mod(strip, 2.0) * 2.0) / 4.0));
	vec2 distance_m = min(phase, 1.0 - phase) * vec2(1.2, 4.0);
	return 1.0 - smoothstep(0.025, 0.095, min(distance_m.x, distance_m.y));
}
float felt_height(vec2 p) {
	return felt_seam(p) * 0.025 + roof_noise(p * 1.7) * 0.012;
}
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	vec3 source = texture(albedo_tex, UV * uv_scale).rgb;
	ALBEDO = source;
	ROUGHNESS = 0.95;
	if (surface_detail) {
		float grain = dot(source, vec3(0.299, 0.587, 0.114));
		float patch = roof_noise(world_xz / 2.7);
		float seam = felt_seam(world_xz);
		// Like the town asphalt: reinterpret the painted source at a real metre scale.
		vec3 felt = vec3(0.075, 0.082, 0.090) + (grain - 0.12) * 0.30;
		felt *= 0.82 + patch * 0.34;
		ALBEDO = max(vec3(0.025), felt * (1.0 - seam * 0.30));
		ROUGHNESS = mix(0.86, 0.97, patch);
		SPECULAR = 0.20;
		vec2 step_m = max(vec2(0.035), fwidth(world_xz));
		float dx = (felt_height(world_xz + vec2(step_m.x, 0.0)) - felt_height(world_xz - vec2(step_m.x, 0.0))) / (step_m.x * 2.0);
		float dy = (felt_height(world_xz + vec2(0.0, step_m.y)) - felt_height(world_xz - vec2(0.0, step_m.y))) / (step_m.y * 2.0);
		NORMAL_MAP = normalize(vec3(-dx, dy, 1.0)) * 0.5 + 0.5;
		NORMAL_MAP_DEPTH = 0.8;
	}
}
