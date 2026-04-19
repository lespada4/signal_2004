shader_type spatial;
render_mode cull_disabled, unshaded;

uniform vec3 glass_color : source_color = vec3(0.8, 0.9, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.5;
uniform float fresnel_strength : hint_range(0.0, 2.0) = 0.5;
uniform float dither_scale : hint_range(1.0, 64.0) = 16.0;  
uniform vec3 tint_color : source_color = vec3(0.0, 1.0, 0.5);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.1;

float bayer4(vec2 pos) {
    int x = int(pos.x) % 4;
    int y = int(pos.y) % 4;
    int idx = y * 4 + x;
    float[16] m = float[](
         0.0,  8.0,  2.0, 10.0,
        12.0,  4.0, 14.0,  6.0,
         3.0, 11.0,  1.0,  9.0,
        15.0,  7.0, 13.0,  5.0
    );
    return m[idx] / 16.0;
}

void fragment() {
    // Используем экранные координаты с масштабом
    vec2 scaled_coords = FRAGCOORD.xy / dither_scale;
    vec2 pixel = floor(scaled_coords);
    float threshold = bayer4(pixel);

    if (threshold >= opacity) discard;

    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0) * fresnel_strength;
    vec3 final_color = mix(glass_color, tint_color, tint_strength);
    final_color += fresnel;
    ALBEDO = clamp(final_color, 0.0, 1.0);
    EMISSION = clamp(final_color * 0.1, 0.0, 1.0);
}