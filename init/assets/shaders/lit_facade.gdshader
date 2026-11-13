// Painted wall that lights up its windows at night. The window mask comes from the
// facade picture itself (dark, not warm), so every facade works without extra art.
shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform bool surface_detail = false;
uniform vec2 seam_blend = vec2(0.0); // Opt-in axes for generated repeating wall tiles.
uniform float night : hint_range(0.0, 1.0) = 0.0;
uniform vec3 glow : source_color = vec3(1.0, 0.74, 0.4);
uniform float lit_share : hint_range(0.0, 1.0) = 0.38; // Share of windows with the light on.
uniform vec2 cell = vec2(2.6, 3.0); // Fallback window pitch in metres: along the wall, per floor.
// Window cells measured on the facade picture, as UV inside one picture tile. With them every window is
// lit as a whole (its measured rectangle, not the dark-glass pixels of the picture) and nothing outside
// the windows glows. `col_edges` are the ascending cell edges, `col_wide` marks balcony-glazing cells,
// rows repeat from `row_origin` every `row_pitch`; the strip above the first row (the frieze) stays dark.
// A texture without cells keeps the old metre-grid glass-mask light.
uniform float col_edges[16];
uniform float col_wide[16];
uniform int col_count = 0;
uniform float row_origin = 0.0;
uniform float row_pitch = 0.0;
// Single openings of a non-repeating picture (stair window, door lamp): UV rectangles (x0, y0, x1, y1).
// `rect_always` lamps burn all night; windows are lit by the usual share.
uniform vec4 rect_data[4];
uniform float rect_always[4];
uniform int rect_count = 0;

// Blank gable end of a panel block: no windows. The concrete grain comes from a window-free crop of the
// wall picture, the panel joints (3 m wide, one per storey) are drawn here, nothing glows at night.
uniform bool blank_wall = false;
uniform vec2 wall_size = vec2(12.0, 15.0);
uniform vec2 panel_size = vec2(3.0, 3.0);

varying vec3 world_pos;
varying vec3 node_origin;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	node_origin = MODEL_MATRIX[3].xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Index of the interval of `edges` that holds x.
float cell_index(float x, float edges[16], int count) {
	float index = 0.0;
	for (int i = 1; i < count - 1; i++) {
		index += step(edges[i], x);
	}
	return index;
}

