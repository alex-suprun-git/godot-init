shader_type spatial;
uniform sampler2D grain_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 surface_tint : source_color = vec4(1.0);
uniform bool winter = false;
uniform bool highway = false;
varying vec2 world_xz;
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	// Compress the old painted mottles into quiet aggregate detail.
	vec3 sample_colour = texture(grain_texture, world_xz / 5.0).rgb;
	float grain = dot(sample_colour, vec3(0.299, 0.587, 0.114));
	float broad = sin(world_xz.x * 0.17 + sin(world_xz.y * 0.12)) * sin(world_xz.y * 0.23);
	vec3 dry = vec3(0.085, 0.091, 0.095) + (grain - 0.28) * 0.24 + broad * 0.004;
	vec3 cold = vec3(0.105, 0.118, 0.135) + (grain - 0.28) * 0.26 + broad * 0.005;
	vec3 surface = winter ? cold : dry;
	// A restrained cooler tone distinguishes the through road from town streets.
	if (highway) {
		vec3 highway_base = winter ? vec3(0.089, 0.105, 0.123) : vec3(0.070, 0.080, 0.087);
		surface = highway_base + (grain - 0.28) * 0.20 + broad * 0.003;
	}
	ALBEDO = surface * surface_tint.rgb;
	ROUGHNESS = 0.96;
	SPECULAR = 0.18;
}
