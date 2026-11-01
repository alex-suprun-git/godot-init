shader_type spatial;
render_mode specular_disabled;

// Same ground, but the patch fades out toward its rectangle edge with a noisy
// border, so dry grass and dirt blend into the lawn under them. Kept separate
// from terrain_ground: writing ALPHA makes every user of a shader transparent.
#include "terrain_ground.gdshaderinc"

uniform vec2 quad_metres = vec2(10.0);
uniform float edge_metres = 2.0;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	ALBEDO = terrain_ground_colour(world_xz);
	ROUGHNESS = 0.95;
	vec2 inside = min(UV, 1.0 - UV) * quad_metres;
	float distance_to_edge = min(inside.x, inside.y);
	// Two noise scales push the border in and out by up to one edge width.
	float wobble = value_noise(world_xz / 2.5) * 0.65 + value_noise(world_xz / 0.9 + 5.0) * 0.35;
	ALPHA = smoothstep(0.0, edge_metres, distance_to_edge + (wobble - 0.5) * edge_metres * 1.6);
}
