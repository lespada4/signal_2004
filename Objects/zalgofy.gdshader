shader_type canvas_item;

uniform float strength : hint_range(0.0, 10.0) = 2.0;
uniform float speed : hint_range(0.0, 10.0) = 3.0;
uniform float frequency : hint_range(0.0, 50.0) = 15.0;
uniform float chromatic_strength : hint_range(0.0, 0.02) = 0.005;

void fragment() {
    vec2 uv = UV;
    
    // Вертикальное смещение — основа zalgo
    float noise_y = sin(uv.x * frequency + TIME * speed) * 0.01 * strength;
    noise_y += sin(uv.x * frequency * 2.3 + TIME * speed * 1.7) * 0.005 * strength;
    noise_y += sin(uv.x * frequency * 0.7 - TIME * speed * 0.9) * 0.007 * strength;
    
    // Горизонтальное смещение — текст "дышит"
    float noise_x = cos(uv.y * frequency * 0.5 + TIME * speed * 0.6) * 0.003 * strength;
    
    vec2 distorted_uv = uv + vec2(noise_x, noise_y);
    
    // Хроматическая аберрация — каналы разъезжаются
    float r = texture(TEXTURE, distorted_uv + vec2(chromatic_strength, 0.0)).r;
    float g = texture(TEXTURE, distorted_uv).g;
    float b = texture(TEXTURE, distorted_uv - vec2(chromatic_strength, 0.0)).b;
    float a = texture(TEXTURE, distorted_uv).a;
    
    // Случайное мерцание отдельных участков
    float flicker = step(0.98, sin(uv.x * 50.0 + TIME * 20.0) * sin(uv.y * 30.0 + TIME * 15.0));
    
    vec4 color = vec4(r, g, b, a);
    
    // Иногда инвертируем случайные пиксели
    color.rgb = mix(color.rgb, 1.0 - color.rgb, flicker * 0.5);
    
    COLOR = color;
}