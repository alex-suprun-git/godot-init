shader_type spatial;
render_mode depth_prepass_alpha, specular_disabled;
uniform sampler2D rural_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D shared_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 seasonal_tint : source_color = vec4(1.0);
uniform bool winter = false;
uniform float edge_metres = 0.0;
uniform vec2 quad_size = vec2(1.0);
uniform sampler2D wear_mask : hint_default_black, filter_linear, repeat_disable;
uniform vec4 wear_rect = vec4(0.0,0.0,1.0,1.0);
varying vec2 world_xz;
void vertex() { world_xz = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz; }
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float field(vec2 p) {
	vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 uv=world_xz/3.6;
	vec3 a=texture(rural_texture,uv).rgb;
	vec3 b=texture(rural_texture,mat2(vec2(.8,.6),vec2(-.6,.8))*uv*.43+vec2(.31,.17)).rgb;
	vec3 mean=textureLod(rural_texture,vec2(.5),12.0).rgb;
	float blend=smoothstep(.25,.75,field(world_xz/7.0));
	float keep=1.0/sqrt(blend*blend+(1.0-blend)*(1.0-blend));
	vec3 rural=mean+(mix(a,b,blend)-mean)*keep;
	vec3 shared = texture(shared_texture,world_xz/22.0).rgb;
	vec3 earth = texture(soil_texture,world_xz/2.0).rgb;
	float macro = field(world_xz*.16)*.7+field(world_xz*.48+9.0)*.3;
	vec3 grass = mix(shared,rural,.52) * seasonal_tint.rgb;
	grass *= .92+.14*macro;
	float dry = smoothstep(.64,.9,macro)*.15;
	vec3 colour = mix(grass,earth,dry);
	float wear=texture(wear_mask,(world_xz-wear_rect.xy)/wear_rect.zw).r;
	float bare=smoothstep(.35,.78,wear+(field(world_xz*1.7)-.5)*.18);
	colour=mix(colour,earth*.67,bare*.78);
	if (winter) { colour = shared * seasonal_tint.rgb; }
	ALBEDO = colour;
	ROUGHNESS = .97;
	ALPHA = 1.0;
	if (edge_metres > 0.0) {
		vec2 edge = min(UV,vec2(1.0)-UV)*quad_size;
		ALPHA = smoothstep(0.0,edge_metres,min(edge.x,edge.y));
	}
}
