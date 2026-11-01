shader_type spatial;
render_mode specular_disabled;

uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
// A joint-centre-to-joint-centre region avoids partial perimeter slabs in the source.
uniform vec4 source_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float repeat_metres = 2.0;
uniform float surface_brightness = 1.0;
uniform float mottle_strength = 0.0;
varying vec2 world_uv;

float grain_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float soft_mottle(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	return mix(mix(grain_hash(cell), grain_hash(cell + vec2(1.0, 0.0)), local.x),
		mix(grain_hash(cell + vec2(0.0, 1.0)), grain_hash(cell + vec2(1.0)), local.x), local.y);
}

void vertex() {
	world_uv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz / repeat_metres;
}

void fragment() {
	vec2 source_uv = source_region.xy + fract(world_uv) * source_region.zw;
	// Derivatives from the unwrapped coordinates keep mip selection stable at seams.
	vec3 surface = textureGrad(surface_texture, source_uv,
		dFdx(world_uv) * source_region.zw, dFdy(world_uv) * source_region.zw).rgb;
	// Millimetre aggregate alone disappears in map mips. Gentle metre-scale
	// variation keeps pedestrian asphalt readable without painting large cracks.
	float mottle = soft_mottle(world_uv * repeat_metres / 1.25);
	ALBEDO = surface * surface_brightness * (1.0 + (mottle * 2.0 - 1.0) * mottle_strength);
	ROUGHNESS = 0.95;
}
