shader_type canvas_item;

// Ink and paper duotone with a fine halftone screen, using the existing art.
void fragment() {
	vec4 photo = texture(TEXTURE, UV);
	float value = dot(photo.rgb, vec3(0.299, 0.587, 0.114));
	value = clamp((value - 0.12) * 1.35, 0.0, 1.0);
	vec2 screen = FRAGCOORD.xy * 2.1;
	float dots = sin(screen.x + screen.y) * sin(screen.x - screen.y);
	value = clamp(value + dots * 0.1, 0.0, 1.0);
	COLOR = vec4(mix(vec3(0.18, 0.16, 0.13), vec3(0.925, 0.88, 0.79), value), photo.a);
}
