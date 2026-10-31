shader_type canvas_item;
render_mode unshaded;

// Keep event paintings close to the map's subdued palette.
uniform float saturation : hint_range(0.0, 1.5) = 0.76;
uniform float contrast : hint_range(0.5, 1.5) = 0.96;
uniform float brightness : hint_range(0.5, 1.5) = 0.96;
uniform vec3 color_balance = vec3(0.98, 1.0, 1.02);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(vec3(luminance), source.rgb, saturation);
	graded = (graded - vec3(0.5)) * contrast + vec3(0.5);
	graded *= brightness * color_balance;
	COLOR = vec4(clamp(graded, vec3(0.0), vec3(1.0)), source.a);
}
