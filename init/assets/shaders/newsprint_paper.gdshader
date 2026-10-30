shader_type canvas_item;

// A static, restrained paper grain; text is rendered separately at full contrast.
void fragment() {
	vec2 pixel = floor(FRAGCOORD.xy);
	float grain = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453);
	float edge = pow(abs(UV.x - 0.5) * 2.0, 12.0) + pow(abs(UV.y - 0.5) * 2.0, 12.0);
	float fold = exp(-abs(UV.x - 0.5) * 180.0);
	vec3 paper = vec3(0.925, 0.88, 0.79);
	paper += (grain - 0.5) * 0.022;
	paper -= edge * 0.018 + fold * 0.012;
	COLOR = vec4(paper, 1.0);
}
