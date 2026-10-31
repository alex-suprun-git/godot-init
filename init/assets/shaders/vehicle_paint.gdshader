shader_type spatial;
uniform sampler2D body_atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_atlas : filter_linear_mipmap, repeat_enable;
uniform vec4 body_color : source_color = vec4(0.65, 0.65, 0.60, 1.0);
void fragment() {
    vec3 base = texture(body_atlas, UV).rgb;
    vec3 orm = texture(orm_atlas, UV).rgb;
    float luminance = dot(base, vec3(0.2126, 0.7152, 0.0722));
    // Preserve bright and metallic fittings baked into the body atlas.
    float paint_mask = (1.0 - smoothstep(0.028, 0.065, luminance))
        * (1.0 - smoothstep(0.30, 0.60, orm.b));
    ALBEDO = mix(base, body_color.rgb * clamp(luminance / 0.016, 0.25, 1.30), paint_mask);
    ROUGHNESS = orm.g;
    METALLIC = orm.b;
}
