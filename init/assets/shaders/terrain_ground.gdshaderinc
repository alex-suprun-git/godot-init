// Organic ground (grass, dry grass, dirt): one tile texture, world-space UVs, no visible repeat.
uniform sampler2D ground_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tile_metres = 22.0;
// Second sample: other scale and rotation, so the two repeat grids never line up.
uniform float second_scale = 0.37;
uniform float second_angle = 0.65;
// Large patches of lush / dry / yellowed ground: a painted grayscale map that covers
// `macro_metres`, sampled twice (second one turned and smaller) so its own repeat hides.
uniform sampler2D macro_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float macro_metres = 120.0;
// The painted map is soft (std ~0.08); this stretches it to the range the tint expects.
uniform float macro_contrast = 2.6;
uniform float macro_strength = 0.18;
// Measured against the flat material: the blend and macro tint came out ~8 % darker and cooler.
uniform vec3 compensation = vec3(1.24, 1.17, 1.14);
// Restoring detail contrast after the blend also raises saturation; pull it back toward grey.
uniform float saturation = 0.88;
uniform vec3 dry_shift = vec3(0.10, 0.04, -0.06);

// Trampled earth: a map-wide mask (0 lawn, 1 bare) and the dirt tile it shows through.
uniform sampler2D wear_mask : hint_default_black, filter_linear, repeat_disable;
uniform vec4 wear_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform sampler2D dirt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float dirt_tile_metres = 12.0;
uniform vec3 dirt_shade = vec3(0.92, 0.88, 0.82);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

// Colour of organic ground at a world position (metres on the XZ plane).
vec3 terrain_ground_colour(vec2 world_xz) {

	vec2 uv_a = world_xz / tile_metres;
	float c = cos(second_angle);
	float s = sin(second_angle);
	vec2 uv_b = mat2(vec2(c, s), vec2(-s, c)) * uv_a * second_scale + vec2(0.31, 0.17);

	vec3 a = texture(ground_texture, uv_a).rgb;
	vec3 b = texture(ground_texture, uv_b).rgb;
	// Smooth weight in 0..1 from metre-scale noise: where it is 0 or 1 one sample
	// shows, in between both do. Blending two samples flattens detail, so the
	// result is re-stretched around the texture's mean colour (lowest mip) to
	// keep the variance of a single sample.
	float w = smoothstep(0.25, 0.75, value_noise(world_xz / 9.0));
	vec3 mean_colour = textureLod(ground_texture, uv_a, 12.0).rgb;
	float keep = 1.0 / sqrt(w * w + (1.0 - w) * (1.0 - w));
	vec3 ground = mean_colour + (mix(a, b, w) - mean_colour) * keep;

	// Large-scale variation: brightness plus a shift toward dry yellow.
	vec2 macro_uv = world_xz / macro_metres;
	float macro_sample = texture(macro_texture, macro_uv).r * 0.65
		+ texture(macro_texture, mat2(vec2(s, -c), vec2(c, s)) * macro_uv * 2.3 + vec2(0.43, 0.71)).r * 0.35;
	float macro_mean = textureLod(macro_texture, macro_uv, 12.0).r;
	float macro = clamp(0.5 + (macro_sample - macro_mean) * macro_contrast, 0.0, 1.0);
	ground *= 1.0 + (macro - 0.5) * 2.0 * macro_strength;
	ground += dry_shift * smoothstep(0.55, 0.9, macro) * macro_strength * 2.0;

	ground = mix(vec3(dot(ground, vec3(0.299, 0.587, 0.114))), ground, saturation);
	vec3 lawn = clamp(ground * compensation, 0.0, 1.0) * tint.rgb;

	// Noise breaks the smooth mask into irregular bare patches and tufts at its edge.
	float wear = texture(wear_mask, (world_xz - wear_rect.xy) / wear_rect.zw).r;
	float grain = value_noise(world_xz / 1.7) * 0.6 + value_noise(world_xz / 0.45 + 9.0) * 0.4;
	float bare = smoothstep(0.3, 0.7, wear + (grain - 0.5) * 0.6);
	vec3 dirt = texture(dirt_texture, world_xz / dirt_tile_metres).rgb * dirt_shade;
	return mix(lawn, dirt, bare);
}
