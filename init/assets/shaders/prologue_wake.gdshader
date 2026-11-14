shader_type canvas_item;
render_mode unshaded;

uniform float opening : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y * 2.0 - 1.0;
	float edge = opening * 1.55 - 0.22 * x * x;
	float lids = smoothstep(edge - 0.22, edge, abs(y + opening * 0.12));
	float light_adaptation = smoothstep(0.0, 0.48, opening);
	COLOR = vec4(0.0, 0.0, 0.0, mix(1.0, lids, light_adaptation));
}
