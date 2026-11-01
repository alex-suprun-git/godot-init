shader_type spatial;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 surface_tint : source_color = vec4(1.0);
uniform bool winter = false;
uniform bool paved = false;
uniform bool yard = false;
varying vec2 world_xz;
void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	float scale = paved ? 3.0 : 4.0;
	vec3 detail = texture(surface_texture, world_xz / scale).rgb;
	vec3 mean_colour = textureLod(surface_texture, vec2(0.5), 12.0).rgb;
	vec3 colour;
	if (paved) {
		// Preserve slab joints while suppressing the large painted stains.
		colour = mean_colour + (detail - mean_colour) * 0.60;
	} else {
		float grain = dot(detail - mean_colour, vec3(0.299, 0.587, 0.114));
		vec3 earth = yard ? vec3(0.165, 0.145, 0.105) : vec3(0.19, 0.145, 0.095);
		vec3 packed_snow = yard ? vec3(0.35, 0.36, 0.37) : vec3(0.32, 0.33, 0.34);
		colour = (winter ? packed_snow : earth) + grain * (winter ? 0.20 : 0.32);
	}
	ALBEDO = clamp(colour * surface_tint.rgb, vec3(0.02), vec3(0.85));
	ROUGHNESS = 1.0;
	SPECULAR = 0.12;
}
