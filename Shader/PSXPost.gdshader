shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix;

uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : source_color, hint_screen_texture, repeat_disable, filter_nearest;

uniform bool enable_fog = true; 
uniform vec3 fog_color : source_color;
uniform vec3 noise_color : source_color;
uniform float fog_distance : hint_range(1, 6000) = 100;
uniform float fog_fade_range : hint_range(1, 6000) = 50;
uniform bool enable_noise = true;
uniform float noise_time_fac : hint_range(0.1, 10) = 4;

float hashOld12(vec2 p){
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453 + (sin((TIME)) / noise_time_fac)) ;
}

vec3 color_mix(vec3 a, vec3 b, float f ){
	f = clamp(abs(f), 0,1);
	float invf = 1.0 - f;
	return (a*f) + (b*invf);
}

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment(){
	vec3 screen_color = texture(screen_texture, SCREEN_UV).rgb;
	vec2 screen_coords = SCREEN_UV * 2.0 - 1.0;
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(screen_coords, depth);
	
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	float linear_depth = -view.z;
	
	// ВСЁ что дальше fog_distance — полностью в тумане
	// ВСЁ что ближе — прозрачное
	float depth_mask_inv = clamp((linear_depth - (fog_distance - fog_fade_range)) / fog_fade_range, 0.0, 1.0);
	
	vec3 final_color = screen_color;
	
	if (enable_noise){
		vec3 twocolornoise = color_mix(fog_color, noise_color, hashOld12(screen_coords));
		final_color = color_mix(twocolornoise, final_color, depth_mask_inv);
	}
	if (enable_fog){
		final_color = color_mix(fog_color, final_color, depth_mask_inv);
	}
	
	ALBEDO = final_color;
	ALPHA = depth_mask_inv;  // ← ВАЖНО: Прозрачность по расстоянию
}