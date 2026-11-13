shader_type spatial;
render_mode specular_disabled;
#include "winter_surfaces.gdshaderinc"

uniform sampler2D soil_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float snow_cover = 0.0;
uniform float field_center_z = 0.0;
varying vec2 field_at;

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float track_at(float z) {
	float pass = abs(mod(z - field_center_z + 12.0, 24.0) - 12.0);
	return 1.0 - smoothstep(0.15, 0.3, abs(pass - 0.9));
}

void vertex() {
	field_at = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	// Shallow snow undulations partly fill the old wheel ruts.
	float drift = 0.018 * sin(field_at.x * 0.32 + sin(field_at.y * 0.48));
	VERTEX.y += snow_cover * (0.045 + drift) - track_at(field_at.y) * 0.018;
}

void fragment() {
	vec2 at = field_at;
	vec3 soil = texture(soil_texture, at / 8.0).rgb;
	float track = track_at(at.y);
	// Broken short straw fragments lie on the soil, aligned with the harvest.
	vec2 cell = floor(at / vec2(0.55, 0.32));
	vec2 local = fract(at / vec2(0.55, 0.32));
	float seed = hash(cell);
	float straw = (1.0 - smoothstep(0.045, 0.14, abs(local.y - seed)))
		* smoothstep(0.08, 0.2, local.x) * (1.0 - smoothstep(0.55, 0.85, local.x));
	// Filter small straw detail out smoothly at distant camera sizes.
	straw *= 1.0 - smoothstep(0.3, 1.0, length(fwidth(at)));
	float rows = 0.94 + 0.06 * sin(at.y * 18.0);
	vec3 autumn = soil * vec3(0.66, 0.58, 0.46) * rows;
	autumn = mix(autumn, vec3(0.43, 0.31, 0.15), straw * 0.58 * (1.0 - track));
	autumn *= 1.0 - track * 0.24;
	// The snow cover is continuous with the headland, with shallow wheel ruts.
	vec3 winter = winter_snow_colour(at, 0.04 + track * 0.09);
	winter = mix(winter, vec3(0.26, 0.20, 0.12), straw * step(0.88, seed) * 0.28);
	ALBEDO = mix(autumn, winter, snow_cover);
	ROUGHNESS = 1.0;
}
