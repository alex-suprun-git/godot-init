shader_type spatial;
#include "winter_surfaces.gdshaderinc"

uniform sampler2D grain_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool concrete = false;
uniform bool winter = false;
varying vec2 world_position;

float hash2(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}

float noise2(vec2 p) {
	vec2 cell=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash2(cell),hash2(cell+vec2(1.0,0.0)),f.x),
		mix(hash2(cell+vec2(0.0,1.0)),hash2(cell+vec2(1.0)),f.x),f.y);
}

void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;
}

void fragment() {
	vec2 p=world_position;
	float grain=dot(texture(grain_texture,p/2.5).rgb,vec3(.299,.587,.114));
	float broad=noise2(p*.18);
	vec3 color=concrete?vec3(.26,.27,.245):vec3(.105,.115,.107);
	color+=(grain-.28)*.09+(broad-.5)*.018;
	if(concrete){
		vec2 local=fract(p/vec2(4.0,3.0));
		vec2 distance_to_joint=min(local,1.0-local)*vec2(4.0,3.0);
		float aa=max(fwidth(p.x),fwidth(p.y));
		float joint=1.0-smoothstep(.008,.018+aa,min(distance_to_joint.x,distance_to_joint.y));
		color*=mix(1.0,.80,joint);
		// Work stains stay at the actual repair-door line and workshop apron.
		vec2 local_hall=p-vec2(-372.0,-245.0);
		float bay=abs(mod(local_hall.x+4.0,8.0)-4.0);
		float use_zone=smoothstep(11.0,13.0,local_hall.y)*(1.0-smoothstep(20.0,25.0,local_hall.y));
		float track=(1.0-smoothstep(.10,.25,abs(bay-.8)))*use_zone;
		color*=1.0-track*.13;
	}else{
		// Sparse asphalt patches with feathered boundaries, not a square grid.
		vec2 patch_cell=floor((p+vec2(1.2,5.7))/vec2(11.0,7.0));
		vec2 local=fract((p+vec2(1.2,5.7))/vec2(11.0,7.0));
		float patch=step(.94,hash2(patch_cell))*smoothstep(.04,.12,min(min(local.x,1.0-local.x),min(local.y,1.0-local.y)));
		color*=1.0-patch*.10;
	}
	if (winter) {
		float cover = concrete ? 0.36 : 0.08;
		color = mix(color, winter_snow_colour(p, 0.80), cover + (broad - 0.5) * 0.08);
	}
	ALBEDO=color;
	ROUGHNESS=.97;
	SPECULAR=.10;
}
