shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D crop_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 crop_tint : source_color = vec4(1.0);
varying vec3 field_position;

void vertex() {
	field_position = VERTEX;
}

void fragment() {
	vec2 at = field_position.xz;
	vec3 grain = texture(crop_texture, at / 6.0).rgb;
	// Broad, restrained variation prevents a uniformly coloured carpet at map zoom.
	float variation = 1.0 + 0.045 * sin(at.x * 0.19 + sin(at.y * 0.31))
		+ 0.025 * sin(at.x * 0.61 + at.y * 0.8);
	float edge_shade = mix(0.66, 1.0, smoothstep(0.05, 0.65, field_position.y));
	ALBEDO = grain * crop_tint.rgb * variation * edge_shade;
	ROUGHNESS = 1.0;
}
