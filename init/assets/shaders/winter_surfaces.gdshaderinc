float snow_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float snow_variation(vec2 world_xz) {
	vec2 point = world_xz / 36.0;
	vec2 cell = floor(point);
	vec2 weight = smoothstep(vec2(0.0), vec2(1.0), fract(point));
	return mix(mix(snow_hash(cell), snow_hash(cell + vec2(1.0, 0.0)), weight.x),
		mix(snow_hash(cell + vec2(0.0, 1.0)), snow_hash(cell + vec2(1.0, 1.0)), weight.x), weight.y);
}

vec3 winter_snow_colour(vec2 world_xz, float compaction) {
	float drift = snow_variation(world_xz) - 0.5;
	return mix(vec3(0.55, 0.57, 0.60), vec3(0.23, 0.25, 0.28), compaction) + drift * 0.07;
}
