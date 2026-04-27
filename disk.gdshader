shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// =====================================================
// PARAMETERS FROM SECOND SHADER (StandardMaterial)
// =====================================================
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D texture_metallic : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);
uniform vec3 uv2_scale = vec3(1.0);
uniform vec3 uv2_offset = vec3(0.0);
uniform float z_clip_scale : hint_range(0.01, 1.0, 0.01) = 1.0;

// =====================================================
// PARAMETERS FROM FIRST SHADER (Rainbow/HSV)
// =====================================================
uniform sampler2D texture_normal : hint_roughness_normal, filter_nearest, repeat_enable;
uniform float normal_depth = 0.25;
uniform float color_compression = 6.0;

// Function to convert HSV to RGB
vec3 hsv2rgb(vec3 hsv) {
    float h = hsv.x * color_compression;
    float s = hsv.y;
    float v = hsv.z;

    float c = v * s;
    float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));
    vec3 rgb = vec3(0.0);

    if (0.0 <= h && h < 1.0) rgb = vec3(c, x, 0.0);
    else if (1.0 <= h && h < 2.0) rgb = vec3(x, c, 0.0);
    else if (2.0 <= h && h < 3.0) rgb = vec3(0.0, c, x);
    else if (3.0 <= h && h < 4.0) rgb = vec3(0.0, x, c);
    else if (4.0 <= h && h < 5.0) rgb = vec3(x, 0.0, c);
    else if (5.0 <= h && h < 6.0) rgb = vec3(c, 0.0, x);

    return rgb + (v - c);
}

// Converts a value in range [istart, istop] to a value in range [ostart, ostop]
float range_lerp(float value, float istart, float istop, float ostart, float ostop) {
    return ostart + (ostop - ostart) * ((value - istart) / (istop - istart));
}

void vertex() {
    UV = UV * uv1_scale.xy + uv1_offset.xy;
    Z_CLIP_SCALE = z_clip_scale;
}

void fragment() {
    vec2 base_uv = UV;
    
    // Albedo from texture
    vec4 albedo_tex = texture(texture_albedo, base_uv);
    ALBEDO = albedo.rgb * albedo_tex.rgb;
    
    // Normal map from first shader
    NORMAL_MAP = texture(texture_normal, UV * 2.0).rgb;
    NORMAL_MAP_DEPTH = normal_depth;
    
    // Metallic from texture
    float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
    METALLIC = metallic_tex * metallic;
    
    // Specular
    SPECULAR = specular;
    
    // Roughness from texture
    vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
    float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
    ROUGHNESS = roughness_tex * roughness;
    
    // Emission for faint glow (from first shader)
    EMISSION = vec3(0.125);
}

void light() {
    vec3 normal_dir = normalize(NORMAL);
    vec3 light_dir = normalize(LIGHT);
    vec3 view_dir = normalize(VIEW);

    vec3 reflection = reflect(light_dir, view_dir);

    float angle = dot(reflection, normal_dir);
    vec3 color = hsv2rgb(vec3(angle, 1.0, 1.0));

    float adjusted_angle = angle;
    if (angle > 0.6) {
        adjusted_angle = range_lerp(angle, 0.6, 0.65, 1.0, 0.0);
        adjusted_angle = clamp(adjusted_angle, 0.0, 1.0);
    }

    SPECULAR_LIGHT += color * LIGHT_COLOR * ATTENUATION * adjusted_angle;
    SPECULAR_LIGHT += color * color;
}