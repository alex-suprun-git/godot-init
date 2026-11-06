shader_type spatial;

uniform vec4 paint : source_color = vec4(0.4, 0.5, 0.6, 1.0);

void fragment() {
	// The exported cargo surface uses darker vertex colours for panels than ribs.
	float shade = 0.75 + COLOR.b * 0.9;
	ALBEDO = paint.rgb * shade;
	ROUGHNESS = 0.85;
}
