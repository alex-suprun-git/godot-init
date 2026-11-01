shader_type spatial;
render_mode cull_disabled;

uniform vec4 paint_colour : source_color = vec4(0.79, 0.78, 0.72, 1.0);

varying vec3 paint_world;

void vertex() {
	paint_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(paint_world.xz * 18.0);
	float wear = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	if (wear < 0.07 || edge < 0.012 + wear * 0.018) {
		discard;
	}
	ALBEDO = paint_colour.rgb * (0.94 + wear * 0.06);
	ROUGHNESS = 1.0;
}
