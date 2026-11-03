// Opaque leaf geometry with local-scale tonal detail; no alpha overdraw.
shader_type spatial;
render_mode cull_disabled;

uniform vec4 season_tint : source_color = vec4(1.0);
uniform float colour_saturation : hint_range(0.0, 1.0) = 1.0;
uniform float tonal_detail : hint_range(0.0, 1.0) = 1.0;
uniform float snow_amount : hint_range(0.0, 1.0) = 0.0;
varying vec3 local_position;
varying vec3 world_normal;

void vertex() {
	local_position = VERTEX;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

float grain(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	// Broad mottling survives the map camera; fine grain breaks up flat lobes.
	float patches = sin(local_position.x * 3.3 + sin(local_position.z * 2.1))
		* cos(local_position.y * 3.6 - local_position.z * 1.7);
	float detail = grain(floor(local_position * 35.0));
	float luminance = dot(COLOR.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 colour = mix(vec3(luminance), COLOR.rgb, colour_saturation);
	vec3 foliage = colour * season_tint.rgb
		* (0.99 + (patches * 0.12 + (detail - 0.5) * 0.10) * tonal_detail);
	// A light dusting settles on upward-facing needles, leaving green sides
	// and sheltered undersides. Broad patches avoid a speckled white canopy.
	float upward = smoothstep(0.05, 0.65, normalize(world_normal).y);
	float settled = smoothstep(-0.65, 0.45, patches);
	float snow = snow_amount * upward * mix(0.35, 1.0, settled);
	ALBEDO = mix(foliage, vec3(0.78, 0.83, 0.85), snow);
	ROUGHNESS = 0.96;
	SPECULAR = 0.08;
}
