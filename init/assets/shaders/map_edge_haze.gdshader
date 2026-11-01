// Full-screen haze that fades the map out beyond an authored rectangle. World
// position is rebuilt from the depth buffer, so the haze stays glued to the
// ground in both camera modes instead of following the screen.
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec4 inner; // x0, z0, x1, z1
uniform vec4 fade; // west, north, east, south (metres)
uniform float noise_amp = 18.0;
uniform float noise_scale = 0.012;
uniform vec4 haze_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform bool debug_stripes = false;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	if (debug_stripes) {
		ALBEDO = vec3(step(0.5, fract(world.x / 50.0)), step(0.5, fract(world.z / 50.0)), 0.0);
		ALPHA = 0.6;
	} else {
		float n = (value_noise(world.xz * noise_scale) * 0.65 + value_noise(world.xz * noise_scale * 2.7) * 0.35 - 0.5) * 2.0 * noise_amp;
		float tw = (inner.x - world.x + n) / fade.x;
		float tn = (inner.y - world.z + n) / fade.y;
		float te = (world.x - inner.z + n) / fade.z;
		float ts = (world.z - inner.w + n) / fade.w;
		float t = clamp(max(max(tw, tn), max(te, ts)), 0.0, 1.0);
		float a = smoothstep(0.0, 1.0, t);
		// Sky pixels (depth at the far plane) are always fully hazed.
		if (depth <= 0.00001) {
			a = 1.0;
		}
		ALBEDO = haze_color.rgb;
		ALPHA = a * haze_color.a;
	}
}
