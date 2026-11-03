shader_type spatial;

uniform sampler2D grain_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform int surface_kind = 0; // 0 platform asphalt; 1 concrete paving; 2 market asphalt.
uniform vec4 site_rect = vec4(0.0);
uniform bool winter = false;
varying vec2 ground_position;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(cell), hash2(cell + vec2(1, 0)), f.x),
		mix(hash2(cell + vec2(0, 1)), hash2(cell + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 p = ground_position;
	float grain = dot(texture(grain_texture, p / 3.0).rgb, vec3(.299, .587, .114));
	float broad = noise2(p * .23);
	float fine = noise2(p * 2.3);
	vec3 color;
	if (surface_kind == 1) {
		// Half-metre municipal slabs: subtle joints and individual replacement slabs.
		vec2 cell = floor(p / .6);
		vec2 local = fract(p / .6);
		vec2 distance_to_joint = min(local, 1.0 - local) * .6;
		float aa = max(fwidth(p.x), fwidth(p.y));
		float joint = 1.0 - smoothstep(.005, .012 + aa, min(distance_to_joint.x, distance_to_joint.y));
		float slab = hash2(cell);
		color = vec3(.30, .295, .265) + (slab - .5) * .038 + (grain - .28) * .07;
		color *= mix(1.0, .72, joint);
		color *= mix(.91, 1.0, broad);
	} else {
		color = surface_kind == 2 ? vec3(.095, .09, .078) : vec3(.145, .15, .143);
		color += (grain - .28) * .14 + (broad - .5) * .022;
		// Quiet rectangular repair patches, with no repeating dark checkerboard.
		vec2 patch_cell = floor((p + vec2(3.7, 1.2)) / vec2(7.0, 4.2));
		vec2 patch_uv = fract((p + vec2(3.7, 1.2)) / vec2(7.0, 4.2));
		float patch = step(.88, hash2(patch_cell)) *
			smoothstep(.06, .13, min(min(patch_uv.x, 1.0-patch_uv.x), min(patch_uv.y, 1.0-patch_uv.y)));
		color *= 1.0 - patch * .18;
		if (surface_kind == 2) {
			// Dust belongs mostly to open walking aisles, not to every roof-sized tile.
			float aisle = abs(mod(p.y - 354.5 + 3.5, 7.0) - 3.5);
			float dust = smoothstep(1.25, 2.0, aisle) * (.18 + broad * .25);
			color = mix(color, vec3(.19, .164, .12), dust);
			float edge = min(min(p.x-site_rect.x, site_rect.z-p.x), min(p.y-site_rect.y, site_rect.w-p.y));
			float broken_edge = noise2(p * 2.0) * .42;
			if (edge < broken_edge) { discard; }
			color = mix(color, vec3(.16, .14, .105), (1.0-smoothstep(.2, .9, edge)) * .6);
		} else {
			color += (fine - .5) * .012;
		}
	}
	if (winter) {
		float snow = smoothstep(.37, .72, broad) * (surface_kind == 1 ? .72 : .45);
		color = mix(color, vec3(.65, .69, .71), snow);
	}
	ALBEDO = max(color, vec3(.025));
	ROUGHNESS = .97;
	SPECULAR = .12;
}
