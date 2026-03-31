shader_type canvas_item;

uniform sampler2D bg_texture_main : source_color, filter_nearest, repeat_enable;
uniform sampler2D bg_texture_alt : source_color, filter_nearest, repeat_enable;
uniform sampler2D bg_texture_solid : source_color, filter_nearest, repeat_enable;
uniform sampler2D noise_tex : source_color, filter_nearest, repeat_enable;
uniform sampler2D normal_map_tex : hint_normal, filter_nearest, repeat_enable;

const float tex_scale = 0.005;
const float tex_scale_noise = 0.001;

instance uniform bool is_solid = false;

varying vec2 world_pos;

void vertex() {
	// Compute world_pos and pass to fragment shader
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float ease_inout(float x, float c) {
	if (x < 0.5) {
		return pow(x * 2.0, -c) * 0.5;
	} else {
		return (1.0 - pow(1.0 - (x - 0.5) * 2.0, -c)) * 0.5 + 0.5;
	}
}

void fragment() {
	vec2 uv_final = world_pos * tex_scale;
	vec2 uv_noise = world_pos * tex_scale_noise;

	vec4 color_multiplier;

	if (is_solid) {
		color_multiplier = texture(bg_texture_solid, uv_final);
		
	} else {
		vec4 tex_main = texture(bg_texture_main, uv_final);
		vec4 tex_alt = texture(bg_texture_alt, uv_final);

		float noise_value = texture(noise_tex, uv_noise).r;
		float blend_value = ease_inout(noise_value, -4.0);

		color_multiplier = mix(tex_main, tex_alt, blend_value);
	}

	// Mulitply because the background poly still has its own color (and mopdulate)
	COLOR *= color_multiplier;

	// NORMAL_MAP = texture(normal_map_tex, uv_final).rgb;
}
