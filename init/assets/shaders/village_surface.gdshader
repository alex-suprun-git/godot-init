// Shared matte material response; the original albedo artwork stays untouched.
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D response_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 colour_tint : source_color = vec4(1.0);
uniform float texture_contrast = .85;
uniform float roughness_floor = .88;
uniform float metal_amount = .0;
uniform float normal_strength = .22;
uniform float snow_amount = .0;
varying vec3 world_normal;
void vertex() { world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL); }
void fragment() {
	vec3 detail=texture(albedo_texture,UV).rgb;
	vec3 mean=textureLod(albedo_texture,vec2(.5),12.0).rgb;
	vec3 colour=mix(mean,detail,texture_contrast)*colour_tint.rgb;
	float snow=smoothstep(.35,.8,world_normal.y)*snow_amount;
	ALBEDO=mix(colour,vec3(.62,.67,.72),snow);
	NORMAL_MAP=texture(normal_texture,UV).rgb;
	NORMAL_MAP_DEPTH=normal_strength*(1.0-snow);
	ROUGHNESS=max(roughness_floor,texture(response_texture,UV).g);
	METALLIC=metal_amount*(1.0-snow);
	SPECULAR=.12;
}
