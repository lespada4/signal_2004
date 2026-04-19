shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float fish_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec2 iResolution = vec2(textureSize(SCREEN_TEXTURE, 0));
    float aspectRatio = iResolution.x / iResolution.y;
    float strength = fish_intensity * 0.03;

    vec2 uv = UV;
    uv.y = 1.0 - uv.y;

    vec2 coords = (uv - 0.5) * 2.0;

    vec2 realCoordOffs;
    realCoordOffs.x = (1.0 - coords.y * coords.y) * strength * aspectRatio * coords.x;
    realCoordOffs.y = (1.0 - coords.x * coords.x) * strength * aspectRatio * coords.y;

    vec2 fuv = uv - realCoordOffs;

    if (fuv.x < 0.0 || fuv.x > 1.0 || fuv.y < 0.0 || fuv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        fuv.y = 1.0 - fuv.y;
        COLOR = texture(SCREEN_TEXTURE, fuv);
    }
}