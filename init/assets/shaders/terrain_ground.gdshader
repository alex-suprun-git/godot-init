shader_type spatial;
render_mode specular_disabled;

#include "terrain_ground.gdshaderinc"

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	ALBEDO = terrain_ground_colour(world_xz);
	ROUGHNESS = 0.95;
}
