// Metre-scale compacted aggregate, with shared world detail across junctions.
shader_type spatial;
render_mode specular_disabled;
#include "winter_surfaces.gdshaderinc"

uniform sampler2D gravel_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool winter = false;
uniform bool along_x = false;
uniform bool traffic_tracks = true;
uniform bool polygon_surface = false;
uniform float soil_mix = .0;
uniform vec2 quad_size = vec2(5.0);
uniform vec4 grass_tint : source_color = vec4(1.0);
uniform vec4 junction_rects[12];
uniform int junction_count = 0;
varying vec2 world_xz;
void vertex() { world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float field(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
    vec3 grain_sample=texture(gravel_texture,world_xz/.55).rgb;
    vec3 mean=textureLod(gravel_texture,vec2(.5),12.0).rgb;
    float grain=dot(grain_sample-mean,vec3(.299,.587,.114));
    float patches=field(world_xz*.24)*.65+field(world_xz*.73+7.0)*.35;
    vec3 base=mix(vec3(.155,.145,.125),vec3(.125,.108,.085),soil_mix);
    vec3 gravel=base+grain*.46+(patches-.5)*.025;
    float junction=.0;
    for (int i=0;i<12;i++) {
        if (i>=junction_count) { break; }
        vec2 d=max(abs(world_xz-junction_rects[i].xy)-junction_rects[i].zw*.5,vec2(.0));
        junction=max(junction,1.0-smoothstep(.0,1.1,length(d)));
    }
    float across=along_x ? UV.y : UV.x;
    float width=along_x ? quad_size.y : quad_size.x;
    float along=along_x ? UV.x : UV.y;
    float length_m=along_x ? quad_size.x : quad_size.y;
    float ends=smoothstep(.0,3.0,min(along,1.0-along)*length_m);
    float track=(exp(-pow((across-.33)*width/.25,2.0))+exp(-pow((across-.67)*width/.25,2.0)))*ends;
    track*=traffic_tracks && !polygon_surface ? 1.0-junction : .0;
    gravel*=1.0-.12*track;
    float margin=min(across,1.0-across)*width;
    float broken_edge=1.0-smoothstep(.03,.32+(field(world_xz*2.1)-.5)*.12,margin);
    broken_edge*=polygon_surface ? .0 : (1.0-junction);
    vec3 grass=texture(grass_texture,world_xz/4.0).rgb*grass_tint.rgb;
    vec3 colour=mix(gravel,grass,broken_edge*.48);
    if (winter) {
        float compaction = mix(0.74 + 0.14 * track, 0.28, broken_edge);
        colour = winter_snow_colour(world_xz, compaction) + grain * 0.10;
    }
    ALBEDO=max(colour,vec3(.015));
    ROUGHNESS=.98;
}