float facade_height(vec3 colour) {
	float brightness = dot(colour, vec3(0.299, 0.587, 0.114));
	float glazing = (1.0 - smoothstep(0.24, 0.36, brightness)) * step(colour.r, colour.b + 0.04);
	return mix(0.45 + brightness * 0.15, 0.08, glazing);
}

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	vec3 c = texture(albedo_tex, uv).rgb;
	if (blank_wall) {
		vec2 metres = UV * wall_size;
		vec2 panel = floor(metres / panel_size);
		vec2 inside = fract(metres / panel_size);
		float shade = hash(panel + floor(node_origin.xz)) - 0.5;
		// Window-free beige panel of the stair picture: x 0..0.22, y 0.2..0.7.
		c = texture(albedo_tex, vec2(0.01 + inside.x * 0.2, 0.2 + inside.y * 0.5)).rgb * (1.0 + shade * 0.16);
		vec2 edge = min(inside, 1.0 - inside) * panel_size;
		float joint = 1.0 - smoothstep(0.03, 0.09, min(edge.x, edge.y));
		c *= 1.0 - 0.38 * joint;
	}
	if (seam_blend.x > 0.0 || seam_blend.y > 0.0) {
		vec2 p = fract(uv);
		// A narrow 2% border mixes the two facing edges into a shared boundary.
		vec2 blend = 0.5 * (1.0 - smoothstep(vec2(0.0), vec2(0.02), min(p, 1.0 - p))) * seam_blend;
		vec3 across_x = texture(albedo_tex, vec2(1.0 - p.x, p.y)).rgb;
		vec3 across_y = texture(albedo_tex, vec2(p.x, 1.0 - p.y)).rgb;
		vec3 across_xy = texture(albedo_tex, 1.0 - p).rgb;
		c = mix(mix(c, across_x, blend.x), mix(across_y, across_xy, blend.x), blend.y);
	}
	ALBEDO = c * tint.rgb;
	ROUGHNESS = 0.95;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float glass = (1.0 - smoothstep(0.24, 0.36, lum)) * step(c.r, c.b + 0.04);
	// Opt-in material separation; the painted window shape remains authoritative.
	if (surface_detail) {
		ROUGHNESS = mix(0.95, 0.46, glass);
		vec2 sample_step = max(vec2(1.0) / vec2(textureSize(albedo_tex, 0)), fwidth(uv));
		float dx = facade_height(texture(albedo_tex, uv + vec2(sample_step.x, 0.0)).rgb) - facade_height(texture(albedo_tex, uv - vec2(sample_step.x, 0.0)).rgb);
		float dy = facade_height(texture(albedo_tex, uv + vec2(0.0, sample_step.y)).rgb) - facade_height(texture(albedo_tex, uv - vec2(0.0, sample_step.y)).rgb);
		NORMAL_MAP = normalize(vec3(-dx * 1.4, -dy * 1.4, 1.0)) * 0.5 + 0.5;
		NORMAL_MAP_DEPTH = 0.65;
	}
	vec2 id = floor(vec2(world_pos.x + world_pos.z, world_pos.y) / vec2(2.6, 3.0));
	float window = glass;
	if (col_count > 1) {
		float fx = fract(uv.x);
		int column = int(cell_index(fx, col_edges, col_count));
		float x0 = col_edges[column];
		float x1 = col_edges[column + 1];
		float rel_x = (fx - x0) / max(x1 - x0, 0.0001);
		float row_f = (uv.y - row_origin) / row_pitch;
		float row = floor(row_f);
		float rel_y = fract(row_f);
		bool wide = col_wide[column] > 0.5;
		vec2 from = wide ? vec2(0.03, 0.05) : vec2(0.23, 0.16);
		vec2 to = wide ? vec2(0.96, 0.58) : vec2(0.77, 0.68);
		float soft = 0.025;
		float inside = smoothstep(from.x, from.x + soft, rel_x) * (1.0 - smoothstep(to.x - soft, to.x, rel_x))
			* smoothstep(from.y, from.y + soft, rel_y) * (1.0 - smoothstep(to.y - soft, to.y, rel_y));
		// The frieze above the first row is not a window. Curtains and frames only shade the light.
		window = inside * step(0.0, row) * (0.8 + 0.2 * glass);
		// Each wall (its node origin) gets its own pattern, so facing walls do not repeat each other.
		id = vec2(float(column) + floor(uv.x) * 16.0 + hash(node_origin.xz) * 97.0, row + floor(uv.y) * 10.0 + hash(node_origin.xz + 3.0) * 53.0);
	}
	float always = 0.0;
	if (col_count <= 1 && rect_count > 0) {
		window = 0.0;
		vec2 p = fract(uv);
		for (int i = 0; i < rect_count; i++) {
			vec4 r = rect_data[i];
			float inside = step(r.x, p.x) * step(p.x, r.z) * step(r.y, p.y) * step(p.y, r.w);
			window = max(window, inside * (0.8 + 0.2 * glass));
			always = max(always, inside * rect_always[i]);
		}
		id = vec2(floor(world_pos.y / 3.0) + hash(node_origin.xz) * 97.0, hash(node_origin.xz + 3.0) * 53.0);
	}
	float on = max(step(hash(id), lit_share), always);
	float warm = 0.75 + 0.25 * hash(id + 7.0);
	if (blank_wall) {
		window = 0.0;
	}
	EMISSION = glow * window * on * warm * night * 1.1;
}
