shader_type spatial;

uniform sampler2D grain_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool concrete = false;
uniform bool winter = false;
varying vec2 ground_position;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = ground_position;
	float grain = dot(texture(grain_texture,p/3.0).rgb,vec3(.299,.587,.114));
	vec2 cell = floor(p/vec2(5,3));
	float patch = hash2(cell);
	vec3 color = concrete ? vec3(.34,.345,.315) : vec3(.135,.145,.137);
	color += (grain-.28) * .12 + (patch-.5)*.015;
	if (concrete) {
		vec2 local = fract(p/vec2(5,3));
		vec2 distance_to_joint = min(local,1.0-local)*vec2(5,3);
		float aa = max(fwidth(p.x),fwidth(p.y));
		float joint = 1.0-smoothstep(.015,.025+aa,min(distance_to_joint.x,distance_to_joint.y));
		color *= mix(1.0,.70,joint);
	}
	if (winter) {
		float snow = smoothstep(.35,.8,texture(grain_texture,p/12.0).g);
		color = mix(color,vec3(.66,.70,.72),snow*.7);
	}
	ALBEDO = color;
	ROUGHNESS = .96;
	SPECULAR = .10;
}
